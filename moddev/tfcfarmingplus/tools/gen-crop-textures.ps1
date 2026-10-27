# ============================================================
# gen-crop-textures.ps1 —— 作物**方块**贴图重绘（第一版：叶菜类）
# ============================================================
# 用户要求（2026-09-23）：
#   ① 学习并对比 TFC 原版贴图的配色与风格；② 必须反映现实原型；③ **不要用简单几何图形和色块**。
#
# 对 TFC 原版贴图的量化画像（实测，16x16 物品图标）：
#   cabbage 126 种颜色 / 明度 51~217（跨度 166）/ sd 39.1
#   orange   85 种颜色 / 明度 61~230（跨度 169）/ sd 39.9
#   cherry    9 种颜色 / 明度 16~161（跨度 145）/ sd 48.7
#   ⇒ TFC 的共同点是**明度跨度极大、颜色层次极多**（不是均匀渐变）。
#   本脚本据此设计三层着色：大尺度光照 + 中尺度纹理（叶脉/噪声）+ 小尺度抖动，
#   并把明暗对比拉到 0.5~1.5 倍区间，力求颜色数进入 60~120 档。
#
# 产出：assets/tfcfarmingplus/textures/block/crop/<n>_<age>.png（覆盖现有 donor 变色版）
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot '..\src\main\resources'
$NS = 'tfcfarmingplus'
$outDir = Join-Path $root ("assets/$NS/textures/block/crop")
$bak = Join-Path $PSScriptRoot '..\..\..\.probe\skill-review\crop-old'
if (-not (Test-Path $bak)) { New-Item -ItemType Directory -Force -Path $bak | Out-Null }

function Set-Px($bmp, [int]$x, [int]$y, [int]$cr, [int]$cg, [int]$cb, [double]$k) {
    if ($x -lt 0 -or $x -gt 15 -or $y -lt 0 -or $y -gt 15) { return }
    if ($k -lt 0) { $k = 0 }
    $r = [Math]::Max(0, [Math]::Min(255, [int]($cr * $k)))
    $g = [Math]::Max(0, [Math]::Min(255, [int]($cg * $k)))
    $b = [Math]::Max(0, [Math]::Min(255, [int]($cb * $k)))
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
}

# 画一片叶：沿参数曲线铺像素，带中脉亮线 + 边缘压暗 + 噪声
function Draw-Leaf($bmp, [double]$cx, [double]$cy, [double]$ang, [double]$len, [double]$wid,
                   [int]$cr, [int]$cg, [int]$cb, [double]$seed, [double]$lift) {
    for ($t = 0.0; $t -le 1.0; $t += 0.015) {
        # 叶形：基部窄 → 中段宽 → 尖端收窄（现实叶片轮廓）
        $w = $wid * [Math]::Sin([Math]::PI * (0.12 + 0.88 * $t)) * (1.0 - 0.15 * $t)
        if ($w -lt 0.25) { continue }
        $px0 = $cx + [Math]::Cos($ang) * $len * $t
        $py0 = $cy + [Math]::Sin($ang) * $len * $t
        # 叶身弯曲（现实叶片不是直线）
        $bend = [Math]::Sin($t * 1.9 + $seed) * 0.9
        $px0 = $px0 - [Math]::Sin($ang) * $bend
        $py0 = $py0 + [Math]::Cos($ang) * $bend
        for ($o = -$w; $o -le $w; $o += 0.35) {
            $px = $px0 - [Math]::Sin($ang) * $o
            $py = $py0 + [Math]::Cos($ang) * $o
            $rel = [Math]::Abs($o) / $w
            # 大尺度：叶面受光（左上亮）
            $shade = 1.32 - 0.62 * $rel * $rel
            # 中尺度：中脉 + 侧脉
            if ([Math]::Abs($o) -lt 0.30) { $shade = 1.52 }
            elseif ((($o + 0.15) % 1.1) -lt 0.30) { $shade = $shade * 1.06 }
            # 小尺度：噪声抖动（制造几十种颜色）
            $n = 1.0 + 0.10 * [Math]::Sin($seed * 3.1 + $px * 2.7 + $py * 1.9)
            $shade = $shade * $n * $lift
            Set-Px $bmp ([int][Math]::Round($px)) ([int][Math]::Round($py)) $cr $cg $cb $shade
        }
    }
}

