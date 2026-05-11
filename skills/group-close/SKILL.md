# group-close

Close a completed or abandoned group. Warns if tasks are still open. Removes the group from the global queue.

## Usage

```
/group-close {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels,state
```

Confirm the issue has `type:group` label. Display the group name and task list.

### 2. Check for open tasks

Parse the `## Queue` section of the group issue body. For each unchecked task (`- [ ]`), fetch its current status:
```bash
gh issue view {task-number} --repo {owner}/{repo} --json title,labels,state
```

If any tasks are still open:
```
{n} tasks in this group are not yet complete:
  #{number} — {title}  ({status})
  #{number} — {title}  ({status})

Close anyway?
(y) yes  (n) cancel
```

### 3. Confirm

```
This will:
  • Close group issue #{number} — {name}
  • Remove from global queue

(y) yes  (n) cancel
```

### 4. Execute

Close the group issue:
```bash
gh issue close {number} --repo {owner}/{repo}
```

Remove the group's line from the global queue issue body (find and delete the line referencing `#{number}`).

### 5. Confirm

```
Group #{number} '{name}' closed.
```
