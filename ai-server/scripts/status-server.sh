#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PID_FILE="$SERVER_DIR/.runtime/server.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "WatcherTracker AI server is stopped."
    exit 1
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    echo "WatcherTracker AI server is running."
    echo "PID: $PID"

    if curl -s --fail http://127.0.0.1:8765/health >/dev/null; then
        echo "API status: healthy"
    else
        echo "API status: process running, API not responding"
    fi

    exit 0
else
    echo "WatcherTracker AI server is stopped."

    rm -f "$PID_FILE"

    exit 1
fi