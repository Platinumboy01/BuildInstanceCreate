# ============================================================
#  Open (launch) the Pongz game on ALL running instances.
#  Uses live adb discovery, then launches the app via monkey.
# ============================================================
. (Join-Path $PSScriptRoot "config.ps1")

Write-Host "=== Pongz : Open game on all instances ===" -ForegroundColor Cyan

if (-not (Test-Path $HDAdb)) {
    Write-Host "ERROR: adb not found at $HDAdb" -ForegroundColor Red
    return
}

# --- 1. Restart adb server for a clean slate ---
Write-Host "Restarting adb server..." -ForegroundColor DarkGray
& $HDAdb kill-server  2>&1 | Out-Null
& $HDAdb start-server 2>&1 | Out-Null

# --- 2. Find listening BlueStacks ports ---
$ports = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalAddress -in @("127.0.0.1","0.0.0.0") -and $_.LocalPort -ge 5550 -and $_.LocalPort -le 5700 } |
    Select-Object -ExpandProperty LocalPort -Unique

if (-not $ports) {
    Write-Host "No instances are running. Launch them first." -ForegroundColor Yellow
    return
}

# --- 3. Connect to each ---
foreach ($p in $ports) { & $HDAdb connect "127.0.0.1:$p" 2>&1 | Out-Null }
Start-Sleep -Seconds 2

# --- 4. Keep only ONLINE 127.0.0.1 devices ---
$devLines = & $HDAdb devices
$targets = @()
foreach ($line in $devLines) {
    if ($line -match '^(127\.0\.0\.1:\d+)\s+device$') { $targets += $matches[1] }
}

if ($targets.Count -eq 0) {
    Write-Host "No online instances found. Make sure they are fully booted." -ForegroundColor Yellow
    return
}

Write-Host ("Online instances: {0}" -f ($targets -join ", ")) -ForegroundColor Green

# --- 5. Launch the app on each ---
$ok = 0; $fail = 0
foreach ($t in $targets) {
    Write-Host ""
    Write-Host (">> {0}" -f $t) -ForegroundColor White
    $out = & $HDAdb -s $t shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 2>&1
    if ($out -match "Events injected: 1" -or $LASTEXITCODE -eq 0) {
        Write-Host "   Game launched" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "   FAILED (is the game installed on this instance?):" -ForegroundColor Red
        $out | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
        $fail++
    }
}

Write-Host ""
Write-Host ("Done. {0} launched, {1} failed." -f $ok, $fail) -ForegroundColor Cyan
