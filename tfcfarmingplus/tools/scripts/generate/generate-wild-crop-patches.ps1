# ============================================================
# tfcfarmingplus 资源生成脚本（批次 2.5：野生作物 + 世界生成）
# ------------------------------------------------------------
# 目的：让 8 种新作物的种子有原版式来源。
# TFC 的种子没有任何合成配方，唯一来源就是打掉野生作物，
# 因此这一步是「作物可玩」的必要条件，而不是可选装饰。
#
# 注入链（与 TFC 完全同构，均为数据驱动，不改 TFC 代码）：
#   placed_feature  tfcfarmingplus:plant/wild_crop/<name>_patch
#     └─ 追加进 data/tfc/tags/worldgen/placed_feature/feature/crops.json
#          └─ 被 #tfc:feature/land_plants 引用
#               └─ 被 #tfc:in_biome/surface_decoration/<地形> 引用（TFC 的每个生物群系）
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

$root = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\mod_rebuild\tfcfarmingplus\src\main\resources"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:count = 0

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($obj), $utf8)
    $script:count++
}

# name / blockRef（借用的 TFC 贴图）/ 气候（与 data/tfcfarmingplus/tfc/climate_range/crop/<name>.json 一致）
$crops = @(
    [ordered]@{ n='spinach';        blockRef='beet';    minHyd=10; maxHyd=70; minTemp=-12.0; maxTemp=25.0; zh='野生菠菜';     en='Wild Spinach' }
    [ordered]@{ n='lettuce';        blockRef='onion';   minHyd=15; maxHyd=75; minTemp=-6.0;  maxTemp=24.0; zh='野生生菜';     en='Wild Lettuce' }
    [ordered]@{ n='celery';         blockRef='onion';   minHyd=20; maxHyd=85; minTemp=-5.0;  maxTemp=24.0; zh='野生芹菜';     en='Wild Celery' }
    [ordered]@{ n='kale';           blockRef='cabbage'; minHyd=10; maxHyd=70; minTemp=-20.0; maxTemp=18.0; zh='野生羽衣甘蓝'; en='Wild Kale' }
    [ordered]@{ n='napa_cabbage';   blockRef='cabbage'; minHyd=10; maxHyd=70; minTemp=-8.0;  maxTemp=24.0; zh='野生大白菜';   en='Wild Napa Cabbage' }
    [ordered]@{ n='mustard_greens'; blockRef='beet';    minHyd=15; maxHyd=75; minTemp=-5.0;  maxTemp=25.0; zh='野生芥菜';     en='Wild Mustard Greens' }
    [ordered]@{ n='broccoli';       blockRef='cabbage'; minHyd=15; maxHyd=80; minTemp=-5.0;  maxTemp=22.0; zh='野生西兰花';   en='Wild Broccoli' }
    [ordered]@{ n='cauliflower';    blockRef='cabbage'; minHyd=15; maxHyd=80; minTemp=-4.0;  maxTemp=23.0; zh='野生花椰菜';   en='Wild Cauliflower' }
)

$patchRefs = @()

