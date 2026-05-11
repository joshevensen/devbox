# PR Process: Shipped to Merged

This document defines the PR lifecycle after a task or bug has been shipped. The task flow that leads here is in `task-process.md`. The bug flow is in `bug-process.md`.

Skills should be updated to match this spec, not the other way around.

---

## Lifecycle

```
shipped (branch on remote)
  ↓ pr-open      →  review
  ↓ pr-feedback  →  review (no label change, optional)
  ↓ pr-review    →  [closed on merge]
```

---

## Status Labels

| Label           | Set by  | Meaning               |
|-----------------|---------|-----------------------|
| `status:review` | pr-open | PR open, under review |

No defective status at the PR level. Issues found during review are fixed inline and the PR is merged.

---

## Stage 1 — Shipped → Review

**Skill:** `pr-open`
**Label transition:** `status:shipped` → `status:review`

Works for both tasks and bugs. Detects issue type from labels.

1. **Load** — Read the issue. Confirm it has `status:shipped`. Display title and acceptance criteria (tasks) or test plan (bugs).

2. **Prepare PR body**:
   - `Closes #{number}` at the top
   - Description: 2–4 sentences on what was accomplished and why it matters
   - Changes: key files created or modified with one-line notes
   - Test plan: specific steps a reviewer can follow

   PR title uses conventional commit format:
   ```
   {type}(#{number}): {short title}
   ```
   Where `{type}` matches the issue's `type:*` label.

3. **Show PR body** and ask:
   ```
   Does this look right?
   (y) yes  (e) edit  (n) start over
   ```

4. **Open PR** — Create against `main`:
   ```bash
   gh pr create --repo {owner}/{repo} \
     --title "{title}" \
     --body "{body}" \
     --base main \
     --head {branch}
   ```

5. **Comment** — Post the PR URL as a comment on the issue:
   ```bash
   gh issue comment {number} --repo {owner}/{repo} --body "{pr-url}"
   ```

6. **Update status** — Remove `status:shipped`, add `status:review`.

7. **Update queue** — Check off the issue in its queue by editing the queue issue body to mark the line as `[x]`. Graceful no-op if the issue is not in any queue.

8. **Report** — "PR #{pr} is open. Run `/pr-feedback {number}` to handle review comments, then `/pr-review {number}` when ready."

---

## Stage 2 — Feedback (optional)

**Skill:** `pr-feedback`
**Label change:** none — issue stays `status:review`

Handles Copilot and human reviewer comment threads so the PR is clean before the file review.

1. **Load** — Find the PR URL from the issue comments. Fetch the PR number.

2. **Wait for Copilot review** — Poll every 15 seconds for up to 3 minutes:
   ```bash
   gh pr reviews {pr} --repo {owner}/{repo} --json author,state \
     --jq '.[] | select(.author.login == "copilot-pull-request-reviewer")'
   ```
   If no Copilot review appears within 3 minutes, or if Copilot is not enabled on the repo: skip Copilot review and proceed with human comments only.

3. **Fetch threads** — Get all unresolved, non-outdated review threads via GraphQL.

4. **Process** — Copilot comments first, then human comments. For each thread, present before asking for a decision:
   - The diff hunk the comment is attached to
   - The comment body
   - A proposed fix (exact code change or reply text)
   - Assessment: is this comment valid in this codebase and context, and why?

   ```
   (f) fix  (r) reply  (d) defer
   ```
   - `(f)`: show the exact edit before applying. Confirm. Apply, run the smallest relevant check, commit, push, reply to the thread, resolve.
   - `(r)`: show the draft reply before posting. Confirm. Post reply, resolve.
   - `(d)`: leave unresolved, move to the next thread.

5. **Apply** — Changes are applied per-thread as approved, not batched.

6. **Report** — Summarize what was fixed, replied, and deferred.

---

## Stage 3 — Review

**Skill:** `pr-review`
**Outcome:** merged (issue closed by GitHub via `Closes #{number}` in PR body)

File-by-file review of the PR changes.

1. **Load** — Find the PR from the issue comments. Check CI status:
   ```bash
   gh pr checks {pr} --repo {owner}/{repo}
   ```

   **If CI is failing:** do not proceed to file review. Help diagnose and fix the CI failure:
   - Show which checks are failing and their output
   - Explore the failure (logs, error messages, affected code)
   - Propose a fix, confirm, apply, commit, push
   - Re-check CI status and repeat until all checks pass

2. **Classify files** — Compare against the PR base branch. Produce three tiered lists, every file numbered across all tiers:

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

3. **File review** — Go through REVIEW THESE one at a time:
   - Show relevant diff hunks (meaningful changes, not full diff).
   - Explain: what changed, why it likely changed, how it fits the system, runtime risk, test coverage.
   ```
   (y) looks good  (c) change requested  (s) skip  (n) next
   ```
   If `(c)`: describe the exact edit, confirm before applying, commit and push.

4. **Verification** — Run verification commands from the project's `AGENTS.md`. Stack defaults first, then project additions. Report CI check status.

5. **Summary** — Show:
   - Files reviewed and any remaining concerns
   - Verification results and CI status
   - Deploy risks: migrations, env vars, queued jobs, webhooks, external APIs

6. **Merge** —
   ```
   Merge PR #{pr}?
   (y) yes  (n) no
   ```
   On yes:
   ```bash
   gh pr merge {pr} --repo {owner}/{repo} --squash
   ```
   GitHub closes the issue via `Closes #{number}` in the PR body.
