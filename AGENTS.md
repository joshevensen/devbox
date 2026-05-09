# Agent context for this server

This is **not a code project** — it's the user's remote devbox. All real coding happens inside repos under `~/repos/<project>/`. When invoked at `/root`, you're in admin/setup mode for the server itself.

## Behavior rules

- **If not confident, say so.** Do not guess or present uncertain information as fact. Prefer "I don't know" or "I'm not sure" over a plausible-sounding but unreliable answer.
- **If a task can't be completed, stop and ask.** If a required tool, service, or MCP server is unavailable, state what is missing and ask for guidance. Do not attempt the task through an alternative method unless explicitly told to.
- **Don't improvise scope.** Only do what was asked. Don't refactor surrounding code, add features, or make unrelated improvements unless explicitly requested.

## Where things live

| Path | What it is |
|---|---|
| `~/repos/` | All project repositories. `cd` into one for project work. |
| `~/devbox/` | This repo. Config, docs, skills, and shell setup. |
| `~/devbox/AGENTS.md` | This file. Symlinked from `~/CLAUDE.md` and `~/.claude/CLAUDE.md`. |
| `~/devbox/docs/` | Server-wide reference docs. **Read these before infrastructure work.** |
| `~/devbox/docs/overview.md` | Devbox plan: access pattern, domain strategy, TBD decisions. |
| `~/devbox/docs/caddy.md` | Caddy install, config paths, service management, TLS, adding sites. |
| `~/devbox/docs/database.md` | PostgreSQL 16 reference + helper aliases/functions. |
| `~/devbox/docs/runtimes.md` | Languages (asdf-managed) + CLIs (doctl/stripe/shopify/forge/laravel/uv/mosh/redis). |
| `~/devbox/docs/stacks.md` | Stack script contract + available stacks + how to add a new one. |
| `~/devbox/repos/` | Per-repo devbox config (`<name>.yaml`). One file per registered repo. |
| `~/devbox/scripts/stacks/` | Stack startup scripts. One script per stack type (laravel, phoenix, etc.). |
| `~/devbox/skills/` | Claude Code + agent skills. Symlinked from `~/.claude/skills`. |
| `~/devbox/rules/` | Scoped rule files. Symlinked from `~/.claude/rules/`. |
| `~/devbox/scripts/` | Server-wide helper scripts. |
| `~/tasks/` | Outstanding work files. Open `~/tasks/README.md` for the status board. |
| `~/.bash_aliases` | Symlink to `~/devbox/home/bash_aliases`. |
| `~/.claude/projects/-root/memory/` | Cross-session memory. |

## How the user works

- SSH-first from Blink Shell (phone), Blink Code (phone/iPad), and laptop. Multiple concurrent clients hit the same server, so any state lives here.
- Primary AI tools: **Claude Code** and **Codex**, driven via prompts/skills.
- Stack: **Laravel** (most common), **Elixir/Phoenix**, **Python**.

## Conventions

- **One Postgres role + DB per project**, same name. Use the `pgnewdb` helper. See `~/devbox/docs/database.md`.
- **Server-wide docs go in `~/devbox/docs/`**, not scattered at `/root` or in random subdirs.
- **Per-project context** (build commands, schema notes, gotchas) belongs in that project's own `CLAUDE.md` inside `~/repos/<project>/`, not here.
- When making infrastructure changes that future sessions need to know about, update the relevant doc in `~/devbox/docs/` — don't rely on memory alone.

## Domain plan (in progress)

User owns `joshevensen.com`. The plan is wildcard branch-based subdomains: `<branch>.<project>.joshevensen.com` (e.g. `task-001.fibermade.joshevensen.com`). Reverse proxy and DNS specifics are still TBD — see `~/devbox/docs/overview.md` "Open decisions".

## When the user asks for help at `/root`

- Server admin / setup tasks: install services, edit configs, manage systemd units.
- Doc maintenance: update files in `~/devbox/docs/`.
- Cross-project utilities: shell aliases, helper scripts.

For anything inside a specific repo, expect to `cd ~/repos/<project>` first.
