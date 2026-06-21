# ============================================================
#  Compile the Pongz Launcher GUI (src\PongzLauncher.cs) into
#  Pongz-Launcher.exe using the in-box .NET Framework C#
#  compiler (csc.exe). No installs, no internet needed.
#
#  Run this once (or after editing the GUI). Then everyone just
#  double-clicks Pongz-Launcher.exe - no need to rebuild.
# ============================================================
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

Write-Host "=== Building Pongz-Launcher.exe ===" -ForegroundColor Cyan

$src = Join-Path $here "src\PongzLauncher.cs"
$out = Join-Path $here "Pongz-Launcher.exe"

if (-not (Test-Path $src)) {
    Write-Host "ERROR: source not found: $src" -ForegroundColor Red
    return
}

# Find csc.exe (prefer 64-bit). Both ship with Windows .NET Framework 4.x.
$cscCandidates = @(
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
$csc = $cscCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) {
    Write-Host "ERROR: csc.exe not found. Looked at:" -ForegroundColor Red
    $cscCandidates | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
    return
}
Write-Host "Compiler: $csc" -ForegroundColor DarkGray

# Close the app if it's currently running so the .exe isn't locked.
Get-Process -Name "Pongz-Launcher" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# Embed the app icon if present (regenerate it with make-icon.ps1).
$icon = Join-Path $here "app.ico"
$iconArg = if (Test-Path $icon) { "/win32icon:$icon" } else { "" }
if ($iconArg) { Write-Host "Icon:     $icon" -ForegroundColor DarkGray }
else { Write-Host "Icon:     (none - run make-icon.ps1 to create app.ico)" -ForegroundColor DarkGray }

# /target:winexe = GUI app (no console window pops up behind it).
& $csc `
    /nologo `
    /target:winexe `
    /out:"$out" `
    /reference:System.dll `
    /reference:System.Drawing.dll `
    /reference:System.Windows.Forms.dll `
    $iconArg `
    "$src"

if ($LASTEXITCODE -eq 0 -and (Test-Path $out)) {
    Write-Host ""
    Write-Host "SUCCESS -> $out" -ForegroundColor Green
    Write-Host "Double-click Pongz-Launcher.exe to use it." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "BUILD FAILED (see errors above)." -ForegroundColor Red
}