foreach ($c in $crops) {
    $n = $c['n']
    $wildId = "tfcfarmingplus:wild_crop/$n"

    # --- 方块状态：成熟时用野生模型，未成熟复用 TFC 的死株模型 ---
    Save-Json "assets/tfcfarmingplus/blockstates/wild_crop/${n}.json" ([ordered]@{
        variants = [ordered]@{
            'mature=true'  = [ordered]@{ model = "tfcfarmingplus:block/wild_crop/$n" }
            'mature=false' = [ordered]@{ model = "tfc:block/dead_crop/$($c['blockRef'])" }
        }
    })

    # --- 方块模型（父模型用 TFC 的野生作物十字模型，贴图暂借 TFC 占位）---
    Save-Json "assets/tfcfarmingplus/models/block/wild_crop/${n}.json" ([ordered]@{
        parent   = 'tfc:block/wild_crop/crop'
        textures = [ordered]@{ crop = "tfc:block/crop/$($c['blockRef'])_wild" }
    })

    # --- 物品模型（野生作物有方块物品，与 TFC 的 tfc:wild_crops 物品标签对应）---
    Save-Json "assets/tfcfarmingplus/models/item/wild_crop/${n}.json" ([ordered]@{
        parent = "tfcfarmingplus:block/wild_crop/$n"
    })

    # --- 掉落表（结构照 TFC 的 loot_table/blocks/wild_crop/<name>.json）---
    Save-Json "data/tfcfarmingplus/loot_table/blocks/wild_crop/${n}.json" ([ordered]@{
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
                                block      = $wildId
                                properties = [ordered]@{ mature = 'true' }
                            }
                        )
                        functions  = @(
                            [ordered]@{
                                function = 'minecraft:set_count'
                                count    = [ordered]@{ min = 1; max = 3; type = 'minecraft:uniform' }
                            }
                        )
                    }
                )
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            },
            [ordered]@{
                name       = 'loot_pool'
                rolls      = 1
                entries    = @([ordered]@{ type = 'minecraft:item'; name = "tfcfarmingplus:seeds/$n" })
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            }
        )
    })

    # --- 世界生成 ①：单株 configured_feature ---
    Save-Json "data/tfcfarmingplus/worldgen/configured_feature/plant/wild_crop/${n}.json" ([ordered]@{
        type   = 'minecraft:simple_block'
        config = [ordered]@{
            to_place = [ordered]@{
                type  = 'minecraft:simple_state_provider'
                state = [ordered]@{ Name = $wildId }
            }
        }
    })

    # --- 世界生成 ②：成片 configured_feature（照 TFC：6 次尝试 / 水平 5 格 / 垂直 1 格）---
    Save-Json "data/tfcfarmingplus/worldgen/configured_feature/plant/wild_crop/${n}_patch.json" ([ordered]@{
        type   = 'minecraft:random_patch'
        config = [ordered]@{
            tries     = 6
            xz_spread = 5
            y_spread  = 1
            feature   = "tfcfarmingplus:plant/wild_crop/$n"
        }
    })

    # --- 世界生成 ③：placed_feature（tfc:climate 按温度与地下水筛选，与作物气候区间同源）---
    Save-Json "data/tfcfarmingplus/worldgen/placed_feature/plant/wild_crop/${n}_patch.json" ([ordered]@{
        feature   = "tfcfarmingplus:plant/wild_crop/${n}_patch"
        placement = @(
            [ordered]@{ type = 'minecraft:rarity_filter'; chance = 90 },
            [ordered]@{ type = 'minecraft:in_square' },
            [ordered]@{
                type            = 'tfc:climate'
                min_temperature = [double]$c['minTemp']
                max_temperature = [double]$c['maxTemp']
                min_groundwater = [int]($c['minHyd'] * 4)
                max_groundwater = [int]($c['maxHyd'] * 4)
            }
        )
    })

    $patchRefs += "tfcfarmingplus:plant/wild_crop/${n}_patch"
}

Write-Host "[1] 野生作物资源: $($crops.Count) 种（方块状态/模型/掉落表/世界生成 ×3）"

# ------------------------------------------------------------
# 2. 追加进 TFC 的作物特征标签（合并式写入，replace:false —— 不会覆盖 TFC 内容）
#    这是本模组唯一需要写入 tfc 命名空间的文件；
#    普通标签（非 replace）在数据包加载时是「合并」语义，因此绝对安全。
# ------------------------------------------------------------
Save-Json 'data/tfc/tags/worldgen/placed_feature/feature/crops.json' ([ordered]@{
    replace = $false
    values  = $patchRefs
})
Write-Host "[2] 标签注入: data/tfc/tags/worldgen/placed_feature/feature/crops.json（追加 $($patchRefs.Count) 项）"

# ------------------------------------------------------------
# 3. 语言文件：读取现有条目并追加野生作物
# ------------------------------------------------------------
foreach ($lang in @('zh_cn','en_us')) {
    $rel  = "assets/tfcfarmingplus/lang/${lang}.json"
    $path = Join-Path $root $rel
    $dict = $ser.DeserializeObject([System.IO.File]::ReadAllText($path, $utf8))
    $out  = [ordered]@{}
    foreach ($k in $dict.Keys) { $out[$k] = $dict[$k] }
    foreach ($c in $crops) {
        $key = if ($lang -eq 'zh_cn') { $c['zh'] } else { $c['en'] }
        $out["block.tfcfarmingplus.wild_crop.$($c['n'])"] = $key
    }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($out), $utf8)
    $script:count++
    Write-Host "    语言 $lang : $($out.Keys.Count) 条"
}

# ------------------------------------------------------------
# 4. JSON 合法性全量校验
# ------------------------------------------------------------
$bad = @()
$all = Get-ChildItem -Recurse -File -Path $root -Filter *.json
foreach ($f in $all) {
    try { $null = $ser.DeserializeObject([System.IO.File]::ReadAllText($f.FullName, $utf8)) }
    catch { $bad += ($f.FullName.Substring($root.Length + 1) + '  -> ' + $_.Exception.Message) }
}
Write-Host "[3] JSON 校验: 共 $($all.Count) 个文件, 非法 $($bad.Count) 个"
if ($bad.Count -gt 0) { $bad | ForEach-Object { Write-Host "  非法: $_" }; exit 1 }
Write-Host "本次写入文件数: $script:count"
