# bug-view

Display a full bug with all comments, status, and branch info in a readable format. Read-only.

## Usage

```
/bug-view {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json number,title,body,labels,comments,state
```

Also check for a local branch:
```bash
git branch --list "bug/{number}-*"
```

### 2. Display

Output in this order:

```
#{number} — {title}
{status label}  {size label}  {priority label}  type:bug

DESCRIPTION
{description}

SENTRY
{sentry links, or "None"}

STEPS TO REPRODUCE
{reproduce steps}

POTENTIAL CAUSES
{if posted, otherwise "(not yet explored)"}

ROOT CAUSE
{if posted, otherwise "(not yet determined)"}

TEST PLAN
{if posted, otherwise "(not yet written)"}

SUBTASKS
{if posted, otherwise "(not yet written)"}

PR
{pr link if posted, otherwise omit section}

BRANCH
{branch name if exists locally, otherwise "(none)"}
```

No interaction — display only.
