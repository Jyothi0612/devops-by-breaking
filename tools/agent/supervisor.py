#!/usr/bin/env python3
"""Trusted Docker broker. This process and its Docker socket are never agent-mounted."""
import http.client
import json
import os
import socket
import socketserver
import struct
import sys
import threading
import time
import urllib.parse

MAX_OUTPUT = 1024 * 1024


class UnixHTTP(http.client.HTTPConnection):
    def __init__(self, timeout=10):
        super().__init__('localhost', timeout=timeout)

    def connect(self):
        self.sock = socket.socket(socket.AF_UNIX)
        self.sock.settimeout(self.timeout)
        self.sock.connect('/var/run/docker.sock')


class Docker:
    def request(self, method, path, body=None, timeout=10, raw=False):
        conn = UnixHTTP(timeout)
        payload = None if body is None else json.dumps(body).encode()
        try:
            conn.request(method, path, payload, {'Content-Type': 'application/json'})
            response = conn.getresponse()
            data = response.read(MAX_OUTPUT + 1)
            if len(data) > MAX_OUTPUT:
                raise RuntimeError('Docker response exceeded output limit')
            if response.status >= 400:
                raise RuntimeError('Docker %s: %s' % (response.status, data.decode(errors='replace')))
            return data if raw else (json.loads(data) if data else None)
        finally:
            conn.close()

    def create(self, name, config):
        return self.request('POST', '/containers/create?name=' + urllib.parse.quote(name), config)['Id']

    def remove(self, container):
        try:
            self.request('DELETE', '/containers/' + container + '?force=true&v=true')
            return True
        except (OSError, RuntimeError, http.client.HTTPException):
            return False  # Host label cleanup retries, but scoring must fail closed.

    def execute(self, container, command, timeout, user=None):
        extra = {"User": user} if user is not None else {}
        info = self.request('POST', '/containers/' + container + '/exec', {
            'AttachStdout': True, 'AttachStderr': True, 'Cmd': command, **extra})
        data = self.request('POST', '/exec/' + info['Id'] + '/start',
                            {'Detach': False, 'Tty': False}, timeout=timeout, raw=True)
        status = self.request('GET', '/exec/' + info['Id'] + '/json')
        if status.get('Running') or not isinstance(status.get('ExitCode'), int):
            raise RuntimeError('lab command did not finish')
        return {'exit_code': status['ExitCode'], 'output': demux(data)}


def demux(data):
    chunks = []
    while data:
        if len(data) < 8:
            raise RuntimeError('truncated Docker stream')
        size = struct.unpack('>I', data[4:8])[0]
        if len(data) < size + 8:
            raise RuntimeError('truncated Docker frame')
        chunks.append(data[8:8 + size])
        data = data[8 + size:]
    return b''.join(chunks).decode(errors='replace')


class Budget:
    def __init__(self, maximum, deadline):
        self.maximum, self.deadline = maximum, deadline
        self.used = 0
        self.exceeded = False
        self.closed = False
        self.lock = threading.Lock()

    def reserve(self):
        with self.lock:
            if self.closed or time.monotonic() >= self.deadline:
                raise RuntimeError('agent session closed or timed out')
            if self.used >= self.maximum:
                self.exceeded = True
                raise RuntimeError('command budget exceeded')
            self.used += 1


def agent_config(config):
    # Intentionally do not mount the workspace, repository or supervisor source.
    return {
        'Image': config['image'], 'User': '65534:65534',
        'WorkingDir': '/agent', 'Entrypoint': config['command'], 'Cmd': [],
        'Env': ['HOME=/tmp', 'DBB_TICKET=/agent/TICKET.md', 'PYTHONDONTWRITEBYTECODE=1'],
        'Labels': {'dbb.lab': config['lab'], 'dbb.agent': 'sandbox'},
        'HostConfig': {
            'Binds': [config['inputs'] + ':/agent:ro', config['rpc'] + ':/rpc:ro'],
            'NetworkMode': config['network'], 'ReadonlyRootfs': True,
            'CapDrop': ['ALL'], 'SecurityOpt': ['no-new-privileges:true'],
            'PidsLimit': 128, 'Memory': 512 * 1024 * 1024,
            'Tmpfs': {'/tmp': 'rw,nosuid,nodev,size=128m,mode=1777'},
        },
    }


