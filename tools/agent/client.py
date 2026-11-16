#!/usr/bin/env python3
"""The agent's only lab tool. No host paths, credentials or Docker socket."""
import json
import socket
import sys


def main():
    args = sys.argv[1:]
    if len(args) < 3 or args[:2] != ['exec', '--']:
        print('usage: ./dbb exec -- <command>', file=sys.stderr)
        return 2
    payload = json.dumps({'command': ' '.join(args[2:])}).encode() + b'\n'
    if len(payload) > 65536:
        print('command exceeds 64 KiB', file=sys.stderr)
        return 2
    with socket.socket(socket.AF_UNIX) as conn:
        conn.connect('/rpc/broker.sock')
        conn.sendall(payload)
        data = bytearray()
        while b'\n' not in data:
            chunk = conn.recv(65536)
            if not chunk:
                raise RuntimeError('broker disconnected')
            data.extend(chunk)
            if len(data) > 8 * 1024 * 1024:
                raise RuntimeError('broker response too large')
    result = json.loads(data)
    sys.stdout.write(result.get('output', ''))
    if result.get('error'):
        print(result['error'], file=sys.stderr)
    return result['exit_code']


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError, RuntimeError) as error:
        print('agent tool: ' + str(error), file=sys.stderr)
        sys.exit(2)
