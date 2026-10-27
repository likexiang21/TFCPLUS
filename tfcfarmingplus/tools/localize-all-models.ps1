# localize-all-models.ps1 —— 补齐「跨命名空间借用 TFC 贴图」的剩余缺口。
#
# 背景：玩家反馈「贴图修改覆盖不彻底」。排查后发现两个真实漏洞：
#
#   ① 【物品贴图完全没处理】238 个 models/item/** 仍在直接引用 TFC 的贴图：
#        item/food/ginger.json   → {"layer0":"tfc:item/food/beet"}
#        item/seeds/ginger.json  → {"layer0":"tfc:item/seeds/beet"}
#        item/plant/pear_sapling.json → {"layer0":"tfc:block/fruit_tree/cherry_sapling"}
#      这些正是**玩家在物品栏里看到的东西** —— 之前只改了方块贴图，等于改了地里、
#      没改手上，难怪「不彻底」。
#
#   ② 【野生作物漏了一个槽】父模型 tfc:block/wild_crop/crop 内部是：
#        {"1":"tfc:block/crop/wild_crop_grass", "particle":"#crop", "crop":"#crop"}
#      之前的脚本只替换了 "crop" 槽，把硬编码的杂草层 "1" 漏掉了 ——
#      74 个野生作物至今仍在加载 TFC 的 wild_crop_grass。
#      注意这个槽是**新增**（子模型里原本没有），不是替换，所以单独处理（见「第 0 步」）。
#
# 做法：扫描**所有**模型，只处理 "textures" 块里的 `"tfc:..."`（绝不碰 "parent" ——
#      父模型是几何体，必须继续借用，branch/leaves 就是靠它拿形状的）。
#
# 目标贴图命名 = 模型的相对路径（去掉 models/ 前缀，.json 改 .png）：
#     models/item/food/ginger.json       → textures/item/food/ginger.png
#     models/item/seeds/ginger.json      → textures/item/seeds/ginger.png
#     models/item/plant/pear_sapling.json→ textures/item/plant/pear_sapling.png
#     models/block/wild_crop/ginger.json → textures/block/wild_crop/ginger_grass.png（杂草层特判）
#   这样「模型 → 贴图」是纯字符串推导，不需要猜 donor 的命名规则。
#
# ⚠️ seed（配色种子）取**物种名**并剥掉形态后缀，保证同一物种的
#    方块贴图 / 物品贴图 / 种子贴图共用同一组色调参数 —— 生姜的作物、种子、
#    食材看起来才像同一株生姜。这也与 localize-textures.ps1 的 seed 规则一致。
#
# ⚠️ 路径必须 Resolve-Path 规范化：$root 里带 '..'，而 Get-ChildItem 的 FullName 是
#    已规范化的，两者长度不一致会让 Substring 切错位置。曾因此把 234 个模型的引用写成
#    `tfcfarmingplus:/celeriac` 这种丢失目录的形式，贴图也生成到了错误位置
#    （115 个 item/food 贴图甚至落到了 D:\ 根目录）。
#
# 幂等：第二次运行时模型里已无 tfc 贴图引用、草层槽也已存在，脚本仍会重跑一次贴图生成
#       （草层 job 每次都重算，保证已经本地化过的工程也能补上草层贴图）。

$ErrorActionPreference = 'Stop'

$root       = Join-Path $PSScriptRoot '..\src\main\resources'
$NS         = 'tfcfarmingplus'
$java       = 'C:\Users\Lenovo\.gradle\jdks\eclipse_adoptium-21-amd64-windows.2\bin\java.exe'
$tfcTexRoot = Join-Path $env:TEMP 'tfcx\assets\tfc\textures'
$utf8       = New-Object System.Text.UTF8Encoding($false)

$modelsRoot = (Resolve-Path (Join-Path $root "assets/$NS/models")).Path
$outTexRoot = (Resolve-Path (Join-Path $root "assets/$NS/textures")).Path

if (-not (Test-Path $tfcTexRoot)) {
    Write-Host "✘ 找不到 TFC 贴图缓存: $tfcTexRoot"
    exit 1
}

# 物种名推导：剥掉形态后缀与数字后缀，让 pear_sapling / pear / pear_dry_leaves 归到同一个 seed
function Get-Seed([string]$name) {
    $s = $name -replace '_[0-9]+$', ''
    foreach ($suf in @('_dry_leaves', '_flowering_leaves', '_fruiting_leaves', '_dry', '_flowering',
                       '_fruiting', '_sapling', '_leaves', '_branch', '_cane', '_bush',
                       '_berries', '_berry', '_seeds', '_seed', '_fruit')) {
        if ($s.EndsWith($suf) -and $s.Length -gt $suf.Length) { return $s.Substring(0, $s.Length - $suf.Length) }
    }
    return $s
}

