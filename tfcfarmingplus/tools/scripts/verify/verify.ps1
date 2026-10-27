# ============================================================
# tfcfarmingplus 资源交叉引用校验（静态验证，不需要启动游戏）
# ------------------------------------------------------------
# 校验内容：
#   1. blockstate 引用的模型是否真实存在（tfcfarmingplus / tfc 命名空间）
#   2. 模型引用的贴图是否真实存在（含跨命名空间借用 TFC 贴图的占位方案）
#   3. loot table 引用的物品 ID 是否在本模组注册（用 models/item 与 lang 交叉验证）
#   4. 世界生成的 placed_feature → configured_feature 引用链是否完整
#   5. 追加式标签引用的 placed_feature 是否存在
#   6. lang 是否覆盖全部注册物品/方块
# 依赖：TFC 的 jar（用于确认借用的模型/贴图确实存在）
# ============================================================
param([string]$Root = '')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

if ([string]::IsNullOrWhiteSpace($Root)) {
    $root = (Resolve-Path (Join-Path $env:TFC_TOOLS_ROOT '..\src\main\resources')).Path
} else {
    $root = (Resolve-Path $Root).Path
}
$tfcJar = (Get-ChildItem (Join-Path (Split-Path (Split-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) -Parent) -Parent) 'mods') -File -Filter 'TerraFirmaCraft-*.jar' | Sort-Object Name -Descending | Select-Object -First 1).FullName
$utf8 = New-Object System.Text.UTF8Encoding($false)
$errors = New-Object System.Collections.ArrayList

# ---------- 1. 建立资源索引 ----------
$models = New-Object System.Collections.Generic.HashSet[string]
$textures = New-Object System.Collections.Generic.HashSet[string]
$features = New-Object System.Collections.Generic.HashSet[string]   # configured_feature
$placed = New-Object System.Collections.Generic.HashSet[string]     # placed_feature
$itemModels = New-Object System.Collections.Generic.HashSet[string] # tfcfarmingplus 物品模型 → 推断已注册物品

foreach ($f in Get-ChildItem -Recurse -File -Path $root -Filter *.json) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    if ($rel -match '^assets/([^/]+)/models/(.+)\.json$')            { [void]$models.Add("$($Matches[1]):$($Matches[2])") }
    if ($rel -match '^assets/([^/]+)/textures/(.+)\.png$')          { [void]$textures.Add("$($Matches[1]):$($Matches[2])") }
    if ($rel -match '^data/([^/]+)/worldgen/configured_feature/(.+)\.json$') { [void]$features.Add("$($Matches[1]):$($Matches[2])") }
    if ($rel -match '^data/([^/]+)/worldgen/placed_feature/(.+)\.json$')     { [void]$placed.Add("$($Matches[1]):$($Matches[2])") }
    if ($rel -match '^assets/tfcfarmingplus/models/item/(.+)\.json$')     { [void]$itemModels.Add($Matches[1]) }
}

# ⚠️ 上面那个循环用的是 `-Filter *.json`，**只索引了 JSON**；
#    可贴图是 PNG —— 那句 `textures/...png` 的判断写在 json 循环里，永远匹配不到。
#    以前没暴露，是因为我们的贴图全部跨命名空间借用 TFC 的（由下面第 2 步从 jar 索引到）；
#    一旦生成了自己的 PNG（见 tools/localize-textures.ps1），就会被误报成「贴图不存在」。
#    这里补一遍 PNG 扫描。
foreach ($f in Get-ChildItem -Recurse -File -Path $root -Filter *.png) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    if ($rel -match '^assets/([^/]+)/textures/(.+)\.png$') { [void]$textures.Add("$($Matches[1]):$($Matches[2])") }
}

# ---------- 2. 并入 TFC jar 的索引（用于跨命名空间借用） ----------
$z = [System.IO.Compression.ZipFile]::OpenRead($tfcJar)
foreach ($e in $z.Entries) {
    $n = $e.FullName
    if ($n -match '^assets/([^/]+)/models/(.+)\.json$')   { [void]$models.Add("$($Matches[1]):$($Matches[2])") }
    if ($n -match '^assets/([^/]+)/textures/(.+)\.png$')  { [void]$textures.Add("$($Matches[1]):$($Matches[2])") }
    if ($n -match '^data/([^/]+)/worldgen/configured_feature/(.+)\.json$') { [void]$features.Add("$($Matches[1]):$($Matches[2])") }
    if ($n -match '^data/([^/]+)/worldgen/placed_feature/(.+)\.json$')     { [void]$placed.Add("$($Matches[1]):$($Matches[2])") }
}

