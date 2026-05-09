#!/usr/bin/env bash
set -euo pipefail

[ -d deps ] || mix deps.get
mix ecto.migrate

exec mix phx.server
