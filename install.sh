#!/bin/sh
set -eu

REPO_ROOT=$(cd "$(dirname "$0")" && pwd)
DOCKER_IMAGE="status-dashboard:latest"
CONTAINER_NAME="status-dashboard"
NGINX_CONF_SRC="$REPO_ROOT/nginx/status-dashboard"
NGINX_CONF_DST="/etc/nginx/sites-available/status-dashboard"
ENV_FILE="$REPO_ROOT/.env"

die() {
  echo "Error: $*" >&2
  exit 1
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    die "This script must be run as root. Use sudo ./install.sh"
  fi
}

check_commands() {
  command -v docker >/dev/null 2>&1 || die "docker is not installed"
  command -v nginx >/dev/null 2>&1 || die "nginx is not installed"
}

load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    die ".env file not found in $REPO_ROOT"
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|\#*) continue ;;
      *=*)
        var=$(printf '%s' "$line" | cut -d= -f1)
        val=$(printf '%s' "$line" | cut -d= -f2-)
        eval "[ -z \"\${$var+x}\" ] && $var=\$val"
        ;;
    esac
  done < "$ENV_FILE"
}

check_env_vars() {
  if [ -z "${API_KEY:-}" ]; then
    die "API_KEY must be set in .env"
  fi
  PORT="${PORT:-5000}"
  VERSION="${VERSION:-1.0.0}"
}

build_image() {
  echo "Building Docker image..."
  docker build -t "$DOCKER_IMAGE" "$REPO_ROOT"
}

stop_remove_container() {
  if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME\$"; then
    echo "Stopping and removing existing container..."
    docker stop "$CONTAINER_NAME" || true
    docker rm "$CONTAINER_NAME" || true
  fi
}

run_container() {
  echo "Running new container..."
  docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -e PORT="$PORT" \
    -e VERSION="$VERSION" \
    -e API_KEY="$API_KEY" \
    -p 127.0.0.1:5000:5000 \
    "$DOCKER_IMAGE"
}

configure_nginx() {
  echo "Configuring nginx..."
  [ -f "$NGINX_CONF_SRC" ] || die "nginx config $NGINX_CONF_SRC not found"
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

print_success() {
  IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  if [ -z "$IP" ]; then
    IP=$(hostname -i 2>/dev/null | awk '{print $1}')
  fi
  echo "------------------------------------------------------------"
  echo "Status Dashboard is up and reachable at: http://$IP/"
  echo "------------------------------------------------------------"
}

main() {
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

main "$@"