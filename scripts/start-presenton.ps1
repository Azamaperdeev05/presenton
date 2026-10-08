# Presenton PowerShell Startup Script (Windows / Cross-platform PowerShell)
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Resolve-Path (Join-Path $scriptDir "..")).Path

$env:APP_DATA_DIRECTORY = Join-Path $rootDir "app_data"
$env:USER_CONFIG_PATH = Join-Path $env:APP_DATA_DIRECTORY "userConfig.json"
$env:FAST_API_INTERNAL_URL = "http://127.0.0.1:8000"
$env:NEXT_PUBLIC_FAST_API = "http://127.0.0.1:8000"
$env:NEXT_PUBLIC_URL = "http://localhost:3000"
$env:MIGRATE_DATABASE_ON_STARTUP = "true"
$env:CAN_CHANGE_KEYS = "true"
$env:DISABLE_AUTH = "true"
$env:NEXT_PUBLIC_DISABLE_AUTH = "true"
$env:EXPORT_PACKAGE_ROOT = Join-Path $rootDir "presentation-export"
$env:PRESENTON_APP_ROOT = $rootDir

# Chrome/Edge Detection
$chromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
)
foreach ($p in $chromePaths) {
    if (Test-Path $p) {
        $env:PUPPETEER_EXECUTABLE_PATH = $p
        break
    }
}

# Directories
$dirs = @("exports", "images", "uploads", "fonts", "templates", "pptx-to-html", "pptx-to-json")
foreach ($d in $dirs) {
    $target = Join-Path $env:APP_DATA_DIRECTORY $d
    if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
}
if (-not (Test-Path $env:USER_CONFIG_PATH)) { Set-Content -Path $env:USER_CONFIG_PATH -Value "{}" }

# Check ports
$port8000Busy = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
$port3000Busy = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue

if ($port8000Busy -and $port3000Busy) {
    Write-Host "Presenton already running."
    Start-Process "http://localhost:3000"
    exit 0
}

Write-Host "Starting Presenton backend and frontend..."

$fastapiDir = Join-Path $rootDir "servers/fastapi"
$nextjsDir = Join-Path $rootDir "servers/nextjs"

$pythonCmd = "python"
$venvPython = Join-Path $fastapiDir ".venv/Scripts/python.exe"
if (Test-Path $venvPython) { $pythonCmd = $venvPython }

Start-Process -FilePath $pythonCmd -ArgumentList "server.py --port 8000 --reload false" -WorkingDirectory $fastapiDir -WindowStyle Minimized
Start-Process -FilePath "npm" -ArgumentList "run dev -- -H 127.0.0.1 -p 3000" -WorkingDirectory $nextjsDir -WindowStyle Minimized

Write-Host "Waiting for Presenton to be ready..."
Start-Sleep -Seconds 3

Start-Process "http://localhost:3000"
Write-Host "Presenton is running at http://localhost:3000"
