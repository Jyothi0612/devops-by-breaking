import socket
import sys

clients = []
try:
    for _ in range(96):
        client = socket.create_connection(("127.0.0.1", 8080), timeout=2)
        clients.append(client)
        reply = b""
        while len(reply) < 6:
            chunk = client.recv(6 - len(reply))
            if not chunk:
                break
            reply += chunk
        if reply != b"ready\n":
            raise RuntimeError("unexpected response")
    print("PASS: 96 simultaneous connections received ready")
except (OSError, RuntimeError) as exc:
    print("FAIL: only %d of 96 connections received ready (%s)" % (len(clients) - 1, exc))
    sys.exit(1)
finally:
    for client in clients:
        client.close()
