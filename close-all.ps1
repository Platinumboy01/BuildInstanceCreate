# ============================================================
#  Close ALL running BlueStacks instances at once.
#  Each open instance window is an HD-Player.exe process, so we
#  stop those. The BlueStacks background service / Multi-Instance
#  Manager are left alone, so BlueStacks itself stays healthy.
# ============================================================
. (Join-Path $PSScriptRoot "config.ps1")

Write-Host "=== Pongz : Close all BlueStacks instances ===" -ForegroundColor Cyan

$procs = Get-Process -Name "HD-Player" -ErrorAction SilentlyContinue
if (-not $procs -or $procs.Count -eq 0) {
    Write-Host "No running instances found (nothing to close)." -ForegroundColor Yellow
    return
}

Write-Host ("Closing {0} instance window(s)..." -f $procs.Count) -ForegroundColor Green

$closed = 0
foreach ($p in $procs) {
    $label = if ($p.MainWindowTitle) { $p.MainWindowTitle } else { "instance (pid $($p.Id))" }
    Write-Host (">> {0}" -f $label) -ForegroundColor White

    # Try a polite window close first, then force if it lingers.
    $p.CloseMainWindow() | Out-Null
    if (-not $p.WaitForExit(4000)) {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
    $closed++
}

Write-Host ""
Write-Host ("Done. {0} instance(s) closed." -f $closed) -ForegroundColor Cyan
