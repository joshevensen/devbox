# group-create

Create a new group issue and optionally place it in the global queue.

## Usage

```
/group-create
```

---

## Steps

### 1. Name

```
Group name?
```

### 2. Description

```
Short description? (n) skip
```

### 3. Create issue

```bash
gh issue create --repo {owner}/{repo} \
  --title "{name}" \
  --body "## Description

{description or "(No description provided.)"}

## Queue

" \
  --label "type:group"
```

Note the new issue number — this is the group number.

### 4. Global queue

```
Add to global queue?
(e) end  (p) choose position  (n) skip
```

If `(e)`: append to the global queue issue body:
```
- [ ] #{number} — Group: {name}
```

If `(p)`: show the current global queue with numbered lines. Ask for a position number. Insert the group entry at that position.

To find the global queue:
```bash
gh issue list --repo {owner}/{repo} --state open --label "type:queue" \
  --json number,title --jq '.[] | select(.title == "Global Queue")'
```

### 5. Confirm

```
Group #{number} '{name}' created. Add tasks with /task-create or /task-move.
```
