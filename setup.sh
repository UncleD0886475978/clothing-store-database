#!/usr/bin/env bash
# setup.sh — clothing-store-database (Threads & Co. apparel retail)
# MySQL 8 store database: categories, products, variants, inventory,
# customers, orders, payments and promotions — seeded with sample
# Threads & Co. catalog, stock, customers and orders.
#
# BOOTSTRAP script: on a fresh Ubuntu/Debian VM it INSTALLS its own
# prerequisites (base tools via apt, Docker via get.docker.com, kubectl via
# the official dl.k8s.io binary) instead of just checking for them.
#
# Usage:
#   ./setup.sh          # same as: ./setup.sh docker
#   ./setup.sh docker   # run MySQL with Docker Compose + load schema/seed + reports
#   ./setup.sh k8s      # run MySQL on Kubernetes (StatefulSet) + load schema/seed + reports
#   ./setup.sh down     # tear down (Docker Compose and/or Kubernetes; data kept)
#
# One-liner (fresh VM):
#   curl -fsSL https://raw.githubusercontent.com/UncleD0886475978/clothing-store-database/main/setup.sh | bash
set -e

REPO_NAME="clothing-store-database"
REPO="clothing-store-database"
OWNER="UncleD0886475978"
REPO_URL="https://github.com/UncleD0886475978/${REPO_NAME}.git"
RUN_ONELINE="curl -fsSL https://raw.githubusercontent.com/${OWNER}/${REPO}/main/setup.sh | bash"
MODE="${1:-docker}"

# ---------- pretty output ----------
if [ -t 1 ]; then
  BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
else
  BOLD=''; GREEN=''; CYAN=''; YELLOW=''; RED=''; NC=''
fi
step() { printf "\n${BOLD}${CYAN}==>${NC} ${BOLD}%s${NC}\n" "$*"; }
info() { printf "    %s\n" "$*"; }
ok()   { printf "${GREEN}  ✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}  ! %s${NC}\n" "$*"; }
die()  { printf "${RED}  ✗ %s${NC}\n" "$*" >&2; exit 1; }

# ---------- defaults (must match .env.example / k8s secret example) ----------
DB_NAME="${DB_NAME:-threads_store}"
DB_USER="${DB_USER:-threads}"
DB_PASSWORD="${DB_PASSWORD:-threads_change_me}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-threads_root_change_me}"
DB_PORT="${DB_PORT:-3306}"
APP="clothing-store-mysql"
NS="threads"

load_env() { if [ -f .env ]; then set -a; . ./.env; set +a; fi; }

# ---------- Step 1: platform check + base bootstrap ----------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "ERROR: this script needs root or sudo to install packages."
    exit 1
  fi
fi
APT=0
if [ "$(uname -s)" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then APT=1; fi
INSTALLED=""
APT_UPDATED=""
note_installed() { INSTALLED="${INSTALLED} $1"; }
apt_update_once() {
  if [ -z "${APT_UPDATED}" ]; then $SUDO apt-get update -y; APT_UPDATED=1; fi
}
apt_install() {
  apt_update_once
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$@"
}

bootstrap_base() {
  step "Step 1: Platform check + base bootstrap (git, curl, ca-certificates, gnupg)"
  if [ "${APT}" -ne 1 ]; then
    warn "Non-apt platform detected ($(uname -s)). This bootstrap script auto-installs only on Ubuntu/Debian."
    info "Install these manually, then re-run: git, curl, ca-certificates, gnupg,"
    info "Docker (https://docs.docker.com/get-docker/) and, for k8s mode, kubectl"
    info "(https://kubernetes.io/docs/tasks/tools/)."
    exit 1
  fi
  BASE_PKGS=""
  command -v git >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} git"
  command -v curl >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} curl"
  [ -f /etc/ssl/certs/ca-certificates.crt ] || BASE_PKGS="${BASE_PKGS} ca-certificates"
  command -v gpg >/dev/null 2>&1 || BASE_PKGS="${BASE_PKGS} gnupg"
  if [ -n "${BASE_PKGS}" ]; then
    info "Installing base tools:${BASE_PKGS}"
    # shellcheck disable=SC2086
    apt_install ${BASE_PKGS}
    note_installed "${BASE_PKGS}"
  else
    ok "Base tools already present (git, curl, ca-certificates, gnupg)"
  fi
}

