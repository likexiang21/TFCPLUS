# ============================================================
# gen-food-textures.ps1 —— 食物图标按**类别**重绘（124 张）
# ============================================================
# 背景：`gen-crops.ps1` 让每个物种借用同 ref 的 TFC 图标（生菜→洋葱、西兰花→卷心菜），
# 形状与物种不符。本脚本改按类别画：
#   grain  谷物/穗  —— 3 根穗（细茎 + 两侧籽粒）
#   legume 豆类     —— 斜放的豆荚 + 露出 3 颗豆
#   root   根菜     —— 锥形根 + 顶部叶簇
#   leafy  叶球类   —— 外叶张开 + 内叶层叠成球（同物品图标那套）
#   herb   香草/散叶 —— 4 片小叶散开
#   fruitveg 果菜   —— 圆果 + 蒂 + 亮斑
#   berry  果实/浆果 —— 圆果 + 果柄 + 小叶（TFC 画法）
# 配色：读旧图平均色（保持物种色系），只改画法。
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Join-Path $env:TFC_TOOLS_ROOT '..\src\main\resources'
$dir = Join-Path $root 'assets/tfcfarmingplus/textures/item/food'
$bak = Join-Path $env:TFC_TOOLS_ROOT '..\..\..\.probe\skill-review\food-old'
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
    if ($n -eq 0) { return @(150, 120, 70) }
    return @([int]($rs / $n), [int]($gs / $n), [int]($bs / $n))
}

function Set-Px($bmp, [int]$x, [int]$y, [int]$cr, [int]$cg, [int]$cb, [double]$k) {
    if ($x -lt 0 -or $x -gt 15 -or $y -lt 0 -or $y -gt 15) { return }
    $r = [Math]::Max(0, [Math]::Min(255, [int]($cr * $k)))
    $g = [Math]::Max(0, [Math]::Min(255, [int]($cg * $k)))
    $b = [Math]::Max(0, [Math]::Min(255, [int]($cb * $k)))
    $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
}

# 类别判定（有序：先匹配先生效）
$rules = @(
    @{ kind = 'slice'; pat = '_slice$|_slice_' },
    @{ kind = 'grain'; pat = 'wheat|barley|oat|rye|rice|maize|sorghum|millet|fonio|einkorn|emmer|spelt|teff|quinoa|amaranth|buckwheat|jobs_tears|canola|sesame|safflower' },
    @{ kind = 'legume'; pat = 'adzuki|bambara|chickpea|faba|fenugreek|lentil|mung|pigeon|cowpea|soybean|green_bean|gram|pea$|peanut|bean' },
    @{ kind = 'root'; pat = 'arrowhead|celeriac|chicory_root|ginger|turmeric|carrot|beet|radish|turnip|onion|garlic|potato|cassava|yam|parsnip|rutabaga|water_chestnut|lotus|taro|jicama|burdock|horseradish|salsify' },
    @{ kind = 'leafy'; pat = 'cabbage|lettuce|kale|broccoli|cauliflower|brussels|napa' },
    @{ kind = 'herb'; pat = 'arugula|spinach|chard|mustard_greens|celtuce|celery|asparagus|artichoke|cardoon|agave|purslane|chive|basil|mint|oregano|thyme|rosemary|sage|dill|parsley|cilantro|fennel|water_caltrop|rhubarb|chrysanthemum|chicory|endive|jute|flax|hemp|cotton|papyrus|sugarcane|hops|tobacco|tea_leaf|coffee' },
    @{ kind = 'fruitveg'; pat = 'melon|gourd|squash|pumpkin|tomato|pepper|chili|eggplant|chayote|okra|cucumber|zucchini|tomatillo' }
)
function Get-Kind([string]$name) {
    foreach ($r in $rules) { if ($name -match $r.pat) { return $r.kind } }
    return 'berry'
}

function New-Canvas { return (New-Object System.Drawing.Bitmap(16, 16)) }
function Save-Tex($bmp, [string]$p) { $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose() }

