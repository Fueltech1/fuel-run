Add-Type -AssemblyName System.Drawing

function New-RoundedRectPath {
    param($x, $y, $w, $h, $r)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($x, $y, $r*2, $r*2, 180, 90)
    $path.AddArc($x + $w - $r*2, $y, $r*2, $r*2, 270, 90)
    $path.AddArc($x + $w - $r*2, $y + $h - $r*2, $r*2, $r*2, 0, 90)
    $path.AddArc($x, $y + $h - $r*2, $r*2, $r*2, 90, 90)
    $path.CloseFigure()
    return $path
}

$W = 1024; $H = 500
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# background gradient
$rectF = New-Object System.Drawing.RectangleF 0,0,$W,$H
$colTop = [System.Drawing.Color]::FromArgb(255,21,24,51)
$colBottom = [System.Drawing.Color]::FromArgb(255,44,32,73)
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rectF, $colTop, $colBottom, 60.0)
$g.FillRectangle($bgBrush, 0, 0, $W, $H)
$bgBrush.Dispose()

# perspective "road" converging toward a vanishing point on the right, for motion/energy
$roadBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90,43,47,60))
$roadPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$roadPath.AddPolygon(@(
  New-Object System.Drawing.PointF(650,$H)
  New-Object System.Drawing.PointF(1400,$H)
  New-Object System.Drawing.PointF(980,-40)
  New-Object System.Drawing.PointF(760,-40)
))
$g.FillPath($roadBrush, $roadPath)
$roadBrush.Dispose()

# lane dash streaks for speed feel
$dashPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160,238,231,214)), 10
for($i=0; $i -lt 5; $i++){
  $yy = 60 + $i*95
  $x1 = 900 + $i*8
  $g.DrawLine($dashPen, $x1, $yy, $x1+70, $yy)
}
$dashPen.Dispose()

# car + fuel glyph, reused composition, placed right-of-center
function Draw-Glyph {
    param($g, $cx, $cy, $scale)
    $u = $scale / 200.0

    $roadW = 96*$u
    $rp = New-RoundedRectPath ($cx-$roadW/2) ($cy-100*$u) $roadW (200*$u) (10*$u)
    $rb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,43,47,60))
    $g.FillPath($rb, $rp); $rb.Dispose()

    $lanePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230,238,231,214)), (6*$u)
    $lanePen.DashPattern = @(3.0,2.4)
    $g.DrawLine($lanePen, $cx, $cy-95*$u, $cx, $cy+95*$u)
    $lanePen.Dispose()

    $carW = 66*$u; $carH = 108*$u
    $carX = $cx - $carW/2; $carY = $cy - $carH/2 + 6*$u
    $shadowPath = New-RoundedRectPath ($carX+4*$u) ($carY+6*$u) $carW $carH (16*$u)
    $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70,0,0,0))
    $g.FillPath($shadowBrush, $shadowPath); $shadowBrush.Dispose()
    $carPath = New-RoundedRectPath $carX $carY $carW $carH (16*$u)
    $carBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,63,199,193))
    $g.FillPath($carBrush, $carPath); $carBrush.Dispose()

    $wsW = $carW - 20*$u; $wsH = $carH*0.30
    $wsX = $carX + 10*$u; $wsY = $carY + $carH*0.16
    $wsPath = New-RoundedRectPath $wsX $wsY $wsW $wsH (8*$u)
    $wsBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,37,147,142))
    $g.FillPath($wsBrush, $wsPath); $wsBrush.Dispose()

    $lf = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,247,214))
    $g.FillRectangle($lf, ($carX+6*$u), ($carY+4*$u), (12*$u), (6*$u))
    $g.FillRectangle($lf, ($carX+$carW-18*$u), ($carY+4*$u), (12*$u), (6*$u))
    $lf.Dispose()
    $lr = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,95,77))
    $g.FillRectangle($lr, ($carX+6*$u), ($carY+$carH-10*$u), (12*$u), (6*$u))
    $g.FillRectangle($lr, ($carX+$carW-18*$u), ($carY+$carH-10*$u), (12*$u), (6*$u))
    $lr.Dispose()

    $dropCx = $cx + 62*$u; $dropCy = $cy + 78*$u; $dropR = 30*$u
    $ds = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70,0,0,0))
    $g.FillEllipse($ds, ($dropCx-$dropR+3*$u), ($dropCy-$dropR+4*$u), ($dropR*2), ($dropR*2)); $ds.Dispose()
    $db = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,201,60))
    $g.FillEllipse($db, ($dropCx-$dropR), ($dropCy-$dropR), ($dropR*2), ($dropR*2)); $db.Dispose()
    $drp = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,201,146,42)), (3.2*$u)
    $g.DrawEllipse($drp, ($dropCx-$dropR), ($dropCy-$dropR), ($dropR*2), ($dropR*2)); $drp.Dispose()
    $canW = 18*$u; $canH = 22*$u
    $canPath = New-RoundedRectPath ($dropCx-$canW/2) ($dropCy-$canH/2) $canW $canH (4*$u)
    $cb = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,58,44,12))
    $g.FillPath($cb, $canPath); $cb.Dispose()
    $cap = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,58,44,12))
    $g.FillRectangle($cap, ($dropCx-3*$u), ($dropCy-$canH/2-5*$u), (6*$u), (6*$u)); $cap.Dispose()
}

Draw-Glyph -g $g -cx 840 -cy 250 -scale 300

# wordmark "FUEL RUN"
$fontFamily = New-Object System.Drawing.FontFamily "Segoe UI Black"
$fontBig = New-Object System.Drawing.Font($fontFamily, 88, [System.Drawing.FontStyle]::Bold)
$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = [System.Drawing.StringAlignment]::Near

# "FUEL" in cream, "RUN" in gold — drawn as two runs on one baseline
$textX = 70; $textY = 150
$fuelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,244,241,234))
$g.DrawString("FUEL", $fontBig, $fuelBrush, $textX, $textY, $fmt)
$fuelSize = $g.MeasureString("FUEL", $fontBig, [int]::MaxValue, $fmt)
$fuelBrush.Dispose()

$runBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,201,60))
$g.DrawString("RUN", $fontBig, $runBrush, ($textX + $fuelSize.Width - 10), $textY, $fmt)
$runBrush.Dispose()

# tagline
$fontTag = New-Object System.Drawing.Font("Segoe UI Semibold", 26, [System.Drawing.FontStyle]::Regular)
$tagBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,169,166,196))
$g.DrawString("Dodge. Drift. Survive.", $fontTag, $tagBrush, $textX+4, $textY+120, $fmt)
$tagBrush.Dispose()

$g.Dispose()
New-Item -ItemType Directory -Force -Path "C:\Users\Lenovo\Documents\FuelRun\store" | Out-Null
$bmp.Save("C:\Users\Lenovo\Documents\FuelRun\store\feature-graphic.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Wrote feature-graphic.png"