# ---------- Step 2: locate or clone the repo ----------
locate_repo() {
  step "Step 2: Locate the repo"
  if [ -f "$0" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  else
    SCRIPT_DIR="$PWD"
  fi
  if [ -f "${SCRIPT_DIR}/docker-compose.yml" ]; then
    REPO_DIR="$SCRIPT_DIR"
    info "Using repo checkout at: $REPO_DIR"
  elif [ -f "$PWD/docker-compose.yml" ]; then
    REPO_DIR="$PWD"
    info "Using repo checkout at: $REPO_DIR"
  else
    REPO_DIR="$HOME/repos/$REPO_NAME"
    if [ -d "$REPO_DIR/.git" ]; then
      info "Existing checkout found — pulling latest..."
      git -C "$REPO_DIR" pull --ff-only || true
    else
      if ! command -v git >/dev/null 2>&1; then
        die "git not found. Install git first: https://git-scm.com/downloads"
      fi
      info "Cloning $REPO_URL into $REPO_DIR ..."
      mkdir -p "$HOME/repos"
      git clone "$REPO_URL" "$REPO_DIR"
    fi
  fi
  cd "$REPO_DIR"
}

# ---------- Step 3: bootstrap Docker / kubectl ----------
DOCKER="docker"
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    info "docker: already present ($(docker --version))"
  elif [ "${APT}" -eq 1 ]; then
    info "Installing Docker Engine via the official get.docker.com script..."
    curl -fsSL https://get.docker.com | $SUDO sh
    note_installed "docker"
  else
    return 1
  fi
  if ! docker info >/dev/null 2>&1 && ! $SUDO docker info >/dev/null 2>&1; then
    info "Starting the Docker daemon..."
    $SUDO systemctl enable --now docker 2>/dev/null || $SUDO service docker start 2>/dev/null || true
    for _i in $(seq 1 15); do
      if docker info >/dev/null 2>&1 || $SUDO docker info >/dev/null 2>&1; then break; fi
      sleep 2
    done
  fi
  if docker info >/dev/null 2>&1; then
    DOCKER="docker"
  elif $SUDO docker info >/dev/null 2>&1; then
    DOCKER="sudo docker"
    if [ "$(id -u)" -ne 0 ]; then
      $SUDO usermod -aG docker "$USER" 2>/dev/null || true
      info "NOTE: you were added to the 'docker' group (applies at next login); this run uses 'sudo docker'."
    fi
  else
    die "Docker is installed but the daemon could not be started. On a VM: sudo systemctl start docker"
  fi
  ok "Docker daemon OK (using: ${DOCKER})"
}

need_docker() {
  step "Step 3: Bootstrap Docker"
  install_docker
  # shellcheck disable=SC2086
  if ! ${DOCKER} compose version >/dev/null 2>&1; then
    die "'docker compose' (v2 plugin) is not available. The get.docker.com installer normally includes it; on Debian/Ubuntu you can also run: sudo apt-get install -y docker-compose-plugin"
  fi
  ok "Docker + Compose found"
}

install_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    info "kubectl: already present ($(kubectl version --client --short 2>/dev/null || kubectl version --client))"
  elif [ "${APT}" -eq 1 ]; then
    info "Installing kubectl from the official dl.k8s.io binary..."
    KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
    curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl"
    $SUDO install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
    note_installed "kubectl"
  else
    return 1
  fi
}

need_kubectl() {
  step "Step 3: Bootstrap kubectl + check Kubernetes access"
  if ! install_kubectl; then
    die "could not auto-install kubectl on this platform. Install it manually: https://kubernetes.io/docs/tasks/tools/"
  fi
  if ! kubectl cluster-info >/dev/null 2>&1; then
    die "kubectl cannot reach a cluster. Start minikube / kind / Docker Desktop Kubernetes, or set your kubeconfig, then re-run. Easy local cluster: https://minikube.sigs.k8s.io/docs/start/"
  fi
  ok "kubectl connected to a cluster"
}

print_summary() {
  cat <<EOF

=================== BOOTSTRAP SUMMARY ===================
Installed during this run:${INSTALLED:- (nothing — all tools were already present)}
Working copy: ${REPO_DIR:-$PWD}
Next time, set up from scratch on any fresh Ubuntu VM with one line:
  ${RUN_ONELINE}
=========================================================
EOF
}

# ---------- report queries (shared by docker + k8s modes) ----------
REPORT_SQL="
SELECT '--- (a) Total stock value ---' AS report;
SELECT sum(i.quantity_on_hand * v.price) AS stock_value
FROM inventory i
JOIN product_variants v ON v.id = i.variant_id;

SELECT '--- (b) Sales by category ---' AS report;
SELECT c.name AS category, sum(oi.quantity * oi.unit_price) AS sales
FROM order_items oi
JOIN product_variants v ON v.id = oi.variant_id
JOIN products p ON p.id = v.product_id
JOIN categories c ON c.id = p.category_id
GROUP BY c.name
ORDER BY sales DESC;
"

do_down() {
  step "Tearing down MySQL (Threads & Co.)"
  # Pick a working docker invocation without installing anything.
  DOCKER="docker"
  if ! docker info >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1 && sudo docker info >/dev/null 2>&1; then
    DOCKER="sudo docker"
  fi
  if command -v docker >/dev/null 2>&1 && ${DOCKER} compose version >/dev/null 2>&1 && [ -f docker-compose.yml ]; then
    load_env
    # shellcheck disable=SC2086
    ${DOCKER} compose down || true
    ok "Docker Compose stack stopped (data volume kept — add -v yourself if you really want it gone)"
  fi
  if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
    kubectl delete -f k8s/service.yaml -f k8s/statefulset.yaml -f k8s/pvc.yaml --ignore-not-found=true || true
    kubectl delete -f k8s/secret.yaml --ignore-not-found=true || true
    ok "Kubernetes resources deleted (namespace '${NS}' kept — delete it yourself if you really want it gone)"
  fi
  echo
  info "Done."
}

