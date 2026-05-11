# Bug Process: Report to Merged

This document defines the full bug lifecycle. The PR flow continues in `pr-process.md`. Task flow is in `task-process.md`. Utility skills are in `utils.md`.

Skills should be updated to match this spec, not the other way around.

---

## Guiding Principles

- **Fix the code, not the noise.** The goal is to eliminate the root cause so the error no longer occurs — not to suppress it. Never turn off error reporting globally. In rare cases, suppressing a specific error is the correct fix (e.g. a known third-party issue with no upstream fix), but this should be the exception and must be explicitly justified in the decided cause comment.
- **Errors that don't happen don't need to be caught.** A silent catch or a filtered Sentry rule is not a fix. If the error disappears after the fix, Sentry will stop reporting it naturally.
- **Reproduce before exploring.** Always confirm the bug exists and can be reproduced before running `bug-explore`. Do not create bug issues for unconfirmed reports.

---

## Lifecycle

```
Bug report / Sentry link(s)
  ↓ bug-explore  →  draft → planned  (investigation + spec in one step)
  ↓ bug-fix      →  progress → built
  ↓ bug-ship     →  shipped
  → continue in pr-process.md
```

If `bug-fix` fails:
```
progress → defective (branch auto-reset to origin/main)
  ↓ fix spec manually and rerun bug-fix, or run bug-retry to try a different approach
```

Other skills:
```
bug-retry  — cancel fix attempt, reset, return to planned or bug-explore
bug-view   — display full bug details
```

---

## Terminology

Same as tasks. See `task-process.md`.

Bugs are never added to the queue. They are fixed either at the time they are found or during dedicated bug-fixing sessions.

---

## Status Labels

Same labels and transitions as tasks. See `task-process.md`.

---

## Issue Structure

| Stage       | Contribution                                  | Written to  |
|-------------|-----------------------------------------------|-------------|
| bug-explore | Description + Sentry links + reproduce steps  | Issue body  |
| bug-explore | Potential causes                              | Comment     |
| bug-explore | Decided cause                                 | Comment     |
| bug-explore | Test plan                                     | Comment     |
| bug-explore | Subtasks                                      | Comment     |
| pr-open     | PR link                                       | Comment     |

### Issue body (written by bug-explore)

```markdown
## Description

{What the bug is, what the observable behavior is, and the impact.}

## Sentry

{Sentry link(s), or "None — reported via {source}."}

## Steps to Reproduce

{Numbered steps to trigger the bug.}
```

### Potential causes comment

```markdown
## Potential Causes

- **{Cause A}** — {Why this could be responsible. Relevant file/function/line.}
- **{Cause B}** — {Why this could be responsible. Relevant file/function/line.}
- **{Cause C}** — {Ruled out because...}
```

### Decided cause comment

```markdown
## Root Cause

{The cause we concluded on and why. Reference the specific file, function, or line. Explain why the other candidates were ruled out.}
```

### Test plan comment

```markdown
## Test Plan

- [ ] {Steps to reproduce the bug before the fix — confirm it occurs}
- [ ] {Steps to verify the bug no longer occurs after the fix}
- [ ] {Any related behavior that should still work correctly}
```

### Subtasks comment

```markdown
## Subtasks

### 1 — {Title}

{What this subtask does and why.}

**Build notes:** {Specific files, functions, constraints, and expected outcome.}

---

### 2 — {Title}

...
```

---

## Stage 1 — Report → Planned

**Skill:** `bug-explore`
**Label transition:** `status:draft` (on create) → `status:planned` (on completion)

Investigation, discussion, and spec creation in a single session.

### Arguments

Accepts any combination:
- One or more Sentry URLs
- A plain description of the bug
- Both together

```
/bug-explore https://sentry.io/...
/bug-explore https://sentry.io/... https://sentry.io/...
/bug-explore "Checkout fails when discount code is applied"
/bug-explore https://sentry.io/... "Also reported by customer on 2026-05-09"
```

### Flow

1. **Parse arguments** — Separate Sentry URLs from plain description text.

2. **Duplicate check** — Before creating anything, search open issues for similar bugs:
   ```bash
   gh issue list --repo {owner}/{repo} --state open --label "type:bug" \
     --search "{keywords}" --json number,title
   ```
   If a possible duplicate is found:
   ```
   Possible duplicate: #{number} — {title}
   (c) continue anyway  (v) view that issue  (n) cancel
   ```

