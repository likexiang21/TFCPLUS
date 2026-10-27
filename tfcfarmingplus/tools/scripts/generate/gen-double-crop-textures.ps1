
param([string]$Out)
Add-Type -AssemblyName System.Drawing
$root = Join-Path $env:TFC_TOOLS_ROOT '..\src\main\resources'
$outDir = Join-Path $root 'assets/tfcfarmingplus/textures/block/crop'
$bak = Join-Path $env:TFC_TOOLS_ROOT '..\..\..\.probe\skill-review\crop-old'
if (-not (Test-Path $bak)) { New-Item -ItemType Directory -Path $bak -Force | Out-Null }

function Set-Px($bmp, [int]$x, [int]$y, [int]$cr, [int]$cg, [int]$cb, [double]$k) {
  if ($x -lt 0 -or $x -gt 15 -or $y -lt 0 -or $y -gt 15) { return }
  $r = [int][Math]::Round($cr * $k); if ($r -lt 0) { $r = 0 }; if ($r -gt 255) { $r = 255 }
  $g = [int][Math]::Round($cg * $k); if ($g -lt 0) { $g = 0 }; if ($g -gt 255) { $g = 255 }
  $b = [int][Math]::Round($cb * $k); if ($b -lt 0) { $b = 0 }; if ($b -gt 255) { $b = 255 }
  $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
}
function Jit([double]$a, [double]$b) { $h = [Math]::Sin($a * 12.9898 + $b * 78.233) * 43758.5453; return ($h - [Math]::Floor($h)) }
function Hue2Rgb2([double]$ppH, [double]$ppS, [double]$ppV) {
  $ppH = (($ppH % 360) + 360) % 360
  $c = $ppV * $ppS
  $hp = $ppH / 60.0
  $x2 = $c * (1 - [Math]::Abs(($hp % 2) - 1))
  $rr = 0.0; $gg = 0.0; $bb = 0.0
  if ($hp -lt 1) { $rr = $c; $gg = $x2 }
  elseif ($hp -lt 2) { $rr = $x2; $gg = $c }
  elseif ($hp -lt 3) { $gg = $c; $bb = $x2 }
  elseif ($hp -lt 4) { $gg = $x2; $bb = $c }
  elseif ($hp -lt 5) { $rr = $x2; $bb = $c }
  else { $rr = $c; $bb = $x2 }
  $m = $ppV - $c
  return @([int][Math]::Round(($rr + $m) * 255), [int][Math]::Round(($gg + $m) * 255), [int][Math]::Round(($bb + $m) * 255))
}

function Stem($bmp, [double]$x0, [double]$yBot, [double]$yTop, [double]$lean, [int]$sr, [int]$sg, [int]$sb, [double]$seed) {
  $steps = [int][Math]::Round($yBot - $yTop)
  if ($steps -lt 1) { return }
  for ($i = 0; $i -le $steps; $i++) {
    $t = $i / [double]$steps
    $y = [int][Math]::Round($yBot - $t * ($yBot - $yTop))
    $x = [int][Math]::Round($x0 + $lean * $t * $t)
    $k = 0.86 + 0.12 * [Math]::Sin($seed + $y * 1.9)
    Set-Px $bmp $x $y $sr $sg $sb $k
    Set-Px $bmp ($x + 1) $y $sr $sg $sb ($k * 0.70)
  }
}
function Blade($bmp, [double]$x0, [double]$y0, [double]$ang, [double]$len, [double]$wid, [int]$cr, [int]$cg, [int]$cb, [double]$seed, [double]$shade) {
  $steps = [int][Math]::Max(2, [Math]::Round($len * 2.4))
  for ($i = 0; $i -le $steps; $i++) {
    $t = $i / [double]$steps
    $px = $x0 + [Math]::Cos($ang) * $t * $len
    $py = $y0 + [Math]::Sin($ang) * $t * $len
    $hw = $wid * [Math]::Sin([Math]::PI * [Math]::Pow($t, 0.70))
    if ($hw -lt 0.28) { $hw = 0.28 }
    $ws = [int][Math]::Ceiling($hw * 2)
    for ($w = -$ws; $w -le $ws; $w++) {
      $ww = $w * 0.5
      if ([Math]::Abs($ww) -gt $hw) { continue }
      $ef = 1.0 - 0.70 * [Math]::Pow([Math]::Abs($ww) / [Math]::Max(0.3, $hw), 2.0)
      $lx = $px - [Math]::Sin($ang) * $ww
      $ly = $py + [Math]::Cos($ang) * $ww
      $nz = Jit ($lx * 3.1) ($ly * 2.7 + $seed)
      Set-Px $bmp ([int][Math]::Round($lx)) ([int][Math]::Round($ly)) $cr $cg $cb ($shade * $ef * (0.88 + 0.20 * $nz) * (0.60 + 0.50 * $t))
    }
  }
}
function Berry($bmp, [double]$cxp, [double]$cyp, [double]$rad, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) {
    $dx = ($x + 0.5 - $cxp) / $rad; $dy = ($y + 0.5 - $cyp) / ($rad * 1.08)
    $d2 = $dx * $dx + $dy * $dy
    if ($d2 -gt 1.0) { continue }
    $nz = [Math]::Sqrt(1.0 - $d2)
    $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.52 + $nz * 0.74)
    Set-Px $bmp $x $y $fr $fg $fb (0.62 + 0.90 * $nl + 0.05 * (Jit ($x * 2.1) ($y * 1.7 + $seed)))
  } }
}

