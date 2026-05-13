# task-create

Capture a new task as a GitHub issue. Walks through problem statement, user stories, size, priority, type, and queue placement. Checks for duplicates before creating.

## Usage

```
/task-create
```

---

## Steps

### 1. Problem

Ask for the raw idea. Ask enough follow-up to understand:
- What problem or pain is this solving?
- What outcome makes this worth doing?
- Any constraints, links, or context to preserve?

Draft the problem statement and show it:
```
Does this capture it?
(y) yes  (e) edit  (n) start over
```

### 2. Duplicate check

Search open issues for similar tasks:
```bash
gh issue list --repo {owner}/{repo} --state open --search "{keywords}" --json number,title
```

If a possible duplicate is found:
```
Possible duplicate: #{number} — {title}
(c) continue anyway  (v) view that issue  (n) cancel
```
If `(v)`: display the issue body, then return to this prompt.

### 3. User stories

Generate 1–3 user stories from the problem statement. Show them:
```
Do these look right?
(y) yes  (e) edit  (s) skip
```

### 4. Codebase scan

```
Quick codebase scan to estimate size and touch points?
(y) yes  (n) no
```
If yes: do a read-only scan, summarize findings, note dependencies and risks.
If no: estimate size from context only.

### 5. Metadata

Derive a recommendation for each field from the problem statement and codebase scan (if done). Mark each recommended option with ✓. Display all four together and collect one response:

```
METADATA — (y) accept all recommendations

  Size:      (S) small    (M) medium    (L) large       {reason}
  Priority:  (H) high     (N) normal    (W) low         {reason}
  Type:      (F) feature  (B) bug  (C) chore  (D) docs  (R) refactor   {reason}
  Title:     (U) use "{suggested title}"   (O) provide my own

Enter (y) to accept all, or type letters to override (e.g. "L H f O"):
```

Parse the response:
- `(y)` or blank: apply all recommendations.
- Any other input: each letter overrides its field; fields not mentioned keep their recommendation.
- If the response includes `O`: ask for the custom title before proceeding.

### 6. Queue

```
Add to queue?
(g) global queue as standalone
(m) assign to a group
(n) skip
```
If `(m)`: list existing groups by number and name, ask which one. Default to end of that group's queue.

### 7. Create

Write the issue body:
```markdown
## Problem

{problem statement}

## User Stories

- As a {role}, I want to {action} so that {outcome}.
```

Create the GitHub issue:
```bash
gh issue create --repo {owner}/{repo} \
  --title "{title}" \
  --body "{body}" \
  --label "status:draft,type:{type},size:{size},priority:{priority}"
```

If queued: add to the appropriate queue issue body.

### 8. Confirm

```
Task #{number} created. Run /task-plan {number} when ready.
```