3. **Sentry grouping** (only if multiple Sentry URLs provided) — Fetch all issues. Analyze stack traces, error types, messages, and affected code paths. Group them:

   ```
   SENTRY ISSUES

   Group A — likely same root cause
     #1 {url} — {error type}: {message} in {file}:{line}
     #3 {url} — {error type}: {message} in {file}:{line}

   Group B — unrelated
     #2 {url} — {error type}: {message} in {file}:{line}

   Reasoning: {Brief explanation of grouping decisions.}

   (p) proceed with Group A    (s) split — explore each group separately    (n) cancel
   ```

   - `(p)`: continue with that group as one bug.
   - `(s)`: stop. Instruct the user to rerun `/bug-explore` with each group's links separately.
   - `(n)`: cancel.

   If only one URL or a plain description: skip grouping and proceed directly.

4. **Fetch Sentry data** — For each Sentry URL in scope, extract: error type, message, stack trace, affected file and line, frequency, first/last seen, user or request context.

5. **Explore codebase** — Using Sentry data and/or description, do a read-only scan to:
   - Find the files and functions in the stack trace
   - Understand the surrounding code and data flow
   - Identify all plausible causes
   - Note dependencies, recent changes, or risky patterns near the failure point

6. **Discuss** — Present findings and walk through potential causes. Ask questions if the root cause is not clear. The goal is to reach a confident conclusion before writing the spec.

7. **Reproduce steps** — Confirm steps to reproduce the bug. Include in the issue body.

8. **Draft issue body** — Write the description, Sentry links, and reproduce steps. Show it:
   ```
   Does this capture the bug?
   (y) yes  (e) edit  (n) start over
   ```

9. **Create issue** — Create the GitHub issue with `status:draft` and labels. Recommend each:
   ```
   Recommended priority: high — {reason}
   (h) high  (m) medium  (l) low

   Recommended size: small — {reason}
   (s) small  (m) medium  (l) large
   ```
   Always applies `type:bug`.

10. **Post potential causes comment** — List all candidates considered with reasoning. Include ruled-out candidates and why.

11. **Post decided cause comment** — State the root cause conclusion with specific file/function references and reasoning for ruling out other candidates.

12. **Test plan** — Generate test plan steps. Show:
    ```
    Test plan — look right?
    (y) yes  (e) edit  (n) start over
    ```
    Post as a comment on confirmation.

13. **Subtasks** — Generate subtasks. Typical pattern:
    - Implement fix
    - Add regression test

    Each subtask must have a title, description, and build notes. Show:
    ```
    Subtasks — look right?
    (y) yes  (e) edit one  (a) add one  (d) delete one  (n) start over
    ```
    Post as a comment on confirmation.

14. **Update labels** — Remove `status:draft`, add `status:planned`.

15. **Confirm** — "Bug #{number} is planned. Run `/bug-fix {number}` when ready."

---

## Stage 2 — Planned → Built

**Skill:** `bug-fix`
**Label transition:** `status:planned` → `status:progress` → `status:built`

Stops when all subtasks are done and verified locally. Nothing is committed or pushed.

1. **Load** — Read the issue body and all comments:
   ```bash
   gh issue view {number} --repo {owner}/{repo} --json title,body,labels,comments
   ```
   Display:
   - Bug title and description
   - Decided cause
   - Subtasks (count and titles)

2. **Branch check** — Branch naming: `bug/{number}-{slug}`.

   - **Does not exist** — fresh fix.
     ```
     Ready to fix?
     (y) yes  (n) not yet
     ```
     On yes: `git checkout -b bug/{number}-{slug} origin/main`

   - **Exists, status is `status:planned`** — previous partial attempt.
     ```
     Branch bug/{number}-{slug} already exists.
     Committed: {summary}
     Uncommitted: {summary or "none"}

     (r) resume from next subtask
     (s) hard reset to origin/main — discards all local changes on this branch
     (n) cancel
     ```

   - **Status is `status:defective`** — branch already reset to `origin/main`.
     ```
     Bug #{number} was marked defective. Branch is at origin/main.
     Ready to rebuild?
     (y) yes  (n) not yet
     ```

