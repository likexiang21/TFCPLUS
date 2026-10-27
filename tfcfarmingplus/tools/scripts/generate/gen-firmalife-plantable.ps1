# ============================================================
# 生成 Firmalife 的种植盆（planter）数据
# ------------------------------------------------------------
# 为什么需要：Firmalife 的物品提示里那两行
#     「可种植于 格子种植架」
#     「营养（仅用于种植盆）：(N) (P) (K)」
# 来自它自己的数据驱动类型 Plantable（data/firmalife/firmalife/plantable/*.json）。
# Firmalife 连 TFC 的原版植物（beet / cabbage / cloudberry / strawberry …）都写了这份数据，
# 所以 TFC 的浆果灌木在提示里会显示这两行；本模组的植物此前没有，因此缺失。
#
# 结构（照 Firmalife 的 Plantable record）：
#   record Plantable(Ingredient ingredient, PlanterType planter, int tier, int stages,
#                    float extraSeedChance, ItemStack seed, ItemStack crop,
#                    NutrientList nutrient, List<ResourceLocation> textures, List<ResourceLocation> specials)
# PlanterType 取值：QUAD / LARGE / TRELLIS / HYDROPONIC
#
# 模板对照（实测 Firmalife 生成数据）：
#   灌木 cloudberry.json → planter=trellis, tier=15, extra_seed_chance=0.08, 4 张 lifecycle 贴图
#   作物 cabbage.json    → planter=quad,    stages=5, 6 张 age 贴图（无 tier / extra_seed_chance）
#
# 贴图沿用本工程一贯的「占位借用」策略：灌木借用 TFC 的 berry_bush 贴图，作物借用 TFC 的 crop 贴图。
# 将来换成自有美术时，只改 textures 数组即可。
# ============================================================
param([string]$OutputRoot = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $env:TFC_TOOLS_ROOT 'cocoa-data-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $OutputRoot
$cocoaPolicy = Read-CocoaPolicy
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

$NS = 'tfcfarmingplus'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$count = 0

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($obj), $utf8)
    $script:count++
}

# 灌木：借用哪套 TFC berry_bush 贴图（12 种各不同）
$bushes = [ordered]@{
    lingonberry  = 'cranberry'
    bearberry    = 'bunchberry'
    crowberry    = 'wintergreen_berry'
    bilberry     = 'blueberry'
    blackcurrant = 'elderberry'
    redcurrant   = 'gooseberry'
    haskap       = 'blackberry'
    goji         = 'raspberry'
    serviceberry = 'snowberry'
    aronia       = 'cloudberry'
    # 茶树 / 咖啡树：与 crop\FarmingBushes.java 的 donor 保持一致（茶树=蓝莓、咖啡树=接骨木莓）
    tea          = 'blueberry'
    coffee       = 'elderberry'
}
# 作物：借用哪套 TFC crop 贴图（与方块模型一致）
$crops = [ordered]@{
    spinach        = 'beet'
    lettuce        = 'onion'
    celery         = 'onion'
    kale           = 'cabbage'
    napa_cabbage   = 'cabbage'
    mustard_greens = 'beet'
    broccoli       = 'cabbage'
    cauliflower    = 'cabbage'
}
# 与 crop\FarmingCrops.java 里一致的 NPK（正=消耗，负=补充）
$cropNpk = [ordered]@{
    spinach        = @(0.7, -0.2, -0.2)
    lettuce        = @(0.6, -0.2, -0.2)
    celery         = @(0.7,  0.3,  0.4)
    kale           = @(0.7,  0.2,  0.3)
    napa_cabbage   = @(0.7,  0.2,  0.4)
    mustard_greens = @(0.3,  0.25, 0.35)
    broccoli       = @(0.8,  0.3,  0.4)
    cauliflower    = @(0.8,  0.3,  0.4)
    taro           = @(0.45, 0.35, 0.6)
    water_chestnut = @(0.4, 0.3, 0.6)
    water_caltrop  = @(0.35, 0.3, 0.55)
    wild_rice_stem = @(0.5, 0.3, 0.5)
    lotus          = @(0.45, 0.35, 0.6)
    water_dropwort = @(0.5, 0.3, 0.4)
    water_spinach  = @(0.8, -0.2, -0.2)
    arrowhead      = @(0.45, 0.35, 0.55)
    gorgon_nut     = @(0.4, 0.3, 0.55)
    water_shield   = @(0.4, 0.2, 0.3)
}

# ---------- ① 浆果灌木：种在格子种植架（TRELLIS） ----------
# ⚠️ 茶树/咖啡树的**产物名与灌木名不同**（tea → food/tea_leaf，coffee → food/coffee_bean）。
#    不特判会写出 tfcfarmingplus:food/tea 这种不存在的物品，Firmalife 解析 plantable 时直接报
#    "Unknown registry key in ResourceKey[... / minecraft:item]: tfcfarmingplus:food/tea"（已实测）。
$bushProduct = @{ tea = 'tea_leaf'; coffee = 'coffee_bean' }
foreach ($n in $bushes.Keys) {
    $ref = $bushes[$n]
    $prodName = if ($bushProduct.ContainsKey($n)) { $bushProduct[$n] } else { $n }
    Save-Json "data/firmalife/firmalife/plantable/$n.json" ([ordered]@{
        crop = [ordered]@{ count = 1; id = "$NS`:food/$prodName" }
        extra_seed_chance = 0.08
        ingredient = [ordered]@{ item = "$NS`:plant/${n}_bush" }
        nutrient = [ordered]@{ nitrogen = 0.25; phosphorous = 0.25; potassium = 0.25 }
        planter = 'trellis'
        seed = [ordered]@{ count = 1; id = "$NS`:plant/${n}_bush" }
        specials = @()
        # 4 张 = 休眠 / 健康 / 开花 / 结果，顺序照 Firmalife（healthy, dry, flowering, fruiting）
        textures = @(
            "tfc:block/berry_bush/${ref}_bush"
            "tfc:block/berry_bush/dry_${ref}_bush"
            "tfc:block/berry_bush/flowering_${ref}_bush"
            "tfc:block/berry_bush/fruiting_${ref}_bush"
        )
        tier = 15
    })
}
Write-Host "[1] 灌木 planter 数据: $($bushes.Count) 个（trellis / tier 15）"

