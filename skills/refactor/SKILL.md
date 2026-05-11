# refactor

Lightweight skill for small, focused code improvements. Creates a minimal issue, makes the change interactively, verifies, and stops before committing. Run `/refactor-ship` to commit and push.

If the change turns out to be large or requires architectural decisions, use `/task-create` instead.

## Usage

```
/refactor {description of the change}
```

If no description is provided, ask: "What do you want to refactor?"

---

## Steps

### 1. Scope check

Do a read-only scan to understand how many files will be touched and whether any design decisions are needed.

If more than ~8 files or requires decisions beyond cleanup:
```
This looks bigger than a small refactor.
Consider creating a proper task with /task-create instead.

(p) proceed anyway  (n) cancel
```

### 2. Create issue

```bash
gh issue create --repo {owner}/{repo} \
  --title "{short action-oriented summary}" \
  --body "## Description

{description}" \
  --label "type:refactor,status:progress"
```

### 3. Branch

```bash
git checkout -b refactor/{number}-{slug} origin/main
```

Where slug is a lowercase kebab-case version of the title.

### 4. Make the change

Apply the refactor. This is interactive — the user is present throughout. If anything is ambiguous or requires a judgment call, stop and ask before writing code. Never guess.

### 5. Verify

Run verification commands from the project's `AGENTS.md`. Stack defaults first, then project additions. See `utils.md` for command resolution.

### 6. Update status

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:progress" \
  --add-label "status:built"
```

### 7. Report

```
Refactor #{number} is done. Run /refactor-ship {number} when ready to commit and push.
```