function ConvertTo-HashtableCompat($value) {
    if ($null -eq $value) { return $null }
    if ($value -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $value.Keys) { $result[$key] = ConvertTo-HashtableCompat $value[$key] }
        return $result
    }
    if ($value -is [pscustomobject]) {
        $result = @{}
        foreach ($property in $value.PSObject.Properties) {
            $result[$property.Name] = ConvertTo-HashtableCompat $property.Value
        }
        return $result
    }
    if ($value -is [System.Array]) {
        $result = @()
        foreach ($entry in $value) { $result += ,(ConvertTo-HashtableCompat $entry) }
        return $result
    }
    return $value
}

function Read-Json([string]$full) {
    $raw = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    # Windows PowerShell 5.1 的 ConvertFrom-Json 不接受空属性名；blockstate 允许 "" variant key。
    $raw = $raw -replace '""\s*:', '"__empty__":'
    $converter = Get-Command ConvertFrom-Json
    if ($converter.Parameters.ContainsKey('AsHashtable')) {
        return ($raw | ConvertFrom-Json -AsHashtable -Depth 100)
    }
    return ConvertTo-HashtableCompat ($raw | ConvertFrom-Json)
}

# minecraft 命名空间的原版资源不在索引里，一律跳过（无法验证）
function Test-Ref([string]$id, $set, [string]$kind) {
    if ($id -like 'minecraft:*') { return }
    if ($id -like '#*') { return }   # 贴图变量引用
    if (-not $set.Contains($id)) { [void]$errors.Add("$kind 不存在: $id") }
}

# ---------- 3. 校验 blockstate → 模型 ----------
$bsCount = 0
foreach ($f in Get-ChildItem -Recurse -File -Path (Join-Path $root 'assets/tfcfarmingplus/blockstates') -Filter *.json) {
    $bsCount++
    $json = Read-Json $f.FullName
    $vars = $json['variants']
    if ($null -eq $vars) {
        # 蔓延型作物（瓜类）的藤用 multipart，照 TFC 的 blockstates/crop/melon.json：
        # age 决定本体、四个方向各挂一条 side 模型。这不是「缺 variants」，是另一种合法写法，
        # 同样要把每个 apply.model 纳入校验。
        $mp = $json['multipart']
        if ($null -eq $mp) { [void]$errors.Add("blockstate 既无 variants 也无 multipart: $($f.Name)"); continue }
        foreach ($part in @($mp)) {
            $ap = $part['apply']
            if ($null -ne $ap) { foreach ($m in @($ap['model'])) { Test-Ref $m $models '模型' } }
        }
        continue
    }
    foreach ($v in $vars.Values) {
        if ($v -is [System.Collections.Generic.Dictionary[string,object]]) {
            foreach ($m in @($v['model'])) { Test-Ref $m $models '模型' }
        } elseif ($v -is [object[]]) {
            foreach ($sub in $v) { foreach ($m in @($sub['model'])) { Test-Ref $m $models '模型' } }
        }
    }
}

# ---------- 4. 校验模型 → 贴图 / 父模型 ----------
$mdlCount = 0
foreach ($f in Get-ChildItem -Recurse -File -Path (Join-Path $root 'assets/tfcfarmingplus/models') -Filter *.json) {
    $mdlCount++
    $json = Read-Json $f.FullName
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    $selfNs = 'tfcfarmingplus'
    if ($json.ContainsKey('parent')) {
        $p = [string]$json['parent']
        if ($p -notlike 'minecraft:*' -and $p -notlike '#*') {
            if ($p -notmatch ':') { $p = "minecraft:$p" }
            Test-Ref $p $models '父模型'
        }
    }
    if ($json.ContainsKey('textures')) {
        foreach ($t in $json['textures'].Values) {
            $t = [string]$t
            if ($t -like '#*') { continue }
            if ($t -notmatch ':') { $t = "${selfNs}:$t" }
            Test-Ref $t $textures '贴图'
        }
    }
}

