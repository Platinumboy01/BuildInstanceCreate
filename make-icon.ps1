# ============================================================
#  Generate app.ico for the Pongz Launcher - a little "pong"
#  graphic (two paddles + a ball on a dark rounded tile).
#  Builds a proper multi-size .ico (PNG-compressed entries) so
#  it stays crisp at every icon size. No art files needed.
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot "app.ico"

function New-PongPng([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::Transparent)

    $s = $size / 256.0   # scale factor (art designed at 256)

    # --- rounded dark background tile ---
    $pad    = [int](10 * $s)
    $radius = [int](48 * $s)
    $rect   = New-Object System.Drawing.Rectangle($pad, $pad, ($size - 2*$pad), ($size - 2*$pad))
    $path   = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
    $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()

    $c1 = [System.Drawing.Color]::FromArgb(255, 38, 50, 78)
    $c2 = [System.Drawing.Color]::FromArgb(255, 24, 28, 40)
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 60)
    $g.FillPath($grad, $path)

    # --- center dashed net ---
    $netPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 255, 255, 255), [single](6 * $s))
    $netPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    $g.DrawLine($netPen, [single]($size/2), [single]($pad + 24*$s), [single]($size/2), [single]($size - $pad - 24*$s))

    # --- paddles ---
    $white  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 235, 240, 248))
    $accent = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 70, 150, 245))
    $pw = [int](20 * $s); $ph = [int](78 * $s)
    $g.FillRectangle($accent, [int](56*$s), [int]($size/2 - $ph*0.7), $pw, $ph)         # left paddle
    $g.FillRectangle($white,  [int]($size - 56*$s - $pw), [int]($size/2 - $ph*0.3), $pw, $ph) # right paddle

    # --- ball ---
    $bd = [int](30 * $s)
    $g.FillEllipse($white, [int]($size/2 - $bd/2 - 6*$s), [int]($size/2 - $bd/2 - 18*$s), $bd, $bd)

    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    return ,$ms.ToArray()
}

$sizes = @(16, 32, 48, 64, 128, 256)
$pngs  = @{}
foreach ($sz in $sizes) { $pngs[$sz] = New-PongPng $sz }

# --- assemble .ico (ICONDIR + entries + PNG payloads) ---
$fs = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($fs)

$bw.Write([uint16]0)              # reserved
$bw.Write([uint16]1)              # type = icon
$bw.Write([uint16]$sizes.Count)   # image count

$offset = 6 + (16 * $sizes.Count) # data starts after dir + entries
foreach ($sz in $sizes) {
    $data = $pngs[$sz]
    $dim  = if ($sz -ge 256) { 0 } else { $sz }   # 256 is encoded as 0
    $bw.Write([byte]$dim)          # width
    $bw.Write([byte]$dim)          # height
    $bw.Write([byte]0)             # palette count
    $bw.Write([byte]0)             # reserved
    $bw.Write([uint16]1)           # color planes
    $bw.Write([uint16]32)          # bits per pixel
    $bw.Write([uint32]$data.Length)
    $bw.Write([uint32]$offset)
    $offset += $data.Length
}
foreach ($sz in $sizes) { $bw.Write($pngs[$sz]) }

$bw.Flush()
[System.IO.File]::WriteAllBytes($out, $fs.ToArray())
$bw.Dispose(); $fs.Dispose()

Write-Host "Created icon: $out  ($((Get-Item $out).Length) bytes, sizes: $($sizes -join ','))" -ForegroundColor Green
