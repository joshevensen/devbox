# bug-explore

Investigate a bug from Sentry URLs and/or a plain description. Groups related Sentry issues, explores the codebase, discusses root cause, and creates a fully specced GitHub issue in one session.

## Usage

```
/bug-explore {sentry-url} [{sentry-url} ...]
/bug-explore "{description}"
/bug-explore {sentry-url} "{additional context}"
```

---

## Steps

### 1. Parse arguments

Separate any Sentry URLs from plain description text.

### 2. Duplicate check

Search open bug issues before creating anything:
```bash
gh issue list --repo {owner}/{repo} --state open --label "type:bug" \
  --search "{keywords}" --json number,title
```

If a possible duplicate is found:
```
Possible duplicate: #{number} — {title}
(c) continue anyway  (v) view that issue  (n) cancel
```

### 3. Sentry grouping (multiple URLs only)

If more than one Sentry URL was provided, fetch all issues and analyze stack traces, error types, messages, and affected code paths. Group them by likely root cause:

```
SENTRY ISSUES

Group A — likely same root cause
  #1 {url} — {error type}: {message} in {file}:{line}
  #3 {url} — {error type}: {message} in {file}:{line}

Group B — unrelated
  #2 {url} — {error type}: {message} in {file}:{line}

Reasoning: {brief explanation}

(p) proceed with Group A    (s) split — explore each separately    (n) cancel
```

- `(p)`: continue with that group as one bug.
- `(s)`: stop and instruct the user to rerun `/bug-explore` with each group's links separately.
- `(n)`: cancel.

If only one URL or a plain description: skip grouping.

### 4. Fetch Sentry data

For each URL in scope, extract: error type, message, stack trace, affected file and line, frequency, first/last seen, user or request context.

### 5. Explore codebase

Read-only scan using Sentry data and/or description:
- Find the files and functions in the stack trace
- Understand surrounding code and data flow
- Identify all plausible causes
- Note dependencies, recent changes, and risky patterns near the failure point

### 6. Discuss

Present findings and walk through potential causes. Ask questions if the root cause is not clear. Do not proceed to writing the spec until a confident conclusion has been reached.

### 7. Reproduce steps

Confirm steps to reproduce the bug. These go into the issue body.

### 8. Draft issue body

Show the proposed issue body:
```
Does this capture the bug?
(y) yes  (e) edit  (n) start over
```

Format:
```markdown
## Description

{What the bug is, observable behavior, and impact.}

## Sentry

{Sentry link(s), or "None — reported via {source}."}

## Steps to Reproduce

{Numbered steps.}
```

### 9. Create issue

Recommend labels:
```
Recommended priority: high — {reason}
(h) high  (m) medium  (l) low

Recommended size: small — {reason}
(s) small  (m) medium  (l) large
```

Always applies `type:bug` and `status:draft`.

```bash
gh issue create --repo {owner}/{repo} \
  --title "{title}" \
  --body "{body}" \
  --label "status:draft,type:bug,size:{size},priority:{priority}"
```

### 10. Post potential causes comment

List all candidates with reasoning, including ruled-out options and why:
```markdown
## Potential Causes

- **{Cause A}** — {reasoning, file/function/line}
- **{Cause B}** — {reasoning}
- **{Cause C}** — Ruled out because {reason}
```

### 11. Post decided cause comment

```markdown
## Root Cause

{Conclusion with specific file/function/line. Why other candidates were ruled out.}
```

### 12. Test plan

Generate and show:
```
Test plan — look right?
(y) yes  (e) edit  (n) start over
```

Format:
```markdown
## Test Plan

- [ ] {Reproduce before fix — confirm it occurs}
- [ ] {Verify after fix — confirm it no longer occurs}
- [ ] {Regression check}
```

Post on confirmation.

### 13. Subtasks

Generate and show. Typical pattern: implement fix, add regression test. Each needs a title, description, and build notes:
```
Subtasks — look right?
(y) yes  (e) edit one  (a) add one  (d) delete one  (n) start over
```

Format:
```markdown
## Subtasks

### 1 — {Title}

{Description}

**Build notes:** {files, functions, constraints, expected outcome}
```

Post on confirmation.

### 14. Update labels

```bash
gh issue edit {number} --repo {owner}/{repo} \
  --remove-label "status:draft" \
  --add-label "status:planned"
```

### 15. Confirm

```
Bug #{number} is planned. Run /bug-fix {number} when ready.
```
