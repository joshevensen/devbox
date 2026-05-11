# refactor-ship

Commit and push a completed refactor. Runs the pre-commit gate, stages refactor-related files, commits, and pushes.

## Usage

```
/refactor-ship {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels
```

Confirm `status:built`. Display branch name and description. If status is not `built`, stop and report the current status.

### 2. Review changes

```bash
git status --short
git diff --stat
```

Confirm branch is `refactor/{number}-{slug}`. Surface any unrelated changes — do not stage them.

### 3. Pre-commit gate

Run pre-commit gate commands from the project's `AGENTS.md`. Stack defaults first, then project additions. See `utils.md` for command resolution.

If a command fails: stop and report which command failed and why.

### 4. Commit

Stage only refactor-related files. Do not use `git add .`.

```
refactor(#{number}): {short description}
```

### 5. Push

```bash
git push -u origin refactor/{number}-{slug}
```

### 6. Update status

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:built" \
  --add-label "status:shipped"
```

### 7. Report

```
Refactor #{number} is shipped. Run /pr-open {number} when ready to open a pull request.
```
