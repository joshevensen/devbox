# Utility Skills

Utility skills that support all workflows. Repository setup, list views, queue navigation, prioritization, and branch utilities.

Skills should be updated to match this spec, not the other way around.

---

## Command Resolution

Several skills need to run pre-commit gate or verification commands. These are resolved at runtime from two sources, merged in order:

1. **Stack defaults** — defined in `~/devbox/scripts/stacks/{stack}.yaml` (a companion to the stack startup script). Keys: `pre_commit_gate` and `verification`, each a list of commands.

2. **Project additions** — defined in the project's `AGENTS.md` under `## Pre-commit Gate` and `## Verification` sections.

**Default behavior (additive):** stack defaults run first, then project additions.

**Override:** if a section in `AGENTS.md` contains `<!-- @override -->` as its first line, that section replaces the stack defaults entirely for that command type.

**Empty or missing section:** falls back to stack defaults only.

Example `AGENTS.md` section (additive):
```markdown
## Pre-commit Gate
<!-- Stack defaults (laravel): php artisan test, php artisan migrate:status -->
php artisan test --filter=MyNewFeature
```

Example with override:
```markdown
## Pre-commit Gate
<!-- @override -->
php artisan test --testsuite=unit
```

The stack defaults comment is written by `repo-scaffold` for reference — it is not parsed. Only `<!-- @override -->` is meaningful to skills.

---

## repo-setup

Provisions a GitHub repository for use with these skills. Idempotent — safe to run at any time.

**Usage:** `/repo-setup {owner}/{repo}` or `/repo-setup {github-url}`

If a full GitHub URL is provided, extract `{owner}/{repo}` from the path. If no argument is provided:
```
A repository is required. Usage: /repo-setup {owner}/{repo}
```

### Steps

1. **Check `gh` CLI**
   ```bash
   gh --version
   ```
   If not found: stop and instruct the user to install from https://cli.github.com.

2. **Check authentication**
   ```bash
   gh auth status
   ```
   If not authenticated: stop and instruct `gh auth login`.

3. **Upsert managed labels** — Create or update each label. Use the create-or-edit pattern:
   ```bash
   if gh label list --repo {owner}/{repo} --limit 1000 --json name \
       --jq '.[].name' | grep -Fxq "status:draft"; then
     gh label edit "status:draft" --repo {owner}/{repo} \
       --color "bfd4f2" --description "Idea captured, not yet planned"
   else
     gh label create "status:draft" --repo {owner}/{repo} \
       --color "bfd4f2" --description "Idea captured, not yet planned"
   fi
   ```
   Repeat for every managed label:

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

4. **Prune unmanaged labels** — Fetch all labels and find those not in the managed list above:
   ```
   These labels are not managed by devbox and will be deleted:
   - bug
   - enhancement
   ...

   Delete them?
   (y) yes  (n) no
   ```

5. **Global queue** — Check if it exists:
   ```bash
   gh issue list --repo {owner}/{repo} --state open --label "type:queue" \
     --json number,title --jq '.[] | select(.title == "Global Queue")'
   ```
   If none exists, create it:
   ```bash
   gh issue create --repo {owner}/{repo} \
     --title "Global Queue" \
     --label "type:queue" \
     --body "## Queue\n\n"
   ```

6. **Report** — Labels created vs already existed, labels deleted or skipped, global queue created or already present.

---

## repo-scaffold

Scaffolds the project's `AGENTS.md`, creates a `CLAUDE.md` symlink, and discovers commands from project config files. Idempotent — shows a diff on re-runs, never silently overwrites.

**Usage:** `/repo-scaffold {path}` or run from within the project directory.

Must be run from inside `~/repos/{name}/` or with a path to the project.

### Steps

1. **Detect stack** — Read `~/devbox/repos/{name}.yaml` to get the stack type.

2. **Load stack defaults** — Read `~/devbox/scripts/stacks/{stack}.yaml` for `pre_commit_gate` and `verification` command lists.

3. **Discover project commands** — Scan the project for:
   - `package.json` → `scripts` block: surface test/lint/build scripts (filter out dev/watch scripts)
   - `composer.json` → `scripts` block: surface relevant scripts
   - `artisan` present → note `php artisan test` as available