# 叶菜类：按阶段画「幼苗 → 叶丛 → 结球」
function Draw-LeafyCrop($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [int]$hr, [int]$hg, [int]$hb, [double]$seed) {
    $leafCount = 2 + $age                       # 0→2 片，5→7 片
    $leafLen = 2.4 + $age * 1.25
    $leafWid = 0.9 + $age * 0.16
    $baseX = 7.6; $baseY = 13.4
    for ($i = 0; $i -lt $leafCount; $i++) {
        $frac = ($i - ($leafCount - 1) / 2.0) / [Math]::Max(1.0, ($leafCount - 1) / 2.0)
        $ang = -[Math]::PI / 2.0 + $frac * (0.55 + 0.10 * $age)   # 向上张开
        $len = $leafLen * (1.0 - 0.18 * [Math]::Abs($frac))
        # 外层叶用叶色、越靠中心越用球色
        $isInner = ([Math]::Abs($frac) -lt 0.34 -and $age -ge 3)
        $rr = if ($isInner) { $hr } else { $cr }
        $gg = if ($isInner) { $hg } else { $cg }
        $bb = if ($isInner) { $hb } else { $cb }
        Draw-Leaf $bmp ($baseX + $frac * 1.1) $baseY $ang $len $leafWid $rr $gg $bb ($seed + $i * 1.7) 1.0
    }
    # age>=3：中心叶球（多层弧，越里面越亮）
    if ($age -ge 3) {
        $rad = 1.6 + ($age - 3) * 1.15
        for ($y = 0; $y -lt 16; $y++) {
            for ($x = 0; $x -lt 16; $x++) {
                $dx = ($x + 0.5 - 7.6) / $rad; $dy = ($y + 0.5 - (9.6 - $rad)) / ($rad * 1.05)
                $d2 = $dx * $dx + $dy * $dy
                if ($d2 -gt 1.0) { continue }
                $nz = [Math]::Sqrt(1.0 - $d2)
                $nl = [Math]::Max(0.0, $dx * -0.45 + $dy * -0.55 + $nz * 0.70)
                $k = 0.62 + 0.85 * $nl
                $ring = 1.0 + 0.10 * [Math]::Sin(($y + 0.5) * 2.1)      # 层叠叶纹
                $n2 = 1.0 + 0.08 * [Math]::Sin($seed + $x * 2.3 + $y * 1.7)
                Set-Px $bmp $x $y $hr $hg $hb ($k * $ring * $n2)
            }
        }
    }
}

# 作物表（第一版只做叶菜，验证画法后再推广）
$crops = @(
    [ordered]@{ n = 'lettuce';      r = 118; g = 172; b = 74;  hr = 178; hg = 212; hb = 128 },
    [ordered]@{ n = 'cabbage';      r = 86;  g = 138; b = 62;  hr = 148; hg = 186; hb = 118 },
    [ordered]@{ n = 'broccoli';     r = 66;  g = 114; b = 56;  hr = 88;  hg = 142; hb = 74 },
    [ordered]@{ n = 'cauliflower';  r = 92;  g = 142; b = 68;  hr = 226; hg = 230; hb = 206 },
    [ordered]@{ n = 'kale';         r = 62;  g = 102; b = 62;  hr = 86;  hg = 128; hb = 88 },
    [ordered]@{ n = 'napa_cabbage'; r = 110; g = 162; b = 84;  hr = 206; hg = 220; hb = 176 }
)

