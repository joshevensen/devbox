# bug-retry

Cancel the current fix attempt and return to a clean state. Resets the branch to origin/main, returns status to planned, and prompts for next steps.

## Usage

```
/bug-retry {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels
```

Display the bug title, decided cause, and current branch state:
```bash
git log origin/main..bug/{number}-{slug} --oneline 2>/dev/null
git status --short 2>/dev/null
```

### 2. Confirm

```
This will:
  • Reset branch bug/{number}-{slug} to origin/main — discards all local changes
  • Return status to planned

(y) yes  (n) cancel
```

### 3. Execute

Revert uncommitted changes:
```bash
git checkout .
```

Hard reset branch:
```bash
git reset --hard origin/main
```

Update labels:
```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:progress,status:built,status:defective" \
  --add-label "status:planned"
```

### 4. Next step

```
What next?
(f) rerun /bug-fix {number} with a different approach
(e) go back to /bug-explore — reconsider the root cause
```

If `(e)`: note that a new `bug-explore` session will create a new issue. The user should decide whether to close the current issue or keep it open as context before proceeding.
