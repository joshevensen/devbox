# task-edit

Edit any part of a task issue — body, acceptance criteria, scope, related tasks, or subtasks. Shows current content, proposes the change, and confirms before writing.

## Usage

```
/task-edit {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels,comments
```

Display the current state of all sections: body, and each structured comment (acceptance criteria, scope, related tasks, subtasks).

### 2. Choose section

```
What do you want to edit?
(b) problem / user stories (body)
(a) acceptance criteria
(s) scope
(r) related tasks
(t) subtasks
```

### 3. Edit

Show the full current content of the chosen section. Accept the new content interactively. Show a clear diff of what will change:

```
Apply this change?
(y) yes  (e) keep editing  (n) cancel
```

### 4. Write

For the body: update the issue body via `gh issue edit`.
For a comment section: find the comment by its heading (`## Acceptance Criteria`, `## Scope`, etc.) and replace it via `gh api` PATCH on the comment ID.

### 5. Confirm

```
Task #{number} updated.
```

Offer to edit another section:
```
Edit another section?
(y) yes  (n) done
```
