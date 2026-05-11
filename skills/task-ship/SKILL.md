# task-ship

Commit and push a built task branch. Runs the pre-commit gate, stages task-related files, and pushes. Does not open a PR.

## Usage

```
/task-ship {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,labels
```

Confirm the issue has `status:built`. Display the branch name and task title. If status is not `built`, stop and report the current status.

### 2. Review changes

```bash
git status --short
git diff --stat
```

Confirm the current branch is `task/{number}-{slug}` and not `main`. If any unrelated changes are present, surface them clearly — do not stage them.

### 3. Pre-commit gate

Run pre-commit gate commands from the project's `AGENTS.md`. Stack defaults run first, then project-specific additions. See `utils.md` for command resolution.

If a command fails: stop and report which command failed and why. Do not proceed until resolved.

If a command cannot run (missing binary, wrong environment): record the command and reason, then continue.

### 4. Commit

Stage only task-related files. Do not use `git add .` — add files explicitly.

Commit with a conventional commit message:
```
{type}(#{number}): {short task title}
```

Where `{type}` matches the task's `type:*` label (feature → feat, bug → fix, chore → chore, docs → docs, refactor → refactor).

### 5. Push

```bash
git push -u origin task/{number}-{slug}
```

### 6. Update status

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:built" \
  --add-label "status:shipped"
```

### 7. Report

```
Task #{number} is shipped. Run /pr-open {number} when ready to open a pull request.
```