function Draw-Stick($bmp, [int]$idx, [int]$cr, [int]$cg, [int]$cb, [int]$sr, [int]$sg, [int]$sb, [double]$seed) {
  $top = 12.0 - $idx * 1.5
  Stem $bmp 7.6 15.0 $top 0.0 $sr $sg $sb $seed
  Draw-Young $bmp $idx $cr $cg $cb $seed $top
}
function Draw-Young($bmp, [int]$idx, [int]$cr, [int]$cg, [int]$cb, [double]$seed, [double]$top) {
  $n = 2 + $idx
  for ($i = 0; $i -lt $n; $i++) {
    $s = if (($i % 2) -eq 0) { -1.0 } else { 1.0 }
    $ang = if ($s -lt 0) { -[Math]::PI * 0.74 } else { -[Math]::PI * 0.26 }
    $yy = 14.0 - [Math]::Floor($i / 2) * 2.1
    if ($yy -lt $top) { continue }
    Blade $bmp (7.6 + 0.3 * $s) $yy $ang ((2.2 + $idx * 0.50) * (0.80 + 0.40 * (Jit ($i * 3.1) $seed))) 0.78 $cr $cg $cb ($seed + $i * 1.7) 1.0
  }
}

function Draw-DblGrain($bmp, [int]$idx, [string]$half, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $isTop = ($half -eq 'top')
  $n = 2 + [int]($idx / 3)
  $hMax = 10.0 + ($idx - 4) * 1.6
  for ($i = 0; $i -lt $n; $i++) {
    $fx = ($i - ($n - 1) / 2.0) / (($n - 1) / 2.0)
    $x0 = 7.5 + $fx * 5.8 + 0.6 * [Math]::Sin($seed + $i * 2.7)
    $lean = 0.8 * $fx
    if ($isTop) {
      $yTop = 15.0 - $hMax
      if ($yTop -lt 0.0) { $yTop = 0.0 }
      Stem $bmp $x0 15.0 $yTop $lean $cr $cg $cb ($seed + $i)
      if ($idx -ge 5) {
        $earLen = 2 + ($idx - 5)
        for ($e = 0; $e -lt $earLen; $e++) {
          $yy = [int][Math]::Round($yTop) + $e
          $tt = 1.0 - $e / [double][Math]::Max(1, $earLen)
          $xx = [int][Math]::Round($x0 + $lean * $tt * $tt)
          $kk = 0.92 + 0.14 * [Math]::Sin($seed + $yy * 2.3)
          Set-Px $bmp $xx $yy $fr $fg $fb $kk
          Set-Px $bmp ($xx + 1) $yy $fr $fg $fb ($kk * 0.74)
          Set-Px $bmp ($xx - 1) $yy $fr $fg $fb ($kk * 0.62)
        }
      }
      else {
        Blade $bmp $x0 ($yTop + 1.5 + 1.8 * (Jit ($i * 4.2) $seed)) (-[Math]::PI * 0.70) (2.0 + $idx * 0.3) 0.62 $cr $cg $cb ($seed + $i) 0.94
        Blade $bmp $x0 ($yTop + 3.0 + 2.2 * (Jit ($i * 2.8) ($seed + 3))) (-[Math]::PI * 0.30) (2.0 + $idx * 0.3) 0.62 $cr $cg $cb ($seed + $i + 9) 0.94
      }
    }
    else {
      Stem $bmp $x0 15.0 0.0 $lean $cr $cg $cb ($seed + $i)
      Blade $bmp $x0 (3.0 + 4.5 * (Jit ($i * 3.3) $seed)) (-[Math]::PI * 0.62) (2.4 + $idx * 0.30) 0.72 $cr $cg $cb ($seed + $i + 3) 0.96
      Blade $bmp $x0 (6.0 + 5.0 * (Jit ($i * 5.1) ($seed + 2))) (-[Math]::PI * 0.38) (2.4 + $idx * 0.30) 0.72 $cr $cg $cb ($seed + $i + 5) 0.96
      Blade $bmp $x0 (10.0 + 4.0 * (Jit ($i * 7.9) ($seed + 4))) (-[Math]::PI * 0.70) (2.3 + $idx * 0.28) 0.70 $cr $cg $cb ($seed + $i + 11) 0.94
      Blade $bmp $x0 (12.2 + 2.8 * (Jit ($i * 9.1) ($seed + 6))) (-[Math]::PI * 0.30) (2.3 + $idx * 0.28) 0.70 $cr $cg $cb ($seed + $i + 13) 0.94
    }
  }
}

