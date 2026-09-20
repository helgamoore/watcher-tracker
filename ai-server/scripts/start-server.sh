#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RUNTIME_DIR="$SERVER_DIR/.runtime"
PID_FILE="$RUNTIME_DIR/server.pid"
export LOG_FILE="$RUNTIME_DIR/server.log"

PYTHON="$SERVER_DIR/.venv/bin/python"

mkdir -p "$RUNTIME_DIR"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")

    if kill -0 "$PID" 2>/dev/null; then
        echo "WatcherTracker AI server is already running. PID: $PID"
        exit 0
    fi

    rm -f "$PID_FILE"
fi

cd "$SERVER_DIR"

nohup "$PYTHON" -m uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8765 \
    > "$LOG_FILE" 2>&1 &

PID=$!

echo "$PID" > "$PID_FILE"

echo "WatcherTracker AI server started."
echo "PID: $PID"
echo "Log: $LOG_FILE"