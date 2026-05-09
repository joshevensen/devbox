# Stack scripts

Each repo registered with devbox declares a stack in `~/devbox/repos/<name>.yaml`. When `devup` starts a branch environment it sources the matching script from `~/devbox/scripts/stacks/<stack>.sh`.

Repos themselves contain no devbox artifacts.

## Repo config format

`~/devbox/repos/<name>.yaml`:

```yaml
stack: laravel-inertia
```

Optional fields (all have defaults in the stack script):

```yaml
stack: laravel-inertia
notes: Uses Horizon for queues — needs Redis warm before starting
```

## Stack script contract

Every script in `~/devbox/scripts/stacks/` must:

1. Receive env vars via systemd `EnvironmentFile`. Always available:
   - `PORT` — port this branch should listen on (allocated by devup)
   - `APP_URL` — public URL (e.g. `https://task-001.fibermade.joshevensen.com`)
   - `DATABASE_URL` — Postgres connection URL
   - `REDIS_URL` — `redis://127.0.0.1:6379/<allocated db index>`
   - Plus everything from `~/devbox/.secrets/<project>.env`
2. Run from the worktree directory (cwd is the worktree root).
3. Install/update dependencies if needed (idempotently — check before running).
4. Run migrations.
5. **Replace itself with the long-running process via `exec`** — do not background.
6. Exit non-zero if startup fails.

## Available stacks

| Stack | Script | Use for |
|---|---|---|
| `laravel` | `laravel.sh` | Laravel API-only or Blade apps |
| `laravel-inertia` | `laravel-inertia.sh` | Laravel + Vue/React via Inertia (runs `npm run build`) |
| `phoenix` | `phoenix.sh` | Elixir/Phoenix apps |
| `python-uvicorn` | `python-uvicorn.sh` | Python ASGI apps via uv + uvicorn |

## Adding a new stack

1. Create `~/devbox/scripts/stacks/<name>.sh` following the contract above.
2. Make it executable: `chmod +x ~/devbox/scripts/stacks/<name>.sh`
3. The stack is immediately available to `/repo-add`.