function Draw-DblVine($bmp, [int]$idx, [string]$half, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $isTop = ($half -eq 'top')
  $sr = 84; $sg = 64; $sb = 16
  $stemTop = if ($isTop) { 15.0 - (9.0 + ($idx - 4) * 1.5) } else { 0.0 }
  if ($stemTop -lt 0.5) { $stemTop = 0.5 }
  if ($isTop) { Stem $bmp 7.6 15.0 $stemTop 0.6 $sr $sg $sb $seed } else { Stem $bmp 7.6 15.0 0.0 0.6 $sr $sg $sb $seed }
  $pairs = 2 + [int]($idx / 3)
  for ($p = 0; $p -lt $pairs; $p++) {
    $yy = 3.0 + $p * (11.0 / [Math]::Max(1, $pairs))
    if ($isTop -and ($yy -lt $stemTop - 1.0)) { continue }
    foreach ($s in @(-1.0, 1.0)) {
      $ang = if ($s -lt 0) { -[Math]::PI * 0.76 } else { -[Math]::PI * 0.24 }
      Blade $bmp (7.6 + 0.35 * $s) $yy $ang ((1.5 + $idx * 0.26) * (0.82 + 0.36 * (Jit ($p + $s * 3) $seed))) 0.80 $cr $cg $cb ($seed + $p * 2.3 + $s) 1.0
    }
  }
  if ($idx -ge 5) {
    $nf = $idx - 4
    $spots = if ($isTop) { @(@(5.2, 9.0), @(10.0, 6.4), @(7.8, 12.4)) } else { @(@(6.0, 11.6), @(9.8, 10.0), @(7.8, 3.4)) }
    for ($q = 0; $q -lt $nf -and $q -lt 3; $q++) {
      Berry $bmp $spots[$q][0] $spots[$q][1] (1.00 + 0.10 * ($idx - 5)) $fr $fg $fb ($seed + $q)
    }
  }
}

function Draw-DblLegume($bmp, [int]$idx, [string]$half, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $isTop = ($half -eq 'top')
  $sr = 84; $sg = 64; $sb = 16
  if ($isTop) { Stem $bmp 7.4 15.0 (15.0 - (8.0 + ($idx - 4) * 1.4)) 0.9 $sr $sg $sb $seed } else { Stem $bmp 7.4 15.0 0.0 0.9 $sr $sg $sb $seed }
  for ($p = 0; $p -lt 3; $p++) {
    $yy = 4.0 + $p * 4.0
    foreach ($s in @(-1.0, 1.0)) {
      $ang = if ($s -lt 0) { -[Math]::PI * 0.78 } else { -[Math]::PI * 0.22 }
      Blade $bmp (7.4 + 0.35 * $s) $yy $ang ((1.4 + $idx * 0.22) * (0.80 + 0.40 * (Jit ($p + $s * 2) $seed))) 0.70 $cr $cg $cb ($seed + $p * 2.7 + $s) 1.0
    }
  }
  if ($idx -ge 5) {
    for ($q = 0; $q -lt ($idx - 4) * 2; $q++) {
      $yy = if ($isTop) { 6.0 + $q * 3.2 } else { 12.5 - $q * 3.2 }
      $s = if (($q % 2) -eq 0) { -1.0 } else { 1.0 }
      for ($t = 0.0; $t -le 1.0; $t += 0.22) {
        Set-Px $bmp ([int][Math]::Round(7.4 + $s * (0.9 + $t * 1.6))) ([int][Math]::Round($yy + $t * 2.2)) $fr $fg $fb (0.94 - 0.14 * $t)
      }
    }
  }
}

