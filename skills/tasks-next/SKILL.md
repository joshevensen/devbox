# tasks-next

Find the next task to work on using the global queue. Drills into group queues automatically.

## Usage

```
/tasks-next
```

---

## Steps

### 1. Read global queue

Find the global queue issue:
```bash
gh issue list --repo {owner}/{repo} --state open --label "type:queue" \
  --json number,title,body --jq '.[] | select(.title == "Global Queue")'
```

If no global queue exists: fall back to step 4.

### 2. Find first unchecked item

Parse the `## Queue` section. Find the first line that starts with `- [ ]`.

**If it references a group** (`#{number} — Group:`):
- Read that group's issue body.
- Parse its `## Queue` section.
- Find the first unchecked task (`- [ ]`).
- Use that task.

**If it's a standalone task**: use it directly.

### 3. Display and prompt

Show the task via the equivalent of `task-view {number}`.

```
Work on #{number} — {title}?
(y) yes — run /task-build {number}
(n) show me more options
```

If `(n)`: show the next 3 items in the queue (or planned tasks by priority if queue is short).

### 4. Fallback (no queue or empty queue)

```bash
gh issue list --repo {owner}/{repo} --state open \
  --label "status:planned" --json number,title,labels --limit 20
```

Display planned tasks grouped by priority (high → medium → low). Ask which one to work on.

Bugs are never in the queue and are not surfaced by this skill.
