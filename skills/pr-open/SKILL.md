# pr-open

Open a pull request for a shipped task or bug. Drafts the PR body, creates the PR, posts the URL to the issue, updates status, and checks off the queue entry.

## Usage

```
/pr-open {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels,comments
```

Confirm the issue has `status:shipped`. If not, stop and report the current status.

Display the title and acceptance criteria (tasks) or test plan (bugs).

Determine issue type from `type:*` label. Derive branch name: `task/{number}-{slug}` or `bug/{number}-{slug}`.

### 2. Prepare PR body

Draft the PR body:

```markdown
Closes #{number}

## Description

{2–4 sentences on what was accomplished and why it matters}

## Changes

- `{file}` — {one-line note}
- `{file}` — {one-line note}

## Test Plan

- [ ] {specific step a reviewer can follow}
- [ ] {specific step}
```

PR title:
```
{type}(#{number}): {short title}
```

Where `{type}` maps from the label: `type:feature` → `feat`, `type:bug` → `fix`, `type:chore` → `chore`, `type:docs` → `docs`, `type:refactor` → `refactor`.

### 3. Show and confirm

```
Does this look right?
(y) yes  (e) edit  (n) start over
```

### 4. Open PR

```bash
gh pr create --repo {owner}/{repo} \
  --title "{title}" \
  --body "{body}" \
  --base main \
  --head {branch}
```

### 5. Comment on issue

Post the PR URL as a comment:
```bash
gh issue comment {number} --repo {owner}/{repo} --body "{pr-url}"
```

### 6. Update status

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:shipped" \
  --add-label "status:review"
```

### 7. Update queue

Find the issue's entry in the global queue or its group queue. Mark it as checked:
- Change `- [ ] #{number}` to `- [x] #{number}` in the queue issue body.
- If the issue is not in any queue: skip — graceful no-op.
- If all items in a group queue are now checked: also check off the group in the global queue.

### 8. Report

```
PR #{pr} is open. Run /pr-feedback {number} to handle review comments, then /pr-review {number} when ready.
```
