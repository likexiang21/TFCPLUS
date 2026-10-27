# ============================================================
# tfcfarmingplus 资源生成脚本（批次 2：8 种叶菜 + 死株 + 批次 1 修复）
# ------------------------------------------------------------
# 环境说明：本机 PowerShell 为 5.1，内置 ConvertTo-Json 对「单元素数组」
# 存在已知的展开缺陷（会输出成标量），因此统一改用 .NET 的
# JavaScriptSerializer 进行序列化与合法性校验，保证数组语义与键顺序正确。
#
# 设计原则（对齐 TFC 原版）：
#   1. 食物营养字段与保质期数值取自同类 TFC 原版作物（cabbage / beet / onion）
#   2. 气候区间取自 TFC 原版相近作物的真实数值
#   3. 贴图暂借用 TFC 原版作物贴图（跨命名空间引用）；将来替换自有贴图时
#      只需改 models/block/crop/<name>_age_<i>.json 的 crop 贴图路径，blockstate 不动
# ============================================================
param([string]$Root='', [switch]$SharedDeadModelsOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

. (Join-Path $PSScriptRoot 'shared-dead-model-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $Root
if($SharedDeadModelsOnly){Copy-ReviewedSharedDead -OutputRoot $root;exit 0}
Write-Warning 'Historical batch-2 output is draft only; never publish the whole tree.'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:count = 0

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($obj), $utf8)
    $script:count++
}

# ------------------------------------------------------------
# 0. 修复批次 1 的非法 item model（原为 {{...}} 双花括号）
#    ⚠️ 这里只处理**矮丛形态**的 4 种（最高 1 格 → 借 cloudberry 的盛果期模型）。
#       蔓生形态的 6 种由 gen-high-bushes.ps1 生成（借各自 donor 的高丛模型），
#       列在这里会被覆盖成矮丛外观。
# ------------------------------------------------------------
$bushes = @('bearberry','bilberry','crowberry','lingonberry')
foreach ($b in $bushes) {
    Save-Json "assets/tfcfarmingplus/models/item/plant/${b}_bush.json" ([ordered]@{ parent = 'tfc:block/plant/cloudberry_bush_2' })
}
Write-Host "[0] 修复灌木 item model（矮丛 4 种）: $($bushes.Count) 个"

# ------------------------------------------------------------
# 1. 死株资源（共享死株方块 dead_crop / dead_rosette）
#    die() 时直接掉落种子，故死株本身掉落为空
# ------------------------------------------------------------
foreach ($d in @('dead_crop')) {
    Save-Json "assets/tfcfarmingplus/blockstates/${d}.json" ([ordered]@{
        variants = [ordered]@{
            'mature=true'  = [ordered]@{ model = "tfcfarmingplus:block/${d}" }
            'mature=false' = [ordered]@{ model = "tfcfarmingplus:block/${d}_young" }
        }
    })
    Save-Json "assets/tfcfarmingplus/models/block/${d}.json"       ([ordered]@{ parent = 'block/crop'; textures = [ordered]@{ crop = 'tfc:block/crop/cabbage_dead' } })
    Save-Json "assets/tfcfarmingplus/models/block/${d}_young.json" ([ordered]@{ parent = 'block/crop'; textures = [ordered]@{ crop = 'tfc:block/crop/cabbage_dead_young' } })
    Save-Json "data/tfcfarmingplus/loot_table/blocks/${d}.json"    ([ordered]@{ type = 'minecraft:block'; pools = @() })
}
Write-Host "[1] 旧普通死株草稿；共享莲座资源在末尾从已复核来源复制"

