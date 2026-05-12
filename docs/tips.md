# Tips & tricks

Day-to-day usage reference: tmux, shell aliases, project commands, and skills.

---

## tmux

tmux is the recommended way to work on this server. Sessions survive SSH disconnects and network changes — start one and leave it running.

```bash
tmux               # start a new session
tmux new -s main   # named session
tmux attach        # reattach to most recent session
tmux ls            # list sessions
```

### Key bindings

All tmux shortcuts start with the prefix `Ctrl+B`, then a key.

| Keys | Action |
|---|---|
| `Ctrl+B [` | Enter scroll mode — use arrow keys or Page Up/Down to scroll; `q` to exit |
| `Ctrl+B d` | Detach (session keeps running in background) |
| `Ctrl+B c` | New window |
| `Ctrl+B n` / `Ctrl+B p` | Next / previous window |
| `Ctrl+B 0–9` | Jump to window by number |
| `Ctrl+B %` | Split pane vertically |
| `Ctrl+B "` | Split pane horizontally |
| `Ctrl+B o` | Focus next pane |
| `Ctrl+B z` | Zoom / unzoom current pane (full-screen toggle) |
| `Ctrl+B &` | Close current window (with confirmation) |
| `Ctrl+B x` | Close current pane (with confirmation) |

---

## Shell aliases

Defined in `~/devbox/home/bash_aliases` (symlinked to `~/.bash_aliases`).

### Claude Code

| Alias | Command |
|---|---|
| `dev` | `cd ~/devbox && claude` — open Claude Code in devbox context |
| `yolo` | `cd ~/devbox && claude --dangerously-skip-permissions` — skip all permission prompts |

### PostgreSQL

| Alias / Function | What it does |
|---|---|
| `pg` | Open a superuser `psql` shell |
| `pgls` | List all databases |
| `pgstatus` | Show PostgreSQL service status |
| `pgstart` / `pgstop` / `pgrestart` / `pgreload` | Service controls |
| `pglog` | Tail the PostgreSQL log |
| `pgconf` | `cd` into `/etc/postgresql/16/main/` |
| `pgnewdb <name> [password]` | Create a project role + database (prompts for password if omitted) |
| `pgdropdb <name>` | Drop a project role + database (requires typing the name to confirm) |
| `pgc <db>` | Open `psql` connected to a specific database |
| `pgdump <db> [dir]` | Dump a database to a timestamped `.sql.gz` file |

---

## Project commands

These scripts live in `~/devbox/scripts/` (on `PATH` automatically).

| Command | What it does |
|---|---|
| `project-init <git-url> [name]` | Clone a repo as a bare repo and create its secrets file under `.secrets/`. Run once per project. |
| `project-up <project> <branch>` | Spin up a full branch environment: worktree, Postgres DB, env file, Caddy snippet, systemd unit. |
| `project-up <project> <branch> <git-ref>` | Same, but check out a specific commit or tag instead of the branch tip. |
| `project-down <project> <branch>` | Tear down an environment: stop service, remove Caddy snippet, drop DB (with confirmation), remove worktree. |
| `project-down <project> <branch> --force` | Same, but skip the DB drop confirmation. |
| `project-logs <project> <branch>` | Tail the service logs via `journalctl` (last 50 lines + follow). |
| `devls` | List all active environments with project, branch, URL, port, and service status. |

---

## Skills

Run any skill from a Claude Code session with `/skill-name`. Skills use GitHub Issues as the backing store — make sure `gh auth login` has been run.

### Task flow

| Skill | What it does |
|---|---|
| `/task-create` | Create a new task (GitHub Issue) with title, description, labels |
| `/task-plan` | Break a task into subtasks and write an implementation plan |
| `/task-build` | Start work on a task: create branch, spin up environment, begin implementation |
| `/task-ship` | Finish a task: open a PR, request review, update issue status |
| `/task-edit` | Edit the title, description, or labels on an existing task |
| `/task-cancel` | Close a task without shipping it |
| `/task-split` | Split one task into two or more smaller tasks |
| `/task-move` | Move a task to a different group or milestone |
| `/task-view` | Display the full details of a task |
| `/tasks-list` | List all open tasks with status and labels |
| `/tasks-next` | Suggest the highest-priority task to work on next |

### Bug flow

| Skill | What it does |
|---|---|
| `/bug-explore <url>` | Investigate a bug from a Sentry URL or description |
| `/bug-fix` | Implement a fix for an open bug issue |
| `/bug-ship` | Ship a bug fix: open a PR and update the issue |
| `/bug-retry` | Re-attempt a bug fix that didn't pass review |
| `/bug-view` | Display the full details of a bug issue |
| `/bugs-list` | List all open bug issues |

### PR flow

| Skill | What it does |
|---|---|
| `/pr-open` | Open a pull request for the current branch |
| `/pr-feedback` | Respond to PR review comments and push updates |
| `/pr-review` | Review an open PR for correctness, style, and completeness |

### Groups

| Skill | What it does |
|---|---|
| `/group-create` | Create a group (milestone) to track related tasks |
| `/group-edit` | Edit a group's title or description |
| `/group-close` | Close a completed group |
| `/group-view` | Display a group and its tasks |
| `/groups-list` | List all open groups |
| `/prioritize-group` | Re-order the tasks within a group by priority |

### Refactor

| Skill | What it does |
|---|---|
| `/refactor` | Plan and begin a refactor task |
| `/refactor-ship` | Ship a completed refactor: PR + issue update |

### Repo management

| Skill | What it does |
|---|---|
| `/repo-add` | Register a new project with its stack |
| `/repo-remove` | Remove a project from the devbox registry |
| `/repo-list` | List all registered projects and their running branches |
| `/repo-setup` | Re-apply stack setup for an existing project |
| `/repo-scaffold` | Generate an `AGENTS.md` for a project (stack defaults, commands) |

### Utilities

| Skill | What it does |
|---|---|
| `/work-list` | List all in-progress and review work across projects |
| `/work-summary` | Show recent activity: in progress, in review, shipped this week |
| `/prioritize` | Re-order the open task backlog by priority |
| `/git-ship` | Group pending changes into logical commits, confirm, then commit and push |
| `/merge-main` | Merge the latest `main` into the current branch |
| `/discuss` | Open a freeform discussion / brainstorm session |
| `/view-file <path>` | Display a file in chat with syntax highlighting; supports line ranges (`/view-file path 40-80`) |
| `/view-directory [path]` | Display a file tree for a directory (depth 2) |
