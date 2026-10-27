
param([string]$Out)
Add-Type -AssemblyName System.Drawing
$root = Join-Path $env:TFC_TOOLS_ROOT '..\src\main\resources'
$outDir = Join-Path $root 'assets/tfcfarmingplus/textures/block/crop'
$bak = Join-Path $env:TFC_TOOLS_ROOT '..\..\..\.probe\skill-review\crop-old'
if (-not (Test-Path $bak)) { New-Item -ItemType Directory -Path $bak -Force | Out-Null }

function H01([double]$na, [double]$nb) { $hx = [Math]::Sin($na * 12.9898 + $nb * 78.233) * 43758.5453; return ($hx - [Math]::Floor($hx)) }

function Draw-MelonSkin {
  param([string]$Name, [int]$br, [int]$bg, [int]$bb, [string]$Style, [int]$ar, [int]$ag, [int]$ab, [double]$Seed)
  $bmp = New-Object System.Drawing.Bitmap(16, 16)
  for ($y = 0; $y -lt 16; $y++) {
    for ($x = 0; $x -lt 16; $x++) {
      $fx = ($x + 0.5 - 7.5) / 8.2
      $k = 1.02 - 0.34 * $fx * $fx
      $k *= (0.93 + 0.14 * (H01 ($x * 3.1) ($y * 2.7 + $Seed)))
      $k *= (0.90 + 0.14 * ($y / 15.0))
      $r = $br * $k; $g = $bg * $k; $b = $bb * $k
      if ($Style -eq 'stripe') {
        $s = [Math]::Sin($x * 1.05 + $Seed)
        if ($s -gt 0.68) {
          $t = 0.55 + 0.35 * $s
          $r = $r * (1 - $t) + $ar * $k * $t
          $g = $g * (1 - $t) + $ag * $k * $t
          $b = $b * (1 - $t) + $ab * $k * $t
        }
      }
      elseif ($Style -eq 'net') {
        $n1 = [Math]::Sin($x * 1.85 + $y * 0.62 + $Seed)
        $n2 = [Math]::Sin($x * 0.58 - $y * 2.05 + $Seed * 1.7)
        if ($n1 -gt 0.86 -or $n2 -gt 0.88) {
          $r = $ar * $k; $g = $ag * $k; $b = $ab * $k
        }
      }
      elseif ($Style -eq 'bloom') {
        $bl = H01 ($x * 2.3) ($y * 1.7 + $Seed)
        if ($y -lt 12 -and $bl -gt 0.52) {
          $t = 0.30 + 0.50 * ($bl - 0.52) / 0.48
          $r = $r * (1 - $t) + $ar * $k * $t
          $g = $g * (1 - $t) + $ag * $k * $t
          $b = $b * (1 - $t) + $ab * $k * $t
        }
      }
      $rr = [int][Math]::Round($r); if ($rr -lt 0) { $rr = 0 }; if ($rr -gt 255) { $rr = 255 }
      $gg = [int][Math]::Round($g); if ($gg -lt 0) { $gg = 0 }; if ($gg -gt 255) { $gg = 255 }
      $bbb = [int][Math]::Round($b); if ($bbb -lt 0) { $bbb = 0 }; if ($bbb -gt 255) { $bbb = 255 }
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $rr, $gg, $bbb))
    }
  }
  $p = Join-Path $outDir ($Name + '.png')
  if ((Test-Path $p) -and -not (Test-Path (Join-Path $bak ($Name + '.png')))) { Copy-Item $p (Join-Path $bak ($Name + '.png')) -Force }
  $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

Draw-MelonSkin 'bottle_gourd_side' 168 192 112 'stripe' 206 224 168 3.1
Draw-MelonSkin 'cantaloupe_side' 200 168 112 'net' 236 224 196 5.7
Draw-MelonSkin 'winter_melon_side' 74 107 60 'bloom' 200 212 192 8.3
Write-Output 'melon skins drawn: 3'

