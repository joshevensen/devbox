# task-split

Split an oversized task into two or more smaller tasks. Closes the original, creates child tasks as drafts with a "split from" relationship, and inserts them into the queue at the original's position.

## Usage

```
/task-split {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels,comments
```

Display the title, problem statement, and subtasks.

### 2. Propose split

Suggest how to divide the work into 2–3 child tasks. Each proposal needs a title and a brief scope summary.

```
Proposed split:
  1. {title} — {scope}
  2. {title} — {scope}

(y) yes  (e) edit  (n) cancel
```

### 3. Branch warning

Check if a branch exists for the original:
```bash
git branch --list "task/{number}-*"
git branch -r | grep "task/{number}-"
```

If found:
```
⚠ Branch task/{number}-{slug} exists. Any work on it will not be carried over automatically.
Handle that branch manually before proceeding.
(y) continue  (n) cancel
```

### 4. Create children

For each child task, run through the `task-create` flow:
- Pre-populate problem statement and user stories from the original where applicable
- Ask for size, priority, and type (can inherit from original with confirmation)
- Suggest a title based on the proposed scope
- Do not queue yet — queue placement happens in step 5

After creating each issue, note the new issue number.

Add a "Split from: #{original}" relationship comment to each child immediately after creation:
```markdown
## Related Tasks

- **Split from:** #{original}
```

Set each child to `status:draft`.

### 5. Queue

Find the original task's position in its queue (global or group). Insert all children at that position in order, replacing the original's entry.

If the original was not in any queue: skip.

### 6. Close original

Post a comment on the original issue:
```markdown
Split into:
- #{child1} — {title}
- #{child2} — {title}
```

Close the issue:
```bash
gh issue close {number} --repo {owner}/{repo}
```

### 7. Confirm

```
Task #{number} split into #{child1} and #{child2}.
Run /task-plan on each when ready.
```
