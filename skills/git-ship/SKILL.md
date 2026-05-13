# git-ship

Inspect all pending changes, group them into logical commits with conventional commit messages, confirm with the user, then commit and push.

## Usage

```
/git-ship
```

---

## Steps

### 1. Survey changes

```bash
git status --short
git diff HEAD
git log --oneline -5
```

Collect:
- All modified, added, deleted, renamed, and untracked files (staged and unstaged)
- The full diff for each file
- The last 5 commits to match the project's commit style

If there are no changes (clean working tree and index), stop: "Nothing to commit. Working tree is clean."

### 2. Analyze and group

Read the diffs and group files by logical concern. A group is a set of changes that belong in a single atomic commit — something a reviewer would want to see together.

Good grouping signals:
- Files in the same feature area (e.g. all changes to a new CLI flag)
- Same change type across files (e.g. updating docs for a new install step)
- Coupled changes that don't make sense independently (e.g. a migration + its model change)
- Config/tooling changes separate from application logic
- Test changes separate from implementation changes (unless they're a single new feature)

When in doubt, fewer larger commits are better than many tiny ones. Don't split changes that are inseparable.

### 3. Draft commit messages

For each group, write a conventional commit message:

```
<type>(<scope>): <short imperative summary>

<optional body — what changed and why, bullet points if multiple things>
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `style`, `test`, `ci`, `build`

Scope is optional but helpful when it narrows the area (e.g. `feat(auth):`, `docs(caddy):`).

Subject line rules:
- Imperative mood: "add X", "fix Y", not "added" or "fixes"
- Under 72 characters
- No period at the end

Body rules:
- Only include if the subject line doesn't tell the full story
- Explain *why*, not just *what* (the diff shows what)
- Bullet points for multiple distinct changes in one commit

Match the style of recent commits in the repo.

### 4. Present the plan

Show the proposed commit plan:

```
Proposed commits (2):

① docs(caddy): document xcaddy build process
  scripts/caddy.service
  docs/caddy.md

② feat(install): add GitHub CLI and devbox@.service to bootstrap
  install.sh
  scripts/devbox@.service
```

Then ask:

```
(y) looks good — commit and push
(e) edit — I'll describe what to change
(r) re-group — I'll describe how to split or combine
(n) cancel
```

Wait for a response before proceeding.

If the user says `(e)` or `(r)`, incorporate their feedback and re-present the plan. Repeat until they confirm with `(y)` or cancel with `(n)`.

### 5. Commit each group

For each group in order:

1. Stage only the files in this group (do NOT use `git add -A` or `git add .`):
   ```bash
   git add <file1> <file2> ...
   ```
   For untracked files, use `git add` as well. For deleted files, use `git rm`.

2. Commit with the drafted message:
   ```bash
   git commit -m "$(cat <<'EOF'
   <message>
   EOF
   )"
   ```

3. Report: `✓ Committed: <subject line>`

If any commit fails (e.g. pre-commit hook), stop immediately, show the error, and tell the user to fix it before continuing. Do NOT use `--no-verify`.

### 6. Push

```bash
git push
```

If the branch has no upstream yet:
```bash
git push -u origin HEAD
```

### 7. Report

```
Pushed {n} commit(s) to {remote}/{branch}.

  <sha> <subject>
  <sha> <subject>
```
