# bugs-list

List open bugs grouped by status.

## Usage

```
/bugs-list
/bugs-list {status}
```

---

## Steps

### 1. Fetch

```bash
gh issue list --repo {owner}/{repo} --state open \
  --label "type:bug" --json number,title,labels --limit 200
```

### 2. Group by status

Bucket into: PLANNED, PROGRESS, BUILT, SHIPPED, REVIEW.

If a status filter was provided: show only that bucket.

### 3. Display

```
PLANNED
#44  Checkout fails with discount code    small    high
#47  Wrong avatar shown after logout      small    medium

PROGRESS
#39  Email not sent on order              medium   high

BUILT
#36  Wrong tax rate on EU orders          small    medium

REVIEW
#33  Session expires too early            small    low
```

Omit empty buckets. If no open bugs: "No open bugs."