function Draw-DblFiber($bmp, [int]$idx, [string]$half, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $isTop = ($half -eq 'top')
  $n = 2 + [int]($idx / 2)
  for ($i = 0; $i -lt $n; $i++) {
    $fx = ($i - ($n - 1) / 2.0) / [Math]::Max(1.0, ($n - 1) / 2.0)
    $x0 = 7.5 + $fx * 3.6 + 0.5 * [Math]::Sin($seed + $i * 2.9)
    if ($isTop) {
      $yTop = 15.0 - (8.0 + ($idx - 4) * 1.5)
      if ($yTop -lt 0.0) { $yTop = 0.0 }
      Stem $bmp $x0 15.0 $yTop (0.9 * $fx) $cr $cg $cb ($seed + $i)
      if ($idx -ge 5) {
        $yy = [int][Math]::Round($yTop)
        foreach ($dd in @(@(0, 0), @(-1, 0), @(1, 0), @(0, -1), @(-1, -1), @(1, -1))) {
          Set-Px $bmp ([int][Math]::Round($x0) + $dd[0]) ($yy + $dd[1]) $fr $fg $fb (0.92 + 0.20 * (Jit ($dd[0] + 4) ($dd[1] + 4 + $seed)))
        }
      }
    }
    else {
      Stem $bmp $x0 15.0 0.0 (0.9 * $fx) $cr $cg $cb ($seed + $i)
      Blade $bmp $x0 (4.0 + 4.0 * (Jit ($i * 2.7) $seed)) (-[Math]::PI * 0.64) (2.1 + $idx * 0.24) 0.66 $cr $cg $cb ($seed + $i + 4) 0.94
      Blade $bmp $x0 (7.5 + 4.0 * (Jit ($i * 4.9) ($seed + 3))) (-[Math]::PI * 0.36) (2.1 + $idx * 0.24) 0.66 $cr $cg $cb ($seed + $i + 6) 0.94
      Blade $bmp $x0 (11.5 + 3.0 * (Jit ($i * 6.1) ($seed + 7))) (-[Math]::PI * 0.68) (2.0 + $idx * 0.22) 0.62 $cr $cg $cb ($seed + $i + 14) 0.92
    }
  }
}

function Draw-DblTuber($bmp, [int]$idx, [string]$half, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $isTop = ($half -eq 'top')
  if ($isTop) {
    Stem $bmp 7.6 15.0 (15.0 - (7.0 + ($idx - 4) * 1.4)) 0.5 $cr $cg $cb $seed
    for ($p = 0; $p -lt 2; $p++) {
      $yy = 6.0 + $p * 4.2
      foreach ($s in @(-1.0, 1.0)) {
        Blade $bmp (7.6 + 0.35 * $s) $yy ($(if ($s -lt 0) { -[Math]::PI * 0.74 } else { -[Math]::PI * 0.26 })) (2.0 + $idx * 0.30) 0.88 $cr $cg $cb ($seed + $p * 3.1 + $s) 1.0
      }
    }
  }
  else {
    Stem $bmp 7.6 15.0 0.0 0.5 $cr $cg $cb $seed
    for ($p = 0; $p -lt 2; $p++) {
      $yy = 9.0 + $p * 4.0
      foreach ($s in @(-1.0, 1.0)) {
        Blade $bmp (7.6 + 0.35 * $s) $yy ($(if ($s -lt 0) { -[Math]::PI * 0.76 } else { -[Math]::PI * 0.24 })) (2.2 + $idx * 0.26) 1.00 $cr $cg $cb ($seed + $p * 3.1 + $s) 1.0
      }
    }
    if ($idx -ge 5) {
      foreach ($pt in @(@(6.2, 13.6), @(9.2, 14.2))) {
        Berry $bmp $pt[0] $pt[1] (1.15 + 0.18 * ($idx - 5)) $fr $fg $fb ($seed + $pt[0])
      }
    }
  }
}

