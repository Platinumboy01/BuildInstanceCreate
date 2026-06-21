# ============================================================
#  Enable ADB in BlueStacks (one-time setup on a new PC).
#  Closes BlueStacks, flips the ADB flag in bluestacks.conf
#  (writing WITHOUT a BOM so the file stays valid), backs up
#  the original, then you relaunch.
# ============================================================
. (Join-Path $PSScriptRoot "config.ps1")

Write-Host "=== Pongz : Enable ADB in BlueStacks ===" -ForegroundColor Cyan

if (-not (Test-Path $BlueStacksConf)) {
    Write-Host "ERROR: bluestacks.conf not found. Is BlueStacks installed?" -ForegroundColor Red
    Write-Host "Looked at: $($ConfCandidates -join '; ')" -ForegroundColor DarkGray
    return
}
Write-Host "Config: $BlueStacksConf" -ForegroundColor DarkGray

# 1. Close all BlueStacks processes (config only applies when closed)
Write-Host "Closing BlueStacks (so the change can be saved)..." -ForegroundColor Yellow
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match 'BlueStacks|HD-Player|HD-Adb|BstkSVC|Bstk|HD-MultiInstance' } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 4

# 2. Backup once
$bak = "$BlueStacksConf.bak_pongz"
if (-not (Test-Path $bak)) { Copy-Item $BlueStacksConf $bak -Force; Write-Host "Backup saved: $bak" -ForegroundColor DarkGray }

# 3. Read, flip flags, write back WITHOUT BOM
$text = [System.IO.File]::ReadAllText($BlueStacksConf)
if ($text -match 'bst\.enable_adb_access=') {
    $text = $text -replace 'bst\.enable_adb_access="0"','bst.enable_adb_access="1"'
    $text = $text -replace 'bst\.enable_adb_remote_access="0"','bst.enable_adb_remote_access="1"'
} else {
    # key missing - append it
    $text = $text.TrimEnd() + "`r`nbst.enable_adb_access=`"1`"`r`nbst.enable_adb_remote_access=`"1`"`r`n"
}
$enc = New-Object System.Text.UTF8Encoding($false)   # $false = NO BOM
[System.IO.File]::WriteAllText($BlueStacksConf, $text, $enc)

# 4. Verify
$check = Get-Content $BlueStacksConf | Select-String "enable_adb_access"
Write-Host "ADB setting is now: $check" -ForegroundColor Green
Write-Host ""
Write-Host "DONE. ADB is enabled. You can now use Launch + Install." -ForegroundColor Cyan