# ------------------------------------------------------------
# 2. 批次 2：8 种叶菜
#    blockRef = 借用哪套 TFC 作物方块贴图（占位）
#    seedRef  = 借用哪张 TFC 种子贴图（占位）
#    foodRef  = 借用哪张 TFC 食物贴图（占位）
# ------------------------------------------------------------
$crops = @(
    [ordered]@{ n='spinach';        maxAge=5; blockRef='beet';    seedRef='beet';    foodRef='cabbage'; decay=1.2; sat=1.0; veg=2.0;  water=$null; maxHyd=70; maxTemp=25.0; minHyd=10; minTemp=-12.0; zh='菠菜';     en='Spinach' }
    [ordered]@{ n='lettuce';        maxAge=5; blockRef='onion';   seedRef='onion';   foodRef='cabbage'; decay=1.5; sat=1.0; veg=1.5;  water=5.0;   maxHyd=75; maxTemp=24.0; minHyd=15; minTemp=-6.0;  zh='生菜';     en='Lettuce' }
    [ordered]@{ n='celery';         maxAge=5; blockRef='onion';   seedRef='onion';   foodRef='cabbage'; decay=1.0; sat=1.0; veg=1.5;  water=5.0;   maxHyd=85; maxTemp=24.0; minHyd=20; minTemp=-5.0;  zh='芹菜';     en='Celery' }
    [ordered]@{ n='kale';           maxAge=5; blockRef='cabbage'; seedRef='cabbage'; foodRef='cabbage'; decay=1.2; sat=1.0; veg=2.0;  water=$null; maxHyd=70; maxTemp=18.0; minHyd=10; minTemp=-20.0; zh='羽衣甘蓝'; en='Kale' }
    [ordered]@{ n='napa_cabbage';   maxAge=5; blockRef='cabbage'; seedRef='cabbage'; foodRef='cabbage'; decay=1.2; sat=1.0; veg=2.0;  water=$null; maxHyd=70; maxTemp=24.0; minHyd=10; minTemp=-8.0;  zh='大白菜';   en='Napa Cabbage' }
    [ordered]@{ n='mustard_greens'; maxAge=5; blockRef='beet';    seedRef='beet';    foodRef='cabbage'; decay=1.5; sat=0.5; veg=1.5;  water=$null; maxHyd=75; maxTemp=25.0; minHyd=15; minTemp=-5.0;  zh='芥菜';     en='Mustard Greens' }
    [ordered]@{ n='broccoli';       maxAge=5; blockRef='cabbage'; seedRef='cabbage'; foodRef='cabbage'; decay=1.5; sat=1.0; veg=1.75; water=$null; maxHyd=80; maxTemp=22.0; minHyd=15; minTemp=-5.0;  zh='西兰花';   en='Broccoli' }
    [ordered]@{ n='cauliflower';    maxAge=5; blockRef='cabbage'; seedRef='cabbage'; foodRef='cabbage'; decay=1.5; sat=1.0; veg=1.75; water=$null; maxHyd=80; maxTemp=23.0; minHyd=15; minTemp=-4.0;  zh='花椰菜';   en='Cauliflower' }
)

