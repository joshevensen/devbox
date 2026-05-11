# tasks-list

List open tasks grouped by status. Optionally filter by status or group.

## Usage

```
/tasks-list
/tasks-list {status}
/tasks-list group:{number}
```

---

## Steps

### 1. Fetch

```bash
gh issue list --repo {owner}/{repo} --state open \
  --json number,title,labels --limit 200
```

Filter to issues that have a `type:*` label that is NOT `type:queue` or `type:group`.

If filtering by group: read that group's queue issue to get the list of task numbers, then fetch only those.

### 2. Group by status

Bucket into: DRAFT, PLANNED, PROGRESS, BUILT, SHIPPED, REVIEW.

If a status filter was provided: show only that bucket.

### 3. Display

```
DRAFT
#41  Revamp onboarding flow       feature   large    high
#34  Add bulk export              feature   small    medium

PLANNED
#28  Fix session timeout          chore     small    low

PROGRESS
#31  Wholesale pricing            feature   large    high

BUILT
#29  Update email templates       chore     medium   medium

SHIPPED
#22  Add webhook retry            feature   medium   medium

REVIEW
#18  Buyer invite flow            feature   large    high
```

Omit empty buckets. If no tasks found: "No open tasks."
