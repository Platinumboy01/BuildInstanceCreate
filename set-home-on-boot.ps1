# ============================================================
#  Make instances open on the Android HOME screen instead of the
#  BlueStacks App Center (store). Flips bst.launch_store_on_boot
#  in bluestacks.conf (0 = home screen, 1 = store).
#
#  Like ADB, this only sticks while BlueStacks is closed, so we
#  close it first, edit the file (BOM-free, with a backup), done.
#
#  Usage:
#    set-home-on-boot.ps1            -> home screen on boot (default)
#    set-home-on-boot.ps1 store      -> restore the App Center store
# ============================================================
param([string]$Mode = "home")
. (Join-Path $PSScriptRoot "config.ps1")

$wantStore = ($Mode.Trim().ToLower() -eq "store")
$value     = if ($wantStore) { "1" } else { "0" }
$label     = if ($wantStore) { "App Center (store)" } else { "Android home screen" }

Write-Host "=== Pongz : Set boot screen -> $label ===" -ForegroundColor Cyan

if (-not (Test-Path $BlueStacksConf)) {
    Write-Host "ERROR: bluestacks.conf not found. Is BlueStacks installed?" -ForegroundColor Red
    Write-Host "Looked at: $($ConfCandidates -join '; ')" -ForegroundColor DarkGray
    return
}
Write-Host "Config: $BlueStacksConf" -ForegroundColor DarkGray

# 1. Close BlueStacks so the change can be saved (conf is rewritten on exit).
Write-Host "Closing BlueStacks (so the change can be saved)..." -ForegroundColor Yellow
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match 'BlueStacks|HD-Player|HD-Adb|BstkSVC|Bstk|HD-MultiInstance' } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 4

# 2. Backup once.
$bak = "$BlueStacksConf.bak_pongz"
if (-not (Test-Path $bak)) { Copy-Item $BlueStacksConf $bak -Force; Write-Host "Backup saved: $bak" -ForegroundColor DarkGray }

# 3. Read, set the flag, write back WITHOUT BOM.
$text = [System.IO.File]::ReadAllText($BlueStacksConf)
if ($text -match 'bst\.launch_store_on_boot=') {
    $text = $text -replace 'bst\.launch_store_on_boot="[01]"', ('bst.launch_store_on_boot="' + $value + '"')
} else {
    $text = $text.TrimEnd() + "`r`nbst.launch_store_on_boot=`"$value`"`r`n"
}
$enc = New-Object System.Text.UTF8Encoding($false)   # $false = NO BOM
[System.IO.File]::WriteAllText($BlueStacksConf, $text, $enc)

# 4. Verify.
$check = Get-Content $BlueStacksConf | Select-String "launch_store_on_boot"
Write-Host "Setting is now: $check" -ForegroundColor Green
Write-Host ""
Write-Host "DONE. Next time you launch, instances open on the $label." -ForegroundColor Cyan