foreach ($c in $crops) {
    $n = $c['n']
    $blockId = "tfcfarmingplus:crop/$n"

    # --- 气候区间 ---
    Save-Json "data/tfcfarmingplus/tfc/climate_range/crop/${n}.json" ([ordered]@{
        max_hydration   = [int]$c['maxHyd']
        max_temperature = [double]$c['maxTemp']
        min_hydration   = [int]$c['minHyd']
        min_temperature = [double]$c['minTemp']
    })

    # --- 食物数据（保质期 + 营养）---
    $food = [ordered]@{ decay_modifier = [double]$c['decay']; hunger = 4 }
    $food['ingredient'] = [ordered]@{ item = "tfcfarmingplus:food/$n" }
    $food['saturation'] = [double]$c['sat']
    $food['vegetables'] = [double]$c['veg']
    if ($null -ne $c['water']) { $food['water'] = [double]$c['water'] }
    Save-Json "data/tfcfarmingplus/tfc/food/${n}.json" $food

    # --- 方块状态（age 0..maxAge）---
    $variants = [ordered]@{}
    for ($i = 0; $i -le [int]$c['maxAge']; $i++) {
        $variants["age=$i"] = [ordered]@{ model = "tfcfarmingplus:block/crop/${n}_age_$i" }
    }
    Save-Json "assets/tfcfarmingplus/blockstates/crop/${n}.json" ([ordered]@{ variants = $variants })

    # --- 方块模型（借 TFC 贴图占位）---
    for ($i = 0; $i -le [int]$c['maxAge']; $i++) {
        Save-Json "assets/tfcfarmingplus/models/block/crop/${n}_age_$i.json" ([ordered]@{
            parent   = 'block/crop'
            textures = [ordered]@{ crop = "tfc:block/crop/$($c['blockRef'])_$i" }
        })
    }

    # --- 作物掉落表（结构照 TFC 的 loot_table/blocks/crop/<name>.json）---
    Save-Json "data/tfcfarmingplus/loot_table/blocks/crop/${n}.json" ([ordered]@{
        type  = 'minecraft:block'
        pools = @(
            [ordered]@{
                name       = 'loot_pool'
                rolls      = 1
                entries    = @(
                    [ordered]@{
                        type       = 'minecraft:item'
                        name       = "tfcfarmingplus:food/$n"
                        conditions = @(
                            [ordered]@{
                                condition  = 'minecraft:block_state_property'
                                block      = $blockId
                                properties = [ordered]@{ age = "$([int]$c['maxAge'])" }
                            }
                        )
                        functions  = @(
                            [ordered]@{
                                function = 'minecraft:set_count'
                                count    = [ordered]@{
                                    type = 'tfc:crop_yield_uniform'
                                    min  = 0
                                    max  = [ordered]@{ type = 'minecraft:uniform'; min = 6; max = 10 }
                                }
                            }
                        )
                    }
                )
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            },
            [ordered]@{
                name       = 'loot_pool'
                rolls      = 1
                entries    = @(
                    [ordered]@{ type = 'minecraft:item'; name = "tfcfarmingplus:seeds/$n" }
                )
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            }
        )
    })

    # --- 物品模型（种子 / 食物）---
    Save-Json "assets/tfcfarmingplus/models/item/seeds/${n}.json" ([ordered]@{
        parent   = 'item/generated'
        textures = [ordered]@{ layer0 = "tfc:item/seeds/$($c['seedRef'])" }
    })
    Save-Json "assets/tfcfarmingplus/models/item/food/${n}.json" ([ordered]@{
        parent   = 'item/generated'
        textures = [ordered]@{ layer0 = "tfc:item/food/$($c['foodRef'])" }
    })
}
Write-Host "[2] 批次 2 叶菜资源: $($crops.Count) 种作物"

# ------------------------------------------------------------
# 3. 标签接入（自动进入堆肥 / 沙拉 / 三明治 / 汤 / 饲料）
#    TFC 的 usable_in_salad / usable_in_soup / usable_in_sandwich /
#    compost_greens/high / goat_food / chicken_food / rabbit_food
#    均引用 #c:foods/vegetable，因此只需加入该 common 标签。
#    注意：普通标签为「合并式」写入，不会覆盖 TFC 已有内容。
# ------------------------------------------------------------
$vegItems = @(); foreach ($c in $crops) { $vegItems += "tfcfarmingplus:food/$($c['n'])" }
Save-Json 'data/c/tags/item/foods/vegetable.json' ([ordered]@{ values = $vegItems })

$seedItems = @(); foreach ($c in $crops) { $seedItems += "tfcfarmingplus:seeds/$($c['n'])" }
Save-Json 'data/c/tags/item/seeds.json' ([ordered]@{ values = $seedItems })
Write-Host "[3] 标签文件: 2 个（合并式）"

# ------------------------------------------------------------
# 4. 语言文件（全量重写：批次 1 + 批次 2）
# ------------------------------------------------------------
$zh = [ordered]@{
    'block.tfcfarmingplus.dead_crop'    = '枯死作物'
    'block.tfcfarmingplus.dead_rosette' = '枯死植株'
}
$en = [ordered]@{
    'block.tfcfarmingplus.dead_crop'    = 'Dead Crop'
    'block.tfcfarmingplus.dead_rosette' = 'Dead Plant'
}

