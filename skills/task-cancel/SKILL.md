# task-cancel

Close a task that will not be completed. Posts a reason comment, removes the task from its queue, and deletes the local branch if one exists.

## Usage

```
/task-cancel {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,labels,state
```

Display the title and current status. If the issue is already closed, report it and stop.

### 2. Reason

```
Reason for cancelling? (required)
```

Do not proceed without a reason.

### 3. Confirm

Determine what will be cleaned up:
- Check for a branch: `git branch --list "task/{number}-*"`
- Check queue membership by reading the global queue and any group queues

Show:
```
This will:
  • Close issue #{number} — {title}
  • Post cancellation reason as a comment
  • Remove from queue (if queued)
  • Delete branch task/{number}-{slug} (if it exists locally)

(y) yes  (n) cancel
```

### 4. Execute

Post comment:
```bash
gh issue comment {number} --repo {owner}/{repo} --body "Cancelled — {reason}"
```

Close issue:
```bash
gh issue close {number} --repo {owner}/{repo}
```

Remove from queue if present — edit the queue issue body to remove the line referencing this task. Graceful no-op if not found in any queue.

Delete local branch if it exists:
```bash
git branch -d task/{number}-{slug} 2>/dev/null || true
```

### 5. Confirm

```
Task #{number} cancelled.
```
