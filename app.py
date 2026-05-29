import os
from flask import Flask, jsonify, redirect, request, abort
import socket

PORT = int(os.environ.get("PORT", 5000)) # what is the difference between os.environ.get() and os.environ['ENV_NAME']  ?
VERSION = os.environ.get("VERSION", "1.0.0")
API_KEY = os.environ.get("API_KEY")
if not API_KEY:
    raise RuntimeError("API_KEY environment variable must be set")

app = Flask(__name__)

@app.route("/")
def index():
    return '''
    <html>
      <head>
        <title>Status Dashboard</title>
        <style>
          body {
            background: #f4f6fa;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            font-family: Arial, sans-serif;
          }
          .acme-logo {
            position: absolute;
            top: 24px;
            left: 32px;
            font-weight: bold;
            font-size: 1.5em;
            color: #e74c3c;
            letter-spacing: 2px;
            font-family: 'Segoe UI', Arial, sans-serif;
          }
          h1 {
            color: #2c3e50;
            margin-bottom: 0.5em;
          }
          p {
            color: #34495e;
            margin-bottom: 1.5em;
          }
          button {
            background: #3498db;
            color: #fff;
            border: none;
            padding: 0.75em 1.5em;
            border-radius: 4px;
            font-size: 1em;
            cursor: pointer;
            margin-bottom: 1em;
            transition: background 0.2s;
          }
          button:hover {
            background: #217dbb;
          }
          pre {
            background: #ecf0f1;
            color: #2c3e50;
            padding: 1em;
            border-radius: 4px;
            width: 320px;
            text-align: left;
            box-shadow: 0 2px 8px rgba(44,62,80,0.05);
          }
        </style>
      </head>
      <body>
        <div class="acme-logo">ACME</div>
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
