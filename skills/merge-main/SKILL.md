# merge-main

Merge the latest `main` into the current branch. Helps resolve conflicts interactively if they arise.

## Usage

```
/merge-main
```

---

## Steps

### 1. Check branch

```bash
git branch --show-current
```

If on `main`: stop. "Cannot merge main into itself. Check out your working branch first."

Show the current branch name before proceeding.

### 2. Fetch and merge

```bash
git fetch origin main
git merge origin/main
```

### 3. If clean

```
Merged latest main into {branch}.
```

Done.

### 4. If conflicts

List conflicting files:
```bash
git diff --name-only --diff-filter=U
```

For each conflicting file, show the conflict markers:
```bash
grep -n "^<<<<<<\|^======\|^>>>>>>" {file}
```

Present each conflict:
```
Conflict in {file}:{line}:

OURS ({branch}):
{our content}

THEIRS (main):
{their content}

(r) resolve — propose a resolution
(s) skip — I'll resolve this manually
(a) abort merge
```

If `(r)`:
- Show the proposed resolution clearly.
- Confirm: `Apply this resolution? (y) yes  (e) edit  (n) skip`
- On yes: write the resolved content, stage the file: `git add {file}`

If `(a)`: `git merge --abort` and report "Merge aborted. Branch is unchanged."

### 5. After all conflicts

If all conflicts were resolved:
```bash
git merge --continue
```
Report: "Merged latest main into {branch}. All conflicts resolved."

If any conflicts were skipped:
```
{n} conflict(s) remaining in:
  {file}
  {file}

Resolve them manually, then run `git merge --continue`.
```
