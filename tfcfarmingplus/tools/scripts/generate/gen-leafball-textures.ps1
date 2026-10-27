
param([string]$Out)
Add-Type -AssemblyName System.Drawing
$root = Join-Path $env:TFC_TOOLS_ROOT '..\src\main\resources'
$outDir = Join-Path $root 'assets/tfcfarmingplus/textures/block/crop'
$bakDir = Join-Path $env:TFC_TOOLS_ROOT '..\..\..\.probe\skill-review\leafball-old'
if (-not (Test-Path $bakDir)) { New-Item -ItemType Directory -Path $bakDir -Force | Out-Null }

function Hue2Rgb([double]$ppH, [double]$ppS, [double]$ppV) {
  $ppH = (($ppH % 360) + 360) % 360
  $c = $ppV * $ppS
  $hp = $ppH / 60.0
  $xx2 = $c * (1 - [math]::Abs(($hp % 2) - 1))
  $rr = 0.0; $gg = 0.0; $bb = 0.0
  if ($hp -lt 1) { $rr = $c; $gg = $xx2 }
  elseif ($hp -lt 2) { $rr = $xx2; $gg = $c }
  elseif ($hp -lt 3) { $gg = $c; $bb = $xx2 }
  elseif ($hp -lt 4) { $gg = $xx2; $bb = $c }
  elseif ($hp -lt 5) { $rr = $xx2; $bb = $c }
  else { $rr = $c; $bb = $xx2 }
  $mm = $ppV - $c
  return @([int][math]::Round(($rr + $mm) * 255), [int][math]::Round(($gg + $mm) * 255), [int][math]::Round(($bb + $mm) * 255))
}
function Hash01([double]$na, [double]$nb, [double]$nc) {
  $hx = [math]::Sin($na * 12.9898 + $nb * 78.233 + $nc * 37.719) * 43758.5453
  return ($hx - [math]::Floor($hx))
}
function Clamp01([double]$cv) { if ($cv -lt 0) { return 0.0 } elseif ($cv -gt 1) { return 1.0 } else { return $cv } }

function Render-Head {
  param([double]$Hue, [double]$Sat, [double]$Val, [int]$Seed = 1, [double]$Rough = 1.0,
        [switch]$Curd, [double]$CurdH = 60, [double]$CurdS = 0.10, [double]$CurdV = 0.90)
  $bmp = New-Object System.Drawing.Bitmap(16, 16)
  for ($y = 0; $y -lt 16; $y++) {
    for ($x = 0; $x -lt 16; $x++) {
      $nx = ($x + 0.5 - 7.6) / 6.15
      $ny = ($y + 0.5 - 7.7) / 6.75
      $d = [math]::Sqrt($nx * $nx + $ny * $ny)
      $th = [math]::Atan2($ny, $nx)
      $edge = 1.0 + $Rough * (0.095 * [math]::Sin(3 * $th + 0.7 + $Seed) + 0.062 * [math]::Sin(5 * $th + 2.1) + 0.040 * [math]::Sin(9 * $th + 0.9 * $Seed))
      if ($d -gt $edge) { continue }
      $n1 = Hash01 $x $y $Seed
      $rim = Clamp01 (($edge - $d) / 0.22)
      $shade = 0.30 + 0.70 * [math]::Pow($rim, 0.60)
      $shade *= (1.0 + 0.50 * (-$nx * 0.42 - $ny * 0.68))
      $shade *= (0.80 + 0.24 * (Clamp01 (1.05 - $d)))
      $hh = $Hue; $ss = $Sat; $vv = $Val
      if ($Curd) {
        if ($y -ge 11) {
          $shade *= (0.62 + 0.30 * $rim)
        }
        else {
          $gx = [math]::Floor($x / 2.0); $gy = [math]::Floor($y / 2.0)
          $g = Hash01 $gx $gy ($Seed + 9)
          $shade *= (0.62 + 0.60 * $g)
          $shade *= (1.0 + 0.08 * [math]::Sin($x * 1.7 + $y * 2.3))
          $hh = $CurdH; $ss = $CurdS; $vv = $CurdV
        }
      }
      else {
        $lay = $d * 3.3 + 0.18 * [math]::Sin(4 * $th + 1.1 + $Seed)
        $fr = $lay - [math]::Floor($lay)
        if ($fr -lt 0.13) { $shade *= (0.42 + 0.58 * $fr / 0.13) }
        $ang = $th + 0.26 * [math]::Sin(2 * $th + $Seed * 0.5)
        $rv = ($ang / (2 * [math]::PI)) * 8.0 + 0.5
        $rvf = $rv - [math]::Floor($rv)
        $dv = [math]::Abs($rvf - 0.5)
        if ($dv -lt 0.09) { $shade *= (1.0 + 0.30 * (1.0 - $dv / 0.09)) }
      }
      $shade *= (0.86 + 0.26 * $n1)
      $cc = Hue2Rgb ($hh + 3.0 * (0.5 - $n1)) (Clamp01 ($ss + 0.06 * ($n1 - 0.5))) (Clamp01 ($vv * 0.96 * $shade))
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $cc[0], $cc[1], $cc[2]))
    }
  }
  return $bmp
}

