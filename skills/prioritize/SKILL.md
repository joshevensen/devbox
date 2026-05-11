# prioritize

Reorder the global queue interactively. Surfaces blocking relationship concerns and recommends an ordering.

## Usage

```
/prioritize
```

---

## Steps

### 1. Load

Find and read the global queue:
```bash
gh issue list --repo {owner}/{repo} --state open --label "type:queue" \
  --json number,title,body --jq '.[] | select(.title == "Global Queue")'
```

For each item in the queue, fetch current status and any blocking relationships (from the issue's related tasks comment).

### 2. Display with context

```
GLOBAL QUEUE

1. [ ] #{number} — Group: Wholesale Management  →  4 tasks remaining
2. [ ] #{number} — Fix CSV export               (planned)
3. [ ] #{number} — Group: Analytics             →  6 tasks, not started
4. [ ] #{number} — Update docs                  (draft)
```

Flag problems:
- Closed issues still in the queue
- Groups with no tasks
- Items with `flag:blocked`

### 3. Recommend

Analyze blocking relationships and surface ordering concerns:
```
RECOMMENDATION

⚠ #12 is blocked by #18, which appears later at position 4. Consider moving #12 after #18.
✓ No other ordering concerns.
```

If no issues: "The current order looks good."

### 4. Reorder

```
Make changes?
(m) move an item  (s) swap two items  (y) accept recommendation  (d) done
```

- `(m)`: ask which item number, then destination position. Update and redisplay.
- `(s)`: ask for two item numbers. Swap and redisplay.
- `(y)`: apply recommended changes, then redisplay for confirmation.
- Repeat until `(d)`.

### 5. Write

Update the global queue issue body with the new ordering.

```
Global queue updated.
```
