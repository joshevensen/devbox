# SSH Access

Two SSH targets, same server, same key:

| Alias | User | Purpose |
|---|---|---|
| `ssh devbox` | `devbox` | Day-to-day work — Claude Code, repos, development |
| `ssh devbox-root` | `root` | System administration only |

The `devbox` user has passwordless sudo for any system task it needs, but unlike `root` it can run Claude Code with `--dangerously-skip-permissions` (the `yolo` alias). Use `ssh devbox-root` only when you actually need a root shell.

## Client setup

Add both entries to `~/.ssh/config` on each client (laptop, Blink Shell, etc.):

```
Host devbox
    HostName <server-ip-or-hostname>
    User devbox
    IdentityFile ~/.ssh/<your-key>

Host devbox-root
    HostName <server-ip-or-hostname>
    User root
    IdentityFile ~/.ssh/<your-key>
```

Replace `<server-ip-or-hostname>` with your server's IP or domain, and `<your-key>` with your private key filename (e.g. `id_ed25519`).

## After first login as devbox

Authenticate tools that require per-user credentials:

```bash
gh auth login
stripe login
```

## How install.sh sets this up

- Creates the `devbox` user with home at `/home/devbox`
- Grants passwordless sudo via `/etc/sudoers.d/devbox`
- Copies `/root/.ssh/authorized_keys` → `/home/devbox/.ssh/authorized_keys` so the same key works for both hosts
- Symlinks all devbox config (`AGENTS.md`, `settings.json`, `skills`, etc.) into `/home/devbox`
- Both users share runtimes via a common asdf data dir at `/opt/asdf`
