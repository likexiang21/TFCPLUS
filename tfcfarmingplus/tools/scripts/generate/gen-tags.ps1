# ============================================================
# 标签（tag）统一生成器 —— 本模组所有 tag 的唯一来源
# ============================================================
# 设计：**全量写入本模组的条目**，不做"读取已有再合并"。
#   因为我们的 tag 文件只装自己的条目（TFC 的条目在 TFC 自己的 jar 里，
#   数据包加载时自动合并），所以每次全量覆盖写是正确且幂等的。
#   ⚠️ 早期试过"读取已有→追加去重"，但 PS 对反序列化结果的类型包装会让读取失效，
#      导致条目重复（实测 flax/sesame/safflower 各出现两次）。集中全量写入没有这个问题。
#
# 对齐 TFC 4.2.10 原版植物的 tag 归属：
#   浆果灌木   → minecraft:mineable/hoe + tfc:fox_raidable（+ 世界生成标签 berry_bushes）
#   作物       → minecraft:mineable/hoe + tfc:crops
#   野生作物   → 上述三项 + tfc:can_be_snow_piled
#   产物       → c:foods/{vegetable,grain,fruit} 与 c:seeds
# ============================================================
param([string]$Root = '')
$ErrorActionPreference = 'Stop'

# ⚠️ 作物名单不在本脚本里维护 —— 一律从 gen-crops.ps1 导出的清单读（§5.34/§5.35）。
#    以前名单散落在四个脚本里，加一种作物要改四处，漏一处**不报错、只静默少东西**。
$cropsManifest = [System.IO.File]::ReadAllText((Join-Path $env:TFC_TOOLS_ROOT 'contracts/crops-manifest.json'), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$cropNames     = @($cropsManifest.crops | ForEach-Object { $_.name })
$noFoodCrops   = @($cropsManifest.crops | Where-Object { $_.noFood } | ForEach-Object { $_.name })
# ⚠️ 莲座作物（RosetteCropBlock）用**共享的** tfcfarmingplus:dead_rosette，
#    根本不存在 tfcfarmingplus:dead_crop/<n> 这个方块。
#    无条件把 dead_crop/<n> 写进 tfc:crops 与 minecraft:mineable/hoe，会让这两个标签
#    **整个加载失败**（TagLoader: "Couldn't load tag ... as it is missing following references"），
#    并级联拖垮 tfc:mineable/scythe 与 tfc:mineable/knife —— 实机实测 10 条 ERROR。
#    注意：这个标记由 gen-crops.ps1 导出，漏加就退回"无条件写"的老行为。
$rosetteCrops  = @($cropsManifest.crops | Where-Object { $_.rosette } | ForEach-Object { $_.name })

Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
. (Join-Path $env:TFC_TOOLS_ROOT 'cocoa-data-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $Root
$utf8 = New-Object System.Text.UTF8Encoding($false)
$NS = 'tfcfarmingplus'

function Save-Tag([string]$rel, $values) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize([ordered]@{ replace = $false; values = @($values) }), $utf8)
    Write-Host ("  {0,-50} {1} 项" -f $rel, @($values).Count)
}

# ---------------- 名单 ----------------
# 浆果灌木（12 种；tea/coffee 是茶树与咖啡树，同走灌木机制）
$bushNames = @('lingonberry','bearberry','crowberry','bilberry','blackcurrant','redcurrant','haskap','goji','serviceberry','aronia','tea','coffee')
# 蔓生形态的 8 种（其余 4 种是矮丛形态）——决定是否有配套的 *_bush_cane 枝叶方块
$highBushNames = @('blackcurrant','redcurrant','haskap','goji','serviceberry','aronia','tea','coffee')
# 草莓使用 TFC 原版果实；旧项目草莓仅作存档兼容，不回填公共水果标签。
# 本段只有真正的**浆果**产物才进 c:foods/fruit：茶树/咖啡树的产物是 tea_leaf / coffee_bean，
# 既不是水果、名字也对不上，写进去会引用不存在的物品（§5.22）。
$berryBushNames = @('lingonberry','bearberry','crowberry','bilberry','blackcurrant','redcurrant','haskap','goji','serviceberry','aronia')
# 谷物类产物的营养类型是 grain 而不是 vegetable（照 TFC：tfc:food/wheat_grain 等在 c:foods/grain）
$grainNames = @('millet','foxtail_millet','buckwheat','fonio','spelt','emmer','einkorn','pearl_millet','amaranth','quinoa','finger_millet','jobs_tears','sorghum')

# ⚠️ $noFoodCrops 来自 gen-crops 导出的清单（noFood 标记）：
#   亚麻/苎麻 → tfc:jute_fiber，棉花 → cotton_boll，蔓延型瓜类 → 结果方块物品。
#   它们没有 food/<n>，写进蔬菜标签会报 "missing following references"（§5.34 踩过）。
# Canonical strawberry is TFC fruit; exclude its retired project item from vegetable generation.
$vegCropNames = $cropNames | Where-Object { ($grainNames -notcontains $_) -and ($noFoodCrops -notcontains $_) -and ($_ -ne 'strawberry') }

