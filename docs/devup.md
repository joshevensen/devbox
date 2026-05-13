# repo-* — branch environment tooling

These scripts manage the lifecycle of per-branch dev environments on this server. Each environment is a combination of: git worktree + Postgres DB + systemd unit + Caddy snippet. All scripts live in `~/devbox/scripts/`.

To register a new repo (clone, stack config, Postgres setup, secrets), use the `/repo-add` skill in Claude Code — not these scripts directly.

## Commands

### `repo-up <project> <branch> [<git-ref>]`

Spins up a branch environment end-to-end.

```bash
repo-up fibermade task-001
repo-up fibermade task-001 origin/feature/task-001   # explicit git ref
```

Steps it performs:
1. Reads the stack from `~/devbox/repos/<project>.yaml`.
2. Allocates a port (40000+, never reused after teardown).
3. Adds a git worktree at `~/repos/<project>/<branch>`.
4. Creates a per-branch Postgres DB named `<project>_<branch>` (hyphens → underscores), owned by the project role.
5. Writes `~/devbox/.state/env/<project>-<branch>.env` with `PORT`, `APP_URL`, `DATABASE_URL`, `REDIS_URL`, `WORKING_DIR_OVERRIDE`, `STACK_SCRIPT`, and everything from `~/devbox/.secrets/<project>.env`.
6. Symlinks `~/devbox/.state/cwd/<project>-<branch>` → worktree (satisfies `WorkingDirectory=` in the systemd template).
7. Writes `~/devbox/.caddy/sites.d/<project>-<branch>.caddy` and reloads Caddy.
8. Enables and starts `devbox@<project>-<branch>.service`.

If any step fails, rollback runs in reverse order.

### `repo-down <project> <branch> [--force]`

Tears down a branch environment. Safe to re-run.

```bash
repo-down fibermade task-001           # prompts before dropping DB
repo-down fibermade task-001 --force   # skips DB drop confirmation
```

Steps: stop/disable unit → remove Caddy snippet + reload → remove env file and cwd symlink → drop DB → remove worktree → free port in ports.json.

Note: ports are never reused. `next_port` keeps incrementing so journal entries for different instances on the same port don't mix.

### `devls`

Lists all active environments with their URLs, ports, and systemd status.

```bash
devls
```

### `repo-logs <project> <branch>`

Tails the journal for a branch env (last 50 lines + follow).

```bash
repo-logs fibermade task-001
```

Equivalent to: `journalctl -u devbox@fibermade-task-001.service -n 50 -f`

---

## How port allocation works

State lives in `~/devbox/.state/ports.json`:

```json
{
  "next_port": 40002,
  "allocations": {
    "fibermade-main": 40000,
    "fibermade-task-001": 40001
  }
}
```

`repo-up` atomically reads `next_port`, assigns it to the new instance, and increments. `repo-down` removes the instance from `allocations` but never decrements `next_port`. Range 40000–49999.

Locking: `flock` on `ports.json.lock`. Fine for single-user box; concurrent `repo-up` calls on different terminals would queue on the lock.

---

## Secrets file format (`~/devbox/.secrets/<project>.env`)

Plain `KEY=VALUE` lines, no export needed. This file is appended to each branch's env file, so every var in it is visible to `start.sh`.

```
DB_USER=fibermade
DB_PASS=supersecret
STRIPE_SECRET_KEY=sk_test_...
```

`devup` also extracts `DB_USER` and `DB_PASS` from this file to construct `DATABASE_URL`. If `DB_USER` is absent, it defaults to the project name.

---

## Redis DB allocation

Redis DB index = `(port - 40000) % 16`. With 16 Redis databases and ports starting at 40000, you'd need more than 16 simultaneous envs before indexes collide. Acceptable for a single-user devbox.

---

## Recovery from corrupt state

If `devup` dies partway and rollback also fails:

1. **Systemd:** `systemctl disable --now devbox@<instance>.service`
2. **Caddy:** `rm ~/devbox/.caddy/sites.d/<instance>.caddy && systemctl reload caddy`
3. **State files:** `rm ~/devbox/.state/env/<instance>.env ~/devbox/.state/cwd/<instance>`
4. **DB:** `sudo -u postgres psql -c "DROP DATABASE IF EXISTS \"<db_name>\";"`
5. **Worktree:** `git -C ~/repos/<project>/.bare worktree remove --force ../<branch>`
6. **ports.json:** manually edit to remove the instance from `allocations`.

Then re-run `repo-up` fresh.

---

## Instance naming

Instance = `<project>-<branch>`. Both must match `^[a-z][a-z0-9-]*$`. The separator is always a hyphen; Caddy snippets, systemd units, env files, and cwd symlinks all use this naming consistently.

DB name: `<project>_<branch>` with all hyphens converted to underscores (Postgres doesn't allow hyphens in unquoted identifiers).