# --- 瓜类切片：楔形切角（顶点在下，外弧是皮，内部果肉 + 籽） ---
function Draw-Slice([string]$out, [int]$fr, [int]$fg, [int]$fb) {
    $bmp = New-Canvas
    $axp = 13.2; $ayp = 16.4         # 楔形顶点：右下角外（开口朝左上，占满画面）
    $rim = 11.6                      # 外弧半径（铺满 16x16）
    $rind = 9.5                      # 皮的内边界（皮薄，约 2px）
    $pr = [int]($fr * 0.52); $pg = [int]($fg * 0.80 + 18); $pb = [int]($fb * 0.48)
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = $x + 0.5 - $axp
            $dy = $ayp - ($y + 0.5)
            $rr = [Math]::Sqrt($dx * $dx + $dy * $dy)
            if ($rr -gt $rim -or $rr -lt 0.4) { continue }
            $ang = [Math]::Atan2($dx, $dy)
            if ([Math]::Abs($ang) -gt 0.62) { continue }
            # 左亮右暗的果肉
            $t = ($dx / ($rr + 0.001) + 1.0) / 2.0
            if ($rr -gt $rind) {
                # 皮：外缘一圈，稍暗且偏绿
                $k = 1.02 - 0.20 * $t
                if (([int]$x + [int]$y) % 3 -eq 0) { $k = $k * 0.86 }   # 瓜皮条纹
                Set-Px $bmp $x $y $pr $pg $pb $k
            } else {
                $k = 1.34 - 0.26 * $t - 0.06 * ($rr / $rim)
                # 切口面（靠顶点一侧）略暗，表现厚度
                if ($rr -lt 2.6) { $k = $k * 0.84 }
                if (([int]$y % 3) -eq 0) { $k = $k * 0.93 }   # 果肉纤维
                Set-Px $bmp $x $y $fr $fg $fb $k
            }
        }
    }
    # 籽：沿 r≈3.6 的弧放 3 颗
    foreach ($a in @(-0.34, 0.0, 0.34)) {
        $sx = [int][Math]::Round($axp + [Math]::Sin($a) * 7.0 - 0.5)
        $sy = [int][Math]::Round($ayp - [Math]::Cos($a) * 7.0 - 0.5)
        Set-Px $bmp $sx $sy 46 36 26 1.0
    }
    Save-Tex $bmp $out
}
# --- 谷物：3 根穗 ---
function Draw-Grain([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    foreach ($sx in @(4.5, 8.0, 11.5)) {
        for ($y = 2; $y -le 14; $y++) { Set-Px $bmp ([int]$sx) $y $cr $cg $cb 0.80 }
        for ($y = 2; $y -le 10; $y += 2) {
            Set-Px $bmp ([int]$sx - 1) $y $cr $cg $cb 1.15
            Set-Px $bmp ([int]$sx + 1) $y $cr $cg $cb 0.95
            Set-Px $bmp ([int]$sx - 1) ($y + 1) $cr $cg $cb 1.02
            Set-Px $bmp ([int]$sx + 1) ($y + 1) $cr $cg $cb 0.88
        }
    }
    Save-Tex $bmp $out
}
# --- 豆类：斜放豆荚 + 3 颗豆 ---
function Draw-Legume([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    for ($t = 0.0; $t -le 1.0; $t += 0.02) {
        $x = 3.0 + $t * 10.0
        $y = 12.0 - $t * 7.5
        $wHalf = 1.6 - 0.5 * [Math]::Abs($t - 0.5) * 2.0
        for ($o = -$wHalf; $o -le $wHalf; $o += 0.5) {
            $k = 1.05 - 0.35 * ([Math]::Abs($o) / [Math]::Max($wHalf, 0.1))
            Set-Px $bmp ([int][Math]::Round($x - 0.5)) ([int][Math]::Round($y + $o - 0.5)) $cr $cg $cb $k
        }
    }
    foreach ($b in @(@(6,10),@(8,9),@(10,8))) { Set-Px $bmp $b[0] $b[1] $cr $cg $cb 1.30 }
    Save-Tex $bmp $out
}
# --- 根菜：锥形根 + 顶部叶簇 ---
function Draw-Root([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    for ($y = 4; $y -le 14; $y++) {
        $t = ($y - 4) / 10.0
        $half = 3.4 * (1.0 - $t * 0.82)
        for ($o = -$half; $o -le $half; $o += 0.5) {
            $k = 1.14 - 0.34 * ([Math]::Abs($o) / [Math]::Max($half, 0.1)) - 0.10 * $t
            Set-Px $bmp ([int][Math]::Round(7.8 + $o - 0.5)) $y $cr $cg $cb $k
        }
    }
    foreach ($a in @(-0.6, -0.2, 0.2, 0.6)) {
        for ($r = 1; $r -le 4; $r++) {
            $x = [int][Math]::Round(7.8 + [Math]::Sin($a) * $r - 0.5)
            $y = [int][Math]::Round(4.5 - [Math]::Cos($a) * $r * 0.7)
            Set-Px $bmp $x $y 96 138 62 (1.12 - 0.05 * $r)
        }
    }
    Save-Tex $bmp $out
}
# --- 香草/散叶：4 片小叶 ---
function Draw-Herb([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    foreach ($a in @(-0.9, -0.3, 0.3, 0.9)) {
        for ($r = 1; $r -le 6; $r++) {
            $x = [int][Math]::Round(7.8 + [Math]::Sin($a) * $r - 0.5)
            $y = [int][Math]::Round(13.5 - [Math]::Cos($a) * $r - 0.5)
            $k = 1.16 - 0.055 * $r
            Set-Px $bmp $x $y $cr $cg $cb $k
            Set-Px $bmp ($x + 1) $y $cr $cg $cb ($k * 0.86)
        }
    }
    Save-Tex $bmp $out
}
# --- 果菜：圆果 + 蒂 ---
function Draw-FruitVeg([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = ($x + 0.5 - 7.8) / 5.9; $dy = ($y + 0.5 - 9.2) / 5.6
            $d2 = $dx * $dx + $dy * $dy
            if ($d2 -gt 1.0) { continue }
            $nz = [Math]::Sqrt(1.0 - $d2)
            $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.55 + $nz * 0.72)
            $k = 0.52 + 0.80 * $nl
            if ($d2 -gt 0.82) { $k = $k * 0.52 } elseif ($d2 -gt 0.68) { $k = $k * 0.82 }
            $hx = $x + 0.5 - 6.0; $hy = $y + 0.5 - 6.6
            if (($hx * $hx + $hy * $hy) -lt 2.4) { $k = $k + 0.60 }
            Set-Px $bmp $x $y $cr $cg $cb $k
        }
    }
    Set-Px $bmp 7 4 92 68 38 1.0; Set-Px $bmp 8 4 92 68 38 1.0; Set-Px $bmp 8 3 92 68 38 1.0
    Save-Tex $bmp $out
}
# --- 坚果：水滴形（上尖下圆）+ 壳纹 ---
function Draw-Nut([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    $cx = 7.8; $cy = 9.4; $rx = 4.1; $ry = 5.4
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = ($x + 0.5 - $cx) / $rx
            $dy = ($y + 0.5 - $cy) / $ry
            # 水滴：上半收窄
            $taper = if ($dy -lt 0) { 1.0 + 0.55 * $dy } else { 1.0 }
            $d2 = ($dx / [Math]::Max($taper, 0.35)) * ($dx / [Math]::Max($taper, 0.35)) + $dy * $dy
            if ($d2 -gt 1.0) { continue }
            $nz = [Math]::Sqrt(1.0 - $d2)
            $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.55 + $nz * 0.72)
            $k = 0.50 + 0.82 * $nl
            if ($d2 -gt 0.80) { $k = $k * 0.52 }
            $hx = $x + 0.5 - 6.2; $hy = $y + 0.5 - 7.4
            if (($hx * $hx + $hy * $hy) -lt 1.6) { $k = $k + 0.55 }
            Set-Px $bmp $x $y $cr $cg $cb $k
        }
    }
    # 壳纹（两道弧）
    foreach ($p in @(@(6,7),@(7,8),@(6,9),@(10,8),@(11,9),@(10,10))) { Set-Px $bmp $p[0] $p[1] $cr $cg $cb 0.62 }
    Set-Px $bmp 8 3 $cr $cg $cb 0.70
    Save-Tex $bmp $out
}

