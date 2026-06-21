# ============================================================
#  Resize BlueStacks windows small and tile them in a grid.
#  Portrait -> tall/narrow, Landscape -> wide/short.
#  Can be run standalone any time, or called by launch-all.ps1.
# ============================================================
. (Join-Path $PSScriptRoot "config.ps1")

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win {
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int t,bool repaint);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int cmd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
$SW_RESTORE = 9

# Screen working area (excludes taskbar)
Add-Type -AssemblyName System.Windows.Forms
$area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$screenW = $area.Width
$screenH = $area.Height

# Map window TITLE -> instance + orientation (CommandLine isn't readable without admin)
$instByTitle = @{}
Get-BstInstances | ForEach-Object { if ($_.Title) { $instByTitle[$_.Title] = $_ } }

$windows = @()
foreach ($gp in (Get-Process -Name "HD-Player" -ErrorAction SilentlyContinue)) {
    if ($gp.MainWindowHandle -eq 0) { continue }
    $title = $gp.MainWindowTitle
    $match = $instByTitle[$title]
    $orient = if ($match) { $match.Orientation } else { "Landscape" }
    $name   = if ($match) { $match.Name } else { $title }
    $windows += [pscustomobject]@{
        Handle = $gp.MainWindowHandle
        Name   = $name
        Orient = $orient
    }
}

if ($windows.Count -eq 0) {
    Write-Host "No BlueStacks windows found to arrange." -ForegroundColor Yellow
    return
}

# Sort: landscape first then portrait, so similar sizes group together
$windows = $windows | Sort-Object @{e={$_.Orient}}, Name

Write-Host ("Arranging {0} window(s) (screen {1}x{2})..." -f $windows.Count, $screenW, $screenH) -ForegroundColor Cyan

# Flow layout: left-to-right, wrap to next row when out of width
$x = $ScreenMargin
$y = $ScreenMargin
$rowH = 0
foreach ($win in $windows) {
    if ($win.Orient -eq "Portrait") { $w = $PortraitW;  $h = $PortraitH }
    else                            { $w = $LandscapeW; $h = $LandscapeH }

    # wrap to next row if it would overflow the screen width
    if (($x + $w) -gt ($screenW - $ScreenMargin)) {
        $x = $ScreenMargin
        $y = $y + $rowH + $WindowGap
        $rowH = 0
    }
    # if we run off the bottom, start stacking from top again (cascade slightly)
    if (($y + $h) -gt ($screenH - $ScreenMargin)) {
        $y = $ScreenMargin
    }

    [Win]::ShowWindow($win.Handle, $SW_RESTORE) | Out-Null
    [Win]::MoveWindow($win.Handle, $x, $y, $w, $h, $true) | Out-Null
    Write-Host ("  {0,-12} [{1}] -> {2},{3} {4}x{5}" -f $win.Name,$win.Orient,$x,$y,$w,$h) -ForegroundColor White

    $x = $x + $w + $WindowGap
    if ($h -gt $rowH) { $rowH = $h }
}

Write-Host "Done arranging." -ForegroundColor Cyan
