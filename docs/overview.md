# Devbox overview

This server is the canonical place I do dev work. SSH-first, AI-assisted, with branch-based preview environments under `joshevensen.com`.

## Server role

- **Remote devbox** — all repos, dependencies, services, and AI tooling live here.
- I work from **multiple clients**: phone (Blink Shell + Blink Code), laptop, iPads. They're thin SSH terminals; the server holds state.
- Local laptop dev is the exception, not the norm.

## Workflow

- **Claude Code** + **Codex** are the primary code-writing tools, driven via prompts and skills from whichever client I'm on.
- Claude Code session context lives in `/root/CLAUDE.md` (server-wide) and per-repo `CLAUDE.md` files inside each project.
- Persistent cross-session memory: `/root/.claude/projects/-root/memory/`.

## Filesystem layout

| Path | Contents |
|---|---|
| `~/repos/` | All project repositories (one subdir per repo). |
| `~/docs/` | Server-wide docs (this file, `database.md`, future infra notes). |
| `~/CLAUDE.md` | Persistent context loaded into every Claude Code session at `/root`. |
| `~/.bash_aliases` | Shell aliases / helper functions (e.g. Postgres helpers). |

## Services on this box

- **PostgreSQL 16** — localhost-only. See `database.md`.
- (Future: reverse proxy, language runtimes, redis if needed, etc.)

## Domain strategy

Goal: every project and every working branch gets a routable URL automatically.

**Pattern:**
```
<branch>.<project>.joshevensen.com
```
Examples:
- `task-001.fibermade.joshevensen.com` — branch `task-001` of project `fibermade`
- `main.fibermade.joshevensen.com` — main branch
- `staging.othertool.joshevensen.com` — branch `staging` of project `othertool`

Probably also a top-level `*.joshevensen.com` for ad-hoc or non-branch subdomains.

### DNS

- **Registrar:** name.com (keep here)
- **Recommendation:** delegate DNS to **Cloudflare** (free, fast API, excellent ACME/Let's Encrypt integration for wildcard certs). Migration = swap nameservers at name.com; takes minutes.
- Required records:
  - `*.joshevensen.com` → server IP (A)
  - `*.<project>.joshevensen.com` → server IP (A) — or rely on the top-level wildcard if the reverse proxy can handle nested wildcards.

### TLS

- Wildcard certs from Let's Encrypt via **DNS-01 challenge** (HTTP-01 can't issue wildcards).
- Reverse proxy handles cert provisioning + renewal automatically when given a DNS API token.

## Architecture decisions (2026-05-07)

| # | Decision | Choice |
|---|---|---|
| 1 | DNS | **Cloudflare** (registration stays at name.com; nameservers point to Cloudflare) |
| 2 | Reverse proxy | **Caddy** with the Cloudflare DNS module for wildcard TLS via DNS-01 |
| 3 | Branch → env mapping | **systemd unit per branch** + Caddy snippets per `<branch>.<project>` |
| 4 | Repo layout | **Git worktrees with a bare repo** (`~/repos/<project>/.bare`, worktrees per branch) |
| 5 | Service template | **One systemd template** `devbox@.service` + stack script from `~/devbox/scripts/stacks/` (repos are devbox-unaware) |
| 6 | Secrets | **Two-tier:** `~/devbox/.secrets/<project>.env` shared, per-branch values computed at `devup` time |

### Resulting layout

```
~/
  repos/
    fibermade/
      .bare/                   # bare clone, shared object storage
      .git                     # → .bare
      main/                    # worktree (no devbox artifacts)
      task-001/                # worktree
  devbox/
    repos/
      fibermade.yaml           # stack: laravel-inertia
    scripts/
      stacks/
        laravel.sh
        laravel-inertia.sh
        phoenix.sh
        python-uvicorn.sh
    .secrets/
      fibermade.env            # shared project secrets, mode 0600
    .caddy/
      sites.d/                 # one file per running branch
        fibermade-task-001.caddy
        fibermade-main.caddy
    .state/
      ports.json               # port allocation registry
  docs/
    overview.md                # this file
    database.md
    stacks.md
    caddy.md
    devup.md
```

### Request flow

```
Browser → task-001.fibermade.joshevensen.com (port 443)
       → Caddy (wildcard cert via Cloudflare DNS-01)
       → Caddy snippet for fibermade-task-001 → 127.0.0.1:<allocated port>
       → systemd unit devbox@fibermade-task-001.service
       → .devbox/start.sh inside the worktree
       → app process (php artisan / mix phx.server / uvicorn / etc.)
       → Postgres on 127.0.0.1:5432 (db & role: fibermade_task001 or shared)
```

### Tooling we need to build

- `devup <project> <branch>` — add worktree, allocate port, generate Caddy snippet + systemd unit (instance), reload Caddy, start unit
- `devdown <project> <branch>` — reverse of devup; tear down the env
- `devls` — list active branch envs and their URLs
- `devlogs <project> <branch>` — `journalctl -u devbox@<project>-<branch>`
- (Helpers for shared-secrets editing, project init, etc.)

## Implementation phases

1. **Cloudflare DNS migration** — set up Cloudflare account, recreate zone, switch nameservers at name.com.
2. **Caddy install** — build Caddy with the Cloudflare DNS module; minimal config serving a single wildcard test page.
3. ✅ **systemd template + state dirs** — `devbox@.service` written, `~/devbox/{.secrets,.caddy/sites.d,.state/env,.state/cwd}` created, `ports.json` initialized. See [`stacks.md`](stacks.md) for the stack script contract.
4. ✅ **`devup` / `devdown` / `devls`** — scripts in `/usr/local/bin/`. See [`devup.md`](devup.md).
5. **Bootstrap one project end-to-end** — pick a real repo, write its `.devbox/start.sh`, spin up `main` and a feature branch, verify the URLs and Postgres wiring work.
6. **Document each piece** — `caddy.md`, `devup.md`, `start-sh.md` as we go.