$jobs       = New-Object System.Collections.ArrayList
$changed    = 0
$injected   = 0
$byCategory = @{}

# ---------- 第 0 步：野生作物补上杂草层 "1" 槽（新增，不是替换） ----------
# 父模型 tfc:block/wild_crop/crop 把 "1" 硬编码成 TFC 的杂草贴图，子模型不写就一直在用。
$wcDir = Join-Path $modelsRoot 'block\wild_crop'
if (Test-Path $wcDir) {
    foreach ($f in Get-ChildItem $wcDir -File -Filter *.json) {
        $sp = $f.BaseName
        [void]$jobs.Add([ordered]@{ src = 'block/crop/wild_crop_grass.png'
                                    dst = "block/wild_crop/${sp}_grass.png"
                                    seed = $sp })
        $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        if ($text -match '"1"\s*:') { continue }
        # ⚠️ 必须写 ${NS} —— "$NS:..." 里的 `$NS:` 会被当成作用域变量（docs/74 §8.2-1）
        $new = [regex]::Replace($text, '("textures"\s*:\s*\{)',
                                "`$1`"1`": `"${NS}:block/wild_crop/${sp}_grass`",")
        if ($new -ne $text) {
            [System.IO.File]::WriteAllText($f.FullName, $new, $utf8)
            $injected++
        }
    }
}
Write-Host "  野生作物补杂草层槽: $injected 个（共 $((Get-ChildItem $wcDir -File -Filter *.json).Count) 个）"

# ---------- 主扫描：所有模型 textures 块里残留的 tfc 贴图引用 ----------
foreach ($f in Get-ChildItem $modelsRoot -Recurse -File -Filter *.json) {
    $relPath = $f.FullName.Substring($modelsRoot.Length + 1).Replace('\', '/')
    $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)

    # ⚠️ 只在 "textures" 块内替换 —— "parent" 必须保留（那是几何体，不是贴图）
    $tm = [regex]::Match($text, '"textures"\s*:\s*\{[^}]*\}')
    if (-not $tm.Success) { continue }

    $inner = [regex]::Matches($tm.Value, '"tfc:([a-z0-9_/]+)"')
    if ($inner.Count -eq 0) { continue }

    $baseRel  = $relPath -replace '\.json$', ''
    $seed     = Get-Seed ([System.IO.Path]::GetFileNameWithoutExtension($relPath))
    $block    = $tm.Value
    $newBlock = $block
    $idx = 0

    foreach ($mm in $inner) {
        $srcPath = $mm.Groups[1].Value
        $idx++
        $suffix = ''
        if ($srcPath -like '*wild_crop_grass') { $suffix = '_grass' }
        elseif ($idx -gt 1)                    { $suffix = "_$idx" }

        [void]$jobs.Add([ordered]@{ src = "$srcPath.png"; dst = "$baseRel$suffix.png"; seed = $seed })

        $newRef   = "${NS}:$baseRel$suffix"
        $newBlock = $newBlock.Replace($mm.Value, "`"$newRef`"")
    }

    if ($newBlock -ne $block) {
        $newText = $text.Replace($tm.Value, $newBlock)
        [System.IO.File]::WriteAllText($f.FullName, $newText, $utf8)
        $changed++

        $cat = Split-Path $relPath -Parent
        if (-not $byCategory.ContainsKey($cat)) { $byCategory[$cat] = 0 }
        $byCategory[$cat]++
    }
}

Write-Host "  本地化模型: $changed 个"
$byCategory.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host "      models/$($_.Key)/ : $($_.Value) 个"
}
Write-Host "  待生成贴图: $($jobs.Count) 个"

$jobFile = Join-Path $PSScriptRoot 'data/texture-jobs-items.json'
[System.IO.File]::WriteAllText($jobFile,
    (([ordered]@{ jobs = $jobs }) | ConvertTo-Json -Depth 5 -Compress), $utf8)

& $java (Join-Path $PSScriptRoot 'java/TintTextures.java') $tfcTexRoot $outTexRoot $jobFile
if ($LASTEXITCODE -ne 0) { Write-Host "✘ 贴图生成失败"; exit 1 }
