# prioritize-group

Reorder tasks within a specific group's queue interactively.

## Usage

```
/prioritize-group {number}
```

Where `{number}` is the group issue number.

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels
```

Confirm the issue has `type:group` label. Parse the `## Queue` section.

For each task, fetch current status and blocking relationships:
```bash
gh issue view {task-number} --repo {owner}/{repo} --json title,labels,comments
```

### 2. Display with context

```
GROUP QUEUE — Wholesale Management (#42)

1. [ ] #{number} — Scaffold wholesale model    (planned)
2. [ ] #{number} — Add pricing rules           (draft)    flag:blocked
3. [ ] #{number} — Build buyer invite flow     (draft)
```

Flag: closed tasks still in queue, `flag:blocked` items.

### 3. Recommend

Surface ordering concerns from blocking relationships:
```
RECOMMENDATION

⚠ #16 is blocked by #15, which appears later at position 3.
✓ No other ordering concerns.
```

### 4. Reorder

```
Make changes?
(m) move an item  (s) swap two items  (y) accept recommendation  (d) done
```

- `(m)`: ask item number, then destination position. Update and redisplay.
- `(s)`: ask two item numbers. Swap and redisplay.
- `(y)`: apply recommendations, redisplay for confirmation.
- Repeat until `(d)`.

### 5. Write

Update the group issue body with the new task ordering in the `## Queue` section.

```
Group #{number} queue updated.
```
