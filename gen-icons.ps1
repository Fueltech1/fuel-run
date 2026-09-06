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

function Draw-Icon {
    param([int]$size, [string]$outPath, [bool]$maskable)

    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # background gradient (sky-top -> sky-bottom), matches game palette
    $rectF = New-Object System.Drawing.RectangleF 0,0,$size,$size
    $colTop = [System.Drawing.Color]::FromArgb(255,21,24,51)     # #151833
    $colBottom = [System.Drawing.Color]::FromArgb(255,44,32,73)  # #2c2049
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rectF, $colTop, $colBottom, 90.0)
    if($maskable){
        $g.FillRectangle($brush, 0,0,$size,$size)
    } else {
        $r = $size * 0.22
        $bgPath = New-RoundedRectPath 0 0 $size $size $r
        $g.FillPath($brush, $bgPath)
    }
    $brush.Dispose()

    # scale factor: maskable needs content inside ~80% safe zone
    $scale = if($maskable) { 0.62 } else { 0.82 }
    $cx = $size/2.0
    $cy = $size/2.0
    $u = $size * $scale / 200.0   # unit scale (design drawn in a 200x200 box)

    # road stripe behind car
    $roadW = 96*$u
    $roadPath = New-RoundedRectPath ($cx-$roadW/2) ($cy-100*$u) $roadW (200*$u) (10*$u)
    $roadBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,43,47,60))
    $g.FillPath($roadBrush, $roadPath)
    $roadBrush.Dispose()

    # lane dashes
    $lanePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230,238,231,214)), (6*$u)
    $lanePen.DashPattern = @(3.0,2.4)
    $g.DrawLine($lanePen, $cx, $cy-95*$u, $cx, $cy+95*$u)
    $lanePen.Dispose()

    # car body (teal, top-down), centered, pointing up
    $carW = 66*$u; $carH = 108*$u
    $carX = $cx - $carW/2; $carY = $cy - $carH/2 + 6*$u
    $carPath = New-RoundedRectPath $carX $carY $carW $carH (16*$u)
    $carBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,63,199,193))
    # drop shadow
    $shadowPath = New-RoundedRectPath ($carX+4*$u) ($carY+6*$u) $carW $carH (16*$u)
    $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70,0,0,0))
    $g.FillPath($shadowBrush, $shadowPath)
    $shadowBrush.Dispose()
    $g.FillPath($carBrush, $carPath)
    $carBrush.Dispose()

    # windshield (darker teal), toward the top (front of car)
    $wsW = $carW - 20*$u; $wsH = $carH*0.30
    $wsX = $carX + 10*$u; $wsY = $carY + $carH*0.16
    $wsPath = New-RoundedRectPath $wsX $wsY $wsW $wsH (8*$u)
    $wsBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,37,147,142))
    $g.FillPath($wsBrush, $wsPath)
    $wsBrush.Dispose()

    # headlights (front/top) and taillights (back/bottom)
    $lightBrushF = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,247,214))
    $g.FillRectangle($lightBrushF, ($carX+6*$u), ($carY+4*$u), (12*$u), (6*$u))
    $g.FillRectangle($lightBrushF, ($carX+$carW-18*$u), ($carY+4*$u), (12*$u), (6*$u))
    $lightBrushF.Dispose()
    $lightBrushR = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,95,77))
    $g.FillRectangle($lightBrushR, ($carX+6*$u), ($carY+$carH-10*$u), (12*$u), (6*$u))
    $g.FillRectangle($lightBrushR, ($carX+$carW-18*$u), ($carY+$carH-10*$u), (12*$u), (6*$u))
    $lightBrushR.Dispose()

    # fuel drop badge, bottom-right, gold
    $dropCx = $cx + 62*$u; $dropCy = $cy + 78*$u; $dropR = 30*$u
    $dropShadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70,0,0,0))
    $g.FillEllipse($dropShadow, ($dropCx-$dropR+3*$u), ($dropCy-$dropR+4*$u), ($dropR*2), ($dropR*2))
    $dropShadow.Dispose()
    $dropBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,255,201,60))
    $g.FillEllipse($dropBrush, ($dropCx-$dropR), ($dropCy-$dropR), ($dropR*2), ($dropR*2))
    $dropBrush.Dispose()
    $dropRingPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255,201,146,42)), (3.2*$u)
    $g.DrawEllipse($dropRingPen, ($dropCx-$dropR), ($dropCy-$dropR), ($dropR*2), ($dropR*2))
    $dropRingPen.Dispose()
    # small fuel-can glyph inside the badge
    $canW = 18*$u; $canH = 22*$u
    $canPath = New-RoundedRectPath ($dropCx-$canW/2) ($dropCy-$canH/2) $canW $canH (4*$u)
    $canBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,58,44,12))
    $g.FillPath($canBrush, $canPath)
    $canBrush.Dispose()
    $capBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,58,44,12))
    $g.FillRectangle($capBrush, ($dropCx-3*$u), ($dropCy-$canH/2-5*$u), (6*$u), (6*$u))
    $capBrush.Dispose()

    $g.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Wrote $outPath"
}

New-Item -ItemType Directory -Force -Path "C:\Users\Lenovo\Documents\FuelRun\icons" | Out-Null

Draw-Icon -size 512 -outPath "C:\Users\Lenovo\Documents\FuelRun\icons\icon-512.png" -maskable $false
Draw-Icon -size 512 -outPath "C:\Users\Lenovo\Documents\FuelRun\icons\icon-512-maskable.png" -maskable $true
Draw-Icon -size 192 -outPath "C:\Users\Lenovo\Documents\FuelRun\icons\icon-192.png" -maskable $false
Draw-Icon -size 180 -outPath "C:\Users\Lenovo\Documents\FuelRun\icons\apple-touch-icon.png" -maskable $false
Draw-Icon -size 32  -outPath "C:\Users\Lenovo\Documents\FuelRun\icons\favicon-32.png" -maskable $false
