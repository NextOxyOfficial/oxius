#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# AdsyClub one-command deploy + FULL reload.
#
#   cd /home/django/adsyclub && bash deploy.sh
#
# Pulls the latest code, runs migrations, rebuilds the Nuxt frontend, then
# reloads BOTH gunicorn (Django HTTP) AND the Celery worker + beat — so a single
# run picks up every code change (views, models, email templates, tasks) with no
# separate celery/script restart. Run as the `django` user; no sudo required
# (gunicorn reloads via a graceful HUP, Celery is owned by django).
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT="/home/django/adsyclub"
VENV="/home/django/venv"
PY="$VENV/bin/python"
CELERY="$VENV/bin/celery"
BEAT_SCHEDULE="/home/django/.local/state/adsyclub-celery/celerybeat-schedule"

cd "$PROJECT"

echo "==> [1/6] git pull"
git pull origin main

echo "==> [2/6] migrate"
"$PY" manage.py migrate --noinput

echo "==> [3/6] collectstatic"
"$PY" manage.py collectstatic --noinput >/dev/null

echo "==> [4/6] frontend build (nuxt generate -> dist)"
( cd frontend && npm run generate && rm -rf dist && cp -r .output/public dist )

echo "==> [5/6] reload gunicorn (graceful, zero-downtime)"
GMASTER="$(ps -eo pid,ppid,cmd | grep '[g]unicorn' | grep 'backend.wsgi' | awk '$2==1{print $1}' | head -1)"
if [ -n "$GMASTER" ]; then
  kill -HUP "$GMASTER" && echo "    gunicorn master $GMASTER reloaded"
else
  echo "    WARN: gunicorn master not found — start it with: sudo service adsyclub start"
fi

echo "==> [6/6] restart Celery worker + beat (reloads task/email code too)"
pkill -f 'celery -A backend' || true
sleep 2
mkdir -p "$(dirname "$BEAT_SCHEDULE")"
nohup "$CELERY" -A backend worker --loglevel=INFO --concurrency=2 --queues=celery \
  --max-tasks-per-child=300 --max-memory-per-child=300000 \
  >> /home/django/celery-worker.log 2>&1 &
nohup "$CELERY" -A backend beat --loglevel=INFO --schedule="$BEAT_SCHEDULE" \
  >> /home/django/celery-beat.log 2>&1 &
sleep 2
echo "    celery processes running: $(pgrep -fc 'celery -A backend' || echo 0)"

echo "==> DONE — code, frontend, gunicorn and Celery all reloaded."