run_docker() {
  need_docker
  step "Preparing configuration"
  if [ ! -f .env ]; then cp .env.example .env; ok "Created .env from .env.example (edit it to change the passwords)"; else ok ".env already exists — using it"; fi
  load_env
  step "Starting MySQL with Docker Compose"
  # shellcheck disable=SC2086
  ${DOCKER} compose up -d
  step "Waiting for MySQL to accept connections"
  for i in $(seq 1 90); do
    # shellcheck disable=SC2086
    if ${DOCKER} compose exec -T db sh -c 'mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" --silent' >/dev/null 2>&1; then ok "Database is ready"; break; fi
    if [ "$i" = "90" ]; then die "Database did not become ready in time. Check logs: ${DOCKER} compose logs db"; fi
    sleep 2
  done
  step "Loading schema (schema.sql)"
  # shellcheck disable=SC2086
  ${DOCKER} compose exec -T db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < schema.sql
  ok "Schema loaded"
  step "Loading seed data — sample Threads & Co. catalog, stock, customers, orders (seed.sql)"
  # shellcheck disable=SC2086
  ${DOCKER} compose exec -T db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < seed.sql
  ok "Seed data loaded"
  step "Running report queries"
  # shellcheck disable=SC2086
  ${DOCKER} compose exec -T db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$REPORT_SQL"
  ok "Reports ran clean"
  print_docker_info
  print_summary
}

print_docker_info() {
  step "MySQL is UP — connection info"
  info "Host:          localhost"
  info "Port:          $DB_PORT"
  info "Database:      $DB_NAME"
  info "User:          $DB_USER"
  info "Password:      $DB_PASSWORD   (from .env — change it for anything real)"
  info "Root password: $DB_ROOT_PASSWORD   (from .env)"
  info "Connect:       mysql -h 127.0.0.1 -P $DB_PORT -u $DB_USER -p $DB_NAME"
  info "Shell:         ${DOCKER} compose exec db mysql -u$DB_USER -p $DB_NAME"
  echo
  info "Logs:  ${DOCKER} compose logs -f db"
  info "Stop:  ./setup.sh down        (or: ${DOCKER} compose down)"
}

run_k8s() {
  need_kubectl
  load_env
  step "Preparing Kubernetes manifests"
  if [ ! -f k8s/secret.yaml ]; then cp k8s/secret.example.yaml k8s/secret.yaml; ok "Created k8s/secret.yaml from the example (edit it to change the passwords)"; fi
  step "Applying manifests (namespace, secret, storage, StatefulSet, service)"
  kubectl apply -f k8s/namespace.yaml
  kubectl apply -f k8s/secret.yaml
  kubectl apply -f k8s/pvc.yaml
  kubectl apply -f k8s/statefulset.yaml
  kubectl apply -f k8s/service.yaml
  step "Waiting for the pod to be ready"
  kubectl -n "$NS" rollout status statefulset/"$APP" --timeout=420s
  ok "Pod is ready"
  step "Loading schema (schema.sql)"
  kubectl -n "$NS" exec -i statefulset/"$APP" -- mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < schema.sql
  ok "Schema loaded"
  step "Loading seed data — sample Threads & Co. catalog, stock, customers, orders (seed.sql)"
  kubectl -n "$NS" exec -i statefulset/"$APP" -- mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < seed.sql
  ok "Seed data loaded"
  step "Running report queries"
  kubectl -n "$NS" exec statefulset/"$APP" -- mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$REPORT_SQL"
  ok "Reports ran clean"
  step "MySQL is UP on Kubernetes — how to connect"
  info "Port-forward (run this, leave it open):"
  info "  kubectl -n $NS port-forward svc/$APP 3306:3306"
  info "Then connect from another terminal:"
  info "  mysql -h 127.0.0.1 -P 3306 -u $DB_USER -p $DB_NAME"
  echo
  info "Logs:  kubectl -n $NS logs statefulset/$APP -f"
  info "Stop:  ./setup.sh down"
  print_summary
}

# ---------- main ----------
case "$MODE" in
  docker)
    bootstrap_base
    locate_repo
    run_docker
    ;;
  k8s)
    bootstrap_base
    locate_repo
    run_k8s
    ;;
  down)
    if [ -f "$0" ]; then cd "$(dirname "$0")"; fi
    do_down
    ;;
  *) echo "Usage: ./setup.sh [docker|k8s|down]" >&2; exit 1 ;;
esac
