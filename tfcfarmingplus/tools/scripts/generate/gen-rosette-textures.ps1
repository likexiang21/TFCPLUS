
param([string]$Out)
# Historical procedural recipe retained for traceability; current artwork must not be overwritten.
throw 'Historical procedural rosette texture generation is retired. Use per-asset artwork review; this script writes nothing.'
Add-Type -AssemblyName System.Drawing
$root = Join-Path $env:TFC_TOOLS_ROOT '..\src\main\resources'
$outDir = Join-Path $root 'assets/tfcfarmingplus/textures/block/crop'
$bak = Join-Path $env:TFC_TOOLS_ROOT '..\..\..\.probe\skill-review\rosette-old'
if (-not (Test-Path $bak)) { New-Item -ItemType Directory -Path $bak -Force | Out-Null }

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

function Ros-Leaf {
  param([double]$Hue, [double]$Sat, [double]$Val, [int]$Age, [int]$Seed,
        [double]$Wide = 1.0, [double]$Lob = 0.30, [double]$Wave = 0.85, [double]$Dry = 0.0)
  $bmp = New-Object System.Drawing.Bitmap(16, 16)
  $len = @(4, 6, 8, 10, 13, 16)[$Age]
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
      $cx = 2.0 + 0.90 * [math]::Sin($tt * 3.4 + $phase)
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
        if ($Dry -gt 0.0) {
          $lum = ($cc[0] * 0.2126 + $cc[1] * 0.7152 + $cc[2] * 0.0722) / 255.0
          $dr = [int][math]::Round((1.0 - $Dry) * $cc[0] + $Dry * (110 + 130 * $lum))
          $dg = [int][math]::Round((1.0 - $Dry) * $cc[1] + $Dry * (86 + 110 * $lum))
          $db = [int][math]::Round((1.0 - $Dry) * $cc[2] + $Dry * (30 + 46 * $lum))
          $cc = @($dr, $dg, $db)
        }
        $bmp.SetPixel(($k * 4 + $u), $v, [System.Drawing.Color]::FromArgb(255, $cc[0], $cc[1], $cc[2]))
      }
    }
  }
  return $bmp
}

function Ros-Fruit {
  param([double]$Hue, [double]$Sat, [double]$Val, [int]$Seed = 1)
  $bmp = New-Object System.Drawing.Bitmap(16, 16)
  for ($y = 0; $y -lt 16; $y++) {
    for ($x = 0; $x -lt 16; $x++) {
      $nx = ($x + 0.5 - 7.6) / 5.4
      $ny = ($y + 0.5 - 7.9) / 6.0
      $d = [math]::Sqrt($nx * $nx + $ny * $ny)
      $th = [math]::Atan2($ny, $nx)
      $edge = 1.0 + 0.09 * [math]::Sin(3 * $th + 0.7 + $Seed) + 0.06 * [math]::Sin(5 * $th + 2.1) + 0.04 * [math]::Sin(9 * $th + 0.9 * $Seed)
      if ($d -gt $edge) { continue }
      $n1 = Hash01 $x $y $Seed
      $rim = Clamp01 (($edge - $d) / 0.22)
      $shade = 0.34 + 0.66 * [math]::Pow($rim, 0.60)
      $shade *= (1.0 + 0.48 * (-$nx * 0.42 - $ny * 0.68))
      $shade *= (0.80 + 0.24 * (Clamp01 (1.05 - $d)))
      $shade *= (0.86 + 0.26 * $n1)
      $cc = Hue2Rgb ($Hue + 3.0 * (0.5 - $n1)) (Clamp01 ($Sat + 0.06 * ($n1 - 0.5))) (Clamp01 ($Val * $shade))
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $cc[0], $cc[1], $cc[2]))
    }
  }
  return $bmp
}

function Save-Bmp($bmp, [string]$name) {
  $p = Join-Path $outDir ($name + '.png')
  if ((Test-Path $p) -and -not (Test-Path (Join-Path $bak ($name + '.png')))) { Copy-Item $p (Join-Path $bak ($name + '.png')) -Force }
  $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

$sp = @(
  @{ n = 'agave_rosette';    hh = 100.0; ss = 0.26; vv = 0.46; wd = 1.10; lb = 0.16; wv = 1.30; fh = 92.0;  fs = 0.28; fv = 0.40 },
  @{ n = 'cardoon_rosette';  hh = 88.0;  ss = 0.38; vv = 0.36; wd = 1.00; lb = 0.48; wv = 1.05; fh = 94.0;  fs = 0.32; fv = 0.32 },
  @{ n = 'purslane_rosette'; hh = 92.0;  ss = 0.52; vv = 0.46; wd = 0.92; lb = 0.30; wv = 0.88; fh = 78.0;  fs = 0.46; fv = 0.50 },
  @{ n = 'rosette';          hh = 94.0;  ss = 0.40; vv = 0.42; wd = 1.00; lb = 0.32; wv = 1.00; fh = 88.0;  fs = 0.34; fv = 0.44 }
)
$count = 0
for ($i = 0; $i -lt $sp.Count; $i++) {
  $q = $sp[$i]
  for ($a = 0; $a -lt 6; $a++) {
    Save-Bmp (Ros-Leaf -Hue $q.hh -Sat $q.ss -Val $q.vv -Age $a -Seed ($i + 1) -Wide $q.wd -Lob $q.lb -Wave $q.wv) ($q.n + '_' + $a)
    $count++
  }
  $fb = Ros-Leaf -Hue $q.hh -Sat $q.ss -Val $q.vv -Age 5 -Seed ($i + 1) -Wide $q.wd -Lob $q.lb -Wave $q.wv
  $fr2 = Ros-Fruit -Hue $q.fh -Sat $q.fs -Val $q.fv -Seed ($i + 7)
  for ($yy = 5; $yy -le 11; $yy++) {
    for ($xx = 5; $xx -le 11; $xx++) {
      $pc = $fr2.GetPixel($xx, $yy)
      if ($pc.A -gt 0) { $fb.SetPixel($xx, $yy, $pc) }
    }
  }
  $fr2.Dispose()
  Save-Bmp $fb ($q.n + '_5_fruiting')
  $count++
  Save-Bmp (Ros-Fruit -Hue $q.fh -Sat $q.fs -Val $q.fv -Seed ($i + 7)) ($q.n + '_fruit')
  $count++
}
Save-Bmp (Ros-Leaf -Hue 94.0 -Sat 0.40 -Val 0.42 -Age 5 -Seed 21 -Dry 1.0) 'rosette_dead'
Save-Bmp (Ros-Leaf -Hue 94.0 -Sat 0.40 -Val 0.42 -Age 1 -Seed 21 -Dry 0.85) 'rosette_dead_young'
$count += 2
Write-Output ('rosette textures drawn: ' + $count)
$chk = New-Object System.Drawing.Bitmap((Join-Path $outDir 'agave_rosette_5.png'))
Write-Output ('probe agave_rosette_5 px(0,15)=' + $chk.GetPixel(0,15).R + ',' + $chk.GetPixel(0,15).G + ',' + $chk.GetPixel(0,15).B + '  px(1,10)=' + $chk.GetPixel(1,10).R + ',' + $chk.GetPixel(1,10).G + ',' + $chk.GetPixel(1,10).B)
$chk.Dispose()


