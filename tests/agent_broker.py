"""No Docker required: test trust boundary, concurrent budgets and scoring."""
import concurrent.futures
import pathlib
import sys
import time
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / 'tools' / 'agent'))
from supervisor import Budget, Broker, Docker, agent_config, demux
from manage import eligible, report


class AgentTests(unittest.TestCase):
    def test_concurrent_budget(self):
        budget = Budget(3, time.monotonic() + 30)
        def attempt(_):
            try:
                budget.reserve()
                return True
            except RuntimeError:
                return False
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as pool:
            self.assertEqual(sum(pool.map(attempt, range(100))), 3)
        self.assertEqual(budget.used, 3)
        self.assertTrue(budget.exceeded)

    def test_expired_and_closed(self):
        for deadline, closed in [(time.monotonic() - 1, False), (time.monotonic() + 30, True)]:
            budget = Budget(10, deadline)
            budget.closed = closed
            with self.assertRaises(RuntimeError):
                budget.reserve()
            self.assertEqual(budget.used, 0)

    def test_mount_boundary(self):
        config = agent_config(dict(image='python@sha256:abc', command=['sh'],
                                   lab='lnx-01', inputs='/stage/inputs', rpc='rpc-volume', network='none'))
        self.assertEqual(config['HostConfig']['Binds'], ['/stage/inputs:/agent:ro', 'rpc-volume:/rpc:ro'])
        self.assertEqual(config['User'], '65534:65534')
        self.assertTrue(config['HostConfig']['ReadonlyRootfs'])
        self.assertEqual(config['HostConfig']['CapDrop'], ['ALL'])
        self.assertNotIn('Privileged', config['HostConfig'])
        self.assertEqual(config['HostConfig']['NetworkMode'], 'none')

    def test_request_schema(self):
        budget = Budget(10, time.monotonic() + 30)
        broker = Broker(None, {}, budget)
        for request in [[], {}, {'command': ''}, {'command': []}, {'command': 'x' * 65536},
                        {'command': 'true', 'container': 'host'}]:
            with self.assertRaises(ValueError):
                broker.handle(request)
        self.assertEqual(budget.used, 0)

    def test_routes_only_to_lab(self):
        class FakeDocker:
            def execute(self, target, command, timeout):
                self.target, self.command = target, command
                return {'exit_code': 0, 'output': 'ok'}
        docker = FakeDocker()
        broker = Broker(docker, dict(runtime='server', lab='lnx-01'), Budget(1, time.monotonic() + 30))
        command = 'printf "$(cat /etc/hostname)"; echo literal'
        self.assertEqual(broker.handle({'command': command})['output'], 'ok')
        self.assertEqual(docker.target, 'dbb-lnx-01-server')
        self.assertEqual(docker.command, ['bash', '-lc', command])

    def test_ansible_tool_user_initialization(self):
        class FakeDocker:
            def create(self, name, config):
                self.config = config
                return 'tool-id'
            def request(self, *args):
                pass
            def execute(self, container, command, timeout, user=None):
                self.init = (container, command, user)
                return {'exit_code': 0, 'output': ''}
        docker = FakeDocker()
        broker = Broker(docker, dict(runtime='ansible', lab='ans-01',
                        ansible_image='ansible-image', workspace='/workspace/ans-01',
                        uid='501', gid='20'), Budget(1, time.monotonic() + 30))
        broker.prepare()
        self.assertEqual(docker.config['User'], '501:20')
        self.assertEqual(docker.config['HostConfig']['Binds'], ['/workspace/ans-01:/work'])
        self.assertEqual(docker.init[0], 'tool-id')
        self.assertEqual(docker.init[1][-2:], ['501', '20'])
        self.assertEqual(docker.init[2], '0')

    def test_failure_cannot_be_pass(self):
        ok = dict(agent_exit_code=0, timed_out=False, budget_exceeded=False, broker_error=None)
        for key, value in [('agent_exit_code', 9), ('timed_out', True),
                           ('budget_exceeded', True), ('broker_error', 'transport')]:
            bad = dict(ok, **{key: value})
            self.assertFalse(eligible(bad))
            self.assertFalse(report(bad, 'test-01', 30, 0, 'PASS\tgood\n')['passed'])
        for rc in [1, 2, None]:
            result = report(ok, 'test-01', 30, rc, 'PASS\tone\nFAIL\ttwo\n')
            self.assertFalse(result['passed'])
            self.assertEqual(result['check_exit_code'], rc)
        self.assertFalse(report(ok, 'test-01', 30, 0, '')['passed'])
        self.assertTrue(report(ok, 'test-01', 30, 0, 'PASS\tgood\n')['passed'])

    def test_cleanup_reports_failure(self):
        docker = Docker()
        docker.request = lambda *args: None
        self.assertTrue(docker.remove('agent'))
        def fail(*args):
            raise RuntimeError('daemon refused removal')
        docker.request = fail
        self.assertFalse(docker.remove('agent'))

    def test_docker_output_frames(self):
        self.assertEqual(demux(b'\x01\x00\x00\x00\x00\x00\x00\x02ok'), 'ok')
        with self.assertRaises(RuntimeError):
            demux(b'short')


if __name__ == '__main__':
    unittest.main()
