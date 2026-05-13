# pr-feedback

Process Copilot and human reviewer comment threads on an open PR. Fix, reply, or defer each thread before the file-by-file review.

## Usage

```
/pr-feedback {number}
```

Where `{number}` is the issue number (not the PR number). The PR is found via the issue's comments.

---

## Steps

### 1. Load

Find the PR URL from the issue comments:
```bash
gh issue view {number} --repo {owner}/{repo} --json comments \
  --jq '.comments[].body | select(startswith("https://github.com") and contains("/pull/"))'
```

Extract the PR number from the URL.

### 2. Wait for Copilot review

First, do an immediate check:
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
  --jq '.[] | select(.user.login == "copilot-pull-request-reviewer[bot]") | .state'
```

If a Copilot review is already present: proceed with Copilot comments first.

If no review yet, ask the user:
```
No Copilot review yet.
(w) wait up to 3 min  (s) skip
```

If `(s)`: skip Copilot review entirely and proceed with human comments only.

If `(w)`: poll every 15 seconds for up to 3 minutes, exiting as soon as a review appears:
```bash
for i in $(seq 1 12); do
  STATE=$(gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
    --jq '.[] | select(.user.login == "copilot-pull-request-reviewer[bot]") | .state')
  [ -n "$STATE" ] && break
  sleep 15
done
```

If a Copilot review appears during the loop: proceed with Copilot comments first.

If the loop completes with no review: skip Copilot review entirely and proceed with human comments only. Do not block.

### 3. Fetch threads

Get all unresolved, non-outdated review threads via GraphQL:
```bash
gh api graphql -f query='
{
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {pr}) {
      reviewThreads(first: 50) {
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 10) {
            nodes {
              author { login }
              body
              diffHunk
              path
              line
            }
          }
        }
      }
    }
  }
}'
```

Filter to unresolved, non-outdated threads only.

### 4. Process threads

Copilot threads first, then human threads. For each thread, show everything before asking for a decision:

```
FILE: {path}:{line}
DIFF:
{diff hunk}

COMMENT ({author}):
{comment body}

PROPOSED ACTION:
{exact code change or reply text}

ASSESSMENT:
{Is this valid in this codebase and context? Why?}

(f) fix  (r) reply  (d) defer
```

**`(f)` — Fix:**
1. Show the exact edit.
2. Confirm: `Apply this change? (y) yes  (n) no`
3. Apply the edit.
4. Run the smallest relevant verification check.
5. Commit: `fix(#{number}): address review comment in {file}`
6. Push.
7. Reply to the thread with a summary of what was changed.
8. Resolve the thread via GraphQL.

**`(r)` — Reply:**
1. Show the draft reply.
2. Confirm: `Post this reply? (y) yes  (e) edit  (n) no`
3. Post the reply via GraphQL.
4. Resolve the thread.

**`(d)` — Defer:**
Leave unresolved. Move to the next thread.

### 5. Report

```
Processed {n} threads:
  Fixed: {count}
  Replied: {count}
  Deferred: {count}
```
