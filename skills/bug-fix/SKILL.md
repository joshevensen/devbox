# bug-fix

Execute a planned bug's subtasks on a branch. Stops when all subtasks are done and verified locally. Nothing is committed or pushed.

## Usage

```
/bug-fix {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels,comments
```

Display:
- Bug title and description
- Decided cause
- Subtasks (count and titles)

### 2. Branch check

Branch naming: `bug/{number}-{slug}` where slug is a lowercase kebab-case version of the title.

Check if it exists:
```bash
git branch --list "bug/{number}-*"
```

**Branch does not exist — fresh fix:**
```
Ready to fix?
(y) yes  (n) not yet
```
On yes: `git checkout -b bug/{number}-{slug} origin/main`

**Branch exists, status is `status:planned`** — previous partial attempt:
```bash
git log origin/main..bug/{number}-{slug} --oneline
git status --short
```
```
Branch bug/{number}-{slug} already exists.
Committed: {summary}
Uncommitted: {summary or "none"}

(r) resume from next subtask
(s) hard reset to origin/main — discards all local changes on this branch
(n) cancel
```

**Status is `status:defective`** — branch already reset to `origin/main`:
```
Bug #{number} was marked defective. Branch is at origin/main.
Ready to rebuild?
(y) yes  (n) not yet
```

### 3. Update status

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:planned,status:defective" \
  --add-label "status:progress"
```

### 4. Execute subtasks

Work through subtasks in order. Do not stop between subtasks unless blocked by uncertainty.

**No guessing allowed:**
- Ambiguous or incomplete build notes → stop and ask
- Decision not covered by the spec → stop and ask
- Codebase differs from spec assumptions → stop and ask

When stopping to ask, state which subtask triggered it, what is ambiguous, and what options exist.

**On failure:**
1. Revert uncommitted changes: `git checkout .`
2. Hard reset branch: `git reset --hard origin/main`
3. Update labels:
   ```bash
   gh issue edit {number} --repo {owner}/{repo} \
     --remove-label "status:progress" \
     --add-label "status:defective"
   ```
4. Report which subtask failed and why.
5. "Fix the subtask spec and rerun `/bug-fix {number}`, or run `/bug-retry {number}` to try a different approach."

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
Bug #{number} is built locally. Run /bug-ship {number} when ready to commit and push.
```
