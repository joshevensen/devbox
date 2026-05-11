# Task Process: Idea to Shipped

This document defines the task lifecycle from idea to an open PR. The PR flow continues in `pr-process.md`. Bug flow is in `bug-process.md`. Group and queue management is in `group-process.md`. Utility skills are in `utils.md`.

Skills should be updated to match this spec, not the other way around.

---

## Guiding Principles

- **Invest in the spec.** Great outcomes come from great specs. The create and plan stages should produce high-quality, unambiguous input for the build.
- **Explicit control points.** Each skill stops at a meaningful checkpoint so the developer can inspect before moving forward.
- **Preserve history.** Each stage appends as a comment. The issue body should only be modified intentionally via `task-edit`.
- **Every question uses letter shortcuts.** All prompts follow `(y) yes  (n) no` patterns. No typing full words.

---

## Lifecycle

```
Idea
  ↓ task-create  →  draft
  ↓ task-plan    →  planned
  ↓ task-build   →  progress (start)  →  built (end)
  ↓ task-ship    →  shipped
  → continue in pr-process.md
```

If `task-build` fails:
```
progress → defective (branch auto-reset to origin/main)
  ↓ task-edit (optional) — fix the spec
  ↓ task-build → progress → built
```

Other skills:
```
task-edit    — edit any part of a task issue
task-cancel  — close and remove from queue
task-split   — split into multiple tasks
task-move    — move between groups or to/from standalone
task-view    — display full task details
```

---

## Terminology

| Term   | GitHub primitive                  |
|--------|-----------------------------------|
| task   | issue                             |
| group  | issue with `type:group` label     |
| queue  | issue with `type:queue` label     |

---

## Status Labels

| Label              | Set by      | Meaning                                    |
|--------------------|-------------|--------------------------------------------|
| `status:draft`     | task-create | Idea captured, not yet planned             |
| `status:planned`   | task-plan   | Spec written, ready to build               |
| `status:progress`  | task-build  | Branch created, build in progress          |
| `status:built`     | task-build  | All subtasks done and verified locally     |
| `status:shipped`   | task-ship   | Committed and pushed, ready for PR         |
| `status:review`    | pr-open     | PR open, under review                      |
| `status:defective` | task-build  | Build failed, branch reset, needs rework   |

---

## Issue Structure

The issue body and comments are the contract between all skills. Each stage appends as a comment. The body may only be modified via `task-edit`.

| Stage       | Contribution           | Written to                    |
|-------------|------------------------|-------------------------------|
| task-create | Problem + user stories | Issue body                    |
| task-plan   | Acceptance criteria    | Comment                       |
| task-plan   | Scope                  | Comment                       |
| task-plan   | Related tasks          | Comment (omitted if none)     |
| task-plan   | Subtasks               | Comment                       |
| pr-open     | PR link                | Comment                       |

### Issue body (written by task-create)

```markdown
## Problem

{What problem this solves, why it matters, and the desired outcome.}

## User Stories

- As a {role}, I want to {action} so that {outcome}.
```

### Acceptance criteria comment

```markdown
## Acceptance Criteria

- [ ] {Discrete, verifiable condition}
- [ ] {Another condition}
```

### Scope comment

```markdown
## Scope

### In Scope
- {What this task includes}

### Out of Scope
- {What this task explicitly excludes}
```

### Related tasks comment (omitted if no relationships)