# ---------- 5. 校验 loot table 物品 ID ----------
$lootCount = 0
foreach ($f in Get-ChildItem -Recurse -File -Path (Join-Path $root 'data/tfcfarmingplus/loot_table') -Filter *.json) {
    $lootCount++
    $txt = [System.IO.File]::ReadAllText($f.FullName, $utf8)
    foreach ($m in [regex]::Matches($txt, '"name":"(tfcfarmingplus:[^"]+)"')) {
        $id = $m.Groups[1].Value
        $path = $id.Substring('tfcfarmingplus:'.Length)
        if ($path -like 'food/*' -or $path -like 'seeds/*') {
            if (-not $itemModels.Contains($path)) { [void]$errors.Add("掉落表引用了没有物品模型的物品: $id  ($($f.Name))") }
        }
    }
}

# ---------- 6. 校验世界生成引用链 ----------
$cfCount = 0
foreach ($f in Get-ChildItem -Recurse -File -Path (Join-Path $root 'data/tfcfarmingplus/worldgen/configured_feature') -Filter *.json) {
    $cfCount++
    $json = Read-Json $f.FullName
    $cfg = $json['config']
    if ($null -ne $cfg -and $cfg.ContainsKey('feature')) {
        # ⚠️ 关键：minecraft:random_patch 的 config.feature 是 Holder<PlacedFeature>，
        #    必须去 placed_feature 集合里找；早期版本错写成查 configured_feature，
        #    导致「引用不存在的 placed_feature」这种致命错误被漏检（已实测踩坑）。
        $type = [string]$json['type']
        if ($type -eq 'minecraft:random_patch') {
            Test-Ref ([string]$cfg['feature']) $placed 'placed_feature(random_patch.config.feature)'
        } else {
            Test-Ref ([string]$cfg['feature']) $features 'configured_feature'
        }
    }
}
$pfCount = 0
foreach ($f in Get-ChildItem -Recurse -File -Path (Join-Path $root 'data/tfcfarmingplus/worldgen/placed_feature') -Filter *.json) {
    $pfCount++
    $json = Read-Json $f.FullName
    Test-Ref ([string]$json['feature']) $features 'configured_feature(placed 引用)'
}

# ---------- 7. 校验追加式标签引用 ----------
$tagFile = Join-Path $root 'data/tfc/tags/worldgen/placed_feature/feature/crops.json'
$tagJson = Read-Json $tagFile
foreach ($v in $tagJson['values']) { Test-Ref ([string]$v) $placed 'placed_feature(标签引用)' }

# ---------- 8. 校验 lang 覆盖 ----------
$langZh = Read-Json (Join-Path $root 'assets/tfcfarmingplus/lang/zh_cn.json')
$langEn = Read-Json (Join-Path $root 'assets/tfcfarmingplus/lang/en_us.json')
$langMissing = 0
foreach ($f in Get-ChildItem -Recurse -File -Path (Join-Path $root 'assets/tfcfarmingplus/models/item') -Filter *.json) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    if ($rel -notmatch '^assets/tfcfarmingplus/models/item/(.+)\.json$') { continue }
    $path = $Matches[1]
    $key = if ($path -like 'food/*') { 'item.tfcfarmingplus.food.' + $path.Substring(5) }
           elseif ($path -like 'seeds/*') { 'item.tfcfarmingplus.seeds.' + $path.Substring(6) }
           elseif ($path -like 'plant/*') { 'block.tfcfarmingplus.plant.' + $path.Substring(6) }
           elseif ($path -like 'wild_crop/*') { 'block.tfcfarmingplus.wild_crop.' + $path.Substring(10) }
           else { $null }
    if ($null -eq $key) { continue }
    if (-not $langZh.ContainsKey($key)) { $langMissing++; [void]$errors.Add("zh_cn 缺语言键: $key") }
    if (-not $langEn.ContainsKey($key)) { $langMissing++; [void]$errors.Add("en_us 缺语言键: $key") }
}

