# Group Process: Organizing and Ordering Work

This document defines how groups and queues work. A group contains tasks (bugs are never queued). The task flow is in `task-process.md`. Queue navigation and prioritization skills are in `utils.md`.

Skills should be updated to match this spec, not the other way around.

---

## Terminology

| Term        | GitHub primitive                  |
|-------------|-----------------------------------|
| group       | issue with `type:group` label     |
| queue       | issue with `type:queue` label     |

---

## What is a Group?

A group is a named collection of related tasks. It can represent a feature set, a release batch, a refactor sweep, or any other logical grouping.

A group is a single GitHub issue with the `type:group` label. It holds the group name, description, and task queue all in one place. The group's number is its GitHub issue number.

---

## Group Issue Structure

```markdown
## Description

{What this group is for and why the tasks within it are related.}

## Queue

- [ ] #{number} — {task title}
- [ ] #{number} — {task title}
- [ ] #{number} — {task title}
```

Groups are never closed until all tasks are complete or the group is explicitly abandoned via `group-close`.

---

## Global Queue Structure

One per repository. A single GitHub issue with `type:queue` label titled "Global Queue". Orders groups and standalone tasks against each other.

```markdown
## Queue

- [ ] #{group-number} — Group: {name}
- [ ] #{task-number} — {task title}
- [ ] #{group-number} — Group: {name}
- [ ] #{task-number} — {task title}
```

- Each line is either a group issue reference or a standalone task.
- Items are checked off when their PR merges (`pr-open` handles this).
- When all tasks in a group are checked off, the group line in the global queue is also checked off.

---

## Skills

### group-create

Creates a new group issue and optionally adds it to the global queue.

**Usage:** `/group-create`

1. **Name** — Ask for a name.
   ```
   Group name?
   ```

2. **Description** — Ask for an optional description.
   ```
   Short description? (n) skip
   ```

3. **Create issue** — Create the GitHub issue:
   ```bash
   gh issue create --repo {owner}/{repo} \
     --title "{name}" \
     --body "## Description\n\n{description}\n\n## Queue\n\n" \
     --label "type:group"
   ```

4. **Global queue** — Ask where to add the group.
   ```
   Add to global queue?
   (e) end  (p) choose position  (n) skip
   ```
   If `(p)`: show the current global queue and ask for a position number. Insert at that position.
   If `(e)`: append to end of global queue.

5. **Confirm** — "Group #{number} '{name}' created. Add tasks with `/task-create` or `/task-move`."

---

### group-edit

Rename a group or update its description.

**Usage:** `/group-edit {number}`

1. **Load** — Read the group issue. Display current name and description.

2. **Choose what to edit.**
   ```
   What do you want to edit?
   (n) name  (d) description  (b) both
   ```

3. **Edit** — Accept new values. Show what will change. Confirm before writing.

4. **Write** — Update the issue title and/or description section via `gh issue edit`.

5. **Confirm** — "Group #{number} updated."

---

### group-close

Close a completed or abandoned group. Removes it from the global queue.

**Usage:** `/group-close {number}`

1. **Load** — Read the group issue. Display name and current task list with statuses.

2. **Check for open tasks** — If any tasks in the queue are not yet checked off:
   ```
   {n} tasks in this group are not yet complete:
     #{number} — {title} (status)
     ...

   Close anyway?
   (y) yes  (n) cancel
   ```

3. **Confirm** — Show what will happen:
   ```
   This will:
     • Close group issue #{number} — {name}
     • Remove from global queue

   (y) yes  (n) cancel
   ```

4. **Execute** —
   - Close the issue: `gh issue close {number} --repo {owner}/{repo}`
   - Remove the group's line from the global queue issue body.

5. **Confirm** — "Group #{number} '{name}' closed."

---

### group-view

Display a group's details and full task list with current statuses.

**Usage:** `/group-view {number}`

1. **Load** — Read the group issue:
   ```bash
   gh issue view {number} --repo {owner}/{repo} --json title,body,labels,state
   ```

2. **Enrich task list** — For each task number in the queue, fetch its current status label:
   ```bash
   gh issue view {task-number} --repo {owner}/{repo} --json title,labels
   ```

3. **Display:**
   ```
   #{number} — {name}
   type:group

   DESCRIPTION
   {description}

   QUEUE
   1. [x] #{number} — {title}  (shipped)
   2. [ ] #{number} — {title}  (planned)
   3. [ ] #{number} — {title}  (draft)
   ```

   Show a summary at the end:
   ```
   {done}/{total} tasks complete
   ```

No interaction — display only.
