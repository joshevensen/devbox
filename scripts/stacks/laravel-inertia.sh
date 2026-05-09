#!/usr/bin/env bash
set -euo pipefail

[ -d vendor ] || composer install --no-interaction --prefer-dist
[ -d node_modules ] || npm ci

cat > .env << ENV
APP_NAME=$(basename "$PWD")
APP_ENV=${APP_ENV:-devbox}
APP_KEY=${APP_KEY:-}
APP_URL=$APP_URL
DB_CONNECTION=pgsql
DB_URL=$DATABASE_URL
REDIS_URL=$REDIS_URL
CACHE_STORE=redis
SESSION_DRIVER=redis
LOG_CHANNEL=stderr
VITE_APP_URL=$APP_URL
ENV

[ -z "${APP_KEY:-}" ] && php artisan key:generate --force

php artisan migrate --force
npm run build

exec php artisan serve --host=127.0.0.1 --port="$PORT"
