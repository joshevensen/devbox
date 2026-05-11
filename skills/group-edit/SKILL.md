# group-edit

Rename a group or update its description.

## Usage

```
/group-edit {number}
```

---

## Steps

### 1. Load

```bash
gh issue view {number} --repo {owner}/{repo} --json title,body,labels
```

Confirm the issue has `type:group` label. Display the current name (title) and description.

### 2. Choose what to edit

```
What do you want to edit?
(n) name  (d) description  (b) both
```

### 3. Edit

Accept new values. Show a clear diff of what will change:

```
Apply this change?
(y) yes  (e) keep editing  (n) cancel
```

### 4. Write

Update name (issue title):
```bash
gh issue edit {number} --repo {owner}/{repo} --title "{new name}"
```

Update description (replace the `## Description` section in the body):
```bash
gh issue edit {number} --repo {owner}/{repo} --body "{updated body}"
```

If the name changed, also update the group's entry in the global queue to reflect the new name.

### 5. Confirm

```
Group #{number} updated.
```
