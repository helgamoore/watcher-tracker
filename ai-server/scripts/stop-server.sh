#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PID_FILE="$SERVER_DIR/.runtime/server.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "WatcherTracker AI server is not running."
    exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping WatcherTracker AI server. PID: $PID"

    kill "$PID"

    while kill -0 "$PID" 2>/dev/null; do
        sleep 0.2
    done

    echo "Server stopped."
else
    echo "Server process does not exist."
fi

rm -f "$PID_FILE"