$done = 0
foreach ($c in $crops) {
    for ($age = 0; $age -le 5; $age++) {
        $p = Join-Path $outDir ($c.n + '_' + $age + '.png')
        if (Test-Path $p) { Copy-Item $p (Join-Path $bak ($c.n + '_' + $age + '.png')) -Force }
        $bmp = New-Object System.Drawing.Bitmap(16, 16)
        Draw-LeafyCrop $bmp $age $c.r $c.g $c.b $c.hr $c.hg $c.hb ($c.n.Length * 1.3)
        $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        $done++
    }
}
Write-Output ('crop block textures redrawn (leafy): ' + $done)
# ============================================================
# 第二部分：把「三层着色 + 曲线叶片」画法推广到全部作物类别
#   root 根菜：叶丛 + age>=3 露出根肩；fruitveg 果菜：植株 + 挂果；
#   grain 谷物：草叶 -> 秸秆 + 穗；legume 豆类：藤叶 + 荚；herb 香草：细密叶丛
# 颜色取自旧贴图平均色（保持物种色系），形状与纹理全部重画。
# ============================================================
function Get-Avg([string]$p) {
    # 取「主色」：把颜色量化到 24 级桶后取最高频桶的中心色，再提升饱和度。
    # 平均色会把暗部与背景混进来 ⇒ 得到浑浊的中间色（用户批「颜色使用极其失败」）。
    $bmp = New-Object System.Drawing.Bitmap($p)
    $h = @{}
    for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) {
        $c = $bmp.GetPixel($x, $y); if ($c.A -lt 8) { continue }
        $qr = [int]($c.R / 24); $qg = [int]($c.G / 24); $qb = [int]($c.B / 24)
        $key = "$qr-$qg-$qb"
        if ($h.ContainsKey($key)) { $h[$key][0] += 1; $h[$key][1] += $c.R; $h[$key][2] += $c.G; $h[$key][3] += $c.B }
        else { $h[$key] = @(1, $c.R, $c.G, $c.B) }
    } }
    $bmp.Dispose()
    if ($h.Count -eq 0) { return @(110, 150, 80) }
    $best = $null; $bestN = -1
    foreach ($k in $h.Keys) { if ($h[$k][0] -gt $bestN) { $bestN = $h[$k][0]; $best = $h[$k] } }
    $r = [int]($best[1] / $best[0]); $g = [int]($best[2] / $best[0]); $b = [int]($best[3] / $best[0])
    # 饱和度提升 1.5 倍（向远离灰色轴的方向推）
    $avg = ($r + $g + $b) / 3.0
    $r = [Math]::Max(0, [Math]::Min(255, [int]($avg + ($r - $avg) * 1.50)))
    $g = [Math]::Max(0, [Math]::Min(255, [int]($avg + ($g - $avg) * 1.50)))
    $b = [Math]::Max(0, [Math]::Min(255, [int]($avg + ($b - $avg) * 1.50)))
    return @($r, $g, $b)
}
function Get-Kind([string]$n) {
    if ($n -match 'carrot|beet|radish|turnip|onion|garlic|potato|cassava|yam|parsnip|rutabaga|ginger|turmeric|arrowhead|water_chestnut|taro|jicama|burdock|horseradish|salsify|celeriac|chicory_root') { return 'root' }
    if ($n -match 'tomato|pepper|chili|eggplant|chayote|okra|cucumber|zucchini|tomatillo|melon|gourd|squash|pumpkin') { return 'fruitveg' }
    if ($n -match 'wheat|barley|oat|rye|rice|maize|sorghum|millet|fonio|einkorn|emmer|spelt|teff|quinoa|amaranth|buckwheat|jobs_tears|canola|sesame|safflower') { return 'grain' }
    if ($n -match 'bean|pea|chickpea|lentil|soybean|peanut|adzuki|faba|fenugreek|gram|bambara') { return 'legume' }
    if ($n -match 'lettuce|cabbage|broccoli|cauliflower|kale|brussels') { return 'leafy' }
    return 'herb'
}
function Draw-Rosetted($bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [double]$seed, [double]$spread, [double]$wid) {
    $cnt = 2 + $age
    for ($i = 0; $i -lt $cnt; $i++) {
        $frac = ($i - ($cnt - 1) / 2.0) / [Math]::Max(1.0, ($cnt - 1) / 2.0)
        $ang = -[Math]::PI / 2.0 + $frac * $spread
        $len = (2.2 + $age * 1.15) * (1.0 - 0.16 * [Math]::Abs($frac))
        Draw-Leaf $bmp (7.6 + $frac * 0.9) 13.4 $ang $len $wid $cr $cg $cb ($seed + $i * 1.9) 1.0
    }
}
function Draw-Crop([string]$kind, $bmp, [int]$age, [int]$cr, [int]$cg, [int]$cb, [double]$seed) {
    switch ($kind) {
        'root' {
            Draw-Rosetted $bmp $age $cr $cg $cb $seed 0.95 0.95
            if ($age -ge 3) {   # 根肩：只在叶丛缝隙露出一小圈（用叶色暗调，不用平均色大块）
                $w = 0.9 + 0.35 * ($age - 3)
                for ($y = 13; $y -le 14; $y++) {
                    for ($x = 0; $x -lt 16; $x++) {
                        $dxr = [Math]::Abs($x + 0.5 - 7.6)
                        if ($dxr -gt $w) { continue }
                        $k = (0.78 - 0.16 * $dxr) * (0.98 + 0.06 * [Math]::Sin($seed + $x * 2.2))
                        Set-Px $bmp $x $y $cr $cg $cb $k
                    }
                }
            }
        }
        'herb' { Draw-Rosetted $bmp $age $cr $cg $cb $seed 1.10 0.72 }
        'legume' {
            Draw-Rosetted $bmp $age $cr $cg $cb $seed 1.05 0.80
            if ($age -ge 4) {
                for ($p = 0; $p -lt 3; $p++) {
                    $bx = 5.0 + $p * 2.6; $by = 9.5 - $p * 0.9
                    for ($t = 0.0; $t -le 1.0; $t += 0.05) {
                        $px = $bx + $t * 2.4; $py = $by + $t * 3.0
                        $kk = 1.15 - 0.25 * [Math]::Abs($t - 0.5) * 2.0
                        Set-Px $bmp ([int][Math]::Round($px)) ([int][Math]::Round($py)) $cr $cg $cb $kk
                        Set-Px $bmp ([int][Math]::Round($px) + 1) ([int][Math]::Round($py)) $cr $cg $cb ($kk * 0.86)
                    }
                }
            }
        }
        'fruitveg' {
            Draw-Rosetted $bmp $age $cr $cg $cb $seed 1.00 0.90
            if ($age -ge 4) {
                $n = $age - 3
                foreach ($pos in @(@(4.6,9.4),@(10.6,8.6),@(7.6,11.6))) {
                    if ($n -le 0) { break }
                    for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) {
                        $dx = ($x + 0.5 - $pos[0]) / 2.1; $dy = ($y + 0.5 - $pos[1]) / 2.1
                        $d2 = $dx * $dx + $dy * $dy
                        if ($d2 -gt 1.0) { continue }
                        $nz = [Math]::Sqrt(1.0 - $d2)
                        $nl = [Math]::Max(0.0, $dx * -0.45 + $dy * -0.52 + $nz * 0.72)
                        $k = 0.72 + 0.90 * $nl + 0.06 * [Math]::Sin($seed + $x * 2.1 + $y * 1.6)
                        Set-Px $bmp $x $y $cr $cg $cb $k
                    } }
                    $n--
                }
            }
        }
        'grain' {
            # 依 TFC wheat 的结构：底部丛生 + **3 根连贯的茎**（不是满屏散点）+ 顶部成组颗粒 + 成熟转黄。
            $ripen = [Math]::Max(0, $age - 3) / 2.0
            $cr2 = [Math]::Min(255, [int]($cr * (1.0 + 0.22 * $ripen)))
            $cg2 = [Math]::Min(255, [int]($cg * (1.0 + 0.08 * $ripen)))
            $cb2 = [Math]::Max(0, [int]($cb * (1.0 - 0.45 * $ripen)))
            # 叶基（3 行，实心）
            for ($b = 0; $b -lt 3; $b++) {
                $yy = 15 - $b
                $half = 2.2 + $b * 1.6
                for ($x = 0; $x -lt 16; $x++) {
                    if ([Math]::Abs($x + 0.5 - 7.6) -gt $half) { continue }
                    $kk = 0.80 + 0.10 * [Math]::Sin($seed + $x * 1.9 + $yy)
                    Set-Px $bmp $x $yy $cr2 $cg2 $cb2 $kk
                }
            }
            # 3 根茎：起点固定、微微倒伏，每根连贯到顶
            $stalkX = @(4.2, 7.8, 11.4)
            foreach ($sx0 in $stalkX) {
                $top = 11.5 - $age * 1.75
                $lean = 0.7 * [Math]::Sin($seed + $sx0)
                for ($y = 13; $y -ge [int]$top; $y--) {
                    $xx = [int][Math]::Round($sx0 + $lean * ((13 - $y) * 0.10))
                    $kk = 0.88 + 0.08 * [Math]::Sin($seed + $y * 1.6)
                    Set-Px $bmp $xx $y $cr2 $cg2 $cb2 $kk
                }
                if ($age -ge 2) {
                    # 穗：顶端 3~5 组，每组左右各一颗（成组，不散乱）
                    $np = 1 + [int]($age / 2)
                    for ($k2 = 0; $k2 -lt $np; $k2++) {
                        $yy = [int]($top - $k2)
                        $xx = [int][Math]::Round($sx0 + $lean * ((13 - $yy) * 0.10))
                        Set-Px $bmp ($xx - 1) $yy $cr2 $cg2 $cb2 1.42
                        Set-Px $bmp ($xx + 1) ($yy - 1) $cr2 $cg2 $cb2 1.30
                    }
                    $yy = [int]($top - $np)
                    $xx = [int][Math]::Round($sx0 + $lean * ((13 - $yy) * 0.10))
                    Set-Px $bmp $xx $yy $cr2 $cg2 $cb2 1.18
                }
            }
        }
        default { Draw-LeafyCrop $bmp $age $cr $cg $cb ([int]($cr * 1.35)) ([int]($cg * 1.28)) ([int]($cb * 1.45)) $seed }
    }
}
$all = Get-ChildItem $outDir -File -Filter '*_5.png' | ForEach-Object { $_.BaseName -replace '_5$', '' } | Sort-Object
$leafyDone = @('lettuce','cabbage','broccoli','cauliflower','kale','napa_cabbage')
$count = 0
foreach ($n in $all) {
    if ($leafyDone -contains $n) { continue }
    $kind = Get-Kind $n
    $avg = Get-Avg (Join-Path $outDir ($n + '_5.png'))
    for ($age = 0; $age -le 5; $age++) {
        $p = Join-Path $outDir ($n + '_' + $age + '.png')
        if (Test-Path $p) { Copy-Item $p (Join-Path $bak ($n + '_' + $age + '.png')) -Force }
        $bmp = New-Object System.Drawing.Bitmap(16, 16)
        Draw-Crop $kind $bmp $age $avg[0] $avg[1] $avg[2] ($n.Length * 1.1)
        $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        $count++
    }
}
Write-Output ('crop block textures redrawn (other kinds): ' + $count)