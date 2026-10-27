# ============================================================
# gen-branch-fruits.ps1 —— 枝干结果（第三版）：果实是枝干的 blockstate 属性
# ============================================================
# 用户要求：「果实作为主干的一个方块状态，不要额外引入方块（毕竟树干不是完整方块）」。
#   · 方块侧：FarmingFruitingBranchBlock 新增 fruit = none / unripe / ripe；
#   · 资源侧：枝干 blockstate（multipart）在 fruit=unripe/ripe 时**叠加**果实模型；
#   · 旧的独立方块资源（plant/<n>_trunk_fruit 的 blockstate / 模型 / 物品模型 / 掉落表）
#     由本脚本删除 —— 删过资源必须 clean build（AGENTS.md 硬约束 4）。
# ============================================================
param([string]$OutputRoot = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $env:TFC_TOOLS_ROOT 'cocoa-data-policy.ps1')
Add-Type -AssemblyName System.Drawing

$root = Resolve-LegacyGeneratorOutput $OutputRoot
$NS = 'tfcfarmingplus'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 12 -Compress), $utf8)
}

# 物种：未熟色 / 成熟色（写实基调：靠明暗塑形，不靠高饱和）
$species = @(
    [ordered]@{ n = 'jabuticaba'; u = @(96, 118, 74);  r = @(48, 40, 66)  },
    [ordered]@{ n = 'soursop';    u = @(104, 128, 78); r = @(92, 142, 74) },
    [ordered]@{ n = 'mangosteen'; u = @(112, 126, 80); r = @(104, 52, 62) },
    [ordered]@{ n = 'cupuacu';    u = @(118, 132, 86); r = @(148, 112, 66) },
    [ordered]@{ n = 'bael';       u = @(110, 132, 76); r = @(168, 148, 74) },
    [ordered]@{ n = 'canistel';   u = @(120, 134, 88); r = @(196, 160, 72) }
    [ordered]@{ n = 'black_pepper'; u = @(96, 128, 74);   r = @(58, 46, 40) }
)

# ---------- 共享果实几何：四颗椭球贴在主干**中下侧**（unripe 小 / ripe 大） ----------
$cubeFaces = [ordered]@{
    north = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#0' }
    east  = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#0' }
    south = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#0' }
    west  = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#0' }
    up    = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#0' }
    down  = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#0' }
}

# 主干截面是 8x8（x/z 4..12）；果实内端嵌入 1 格、外端凸出，四向各一颗。
# 高度 h 略大于宽度 w -> 视觉上是椭球（配合球面光照贴图）。
function New-FruitCluster([double]$w, [double]$h, [double]$d) {
    $y1 = 3.0; $y2 = $y1 + $h
    $a1 = 8.0 - $w / 2.0; $a2 = 8.0 + $w / 2.0
    $o1 = 5.0 - $d; $o2 = 5.0    # 北/西侧：外端 .. 嵌入端
    $list = New-Object System.Collections.ArrayList
    [void]$list.Add([ordered]@{ from = @($a1, $y1, $o1);       to = @($a2, $y2, $o2);       faces = $cubeFaces })  # N
    [void]$list.Add([ordered]@{ from = @($a1, $y1, (11.0));   to = @($a2, $y2, (11.0 + $d)); faces = $cubeFaces })  # S
    [void]$list.Add([ordered]@{ from = @($o1, $y1, $a1);       to = @($o2, $y2, $a2);       faces = $cubeFaces })  # W
    [void]$list.Add([ordered]@{ from = @((11.0), $y1, $a1);   to = @((11.0 + $d), $y2, $a2); faces = $cubeFaces })  # E
    return $list
}

