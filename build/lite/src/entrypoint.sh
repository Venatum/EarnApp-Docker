#!/usr/bin/env bash
set -euo pipefail

BIN_PATH="/usr/bin/earnapp"
CONFIG_DIR="/etc/earnapp"

if [[ -z "${EARNAPP_UUID:-}" ]]; then
    echo "[ERROR] EARNAPP_UUID not set!"
    exit 1
fi

mkdir -p "$CONFIG_DIR"
echo -n "$EARNAPP_UUID" > "$CONFIG_DIR/uuid"
touch "$CONFIG_DIR/status"
chmod a+wr "$CONFIG_DIR/status"

echo "[entrypoint] Starting EarnApp..."
"$BIN_PATH" stop || true
sleep 1

backoff=5
MAX_BACKOFF=300

while true; do
    "$BIN_PATH" start || true
    sleep 2

    start_time=$(date +%s)
    "$BIN_PATH" run
    run_duration=$(( $(date +%s) - start_time ))

    if [[ $run_duration -gt 60 ]]; then
        backoff=5
        echo "[entrypoint] EarnApp exited after ${run_duration}s, restarting in ${backoff}s..."
    else
        echo "[entrypoint] EarnApp crashed after ${run_duration}s, backing off ${backoff}s..."
        sleep "$backoff"
        backoff=$((backoff * 2))
        [[ $backoff -gt $MAX_BACKOFF ]] && backoff=$MAX_BACKOFF
    fi

    "$BIN_PATH" stop || true
    sleep 1
done
