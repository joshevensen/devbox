# work-summary

Show recent activity and current work-in-progress: what's in progress, what's in review, and what shipped recently.

## Usage

```
/work-summary
```

---

## Steps

### 1. Fetch

Run in parallel:

```bash
# In progress
gh issue list --repo {owner}/{repo} --state open \
  --label "status:progress" --json number,title,labels

# In review (open PRs)
gh pr list --repo {owner}/{repo} --state open \
  --json number,title,headRefName,createdAt

# Recently closed issues (last 14 days)
gh issue list --repo {owner}/{repo} --state closed \
  --json number,title,labels,closedAt --limit 50
```

### 2. Process

- In progress: all issues with `status:progress`
- In review: all open PRs — extract issue number from branch name (`task/{number}-*`, `bug/{number}-*`, `refactor/{number}-*`)
- Shipped this week: closed issues from last 7 days
- Shipped last week: closed issues from 7–14 days ago

### 3. Display

```
IN PROGRESS
#31  Wholesale pricing      feature   large

IN REVIEW
PR #47  feat(#31): wholesale pricing    (opened 2 days ago)

SHIPPED THIS WEEK
#22  Add webhook retry      feature   (merged 2 days ago)
#18  Buyer invite flow      feature   (merged 5 days ago)

SHIPPED LAST WEEK
#15  Fix tax rate bug       bug       (merged 9 days ago)
```

Omit empty sections. If nothing in any section: "No recent activity."
