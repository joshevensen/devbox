# pr-review

File-by-file review of a PR. CI failure blocks the merge and triggers a fix flow. Verifies, then merges.

## Usage

```
/pr-review {number}
```

Where `{number}` is the issue number. The PR is found via the issue's comments.

---

## Steps

### 1. Load and CI check

Find the PR URL from the issue comments and extract the PR number.

Check CI status:
```bash
gh pr checks {pr} --repo {owner}/{repo}
```

**If any checks are failing:** do not proceed to file review. Enter CI fix mode:

1. Show which checks are failing and fetch their output:
   ```bash
   gh run view {run-id} --repo {owner}/{repo} --log-failed
   ```
2. Explore the failure — read error messages, find affected code.
3. Propose a fix. Confirm before applying.
4. Apply, commit (`fix(#{number}): fix CI — {brief description}`), push.
5. Re-check CI:
   ```bash
   gh pr checks {pr} --repo {owner}/{repo} --watch
   ```
6. Repeat until all checks pass, then continue to file classification.

### 2. Classify files

Get the list of changed files:
```bash
gh pr diff {pr} --repo {owner}/{repo} --name-only
```

Produce three tiered lists, every file numbered across all tiers:

```
REVIEW THESE
1. path/to/file — {why this deserves attention}
2. path/to/file — {why}

MIGHT WANT TO REVIEW
3. path/to/file — {brief note}

SKIP
4. package-lock.json — lockfile update only
5. path/to/generated — auto-generated, no logic
```

**Step 1:**
```
Any files in REVIEW THESE you don't want to review? Enter numbers, or (n) to proceed.
```
Move entered numbers to MIGHT WANT TO REVIEW.

**Step 2:**
```
Any files in MIGHT WANT TO REVIEW or SKIP you want to review? Enter numbers, or (n) to proceed.
```
Move entered numbers to REVIEW THESE.

**Step 3:**
```
Ready to proceed?
(y) yes  (n) no — go back and adjust
```

### 3. File review

Go through REVIEW THESE one at a time:

```bash
gh pr diff {pr} --repo {owner}/{repo} -- {file}
```

For each file:
- Show relevant diff hunks (focus on meaningful changes).
- Explain: what changed, why it likely changed, how it fits the system, runtime risk, test coverage.

```
(y) looks good  (c) change requested  (s) skip  (n) next
```

If `(c)`:
1. Describe the exact edit.
2. Confirm: `Apply this change? (y) yes  (n) no`
3. Apply, commit (`fix(#{number}): {brief description}`), push.

### 4. Verification

Run verification commands from the project's `AGENTS.md`. Stack defaults first, then project additions. See `utils.md` for command resolution.

Report CI check status:
```bash
gh pr checks {pr} --repo {owner}/{repo}
```

### 5. Summary

```
REVIEWED
{file} — {status}
{file} — {status}

VERIFICATION
{results}

CI
{check statuses}

DEPLOY RISKS
{Any: migrations, env vars, queued jobs, webhooks, external API changes}
{or "None identified"}
```

### 6. Merge

```
Merge PR #{pr}?
(y) yes  (n) no
```

On yes:
```bash
gh pr merge {pr} --repo {owner}/{repo} --squash
```

GitHub closes the issue via `Closes #{number}` in the PR body.
