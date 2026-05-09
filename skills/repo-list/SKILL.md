# repo-list

Lists all repos registered with devbox, showing their stack and whether any branch environments are currently running.

## Usage

```
/repo-list
```

---

## Steps

### 1. Find registered repos

```bash
ls ~/devbox/repos/*.yaml 2>/dev/null
```

If no files exist, tell the user: "No repos registered yet. Use `/repo-add <git-url>` to add one."

### 2. For each repo, read its config

```bash
cat ~/devbox/repos/<name>.yaml
```

Extract the `stack:` value.

### 3. Check for running branch environments

```bash
systemctl list-units 'devbox@*' --no-legend --state=active 2>/dev/null
```

Match running units against each repo name to identify active branches.

### 4. Display results

Format as a table:

```
Registered repos:

  NAME          STACK               RUNNING BRANCHES
  fibermade     laravel-inertia     main, task-001
  myapi         python-uvicorn      —
```

If no branch environments are running for a repo, show `—` in that column.