# --- 带刺大果（榴莲 / 菠萝蜜 / 刺果番荔枝）：椭圆 + 放射短刺 ---
function Draw-Spiky([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    $cx = 7.8; $cy = 8.8; $rx = 5.2; $ry = 5.6
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $cy) / $ry
            $d2 = $dx * $dx + $dy * $dy
            if ($d2 -gt 1.0) { continue }
            $nz = [Math]::Sqrt(1.0 - $d2)
            $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.52 + $nz * 0.72)
            $k = 0.54 + 0.78 * $nl
            if ($d2 -gt 0.84) { $k = $k * 0.55 }
            $hx = $x + 0.5 - 6.0; $hy = $y + 0.5 - 6.8
            if (($hx * $hx + $hy * $hy) -lt 1.8) { $k = $k + 0.55 }
            if ((($x + $y) % 3) -eq 0) { $k = $k * 0.80 }
            Set-Px $bmp $x $y $cr $cg $cb $k
        }
    }
    # 放射短刺
    foreach ($a in @(0.0, 0.9, 1.8, 2.7, 3.6, 4.5, 5.4)) {
        $tx = [int][Math]::Round($cx + [Math]::Cos($a) * ($rx + 0.9) - 0.5)
        $ty = [int][Math]::Round($cy + [Math]::Sin($a) * ($ry + 0.9) - 0.5)
        Set-Px $bmp $tx $ty $cr $cg $cb 0.78
    }
    Set-Px $bmp 7 3 $cr $cg $cb 0.75
    Save-Tex $bmp $out
}
# --- 浆果：3 颗小球一簇 ---
function Draw-BerryCluster([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    $spots = @(@(5.0,7.5),@(11.0,7.0),@(8.0,12.2))
    for ($i = 0; $i -lt 3; $i++) {
        $s = $spots[$i]
        for ($y = 0; $y -lt 16; $y++) {
            for ($x = 0; $x -lt 16; $x++) {
                $dx = ($x + 0.5 - $s[0]) / 2.6; $dy = ($y + 0.5 - $s[1]) / 2.6
                $d2 = $dx * $dx + $dy * $dy
                if ($d2 -gt 1.0) { continue }
                $nz = [Math]::Sqrt(1.0 - $d2)
                $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.55 + $nz * 0.72)
                $k = 0.52 + 0.82 * $nl
                if ($d2 -gt 0.78) { $k = $k * 0.55 }
                $hx = $x + 0.5 - ($s[0] - 0.9); $hy = $y + 0.5 - ($s[1] - 1.0)
                if (($hx * $hx + $hy * $hy) -lt 1.0) { $k = $k + 0.55 }
                Set-Px $bmp $x $y $cr $cg $cb $k
            }
        }
    }
    Set-Px $bmp 8 5 92 68 38 1.0; Set-Px $bmp 7 6 92 68 38 0.9
    Save-Tex $bmp $out
}
# --- 单果：形状随物种名变化；圆润球体 + 柔光 + 果点 + 果柄小叶 ---
function Draw-Berry([string]$out, [int]$cr, [int]$cg, [int]$cb, [string]$name) {
    $bmp = New-Canvas
    $h = 0
    foreach ($ch in $name.ToCharArray()) { $h = ($h * 31 + [int]$ch) % 100003 }
    $shape = $h % 4
    $rx = 5.6; $ry = 5.7
    if ($shape -eq 1) { $ry = 6.3; $rx = 4.9 }
    elseif ($shape -eq 2) { $rx = 6.3; $ry = 4.9 }
    elseif ($shape -eq 3) { $rx = 6.1; $ry = 6.2 }
    $cx = 7.7; $cy = 8.7
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = ($x + 0.5 - $cx) / $rx; $dy = ($y + 0.5 - $cy) / $ry
            $d2 = $dx * $dx + $dy * $dy
            if ($d2 -gt 1.0) { continue }
            $nz = [Math]::Sqrt(1.0 - $d2)
            $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.52 + $nz * 0.74)
            $k = 0.58 + 0.62 * $nl
            $edge = 1.0 - 0.30 * [Math]::Pow($d2, 3.4)
            $grain = 1.0
            if ((($x * 7 + $y * 13 + $h) % 6) -eq 0) { $grain = 0.94 }
            $hx = ($x + 0.5) - ($cx - $rx * 0.36); $hy = ($y + 0.5) - ($cy - $ry * 0.40)
            $hd = [Math]::Sqrt($hx * $hx + $hy * $hy)
            $spec = 0.0
            if ($hd -lt 2.4) { $spec = [Math]::Pow(1.0 - $hd / 2.4, 1.6) * 0.34 }
            $kk = $k * $edge * $grain + $spec
            Set-Px $bmp $x $y $cr $cg $cb $kk
        }
    }
    # 果柄：顶部 2 px 深棕；小叶：右上 1 片（小、贴合，不夸张）
    Set-Px $bmp 7 3 92 68 38 1.0; Set-Px $bmp 8 3 92 68 38 1.0; Set-Px $bmp 8 4 92 68 38 1.0
    Set-Px $bmp 9 4 88 126 56 0.95
    Save-Tex $bmp $out
}
# --- 叶球类：中心叶球 + 下方放射宽叶（叶从球底向外铺开，不是碎叶） ---
function Draw-Leafy([string]$out, [int]$cr, [int]$cg, [int]$cb) {
    $bmp = New-Canvas
    # 5 片宽叶：从球体下方向外辐射（角度全在下方）
    foreach ($a in @(0.35, 0.95, 1.57, 2.19, 2.79)) {
        for ($r = 2.4; $r -le 7.6; $r += 0.25) {
            $x = 7.7 + [Math]::Cos($a) * $r * 1.05
            $y = 7.4 + [Math]::Sin($a) * $r * 0.82
            $wHalf = 1.55 - 0.13 * ($r - 2.4)
            if ($wHalf -lt 0.35) { $wHalf = 0.35 }
            for ($o = -$wHalf; $o -le $wHalf; $o += 0.5) {
                $px = [int][Math]::Round($x - [Math]::Sin($a) * $o - 0.5)
                $py = [int][Math]::Round($y + [Math]::Cos($a) * $o - 0.5)
                $k = 1.12 - 0.042 * ($r - 2.4)
                if ([Math]::Abs($o) -gt ($wHalf - 0.5)) { $k = $k * 0.70 }
                Set-Px $bmp $px $py $cr $cg $cb $k
            }
        }
    }
    # 中心叶球
    for ($y = 2; $y -le 11; $y++) {
        for ($x = 2; $x -le 13; $x++) {
            $dx = ($x + 0.5 - 7.7) / 4.7; $dy = ($y + 0.5 - 7.2) / 4.9
            $d2 = $dx * $dx + $dy * $dy
            if ($d2 -gt 1.0) { continue }
            $nz = [Math]::Sqrt(1.0 - $d2)
            $nl = [Math]::Max(0.0, $dx * -0.45 + $dy * -0.55 + $nz * 0.70)
            $k = 0.60 + 0.72 * $nl
            $edge = 1.0 - 0.24 * [Math]::Pow($d2, 3.4)
            $rings = 1.0 + 0.075 * [Math]::Sin(($y + 0.5) * 1.5)
            $hx = ($x + 0.5) - 6.2; $hy = ($y + 0.5) - 5.7
            $spec = 0.0
            if (($hx * $hx + $hy * $hy) -lt 2.2) { $spec = 0.28 }
            Set-Px $bmp $x $y $cr $cg $cb ($k * $edge * $rings + $spec)
        }
    }
    Save-Tex $bmp $out
}

