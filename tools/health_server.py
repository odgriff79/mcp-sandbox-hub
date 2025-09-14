from http.server import BaseHTTPRequestHandler, HTTPServer
import json, time

class H(BaseHTTPRequestHandler):
    def _send_json(self, payload, code=200):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path in ("/", "/health"):
            self._send_json({"status": "ok", "ts": time.time()})
        else:
            self._send_json({"error": "not found", "path": self.path}, code=404)

if __name__ == "__main__":
    # Bind on 0.0.0.0 so Codespaces can forward
    HTTPServer(("0.0.0.0", 8765), H).serve_forever()
