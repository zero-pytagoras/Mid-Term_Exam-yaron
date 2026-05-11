import os
from flask import Flask, jsonify, redirect, request, abort
import socket

PORT = int(os.environ.get("PORT", 5000))
VERSION = os.environ.get("VERSION", "1.0.0")
API_KEY = os.environ.get("API_KEY")
if not API_KEY:
    raise RuntimeError("API_KEY environment variable must be set")

app = Flask(__name__)

@app.route("/")
def index():
    return '''
    <html>
      <head><title>Status Dashboard</title></head>
      <body>
        <h1>Status Dashboard</h1>
        <p>Internal status dashboard for Acme Internal Tools Ltd.</p>
        <button onclick="fetchStatus()">Check Status</button>
        <pre id="result"></pre>
        <script>
          function fetchStatus() {
            fetch('/api/v1/status').then(r => r.json()).then(j => {
              document.getElementById('result').textContent = JSON.stringify(j, null, 2);
            });
          }
        </script>
      </body>
    </html>
    '''

@app.route("/api/status")
def api_status():
    return redirect("/api/v1/status", code=302)

@app.route("/api/v1/status")
def api_v1_status():
    return jsonify({
        "status": "ok",
        "hostname": socket.gethostname(),
        "version": VERSION
    })

@app.route("/api/v1/secret")
def api_v1_secret():
    key = request.headers.get("X-API-Key")
    if key != API_KEY:
        abort(401)
    return jsonify({"message": "you found the secret"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)