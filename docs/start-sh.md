# `.devbox/start.sh` contract

Each project committed to `~/repos/<project>/` should include `.devbox/start.sh` (executable). The systemd template `devbox@<project>-<branch>.service` execs this file when the branch env starts.

## Contract

The script:
1. Receives env vars via systemd `EnvironmentFile`. Always available:
   - `PORT` — the port this branch should listen on (allocated by devup)
   - `APP_URL` — the public URL (e.g. https://task-001.fibermade.joshevensen.com)
   - `DATABASE_URL` — a Postgres URL
   - `REDIS_URL` — redis://127.0.0.1:6379/<allocated_db_index>
   - Plus everything from `~/.devbox/secrets/<project>.env`
2. Runs from the worktree directory (cwd is the worktree root).
3. **Replaces itself with the long-running app process** via `exec` — don't background.
4. Returns non-zero if startup fails.

## Examples

### Laravel
```bash
#!/usr/bin/env bash
set -euo pipefail
[ -d vendor ] || composer install --no-interaction
[ -f .env ] || cp .env.devbox .env  # or generate from EnvironmentFile
php artisan migrate --force
exec php artisan serve --host=127.0.0.1 --port="$PORT"
```

### Phoenix
```bash
#!/usr/bin/env bash
set -euo pipefail
[ -d deps ] || mix deps.get
mix ecto.migrate
exec mix phx.server
```

### Python (uv + uvicorn)
```bash
#!/usr/bin/env bash
set -euo pipefail
uv sync
exec uv run uvicorn app:app --host 127.0.0.1 --port "$PORT"
```
