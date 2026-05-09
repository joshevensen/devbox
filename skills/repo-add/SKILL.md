# repo-add

Registers a new repo with devbox end-to-end: clones it as a bare repo, writes the stack config to `~/devbox/repos/<name>.yaml`, creates the Postgres role + primary DB, and populates the secrets file. Stops before spinning up any branch environment. The repo itself is left untouched — no devbox artifacts are committed.

## Usage

```
/repo-add <git-url> [<name>]
```

- `<git-url>` — SSH or HTTPS git remote (required)
- `<name>` — override the name derived from the URL (optional)

---

## Steps

Work through these in order. Show the user what you are doing at each step. If a step fails, stop and explain the error clearly before proceeding.

### 1. Derive the repo name

If `<name>` was not supplied, extract it from the URL:
```bash
basename "<git-url>" .git
```
The name must match `^[a-z][a-z0-9-]*$`. If it doesn't (e.g. contains uppercase or underscores), tell the user and ask them to provide an explicit name.

### 2. Check for conflicts

```bash
ls ~/devbox/repos/<name>.yaml 2>/dev/null && echo exists
ls ~/repos/<name> 2>/dev/null && echo exists
```

If either exists, stop and tell the user.

### 3. Clone the bare repo

```bash
project-init <git-url> [<name>]
```

If `project-init` is not available, do it manually:
```bash
mkdir -p ~/repos/<name>
git clone --bare <git-url> ~/repos/<name>/.bare
echo "gitdir: ./.bare" > ~/repos/<name>/.git
git -C ~/repos/<name>/.bare config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
```

### 4. Detect the stack

Check which stacks are available:
```bash
ls ~/devbox/scripts/stacks/
```

Then inspect the repo HEAD to detect the stack automatically. Use `git -C ~/repos/<name>/.bare show HEAD:<path>` to read files without creating a worktree:

| Signal | Suggested stack |
|---|---|
| `artisan` exists + `package.json` contains `"inertia"` | `laravel-inertia` |
| `artisan` exists | `laravel` |
| `mix.exs` exists | `phoenix` |
| `pyproject.toml` or `requirements.txt` exists | `python-uvicorn` |

If you can detect a stack with confidence, tell the user which one you selected and why, then ask them to confirm or choose a different one. If you cannot detect the stack, list the available stacks from `~/devbox/scripts/stacks/` and ask the user to pick one.

### 5. Write the repo config

Write `~/devbox/repos/<name>.yaml`:

```yaml
stack: <detected-stack>
```

### 6. Generate secrets

Generate a secure random DB password:
```bash
DB_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)
```

For Laravel stacks, also generate an APP_KEY:
```bash
APP_KEY="base64:$(openssl rand -base64 32)"
```

### 7. Create the Postgres role and primary database

```bash
pgnewdb <name> "$DB_PASS"
```

### 8. Write the secrets file

Write to `~/devbox/.secrets/<name>.env` (create or overwrite):

```
DB_USER=<name>
DB_PASS=<generated-password>
```

For Laravel stacks, also add:
```
APP_KEY=<generated-app-key>
```

For Phoenix, note to the user that `SECRET_KEY_BASE` will need to be added manually.

Set permissions:
```bash
chmod 600 ~/devbox/.secrets/<name>.env
```

Show the user the secrets file contents (mask the password to the first 6 characters followed by `***`).

### 9. Summary

```
Repo <name> is registered.

Done automatically:
  ✓ Bare repo cloned to ~/repos/<name>/.bare
  ✓ Stack: <stack> → ~/devbox/repos/<name>.yaml
  ✓ Postgres role + primary DB created: <name>
  ✓ Secrets written to ~/devbox/.secrets/<name>.env

What to do next:
  • Add any additional secrets (API keys, etc.) to ~/devbox/.secrets/<name>.env
  • <any stack-specific manual steps, e.g. SECRET_KEY_BASE for Phoenix>
  • When ready: devup <name> <branch>
```

Only include manual steps that actually apply.
