# ============================================================
#  Install the newest APK build onto ALL running instances.
#  Discovers LIVE devices straight from adb (does not trust the
#  config ports, which can be stale).
# ============================================================
. (Join-Path $PSScriptRoot "config.ps1")

Write-Host "=== Pongz : Install build to all instances ===" -ForegroundColor Cyan

if (-not (Test-Path $HDAdb)) {
    Write-Host "ERROR: HD-Adb.exe not found at $HDAdb" -ForegroundColor Red
    return
}

$apk = Resolve-ApkPath
if (-not $apk) {
    Write-Host "ERROR: No .apk found in: $($ApkSearchDirs -join '; ')" -ForegroundColor Red
    return
}
Write-Host "APK: $apk" -ForegroundColor Green

# --- 1. Restart the adb server for a clean slate ---
Write-Host "Restarting adb server..." -ForegroundColor DarkGray
& $HDAdb kill-server  2>&1 | Out-Null
& $HDAdb start-server 2>&1 | Out-Null

# --- 2. Find every localhost port BlueStacks is actually listening on ---
$ports = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalAddress -in @("127.0.0.1","0.0.0.0") -and $_.LocalPort -ge 5550 -and $_.LocalPort -le 5700 } |
    Select-Object -ExpandProperty LocalPort -Unique

if (-not $ports) {
    Write-Host "No BlueStacks adb ports are listening. Are the instances booted?" -ForegroundColor Yellow
    return
}

# --- 3. Connect to each candidate port ---
foreach ($p in $ports) { & $HDAdb connect "127.0.0.1:$p" 2>&1 | Out-Null }
Start-Sleep -Seconds 2

# --- 4. Keep only the ONLINE 127.0.0.1 devices (skip offline / emulator-*) ---
$devLines = & $HDAdb devices
$targets = @()
foreach ($line in $devLines) {
    if ($line -match '^(127\.0\.0\.1:\d+)\s+device$') { $targets += $matches[1] }
}

if ($targets.Count -eq 0) {
    Write-Host "No online instances found. Make sure each instance is fully booted (home screen)." -ForegroundColor Yellow
    Write-Host "adb saw:" -ForegroundColor DarkGray
    $devLines | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
    return
}

Write-Host ("Online instances: {0}" -f ($targets -join ", ")) -ForegroundColor Green

# --- 5. Install to each ---
$ok = 0; $fail = 0
foreach ($t in $targets) {
    Write-Host ""
    Write-Host (">> {0}" -f $t) -ForegroundColor White
    $out = & $HDAdb -s $t install -r -g "$apk" 2>&1
    if ($out -match "Success") {
        Write-Host "   Installed OK" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "   FAILED:" -ForegroundColor Red
        $out | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
        $fail++
    }
}

Write-Host ""
Write-Host ("Done. {0} succeeded, {1} failed." -f $ok, $fail) -ForegroundColor Cyan
