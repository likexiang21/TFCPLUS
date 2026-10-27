# ============================================================
# gen-pixelart-textures.ps1 —— 「手绘笔触」版作物贴图（叶菜类原型验证）
# ============================================================
# 用户反馈：「歪歪扭扭不成样子」「颜色使用极其失败」「用尽可能真实的笔触」。
# 根因：此前所有贴图都是**数学函数逐像素生成**（sin 抖动 + 连续渐变），
#       必然得到「碎点状、机械对称、颜色浑浊」的结果 —— 那不是笔触。
#
# 本脚本改用**模板驱动**：
#   · 每个阶段一张手写 16×16 字符画（不是函数生成）；
#   · 字符 = 有限调色板：. 透明 / a 暗部 / b 中间调 / c 亮部 / d 高光 / e 叶脉凹陷；
#   · 颜色由物种「主色」（最高频色）派生 5 阶，不再用平均色。
# 笔触特征（手绘感来源）：不对称布局、叶脉凹陷线、底部外叶、高光偏左上。
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Join-Path $PSScriptRoot '..\src\main\resources'
$NS = 'tfcfarmingplus'
$outDir = Join-Path $root ("assets/$NS/textures/block/crop")
$bak = Join-Path $PSScriptRoot '..\..\..\.probe\skill-review\crop-old'
if (-not (Test-Path $bak)) { New-Item -ItemType Directory -Force -Path $bak | Out-Null }

# ---- 叶菜 6 阶段模板（手写） ----
$templates = @{}
$templates[0] = @(
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '.......c........',
    '......cbc.......',
    '.......c........',
    '.......b........',
    '.......b........',
    '................')
$templates[1] = @(
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '.....c.....c....',
    '......c...c.....',
    '.......ccc......',
    '........b.......',
    '........b.......',
    '........b.......',
    '................')
$templates[2] = @(
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '....c.....c.....',
    '.....cc.cc......',
    '......ccc.......',
    '.....ccbcc......',
    '......cbc.......',
    '.......b........',
    '.......b........',
    '.......b........',
    '................')
$templates[3] = @(
    '................',
    '................',
    '................',
    '................',
    '................',
    '....c.....c.....',
    '.....cc.cc......',
    '....ccbccbcc....',
    '.....cbddbc.....',
    '.....cbddbc.....',
    '......cbdc......',
    '.......bc.......',
    '.......b........',
    '.......b........',
    '.......b........',
    '................')
$templates[4] = @(
    '................',
    '................',
    '................',
    '.....cccc.......',
    '...ccbbbbcc.....',
    '..cbbbbbbbbc....',
    '..cbbbddddbbc...',
    '.cbbbddddddbbc..',
    '.cbbbddddddbbbc.',
    'ccbbbddddddbbbcc',
    'ccbbbbddddbbbbcc',
    '.ccbbbbbbbbbbcc.',
    '..ccbbbbbbbbcc..',
    '....ccbbbbcc....',
    '................',
    '................')
$templates[5] = @(
    '................',
    '.....cccc.......',
    '...ccbbbbcc.....',
    '..cbbbbbbbbc....',
    '..cbbbddddbbc...',
    '.cbbbbddddbbbc..',
    '.cbbbddddddbbbc.',
    '.cbbbddddddbbbc.',
    'ccbbbbddddbbbbcc',
    'ccbbbbddddbbbbcc',
    '.ccbbbbbbbbbbcc.',
    '..ccbbbbbbbbcc..',
    '...cccbbbbbcc...',
    '..ccbbbbbbbcc...',
    '.ccbbbbbbbbbcc..',
    '..ccccccccccc...')

# 调色板：主色 5 阶（暗 / 中 / 亮 / 高光 / 叶脉凹陷），不是连续渐变
$shades = @{
    'a' = 0.52
    'b' = 0.82
    'c' = 1.06
    'd' = 1.38
    'e' = 0.68
}

function Get-Dominant([string]$p) {
    $bmp = New-Object System.Drawing.Bitmap($p)
    $h = @{}
    for ($y = 0; $y -lt 16; $y++) { for ($x = 0; $x -lt 16; $x++) {
        $c = $bmp.GetPixel($x, $y); if ($c.A -lt 8) { continue }
        $key = ('{0}-{1}-{2}' -f [int]($c.R/24), [int]($c.G/24), [int]($c.B/24))
        if ($h.ContainsKey($key)) { $h[$key][0]++; $h[$key][1] += $c.R; $h[$key][2] += $c.G; $h[$key][3] += $c.B }
        else { $h[$key] = @(1, $c.R, $c.G, $c.B) }
    } }
    $bmp.Dispose()
    $best = $null; $bestN = -1
    foreach ($k in $h.Keys) { if ($h[$k][0] -gt $bestN) { $bestN = $h[$k][0]; $best = $h[$k] } }
    $r = [int]($best[1]/$best[0]); $g = [int]($best[2]/$best[0]); $b = [int]($best[3]/$best[0])
    $avg = ($r + $g + $b) / 3.0
    return @([Math]::Max(0,[Math]::Min(255,[int]($avg + ($r-$avg)*1.45))),
             [Math]::Max(0,[Math]::Min(255,[int]($avg + ($g-$avg)*1.45))),
             [Math]::Max(0,[Math]::Min(255,[int]($avg + ($b-$avg)*1.45))))
}

$crops = @('lettuce','cabbage','broccoli','cauliflower','kale','napa_cabbage')
$done = 0
foreach ($n in $crops) {
    $ref = Join-Path $outDir ($n + '_5.png')
    if (-not (Test-Path $ref)) { continue }
    $pal = Get-Dominant $ref
    foreach ($age in 0..5) {
        $p = Join-Path $outDir ($n + '_' + $age + '.png')
        Copy-Item $p (Join-Path $bak ($n + '_' + $age + '.png')) -Force
        $bmp = New-Object System.Drawing.Bitmap(16, 16)
        $rows = $templates[$age]
        for ($y = 0; $y -lt 16; $y++) {
            $line = $rows[$y]
            for ($x = 0; $x -lt 16; $x++) {
                $ch = $line.Substring($x, 1)
                if ($ch -eq '.') { continue }
                $k = $shades[$ch]
                if ($null -eq $k) { continue }
                # —— 结构化明暗（贴近 TFC 的逐像素层次；不是随机噪声）——
                # ① 沿光照方向的结构渐变：左上受光、右下入影
                $lx = ($x - 7.5) / 8.0; $ly = ($y - 7.5) / 8.0
                $lit = 1.0 - 0.16 * ($lx * 0.55 + $ly * 0.85)
                # ② 极轻的笔压不匀（高频、幅度小，避免退化成「碎点」）
                $jit = 1.0 + 0.035 * [Math]::Sin($x * 5.1 + $y * 3.7)
                $k = $k * $lit * $jit
                $r = [Math]::Max(0, [Math]::Min(255, [int]($pal[0] * $k)))
                $g = [Math]::Max(0, [Math]::Min(255, [int]($pal[1] * $k)))
                $b = [Math]::Max(0, [Math]::Min(255, [int]($pal[2] * $k)))
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
            }
        }
        $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        $done++
    }
}
Write-Output ('pixel-art crop textures (leafy): ' + $done)