```markdown
## Related Tasks

- **Split from:** #{number}
- **Split into:** #{number}
- **Blocked by:** #{number}
- **Blocks:** #{number}
- **Related:** #{number}
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

## Stage 1 — Idea → Draft

**Skill:** `task-create`
**Label applied:** `status:draft`

Work through each section in order, confirming before moving on.

1. **Problem** — Ask for the raw idea. Ask enough to understand:
   - What problem or pain is this solving?
   - What outcome makes this worth doing?
   - Any constraints, links, or context to preserve?

   Draft the problem statement and show it.
   ```
   Does this capture it?
   (y) yes  (e) edit  (n) start over
   ```

2. **Duplicate check** — Search open issues for similar tasks before proceeding.
   ```bash
   gh issue list --state open --search "{keywords}" --json number,title
   ```
   If a possible duplicate is found, show it and ask:
   ```
   Possible duplicate: #{number} — {title}
   (c) continue anyway  (v) view that issue  (n) cancel
   ```

3. **User stories** — Generate 1–3 user stories from the problem. Show them.
   ```
   Do these look right?
   (y) yes  (e) edit  (s) skip
   ```

4. **Codebase scan** — Ask:
   ```
   Quick codebase scan to estimate size and touch points?
   (y) yes  (n) no
   ```
   If yes: scan, summarize findings, note dependencies and risks.
   If no: estimate size from context only.

5. **Size** — Recommend with a short reason.
   ```
   Recommended size: medium — {reason}
   (s) small  (m) medium  (l) large
   ```

6. **Priority**
   ```
   Recommended priority: medium — {reason}
   (h) high  (m) medium  (l) low
   ```

7. **Type**
   ```
   Recommended type: feature — {reason}
   (f) feature  (b) bug  (c) chore  (d) docs  (r) refactor
   ```

8. **Title** — Suggest a short action-oriented title.
   ```
   Suggested title: {title}
   (u) use this  (o) provide my own
   ```

9. **Queue** — Ask where to add the task.
   ```
   Add to queue?
   (g) global queue as standalone
   (m) assign to a group
   (n) skip
   ```
   If `(m)`: list existing groups by number and name, ask which one, default to end of that group's queue.

10. **Create** — Write the issue body and create the GitHub issue with labels.

11. **Confirm** — "Task #{number} created. Run `/task-plan {number}` when ready."

---

## Stage 2 — Draft → Planned

**Skill:** `task-plan`
**Label transition:** `status:draft` → `status:planned`

Work through each section in order, confirming before moving on.

1. **Load** — Read the issue body. Display the problem statement and user stories. Ask any clarifying questions needed to understand scope, constraints, and what "done" looks like.

2. **Scope check** — Estimate likely file count from the problem, user stories, and a read-only codebase scan.
   - 1–20 files: proceed
   - 21–30 files: acceptable if tightly coupled
   - 30+ files: recommend splitting unless a mechanical refactor

   If recommending a split:
   ```
   This task should be split. Proposed split:
     1. {title}
     2. {title}
   (s) split as proposed  (n) narrow and proceed  (p) proceed anyway
   ```
   If `(s)`: stop here. Run `/task-split {number}` to create the child tasks.

3. **Acceptance criteria** — Generate and show.
   ```
   Acceptance criteria — look right?
   (y) yes  (e) edit  (a) add more  (n) start over
   ```

4. **Scope** — Generate in scope / out of scope and show.
   ```
   Scope — look right?
   (y) yes  (e) edit  (n) start over
   ```

5. **Related tasks** — Ask if there are relationships to other tasks. If yes, capture them.
   ```
   Any related tasks?
   (y) yes  (n) no
   ```

6. **Subtasks** — Generate and show. Each must have a title, description, and build notes with specific files, functions, and expected outcome.
   ```
   Subtasks — look right?
   (y) yes  (e) edit one  (a) add one  (d) delete one  (n) start over
   ```

7. **Post comments** — Post each section as a separate comment: acceptance criteria, scope, related tasks (if any), subtasks.

8. **Update labels** — Remove `status:draft`, add `status:planned`. Update `size:*` if the scope assessment changed the estimate. Add `flag:blocked` if a `Blocked by` relationship exists. `task-build` will check and remove this flag automatically once all blockers are closed.

9. **Confirm** — "Task #{number} is planned. Run `/task-build {number}` when ready."

---

## Stage 3 — Planned → Built

**Skill:** `task-build`
**Label transition:** `status:planned` → `status:progress` → `status:built`

Stops when all subtasks are done and verified locally. Nothing is committed or pushed.

1. **Load** — Read the issue body and all comments. Display:
   - Task title and problem statement
   - Acceptance criteria
   - Subtasks (count and titles)

2. **Blocked check** — If the task has `flag:blocked`, read the related tasks comment and find all "Blocked by" issue numbers. Check each via `gh issue view`:
   - If any blocker is still open: stop.
     ```
     Task #{number} is blocked by #{blocker} which is not yet complete.
     Complete that task first, then rerun /task-build {number}.
     ```
   - If all blockers are closed: remove `flag:blocked` and continue.

3. **Branch check** — Check whether the task branch exists.

   - **Does not exist** — fresh build.
     ```
     Ready to build?
     (y) yes  (n) not yet
     ```

   - **Exists, status is planned** — a previous partial attempt. Show committed subtasks from `git log` and uncommitted state.
     ```
     Branch task/{number}-{slug} already exists.
     Committed: subtasks 1–2
     Uncommitted: none

     (r) resume from subtask 3
     (s) hard reset to origin/main — discards all local changes on this branch
     (n) cancel
     ```

   - **Status is defective** — branch was already reset to `origin/main` when the defective label was applied.
     ```
     Task #{number} was marked defective. Branch is at origin/main.
     Ready to rebuild?
     (y) yes  (n) not yet — run /task-edit {number} first
     ```

4. **Update status** — Remove any `status:*` label, add `status:progress`.

5. **Execute subtasks in order.** Do not stop between subtasks unless blocked by uncertainty.

   **Rules for uncertainty — no guessing allowed:**
   - If the subtask description or build notes are ambiguous, incomplete, or conflict with what exists in the codebase, **stop and ask** before writing any code.
   - If a decision requires knowledge that isn't in the spec, **stop and ask**.
   - If the codebase state differs from what the spec assumes, **stop and ask**.
   - Never make a judgment call silently. If proceeding requires a guess, it requires user input instead.

   When stopping to ask, state clearly:
   - Which subtask triggered the question
   - What is ambiguous or missing
   - What options you see and which you would lean toward, if any

   When a subtask fails due to a code or runtime error:
   - Stop immediately.
   - Revert uncommitted changes: `git checkout .`
   - Hard reset the branch: `git reset --hard origin/main`
   - Remove `status:progress`, add `status:defective`.
   - Report exactly which subtask failed and why.
   - "Run `/task-edit {number}` to fix the spec, then `/task-build {number}` to rebuild."

6. **Verify** — Run the pre-commit gate and verification commands from the project's `AGENTS.md`. See `utils.md` for how commands are resolved (stack defaults + project additions).

7. **Update status** — Remove `status:progress`, add `status:built`.

8. **Report** — Show a summary of what was built. "Task #{number} is built locally. Run `/task-ship {number}` when ready to commit and push."

---

## Stage 4 — Built → Shipped

**Skill:** `task-ship`
**Label transition:** `status:built` → `status:shipped`

Commits the local work and pushes the branch. Does not open a PR.

1. **Load** — Read the issue to confirm it has `status:built`. Display branch name and task title.

2. **Review changes** — Show what will be committed.
   ```bash
   git status --short
   git diff --stat
   ```
   Confirm the current branch is the task branch, not `main`. Surface any unrelated changes clearly — do not stage them.

3. **Pre-commit gate** — Run the pre-commit gate commands from the project's `AGENTS.md` (stack defaults first, then project additions). If a command cannot run, record it and the reason before proceeding.

4. **Commit** — Stage only task-related files. Commit with a conventional commit message:
   ```
   {type}(#{number}): {short task title}
   ```

5. **Push** — Push the branch to remote.

6. **Update status** — Remove `status:built`, add `status:shipped`.

7. **Report** — "Task #{number} is shipped. Run `/pr-open {number}` when ready to open a pull request."

---

## task-edit

Edits any part of a task issue — body, acceptance criteria, scope, related tasks, or subtasks. Shows current content, proposes changes, confirms before writing.

**Usage:** `/task-edit {number}`

1. **Load** — Read the issue body and all comments. Display the current state of each section.

2. **Choose section** — Ask what to edit.
   ```
   What do you want to edit?
   (b) problem/user stories (body)
   (a) acceptance criteria
   (s) scope
   (r) related tasks
   (t) subtasks
   ```

3. **Edit** — Show the current content of the chosen section. Accept the new content. Show a diff of what will change.
   ```
   Apply this change?
   (y) yes  (e) keep editing  (n) cancel
   ```

4. **Write** — Update the issue body or replace the relevant comment.

5. **Confirm** — "Task #{number} updated."

Repeat from step 2 if the user wants to edit another section.

---

## task-cancel

Closes a task that will not be completed. Cleans up queue and branch.

**Usage:** `/task-cancel {number}`

1. **Load** — Read the issue. Display title and current status.

2. **Reason** — Ask for a reason.
   ```
   Reason for cancelling? (required)
   ```

3. **Confirm** — Show what will happen.
   ```
   This will:
     • Close issue #{number}
     • Remove from queue (if queued)
     • Delete branch task/{number}-{slug} (if it exists)

   (y) yes  (n) cancel
   ```

4. **Execute** —
   - Post a comment: "Cancelled — {reason}"
   - Close the issue via `gh issue close`
   - Remove from queue if present (graceful no-op if not queued)
   - Delete local branch if it exists: `git branch -d task/{number}-{slug}`

5. **Confirm** — "Task #{number} cancelled."

---

## task-split

Splits an oversized task into two or more smaller tasks. Closes the original and inserts the children into the queue at the same position.

**Usage:** `/task-split {number}`

1. **Load** — Read the issue body and all comments. Display title, problem, and subtasks.

2. **Propose split** — Suggest how to divide the work into 2–3 child tasks, each with a title and brief scope. Show the proposal.
   ```
   Proposed split:
     1. {title} — {scope}
     2. {title} — {scope}

   (y) yes  (e) edit  (n) cancel
   ```

3. **Branch warning** — If a branch exists for the original task:
   ```
   ⚠ Branch task/{number}-{slug} exists. Any work on it will not be carried over automatically.
   Handle that branch manually before proceeding.
   (y) continue  (n) cancel
   ```

4. **Create children** — For each child task, run the `task-create` flow (problem, user stories, size, priority, type, title). Pre-populate from the original where applicable. Add a "Split from: #{original}" relationship. Set status to `status:draft`.

5. **Queue** — Insert children into the queue at the position previously occupied by the original. Remove the original from the queue.

6. **Close original** — Post a comment listing the child issue numbers, then close the issue.

7. **Confirm** — "Task #{number} split into #{child1} and #{child2}. Run `/task-plan` on each when ready."

---

## task-move

Moves one or more tasks between groups, or to/from standalone. Accepts multiple task numbers.

**Usage:** `/task-move {number} [{number} ...]`

1. **Load** — For each task number, read the issue title and current queue position (group or standalone).

   Display:
   ```
   #12 — {title}  currently in: Group: Wholesale Management
   #15 — {title}  currently in: standalone
   ```

2. **Destination** — Ask where to move them.
   ```
   Move to:
   (g) global queue as standalone
   (m) a group — list groups
   ```
   If `(m)`: show numbered list of groups, ask which one.

3. **Confirm** — Show the change.
   ```
   Move #12 and #15 to Group: Analytics?
   (y) yes  (n) cancel
   ```

4. **Execute** —
   - Remove each task from its current queue entry
   - Add each task to the destination queue (end of queue by default)
   - Update the milestone assignment if applicable

5. **Confirm** — "Moved {count} task(s) to {destination}."

---

## task-view

Displays a full task with all comments, current status, and branch info in a readable format.

**Usage:** `/task-view {number}`

1. **Load** — Read the issue body, all comments, and labels via `gh issue view --comments`.

2. **Display** in order:
   - Title, number, status labels, size, priority, type
   - Problem statement and user stories (body)
   - Acceptance criteria (if posted)
   - Scope (if posted)
   - Related tasks (if posted)
   - Subtasks (if posted)
   - PR link (if posted)
   - Current branch: `git branch --list "task/{number}-*"`

No interaction — display only.
