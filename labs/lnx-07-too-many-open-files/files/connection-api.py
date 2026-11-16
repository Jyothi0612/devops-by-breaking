import errno
import socket
import threading
import time


def serve(client):
    with client:
        client.sendall(b"ready\n")
        client.recv(1)


listener = socket.socket()
listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
listener.bind(("127.0.0.1", 8080))
listener.listen(128)
print("connection-api listening on 127.0.0.1:8080", flush=True)
while True:
    try:
        client, _ = listener.accept()
    except OSError as exc:
        if exc.errno != errno.EMFILE:
            raise
        print("accept failed: Too many open files", flush=True)
        time.sleep(0.2)
        continue
    threading.Thread(target=serve, args=(client,), daemon=True).start()
