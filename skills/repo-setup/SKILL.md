# repo-setup

Provision a GitHub repository for use with the devbox skill system. Creates managed labels, prunes unmanaged ones, and ensures the global queue issue exists. Idempotent — safe to re-run at any time.

## Usage

```
/repo-setup {owner}/{repo}
/repo-setup {github-url}
```

If a full GitHub URL is provided, extract `{owner}/{repo}` from the path. If no argument is provided:
```
A repository is required. Usage: /repo-setup {owner}/{repo}
```

---

## Steps

### 1. Check gh CLI

```bash
gh --version
```
If not found: stop and instruct the user to install from https://cli.github.com.

### 2. Check authentication

```bash
gh auth status
```
If not authenticated: stop and instruct `gh auth login`.

### 3. Upsert managed labels

For each label, use the create-or-edit pattern:
```bash
if gh label list --repo {owner}/{repo} --limit 1000 --json name \
    --jq '.[].name' | grep -Fxq "{name}"; then
  gh label edit "{name}" --repo {owner}/{repo} --color "{color}" --description "{description}"
else
  gh label create "{name}" --repo {owner}/{repo} --color "{color}" --description "{description}"
fi
```

**Status labels** (blue):
- `status:draft` — `bfd4f2` — Idea captured, not yet planned
- `status:planned` — `6ea8fe` — Spec written, ready to build
- `status:progress` — `1d76db` — Branch created, build in progress
- `status:built` — `0969da` — All subtasks done and verified locally
- `status:shipped` — `0052cc` — Committed and pushed, ready for PR
- `status:review` — `003b8c` — PR open, under review
- `status:defective` — `001f4d` — Build failed, needs rework

**Priority labels** (warm):
- `priority:high` — `b60205` — High priority
- `priority:medium` — `d93f0b` — Medium priority
- `priority:low` — `fbca04` — Low priority

**Type labels** (green):
- `type:feature` — `0e8a16` — Feature work
- `type:bug` — `2cbe4e` — Bug fix
- `type:chore` — `56d364` — Maintenance or operations
- `type:docs` — `7ee787` — Documentation
- `type:refactor` — `aff5b4` — Refactoring
- `type:queue` — `e8f5e9` — Global queue issue
- `type:group` — `c2e0c6` — Group issue

**Size labels** (purple):
- `size:small` — `d4c5f9` — Localized scope
- `size:medium` — `b392f0` — Moderate scope or uncertainty
- `size:large` — `8250df` — Broad scope or cross-cutting changes

**Flag labels** (salmon):
- `flag:blocked` — `f9d0c4` — Blocked by another task or bug

### 4. Prune unmanaged labels

```bash
gh label list --repo {owner}/{repo} --limit 1000 --json name --jq '.[].name'
```

Compare against the managed list. Collect any not in the list.

```
These labels are not managed by devbox and will be deleted:
- bug
- enhancement
- good first issue
...

Delete them?
(y) yes  (n) no
```

On yes: `gh label delete "{name}" --repo {owner}/{repo} --yes` for each.

### 5. Global queue

```bash
gh issue list --repo {owner}/{repo} --state open --label "type:queue" \
  --json number,title --jq '.[] | select(.title == "Global Queue")'
```

If none exists:
```bash
gh issue create --repo {owner}/{repo} \
  --title "Global Queue" \
  --label "type:queue" \
  --body "## Queue

"
```

If one exists: leave untouched.

### 6. Report

```
repo-setup complete for {owner}/{repo}:
  Labels: {n} created, {n} already existed
  Unmanaged labels: {n} deleted / skipped
  Global queue: created / already present
```
