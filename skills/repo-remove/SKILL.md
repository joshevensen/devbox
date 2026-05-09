# repo-remove

Removes a repo's devbox registration. By default removes the config and secrets; optionally drops the Postgres database. Does not touch the bare repo on disk unless explicitly asked.

## Usage

```
/repo-remove <name>
```

---

## Steps

### 1. Verify the repo exists

```bash
ls ~/devbox/repos/<name>.yaml 2>/dev/null
```

If the file does not exist, stop and tell the user: "No devbox config found for `<name>`. Run `/repo-list` to see registered repos."

### 2. Show what will be removed and confirm

Display:
```
About to remove devbox registration for <name>:

  ~/devbox/repos/<name>.yaml      (stack config)
  ~/devbox/.secrets/<name>.env    (if it exists)

Postgres role + database "<name>" will NOT be dropped unless you confirm below.
```

Ask the user two questions before continuing:
1. Confirm removal of the config + secrets files (yes/no).
2. Whether to also drop the Postgres role and database (yes/no — default no, flag as destructive and irreversible).

Do not proceed until the user confirms question 1.

### 3. Remove config and secrets

```bash
rm ~/devbox/repos/<name>.yaml
rm -f ~/devbox/.secrets/<name>.env
```

### 4. Drop Postgres (if confirmed)

```bash
psql -U postgres -c "DROP DATABASE IF EXISTS <name>;"
psql -U postgres -c "DROP ROLE IF EXISTS <name>;"
```

### 5. Summary

```
Removed devbox registration for <name>.

  ✓ ~/devbox/repos/<name>.yaml deleted
  ✓ ~/devbox/.secrets/<name>.env deleted (or: not found, skipped)
  ✓ Postgres role + database dropped  (or: skipped)

Note: ~/repos/<name>/ (the bare repo and worktrees) was left on disk.
To remove it: rm -rf ~/repos/<name>/
```