class Broker:
    def __init__(self, docker, config, budget):
        self.docker, self.config, self.budget = docker, config, budget
        self.execution_lock = threading.Lock()
        self.failed = False
        self.tool = None

    def prepare(self):
        c = self.config
        if c['runtime'] in ('terraform', 'ansible'):
            image = c['terraform_image'] if c['runtime'] == 'terraform' else c['ansible_image']
            network = 'none' if c['runtime'] == 'terraform' else 'dbb-' + c['lab'] + '-net'
            self.tool = self.docker.create('dbb-' + c['lab'] + '-agent-tool', {
                'Image': image, 'Entrypoint': ['sh', '-c', 'exec sleep 2147483647'],
                'WorkingDir': '/work', 'User': c['uid'] + ':' + c['gid'],
                'Env': ['HOME=/tmp', 'USER=dbb', 'LOGNAME=dbb',
                        'ANSIBLE_HOST_KEY_CHECKING=False', 'ANSIBLE_NOCOLOR=1'],
                'Labels': {'dbb.lab': c['lab']},
                'HostConfig': {'Binds': [c['workspace'] + ':/work'], 'NetworkMode': network,
                               'PidsLimit': 128, 'Memory': 512 * 1024 * 1024},
            })
            self.docker.request('POST', '/containers/' + self.tool + '/start')
            if c['runtime'] == 'ansible':
                # OpenSSH requires a passwd entry even when numeric UID/GID are valid.
                # Only this fixed trusted initialization runs as root in the tool.
                result = self.docker.execute(self.tool, [
                    'sh', '-c',
                    'getent passwd "$1" >/dev/null || printf "dbb:x:%s:%s:Lab user:/tmp:/bin/sh\\n" "$1" "$2" >> /etc/passwd',
                    'sh', c['uid'], c['gid']], timeout=10, user='0')
                if result['exit_code'] != 0:
                    raise RuntimeError('could not initialize tool user')

    def handle(self, request):
        if not isinstance(request, dict) or set(request) != {'command'}:
            raise ValueError('only a command request is accepted')
        command = request['command']
        if not isinstance(command, str) or not command or len(command.encode()) > 64000:
            raise ValueError('command must be a nonempty string under 64 KiB')
        # Reserve atomically before execution; queued and failed commands count too.
        self.budget.reserve()
        with self.execution_lock:
            remaining = self.budget.deadline - time.monotonic()
            if self.budget.closed or remaining <= 0:
                raise RuntimeError('agent session closed or timed out')
            runtime, lab = self.config['runtime'], self.config['lab']
            if runtime == 'server':
                target, argv = 'dbb-' + lab + '-server', ['bash', '-lc', command]
            elif runtime == 'k8s':
                target, argv = 'dbb-' + lab + '-k3s', ['sh', '-c', command]
            else:
                target, argv = self.tool, ['sh', '-c', command]
            try:
                return self.docker.execute(target, argv, timeout=max(0.1, remaining))
            except (OSError, RuntimeError):
                self.failed = True
                raise


class Server(socketserver.ThreadingUnixStreamServer):
    daemon_threads = True
    request_queue_size = 128


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        self.connection.settimeout(5)
        try:
            data = self.rfile.readline(65537)
            if len(data) > 65536 or not data.endswith(b'\n'):
                raise ValueError('invalid request framing')
            result = self.server.broker.handle(json.loads(data))
        except (ValueError, OSError, RuntimeError) as error:
            result = {'exit_code': 2, 'error': str(error)}
        try:
            self.wfile.write(json.dumps(result).encode() + b'\n')
        except OSError:
            pass


def run(config):
    docker = Docker()
    start = time.monotonic()
    budget = Budget(config['max_commands'], start + config['timeout'])
    broker = Broker(docker, config, budget)
    agent = None
    server = None
    outcome = {'agent_exit_code': None, 'timed_out': False, 'broker_error': None}
    try:
        broker.prepare()
        server = Server('/rpc/broker.sock', Handler)
        server.broker = broker
        os.chmod('/rpc/broker.sock', 0o666)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        agent = docker.create('dbb-' + config['lab'] + '-agent', agent_config(config))
        docker.request('POST', '/containers/' + agent + '/start')
        while True:
            if time.monotonic() >= budget.deadline:
                outcome['timed_out'] = True
                break
            state = docker.request('GET', '/containers/' + agent + '/json')['State']
            if not state['Running']:
                outcome['agent_exit_code'] = state['ExitCode']
                break
            time.sleep(0.1)
    except Exception as error:
        outcome['broker_error'] = str(error)
    finally:
        # Destroy the sandbox (including detached/TERM-ignoring children) before scoring.
        with budget.lock:
            budget.closed = True
        if agent:
            try:
                logs = docker.request('GET', '/containers/' + agent + '/logs?stdout=true&stderr=true&tail=200', raw=True)
                outcome['agent_output'] = demux(logs)
            except (OSError, RuntimeError):
                outcome['agent_output'] = '[agent output unavailable or exceeds 1 MiB]'
            if not docker.remove(agent):
                outcome['broker_error'] = 'could not remove agent container'
        if server:
            server.shutdown()
            server.server_close()
        # An agent that leaves tool work outstanding has not finished a valid run.
        if not broker.execution_lock.acquire(timeout=2):
            outcome['broker_error'] = 'agent exited with an outstanding lab command'
        else:
            broker.execution_lock.release()
        if broker.tool:
            if not docker.remove(broker.tool):
                outcome['broker_error'] = 'could not remove tool container'
        outcome.update(commands_used=budget.used, budget_exceeded=budget.exceeded,
                       seconds=round(time.monotonic() - start, 3))
        if broker.failed:
            outcome['broker_error'] = outcome['broker_error'] or 'lab command transport failed'
        with open('/report/agent.json', 'w') as stream:
            json.dump(outcome, stream)
    return 0 if outcome['broker_error'] is None else 2


if __name__ == '__main__':
    with open('/config.json') as stream:
        config = json.load(stream)
    sys.exit(run(config))
