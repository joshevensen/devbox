# bug-ship

Commit and push a built bug fix. Checks for error suppression, runs the pre-commit gate, commits, pushes, and resolves linked Sentry issues via sentry-cli.

## Usage

```
/bug-ship {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels
```

Confirm `status:built`. Display branch name and bug title. If status is not `built`, stop and report the current status.

### 2. Review changes

```bash
git status --short
git diff --stat
```

Confirm branch is `bug/{number}-{slug}`. Surface any unrelated changes — do not stage them.

### 3. Error suppression check

Scan the diff for global error suppression patterns:
- `error_reporting(0)` or similar PHP error suppression
- `@` operator applied broadly (not isolated to a single known-safe call)
- Catch-all exception handlers that swallow errors silently
- Sentry `beforeSend` filters that drop entire error classes

If found:
```
⚠ This change appears to suppress errors rather than fix them:
  {file}:{line} — {description}

The preferred fix eliminates the root cause so the error no longer occurs.
Is this suppression intentional and justified?
(y) yes, it's the right fix — continue  (n) no — go back and fix it
```

If `(y)`: before proceeding, add a justification comment to the decided cause comment on the issue via:
```bash
gh issue comment {number} --repo {owner}/{repo} --body "Suppression justification: {reason}"
```

### 4. Pre-commit gate

Run pre-commit gate commands from the project's `AGENTS.md`. Stack defaults first, then project additions. If a command fails, stop and report it.

### 5. Commit

Stage only bug-related files. Commit:
```
fix(#{number}): {short bug title}
```

### 6. Push

```bash
git push -u origin bug/{number}-{slug}
```

### 7. Update status

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:built" \
  --add-label "status:shipped"
```

### 8. Sentry resolution

Extract Sentry issue IDs from the `## Sentry` section of the issue body. The ID is the numeric value at the end of each Sentry URL path.

For each ID:
```bash
sentry-cli issues resolve {sentry-issue-id}
```

If no Sentry links in the issue body: skip.

If `sentry-cli` is not available or `SENTRY_AUTH_TOKEN` is not set:
```
Resolve these Sentry issues manually:
  {url}
```

### 9. Report

```
Bug #{number} is shipped. Run /pr-open {number} when ready to open a pull request.
```

Report which Sentry issues were resolved (or flagged for manual resolution).
