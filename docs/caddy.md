# Caddy reference

## Installation

Built from source using `xcaddy` with the Cloudflare DNS module. Go 1.26.3 installed at `/usr/local/go/` for the build.

```bash
xcaddy build --with github.com/caddy-dns/cloudflare
mv caddy /usr/local/bin/caddy
```

Binary: `/usr/local/bin/caddy`  
Version: v2.11.2 with `dns.providers.cloudflare`

## Key paths

| Path | What it is |
|---|---|
| `/etc/caddy/Caddyfile` | Main config |
| `/etc/caddy/cloudflare.env` | `CF_API_TOKEN=…` (mode 600, owned by caddy) |
| `/var/lib/caddy/` | Caddy home: ACME certs, autosave config |
| `/var/log/caddy/` | Log dir (Caddy uses journald by default) |
| `~/.devbox/caddy/sites.d/` | Per-branch site snippets (imported when `devup` activates) |

## Service management

```bash
systemctl status caddy
systemctl reload caddy     # hot-reload config (preferred over restart)
systemctl restart caddy    # full restart if reload doesn't pick up changes
journalctl -u caddy -f     # tail logs
```

## Config structure

The Caddyfile has two blocks for now:

- `*.joshevensen.com` — wildcard block; handles all subdomains
- `joshevensen.com` — apex block

Both use DNS-01 via Cloudflare for TLS (required for wildcard certs).

Once `devup` is working, the import directive at the bottom is uncommented:

```
import /root/.devbox/caddy/sites.d/*.caddy
```

Each `.caddy` file in that dir routes `<branch>.<project>.joshevensen.com` to the appropriate local port.

## Adding a site manually

Create `/root/.devbox/caddy/sites.d/<name>.caddy`:

```
handle @<project>-<branch> {
  reverse_proxy 127.0.0.1:<port>
}
```

Then `systemctl reload caddy`.

## TLS / cert renewal

Caddy handles renewal automatically. Certs are stored in `/var/lib/caddy/.local/share/caddy/`. Check renewal health with:

```bash
journalctl -u caddy | grep -i "certif"
```

## Token location

The Cloudflare API token is stored in two places:
- `~/.devbox/secrets/cloudflare.env` — source of truth (`CLOUDFLARE_API_TOKEN=…`)
- `/etc/caddy/cloudflare.env` — Caddy's copy (`CF_API_TOKEN=…`), loaded by systemd `EnvironmentFile`

If you rotate the token, update both files and `systemctl restart caddy`.