# ---------- ② 叶菜作物：种在四格种植盆（QUAD） ----------
foreach ($n in $crops.Keys) {
    $ref = $crops[$n]
    $tex = @()
    for ($age = 0; $age -le 5; $age++) { $tex += "tfc:block/crop/${ref}_$age" }
    $npk = $cropNpk[$n]
    Save-Json "data/firmalife/firmalife/plantable/$n.json" ([ordered]@{
        crop = [ordered]@{ count = 1; id = "$NS`:food/$n" }
        ingredient = [ordered]@{ item = "$NS`:seeds/$n" }
        nutrient = [ordered]@{ nitrogen = [double]$npk[0]; phosphorous = [double]$npk[1]; potassium = [double]$npk[2] }
        planter = 'quad'
        seed = [ordered]@{ count = 1; id = "$NS`:seeds/$n" }
        specials = @()
        stages = 5
        textures = $tex
    })
}
Write-Host "[2] 作物 planter 数据: $($crops.Count) 个（quad / stages 5）"

# ---------- ②b 果树：种在盆景种植盆（BONSAI） ----------
# 照 Firmalife 自己的果树数据（cherry.json / red_apple.json / cocoa.json）：
#   planter=bonsai, tier=15, extra_seed_chance=0.08, 5 张贴图。
# 贴图顺序是 Firmalife 的约定：fruiting_leaves, dry_leaves, flowering_leaves, branch, leaves。
# ⚠️ 路径是 tfc:block/fruit_tree/*，**不是** tfc:block/plant/* ——
#    后者是方块模型（parent 链），真正的贴图在 fruit_tree 下（实测 cherry_leaves.png 就在这里）。
$treeManifest = Join-Path $env:TFC_TOOLS_ROOT 'contracts/fruit-trees-manifest.json'
if (-not (Test-Path $treeManifest)) { throw "缺少 $treeManifest —— 请先运行 gen-fruit-trees.ps1" }
$trees = @(([System.IO.File]::ReadAllText($treeManifest, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).trees)
foreach ($t in $trees) {
    $n = $t.name; $ref = $t.donor
    if ($n -eq $cocoaPolicy.legacy_tree) { continue }
    $product = if ($n -eq $cocoaPolicy.tree) { $cocoaPolicy.product } else { "$NS`:food/$n" }
    # ⚠️ 文件名必须带 `fpt_` 前缀：Firmalife 自带的 plantable 里已经有 `fig.json`
    #    （firmalife:plant/fig_sapling）和 `elderberry.json`（tfc:plant/elderberry_bush），
    #    同名会**直接覆盖掉它们** —— 结果是 TFC 的接骨木灌木与 Firmalife 的无花果树
    #    从种植盆里消失（本工程实测踩过，脚本末尾的重名检查就是为此加的）。
    #    id 只是标识：Firmalife 用 IndirectHashCollection 按 `ingredient` 索引，前缀不影响功能。
    Save-Json "data/firmalife/firmalife/plantable/fpt_$n.json" ([ordered]@{
        crop = [ordered]@{ count = 1; id = $product }
        extra_seed_chance = 0.08
        ingredient = [ordered]@{ item = "$NS`:plant/${n}_sapling" }
        nutrient = [ordered]@{ nitrogen = 0.3; phosphorous = 0.3; potassium = 0.3 }
        planter = 'bonsai'
        seed = [ordered]@{ count = 1; id = "$NS`:plant/${n}_sapling" }
        specials = @()
        textures = @(
            "tfc:block/fruit_tree/${ref}_fruiting_leaves"
            "tfc:block/fruit_tree/${ref}_dry_leaves"
            "tfc:block/fruit_tree/${ref}_flowering_leaves"
            "tfc:block/fruit_tree/${ref}_branch"
            "tfc:block/fruit_tree/${ref}_leaves"
        )
        tier = 15
    })
}
Write-Host "[2b] 果树 planter 数据: $($trees.Count) 个（bonsai / tier 15）"

# ---------- ③ 校验：与 Firmalife 现有文件不重名 ----------
$instance = Split-Path (Split-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) -Parent) -Parent
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fmJar = @(Get-ChildItem -LiteralPath (Join-Path $instance 'mods') -File -Filter 'Firmalife-*.jar')
if ($fmJar.Count -ne 1) { throw 'Expected exactly one installed Firmalife JAR.' }
$fmZip = [IO.Compression.ZipFile]::OpenRead($fmJar[0].FullName)
$clash = @()
try {
    foreach ($f in (Get-ChildItem (Join-Path $root 'data/firmalife/firmalife/plantable') -File)) {
        if ($fmZip.GetEntry('data/firmalife/firmalife/plantable/' + $f.Name)) { $clash += $f.Name }
    }
} finally { $fmZip.Dispose() }
if ($clash.Count -gt 0) {
    Write-Host "!! 与 Firmalife 现有 plantable 文件重名（会覆盖）："
    $clash | ForEach-Object { Write-Host "    $_" }
    exit 1
}
Write-Host "[3] 重名检查通过：$count 个文件全部不与 Firmalife 冲突"