# ---------- 9. 【反向检查】每个已注册物品都必须有物品模型 ----------
# 为什么需要这一段：正向检查只能发现「模型引用了不存在的资源」，
# 发现不了「物品存在但压根没有模型文件」——批次 1 的 10 个浆果食物正是这样漏掉的
# （游戏里表现为紫黑格，日志报 Unable to load model: 'tfcfarmingplus:item/food/<name>'）。
# 这里用语言键反推物品 id，再要求模型文件存在。
$itemModelPaths = New-Object System.Collections.Generic.HashSet[string]
foreach ($f in Get-ChildItem -Recurse -File -Path (Join-Path $root 'assets/tfcfarmingplus/models/item') -Filter *.json) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    if ($rel -match '^assets/tfcfarmingplus/models/item/(.+)\.json$') { [void]$itemModelPaths.Add($Matches[1]) }
}
$checkedItems = 0
foreach ($key in $langZh.Keys) {
    $path = $null
    if     ($key -match '^item\.tfcfarmingplus\.(.+)$')                        { $path = $Matches[1] -replace '\.', '/' }
    elseif ($key -match '^block\.tfcfarmingplus\.(plant|wild_crop)\.(.+)$')    {
        # 枯死灌木 / 枯死藤蔓照 TFC 是 registerNoItem（无方块物品），不要求物品模型
        if ($Matches[2] -eq 'dead_berry_bush' -or $Matches[2] -eq 'dead_cane') { continue }
        $path = "$($Matches[1])/$($Matches[2])"   # 有方块物品
    }
    # block.tfcfarmingplus.crop.* / dead_crop / dead_rosette 没有方块物品，跳过
    if (-not $path) { continue }
    $checkedItems++
    if (-not $itemModelPaths.Contains($path)) {
        [void]$errors.Add("已注册物品缺少物品模型: models/item/$path.json  （语言键 $key）")
    }
}

