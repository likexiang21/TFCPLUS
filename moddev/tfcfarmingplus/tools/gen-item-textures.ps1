# ============================================================
# gen-item-textures.ps1 —— 物品图标重绘（第二版：照 TFC 原版物品的画法）
# ============================================================
# 第一版被用户判为「很失败」，并给了明确方法：**先读 TFC 对应的原版物品贴图，学习怎么画**。
# 从 TFC jar 提取 32 张原版食物图标（.probe/skill-review/tfc-items/tfc-items-atlas.png）后，
# 归纳出的画法要点（本脚本逐条落实）：
#   1. 主体占满画面 ~80%（圆形果实直径约 12~13 px，不是小小一颗）；
#   2. 最外一圈是**深色描边**（约主色 × 0.5），保证在任何背景上都可辨；
#   3. 立体感 = 左上亮面 + 右下暗面 + 一个**明确的小亮斑高光**（接近白，2~3 px）；
#   4. 顶部有**果柄**（棕色 2~3 px）与 1~2 片**小叶**（绿色，带描边）；
#   5. 叶菜不是几根草，而是「外叶张开 + 内叶层叠成球」（TFC cabbage 的画法）；
#   6. 配色明亮饱和适中，主体色比背景亮一档。
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot '..\src\main\resources'
$NS = 'tfcfarmingplus'
$outDir = Join-Path $root ("assets/$NS/textures/item/food")
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

function Set-Px($bmp, [int]$x, [int]$y, [int]$cr, [int]$cg, [int]$cb, [double]$k) {
    if ($x -lt 0 -or $x -gt 15 -or $y -lt 0 -or $y -gt 15) { return }
    $r = [Math]::Max(0, [Math]::Min(255, [int]($cr * $k)))
    $g = [Math]::Max(0, [Math]::Min(255, [int]($cg * $k)))
    $b = [Math]::Max(0, [Math]::Min(255, [int]($cb * $k)))
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
}
function Save-Tex($bmp, [string]$name) {
    $bmp.Save((Join-Path $outDir ($name + '.png')), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# --- 圆形果实（TFC 风格：近满幅 + 描边 + 亮斑 + 果柄小叶） ---
function Draw-Berry([string]$name, [int]$cr, [int]$cg, [int]$cb, [double]$rx, [double]$ry, [int]$stem) {
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $cx = 7.8; $cy = 8.9
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = ($x + 0.5 - $cx) / $rx
            $dy = ($y + 0.5 - $cy) / $ry
            $d2 = $dx * $dx + $dy * $dy
            if ($d2 -gt 1.0) { continue }
            $nz = [Math]::Sqrt(1.0 - $d2)
            $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.55 + $nz * 0.72)
            $k = 0.52 + 0.80 * $nl
            if ($d2 -gt 0.82) { $k = $k * 0.52 }                    # 深色描边圈
            elseif ($d2 -gt 0.68) { $k = $k * 0.82 }                # 过渡暗面
            $hx = $x + 0.5 - ($cx - $rx * 0.34); $hy = $y + 0.5 - ($cy - $ry * 0.40)
            if (($hx * $hx + $hy * $hy) -lt 2.4) { $k = $k + 0.60 }  # 亮斑高光
            Set-Px $bmp $x $y $cr $cg $cb $k
        }
    }
    if ($stem -eq 1) {
        Set-Px $bmp 7 3 92 68 38 1.0; Set-Px $bmp 8 3 92 68 38 1.0
        Set-Px $bmp 8 4 92 68 38 1.0; Set-Px $bmp 7 4 76 56 32 1.0
        foreach ($p in @(@(9,4),@(10,4),@(9,5),@(10,5),@(11,5),@(10,6))) { Set-Px $bmp $p[0] $p[1] 96 138 62 1.05 }
        foreach ($p in @(@(9,6),@(11,6),@(12,5))) { Set-Px $bmp $p[0] $p[1] 74 108 50 1.0 }
    }
    Save-Tex $bmp $name
}