$files = Get-ChildItem $dir -File -Filter '*.png' | Sort-Object Name
Write-Output ('food icons: ' + $files.Count)
$hist = @{}
foreach ($f in $files) {
    Copy-Item $f.FullName (Join-Path $bak $f.Name) -Force
    $kind = Get-Kind $f.BaseName
    if (-not $hist.ContainsKey($kind)) { $hist[$kind] = 0 }
    $hist[$kind] = $hist[$kind] + 1
    $avg = Get-AverageColor $f.FullName
    switch ($kind) {
        'slice'    { Draw-Slice    $f.FullName $avg[0] $avg[1] $avg[2] }
        'grain'    { Draw-Grain    $f.FullName $avg[0] $avg[1] $avg[2] }
        'legume'   { Draw-Legume   $f.FullName $avg[0] $avg[1] $avg[2] }
        'root'     { Draw-Root     $f.FullName $avg[0] $avg[1] $avg[2] }
        'leafy'    { Draw-Leafy    $f.FullName $avg[0] $avg[1] $avg[2] }
        'herb'     { Draw-Herb     $f.FullName $avg[0] $avg[1] $avg[2] }
        'fruitveg' { Draw-FruitVeg $f.FullName $avg[0] $avg[1] $avg[2] }
        default    {
            $nm = $f.BaseName
            if ($nm -match 'almond|hazelnut|chestnut|walnut|pecan|gorgon_nut|acorn|pinenut|cashew|pistachio|macadamia|butternut|brazil') { Draw-Nut $f.FullName $avg[0] $avg[1] $avg[2] }
            elseif ($nm -match 'durian|jackfruit|breadfruit|soursop|cherimoya|custard_apple|sugar_apple|osage|monstera') { Draw-Spiky $f.FullName $avg[0] $avg[1] $avg[2] }
            elseif ($nm -match 'berry|currant|goji|haskap|bilberry|aronia|serviceberry|crowberry|bearberry|elderberry|gooseberry|raspberry|blackberry|strawberry|blueberry|cranberry|snowberry|wintergreen') { Draw-BerryCluster $f.FullName $avg[0] $avg[1] $avg[2] }
            else { Draw-Berry $f.FullName $avg[0] $avg[1] $avg[2] $nm }
        }
    }
}
$hist.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Output ('  ' + $_.Key + ': ' + $_.Value) }
Write-Output 'food icons redrawn'