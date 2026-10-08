@echo off
setlocal enabledelayedexpansion

echo Stopping Presenton servers...

taskkill /FI "WINDOWTITLE eq Presenton FastAPI*" /F /T >nul 2>&1
taskkill /FI "WINDOWTITLE eq Presenton Next.js*" /F /T >nul 2>&1

rem Terminate processes listening on port 8000 and 3000
for /f "tokens=5" %%a in ('netstat -aon ^| find ":8000" ^| find "LISTENING"') do (
    echo Stopping process on port 8000 (PID: %%a)...
    taskkill /f /pid %%a >nul 2>&1
)

for /f "tokens=5" %%a in ('netstat -aon ^| find ":3000" ^| find "LISTENING"') do (
    echo Stopping process on port 3000 (PID: %%a)...
    taskkill /f /pid %%a >nul 2>&1
)

echo Presenton stopped.
