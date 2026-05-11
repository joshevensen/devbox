# task-build

Execute a planned task's subtasks on a branch. Stops when all subtasks are done and verified locally. Nothing is committed or pushed.

## Usage

```
/task-build {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels,comments
```

Display:
- Task title and problem statement
- Acceptance criteria
- Subtasks (count and titles)

### 2. Blocked check

If the task has `flag:blocked`, read the related tasks comment and find all "Blocked by" issue numbers. Check each:
```bash
gh issue view {blocker} --repo {owner}/{repo} --json state
```

If any blocker is still open:
```
Task #{number} is blocked by #{blocker} which is not yet complete.
Complete that task first, then rerun /task-build {number}.
```
Stop.

If all blockers are closed: remove `flag:blocked` and continue.

### 3. Branch check

Determine the branch name: `task/{number}-{slug}` where slug is a lowercase kebab-case version of the title.

Check if it exists:
```bash
git branch --list "task/{number}-*"
```

**Branch does not exist — fresh build:**
```
Ready to build?
(y) yes  (n) not yet
```
On yes: `git checkout -b task/{number}-{slug} origin/main`

**Branch exists, status is `status:planned`** — a previous partial attempt. Show state:
```bash
git log origin/main..task/{number}-{slug} --oneline
git status --short
```
```
Branch task/{number}-{slug} already exists.
Committed: {summary from git log}
Uncommitted: {summary or "none"}

(r) resume from next subtask
(s) hard reset to origin/main — discards all local changes on this branch
(n) cancel
```
On `(s)`: `git reset --hard origin/main`

**Status is `status:defective`** — branch was already reset to `origin/main`:
```
Task #{number} was marked defective. Branch is at origin/main.
Ready to rebuild?
(y) yes  (n) not yet — run /task-edit {number} first
```

### 4. Update status

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:planned,status:defective" \
  --add-label "status:progress"
```

### 5. Execute subtasks

Work through subtasks in order. Do not stop between subtasks unless blocked by uncertainty.

**No guessing allowed:**
- If a subtask description or build notes are ambiguous, incomplete, or conflict with the codebase — stop and ask before writing code.
- If a decision requires knowledge not in the spec — stop and ask.
- If the codebase differs from what the spec assumes — stop and ask.

When stopping to ask, state:
- Which subtask triggered the question
- What is ambiguous or missing
- What options exist and which you lean toward

**On failure:**

If a subtask fails due to a code or runtime error:
1. Revert uncommitted changes: `git checkout .`
2. Hard reset the branch: `git reset --hard origin/main`
3. Update labels:
   ```bash
   gh issue edit {number} --repo {owner}/{repo} \
     --remove-label "status:progress" \
     --add-label "status:defective"
   ```
4. Report exactly which subtask failed and why.
5. "Run `/task-edit {number}` to fix the spec, then `/task-build {number}` to rebuild."

### 6. Verify

Run verification commands from the project's `AGENTS.md`. Stack defaults run first, then any project-specific additions. See `utils.md` for command resolution.

### 7. Update status

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:progress" \
  --add-label "status:built"
```

### 8. Report

Show a summary of what was built across all subtasks.

```
Task #{number} is built locally. Run /task-ship {number} when ready to commit and push.
```
