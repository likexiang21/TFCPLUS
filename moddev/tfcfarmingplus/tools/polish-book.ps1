# ============================================================
# 手册条目字段对齐（照 TFC field_guide 的用法）
# ------------------------------------------------------------
# 内容写在 TFC 原版 field_guide 的新选项卡 tfc:farming_plus 下，共 4 个条目。
# 本脚本做两件事（照 TFC 的条目字段规范）：
#   1. 补 read_by_default + sortnum（TFC 的每条 entry 都带）
#   2. 生成 extra_recipe_mappings —— **「物品 → 本条目第 N 页」的跳转映射**：
#      在 JEI/REI 里查看该物品时会出现「跳转到手册此页」的按钮
#      （TFC 的 food/farmland.json 就是这么写的：{"tfc:dirt/entisol":2,...}，页码为 0 基）
# 幂等，可反复执行。
# ============================================================
param([string]$OutputRoot = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'cocoa-data-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $OutputRoot
$cocoaPolicy = Read-CocoaPolicy

# ⚠️ 作物名单不在本脚本里维护 —— 一律从 gen-crops.ps1 导出的清单读（§5.34）。
#    以前名单散落四处，加作物漏改一处**不报错、只静默少东西**，连续踩了两次。
$cropsManifest = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'crops-manifest.json'), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$cropNames        = @($cropsManifest.crops | ForEach-Object { $_.name })
$noFoodCrops      = @($cropsManifest.crops | Where-Object { $_.noFood } | ForEach-Object { $_.name })
$spreadCrops      = @($cropsManifest.crops | Where-Object { $_.spread } | ForEach-Object { $_.name })
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$utf8 = New-Object System.Text.UTF8Encoding($false)

$ENTRIES = 'assets/tfc/patchouli_books/field_guide'
$NS = 'tfcfarmingplus'

$smallBushNames  = @('lingonberry','bearberry','crowberry','bilberry')
$highBushNames2  = @('blackcurrant','redcurrant','haskap','goji','serviceberry','aronia','tea','coffee')
# 产物物品名与灌木名不同的：茶树 → 茶叶，咖啡树 → 咖啡豆。
# 不特判会写出 food/tea 这种不存在的映射，Patchouli 直接报 Invalid extra recipe mapping。
$bushProduct = @{ tea = 'tea_leaf'; coffee = 'coffee_bean' }
# 果树清单：同样读 gen-fruit-trees.ps1 导出的 manifest，保持「树名只有一处定义」。
$treeNames2 = @(
    ([System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fruit-trees-manifest.json'),
        [System.Text.Encoding]::UTF8) | ConvertFrom-Json).trees |
        Where-Object { $_.name -ne $cocoaPolicy.legacy_tree } | ForEach-Object { $_.name })
# 条目 -> (页码基数, 植物清单, 映射类型)
#   bushes: 3 页总述 + 1 页日历表 -> index 4 起是 10 株，每株 2 页（文字 + 多块）
#   trees : 1 页总述 + 1 页空页（凑跨页对齐，见 gen-patchouli-book.ps1）-> index 2 起是 14 株，每株 2 页（文字页 + multimultiblock）
#   crops : 3 页总述 + 1 页空页（凑偶数索引，见 gen-patchouli-book.ps1）-> index 4 起，每株 2 页
#   wild  : 2 页总述 -> index 2 起是 8 株，每株 1 页
$plan = [ordered]@{
    'intro'      = [ordered]@{ base = 0; step = 1; names = @(); kind = 'intro' }
    'bushes'      = [ordered]@{ base = 4; step = 2; names = $smallBushNames; kind = 'bush' }
    'bushes_high' = [ordered]@{ base = 4; step = 2; names = $highBushNames2; kind = 'bush' }
    'fruit_trees' = [ordered]@{ base = 2; step = 2; names = $treeNames2; kind = 'tree' }
    'crops'      = [ordered]@{ base = 2; step = 2; names = $cropNames; kind = 'crop' }
    'wild_crops' = [ordered]@{ base = 1; step = 1; names = $cropNames; kind = 'wild' }
}