Save-Json ("assets/$NS/models/block/plant/branch_fruit_unripe.json") ([ordered]@{
    credit           = 'TFC Farming Plus - four young cauliflory fruits around the trunk (unripe, small)'
    ambientocclusion = $false
    textures         = [ordered]@{ '0' = ($NS + ':block/plant/branch_fruit_unripe'); particle = ($NS + ':block/plant/branch_fruit_unripe') }
    elements         = (New-FruitCluster -w 3.0 -h 4.0 -d 3.0)
})
Save-Json ("assets/$NS/models/block/plant/branch_fruit_ripe.json") ([ordered]@{
    credit           = 'TFC Farming Plus - four mature cauliflory fruits around the trunk (ripe, larger)'
    ambientocclusion = $false
    textures         = [ordered]@{ '0' = ($NS + ':block/plant/branch_fruit_ripe'); particle = ($NS + ':block/plant/branch_fruit_ripe') }
    elements         = (New-FruitCluster -w 4.0 -h 5.0 -d 4.0)
})

# ---------- 写实果皮贴图：球面光照 + 果点 + 蒂部 ----------
function New-FruitSkin([string]$out, [int]$cr, [int]$cg, [int]$cb, [double]$seed, [bool]$ripe) {
    # 16x16 果皮：球面光照（光来自左上）+ 柔和小高光 + 果点纹理 + 轮廓暗边
    # ⚠️ 早期版本在球心画了一块深色「蒂部」，在 16x16 下变成一个突兀的深绿方块 —— 已去掉。
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $cx = 7.5; $cy = 8.0; $rad = 7.6
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $dx = ($x + 0.5 - $cx) / $rad
            $dy = ($y + 0.5 - $cy) / $rad
            $d2 = $dx * $dx + $dy * $dy
            if ($d2 -gt 1.0) { continue }
            $nz = [Math]::Sqrt(1.0 - $d2)
            # 主光：左上（lambert 近似）
            $nl = [Math]::Max(0.0, $dx * -0.42 + $dy * -0.52 + $nz * 0.74)
            $k = 0.62 + 0.60 * $nl
            # 轮廓：最外圈压暗（代替硬边）
            $edge = 1.0 - 0.26 * [Math]::Pow($d2, 4.0)
            # 果点：稀疏的略暗点，给果皮质感
            $grain = 1.0
            if ((($x * 7 + $y * 13 + [int]($seed * 5)) % 6) -eq 0) { $grain = 0.93 }
            # 柔和高光：左上一个小亮斑（半径约 1.6 px），不做满白
            $hx = ($x + 0.5) - ($cx - 2.4); $hy = ($y + 0.5) - ($cy - 2.6)
            $hd = [Math]::Sqrt($hx * $hx + $hy * $hy)
            $spec = 0.0
            if ($hd -lt 2.8) { $spec = [Math]::Pow(1.0 - $hd / 2.8, 1.6) * 0.34 }
            $kk = $k * $edge * $grain + $spec
            $r = [Math]::Max(0, [Math]::Min(255, [int]($cr * $kk + 90 * $spec)))
            $g = [Math]::Max(0, [Math]::Min(255, [int]($cg * $kk + 90 * $spec)))
            $b = [Math]::Max(0, [Math]::Min(255, [int]($cb * $kk + 90 * $spec)))
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
        }
    }
    # 顶部果柄痕：2x2 深色点（不放在球心）
    foreach ($p in @(@(7,1),@(8,1),@(8,2))) {
        $c0 = $bmp.GetPixel($p[0], $p[1])
        if ($c0.A -ge 8) { $bmp.SetPixel($p[0], $p[1], [System.Drawing.Color]::FromArgb(255, [int]($c0.R * 0.62), [int]($c0.G * 0.66), [int]($c0.B * 0.55))) }
    }
    $dir = Split-Path $out -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

$texRoot   = Join-Path $root ("assets/$NS/textures/block/plant")
$stateRoot = Join-Path $root ("assets/$NS/blockstates/plant")
$modelRoot = Join-Path $root ("assets/$NS/models/block/plant")
$itemRoot  = Join-Path $root ("assets/$NS/models/item/plant")
$lootRoot  = Join-Path $root ("data/$NS/loot_table/blocks/plant")
$removed = 0