function Render-LeafStrip {
  param([double]$Hue, [double]$Sat, [double]$Val, [int]$Age, [int]$Seed,
        [double]$Wide = 1.0, [double]$Lob = 0.30, [double]$Wave = 0.85)
  $bmp = New-Object System.Drawing.Bitmap(16, 16)
  $len = @(3, 5, 7, 10, 13, 16)[$Age]
  for ($k = 0; $k -lt 4; $k++) {
    if (($Age -lt 3) -and ($k -gt $Age)) { continue }
    $lenK = $len - [int]([math]::Floor(2.8 * (Hash01 $k ($Seed + 4) 3.3)))
    if ($lenK -lt 2) { $lenK = 2 }
    $topK = 16 - $lenK
    $wideK = $Wide * (0.78 + 0.48 * (Hash01 ($k + 11) ($Seed + 2) 8.1))
    $phase = $Seed * 0.9 + $k * 1.95
    for ($v = $topK; $v -lt 16; $v++) {
      $tt = ($v - $topK + 0.5) / [double]$lenK
      $halfw = (0.26 + 0.74 * [math]::Sin([math]::PI * [math]::Pow($tt, $Wave))) * $wideK
      $halfw *= (1.0 - $Lob + 2.0 * $Lob * (Hash01 ($k * 5 + $v) 3.1 0.7))
      $cx = 2.0 + 1.22 * [math]::Sin($tt * 3.4 + $phase)
      for ($u = 0; $u -lt 4; $u++) {
        $ax = $u + 0.5 + 0.08 * [math]::Sin($v * 1.7 + $phase)
        $dax = [math]::Abs($ax - $cx)
        if ($dax -gt $halfw) { continue }
        $rr = $dax / [math]::Max(0.26, $halfw)
        $shade = 1.00 - 0.72 * $rr * $rr
        if ($dax -lt 0.44) { $shade *= 1.18 }
        if ($rr -gt 0.76) { $shade *= 0.72 }
        $shade *= (0.30 + 0.70 * (1.0 - $tt))
        $nz = Hash01 ($k * 17 + $u) ($v + $Seed * 31) 7
        $shade *= (0.86 + 0.22 * $nz)
        $cc = Hue2Rgb ($Hue - 10 * $tt + 4 * ($nz - 0.5)) (Clamp01 ($Sat * 1.05)) (Clamp01 ($Val * $shade))
        $bmp.SetPixel(($k * 4 + $u), $v, [System.Drawing.Color]::FromArgb(255, $cc[0], $cc[1], $cc[2]))
      }
    }
  }
  return $bmp
}

function Save-Bmp($bmp, [string]$name) {
  $p = Join-Path $outDir ($name + '.png')
  if ((Test-Path $p) -and -not (Test-Path (Join-Path $bakDir ($name + '.png')))) { Copy-Item $p (Join-Path $bakDir ($name + '.png')) -Force }
  $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

$species = @(
  @{ n = 'cabbage';      h = 84.0;  s = 0.68; v = 0.33; wide = 1.00; lob = 0.26; wave = 0.85; rough = 1.15 },
  @{ n = 'lettuce';      h = 88.0;  s = 0.60; v = 0.41; wide = 0.92; lob = 0.44; wave = 0.70; rough = 1.45 },
  @{ n = 'kale';         h = 100.0; s = 0.54; v = 0.25; wide = 1.05; lob = 0.56; wave = 0.90; rough = 1.62 },
  @{ n = 'napa_cabbage'; h = 78.0;  s = 0.48; v = 0.47; wide = 1.12; lob = 0.20; wave = 1.10; rough = 0.90 },
  @{ n = 'broccoli';     h = 108.0; s = 0.54; v = 0.25; wide = 0.85; lob = 0.36; wave = 0.95; rough = 1.20; curd = $true; ch = 108.0; cs = 0.48; cv = 0.23 },
  @{ n = 'cauliflower';  h = 90.0;  s = 0.48; v = 0.33; wide = 0.88; lob = 0.32; wave = 0.95; rough = 1.20; curd = $true; ch = 58.0; cs = 0.06; cv = 0.84 }
)
$made = 0
for ($i = 0; $i -lt $species.Count; $i++) {
  $sp = $species[$i]
  for ($a = 0; $a -lt 6; $a++) {
    Save-Bmp (Render-LeafStrip -Hue $sp.h -Sat $sp.s -Val $sp.v -Age $a -Seed ($i + 1) -Wide $sp.wide -Lob $sp.lob -Wave $sp.wave) ($sp.n + '_leafball_' + $a)
    $made++
  }
  if ($sp.curd) { Save-Bmp (Render-Head -Hue $sp.h -Sat $sp.s -Val $sp.v -Seed ($i + 1) -Rough $sp.rough -Curd -CurdH $sp.ch -CurdS $sp.cs -CurdV $sp.cv) ($sp.n + '_leafball_head') }
  else { Save-Bmp (Render-Head -Hue $sp.h -Sat $sp.s -Val $sp.v -Seed ($i + 1) -Rough $sp.rough) ($sp.n + '_leafball_head') }
  $made++
}
for ($a = 0; $a -lt 6; $a++) {
  Save-Bmp (Render-LeafStrip -Hue 78.0 -Sat 0.60 -Val 0.52 -Age $a -Seed 13) ('leafball_' + $a)
  $made++
}
Save-Bmp (Render-Head -Hue 78.0 -Sat 0.60 -Val 0.52 -Seed 13) 'leafball_head'
$made++
Write-Output ('generated ' + $made + ' textures')