# --- 叶菜（TFC cabbage 画法：外叶张开 + 内叶层叠成球） ---
function Draw-Leafy([string]$name, [int]$cr, [int]$cg, [int]$cb, [int]$hr, [int]$hg, [int]$hb) {
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $baseX = 7.8; $baseY = 13.5
    for ($i = 0; $i -lt 5; $i++) {
        $frac = ($i - 2) / 2.0
        $ang = $frac * 0.86
        $len = 9.5 - [Math]::Abs($frac) * 1.6
        for ($r = 1.0; $r -lt $len; $r += 0.5) {
            $wHalf = 1.5 - 0.09 * $r
            $x0 = $baseX + [Math]::Sin($ang) * $r
            $y0 = $baseY - [Math]::Cos($ang) * $r
            for ($o = -$wHalf; $o -le $wHalf; $o += 0.5) {
                $x = [int][Math]::Round($x0 + [Math]::Cos($ang) * $o - 0.5)
                $y = [int][Math]::Round($y0 + [Math]::Sin($ang) * $o - 0.5)
                $k = 1.14 - 0.022 * $r
                if ([Math]::Abs($o) -gt ($wHalf - 0.5)) { $k = $k * 0.66 }
                Set-Px $bmp $x $y $cr $cg $cb $k
            }
        }
    }
    for ($y = 3; $y -le 12; $y++) {
        for ($x = 3; $x -le 12; $x++) {
            $dx = ($x + 0.5 - 8.0) / 4.6; $dy = ($y + 0.5 - 8.2) / 4.8
            $d2 = $dx * $dx + $dy * $dy
            if ($d2 -gt 1.0) { continue }
            $nz = [Math]::Sqrt(1.0 - $d2)
            $nl = [Math]::Max(0.0, $dx * -0.45 + $dy * -0.55 + $nz * 0.70)
            $k = 0.58 + 0.78 * $nl
            if ($d2 -gt 0.84) { $k = $k * 0.60 }
            $rings = 1.0 + 0.10 * [Math]::Sin(($y + 0.5) * 1.4)      # 层叠叶纹
            Set-Px $bmp $x $y $hr $hg $hb ($k * $rings)
        }
    }
    Save-Tex $bmp $name
}

# --- 莲座：中心紧凑 + 放射尖叶（多肉植物的画法） ---
function Draw-RosetteItem([string]$name, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    for ($i = 0; $i -lt 9; $i++) {
        $ang = ($i / 9.0) * [Math]::PI * 2.0 - [Math]::PI / 2.0
        $len = 6.2 + 0.9 * [Math]::Sin($i * 2.1)
        for ($r = 1.2; $r -lt $len; $r += 0.5) {
            $wHalf = 1.1 - 0.11 * $r
            $x0 = 7.8 + [Math]::Cos($ang) * $r
            $y0 = 8.8 + [Math]::Sin($ang) * $r * 0.9
            for ($o = -$wHalf; $o -le $wHalf; $o += 0.5) {
                $x = [int][Math]::Round($x0 - [Math]::Sin($ang) * $o - 0.5)
                $y = [int][Math]::Round($y0 + [Math]::Cos($ang) * $o - 0.5)
                $k = 1.16 - 0.045 * $r
                if ([Math]::Abs($o) -gt ($wHalf - 0.4)) { $k = $k * 0.70 }
                Set-Px $bmp $x $y $cr $cg $cb $k
            }
        }
    }
    foreach ($p in @(@(7,8),@(8,8),@(7,9),@(8,9))) { Set-Px $bmp $p[0] $p[1] $cr $cg $cb 1.35 }
    Save-Tex $bmp $name
}

# ---------------- 果实（枝干结果的 6 种） ----------------
Draw-Berry 'jabuticaba' 62 52 84   6.0 6.2 1
Draw-Berry 'soursop'    108 150 76 6.2 6.4 1
Draw-Berry 'mangosteen' 124 62 74  6.0 6.1 1
Draw-Berry 'cupuacu'    156 118 70 5.7 6.6 1
Draw-Berry 'bael'       176 152 76 6.0 6.2 1
Draw-Berry 'canistel'   206 168 76 5.6 6.6 1
Write-Host '果实图标（6）完成'

# ---------------- 叶菜（5 种） ----------------
Draw-Leafy 'lettuce'      132 184 88 206 228 152
Draw-Leafy 'cauliflower'  104 156 80 236 240 220
Draw-Leafy 'broccoli'      74 126 66 100 158 88
Draw-Leafy 'kale'          70 112 74  96 140 100
Draw-Leafy 'napa_cabbage' 124 172 96 222 232 186
Write-Host '叶菜图标（5）完成'

# ---------------- 莲座（3 种） ----------------
Draw-RosetteItem 'cardoon'  108 138 72
Draw-RosetteItem 'agave'    146 174 88
Draw-RosetteItem 'purslane' 156 138 76
Write-Host '莲座图标（3）完成'
Write-Output 'done'