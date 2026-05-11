Mid-Term Practical Exam — Junior DevOps Engineer
1. Scenario
You are a junior DevOps engineer at Acme Internal Tools Ltd. The operations team needs a small internal Status Dashboard service deployed on a Linux host. Your job, in a single shift, is to build the service and ship it end-to-end the way a real production change would go: containerized application, host-level reverse proxy, a repeatable installation script, and a clean pull-request history on GitHub.

You will be graded on the working result and on the way you got there (commits, branches, PRs).

2. Duration and Environment
Time allowed: 8 hours, in 2 separate sittings.
Lab VM: a Ubuntu Linux machine prepared for you. The following are already installed and on PATH:
docker (your user is in the docker group — no sudo needed for docker commands)
git
python3 and pip
poetry (used to manage Python dependencies for this project)
nginx (installed and stopped; you decide when to start it)
curl, jq, vim, nano
GitHub: you have a personal account and a personal access token preconfigured for git push. You will create a new public repository for this exam.
Network: internet access is available for pip, Docker Hub, and GitHub.
3. The Application You Will Build
Build a Python Flask service called status-dashboard that exposes the following:

Method	Path	Behavior
GET	/	A static HTML page showing the title "Status Dashboard", a short blurb, and a button that calls /api/v1/status and renders the result.
GET	/api/status	Redirects to latest version of api which will be v1 -> /api/v1/status
GET	/api/v1/status	JSON: {"status": "ok", "hostname": "<container hostname>", "version": "<VERSION env var>"}
GET	/api/v1/secret	Requires request header X-API-Key: <API_KEY env var>. Returns 401 Unauthorized if missing or wrong; returns a small JSON payload (e.g. {"message": "you found the secret"}) when the header matches.
Requirements:

The Flask app must read three environment variables: PORT (default 5000), VERSION (e.g. "1.0.0"), and API_KEY (no default — the app must refuse to start if it is not set).
A pyproject.toml file with pinned versions.
The static HTML may live inline in the Flask code or in a templates/ folder — your choice.
The code must run as python app.py from inside the container.
4. Containerization (Docker)
Write a Dockerfile for the Flask app:

Base image python:3.12-slim.
Create and use a non-root user to run the application.
Set a WORKDIR, COPY only what you need, install dependencies with poetry.
EXPOSE the application port.
The default CMD runs the Flask app.
Provide a .dockerignore that excludes __pycache__, .git, *.pyc, and any local virtual-env folders.
The image must build with:

docker build -t status-dashboard .
The container must run with the env vars described in §3, and its port must be published only on the loopback interface (127.0.0.1:5000) — not on 0.0.0.0. The outside world reaches the app through nginx, not directly through Docker.

nginx itself runs on the host, not in a container.

5. nginx (Host Service)
Configure host nginx as a reverse proxy in front of the Docker container.

Place a site config at /etc/nginx/sites-available/status-dashboard and enable it via a symlink to /etc/nginx/sites-enabled/status-dashboard.
The default nginx site (/etc/nginx/sites-enabled/default) must be disabled.
The site listens on port 80, server_name _; is acceptable.
All requests to / and /api/ are proxied to http://127.0.0.1:5000.
The following proxy headers must be set: Host, X-Real-IP, X-Forwarded-For, X-Forwarded-Proto.
Validate the configuration with nginx -t before reloading.
nginx must be enabled to start at boot (systemctl enable nginx).
6. Install Script
Write a Bash script install.sh at the repository root that performs a full installation on a freshly provisioned VM. When the instructor clones your repository on a clean machine and runs:

sudo ./install.sh
…the service must be up and reachable at http://<vm-ip>/.

The script must:

Begin with #!/usr/bin/env bash and set -euo pipefail.
Refuse to run if not invoked as root (or via sudo) and exit with a clear error message.
Build the Docker image from the repository.
Stop and remove any previously running container named status-dashboard so the script is safe to re-run (idempotent).
Run the new container detached, with --restart unless-stopped, with the required env vars (PORT, VERSION, API_KEY), and with the port published to 127.0.0.1:5000.
Install the nginx site config from the repository to /etc/nginx/sites-available/, create the symlink in sites-enabled/, remove the default site, run nginx -t, and reload nginx.
Print a clear success line at the end, including the URL the service can be reached at.
You are free to ship a small .env.example and read values from it, or to accept them as arguments / environment variables — but the script must run successfully with sensible defaults if the instructor does not supply anything beyond API_KEY.

7. Git and Pull-Request Workflow
You will create your own public GitHub repository for this exam (for example, acme-status-dashboard). The graded history of the repository must look like this:

The default branch is main.

Direct pushes to main are not allowed. All work reaches main through pull requests.

Five feature branches, each merged into main via a separate pull request, in this order:

feat/flask-app — the Flask source code and pyproject.toml.
feat/dockerfile — the Dockerfile and .dockerignore.
feat/nginx-config — the nginx site config file.
feat/install-script — the install.sh script.
feat/readme — a README.md with run instructions.
Each pull request must have:

A descriptive title (e.g. Add Flask status dashboard service, not update).
A body that briefly describes what changed and how to verify it manually.
Be merged into main before you start the next branch (or, if you prefer, rebased onto the latest main before merging).
At submission time, all five PRs must be merged.

8. Submission
When you are done:

Make sure all five pull requests are merged into main.
Make sure main contains the working code, Dockerfile, nginx config, install.sh, and README.md.
Email the GitHub repository URL to the instructor.
The instructor will grade by cloning your repository on a fresh identical lab VM and running:

git clone <your-repo-url>
cd <repo>
sudo API_KEY=letmein ./install.sh
curl -s http://localhost/api/status | jq .
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/api/secret
curl -s -H "X-API-Key: letmein" http://localhost/api/secret | jq .
If all commands return the expected results and your git history matches the rules, you get 100.

Good luck.
