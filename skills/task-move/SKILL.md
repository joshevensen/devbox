# task-move

Move one or more tasks between groups, or to/from standalone in the global queue. Accepts multiple task numbers in one command.

## Usage

```
/task-move {number} [{number} ...]
```

---

## Steps

### 1. Load

For each task number, read the issue title and find its current queue position:
```bash
gh issue view {number} --repo {owner}/{repo} --json title,labels
```

Search the global queue and all group queues for each task number to determine current placement.

Display:
```
#12 — {title}  currently: Group: Wholesale Management
#15 — {title}  currently: standalone (global queue)
#18 — {title}  currently: not in any queue
```

### 2. Destination

```
Move to:
(g) global queue as standalone
(m) a group
```

If `(m)`: list all open groups by number and name. Ask which one.

### 3. Confirm

```
Move the following to {destination}?
  #12 — {title}
  #15 — {title}

(y) yes  (n) cancel
```

### 4. Execute

For each task:

1. Remove from current queue if present — edit the queue issue body to remove the task's line. Graceful no-op if not currently queued.

2. Add to destination queue — append to the end of the destination queue issue body.

Queue entry format:
```
- [ ] #{number} — {title}
```

### 5. Confirm

```
Moved {count} task(s) to {destination}.
```