4. **Show stack defaults** — Display what will run automatically without any AGENTS.md config:
   ```
   Stack defaults that will run automatically (laravel):
     Pre-commit gate:  php artisan test, php artisan migrate:status
     Verification:     php artisan test

   These run without any AGENTS.md config. Add project-specific commands below.
   ```

5. **Build AGENTS.md content** — Construct the scaffold with discovered commands as additions:

   ```markdown
   ## Pre-commit Gate
   <!-- Stack defaults (laravel): php artisan test, php artisan migrate:status -->
   {discovered commands, if any}

   ## Verification
   <!-- Stack defaults (laravel): php artisan test -->
   {discovered commands, if any}
   ```

6. **Idempotent write** —
   - **First run:** show the full content. Ask:
     ```
     Add AGENTS.md to this project?
     (y) yes  (e) edit  (n) skip
     ```
   - **Re-run (file exists):** show only what would change (diff). If nothing changed: "AGENTS.md is already up to date." Ask:
     ```
     Apply changes?
     (y) yes  (e) edit  (n) skip
     ```

7. **CLAUDE.md symlink** — Check if `CLAUDE.md` exists in the project root.
   - If not: create as a symlink: `ln -s AGENTS.md CLAUDE.md`
   - If it exists and is already a symlink to AGENTS.md: skip.
   - If it exists as a regular file: warn and ask before replacing.

8. **Report** — What was created or updated.

---

## tasks-list

List open tasks grouped by status.

**Usage:** `/tasks-list [{status}] [group:{number}]`

- No arguments: all open tasks grouped by status
- Status filter: `/tasks-list planned` — only planned tasks
- Group filter: `/tasks-list group:42` — only tasks in group #42

```bash
gh issue list --repo {owner}/{repo} --state open \
  --label "type:feature,type:bug,type:chore,type:docs,type:refactor" \
  --json number,title,labels --limit 200
```

Exclude `type:queue` and `type:group` issues.

Output format:
```
DRAFT
#34  Add bulk export              feature   small    medium
#41  Revamp onboarding flow       feature   large    high

PLANNED
#28  Fix session timeout          chore     small    low

PROGRESS
#31  Wholesale pricing            feature   large    high

BUILT
#29  Update email templates       chore     medium   medium

SHIPPED
#22  Add webhook retry            feature   medium   medium

REVIEW
#18  Buyer invite flow            feature   large    high
```

If filtering by group: show group name as header, tasks only from that group's queue.

---

## bugs-list

List open bugs grouped by status.

**Usage:** `/bugs-list [{status}]`

```bash
gh issue list --repo {owner}/{repo} --state open \
  --label "type:bug" --json number,title,labels --limit 200
```

Output format:
```
PLANNED
#44  Checkout fails with discount code    small    high

PROGRESS
#39  Email not sent on order              medium   high

BUILT
#36  Wrong tax rate on EU orders          small    medium
```

Optional status filter: `/bugs-list planned`

---

## work-list

Show all open work — tasks, bugs, and groups — in one view.

**Usage:** `/work-list`

Fetches tasks (all non-queue, non-group issues), bugs, and groups. Groups by type then status.

```
GROUPS
#42  Wholesale Management    3/7 tasks complete
#51  Analytics               0/4 tasks complete

TASKS
  PROGRESS
  #31  Wholesale pricing      feature   large   high

  PLANNED
  #28  Fix session timeout    chore     small   low

BUGS
  PROGRESS
  #39  Email not sent         medium    high

  PLANNED
  #44  Checkout discount      small     high
```

---

## work-summary

Show recent activity and current work-in-progress across the repository.

**Usage:** `/work-summary`

```bash
# Shipped in the last 14 days
gh issue list --repo {owner}/{repo} --state closed \
  --json number,title,labels,closedAt --limit 50

# Currently in review
gh pr list --repo {owner}/{repo} --state open \
  --json number,title,headRefName

# In progress
gh issue list --repo {owner}/{repo} --state open \
  --label "status:progress" --json number,title,labels
```

Output:
```
IN PROGRESS
#31  Wholesale pricing      feature   large

IN REVIEW
PR #47  feat(#31): wholesale pricing

SHIPPED THIS WEEK
#22  Add webhook retry      feature   (merged 2 days ago)
#18  Buyer invite flow      feature   (merged 5 days ago)

SHIPPED LAST WEEK
#15  Fix tax rate bug       bug       (merged 8 days ago)
```

