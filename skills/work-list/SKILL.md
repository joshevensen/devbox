# work-list

Show all open work — tasks, bugs, and groups — in one view.

## Usage

```
/work-list
```

---

## Steps

### 1. Fetch everything

```bash
gh issue list --repo {owner}/{repo} --state open \
  --json number,title,labels --limit 200
```

Partition results:
- `type:group` → groups
- `type:bug` → bugs
- `type:queue` → discard
- everything else → tasks

For groups: parse each group's `## Queue` section to get task counts.

### 2. Display

```
GROUPS
#42  Wholesale Management    3/7 tasks complete
#51  Analytics               0/4 tasks complete

TASKS
  PROGRESS
  #31  Wholesale pricing      feature   large    high

  PLANNED
  #28  Fix session timeout    chore     small    low
  #34  Add bulk export        feature   small    medium

  DRAFT
  #41  Revamp onboarding      feature   large    high

BUGS
  PROGRESS
  #39  Email not sent         medium   high

  PLANNED
  #44  Checkout discount      small    high
```

Omit sections with no items. If nothing is open: "No open work."
