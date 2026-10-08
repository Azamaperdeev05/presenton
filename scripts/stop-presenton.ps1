# Presenton PowerShell Stop Script
$ErrorActionPreference = "SilentlyContinue"

Write-Host "Stopping Presenton..."

$ports = @(8000, 3000)
foreach ($port in $ports) {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen
    foreach ($c in $conns) {
        if ($c.OwningProcess) {
            Write-Host "Killing process on port $port (PID: $($c.OwningProcess))..."
            Stop-Process -Id $c.OwningProcess -Force
        }
    }
}

Get-Process -Name "python", "node" | Where-Object { $_.MainWindowTitle -match "Presenton" } | Stop-Process -Force

Write-Host "Presenton stopped."
