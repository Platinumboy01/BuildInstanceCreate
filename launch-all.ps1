# ============================================================
#  Launch BlueStacks instances (one click)
#  Reads instance list + orientation from bluestacks.conf.
#
#  Usage:
#    launch-all.ps1                       -> launches ALL (portrait + landscape)
#    launch-all.ps1 portrait              -> only Portrait instances
#    launch-all.ps1 landscape             -> only Landscape instances
#    launch-all.ps1 -Only all -Count 4    -> only the first 4 instances
#    (Count 0 = no limit / launch all of the selected orientation)
# ============================================================
param([string]$Only = "all", [int]$Count = 0)
. (Join-Path $PSScriptRoot "config.ps1")

Write-Host "=== Pongz : Launch BlueStacks instances ===" -ForegroundColor Cyan

if (-not (Test-Path $HDPlayer)) {
    Write-Host "ERROR: HD-Player.exe not found at $HDPlayer" -ForegroundColor Red
    return
}

$instances = Get-BstInstances
if ($instances.Count -eq 0) {
    Write-Host "No instances found. Create some in the Multi-Instance Manager first." -ForegroundColor Yellow
    return
}

# Filter by orientation if requested
$filter = $Only.Trim().ToLower()
if ($filter -eq "portrait")  { $instances = $instances | Where-Object { $_.Orientation -eq "Portrait" } }
elseif ($filter -eq "landscape") { $instances = $instances | Where-Object { $_.Orientation -eq "Landscape" } }

if ($instances.Count -eq 0) {
    Write-Host "No '$filter' instances found." -ForegroundColor Yellow
    return
}

# Limit to the first N if a count was requested (0 = launch all).
if ($Count -gt 0 -and $instances.Count -gt $Count) {
    Write-Host ("Limiting to the first {0} of {1} instance(s)." -f $Count, $instances.Count) -ForegroundColor DarkGray
    $instances = $instances | Select-Object -First $Count
}

$nP = ($instances | Where-Object { $_.Orientation -eq "Portrait" }).Count
$nL = ($instances | Where-Object { $_.Orientation -eq "Landscape" }).Count
Write-Host ("Launching {0} instance(s):  {1} Landscape + {2} Portrait" -f $instances.Count, $nL, $nP) -ForegroundColor Green

foreach ($inst in $instances) {
    Write-Host (">> Starting '{0}'  [{1} {2}x{3}]..." -f $inst.Name, $inst.Orientation, $inst.Width, $inst.Height) -ForegroundColor White

    $args = @("--instance", $inst.Name)
    if ($LaunchGameOnStart) {
        $args += @("--cmd", "launchApp", "--package", $PackageName)
    }

    Start-Process -FilePath $HDPlayer -ArgumentList $args | Out-Null

    if ($StartStaggerSeconds -gt 0) {
        Start-Sleep -Seconds $StartStaggerSeconds
    }
}

Write-Host "Done. All requested instances launched." -ForegroundColor Cyan

# Resize + tile the windows so they're small and neatly spaced
if ($ArrangeWindows) {
    Write-Host ("Waiting {0}s for windows to appear, then arranging..." -f $ArrangeDelaySeconds) -ForegroundColor DarkGray
    Start-Sleep -Seconds $ArrangeDelaySeconds
    & (Join-Path $PSScriptRoot "arrange-windows.ps1")
}
