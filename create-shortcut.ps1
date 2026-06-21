# ============================================================
#  Put a "Pongz Launcher" shortcut on the Desktop so the user
#  never has to open this folder. Points at Pongz-Launcher.exe
#  (and uses the app icon). Portable: paths are resolved from
#  wherever this folder currently lives.
# ============================================================
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

Write-Host "=== Pongz : Create Desktop shortcut ===" -ForegroundColor Cyan

$exe = Join-Path $here "Pongz-Launcher.exe"
if (-not (Test-Path $exe)) {
    Write-Host "Pongz-Launcher.exe not found. Building it first..." -ForegroundColor Yellow
    & (Join-Path $here "build-launcher.ps1")
}
if (-not (Test-Path $exe)) {
    Write-Host "ERROR: could not find or build Pongz-Launcher.exe" -ForegroundColor Red
    return
}

$icon    = Join-Path $here "app.ico"
$iconLoc = if (Test-Path $icon) { $icon } else { $exe }   # fall back to exe's own icon

$desktop = [Environment]::GetFolderPath("Desktop")
$lnkPath = Join-Path $desktop "Pongz Launcher.lnk"

$shell = New-Object -ComObject WScript.Shell
$lnk   = $shell.CreateShortcut($lnkPath)
$lnk.TargetPath       = $exe
$lnk.WorkingDirectory = $here
$lnk.IconLocation     = $iconLoc
$lnk.Description       = "Pongz - BlueStacks Multi-Instance Test Kit"
$lnk.Save()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null

if (Test-Path $lnkPath) {
    Write-Host "SUCCESS -> $lnkPath" -ForegroundColor Green
    Write-Host "A 'Pongz Launcher' icon is now on the Desktop." -ForegroundColor Cyan
} else {
    Write-Host "ERROR: shortcut was not created." -ForegroundColor Red
}
