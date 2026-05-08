# add-project

Bootstraps a new project on this devbox end-to-end: initialises the bare repo, detects the stack, generates `.devbox/start.sh` if missing, creates the Postgres role + primary DB, and populates the secrets file. Stops before spinning up any branch environment.

## Usage

```
/add-project <git-url> [<project-name>]
```

- `<git-url>` — SSH or HTTPS git remote (required)
- `<project-name>` — override the name derived from the URL (optional)

---

## Steps

Work through these in order. At each step, show the user what you are doing and the output. If a step fails, stop and explain the error clearly before proceeding.

### 1. Derive the project name

If `<project-name>` was not supplied, extract it from the URL:
```bash
basename "<git-url>" .git   # works for both git@ and https:// URLs
```
The name must match `^[a-z][a-z0-9-]*$`. If it doesn't (e.g. contains uppercase or underscores), tell the user and ask them to provide an explicit name.

### 2. Run project-init

```bash
project-init <git-url> [<project-name>]
```

If it fails because the project already exists, stop and tell the user.

### 3. Detect the stack

Use `git -C ~/repos/<project>/.bare show HEAD:<path>` to read files from the bare repo without creating a worktree. Check in this order:

| Signal | Stack |
|---|---|
| `artisan` file exists | Laravel (PHP) |
| `mix.exs` exists | Phoenix (Elixir) |
| `pyproject.toml` or `requirements.txt` exists | Python |

If you can't determine the stack, tell the user and ask them to confirm before continuing.

### 4. Check for `.devbox/start.sh`

```bash
git -C ~/repos/<project>/.bare show HEAD:.devbox/start.sh 2>/dev/null
```

**If it exists:** confirm to the user and skip to step 5.

**If it is missing:** generate one (see templates below), then:

1. Create a temporary worktree:
   ```bash
   git -C ~/repos/<project>/.bare worktree add ../tmp-setup HEAD
   ```
2. Write the generated `start.sh` into `~/repos/<project>/tmp-setup/.devbox/start.sh` and make it executable.
3. Commit and push:
   ```bash
   git -C ~/repos/<project>/tmp-setup add .devbox/start.sh
   git -C ~/repos/<project>/tmp-setup commit -m "Add .devbox/start.sh for devbox deployment"
   git -C ~/repos/<project>/tmp-setup push origin HEAD
   ```
4. Remove the temporary worktree:
   ```bash
   git -C ~/repos/<project>/.bare worktree remove --force ../tmp-setup
   ```

Show the user the generated `start.sh` content and note that they should review it.

#### start.sh templates

**Laravel:**
```bash
#!/usr/bin/env bash
set -euo pipefail

[ -d vendor ] || composer install --no-interaction --prefer-dist

cat > .env << ENV
APP_NAME=$(basename "$PWD")
APP_ENV=${APP_ENV:-devbox}
APP_KEY=${APP_KEY:-}
APP_URL=$APP_URL
DB_CONNECTION=pgsql
DB_URL=$DATABASE_URL
REDIS_URL=$REDIS_URL
CACHE_STORE=redis
SESSION_DRIVER=redis
LOG_CHANNEL=stderr
ENV

[ -z "${APP_KEY:-}" ] && php artisan key:generate --force

php artisan migrate --force

exec php artisan serve --host=127.0.0.1 --port="$PORT"
```

**Phoenix:**
```bash
#!/usr/bin/env bash
set -euo pipefail

[ -d deps ] || mix deps.get
mix ecto.migrate

exec mix phx.server
```

**Python:**
```bash
#!/usr/bin/env bash
set -euo pipefail

uv sync
exec uv run uvicorn app:app --host 127.0.0.1 --port "$PORT"
```

For Python, inspect `pyproject.toml` or `requirements.txt` to find the actual entrypoint and adjust accordingly.

### 5. Generate secrets

Generate a secure random DB password:
```bash
DB_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)
```

For Laravel, also generate an APP_KEY:
```bash
APP_KEY="base64:$(openssl rand -base64 32)"
```

### 6. Create the Postgres role and primary database

```bash
pgnewdb <project> "$DB_PASS"
```

### 7. Write the secrets file

Write to `~/.devbox/secrets/<project>.env` (create or overwrite):

```
DB_USER=<project>
DB_PASS=<generated-password>
```

For Laravel, also add:
```
APP_KEY=<generated-app-key>
```

For Phoenix, note to the user that `SECRET_KEY_BASE` will need to be added manually.

Set permissions:
```bash
chmod 600 ~/.devbox/secrets/<project>.env
```

Show the user the secrets file contents (mask the password to the first 6 characters followed by `***`).

### 8. Summary

Print a clear summary:

```
Project <project> is ready.

Done automatically:
  ✓ Bare repo initialised at ~/repos/<project>/.bare
  ✓ .devbox/start.sh present (generated / already existed)
  ✓ Postgres role + primary DB created: <project>
  ✓ Secrets written to ~/.devbox/secrets/<project>.env

What to do next:
  • Review .devbox/start.sh in your repo — adjust for your app's actual startup sequence
  • <any stack-specific manual steps, e.g. SECRET_KEY_BASE for Phoenix>
  • Add any additional secrets (API keys, etc.) to ~/.devbox/secrets/<project>.env
  • When ready: project-up <project> <branch>
```

Only include manual steps that actually apply.
