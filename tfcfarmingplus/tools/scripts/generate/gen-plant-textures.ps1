
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

function Draw-Stalk($bmp, [double]$x0, [double]$yBot, [double]$yTop, [double]$lean, [int]$cr, [int]$cg, [int]$cb, [double]$seed, [double]$shade) {
  $steps = [int][Math]::Round($yBot - $yTop)
  if ($steps -lt 1) { return }
  for ($i = 0; $i -le $steps; $i++) {
    $t = $i / [double]$steps
    $y = [int][Math]::Round($yBot - $t * ($yBot - $yTop))
    $x = [int][Math]::Round($x0 + $lean * $t * $t)
    $k = $shade * (0.88 + 0.10 * [Math]::Sin($seed + $y * 1.7))
    Set-Px $bmp $x $y $cr $cg $cb $k
    if ($t -gt 0.25) { Set-Px $bmp ($x + 1) $y $cr $cg $cb ($k * 0.74) }
  }
}
function Draw-LeafBlade($bmp, [double]$x0, [double]$y0, [double]$ang, [double]$len, [double]$wid, [int]$cr, [int]$cg, [int]$cb, [double]$seed, [double]$shade) {
  $steps = [int][Math]::Max(2, [Math]::Round($len * 2.2))
  for ($i = 0; $i -le $steps; $i++) {
    $t = $i / [double]$steps
    $px = $x0 + [Math]::Cos($ang) * $t * $len
    $py = $y0 + [Math]::Sin($ang) * $t * $len
    $hw = $wid * [Math]::Sin([Math]::PI * [Math]::Pow($t, 0.72))
    if ([Math]::Abs($t - 1.0) -lt 1e-9) { $hw = 0.0 }
    if ($hw -lt 0.30) { $hw = 0.30 }
    $wSteps = [int][Math]::Ceiling($hw * 2)
    for ($w = -$wSteps; $w -le $wSteps; $w++) {
      $ww = $w * 0.5
      if ([Math]::Abs($ww) -gt $hw) { continue }
      $ef = 1.0 - 0.72 * [Math]::Pow([Math]::Abs($ww) / [Math]::Max(0.3, $hw), 2.0)
      $lx = $px - [Math]::Sin($ang) * $ww
      $ly = $py + [Math]::Cos($ang) * $ww
      $nz = Jit ($lx * 3.1) ($ly * 2.7 + $seed)
      Set-Px $bmp ([int][Math]::Round($lx)) ([int][Math]::Round($ly)) $cr $cg $cb ($shade * $ef * (0.90 + 0.18 * $nz) * (0.62 + 0.48 * $t))
    }
  }
}
function Draw-Roots($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [double]$seed) {
  $n = 4 + $age * 2
  for ($i = 0; $i -lt $n; $i++) {
    $jx = Jit ($i * 3.7) $seed
    $x = [int][Math]::Round(2.2 + $jx * 11.6)
    $jy = Jit ($i * 1.9) ($seed + 5.1)
    $y = 15 - [int][Math]::Floor($jy * (1.0 + $age * 0.45))
    $d = [Math]::Abs($x - 7.5) / 8.0
    Set-Px $bmp $x $y $cr $cg $cb (0.50 + 0.34 * (1.0 - $d) + 0.10 * (Jit ($i * 2.3) ($seed + 9.0)))
  }
}

function Draw-Grain($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $n = 4 + [int]($age / 3)
  $maxH = 3.0 + $age * 2.15
  for ($i = 0; $i -lt $n; $i++) {
    $fx = ($i - ($n - 1) / 2.0) / (($n - 1) / 2.0)
    $xj = 0.7 * [Math]::Sin($seed * 1.7 + $i * 2.3)
    $x0 = 7.5 + $fx * 5.3 + $xj
    $h = $maxH * (1.0 - 0.20 * [Math]::Abs($fx)) * (0.86 + 0.26 * (Jit ($i + 1) $seed))
    $yTop = 15.0 - $h
    if ($yTop -lt 0.0) { $yTop = 0.0 }
    $lean = 0.85 * $fx + 0.35 * [Math]::Sin($seed + $i * 1.3)
    Draw-Stalk $bmp $x0 14.5 $yTop $lean $cr $cg $cb ($seed + $i) 1.0
    if ($age -ge 2) {
      $earLen = 1 + [int]($age / 2)
      for ($e = 0; $e -lt $earLen; $e++) {
        $yy = [int][Math]::Round($yTop) + $e
        $tt = 1.0 - ($e / [double][Math]::Max(1, $earLen))
        $xx = [int][Math]::Round($x0 + $lean * $tt * $tt)
        $kk = 0.94 + 0.14 * [Math]::Sin($seed + $yy * 2.3)
        Set-Px $bmp $xx $yy $fr $fg $fb $kk
        Set-Px $bmp ($xx + 1) $yy $fr $fg $fb ($kk * 0.76)
        if ($e -lt $earLen - 1) { Set-Px $bmp ($xx - 1) $yy $fr $fg $fb ($kk * 0.84) }
      }
    }
  }
  Draw-Roots $bmp $age $cr $cg $cb $seed
}

