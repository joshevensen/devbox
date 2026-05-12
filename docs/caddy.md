# Caddy reference

## Installation

Handled automatically by `install.sh`. Standard apt Caddy lacks the Cloudflare DNS module required for wildcard TLS, so the script builds from source with `xcaddy`.

What the script does:

1. Installs Go to `/usr/local/go/`
2. Installs `xcaddy` via `go install`
3. Builds Caddy with `--with github.com/caddy-dns/cloudflare`
4. Places the binary at `/usr/local/bin/caddy`
5. Creates the `caddy` system user and `/etc/caddy`, `/var/lib/caddy`, `/var/log/caddy` directories
6. Installs `scripts/caddy.service` to `/etc/systemd/system/` and enables the service

To reproduce manually (e.g. to upgrade Caddy):

```bash
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
xcaddy build v2.11.2 --with github.com/caddy-dns/cloudflare --output /usr/local/bin/caddy
systemctl restart caddy
```

Binary: `/usr/local/bin/caddy`  
Version: v2.11.2 with `dns.providers.cloudflare`

**After install:** add your Cloudflare API token:

```bash
echo "CF_API_TOKEN=your-token-here" > /etc/caddy/cloudflare.env
chmod 600 /etc/caddy/cloudflare.env
chown caddy /etc/caddy/cloudflare.env
systemctl restart caddy
```

## Key paths

| Path | What it is |
|---|---|
| `/etc/caddy/Caddyfile` | Main config |
| `/etc/caddy/cloudflare.env` | `CF_API_TOKEN=…` (mode 600, owned by caddy) |
| `/var/lib/caddy/` | Caddy home: ACME certs, autosave config |
| `/var/log/caddy/` | Log dir (Caddy uses journald by default) |
| `~/devbox/.caddy/sites.d/` | Per-branch site snippets (imported when `devup` activates) |

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
import /root/devbox/.caddy/sites.d/*.caddy
```

Each `.caddy` file in that dir routes `<branch>.<project>.joshevensen.com` to the appropriate local port.

## Adding a site manually

Create `~/devbox/.caddy/sites.d/<name>.caddy`:

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
- `~/devbox/.secrets/cloudflare.env` — source of truth (`CLOUDFLARE_API_TOKEN=…`)
- `/etc/caddy/cloudflare.env` — Caddy's copy (`CF_API_TOKEN=…`), loaded by systemd `EnvironmentFile`

If you rotate the token, update both files and `systemctl restart caddy`.