3. **Update status** — Remove any `status:*` label, add `status:progress`.

4. **Execute subtasks in order.** Same no-guessing rules as `task-build` — stop and ask rather than guess on any ambiguity.

   When stopping to ask, state:
   - Which subtask triggered the question
   - What is ambiguous or missing
   - What options exist and which you lean toward

   **On failure:**
   1. Revert uncommitted changes: `git checkout .`
   2. Hard reset the branch: `git reset --hard origin/main`
   3. Update labels: remove `status:progress`, add `status:defective`
   4. Report which subtask failed and why.
   5. "Fix the subtask spec and rerun `/bug-fix {number}`, or run `/bug-retry {number}` to try a different approach."

5. **Verify** — Run verification commands from the project's `AGENTS.md`. Stack defaults first, then project additions. See `utils.md` for command resolution.

6. **Update status** — Remove `status:progress`, add `status:built`.

7. **Report** — "Bug #{number} is built locally. Run `/bug-ship {number}` when ready to commit and push."

---

## Stage 3 — Built → Shipped

**Skill:** `bug-ship`
**Label transition:** `status:built` → `status:shipped`

Follows the same flow as `task-ship` with two additions.

1. **Load** — Read the issue to confirm `status:built`. Display branch name and bug title.

2. **Review changes** — `git status --short` and `git diff --stat`. Confirm branch is `bug/{number}-{slug}`.

3. **Error suppression check** — Before running the pre-commit gate, scan the changes for global error suppression patterns:
   - `error_reporting(0)` or similar
   - `@` operator applied broadly
   - Catch-all exception handlers that swallow errors
   - Sentry `beforeSend` filters that drop entire error classes

   If found:
   ```
   ⚠ This change appears to suppress errors rather than fix them:
     {file}:{line} — {description}

   The preferred fix eliminates the root cause so the error no longer occurs.
   Is this suppression intentional and justified?
   (y) yes, it's the right fix — continue  (n) no — go back and fix it
   ```
   If `(y)`: require a justification comment to be added to the decided cause comment before proceeding.

4. **Pre-commit gate** — Run pre-commit gate commands from the project's `AGENTS.md`. Stack defaults first, then project additions.

5. **Commit** — Stage only bug-related files. Commit message:
   ```
   fix(#{number}): {short bug title}
   ```

6. **Push** — `git push -u origin bug/{number}-{slug}`

7. **Update status** — Remove `status:built`, add `status:shipped`.

8. **Sentry resolution** — Extract Sentry issue IDs from the issue body (numeric ID at the end of each Sentry URL). Resolve via `sentry-cli`:
   ```bash
   sentry-cli issues resolve {sentry-issue-id}
   ```
   If no Sentry links in the issue body: skip this step.
   If `sentry-cli` is not available or `SENTRY_AUTH_TOKEN` is not set: list the URLs and instruct manual resolution.

9. **Report** — "Bug #{number} is shipped. Run `/pr-open {number}` when ready to open a pull request."

---

## bug-retry

Cancel the current fix attempt and return to a clean state to try a different approach.

**Usage:** `/bug-retry {number}`

1. **Load** — Read the issue. Display title, decided cause, and current branch state.

2. **Confirm** — Show what will happen:
   ```
   This will:
     • Reset branch bug/{number}-{slug} to origin/main
     • Return status to planned

   (y) yes  (n) cancel
   ```

3. **Execute** —
   - Revert any uncommitted changes: `git checkout .`
   - Hard reset branch: `git reset --hard origin/main`
   - Update labels: remove current `status:*`, add `status:planned`

4. **Next step** — Ask:
   ```
   What next?
   (f) run /bug-fix {number} with a different approach
   (e) go back to /bug-explore — reconsider the root cause
   ```
   If `(e)`: note that a new `bug-explore` session will create a new issue. Close this one or keep it open as context.

---

## bug-view

Display a full bug with all comments, status, and branch info. Read-only.

**Usage:** `/bug-view {number}`

Display in order:
- Title, number, status, size, priority
- Description, Sentry links, reproduce steps (body)
- Potential causes (if posted)
- Decided cause (if posted)
- Test plan (if posted)
- Subtasks (if posted)
- PR link (if posted)
- Current branch: `git branch --list "bug/{number}-*"`

No interaction — display only.
