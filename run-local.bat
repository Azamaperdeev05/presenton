@echo off
setlocal enabledelayedexpansion

set "DIR=%~dp0"
if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"

set "APP_DATA_DIRECTORY=%DIR%\app_data"
set "USER_CONFIG_PATH=%APP_DATA_DIRECTORY%\userConfig.json"
set "FAST_API_INTERNAL_URL=http://127.0.0.1:8000"
set "NEXT_PUBLIC_FAST_API=http://127.0.0.1:8000"
set "NEXT_PUBLIC_URL=http://localhost:3000"
set "MIGRATE_DATABASE_ON_STARTUP=true"
set "CAN_CHANGE_KEYS=true"
set "DISABLE_AUTH=true"
set "NEXT_PUBLIC_DISABLE_AUTH=true"
set "EXPORT_PACKAGE_ROOT=%DIR%\presentation-export"
set "PRESENTON_APP_ROOT=%DIR%"

rem Auto-detect Chrome or Edge on Windows
if exist "%PROGRAMFILES%\Google\Chrome\Application\chrome.exe" (
    set "PUPPETEER_EXECUTABLE_PATH=%PROGRAMFILES%\Google\Chrome\Application\chrome.exe"
) else if exist "%PROGRAMFILES(X86)%\Google\Chrome\Application\chrome.exe" (
    set "PUPPETEER_EXECUTABLE_PATH=%PROGRAMFILES(X86)%\Google\Chrome\Application\chrome.exe"
) else if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
    set "PUPPETEER_EXECUTABLE_PATH=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) else if exist "%PROGRAMFILES(X86)%\Microsoft\Edge\Application\msedge.exe" (
    set "PUPPETEER_EXECUTABLE_PATH=%PROGRAMFILES(X86)%\Microsoft\Edge\Application\msedge.exe"
) else if exist "%PROGRAMFILES%\Microsoft\Edge\Application\msedge.exe" (
    set "PUPPETEER_EXECUTABLE_PATH=%PROGRAMFILES%\Microsoft\Edge\Application\msedge.exe"
)

rem Create app_data directories
if not exist "%APP_DATA_DIRECTORY%\exports" mkdir "%APP_DATA_DIRECTORY%\exports"
if not exist "%APP_DATA_DIRECTORY%\images" mkdir "%APP_DATA_DIRECTORY%\images"
if not exist "%APP_DATA_DIRECTORY%\uploads" mkdir "%APP_DATA_DIRECTORY%\uploads"
if not exist "%APP_DATA_DIRECTORY%\fonts" mkdir "%APP_DATA_DIRECTORY%\fonts"
if not exist "%APP_DATA_DIRECTORY%\templates" mkdir "%APP_DATA_DIRECTORY%\templates"
if not exist "%APP_DATA_DIRECTORY%\pptx-to-html" mkdir "%APP_DATA_DIRECTORY%\pptx-to-html"
if not exist "%APP_DATA_DIRECTORY%\pptx-to-json" mkdir "%APP_DATA_DIRECTORY%\pptx-to-json"

if not exist "%USER_CONFIG_PATH%" echo {} > "%USER_CONFIG_PATH%"

echo ==========================================
echo Starting Presenton locally on Windows...
echo ==========================================

rem Check Python
set "PYTHON_CMD=python"
if exist "%DIR%\servers\fastapi\.venv\Scripts\python.exe" (
    set "PYTHON_CMD=%DIR%\servers\fastapi\.venv\Scripts\python.exe"
)

echo Starting FastAPI Backend...
start "Presenton FastAPI" /min cmd /c "cd /d %DIR%\servers\fastapi && %PYTHON_CMD% server.py --port 8000 --reload false"

echo Starting Next.js Frontend...
start "Presenton Next.js" /min cmd /c "cd /d %DIR%\servers\nextjs && npm run dev -- -H 127.0.0.1 -p 3000"

echo.
echo ==========================================
echo Presenton is running!
echo Backend:  http://127.0.0.1:8000
echo Frontend: http://localhost:3000
echo ==========================================
echo Opening browser...
timeout /t 3 /nobreak >nul
start http://localhost:3000

echo.
echo Press any key to stop all Presenton servers...
pause >nul

echo Stopping Presenton servers...
taskkill /FI "WINDOWTITLE eq Presenton FastAPI*" /F /T >nul 2>&1
taskkill /FI "WINDOWTITLE eq Presenton Next.js*" /F /T >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find ":8000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find ":3000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
echo Presenton stopped.
