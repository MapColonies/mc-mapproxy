#!/bin/sh
set -e

# Create temporary directories MapProxy needs for locks and cache
mkdir -p /tmp/mapproxy/locks /tmp/mapproxy/cache

# If no arguments were passed (or the default CMD "uwsgi" is given), launch
# uWSGI with the full option set.  This allows env-var expansion for
# PROCESSES / THREADS while still exec-ing uWSGI as PID 1.
if [ "$1" = "uwsgi" ] || [ $# -eq 0 ]; then
    exec uwsgi \
        --socket 0.0.0.0:3031 \
        --protocol uwsgi \
        --http-socket 0.0.0.0:8080 \
        --wsgi-file /mapproxy/app.py \
        --callable application \
        --master \
        --processes "${PROCESSES:-6}" \
        --cheaper 2 \
        --enable-threads \
        --threads "${THREADS:-10}" \
        --harakiri 120 \
        --wsgi-disable-file-wrapper \
        --lazy-app \
        --buffer-size 14336 \
        --max-requests 1000 \
        --reload-on-rss 2048 \
        --worker-reload-mercy 60 \
        --need-app \
        --die-on-term \
        --vacuum \
        --log-5xx \
        --log-4xx \
        --memory-report
fi

# For any other command (e.g. "bash", "python", debugging), exec it directly.
exec "$@"
