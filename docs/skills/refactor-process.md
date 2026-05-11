# Refactor Process

A lightweight two-skill flow for small, focused code improvements that don't warrant a full task. `refactor` makes the change interactively and stops before committing. `refactor-ship` commits and pushes.

If a refactor turns out to be large or requires architectural decisions, it should become a proper task. Use `/task-create` instead.

The PR flow continues in `pr-process.md`. Refactors are never added to the queue.

---

## Lifecycle

```
Description
  ↓ refactor       →  progress (change made, verified locally)
  ↓ refactor-ship  →  shipped
  → continue in pr-process.md
```

No draft or planned phase — the description IS the spec.

---

## Status Labels

| Label             | Set by        | Meaning                              |
|-------------------|---------------|--------------------------------------|
| `status:progress` | refactor      | Issue created, change in progress    |
| `status:built`    | refactor      | Change complete, verified locally    |
| `status:shipped`  | refactor-ship | Committed and pushed, ready for PR   |

---

## Issue Structure

A refactor issue is intentionally minimal. No comments — the issue body is the full record.

```markdown
## Description

{What was changed and why.}
```

Labels: `type:refactor`, `status:progress` → `status:built` → `status:shipped`

---

## refactor

**Usage:** `/refactor {description of the change}`

If no argument is provided, ask: "What do you want to refactor?"

Interactive — the change is made in real time with the user. If anything looks wrong mid-execution, correct it in the moment. No retry skill needed.

### Flow

1. **Scope check** — Do a read-only scan to understand how many files the change will touch and whether any architectural decisions are required.

   If more than ~8 files, or requires design decisions beyond cleanup:
   ```
   This looks bigger than a small refactor.
   Consider creating a proper task with /task-create instead.

   (p) proceed anyway  (n) cancel
   ```

2. **Create issue** — Create a minimal GitHub issue:
   - Title: short action-oriented summary
   - Body: the description
   - Labels: `type:refactor`, `status:progress`

3. **Branch** — Create off `origin/main`:
   ```bash
   git checkout -b refactor/{number}-{slug} origin/main
   ```

4. **Make the change** — Apply the refactor. Same no-guessing rules as `task-build`:
   - If anything is ambiguous or requires a judgment call, stop and ask before writing code.
   - Never guess. Surface the question, state what you'd lean toward, and let the user decide.

5. **Verify** — Run verification commands from the project's `AGENTS.md`. Stack defaults first, then project additions. See `utils.md` for command resolution.

6. **Update status** — Change `status:progress` to `status:built`.

7. **Report** — "Refactor #{number} is done. Run `/refactor-ship {number}` when ready to commit and push."

---

## refactor-ship

**Usage:** `/refactor-ship {number}`

### Flow

1. **Load** — Read the issue. Confirm `status:built`. Display branch name and description.

2. **Review changes** —
   ```bash
   git status --short
   git diff --stat
   ```
   Surface any unrelated changes — do not stage them.

3. **Pre-commit gate** — Run pre-commit gate commands from the project's `AGENTS.md`. Stack defaults first, then project additions. If a command fails, stop and report it.

4. **Commit** — Stage only refactor-related files. Commit:
   ```
   refactor(#{number}): {short description}
   ```

5. **Push** —
   ```bash
   git push -u origin refactor/{number}-{slug}
   ```

6. **Update status** — Change `status:built` to `status:shipped`.

7. **Report** — "Refactor #{number} is shipped. Run `/pr-open {number}` when ready to open a pull request."
