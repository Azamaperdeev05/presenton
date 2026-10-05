#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"

export APP_DATA_DIRECTORY="$DIR/app_data"
export USER_CONFIG_PATH="$APP_DATA_DIRECTORY/userConfig.json"
export FAST_API_INTERNAL_URL="http://127.0.0.1:8000"
export NEXT_PUBLIC_FAST_API="http://127.0.0.1:8000"
export NEXT_PUBLIC_URL="http://localhost:3000"
export MIGRATE_DATABASE_ON_STARTUP="true"
export CAN_CHANGE_KEYS="true"
export DISABLE_AUTH="true"
export NEXT_PUBLIC_DISABLE_AUTH="true"

# Export runtime settings for PPTX/PDF generation
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

# Ensure presentation-export package is ready
if [ ! -f "$DIR/presentation-export/runner.mjs" ]; then
    echo "📦 Syncing presentation-export runtime..."
    node "$DIR/scripts/sync-presentation-export.cjs"
fi

echo "=========================================="
echo "🚀 Starting Presenton locally..."
echo "=========================================="

cd "$DIR/servers/fastapi"
if [ -f "$DIR/servers/fastapi/.venv/bin/python" ]; then
    "$DIR/servers/fastapi/.venv/bin/python" server.py --port 8000 --reload false &
else
    uv run python server.py --port 8000 --reload false &
fi
FASTAPI_PID=$!

cd "$DIR/servers/nextjs"
npm run dev -- -H 127.0.0.1 -p 3000 &
NEXTJS_PID=$!

cleanup() {
    echo ""
    echo "🛑 Shutting down Presenton servers..."
    kill $FASTAPI_PID $NEXTJS_PID 2>/dev/null || true
    wait $FASTAPI_PID $NEXTJS_PID 2>/dev/null || true
}

trap cleanup SIGINT SIGTERM EXIT

echo ""
echo "✨ Presenton is launching!"
echo "📡 FastAPI Backend:  http://127.0.0.1:8000"
echo "🌐 Next.js Frontend: http://localhost:3000"
echo ""

wait
