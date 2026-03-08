# syntax=docker/dockerfile:1
# ─────────────────────────────────────────────────────────────────────────────
# MapProxy with OpenTelemetry Instrumentation
# ─────────────────────────────────────────────────────────────────────────────

# Single-source version — referenced in pip install, LABELs, and ENV.
ARG MAPPROXY_VERSION=6.0.1

# OCI label build args (set by CI; safe defaults for local builds)
ARG BUILD_DATE="1970-01-01T00:00:00Z"
ARG VCS_REF="unknown"
ARG IMAGE_SOURCE="https://github.com/MapColonies/mc-mapproxy"

# ── Build Stage ──────────────────────────────────────────────────────────────
FROM python:3.11-slim-bookworm AS builder

ARG MAPPROXY_VERSION

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgeos-dev \
    libgdal-dev \
    libproj-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libpng-dev \
    libffi-dev

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    "MapProxy==${MAPPROXY_VERSION}" \
    "uWSGI" \
    "redis" \
    "opentelemetry-api" \
    "opentelemetry-sdk" \
    "opentelemetry-distro" \
    "opentelemetry-instrumentation-wsgi" \
    "opentelemetry-instrumentation-logging" \
    "opentelemetry-instrumentation-redis" \
    "opentelemetry-instrumentation-sqlite3" \
    "opentelemetry-exporter-otlp-proto-grpc" \
    "opentelemetry-exporter-otlp-proto-http" \
    "opentelemetry-propagator-b3" \
    "opentelemetry-instrumentation-botocore" \
    "opentelemetry-instrumentation-requests" \
    "opentelemetry-instrumentation-urllib3" \
    "opentelemetry-instrumentation-sqlalchemy" \
    "opentelemetry-instrumentation-psycopg2" \
    "psycopg2-binary" \
    "boto3" \
    "sqlalchemy"

# Apply MapProxy patches
# Uses a bind mount so the patch file is never written into an image layer —
# only the result (the overwritten site-packages file) is committed.
# Set PATCH_FILES=false at build time to skip (e.g. for upstream compat tests).
ARG PATCH_FILES=true
RUN --mount=type=bind,source=config/patch/redis.py,target=/tmp/redis_patch.py \
    if [ "${PATCH_FILES}" = "true" ]; then \
    cp /tmp/redis_patch.py \
    /opt/venv/lib/python3.11/site-packages/mapproxy/cache/redis.py && \
    echo "[patch] redis.py applied"; \
    fi

# ── Runtime Stage ───────────────────────────────────────────────────────────
FROM python:3.11-slim-bookworm

# Install runtime libraries (changes rarely — cached early)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libgeos-c1v5 \
    libgdal32 \
    libproj25 \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libjpeg62-turbo \
    libpng16-16

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Re-declare ARGs needed in this stage (ARGs don't cross FROM boundaries)
ARG MAPPROXY_VERSION
ARG BUILD_DATE
ARG VCS_REF
ARG IMAGE_SOURCE

# OCI metadata labels
LABEL org.opencontainers.image.title="MapProxy" \
    org.opencontainers.image.version="${MAPPROXY_VERSION}" \
    org.opencontainers.image.description="MapProxy ${MAPPROXY_VERSION} with OpenTelemetry instrumentation" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="${IMAGE_SOURCE}"

# Environment defaults — paths & Python
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED="1"

# Environment defaults — service version (read by app.py at runtime)
ENV SERVICE_VERSION="${MAPPROXY_VERSION}"

# Environment defaults — OpenTelemetry
ENV OTEL_SERVICE_NAME="mapproxy" \
    OTEL_TRACES_EXPORTER="otlp" \
    OTEL_METRICS_EXPORTER="otlp" \
    OTEL_LOGS_EXPORTER="otlp" \
    TELEMETRY_TRACING_ENDPOINT="localhost:4317" \
    OTEL_PROPAGATORS="tracecontext,baggage,b3" \
    OTEL_PYTHON_LOG_CORRELATION="false"

# Environment defaults — Application
ENV MAPPROXY_CONFIG="/mapproxy/mapproxy.yaml" \
    LOG_CONFIG="/mapproxy/log.ini"

# Environment defaults — Telemetry
ENV TELEMETRY_TRACING_ENABLED="true" \
    TELEMETRY_TRACING_SAMPLING_RATIO_DENOMINATOR="1000" \
    TELEMETRY_BOTO_ENABLED="true" \
    TELEMETRY_BOTO_CAPTURE_HEADERS="false" \
    TELEMETRY_HTTP_ENABLED="true" \
    TELEMETRY_SQL_ENABLED="true" \
    TELEMETRY_TILE_CACHE_ENABLED="true"

# Environment defaults — CORS
ENV CORS_ENABLED="true" \
    CORS_ALLOWED_ORIGIN="*" \
    CORS_ALLOWED_HEADERS="*" \
    CORS_ALLOWED_METHODS="GET,OPTIONS"

# Environment defaults — Redis resilience
# Short timeouts ensure a slow/unreachable Redis never stalls a tile request;
# errors return False (cache-miss) so MapProxy falls back to the next source.
# REDIS_POOL_TIMEOUT: max seconds to wait for a free connection from the pool.
# SSL_CERT_REQS: server-cert verification ('required'/'optional'/'none').
ENV SOCKET_TIMEOUT_SECONDS="0.1" \
    SOCKET_CONNECTION_TIMEOUT_SECONDS="0.1" \
    REDIS_POOL_TIMEOUT="0.1" \
    REDIS_TLS="false" \
    SSL_CERT_REQS="required"

# Environment defaults — uWSGI tuning
ENV PROCESSES="6" \
    THREADS="10"

# Create non-root user and working directory
RUN useradd -m -u 1000 -s /bin/bash mapproxy && \
    mkdir -p /mapproxy

WORKDIR /mapproxy

# Copy application code and entrypoint (single layer, correct ownership)
COPY --chown=mapproxy:mapproxy src/app.py /mapproxy/app.py
COPY --chown=mapproxy:mapproxy entrypoint.sh /mapproxy/entrypoint.sh

# Fix permissions: mapproxy owns /mapproxy, group 0 can read/write (OpenShift)
RUN chown -R mapproxy:mapproxy /mapproxy && \
    chgrp -R 0 /mapproxy && \
    chmod -R g=u /mapproxy && \
    chmod +x /mapproxy/entrypoint.sh

# Health check — hit the HTTP socket to confirm uWSGI + MapProxy are alive
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:8080/ || exit 1

# Drop to non-root
USER mapproxy

# Expose HTTP (8080) and uWSGI binary protocol (3031)
EXPOSE 8080 3031

# Entrypoint creates temp dirs, then execs the CMD so uWSGI is PID 1
ENTRYPOINT ["/mapproxy/entrypoint.sh"]

CMD ["uwsgi"]
