# task-view

Display a full task with all comments, labels, status, and branch info in a readable format. Read-only.

## Usage

```
/task-view {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json number,title,body,labels,comments,state
```

Also check for a local branch:
```bash
git branch --list "task/{number}-*"
```

### 2. Display

Output in this order:

```
#{number} — {title}
{status label}  {type label}  {size label}  {priority label}

PROBLEM
{problem statement}

USER STORIES
{user stories}

ACCEPTANCE CRITERIA
{criteria if posted, otherwise "(not yet planned)"}

SCOPE
{scope if posted, otherwise "(not yet planned)"}

RELATED TASKS
{relationships if posted, otherwise omit section}

SUBTASKS
{subtasks if posted, otherwise "(not yet planned)"}

PR
{pr link comment if posted, otherwise omit section}

BRANCH
{branch name if exists locally, otherwise "(none)"}
```

No interaction — display only.
