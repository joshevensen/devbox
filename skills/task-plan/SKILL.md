# task-plan

Flesh out a draft task into a full spec: acceptance criteria, scope, related tasks, and subtasks. Transitions the issue from `status:draft` to `status:planned`.

## Usage

```
/task-plan {number}
```

---

## Steps

### 1. Load

Read the issue body and labels:
```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels
```
Display the problem statement and user stories. Ask any clarifying questions needed to understand scope, constraints, and what "done" looks like before proceeding.

### 2. Scope check

Do a read-only codebase scan to estimate how many files this task will touch.

- 1–20 files: proceed
- 21–30 files: acceptable if tightly coupled
- 30+ files: recommend splitting unless it's a mechanical refactor

If recommending a split:
```
This task should be split. Proposed split:
  1. {title}
  2. {title}
(s) split as proposed  (n) narrow and proceed  (p) proceed anyway
```
If `(s)`: stop. Run `/task-split {number}` to create the child tasks.

### 3. Acceptance criteria

Generate discrete, verifiable conditions. Show them:
```
Acceptance criteria — look right?
(y) yes  (e) edit  (a) add more  (n) start over
```

### 4. Scope

Generate in scope / out of scope. Show:
```
Scope — look right?
(y) yes  (e) edit  (n) start over
```

### 5. Related tasks

```
Any related tasks?
(y) yes  (n) no
```
If yes: ask for issue numbers and relationship type (split from, blocked by, blocks, related).

### 6. Subtasks

Generate subtasks. Each must have:
- A title
- A description (what it does and why)
- Build notes (specific files, functions, constraints, expected outcome)

Show them:
```
Subtasks — look right?
(y) yes  (e) edit one  (a) add one  (d) delete one  (n) start over
```

### 7. Post comments

Post each section as a separate comment in this order:
1. Acceptance criteria
2. Scope
3. Related tasks (omit if none)
4. Subtasks

Comment format for each:

**Acceptance criteria:**
```markdown
## Acceptance Criteria

- [ ] {condition}
```

**Scope:**
```markdown
## Scope

### In Scope
- {item}

### Out of Scope
- {item}
```

**Related tasks:**
```markdown
## Related Tasks

- **{Relationship}:** #{number}
```

**Subtasks:**
```markdown
## Subtasks

### 1 — {Title}

{Description}

**Build notes:** {files, functions, constraints, expected outcome}

---

### 2 — {Title}
...
```

### 8. Update labels

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:draft" \
  --add-label "status:planned"
```

Update `size:*` if the scope assessment changed the estimate. Add `flag:blocked` if a "Blocked by" relationship was recorded.

### 9. Confirm

```
Task #{number} is planned. Run /task-build {number} when ready.
```