# ---------------- 收集 ----------------
$mineableHoe = @(); $cropTag = @(); $snowPiled = @()
$wildItems = @(); $vegItems = @(); $seedItems = @()
foreach ($n in $cropNames) {
    $mineableHoe += "${NS}:crop/$n", "${NS}:wild_crop/$n"
    $cropTag     += "${NS}:crop/$n", "${NS}:wild_crop/$n"
    # 莲座没有 per-crop 死株（用共享 dead_rosette）—— 写进去会让标签整个加载失败，见上方注释
    if ($rosetteCrops -notcontains $n) {
        $mineableHoe += "${NS}:dead_crop/$n"
        $cropTag     += "${NS}:dead_crop/$n"
    }
    $snowPiled   += "${NS}:wild_crop/$n"
    $wildItems   += "${NS}:wild_crop/$n"
    $seedItems   += "${NS}:seeds/$n"
}
foreach ($n in $vegCropNames) { $vegItems += "${NS}:food/$n" }

# 灌木：主丛 + （蔓生形态的）枝叶；再加两种共用的枯死方块
foreach ($b in $bushNames)     { $mineableHoe += "${NS}:plant/${b}_bush" }
foreach ($b in $highBushNames) { $mineableHoe += "${NS}:plant/${b}_bush_cane" }
$mineableHoe += "${NS}:plant/dead_berry_bush", "${NS}:plant/dead_cane"

# ---------------- 方块标签 ----------------
Save-Tag 'data/minecraft/tags/block/mineable/hoe.json' $mineableHoe
Save-Tag 'data/tfc/tags/block/fox_raidable.json'       @($bushNames | ForEach-Object { "${NS}:plant/${_}_bush" })
Save-Tag 'data/tfc/tags/block/crops.json'              $cropTag
Save-Tag 'data/tfc/tags/block/can_be_snow_piled.json'  $snowPiled
# 蔓生灌木的**枯死**方块（活着的主丛在 living 里）
Save-Tag 'data/tfc/tags/block/spreading_bushes.json'   @("${NS}:plant/dead_berry_bush", "${NS}:plant/dead_cane")
# 活着的蔓生灌木：8 个主丛 + 8 条枝叶
$living = @()
foreach ($b in $highBushNames) { $living += "${NS}:plant/${b}_bush", "${NS}:plant/${b}_bush_cane" }
Save-Tag 'data/tfc/tags/block/spreading_bushes/living.json' $living
# 带刺的灌木（TFC 用这个标签处理"走过会扎人"）
Save-Tag 'data/tfc/tags/block/thorny_bushes.json'      @("${NS}:plant/goji_bush")

