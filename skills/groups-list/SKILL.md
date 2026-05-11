# groups-list

List all open groups with task counts and completion status. Read-only.

## Usage

```
/groups-list
```

---

## Steps

### 1. Fetch groups

```bash
gh issue list --repo {owner}/{repo} --state open --label "type:group" \
  --json number,title,body --limit 100
```

### 2. Enrich each group

For each group, parse the `## Queue` section to count total tasks and checked-off tasks.

### 3. Display

```
GROUPS

#42  Wholesale Management    3/7 tasks complete
#51  Analytics               0/4 tasks complete
#38  Email Redesign          6/6 tasks complete  ✓
```

Sort: incomplete groups first (by issue number), complete groups last.

If no open groups exist:
```
No open groups. Create one with /group-create.
```
