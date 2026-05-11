# repo-scaffold

Scaffold the project's `AGENTS.md`, create a `CLAUDE.md` symlink, and discover commands from project config files. Idempotent — shows a diff on re-runs, never silently overwrites.

## Usage

```
/repo-scaffold
```

Run from inside `~/repos/{name}/` or with the project directory as context.

---

## Steps

### 1. Detect project name and stack

Derive project name from the current directory. Read the stack type:
```bash
cat ~/devbox/repos/{name}.yaml
```

If no registry file found: stop and instruct the user to run `/repo-add` first.

### 2. Load stack defaults

Read `~/devbox/scripts/stacks/{stack}.yaml` for `pre_commit_gate` and `verification` command lists.

If the commands YAML does not exist: note that no stack defaults are defined and continue.

### 3. Discover project commands

Scan the project root for:

**`package.json`** — read the `scripts` block. Surface commands that look like test/lint/build (filter out: `dev`, `watch`, `start`, `preview`).

**`composer.json`** — read the `scripts` block. Surface relevant scripts.

**`artisan`** — if present, note `php artisan test` as available.

### 4. Show stack defaults

Display what will run automatically without any project-specific AGENTS.md:
```
Stack defaults that will run automatically (laravel):
  Pre-commit gate:  php artisan test, php artisan migrate:status
  Verification:     php artisan test

Add project-specific commands below these, or use <!-- @override --> to replace them.
```

### 5. Build scaffold content

Construct the AGENTS.md content:

```markdown
## Pre-commit Gate
<!-- Stack defaults (laravel): php artisan test, php artisan migrate:status -->
{discovered commands, one per line, or leave empty}

## Verification
<!-- Stack defaults (laravel): php artisan test -->
{discovered commands, one per line, or leave empty}
```

### 6. Idempotent write

**First run (no AGENTS.md exists):**

Show the full content:
```
AGENTS.md to be created:
{content}

(y) yes  (e) edit  (n) skip
```

**Re-run (AGENTS.md exists):**

Diff the existing file against what would be generated. If nothing changed: "AGENTS.md is already up to date." Done.

If there are changes, show only the diff:
```
Changes to AGENTS.md:
{diff}

(y) apply  (e) edit  (n) skip
```

On confirm: write the file.

### 7. CLAUDE.md symlink

Check for `CLAUDE.md` in the project root.

- Not present: `ln -s AGENTS.md CLAUDE.md`
- Present, already symlinks to AGENTS.md: skip.
- Present as a regular file: warn:
  ```
  CLAUDE.md exists as a regular file, not a symlink.
  Replace it with a symlink to AGENTS.md?
  (y) yes  (n) no — leave it
  ```

### 8. Report

```
repo-scaffold complete:
  AGENTS.md: created / updated / already up to date
  CLAUDE.md: symlink created / already correct / skipped
```
