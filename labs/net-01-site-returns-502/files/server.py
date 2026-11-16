from http.server import BaseHTTPRequestHandler, HTTPServer

REQ_COUNT = 0

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        global REQ_COUNT
        REQ_COUNT += 1
        body = f"orders-backend: checkout ready req={REQ_COUNT}\n".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8081), Handler).serve_forever()
