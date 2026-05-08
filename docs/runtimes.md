# Runtimes & CLIs

Installed 2026-05-07. Updates land here when versions change.

## What's installed

| Tool | Version | Managed by |
|---|---|---|
| asdf | v0.19.0 | system (binary at `/usr/local/bin/asdf`) |
| PHP | 8.4.21 | asdf |
| Python | 3.13.13 | asdf |
| Node.js | 24.15.0 (Active LTS) | asdf |
| Erlang/OTP | 27.3.4.11 | asdf |
| Elixir | 1.18.4 (OTP 27) | asdf |
| Composer | 2.9.7 | system (`/usr/local/bin/composer`) |
| uv | 0.11.11 | system (`~/.local/bin/uv`) |
| doctl | 1.158.0 | system (`/usr/local/bin/doctl`) |
| Stripe CLI | 1.40.9 | apt |
| Shopify CLI | 3.94.3 | npm global |
| Laravel installer | 5.27.0 | composer global |
| Laravel Forge CLI | ~1.8 | composer global |
| mosh | 1.4.0 | apt |
| Redis | (apt default) | apt, systemd |

## asdf — language version manager

asdf manages PHP, Node, Python, Erlang, Elixir. Global versions are pinned in `~/.tool-versions`.

### Per-project pinning

Inside a project directory, override the global version:
```bash
cd ~/repos/myproject
asdf set php 8.3.10                    # writes/updates project .tool-versions
```

Each branch worktree will get its own `.tool-versions` if the project's main repo has one — perfect for branch-specific upgrades without disturbing other branches.

### Common commands

| Command | Effect |
|---|---|
| `asdf list <plugin>` | Versions installed locally |
| `asdf list all <plugin>` | All versions available to install |
| `asdf install <plugin> <version>` | Install a version |
| `asdf set -u <plugin> <version>` | Set as global default |
| `asdf set <plugin> <version>` | Set for current directory only |
| `asdf current` | Show active versions and where they're set |
| `asdf uninstall <plugin> <version>` | Remove |

### Adding a new plugin

```bash
asdf plugin add ruby                                          # if known
asdf plugin add deno https://github.com/asdf-community/...    # custom
```

## Composer (PHP)

System-wide install at `/usr/local/bin/composer`. Two env vars are set in `~/.bash_aliases`:

- `COMPOSER_ALLOW_SUPERUSER=1` — silences the "don't run as root" nag (we're root by design here).
- `COMPOSER_HOME=~/.composer` — stable path so global tools survive PHP version bumps.

`~/.composer/vendor/bin` is on `PATH`, so `laravel`, `forge`, etc. are directly invocable.

### Global tools

```bash
composer global require <package>          # install
composer global update                     # upgrade all
composer global remove <package>
composer global show                       # list installed
```

Currently installed globally:
- `laravel/installer` → `laravel new <app>`
- `laravel/forge-cli` → `forge ...`

## uv (Python)

`uv` replaces pip + venv + pip-tools. Project-local virtualenvs live at `.venv/` by default.

### Common commands

| Command | Effect |
|---|---|
| `uv init` | Init a new project (creates `pyproject.toml`, `.venv/`) |
| `uv venv` | Create a `.venv/` in cwd |
| `uv add <pkg>` | Add a dependency to the current project |
| `uv remove <pkg>` | Remove |
| `uv sync` | Install everything from lockfile |
| `uv run <cmd>` | Run a command inside the project's venv |
| `uvx <tool>` | Run a Python tool ephemerally without installing (like `npx`) |

### One-off scripts

```bash
uv run --with requests script.py
```

## Node / npm

`node` and `npm` come via asdf (`asdf install nodejs <ver>`). Globally installed npm packages live under the active Node version's `lib/node_modules` — `asdf reshim nodejs` after global installs (run automatically by asdf).

Currently installed globally:
- `@shopify/cli` → `shopify ...`

## Standalone CLIs

### doctl (DigitalOcean)
```bash
doctl auth init        # paste API token from cloud.digitalocean.com/account/api/tokens
doctl account get      # verify
doctl compute droplet list
```

### stripe CLI
```bash
stripe login                     # opens browser-based pairing flow
stripe listen --forward-to ...   # webhook tunnel for local dev
stripe trigger payment_intent.succeeded
```

### Laravel Forge CLI (`forge`)
```bash
forge login            # API token auth
forge list             # list servers
forge ssh <server>     # SSH to a server
```

### Shopify CLI (`shopify`)
```bash
shopify auth login
shopify app dev
shopify theme dev
```

## mosh (resumable SSH)

Already installed and listening on UDP 60000-61000 by default. No firewall rules currently block it (ufw is inactive on this box).

### From Blink Shell (iOS/iPadOS)

In Blink, set the host's protocol to "mosh" instead of "ssh". Sessions will survive network changes (wifi → cellular, sleep, etc.) and reconnect automatically.

### From a regular terminal

```bash
mosh root@joshevensen.com         # if the domain points here
mosh root@<server-ip>
```

If a future firewall is enabled, allow UDP 60000-61000:
```bash
ufw allow 60000:61000/udp
```

## Redis

Running on `127.0.0.1:6379` via systemd (`systemctl status redis-server`). No password by default — fine for localhost-only use. Used by Laravel for queues, cache, sessions when projects opt in.

```bash
redis-cli ping        # → PONG
redis-cli monitor     # watch live commands
```

## Updating

| What | How |
|---|---|
| Languages (PHP, Python, Node, Erlang, Elixir) | `asdf install <plugin> <newer>` then `asdf set -u <plugin> <newer>` |
| asdf itself | Replace `/usr/local/bin/asdf` binary from GitHub releases |
| Composer | `composer self-update` |
| uv | `uv self update` |
| doctl | Re-download binary from GitHub releases |
| Stripe | `apt update && apt upgrade stripe` |
| Shopify CLI | `npm install -g @shopify/cli@latest` |
| Laravel installer / Forge CLI | `composer global update` |

## Open security note

This server has **no OS-level firewall** active (ufw inactive, default-accept iptables). Inbound protection currently relies on whatever the cloud provider gives. Worth deciding if/when to add `ufw` rules — at minimum, allowing only ssh/mosh + 80/443 once the reverse proxy is up.