---

## tasks-next

Find the next task to work on using the queue.

**Usage:** `/tasks-next`

1. Read the global queue issue. Find the first unchecked item (`- [ ]`).

2. If it is a group (`#{number} — Group:`): read that group's issue body, find the first unchecked task in its queue.

3. If it is a standalone task: use it directly.

4. If the queue is empty or no queue exists: fall back to listing planned tasks by priority (high → medium → low).

5. Fetch and display the task via `task-view`.

6. Ask:
   ```
   Work on #{number}?
   (y) yes — run /task-build {number}
   (n) show me more options
   ```

Bugs are never in the queue and are not surfaced by this skill.

---

## prioritize

Reorder the global queue interactively.

**Usage:** `/prioritize`

1. **Load** — Read the global queue issue. For each item, fetch current status and any blocking relationships.

2. **Display** with live context:
   ```
   GLOBAL QUEUE

   1. [ ] #{number} — Group: Wholesale Management  →  4 tasks remaining
   2. [ ] #{number} — Fix CSV export               (planned)
   3. [ ] #{number} — Group: Analytics             →  6 tasks, not started
   4. [ ] #{number} — Update docs                  (draft)
   ```
   Flag: closed tasks still in the queue, groups with no tasks, `flag:blocked` items.

3. **Recommend** — Surface ordering concerns from blocking relationships:
   ```
   RECOMMENDATION

   ⚠ #12 is blocked by #18, which appears later at position 4.
   ✓ No other ordering concerns.
   ```

4. **Reorder** —
   ```
   Make changes?
   (m) move an item  (s) swap two items  (y) accept recommendation  (d) done
   ```
   - `(m)`: ask item number, then destination position. Update and redisplay.
   - `(s)`: ask two item numbers. Swap and redisplay.
   - `(y)`: apply recommendations, redisplay for confirmation.
   - Repeat until `(d)`.

5. Write the updated order back to the global queue issue body.

---

## prioritize-group

Reorder tasks within a specific group's queue interactively.

**Usage:** `/prioritize-group {number}`

1. **Load** — Read the group issue. Parse the `## Queue` section. For each task, fetch current status and blocking relationships.

2. **Display** with live context:
   ```
   GROUP QUEUE — Wholesale Management (#42)

   1. [ ] #{number} — Scaffold wholesale model   (planned)
   2. [ ] #{number} — Add pricing rules           (draft)
   3. [ ] #{number} — Build buyer invite flow     (draft)
   ```
   Flag: closed tasks still in the queue, `flag:blocked` items.

3. **Recommend** — Surface ordering concerns:
   ```
   RECOMMENDATION

   ⚠ #16 is blocked by #15, which appears later at position 3.
   ```

4. **Reorder** —
   ```
   Make changes?
   (m) move an item  (s) swap two items  (y) accept recommendation  (d) done
   ```
   Same mechanics as `prioritize`.

5. Write the updated order back to the group issue body.

---

## merge-main

Merge the latest `main` into the current branch. Helps resolve conflicts interactively.

**Usage:** `/merge-main`

1. **Check branch** — Confirm current branch is not `main`:
   ```bash
   git branch --show-current
   ```
   If on `main`: stop. "Cannot merge main into itself. Check out your working branch first."

2. **Fetch and merge**:
   ```bash
   git fetch origin main
   git merge origin/main
   ```

3. **If clean** — "Merged latest main into {branch}."

4. **If conflicts** — List the conflicting files:
   ```bash
   git diff --name-only --diff-filter=U
   ```

   For each conflicting file, show the conflict markers and offer help:
   ```
   Conflict in {file}:
   {diff excerpt showing conflict markers}

   (r) resolve this conflict  (s) skip — resolve manually  (a) abort merge
   ```

   If `(r)`:
   - Show both sides of the conflict clearly.
   - Propose a resolution. Show it.
   - Confirm: `Apply this resolution? (y) yes  (e) edit  (n) skip`
   - On yes: apply the resolution, stage the file.

   After all conflicts are handled or skipped:
   - If all resolved: `git merge --continue`
   - If any skipped: list remaining conflicts and instruct the user to resolve manually before running `git merge --continue`.
