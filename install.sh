#!/bin/bash
# missing headser explain
set -eu

function main() { #no control in main function
  require_root
  check_commands
  load_env
  check_env_vars
  build_image
  stop_remove_container
  run_container
  configure_nginx
  print_success
}

function die() { # bad naming
  echo "Error: $*" >&2
  exit 1
}

function require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    die "This script must be run as root. Use sudo ./install.sh"
  fi
}

function check_commands() {
  command -v docker >/dev/null 2>&1 || die "docker is not installed"
  command -v nginx >/dev/null 2>&1 || die "nginx is not installed"
}

function load_env() {
  REPO_ROOT=$(cd "$(dirname "$0")" && pwd)
  ENV_FILE="$REPO_ROOT/.env"
  # Only load from .env if not set in environment
  # (API_KEY, PORT, VERSION)
  if [[ -f "$ENV_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in
        ''|\#*) continue ;;
        *=*)
          var=$(printf '%s' "$line" | cut -d= -f1)
          val=$(printf '%s' "$line" | cut -d= -f2-)
          # Only set if not already set in environment
          if [[ -z "${!var:-}" ]]; then
            export "$var=$val"
          fi
          ;;
      esac
    done < "$ENV_FILE"
  fi
  # Set defaults for PORT and VERSION if still not set
  export PORT="${PORT:-5000}"
  export VERSION="${VERSION:-1.0.0}"
}

function check_env_vars() {
  if [[ -z "${API_KEY:-}" ]]; then
    die "API_KEY must be set as an environment variable or in .env"
  fi
}

function build_image() {
  echo "Building Docker image..."
  docker build -t "status-dashboard:latest" "$(cd "$(dirname "$0")" && pwd)"
}

function stop_remove_container() {
  if docker ps -a --format '{{.Names}}' | grep -q "^status-dashboard\$"; then
    echo "Stopping and removing existing container..."
    docker stop "status-dashboard" || true
    docker rm "status-dashboard" || true
  fi
}

function run_container() {
  echo "Running new container..."
  docker run -d \
    --name "status-dashboard" \
    --restart unless-stopped \
    -e PORT="$PORT" \
    -e VERSION="$VERSION" \
    -e API_KEY="$API_KEY" \
    -p 127.0.0.1:5000:5000 \
    "status-dashboard:latest"
}

function configure_nginx() {
  REPO_ROOT=$(cd "$(dirname "$0")" && pwd)
  NGINX_CONF_SRC="$REPO_ROOT/nginx/status-dashboard"
  NGINX_CONF_DST="/etc/nginx/sites-available/status-dashboard"
  echo "Configuring nginx..."
  [[ -f "$NGINX_CONF_SRC" ]] || die "nginx config $NGINX_CONF_SRC not found"
  cp "$NGINX_CONF_SRC" "$NGINX_CONF_DST"
  ln -sf "$NGINX_CONF_DST" /etc/nginx/sites-enabled/status-dashboard
  rm -f /etc/nginx/sites-enabled/default

  nginx -t
  if command -v systemctl >/dev/null 2>&1; then
    systemctl reload nginx
  else
    service nginx reload
  fi
}

function print_success() {
  IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  if [[ -z "$IP" ]]; then
    IP=$(hostname -i 2>/dev/null | awk '{print $1}')
  fi
  echo "------------------------------------------------------------"
  echo "Status Dashboard is up and reachable at: http://$IP/"
  echo "------------------------------------------------------------"
}

main "$@"
