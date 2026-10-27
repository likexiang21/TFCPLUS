# ============================================================
# gen-seed-textures.ps1 —— 种子图标重绘（照 TFC 原版种子的画法）
# ============================================================
# 学习依据：从 TFC jar 提取 30 张原版种子贴图（.probe/skill-review/tfc-seeds/atlas.png）后归纳：
#   · 3~6 颗**彼此分开**的小颗粒（不是挤成一团）；
#   · 每颗自带左上高光 + 右下暗面 + 一圈深色描边；
#   · 颗粒是 2~3 px 宽、3~4 px 高的**长椭球**，朝向略有差异；
#   · 画面留白多，颜色与作物同色系。
# 配色来源：**读现有种子贴图的平均色**当基色（保持物种色系不变），只改画法。
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot '..\src\main\resources'
$dir = Join-Path $root 'assets/tfcfarmingplus/textures/item/seeds'
$bak = Join-Path $PSScriptRoot '..\..\..\.probe\skill-review\seeds-old'
if (-not (Test-Path $bak)) { New-Item -ItemType Directory -Force -Path $bak | Out-Null }

function Get-AverageColor([string]$p) {
    $bmp = New-Object System.Drawing.Bitmap($p)
    $rs = 0; $gs = 0; $bs = 0; $n = 0
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $c = $bmp.GetPixel($x, $y)
            if ($c.A -lt 128) { continue }
            $rs += $c.R; $gs += $c.G; $bs += $c.B; $n++
        }
    }
    $bmp.Dispose()
    if ($n -eq 0) { return @(140, 120, 80) }
    return @([int]($rs / $n), [int]($gs / $n), [int]($bs / $n))
}

# 五颗种子的落点（彼此分开，留白）与朝向偏移
function Get-Spots([string]$name) {
    $seedNum = 0
    foreach ($ch in $name.ToCharArray()) { $seedNum = ($seedNum * 31 + [int]$ch) % 1000003 }
    $rnd = New-Object System.Random($seedNum)
    $count = 3 + $rnd.Next(0, 4)          # 3~6 颗
    $spots = @()
    $tries = 0
    while ($spots.Count -lt $count -and $tries -lt 80) {
        $tries++
        $cx = 3.5 + $rnd.NextDouble() * 9.0
        $cy = 3.5 + $rnd.NextDouble() * 9.0
        $ok = $true
        foreach ($s in $spots) { if ([Math]::Sqrt([Math]::Pow($cx - $s.cx, 2) + [Math]::Pow($cy - $s.cy, 2)) -lt 3.4) { $ok = $false; break } }
        if ($ok) { $spots += @{ cx = $cx; cy = $cy; w = 1.30 + $rnd.NextDouble() * 0.35; h = 2.00 + $rnd.NextDouble() * 0.55 } }
    }
    return $spots
}

function Draw-SeedSet([string]$out, [int]$cr, [int]$cg, [int]$cb, [string]$name) {
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $k = 0
    $spots = Get-Spots $name
    foreach ($s in $spots) {
        $k++
        $tone = 1.0 + 0.13 * [Math]::Sin($k * 2.7)
        for ($y = 0; $y -lt 16; $y++) {
            for ($x = 0; $x -lt 16; $x++) {
                $dx = ($x + 0.5 - $s.cx) / $s.w
                $dy = ($y + 0.5 - $s.cy) / $s.h
                $d2 = $dx * $dx + $dy * $dy
                if ($d2 -gt 1.0) { continue }
                # 立体：左上亮、右下暗；最外圈做描边
                $shade = 1.20 - 0.42 * (($dx + 1.0) / 2.0) - 0.30 * (($dy + 1.0) / 2.0)
                if ($d2 -gt 0.72) { $shade = $shade * 0.60 }
                $r = [Math]::Max(0, [Math]::Min(255, [int]($cr * $shade * $tone)))
                $g = [Math]::Max(0, [Math]::Min(255, [int]($cg * $shade * $tone)))
                $b = [Math]::Max(0, [Math]::Min(255, [int]($cb * $shade * $tone)))
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
            }
        }
    }
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

$files = Get-ChildItem $dir -File -Filter '*.png' | Sort-Object Name
Write-Output ('seed textures: ' + $files.Count)
foreach ($f in $files) {
    Copy-Item $f.FullName (Join-Path $bak $f.Name) -Force
    $avg = Get-AverageColor $f.FullName
    Draw-SeedSet $f.FullName $avg[0] $avg[1] $avg[2] $f.BaseName
}
Write-Output 'seed icons redrawn'