# ---------- 10. Reject orphan food/<name> references; allow reviewed inedible whole fruit. ----------
# 为什么需要这一段：gen-crops.ps1 里已经有 `if (-not $noFood)` 跳过生成，
# 但它**从不删除旧文件**，于是「早期生成过、后来才被标成 noFood」的作物会留下孤儿数据。
# 游戏里表现为启动即报：
#   food 'tfcfarmingplus:hops' failed to parse. ...
#   Unknown registry key in ResourceKey[minecraft:root / minecraft:item]: tfcfarmingplus:food/hops
# （hops 的产物就是 hops 本身，压根没有 food/hops 这个注册项。）
# 本模组已实测踩过一次，加这段防回归。
$cropManifest = Join-Path $env:TFC_TOOLS_ROOT 'contracts/crops-manifest.json'
if (Test-Path $cropManifest) {
    $mf = [System.IO.File]::ReadAllText($cropManifest, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    $noFoodNames = @($mf.crops | Where-Object { $_.noFood } | ForEach-Object { $_.name })
    $foodDir = Join-Path $root 'data/tfcfarmingplus/tfc/food'
    if (Test-Path $foodDir) {
        foreach ($jf in (Get-ChildItem -File -Path $foodDir -Filter *.json)) {
            if ($noFoodNames -contains $jf.BaseName) {
                $shape = @($mf.crops | Where-Object { $_.name -eq $jf.BaseName })
                $definition = Read-Json $jf.FullName
                if ($shape.Count -eq 1 -and $shape[0].spread -and
                    $definition.ingredient.item -eq "tfcfarmingplus:$($jf.BaseName)" -and $definition.edible -eq $false) {
                    continue
                }
                [void]$errors.Add("noFood 作物不该有食物数据（没有 food/$($jf.BaseName) 物品，游戏会报 Unknown registry key）: tfc/food/$($jf.Name)")
            }
        }
    }
}

# ---------- 11. 果树掉落表必须与 TFC 原版语义一致 ----------
# 为什么需要：果树掉落表是**易错点**，本工程实测踩过两次 ——
#   ① 枝干漏了「斧头砍掉『向上 + 有水平分枝』的枝 → 掉一棵树苗」，
#      而这是果树唯一的自然繁殖途径（用户点名问「树苗掉落」才发现）；
#   ② 树叶的木棍池把 `inverted`(剪刀/精准采集) 挂在 **pool** 上而不是 **alternatives 条目**上 ——
#      挂在池上时条件不满足会消耗掉这次 rolls，语义不同。
# 这类细节凭直觉写不对，所以直接把 TFC 的 cherry_* 当基准做递归比较。
#
# ⚠️ **必须忽略键序**：不能用 `ConvertTo-Json` 后比字符串 ——
#    那样 `{"type":"uniform","min":1,"max":4}` 与 `{"min":1,"max":4,"type":"uniform"}`
#    会被判成不同（本工程因此报过一次**假阳性**）。
function Compare-JsonTree($a, $b, [string]$path) {
    $diffs = @()
    if ($null -eq $a -and $null -eq $b) { return $diffs }
    if ($null -eq $a -or $null -eq $b) { return @("$path 一侧为空") }
    if ($a -is [System.Management.Automation.PSCustomObject] -and $b -is [System.Management.Automation.PSCustomObject]) {
        $ka = @($a.PSObject.Properties.Name | Sort-Object)
        $kb = @($b.PSObject.Properties.Name | Sort-Object)
        $onlyA = @($ka | Where-Object { $kb -notcontains $_ })
        $onlyB = @($kb | Where-Object { $ka -notcontains $_ })
        if ($onlyA.Count) { $diffs += "$path 多出字段 [$($onlyA -join ',')]" }
        if ($onlyB.Count) { $diffs += "$path 缺少字段 [$($onlyB -join ',')]" }
        foreach ($k in @($ka | Where-Object { $kb -contains $_ })) { $diffs += (Compare-JsonTree $a.$k $b.$k "$path.$k") }
    } elseif ($a -is [System.Array] -and $b -is [System.Array]) {
        if ($a.Count -ne $b.Count) { return @("$path 数组长度 $($a.Count) vs $($b.Count)") }
        for ($i = 0; $i -lt $a.Count; $i++) { $diffs += (Compare-JsonTree $a[$i] $b[$i] "$path[$i]") }
    } else {
        $sa = "$a" -replace 'tfcfarmingplus:plant/pear',   'X:plant/T' -replace 'tfcfarmingplus:food/pear',   'X:food/T' -replace 'firmalife:food/cocoa_beans', 'X:food/T'
        $sb = "$b" -replace 'tfc:plant/cherry',            'X:plant/T' -replace 'tfc:food/cherry',            'X:food/T'
        if ($sa -ne $sb) { $diffs += "$path 值 '$sa' vs '$sb'" }
    }
    return $diffs
}
function Read-ZipEntryText($zip, [string]$name) {
    $en = $zip.Entries | Where-Object { $_.FullName -eq $name } | Select-Object -First 1
    if (-not $en) { return $null }
    $sr = New-Object System.IO.StreamReader($en.Open(), [System.Text.Encoding]::UTF8)
    $txt = $sr.ReadToEnd(); $sr.Close(); return $txt
}
$treeManifestPath = Join-Path $env:TFC_TOOLS_ROOT 'contracts/fruit-trees-manifest.json'
if (Test-Path $treeManifestPath) {
    $treeNamesV = @(([System.IO.File]::ReadAllText($treeManifestPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).trees | ForEach-Object { $_.name })
    $parts = @('sapling', 'leaves', 'branch', 'growing_branch')
    $lootChecked = 0
    foreach ($tn in $treeNamesV) {
        foreach ($pt in $parts) {
            $minePath = Join-Path $root "data/tfcfarmingplus/loot_table/blocks/plant/${tn}_$pt.json"
            if (-not (Test-Path $minePath)) { [void]$errors.Add("果树掉落表缺失: ${tn}_$pt.json"); continue }
            $baseTxt = Read-ZipEntryText $z "data/tfc/loot_table/blocks/plant/cherry_$pt.json"
            if (-not $baseTxt) { continue }
            $mineTxt = [System.IO.File]::ReadAllText($minePath, [System.Text.Encoding]::UTF8)
            $a = $mineTxt | ConvertFrom-Json
            $b = $baseTxt | ConvertFrom-Json
            # 归一化树名：把我们的 <tn> 换成 pear，好和基准的 cherry 对齐
            $aNorm = ($mineTxt -replace [regex]::Escape("tfcfarmingplus:plant/${tn}"), 'tfcfarmingplus:plant/pear' `
                                -replace [regex]::Escape("tfcfarmingplus:food/${tn}"),  'tfcfarmingplus:food/pear') | ConvertFrom-Json
            # The dedicated branch audit checks the exact extra pool. Compare
            # the remaining two native pools without weakening their baseline.
            if ($pt -eq 'branch' -and $tn -in @('jabuticaba','soursop','mangosteen','cupuacu','bael','canistel','black_pepper')) {
                $aNorm.pools = @($aNorm.pools | Where-Object {$_.name -ne 'tfcfarmingplus_branch_fruit'})
            }
            # Legacy cocoa keeps its block conditions, but drops modern cupuacu
            # saplings/leaves. Normalize only this explicitly reviewed alias.
            if ($tn -eq 'cocoa') {
                $aNorm = (($aNorm | ConvertTo-Json -Depth 100 -Compress) -replace
                    'tfcfarmingplus:plant/cupuacu', 'tfcfarmingplus:plant/pear') | ConvertFrom-Json
            }
            $d = @(Compare-JsonTree $aNorm $b 'root' | Where-Object { $_ })
            if ($d.Count -gt 0) {
                [void]$errors.Add("果树掉落表与 TFC 不一致 ${tn}_$pt.json: " + ($d | Select-Object -First 3 | ForEach-Object { $_ }) -join ' | ')
            }
            $lootChecked++
        }
    }
    if ($lootChecked -gt 0) { [void]$lootChecked }
    Write-Host "  [果树掉落表] 与 TFC cherry_* 基准比对 $lootChecked 个文件"
}

# ---------- 12. lang 里不得出现 null 值 ----------
# 为什么需要：这是本工程最隐蔽的一个坑。gen-crops.ps1 里曾把 $null 直接写进 lang，
# ConvertTo-Json 照实输出成 JSON 的 `null`：
#     "item.tfcfarmingplus.hops":null
# MC 用 Gson 逐键灌语言表，读到 JsonNull.getAsString() 抛异常并被 catch ——
# **该键之后的所有键全部丢弃**。表现为「hops 之前的作物名正常，之后 14 种果树全是原始键名」，
# 而文件内容、jar 打包、资源包覆盖逐项检查全都正常，极难定位。
# 这里直接扫两个 lang，任何 `:null` 都判错。
foreach ($langName in @('en_us', 'zh_cn')) {
    $langPath = Join-Path $root "assets/tfcfarmingplus/lang/$langName.json"
    if (-not (Test-Path $langPath)) { [void]$errors.Add("语言文件缺失: assets/tfcfarmingplus/lang/$langName.json"); continue }
    $langText = [System.IO.File]::ReadAllText($langPath, [System.Text.Encoding]::UTF8)
    $nullKeys = @([regex]::Matches($langText, '"([^"]+)":null') | ForEach-Object { $_.Groups[1].Value })
    if ($nullKeys.Count -gt 0) {
        [void]$errors.Add("$langName.json 存在值为 null 的键（会让其后的所有键在游戏内失效）: " + ($nullKeys -join ', '))
    }
}

# ---------- 13. Firmalife 果树叶掉落 modifier ----------
# 背景：Firmalife 给 TFC 那 8 种果树的树叶挂了一张额外掉落表 ——
# 「没用剪刀 / 精准采集时，50% 概率额外掉 1 个 firmalife:fruit_leaf」。
# 我们的 33 种果树树叶同样要有，做法是 neoforge:add_table 的 loot modifier。
# **刻意不改掉落表本身**，好让第 11 项「与 TFC cherry_* 语义一致」那条保护继续有效。
#
# ⚠️ 这里特别检查 id 的分隔符：PowerShell 里 `"$NS:xxx"` 的 `$NS:` 会被当成作用域变量
#    （同 $env:）而整段变空 —— 本项目在这个坑上已经栽过四次（§5.1 / §8.1-18）。
#    loot modifier 的 id 必须是 `tfcfarmingplus:pear_leaves` 这种**冒号**形式；
#    写成斜杠时文件照样生成、游戏里却完全加载不到，属于「静默失效」，最难查。
$glmPath = Join-Path $root 'data/tfcfarmingplus/loot_modifiers/global_loot_modifiers.json'
if (Test-Path $glmPath) {
    $glm = Read-Json $glmPath
    $entries = @($glm.entries)
    $treeManifestPath = Join-Path $env:TFC_TOOLS_ROOT 'contracts/fruit-trees-manifest.json'
    $treeCount = 0
    if (Test-Path $treeManifestPath) { $treeCount = @((Read-Json $treeManifestPath).trees).Count }
    if ($treeCount -gt 0 -and $entries.Count -ne $treeCount) {
        [void]$errors.Add("loot modifier 条目数 $($entries.Count) 与树种数 $treeCount 不一致")
    }
    $checkedMods = 0
    foreach ($id in $entries) {
        $s = [string]$id
        if ($s -notmatch '^[a-z0-9_]+:[a-z0-9_/]+$') {
            [void]$errors.Add("loot modifier id 格式错误（必须是 ns:path 的冒号形式）: $s")
            continue
        }
        $modRel = 'data/tfcfarmingplus/loot_modifiers/' + ($s -replace '^[^:]+:', '') + '.json'
        $modPath = Join-Path $root $modRel
        if (-not (Test-Path $modPath)) { [void]$errors.Add("loot modifier 文件缺失: $s"); continue }
        $mod = Read-Json $modPath
        if ($mod.table -ne 'firmalife:blocks/fruit_leaves') {
            [void]$errors.Add("loot modifier $s 的 table 应为 firmalife:blocks/fruit_leaves，实际为 $($mod.table)")
        }
        $ltId = [string]$mod.conditions[0].loot_table_id
        $ltRel = 'data/tfcfarmingplus/loot_table/' + ($ltId -replace '^[^:]+:', '') + '.json'
        if (-not (Test-Path (Join-Path $root $ltRel))) {
            [void]$errors.Add("loot modifier $s 指向的掉落表不存在: $ltId")
        }
        $checkedMods++
    }
    Write-Host "  [Firmalife 果树叶掉落] modifier $checkedMods 个，与 $treeCount 种树一一对应"
}

$z.Dispose()

# Source/resource crop contracts complement reference existence checks.
& (Join-Path $env:TFC_TOOLS_ROOT 'audit-crop-contracts.ps1') -Resources $root
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Crop source/resource contract check failed; see its findings above.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-tree-contracts.ps1') -Resources $root
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Tree source/resource contract check failed; see its findings above.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-branch-fruit-contracts.ps1') -Resources $root
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Branch-fruit contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-bush-contracts.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Bush contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-soil-contracts.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Soil nutrient/fertilizer contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-leaf-vegetable-models.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Leaf vegetable model contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-rosette-fruit-support.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Rosette mature fruit support contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-rosette-dead-consumers.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Shared dead rosette consumer contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-leafball-support.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Shared leafball support contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-chili-display.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Chili display contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-fenugreek-display.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Fenugreek display contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-spinach-display.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Spinach display contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-sunflower-display.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Sunflower display contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-swiss-chard-display.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Swiss chard display contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-celery-display.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Celery display contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-celtuce-display.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Celtuce display contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-rhubarb-display.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Rhubarb display contracts failed.') }

& (Join-Path $env:TFC_TOOLS_ROOT 'audit-item-icon-routes.ps1')
if ($LASTEXITCODE -ne 0) { [void]$errors.Add('Reviewed item icon contracts failed.') }

# ---------- 汇总 ----------
Write-Host "索引: 模型 $($models.Count) / 贴图 $($textures.Count) / configured_feature $($features.Count) / placed_feature $($placed.Count)"
Write-Host "已校验: blockstate $bsCount / 模型 $mdlCount / 掉落表 $lootCount / configured_feature $cfCount / placed_feature $pfCount / 物品模型 $checkedItems"
if ($errors.Count -eq 0) {
    Write-Host "结果: 全部交叉引用有效，未发现问题"
} else {
    Write-Host "结果: 发现 $($errors.Count) 个问题"
    $errors | Select-Object -First 40 | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