foreach ($sp in $species) {
    $n = $sp['n']
    $u = $sp['u']; $rp = $sp['r']
    # 共享兜底贴图（共享几何 branch_fruit 自身要能独立解析）
New-FruitSkin (Join-Path $texRoot 'branch_fruit_unripe.png') 118 132 82 1.7 $false
New-FruitSkin (Join-Path $texRoot 'branch_fruit_ripe.png') 150 122 74 2.3 $true
New-FruitSkin (Join-Path $texRoot ($n + '_branch_fruit_unripe.png')) $u[0] $u[1] $u[2] ($n.Length * 0.7) $false
    New-FruitSkin (Join-Path $texRoot ($n + '_branch_fruit_ripe.png')) $rp[0] $rp[1] $rp[2] ($n.Length * 1.3) $true
    Save-Json ("assets/$NS/models/block/plant/" + $n + '_branch_fruit_unripe.json') ([ordered]@{
        parent   = ($NS + ':block/plant/branch_fruit_unripe')
        textures = [ordered]@{ '0' = ($NS + ':block/plant/' + $n + '_branch_fruit_unripe') }
    })
    Save-Json ("assets/$NS/models/block/plant/" + $n + '_branch_fruit_ripe.json') ([ordered]@{
        parent   = ($NS + ':block/plant/branch_fruit_ripe')
        textures = [ordered]@{ '0' = ($NS + ':block/plant/' + $n + '_branch_fruit_ripe') }
    })

    $bsPath = Join-Path $stateRoot ($n + '_branch.json')
    if (-not (Test-Path $bsPath)) { Write-Output ('  !! missing ' + $bsPath); continue }
    $bs = Get-Content $bsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $parts = New-Object System.Collections.ArrayList
    foreach ($p in $bs.multipart) {
        $w = $p.when
        if ($null -ne $w -and $null -ne $w.fruit) { continue }
        [void]$parts.Add($p)
    }
    [void]$parts.Add([ordered]@{ when = [ordered]@{ fruit = 'unripe' }; apply = [ordered]@{ model = ($NS + ':block/plant/' + $n + '_branch_fruit_unripe') } })
    [void]$parts.Add([ordered]@{ when = [ordered]@{ fruit = 'ripe' };   apply = [ordered]@{ model = ($NS + ':block/plant/' + $n + '_branch_fruit_ripe') } })
    [System.IO.File]::WriteAllText($bsPath, (([ordered]@{ multipart = $parts }) | ConvertTo-Json -Depth 10 -Compress), $utf8)

    foreach ($p in @((Join-Path $stateRoot ($n + '_trunk_fruit.json')), (Join-Path $itemRoot ($n + '_trunk_fruit.json')), (Join-Path $lootRoot ($n + '_trunk_fruit.json')))) {
        if (Test-Path $p) { Remove-Item $p -Force; $removed++ }
    }
    Get-ChildItem $modelRoot -File -Filter ($n + '_trunk_fruit_*.json') -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.FullName -Force; $script:removed++ }
    Get-ChildItem $texRoot -File -Filter ($n + '_trunk_fruit_*.png') -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.FullName -Force; $script:removed++ }
    Write-Host ('  ' + $n + ' 果实层已就位（unripe/ripe）')
}

# ---------- lang：删掉旧方块名 ----------
foreach ($langFile in @('en_us.json', 'zh_cn.json')) {
    $lp = Join-Path $root ("assets/$NS/lang/" + $langFile)
    if (-not (Test-Path $lp)) { continue }
    $txt = [System.IO.File]::ReadAllText($lp, [System.Text.Encoding]::UTF8)
    $before = $txt.Length
    $txt = [regex]::Replace($txt, ('(?m)^\s*"block\.' + $NS + '\.plant\.[a-z_]+_trunk_fruit"\s*:\s*"[^"]*",?\r?\n'), '')
    $txt = [regex]::Replace($txt, ',(\s*\})', '$1')
    if ($txt.Length -ne $before) { [System.IO.File]::WriteAllText($lp, $txt, $utf8); Write-Host ('  ' + $langFile + ' 清理了 trunk_fruit 条目') }
}
Write-Host ('枝干果实资源完成；删除旧资源 ' + $removed + ' 个（删除后需 clean build）')