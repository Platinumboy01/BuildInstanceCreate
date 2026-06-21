# ============================================================
#  Pongz BlueStacks Tools - shared config
#  Edit values here; the other scripts read from this file.
# ============================================================

# This folder (portable - everything is relative to it)
$Global:ToolsDir = $PSScriptRoot

# --- BlueStacks (auto-detected; works on any PC with a standard install) ---
$Global:BlueStacksCandidates = @(
    "C:\Program Files\BlueStacks_nxt",
    "C:\Program Files (x86)\BlueStacks_nxt",
    "C:\Program Files\BlueStacks_msi5",
    "C:\Program Files\BlueStacks"
)
$Global:BlueStacksDir = ($BlueStacksCandidates | Where-Object { Test-Path (Join-Path $_ "HD-Player.exe") } | Select-Object -First 1)
if (-not $BlueStacksDir) { $Global:BlueStacksDir = "C:\Program Files\BlueStacks_nxt" }
$Global:HDPlayer = Join-Path $BlueStacksDir "HD-Player.exe"

$Global:ConfCandidates = @(
    "C:\ProgramData\BlueStacks_nxt\bluestacks.conf",
    "$env:USERPROFILE\Documents\BlueStacks_nxt\bluestacks.conf"
)
$Global:BlueStacksConf = ($ConfCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
if (-not $BlueStacksConf) { $Global:BlueStacksConf = "C:\ProgramData\BlueStacks_nxt\bluestacks.conf" }

# IMPORTANT: BlueStacks' own HD-Adb.exe is v1.0.36 (2016) - too old; installs
# fail with "connect error for write: closed". We use the MODERN adb bundled
# inside this folder (platform-tools\adb.exe) so it works on any PC.
$Global:AdbCandidates = @(
    (Join-Path $ToolsDir "platform-tools\adb.exe"),
    "C:\Program Files\Unity\Hub\Editor\6000.3.10f1\Editor\Data\PlaybackEngines\AndroidPlayer\SDK\platform-tools\adb.exe",
    "C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe",
    (Join-Path $BlueStacksDir "HD-Adb.exe")
)
$Global:HDAdb = ($AdbCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1)

# --- Game ---
$Global:PackageName   = "com.pixelstackstudios.pongz"

# Build folder - the Builds subfolder INSIDE this toolkit (portable).
# Put your .apk in there and it gets picked up automatically.
$Global:ApkSearchDirs = @(
    (Join-Path $ToolsDir "Builds")
)

# Optional: hard-code a specific APK to install instead of auto-picking newest.
# Leave empty ("") to auto-pick the newest from $ApkSearchDirs.
$Global:ApkExplicitPath = ""

# Set to $true to auto-launch the game after each instance boots.
$Global:LaunchGameOnStart = $true

# Seconds to wait between starting each instance (avoids CPU spike).
$Global:StartStaggerSeconds = 6

# --- Window arrangement (small + tiled grid) ---
# Set to $true to auto-resize + tile windows after launching.
$Global:ArrangeWindows = $true

# Window sizes in pixels (outer window). Tweak to taste.
$Global:PortraitW  = 280
$Global:PortraitH  = 500
$Global:LandscapeW = 480
$Global:LandscapeH = 290

# Gap between windows and margin from screen edge (pixels).
$Global:WindowGap    = 8
$Global:ScreenMargin = 8

# Seconds to wait after launching before arranging (let windows appear).
$Global:ArrangeDelaySeconds = 8

# ============================================================
#  Helper: read all instances + adb ports from bluestacks.conf
#  Returns array of [pscustomobject]@{ Name; Port }
# ============================================================
function Get-BstInstances {
    if (-not (Test-Path $BlueStacksConf)) {
        Write-Host "ERROR: config not found: $BlueStacksConf" -ForegroundColor Red
        return @()
    }
    $lines = Get-Content $BlueStacksConf

    # Base adb ports:  bst.instance.<NAME>.adb_port="5555"
    $base = @{}
    foreach ($l in $lines) {
        if ($l -match '^bst\.instance\.([^.]+)\.adb_port="(\d+)"') {
            $base[$matches[1]] = $matches[2]
        }
    }
    # Live/status ports override base when present.
    foreach ($l in $lines) {
        if ($l -match '^bst\.instance\.([^.]+)\.status\.adb_port="(\d+)"') {
            if ($matches[2] -ne "0") { $base[$matches[1]] = $matches[2] }
        }
    }

    # Resolution -> orientation (width >= height = Landscape, else Portrait)
    $w = @{}; $h = @{}; $dn = @{}
    foreach ($l in $lines) {
        if ($l -match '^bst\.instance\.([^.]+)\.fb_width="(\d+)"')  { $w[$matches[1]] = [int]$matches[2] }
        if ($l -match '^bst\.instance\.([^.]+)\.fb_height="(\d+)"') { $h[$matches[1]] = [int]$matches[2] }
        if ($l -match '^bst\.instance\.([^.]+)\.display_name="([^"]*)"') { $dn[$matches[1]] = $matches[2] }
    }

    $result = @()
    foreach ($name in $base.Keys) {
        $ww = $w[$name]; $hh = $h[$name]
        $orient = if ($ww -and $hh) { if ($ww -ge $hh) { "Landscape" } else { "Portrait" } } else { "Unknown" }
        $title = if ($dn.ContainsKey($name)) { $dn[$name] } else { "" }
        $result += [pscustomobject]@{ Name = $name; Port = $base[$name]; Orientation = $orient; Width = $ww; Height = $hh; Title = $title }
    }
    return ($result | Sort-Object Name)
}

function Resolve-ApkPath {
    if ($ApkExplicitPath -and (Test-Path $ApkExplicitPath)) { return $ApkExplicitPath }
    $found = @()
    foreach ($d in $ApkSearchDirs) {
        if (Test-Path $d) {
            $found += Get-ChildItem -Path $d -Filter *.apk -Recurse -ErrorAction SilentlyContinue
        }
    }
    if ($found.Count -eq 0) { return $null }
    return ($found | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}
