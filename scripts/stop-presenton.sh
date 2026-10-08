#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_DIR="$DIR/app_data/pids"
FASTAPI_PID_FILE="$PID_DIR/fastapi.pid"
NEXTJS_PID_FILE="$PID_DIR/nextjs.pid"

echo "Stopping Presenton..."

# 1. Kill recorded PIDs
if [ -f "$FASTAPI_PID_FILE" ]; then
    PID=$(cat "$FASTAPI_PID_FILE" 2>/dev/null)
    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null || true
    fi
    rm -f "$FASTAPI_PID_FILE"
fi

if [ -f "$NEXTJS_PID_FILE" ]; then
    PID=$(cat "$NEXTJS_PID_FILE" 2>/dev/null)
    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null || true
    fi
    rm -f "$NEXTJS_PID_FILE"
fi

# 2. Terminate any remaining processes on port 8000 and 3000
kill_port() {
    local port="$1"
    if command -v lsof >/dev/null 2>&1; then
        local pids=$(lsof -ti:"$port" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo "Stopping processes on port $port: $pids"
            kill $pids 2>/dev/null || true
            sleep 0.5
            kill -9 $pids 2>/dev/null || true
        fi
    elif command -v fuser >/dev/null 2>&1; then
        fuser -k -n tcp "$port" >/dev/null 2>&1 || true
    fi
}

kill_port 8000
kill_port 3000

echo "Presenton stopped."
if command -v osascript >/dev/null 2>&1; then
    osascript -e 'display notification "Presenton өшірілді." with title "Presenton"' >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "Presenton" "Presenton өшірілді." >/dev/null 2>&1 || true
fi
