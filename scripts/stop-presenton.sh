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
PIDS_8000=$(lsof -ti:8000 2>/dev/null || true)
if [ -n "$PIDS_8000" ]; then
    echo "Stopping remaining port 8000 processes: $PIDS_8000"
    kill $PIDS_8000 2>/dev/null || true
fi

PIDS_3000=$(lsof -ti:3000 2>/dev/null || true)
if [ -n "$PIDS_3000" ]; then
    echo "Stopping remaining port 3000 processes: $PIDS_3000"
    kill $PIDS_3000 2>/dev/null || true
fi

sleep 1

# Force kill if still holding ports
PIDS_8000_FORCE=$(lsof -ti:8000 2>/dev/null || true)
if [ -n "$PIDS_8000_FORCE" ]; then
    kill -9 $PIDS_8000_FORCE 2>/dev/null || true
fi

PIDS_3000_FORCE=$(lsof -ti:3000 2>/dev/null || true)
if [ -n "$PIDS_3000_FORCE" ]; then
    kill -9 $PIDS_3000_FORCE 2>/dev/null || true
fi

echo "Presenton stopped."
osascript -e 'display notification "Presenton өшірілді." with title "Presenton"' >/dev/null 2>&1 || true
