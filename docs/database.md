# Database guide

PostgreSQL 16 reference for this server. Installed 2026-05-07.

## At a glance

| | |
|---|---|
| Version | PostgreSQL 16.13 (Ubuntu repo) |
| Listen | `127.0.0.1:5432` (local only) |
| Service | `postgresql` (systemd, enabled at boot) |
| Superuser | `postgres` (peer auth via unix socket) |
| Config dir | `/etc/postgresql/16/main/` |
| Data dir | `/var/lib/postgresql/16/main/` |
| Log file | `/var/log/postgresql/postgresql-16-main.log` |

## Convention

**One role + one database per project.** The role and database share the same name. This keeps projects isolated — a Laravel app can't accidentally read an Elixir app's data.

## Aliases & helpers

These are defined in `~/.bash_aliases` (sourced automatically by `.bashrc`). Run `source ~/.bash_aliases` after edits, or open a new shell.

### Aliases

| Alias | Command |
|---|---|
| `pg` | `sudo -u postgres psql` — superuser shell |
| `pgls` | `sudo -u postgres psql -l` — list all databases |
| `pgstatus` | service status |
| `pgstart` / `pgstop` / `pgrestart` / `pgreload` | service controls |
| `pglog` | tail the postgres log |
| `pgconf` | `cd` into the config directory |

### Functions

| Function | Purpose |
|---|---|
| `pgnewdb <name> [password]` | Create a project role + database. Prompts for password if omitted. Name must be lowercase + underscores. |
| `pgdropdb <name>` | Drop a project's role + database (asks you to retype the name to confirm). |
| `pgc <db>` | Open a `psql` shell on a specific database as the `postgres` superuser. |
| `pgdump <db> [dir]` | Dump a database to `<db>-YYYYMMDD-HHMMSS.sql.gz` (current dir by default). |

## Workflow: starting a new project

```bash
pgnewdb myapp                  # prompts for password (hidden)
# or:
pgnewdb myapp 's3cret'         # password inline
```

Then plug the credentials into your app:

### Laravel (`.env`)
```
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=myapp
DB_USERNAME=myapp
DB_PASSWORD=s3cret
```
Run `php artisan migrate` to verify.

### Elixir / Phoenix (`config/dev.exs`)
```elixir
config :myapp, MyApp.Repo,
  username: "myapp",
  password: "s3cret",
  hostname: "127.0.0.1",
  database: "myapp",
  pool_size: 10
```
Run `mix ecto.create` (will succeed since DB already exists) then `mix ecto.migrate`.

### Python (`psycopg` / SQLAlchemy)
```python
import psycopg
conn = psycopg.connect("postgresql://myapp:s3cret@127.0.0.1:5432/myapp")
```
Or as a SQLAlchemy URL: `postgresql+psycopg://myapp:s3cret@127.0.0.1:5432/myapp`

## Backup & restore

Quick backup of a single database:
```bash
pgdump myapp                       # writes ./myapp-YYYYMMDD-HHMMSS.sql.gz
pgdump myapp /var/backups/pg       # to a specific directory
```

Restore from a dump:
```bash
gunzip -c myapp-20260507-120000.sql.gz | sudo -u postgres psql -d myapp
```

Dump everything (roles, databases, all):
```bash
sudo -u postgres pg_dumpall | gzip > all-$(date +%F).sql.gz
```

## Common psql commands

Inside a `psql` shell:

| Command | Effect |
|---|---|
| `\l` | List databases |
| `\c <db>` | Connect to a database |
| `\dt` | List tables in current db |
| `\d <table>` | Describe a table |
| `\du` | List roles |
| `\dn` | List schemas |
| `\df` | List functions |
| `\timing` | Toggle query timing |
| `\x` | Toggle expanded display (good for wide rows) |
| `\?` | Help on `\` commands |
| `\q` | Quit |

## Manual role + database creation

If you need something the helper doesn't cover:

```sql
-- as `postgres` superuser (run `pg`)
CREATE ROLE myapp WITH LOGIN PASSWORD 'change-me';
CREATE DATABASE myapp OWNER myapp;
GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp;

-- read-only role for reporting:
CREATE ROLE myapp_ro WITH LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE myapp TO myapp_ro;
\c myapp
GRANT USAGE ON SCHEMA public TO myapp_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO myapp_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO myapp_ro;
```

## Opening up remote access (later)

The server is currently localhost-only. To allow remote connections (e.g., from your laptop):

1. Edit `/etc/postgresql/16/main/postgresql.conf` → set `listen_addresses = '*'`
2. Edit `/etc/postgresql/16/main/pg_hba.conf` → add a line like:
   ```
   host    all    all    YOUR.IP.HERE/32    scram-sha-256
   ```
   **Don't use `0.0.0.0/0` on a public server** — restrict to specific IPs or a VPN range.
3. Open the firewall port: `ufw allow from YOUR.IP.HERE to any port 5432`
4. `pgrestart`

## Troubleshooting

- **"role does not exist"** — you used the wrong username, or you forgot to create the role. Check with `pg` then `\du`.
- **"password authentication failed"** — wrong password, or you're connecting to the wrong db (Postgres requires the role have access to the specific db). Re-check `.env`.
- **"could not connect to server"** — `pgstatus`. If it's down, `pglog` to see why.
- **Connection works as `postgres` but not as a project user** — `pg_hba.conf` controls this. The default config allows `127.0.0.1` connections with password auth, which is what we want.
- **Forgot a password** — reset with `pg` then `ALTER ROLE myapp WITH PASSWORD 'new-one';`.