$berryZh = [ordered]@{
    lingonberry='越橘'; bilberry='山蓝莓'; crowberry='岩高兰'; bearberry='熊果'; goji='枸杞'
    haskap='蓝靛果'; aronia='野樱莓'; serviceberry='唐棣'; blackcurrant='黑加仑'; redcurrant='红加仑'
}
$berryEn = [ordered]@{
    lingonberry='Lingonberry'; bilberry='Bilberry'; crowberry='Crowberry'; bearberry='Bearberry'; goji='Goji Berry'
    haskap='Haskap'; aronia='Aronia'; serviceberry='Serviceberry'; blackcurrant='Blackcurrant'; redcurrant='Redcurrant'
}
foreach ($k in $berryZh.Keys) {
    # 照 TFC 的命名格式「XX灌木」（黑莓灌木 / 树莓灌木 / 云莓灌木 …），不用「XX丛」
    $zh["block.tfcfarmingplus.plant.${k}_bush"] = "$($berryZh[$k])灌木"
    $zh["item.tfcfarmingplus.food.$k"]          = $berryZh[$k]
    $en["block.tfcfarmingplus.plant.${k}_bush"] = "$($berryEn[$k]) Bush"
    $en["item.tfcfarmingplus.food.$k"]          = $berryEn[$k]
}

# 茶树 / 咖啡树：**灌木名与产物名不同**（茶树 → 茶叶，咖啡树 → 咖啡豆），
# 而且它们是树不是「XX灌木」，所以不能塞进上面的 $berryZh 循环（会生成 food/tea 这种错键）。
$zh["block.tfcfarmingplus.plant.tea_bush"]    = '茶树'
$zh["block.tfcfarmingplus.plant.coffee_bush"] = '咖啡树'
$zh["item.tfcfarmingplus.food.tea_leaf"]      = '茶叶'
$zh["item.tfcfarmingplus.food.coffee_bean"]   = '咖啡豆'

# 创造模式物品栏的标题。⚠️ 少了这个键，物品栏在游戏里会直接显示原始键名 `itemGroup.tfcfarmingplus.main`。
$zh["itemGroup.tfcfarmingplus.main"] = 'TFC农业+'
$en["itemGroup.tfcfarmingplus.main"] = 'TFC Farming Plus'
$en["block.tfcfarmingplus.plant.tea_bush"]    = 'Tea Bush'
$en["block.tfcfarmingplus.plant.coffee_bush"] = 'Coffee Bush'
$en["item.tfcfarmingplus.food.tea_leaf"]      = 'Tea Leaf'
$en["item.tfcfarmingplus.food.coffee_bean"]   = 'Coffee Bean'

foreach ($c in $crops) {
    $n = $c['n']
    $zh["item.tfcfarmingplus.food.$n"]  = $c['zh']
    $zh["item.tfcfarmingplus.seeds.$n"] = "$($c['zh'])种子"
    $zh["block.tfcfarmingplus.crop.$n"] = "$($c['zh'])作物"
    $en["item.tfcfarmingplus.food.$n"]  = $c['en']
    $en["item.tfcfarmingplus.seeds.$n"] = "$($c['en']) Seeds"
    $en["block.tfcfarmingplus.crop.$n"] = "$($c['en']) Crop"
}

Save-Json 'assets/tfcfarmingplus/lang/zh_cn.json' $zh
Save-Json 'assets/tfcfarmingplus/lang/en_us.json' $en
Write-Host "[4] 语言文件: zh_cn=$($zh.Keys.Count) 条, en_us=$($en.Keys.Count) 条"

# ------------------------------------------------------------
# 5. JSON 合法性全量校验（严格解析，非法即报错退出）
# ------------------------------------------------------------
$bad = @()
$all = Get-ChildItem -Recurse -File -Path $root -Filter *.json
foreach ($f in $all) {
    $txt = [System.IO.File]::ReadAllText($f.FullName, $utf8)
    try { $null = $ser.DeserializeObject($txt) }
    catch { $bad += ($f.FullName.Substring($root.Length + 1) + '  -> ' + $_.Exception.Message) }
}
Write-Host "[5] JSON 校验: 共 $($all.Count) 个文件, 非法 $($bad.Count) 个"
if ($bad.Count -gt 0) {
    $bad | ForEach-Object { Write-Host "  非法: $_" }
    exit 1
}
Write-Host "本次写入文件数: $script:count"

# Do not restore the old cabbage parent or overwrite the shared seed policy.
Copy-ReviewedSharedDead -OutputRoot $root