function Draw-Root($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $n = 3 + $age
  for ($i = 0; $i -lt $n; $i++) {
    $fx = ($i - ($n - 1) / 2.0) / (($n - 1) / 2.0)
    $ang = -[Math]::PI / 2.0 + $fx * 0.95
    $len = (2.0 + $age * 1.25) * (1.0 - 0.20 * [Math]::Abs($fx)) * (0.74 + 0.52 * (Jit ($i * 3.3) $seed))
    Draw-LeafBlade $bmp (7.6 + 0.55 * $fx) (11.6 + 0.7 * ((Jit ($i * 4.4) $seed) - 0.5)) $ang $len 0.95 $cr $cg $cb ($seed + $i * 1.7) 1.05
  }
  if ($age -ge 2) {
    $hw = 0.9 + ($age - 2) * 0.55
    for ($y = 11; $y -le 15; $y++) {
      for ($x = 0; $x -lt 16; $x++) {
        $dx = ($x + 0.5 - 7.6) / $hw
        $dy = ($y + 0.4 - 15.2) / ($hw * 1.25)
        if ($dx * $dx + $dy * $dy -gt 1.0) { continue }
        $k = (0.98 - 0.26 * ($dx * $dx + $dy * $dy)) * (0.96 + 0.08 * [Math]::Sin($seed + $x * 2.1 + $y))
        Set-Px $bmp $x $y $fr $fg $fb $k
      }
    }
  }
}

function Draw-Bush($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $top = 12.5 - $age * 1.55
  if ($top -lt 1.5) { $top = 1.5 }
  Draw-Stalk $bmp 7.6 14.5 $top 0.4 $cr $cg $cb $seed 0.92
  $pairs = 1 + [int]($age / 2)
  for ($p = 0; $p -lt $pairs; $p++) {
    $yy = 12.0 - $p * (10.0 / [Math]::Max(1, $pairs + 1))
    foreach ($s in @(-1.0, 1.0)) {
      $ang = if ($s -lt 0) { -[Math]::PI * 0.72 } else { -[Math]::PI * 0.28 }
      $len = (1.4 + $age * 0.55) * (0.92 + 0.20 * (Jit ($p + $s * 3) $seed))
      Draw-LeafBlade $bmp (7.6 + 0.35 * $s) $yy $ang $len 0.78 $cr $cg $cb ($seed + $p * 2.1 + $s) 1.0
    }
  }
  if ($age -ge 4) {
    $nf = $age - 3
    $spots = @(@(6.0, 11.5), @(9.6, 10.2), @(7.8, 13.2))
    for ($q = 0; $q -lt $nf -and $q -lt 3; $q++) {
      $cxp = $spots[$q][0]; $cyp = $spots[$q][1]
      for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) {
        $dx = ($x + 0.5 - $cxp) / 1.55; $dy = ($y + 0.5 - $cyp) / 1.55
        $d2 = $dx * $dx + $dy * $dy
        if ($d2 -gt 1.0) { continue }
        $nz = [Math]::Sqrt(1.0 - $d2)
        $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.50 + $nz * 0.76)
        Set-Px $bmp $x $y $fr $fg $fb (0.66 + 0.86 * $nl)
      } }
    }
  }
  Draw-Roots $bmp $age $cr $cg $cb $seed
}

