# devbox

A personal remote development server — SSH-first, AI-assisted, with per-branch preview environments. All repos, runtimes, services, and tooling live here. Thin clients (phone, tablet, laptop) connect via SSH or mosh and drive everything through Claude Code skills.

## What it does

- **Branch environments on demand** — `project-up <project> <branch>` spins up a full environment: git worktree, Postgres DB, systemd unit, and Caddy reverse proxy snippet. Each branch gets a routable URL at `<branch>.<project>.joshevensen.com`.
- **AI-driven workflows** — 39 Claude Code skills cover the full development lifecycle: task planning, bug triage, PR management, refactoring, group/milestone tracking, and utility operations.
- **Stack-aware startup** — each project declares a stack (`laravel`, `laravel-inertia`, `phoenix`, `python-uvicorn`). The matching stack script handles dependency install, migrations, and process startup automatically.
- **Multi-client safe** — all state lives on the server. Sessions from Blink Shell, Blink Code, and laptop terminals share the same environment without conflict.

## Server requirements

| Requirement | Notes |
|---|---|
| Ubuntu 22.04+ | Other Debian-based distros likely work |
| PostgreSQL 16 | Localhost only; one role + DB per project |
| Caddy (with Cloudflare DNS module) | Wildcard TLS via DNS-01 challenge |
| systemd | Process management for branch environments |
| Redis | Localhost only; used by queue-based stacks |
| mosh | Optional; recommended for mobile clients |

### Runtimes (managed via asdf)

| Runtime | Version |
|---|---|
| PHP | 8.4 |
| Python | 3.13 |
| Node.js | 24 (Active LTS) |
| Erlang/OTP | 27 |
| Elixir | 1.18 |

See `docs/runtimes.md` for full version list and CLI tools (doctl, Stripe, Shopify, Forge, uv, Composer).

## Installation

Before you begin, your server needs two tools that must be installed manually:

- **`git`** — to clone this repo
- **`gh`** (GitHub CLI) — used by every skill that manages tasks, bugs, and PRs; must be authenticated before the skills work

```bash
# On a fresh Ubuntu server (run as root)
apt-get update && apt-get install -y git

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" \
  > /etc/apt/sources.list.d/github-cli.list
apt-get update && apt-get install -y gh

gh auth login
```

`install.sh` handles everything else from there.

### 1. Clone the repo

```bash
git clone git@github.com:joshevensen/devbox.git ~/devbox
```

### 2. Run the install script

```bash
bash ~/devbox/install.sh
```

This bootstraps the full server: installs system packages, all runtimes via asdf (PHP, Node, Python, Erlang, Elixir), uv, doctl, Stripe CLI, GitHub CLI, Caddy with the Cloudflare DNS module, PostgreSQL 16, Redis, Shopify CLI, Composer globals, and the `devbox@.service` systemd template. It also creates symlinks for `~/.bash_aliases`, `~/CLAUDE.md`, and `~/.claude/skills/`.

### 3. Register a project

```bash
# One-time: clone the repo as a bare repo and create the secrets file
project-init git@github.com:you/myapp.git

# Register the project and set its stack (Claude Code)
/repo-add

# Create the Postgres role and primary database
pgnewdb myapp

# Add project-wide secrets
nano ~/devbox/.secrets/myapp.env
```

### 4. Spin up a branch environment

```bash
project-up myapp main
```

The app will be available at `https://main.myapp.joshevensen.com`.

## How skills work

Skills are Claude Code slash commands stored in `~/devbox/skills/`. Each skill is a directory containing a `SKILL.md` file that describes what the skill does and how to execute it. The `skills/` directory is symlinked from `~/.claude/skills/` so Claude Code picks them up automatically.

```
~/devbox/skills/
  task-create/SKILL.md
  task-build/SKILL.md
  bug-explore/SKILL.md
  pr-review/SKILL.md
  ...
```

Run any skill from within a Claude Code session:

```
/task-create
/bug-explore https://sentry.io/...
/pr-review
/work-summary
```

### Skill categories

| Category | Skills |
|---|---|
| **Task flow** | `task-create`, `task-plan`, `task-build`, `task-ship`, `task-edit`, `task-cancel`, `task-split`, `task-move`, `task-view` |
| **Bug flow** | `bug-explore`, `bug-fix`, `bug-ship`, `bug-retry`, `bug-view` |
| **PR flow** | `pr-open`, `pr-feedback`, `pr-review` |
| **Groups** | `group-create`, `group-edit`, `group-close`, `group-view`, `groups-list` |
| **Refactor** | `refactor`, `refactor-ship` |
| **Utilities** | `repo-setup`, `repo-scaffold`, `tasks-list`, `bugs-list`, `work-list`, `work-summary`, `tasks-next`, `prioritize`, `prioritize-group`, `merge-main` |

Skills use GitHub Issues as the backing store for tasks, bugs, groups, and queues — portable across machines and accessible from any GitHub client.

See `docs/tips.md` for a full skill reference, shell aliases, project commands, and tmux tips.

### Per-project context

Each project has an `AGENTS.md` at its repo root. This is the canonical LLM context file (LLM-agnostic). `CLAUDE.md` is a symlink to it. Use `/repo-scaffold` to generate this file for a new project — it discovers stack defaults and surfaces commands from `package.json`, `composer.json`, and `artisan`.

## Supported stacks

| Stack | Use for |
|---|---|
| `laravel` | Laravel API-only or Blade apps |
| `laravel-inertia` | Laravel + Vue/React via Inertia |
| `phoenix` | Elixir/Phoenix apps |
| `python-uvicorn` | Python ASGI apps via uv + uvicorn |

Stack scripts live in `~/devbox/scripts/stacks/`. See `docs/stacks.md` to add a new stack.

## Project structure

```
~/devbox/
  docs/           Server-wide reference documentation
  home/           Shell config (bash_aliases → ~/.bash_aliases)
  repos/          Per-project devbox config (<name>.yaml)
  scripts/
    stacks/       Stack startup scripts (one per stack type)
  skills/         Claude Code skills (symlinked from ~/.claude/skills/)
  rules/          Scoped rule files (symlinked from ~/.claude/rules/)
  .secrets/       Per-project env files (mode 0600, not committed)
  .state/         Runtime state (ports, env files, cwd symlinks)
  .caddy/sites.d/ Generated Caddy snippets (one per running branch)
  install.sh      Bootstrap script
  AGENTS.md       Server-wide AI context (symlinked to ~/CLAUDE.md)
```

## Contributing

This is a personal devbox config, but issues and pull requests are welcome — especially for new stack scripts, skill improvements, or documentation fixes.

### Guidelines

- **Stack scripts** — follow the contract in `docs/stacks.md`. New stacks should handle dependency install, migrations, and `exec` to the long-running process.
- **Skills** — each skill lives in its own directory under `skills/`. Keep specs declarative and step-based so any LLM can follow them. Avoid baking in assumptions that only hold for one project.
- **Docs** — infrastructure docs go in `docs/`. Keep them accurate over comprehensive; a short doc that's always current beats a long one that goes stale.
- **Secrets** — never commit anything under `.secrets/`. The `.gitignore` covers this, but double-check.

### Running locally

There's no test suite — the "tests" are running the scripts and skills against a real environment. If you're iterating on a stack script, `project-up` / `project-down` are your feedback loop.

### Reporting issues

Open a GitHub issue. Include the stack, the command or skill you ran, and any relevant output from `journalctl -u devbox@<project>-<branch>`.

## License

MIT — see [LICENSE](LICENSE).