# ---------------- 果树标签（TFC 的果树机制靠这些标签识别）----------------
# ⚠️ 漏了它们，梨树虽然是「像果树的东西」，却不会被 TFC 当成果树看待：
#   fruit_tree_saplings  树苗（世界生成、其它机制按它识别）
#   fruit_tree_branches  **树枝**（含 branch 与 growing_branch 两种）
#   fruit_tree_leaves    树叶
# 第一版梨树就是漏了这三个标签 —— 用户点名「连树枝都没加」。
# 树名从 gen-fruit-trees.ps1 导出的 manifest 读 —— 单一数据源，避免「加了一种树却忘了加标签」。
# （crops-manifest.json 用的是同一套模式。）
$treeManifest = Join-Path $env:TFC_TOOLS_ROOT 'contracts/fruit-trees-manifest.json'
if (-not (Test-Path $treeManifest)) { throw "缺少 $treeManifest —— 请先运行 gen-fruit-trees.ps1" }
$treeNames = @(([System.IO.File]::ReadAllText($treeManifest, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).trees | ForEach-Object { $_.name })
if ($treeNames.Count -eq 0) { throw "fruit-trees-manifest.json 里没有树" }
Save-Tag 'data/tfc/tags/block/fruit_tree_saplings.json' @($treeNames | ForEach-Object { "${NS}:plant/${_}_sapling" })
$treeBranches = @()
foreach ($tr in $treeNames) { $treeBranches += "${NS}:plant/${tr}_branch", "${NS}:plant/${tr}_growing_branch" }
Save-Tag 'data/tfc/tags/block/fruit_tree_branches.json' $treeBranches
Save-Tag 'data/tfc/tags/block/fruit_tree_leaves.json' @($treeNames | ForEach-Object { "${NS}:plant/${_}_leaves" })

# Firmalife 的开花期蜜蜂粒子：树叶同时「在这个标签里」且「LIFECYCLE=FLOWERING」时才会冒蜜蜂
# （Firmalife 的 FLFruitTreeLeavesBlock.animateTick 里 random.nextInt(100)==0 触发 SwarmEffect）。
# 这属于果树机制的一部分，所以和果树标签写在一起。Firmalife 原本只登记了它自己的 fig_leaves。
Save-Tag 'data/firmalife/tags/block/buzzing_leaves.json' @($treeNames | ForEach-Object { "${NS}:plant/${_}_leaves" })

# 原版标签 —— 对照 TFC 的 cherry_* **全部命中位置**后补齐的三项（此前漏掉，属于机制缺口）：
#   minecraft:mineable/axe  枝干与树叶是木头类，用斧头挖才快（TFC 的 cherry_branch/leaves 都在这）
#   minecraft:leaves        原版树叶标签（影响树叶的渲染与破坏语义）
#   minecraft:item/leaves   对应的物品标签
Save-Tag 'data/minecraft/tags/block/mineable/axe.json' @($treeNames | ForEach-Object {
    "${NS}:plant/${_}_branch"; "${NS}:plant/${_}_growing_branch"; "${NS}:plant/${_}_leaves"
})
Save-Tag 'data/minecraft/tags/block/leaves.json' @($treeNames | ForEach-Object { "${NS}:plant/${_}_leaves" })
Save-Tag 'data/minecraft/tags/item/leaves.json'  @($treeNames | ForEach-Object { "${NS}:plant/${_}_leaves" })

# ---------------- 物品标签 ----------------
Save-Tag 'data/tfc/tags/item/wild_crops.json'          $wildItems
Save-Tag 'data/c/tags/item/foods/vegetable.json'       $vegItems
Save-Tag 'data/c/tags/item/foods/grain.json'           @($grainNames | ForEach-Object { "${NS}:food/$_" })
$fruitValues = @($berryBushNames | ForEach-Object { "${NS}:food/$_" })
$fruitValues += @($cropsManifest.crops | Where-Object { $_.spread } | ForEach-Object { "${NS}:food/$($_.name)_slice" })
# AR3-A/B reviewed temperate and tropical harvests; other groups await audit.
$temperateFruitNames = @('pear','apricot','quince','persimmon','pomegranate','loquat','sorb','mulberry','jujube','hawthorn','medlar','pawpaw','crabapple','cornelian_cherry')
$fruitValues += @($temperateFruitNames | ForEach-Object { "${NS}:food/$_" })
$tropicalFruitNames = @('mango','papaya','guava','lychee','longan','avocado','starfruit','tamarind','sapodilla','cherimoya','rambutan','durian','jackfruit','breadfruit')
$fruitValues += @($tropicalFruitNames | ForEach-Object { "${NS}:food/$_" })
$remainingFruitNames = @('waxberry','lime','grapefruit','kiwi','wax_apple','wampee','amla','sea_buckthorn')
$fruitValues += @($remainingFruitNames | ForEach-Object { "${NS}:food/$_" })
$branchFruitNames = @('jabuticaba','soursop','mangosteen','bael','canistel')
$fruitValues += @($branchFruitNames | ForEach-Object { "${NS}:food/$_" })
Save-Tag 'data/c/tags/item/foods/fruit.json' $fruitValues
# Reviewed nuts remain protein food; only the selected native meal entry tags are extended.
$nutFoodNames = @('walnut','hazelnut','almond','pecan','macadamia')
Save-Tag "data/${NS}/tags/item/foods/nuts.json" @($nutFoodNames | ForEach-Object { "${NS}:food/$_" })
Save-Tag 'data/c/tags/item/foods.json' @("#${NS}:foods/nuts")
foreach ($meal in @('soup','salad','sandwich')) {
    Save-Tag "data/tfc/tags/item/usable_in_${meal}.json" @("#${NS}:foods/nuts")
}
Save-Tag 'data/c/tags/item/seeds.json'                 $seedItems
# Whole project melons follow the native pumpkin/melon high-green compost route.
$wholeMelonItems = @($cropsManifest.crops | Where-Object { $_.spread } | ForEach-Object { "${NS}:$($_.name)" })
Save-Tag 'data/tfc/tags/item/compost_greens/high.json' $wholeMelonItems
# Harvested fibers are already material items, separate from raw-stem processing plans.
$plantFiberItems = @('fiber/flax','fiber/hemp','fiber/ramie','fiber/sisal') | ForEach-Object { "${NS}:$_" }
Save-Tag "data/${NS}/tags/item/materials/plant_fibers.json" $plantFiberItems
Save-Tag 'data/tfc/tags/item/compost_browns/high.json' (@($plantFiberItems) + @("${NS}:cotton_boll"))
Save-Tag 'data/tfc/tags/item/compost_greens/low.json' @("${NS}:hops", "${NS}:food/tea_leaf", "${NS}:food/coffee_bean")
Write-Host "tag 生成完成（全量写入，replace:false 与 TFC 合并）"