function Draw-Legume($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $top = 12.5 - $age * 1.45
  if ($top -lt 2.0) { $top = 2.0 }
  Draw-Stalk $bmp 7.4 14.5 $top 0.9 $cr $cg $cb $seed 0.94
  for ($p = 0; $p -lt 3; $p++) {
    $yy = 12.0 - $p * 2.2
    if ($yy -lt $top) { break }
    foreach ($s in @(-1.0, 1.0)) {
      $ang = if ($s -lt 0) { -[Math]::PI * 0.78 } else { -[Math]::PI * 0.22 }
      Draw-LeafBlade $bmp (7.4 + 0.35 * $s) $yy $ang ((1.3 + $age * 0.42) * (0.78 + 0.44 * (Jit ($p + $s * 2) $seed))) 0.62 $cr $cg $cb ($seed + $p * 2.7 + $s) 1.0
    }
  }
  if ($age -ge 4) {
    for ($q = 0; $q -lt ($age - 3) * 2; $q++) {
      $yy = 11.5 - $q * 2.0
      $s = if (($q % 2) -eq 0) { -1.0 } else { 1.0 }
      for ($t = 0.0; $t -le 1.0; $t += 0.25) {
        $px = 7.4 + $s * (0.8 + $t * 1.5)
        $py = $yy + $t * 1.9
        Set-Px $bmp ([int][Math]::Round($px)) ([int][Math]::Round($py)) $fr $fg $fb (0.96 - 0.12 * $t)
      }
    }
  }
  Draw-Roots $bmp $age $cr $cg $cb $seed
}

function Draw-Fiber($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $n = 3 + [int]($age / 2)
  $maxH = 3.5 + $age * 2.3
  for ($i = 0; $i -lt $n; $i++) {
    $fx = ($i - ($n - 1) / 2.0) / (($n - 1) / 2.0)
    $x0 = 7.5 + $fx * 4.6 + 0.6 * [Math]::Sin($seed + $i * 2.9)
    $h = $maxH * (1.0 - 0.16 * [Math]::Abs($fx))
    $yTop = 15.0 - $h
    if ($yTop -lt 0.0) { $yTop = 0.0 }
    Draw-Stalk $bmp $x0 14.5 $yTop (1.1 * $fx) $cr $cg $cb ($seed + $i) 1.0
    if ($age -ge 3) {
      $yy = [int][Math]::Round($yTop)
      Set-Px $bmp ([int][Math]::Round($x0)) $yy $fr $fg $fb 1.08
      Set-Px $bmp ([int][Math]::Round($x0) - 1) $yy $fr $fg $fb 0.92
      Set-Px $bmp ([int][Math]::Round($x0) + 1) $yy $fr $fg $fb 0.92
      Set-Px $bmp ([int][Math]::Round($x0)) ($yy - 1) $fr $fg $fb 1.00
    }
  }
  Draw-Roots $bmp $age $cr $cg $cb $seed
}

function Draw-Leafy($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $n = 4 + $age
  for ($i = 0; $i -lt $n; $i++) {
    $fx = ($i - ($n - 1) / 2.0) / (($n - 1) / 2.0)
    $ang = -[Math]::PI / 2.0 + $fx * 1.25
    $len = (1.8 + $age * 1.15) * (1.0 - 0.22 * [Math]::Abs($fx)) * (0.72 + 0.56 * (Jit ($i * 5.1) $seed))
    Draw-LeafBlade $bmp (7.6 + 0.55 * $fx) (12.6 + 0.7 * ((Jit ($i * 2.6) $seed) - 0.5)) $ang $len 1.05 $cr $cg $cb ($seed + $i * 1.9) 1.02
  }
  if ($age -ge 4) {
    for ($q = 0; $q -lt $age - 3; $q++) {
      $cxp = 5.6 + $q * 3.4; $cyp = 12.6
      for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) {
        $dx = ($x + 0.5 - $cxp) / 1.3; $dy = ($y + 0.5 - $cyp) / 1.3
        if ($dx * $dx + $dy * $dy -gt 1.0) { continue }
        Set-Px $bmp $x $y $fr $fg $fb (0.84 + 0.24 * [Math]::Sin($seed + $x + $y))
      } }
    }
  }
}

function Draw-Flower($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [int]$fr, [int]$fg, [int]$fb, [double]$seed) {
  $top = 12.5 - $age * 1.5
  if ($top -lt 2.0) { $top = 2.0 }
  Draw-Stalk $bmp 7.6 14.5 $top 0.5 $cr $cg $cb $seed 0.96
  foreach ($s in @(-1.0, 1.0)) {
    Draw-LeafBlade $bmp 7.6 (12.2) ($(if ($s -lt 0) { -[Math]::PI * 0.76 } else { -[Math]::PI * 0.24 })) (1.6 + $age * 0.4) 0.70 $cr $cg $cb ($seed + $s) 1.0
  }
  if ($age -ge 3) {
    $yy = [int][Math]::Round($top)
    for ($dx = -1; $dx -le 1; $dx++) {
      for ($dy = -1; $dy -le 1; $dy++) {
        if ([Math]::Abs($dx) + [Math]::Abs($dy) -gt 1) { continue }
        Set-Px $bmp (7 + $dx) ($yy + $dy) $fr $fg $fb (0.96 + 0.16 * (Jit ($dx + 5) ($dy + 5)))
      }
    }
    Set-Px $bmp 7 $yy $fr $fg $fb 1.22
  }
  Draw-Roots $bmp $age $cr $cg $cb $seed
}

