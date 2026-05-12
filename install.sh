#!/usr/bin/env bash
# Devbox bootstrap — run as root on a fresh Ubuntu server.
# Usage: bash install.sh

set -euo pipefail

DEVBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ASDF_VERSION="0.19.0"
DOCTL_VERSION="1.158.0"
GO_VERSION="1.26.3"
CADDY_VERSION="2.11.2"

info()  { echo "[devbox] $*"; }
die()   { echo "[devbox] ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root (sudo -i first)"

# ── Symlinks ──────────────────────────────────────────────────────────────────

info "Creating symlinks..."

symlink() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    info "  Backing up existing $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sfn "$src" "$dst"
  info "  $dst -> $src"
}

symlink "$DEVBOX_DIR/AGENTS.md"              "$HOME/CLAUDE.md"
symlink "$DEVBOX_DIR/AGENTS.md"              "$HOME/.claude/CLAUDE.md"
symlink "$DEVBOX_DIR/home/bash_aliases"      "$HOME/.bash_aliases"
symlink "$DEVBOX_DIR/home/tool-versions"     "$HOME/.tool-versions"
symlink "$DEVBOX_DIR/claude/settings.json"   "$HOME/.claude/settings.json"
symlink "$DEVBOX_DIR/skills"                 "$HOME/.agents/skills"
symlink "$DEVBOX_DIR/skills"                 "$HOME/.claude/skills"
[[ -d "$DEVBOX_DIR/rules" ]] && symlink "$DEVBOX_DIR/rules" "$HOME/.claude/rules"

# ── Directory structure ───────────────────────────────────────────────────────

info "Creating directories..."
mkdir -p "$HOME/repos" "$HOME/tasks" "$HOME/devbox/scripts"
mkdir -p "$DEVBOX_DIR/.secrets" "$DEVBOX_DIR/.caddy/sites.d" "$DEVBOX_DIR/.state/env" "$DEVBOX_DIR/.state/cwd"
chmod 700 "$DEVBOX_DIR/.secrets"

# ── .bashrc hook ─────────────────────────────────────────────────────────────

if ! grep -q 'bash_aliases' "$HOME/.bashrc" 2>/dev/null; then
  info "Adding bash_aliases source to .bashrc..."
  echo '[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases' >> "$HOME/.bashrc"
fi

# ── System packages ───────────────────────────────────────────────────────────

info "Installing system packages..."
apt-get update -qq
apt-get install -y -qq \
  build-essential curl git unzip wget jq gnupg2 lsb-release \
  libssl-dev libreadline-dev zlib1g-dev \
  libpq-dev libyaml-dev libffi-dev \
  mosh tmux htop

# ── asdf ─────────────────────────────────────────────────────────────────────

if ! command -v asdf &>/dev/null; then
  info "Installing asdf ${ASDF_VERSION}..."
  curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf_${ASDF_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin asdf
fi

install_asdf_plugin() {
  local name="$1"
  asdf plugin list | grep -q "^$name$" || asdf plugin add "$name"
}

info "Installing asdf plugins and runtimes from .tool-versions..."
while IFS=' ' read -r name version; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  install_asdf_plugin "$name"
  asdf install "$name" "$version"
done < "$HOME/.tool-versions"

asdf reshim
export PATH="$HOME/.asdf/shims:$PATH"

# ── uv (Python tooling) ───────────────────────────────────────────────────────

if ! command -v uv &>/dev/null; then
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ── doctl (DigitalOcean CLI) ──────────────────────────────────────────────────

if ! command -v doctl &>/dev/null; then
  info "Installing doctl ${DOCTL_VERSION}..."
  curl -fsSL "https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz" \
    | tar -xz -C /usr/local/bin doctl
fi

# ── Stripe CLI ────────────────────────────────────────────────────────────────

if ! command -v stripe &>/dev/null; then
  info "Installing Stripe CLI..."
  curl -fsSL https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public \
    | gpg --dearmor -o /usr/share/keyrings/stripe.gpg
  echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" \
    > /etc/apt/sources.list.d/stripe.list
  apt-get update -qq && apt-get install -y -qq stripe
fi

# ── Caddy (xcaddy build with Cloudflare DNS module) ───────────────────────────
# Standard apt Caddy lacks the Cloudflare DNS module required for wildcard TLS.

if ! caddy list-modules 2>/dev/null | grep -q 'dns.providers.cloudflare'; then
  info "Installing Go ${GO_VERSION} for xcaddy build..."
  if [[ ! -f /usr/local/go/bin/go ]]; then
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -xz -C /usr/local
  fi
  export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

  info "Installing xcaddy..."
  go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

  info "Building Caddy v${CADDY_VERSION} with Cloudflare DNS module..."
  CADDY_BUILD_DIR=$(mktemp -d)
  xcaddy build "v${CADDY_VERSION}" --with github.com/caddy-dns/cloudflare \
    --output "$CADDY_BUILD_DIR/caddy"
  install -m 755 "$CADDY_BUILD_DIR/caddy" /usr/local/bin/caddy
  rm -rf "$CADDY_BUILD_DIR"

  id -u caddy &>/dev/null || useradd -r -M -d /var/lib/caddy -s /usr/sbin/nologin caddy
  mkdir -p /etc/caddy /var/lib/caddy /var/log/caddy
  chown -R caddy:caddy /var/lib/caddy /var/log/caddy

  install -m 644 "$DEVBOX_DIR/scripts/caddy.service" /etc/systemd/system/caddy.service
  systemctl daemon-reload
  systemctl enable --now caddy
fi

# ── PostgreSQL 16 ─────────────────────────────────────────────────────────────

if ! command -v psql &>/dev/null; then
  info "Installing PostgreSQL 16..."
  curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
  echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
    https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list
  apt-get update -qq && apt-get install -y -qq postgresql-16 postgresql-client-16
  systemctl enable --now postgresql
fi

# ── Redis ─────────────────────────────────────────────────────────────────────

if ! command -v redis-cli &>/dev/null; then
  info "Installing Redis..."
  apt-get install -y -qq redis-server
  systemctl enable --now redis-server
fi

# ── GitHub CLI ───────────────────────────────────────────────────────────────

if ! command -v gh &>/dev/null; then
  info "Installing GitHub CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt-get update -qq && apt-get install -y -qq gh
fi

# ── Shopify CLI (npm global) ──────────────────────────────────────────────────

if ! command -v shopify &>/dev/null; then
  info "Installing Shopify CLI..."
  npm install -g @shopify/cli
  asdf reshim nodejs
fi

# ── Composer global packages ──────────────────────────────────────────────────

info "Installing Composer global packages..."
export COMPOSER_ALLOW_SUPERUSER=1
export COMPOSER_HOME="$HOME/.composer"
composer global require laravel/installer laravel/forge-cli --no-interaction -q

# ── Devbox systemd template ───────────────────────────────────────────────────

info "Installing devbox@.service..."
install -m 644 "$DEVBOX_DIR/scripts/devbox@.service" /etc/systemd/system/devbox@.service
systemctl daemon-reload

# ── Done ──────────────────────────────────────────────────────────────────────

info "Done. Reload your shell and authenticate GitHub CLI:"
info "  source ~/.bashrc"
info "  gh auth login"
