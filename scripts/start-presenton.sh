#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

if [ -n "$SSL_CERT_FILE" ] && [ ! -f "$SSL_CERT_FILE" ]; then
    unset SSL_CERT_FILE
fi
if [ -n "$REQUESTS_CA_BUNDLE" ] && [ ! -f "$REQUESTS_CA_BUNDLE" ]; then
    unset REQUESTS_CA_BUNDLE
fi
if [ -n "$CURL_CA_BUNDLE" ] && [ ! -f "$CURL_CA_BUNDLE" ]; then
    unset CURL_CA_BUNDLE
fi

PID_DIR="$DIR/app_data/pids"
LOG_FILE="$DIR/app_data/presenton.log"
mkdir -p "$PID_DIR"

FASTAPI_PID_FILE="$PID_DIR/fastapi.pid"
NEXTJS_PID_FILE="$PID_DIR/nextjs.pid"

export APP_DATA_DIRECTORY="$DIR/app_data"
export USER_CONFIG_PATH="$APP_DATA_DIRECTORY/userConfig.json"
export FAST_API_INTERNAL_URL="http://127.0.0.1:8000"
export NEXT_PUBLIC_FAST_API="http://127.0.0.1:8000"
export NEXT_PUBLIC_URL="http://localhost:3000"
export MIGRATE_DATABASE_ON_STARTUP="true"
export CAN_CHANGE_KEYS="true"
export DISABLE_AUTH="true"
export NEXT_PUBLIC_DISABLE_AUTH="true"
export EXPORT_PACKAGE_ROOT="$DIR/presentation-export"
export PRESENTON_APP_ROOT="$DIR"

if [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fi

mkdir -p "$APP_DATA_DIRECTORY/exports" \
         "$APP_DATA_DIRECTORY/images" \
         "$APP_DATA_DIRECTORY/uploads" \
         "$APP_DATA_DIRECTORY/fonts" \
         "$APP_DATA_DIRECTORY/templates" \
         "$APP_DATA_DIRECTORY/pptx-to-html" \
         "$APP_DATA_DIRECTORY/pptx-to-json"

if [ ! -f "$USER_CONFIG_PATH" ]; then
    echo "{}" > "$USER_CONFIG_PATH"
fi

# 1. Check if already running
IS_FASTAPI_RUNNING=0
IS_NEXTJS_RUNNING=0

if lsof -nP -iTCP:8000 -sTCP:LISTEN >/dev/null 2>&1; then
    IS_FASTAPI_RUNNING=1
fi

if lsof -nP -iTCP:3000 -sTCP:LISTEN >/dev/null 2>&1; then
    IS_NEXTJS_RUNNING=1
fi

if [ "$IS_FASTAPI_RUNNING" -eq 1 ] && [ "$IS_NEXTJS_RUNNING" -eq 1 ]; then
    echo "Presenton already running."
    if [ "$NO_OPEN_BROWSER" != "1" ] && [ "$1" != "--no-open" ]; then
        if [ -d "/Applications/Google Chrome.app" ]; then
            open -na "Google Chrome" --args --app="http://localhost:3000"
        else
            open "http://localhost:3000"
        fi
    fi
    exit 0
fi

echo "Starting Presenton backend and frontend..."

# 2. Start FastAPI if not running
if [ "$IS_FASTAPI_RUNNING" -eq 0 ]; then
    cd "$DIR/servers/fastapi"
    if [ -f ".venv/bin/python" ]; then
        nohup .venv/bin/python server.py --port 8000 --reload false >> "$LOG_FILE" 2>&1 &
        echo $! > "$FASTAPI_PID_FILE"
    else
        nohup uv run python server.py --port 8000 --reload false >> "$LOG_FILE" 2>&1 &
        echo $! > "$FASTAPI_PID_FILE"
    fi
fi

# 3. Start Next.js if not running
if [ "$IS_NEXTJS_RUNNING" -eq 0 ]; then
    cd "$DIR/servers/nextjs"
    nohup npm run dev -- -H 127.0.0.1 -p 3000 >> "$LOG_FILE" 2>&1 &
    echo $! > "$NEXTJS_PID_FILE"
fi

# 4. Wait for Next.js and FastAPI to become ready
echo "Waiting for Presenton to be ready..."
READY=0
for i in {1..30}; do
    STATUS_NEXT=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 || echo "000")
    STATUS_FAST=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/v1/auth/status || echo "000")
    if ([ "$STATUS_NEXT" = "200" ] || [ "$STATUS_NEXT" = "307" ] || [ "$STATUS_NEXT" = "308" ]) && [ "$STATUS_FAST" = "200" ]; then
        READY=1
        break
    fi
    sleep 1
done

if [ "$READY" -eq 1 ]; then
    echo "Presenton is ready!"
    if [ "$NO_OPEN_BROWSER" != "1" ] && [ "$1" != "--no-open" ]; then
        if [ -d "/Applications/Google Chrome.app" ]; then
            open -na "Google Chrome" --args --app="http://localhost:3000"
        else
            open "http://localhost:3000"
        fi
        osascript -e 'display notification "Presenton іске қосылды!" with title "Presenton"' >/dev/null 2>&1 || true
    fi
else
    echo "Timeout waiting for Presenton to start. Check $LOG_FILE"
fi