$specs = @{}
function D($n, $form, $r, $g, $b) { $script:specs[$n] = @($form, $r, $g, $b) }
D 'amaranth' 'grain' 168 48 72
D 'emmer' 'grain' 208 184 104
D 'foxtail_millet' 'grain' 216 184 88
D 'millet' 'grain' 208 184 96
D 'pearl_millet' 'grain' 200 192 136
D 'jobs_tears' 'grain' 216 216 192
D 'quinoa' 'grain' 208 128 72
D 'bitter_melon' 'vine' 152 176 88
D 'chayote' 'vine' 176 200 140
D 'loofah' 'vine' 152 176 96
D 'snake_gourd' 'vine' 168 192 144
D 'winter_melon' 'vine' 96 120 96
D 'hops' 'vine' 168 184 104
D 'malabar_spinach' 'vine' 96 48 80
D 'faba_bean' 'legume' 144 168 88
D 'cotton' 'fiber' 232 232 220
D 'ramie' 'fiber' 208 216 192
D 'sunchoke' 'tuber' 192 168 104
D 'yam' 'tuber' 152 120 88
D 'taro' 'tuber' 160 136 104
D 'lotus' 'tuber' 232 152 176
D 'buckwheat' 'grain' 108 72 52
D 'finger_millet' 'grain' 168 88 56
D 'fonio' 'grain' 224 208 144
D 'einkorn8' 'grain' 216 200 120
D 'spelt' 'grain' 216 196 112

$count = 0
foreach ($n in ($specs.Keys | Sort-Object)) {
  $sp = $specs[$n]
  $name = if ($n -eq 'einkorn8') { 'einkorn' } else { $n }
  $hsum = 0
  foreach ($ch in $name.ToCharArray()) { $hsum += [int]$ch }
  $lcv = Hue2Rgb2 (68.0 + ($hsum % 37)) (0.38 + (($hsum * 7) % 25) / 100.0) (0.30 + (($hsum * 11) % 26) / 100.0)
  $lr = $lcv[0]; $lg = $lcv[1]; $lb = $lcv[2]
  for ($i = 0; $i -le 7; $i++) {
    $targets = @()
    if (Test-Path (Join-Path $outDir ($name + '_' + $i + '_bottom.png'))) { $targets += 'bottom' }
    if (Test-Path (Join-Path $outDir ($name + '_' + $i + '_top.png'))) { $targets += 'top' }
    if (Test-Path (Join-Path $outDir ($name + '_' + $i + '_stick.png'))) { $targets += 'stick' }
    if ((Test-Path (Join-Path $outDir ($name + '_' + $i + '.png'))) -and -not ($name -eq 'einkorn' -and $i -le 5)) { $targets += 'single' }
    foreach ($tg in $targets) {
      $suffix = if ($tg -eq 'single') { '' } else { '_' + $tg }
      $p = Join-Path $outDir ($name + '_' + $i + $suffix + '.png')
      Copy-Item $p (Join-Path $bak ($name + '_' + $i + $suffix + '.png')) -Force
      $bmp = New-Object System.Drawing.Bitmap(16, 16)
      $seed = ($name.Length * 1.31 + 3.7)
      if ($tg -eq 'single') {
        if ($i -le 3) { Draw-Stick $bmp $i $lr $lg $lb $lr $lg $lb $seed }
        else { Draw-DblVine $bmp $i 'bottom' $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
      }
      elseif ($tg -eq 'stick') { Draw-Stick $bmp $i $lr $lg $lb 84 64 16 $seed }
      else {
        switch ($sp[0]) {
          'grain'  { Draw-DblGrain $bmp $i $tg $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
          'vine'   { Draw-DblVine $bmp $i $tg $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
          'legume' { Draw-DblLegume $bmp $i $tg $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
          'fiber'  { Draw-DblFiber $bmp $i $tg $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
          'tuber'  { Draw-DblTuber $bmp $i $tg $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
        }
      }
      $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
      $bmp.Dispose()
      $count++
    }
  }
}
Write-Output ('double-crop textures drawn: ' + $count)