$count = 0
foreach ($lang in @('en_us','zh_cn')) {
    $sortnum = 1
    foreach ($name in $plan.Keys) {
        $rel  = "$ENTRIES/$lang/entries/farming_plus/$name.json"
        $path = Join-Path $root $rel
        if (-not (Test-Path $path)) { Write-Host "    !! 缺文件: $rel"; continue }
        $j = $ser.DeserializeObject([System.IO.File]::ReadAllText($path, $utf8))

        # 页码一律**从手册条目里的 anchor 反推**，不再按名字清单自己算。
        # ⚠️ 两份清单顺序一旦不一致，跳转会静默指向别的作物（§5.29 实测：seeds/water_shield 跳到了苎麻页）。
        $pagesOf = @{}
        foreach ($en in $plan.Keys) {
            $pth = Join-Path $root "$ENTRIES/$lang/entries/farming_plus/$en.json"
            if (-not (Test-Path $pth)) { continue }
            $jj = $ser.DeserializeObject([System.IO.File]::ReadAllText($pth, $utf8))
            $pi = 0
            foreach ($pg in $jj['pages']) {
                if ($pg['anchor']) { $pagesOf["$en/$($pg['anchor'])"] = $pi }
                $pi++
            }
        }
        $info = $plan[$name]

        $map = [ordered]@{}
        $i = 0
        foreach ($pn in $info['names']) {
            # 优先用 anchor 查出来的真实页码；查不到才退回按序号推算
            $page = if ($pagesOf.ContainsKey("$name/$pn")) { $pagesOf["$name/$pn"] } else { $info['base'] + $info['step'] * $i }
            switch ($info['kind']) {
                'bush' {
                    $map["$NS`:plant/${pn}_bush"] = $page     # 灌木方块物品
                    # 茶树/咖啡树的产物名与灌木名不同，要按 $bushProduct 取名
                    $prodName = if ($bushProduct.ContainsKey($pn)) { $bushProduct[$pn] } else { $pn }
                    $map["$NS`:food/$prodName"]   = $page     # 浆果/茶叶/咖啡豆产物
                }
                'crop' {
                    # 产物与种子都指向**栽培页** —— 种子是"怎么种"的东西，
                    # 玩家在 JEI 里点种子时想看的是栽培说明，而不是野生分布。
                    # ⚠️ 亚麻/苎麻没有自己的食物物品（产物是 tfc:jute_fiber），
                    #    给它们写 food/<n> 映射会让 Patchouli 报 "Invalid extra recipe mapping"。
                    if ($spreadCrops -contains $pn) {
                        # 蔓延型瓜类：整瓜（结果方块物品）+ 切片 + 种子，**没有** food/<n>
                        $map["$NS`:$pn"]              = $page
                        $map["$NS`:food/${pn}_slice"] = $page
                        $map["$NS`:seeds/$pn"]        = $page
                    } else {
                    if ($noFoodCrops -notcontains $pn) { $map["$NS`:food/$pn"] = $page }
                    $map["$NS`:seeds/$pn"]        = $page     # 种子
                    }
                }
                'wild' {
                    # 只映射野生植株本身。同一个物品不能同时出现在两个条目的映射里，
                    # 否则点击时会跳到后写入的那一条（seed 之前就因此跳到了野生作物页）。
                    $map["$NS`:wild_crop/$pn"]    = $page     # 野生植株
                }
                'tree' {
                    # 果树的三个物品全部指向**同一页**（该树的文字页）：
                    # 树苗是「怎么种」，树叶是「果实挂在哪」，果实在同一页说明，跳开反而割裂。
                    $map["$NS`:plant/${pn}_sapling"] = $page  # 树苗
                    $map["$NS`:plant/${pn}_leaves"]  = $page  # 树叶（结果期挂果）
                    if ($pn -ne $cocoaPolicy.tree) { $map["$NS`:food/$pn"] = $page }
                }
            }
            $i++
        }

        $out = [ordered]@{
            name            = $j['name']
            category        = $j['category']
            icon            = $j['icon']
            pages           = $j['pages']
            read_by_default = $true
            sortnum         = $sortnum
        }
        if ($map.Count -gt 0) { $out['extra_recipe_mappings'] = $map }
        [System.IO.File]::WriteAllText($path, $ser.Serialize($out), $utf8)
        $sortnum++; $count++
        Write-Host ("  {0,-12} {1,-6} 跳转映射 {2} 项" -f $name, $lang, $map.Count)
    }
}
Write-Host "已对齐的条目: $count 个"

# 校验：字段齐全 + 映射页码不超过该条目页数
$bad = 0
foreach ($f in (Get-ChildItem -Recurse -File -Path (Join-Path $root "$ENTRIES/en_us/entries/farming_plus") -Filter *.json)) {
    $j = $ser.DeserializeObject([System.IO.File]::ReadAllText($f.FullName, $utf8))
    if (-not $j.ContainsKey('read_by_default') -or -not $j.ContainsKey('sortnum')) { $bad++; Write-Host "  !! 缺字段: $($f.Name)" }
    if ($j['category'] -ne 'tfc:farming_plus') { $bad++; Write-Host "  !! category 错误: $($f.Name)" }
    if ($j.ContainsKey('extra_recipe_mappings')) {
        $pages = @($j['pages']).Count
        foreach ($k in $j['extra_recipe_mappings'].Keys) {
            $v = [int]$j['extra_recipe_mappings'][$k]
            if ($v -lt 0 -or $v -ge $pages) { $bad++; Write-Host "  !! $($f.Name): $k 的页码 $v 超出页数 $pages" }
        }
    }
}
Write-Host $(if ($bad -eq 0) { "校验通过" } else { "校验失败: $bad 处" })
if ($bad -gt 0) { exit 1 }