$specs = @{}
function S($n, $form, $r, $g, $b) { $script:specs[$n] = @($form, $r, $g, $b) }
S 'einkorn' 'grain' 216 200 120
S 'fonio' 'grain' 224 208 144
S 'buckwheat' 'grain' 108 72 52
S 'wild_rice_stem' 'grain' 208 192 128
S 'sesame' 'flower' 236 228 196
S 'flax' 'fiber' 120 152 208
S 'safflower' 'flower' 224 136 48
S 'garland_chrysanthemum' 'flower' 232 200 96
S 'parsnip' 'root' 232 220 192
S 'turnip' 'root' 200 184 216
S 'salsify' 'root' 200 176 112
S 'celeriac' 'root' 168 152 120
S 'chicory_root' 'root' 192 160 96
S 'yacon' 'root' 138 90 72
S 'taro' 'root' 160 136 104
S 'ginger' 'root' 200 168 112
S 'turmeric' 'root' 224 160 48
S 'water_chestnut' 'root' 96 64 44
S 'arrowhead' 'root' 232 228 208
S 'water_caltrop' 'root' 128 72 56
S 'eggplant' 'bush' 74 40 72
S 'chili' 'bush' 192 40 24
S 'okra' 'bush' 168 184 88
S 'brussels_sprouts' 'bush' 136 168 80
S 'cantaloupe' 'bush' 224 160 80
S 'winter_melon' 'bush' 56 96 44
S 'bottle_gourd' 'bush' 168 192 112
S 'artichoke' 'bush' 128 152 96
S 'rhubarb' 'bush' 192 56 40
S 'water_shield' 'bush' 96 144 88
S 'adzuki' 'legume' 160 64 56
S 'bambara_nut' 'legume' 176 152 104
S 'chickpea' 'legume' 192 192 112
S 'gorgon_nut' 'legume' 120 96 72
S 'lupin' 'legume' 176 184 104
S 'fenugreek' 'legume' 200 192 128
S 'arugula' 'leafy' 144 176 88
S 'spinach' 'leafy' 88 136 72
S 'swiss_chard' 'leafy' 200 64 64
S 'mustard_greens' 'leafy' 152 184 80
S 'water_spinach' 'leafy' 120 168 88
S 'perilla' 'leafy' 152 80 120
S 'celtuce' 'leafy' 152 184 96
S 'celery' 'leafy' 168 192 120
S 'asparagus' 'leafy' 136 168 88
S 'chive' 'leafy' 152 184 104
S 'water_dropwort' 'leafy' 144 176 96
S 'shallot' 'root' 200 144 152

$count = 0
foreach ($n in ($specs.Keys | Sort-Object)) {
  $sp = $specs[$n]
  $p5 = Join-Path $outDir ($n + '_5.png')
  if (-not (Test-Path $p5)) { Write-Output ('SKIP (no _5): ' + $n); continue }
  for ($age = 0; $age -le 5; $age++) {
    $p = Join-Path $outDir ($n + '_' + $age + '.png')
    if (-not (Test-Path $p)) { continue }
    Copy-Item $p (Join-Path $bak ($n + '_' + $age + '.png')) -Force
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $seed = ($n.Length * 1.13 + 2.7)
    $hsum = 0
    foreach ($ch in $n.ToCharArray()) { $hsum += [int]$ch }
    $lh = 68.0 + ($hsum % 37)
    $ls = 0.38 + (($hsum * 7) % 25) / 100.0
    $lv = 0.30 + (($hsum * 11) % 26) / 100.0
    $lcv = Hue2Rgb2 $lh $ls $lv
    $lr = $lcv[0]; $lg = $lcv[1]; $lb = $lcv[2]
    switch ($sp[0]) {
      'grain'  { Draw-Grain $bmp $age $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
      'root'   { Draw-Root $bmp $age $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
      'bush'   { Draw-Bush $bmp $age $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
      'legume' { Draw-Legume $bmp $age $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
      'fiber'  { Draw-Fiber $bmp $age $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
      'leafy'  { Draw-Leafy $bmp $age $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
      'flower' { Draw-Flower $bmp $age $lr $lg $lb $sp[1] $sp[2] $sp[3] $seed }
    }
    $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $count++
  }
}
Write-Output ('plant textures drawn: ' + $count)





