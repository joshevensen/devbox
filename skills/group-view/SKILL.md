# group-view

Display a group's description and full task list with current statuses. Read-only.

## Usage

```
/group-view {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json number,title,body,labels,state
```

Confirm the issue has `type:group` label.

### 2. Enrich task list

Parse the `## Queue` section of the group body. For each task number (both checked and unchecked), fetch the current title and status:
```bash
gh issue view {task-number} --repo {owner}/{repo} --json title,labels,state
```

### 3. Display

```
#{number} — {name}
type:group  {state}

DESCRIPTION
{description or "(none)"}

QUEUE
1. [x] #{number} — {title}  (review)
2. [x] #{number} — {title}  (shipped)
3. [ ] #{number} — {title}  (planned)
4. [ ] #{number} — {title}  (draft)

{done}/{total} tasks complete
```

No interaction — display only.
