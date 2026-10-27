# ============================================================
# 生成：① 每种作物的独立枯萎方块  ② 枯死灌木  ③ 10 种灌木的自然生成
# ------------------------------------------------------------
# 全部照 TFC 原版结构：
#   作物枯萎  data/<ns>/loot_table/blocks/dead_crop/<name>.json   （掉回对应种子）
#             assets/<ns>/blockstates/dead_crop/<name>.json
#   枯死灌木  blockstates/plant/dead_berry_bush.json（stage 0~2）+ 掉落木棍
#   灌木生成  configured_feature/plant/<name>_bush[_patch].json
#             placed_feature/plant/<name>_bush[_patch].json
#             追加进 data/tfc/tags/worldgen/placed_feature/feature/berry_bushes.json
# ============================================================
param([string]$OutputRoot = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $env:TFC_TOOLS_ROOT 'cocoa-data-policy.ps1')
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

$root = Resolve-LegacyGeneratorOutput $OutputRoot
$ns   = 'tfcfarmingplus'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:count = 0

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($obj), $utf8)
    $script:count++
}

function Get-Json([string]$rel) {
    return $ser.DeserializeObject([System.IO.File]::ReadAllText((Join-Path $root $rel), $utf8))
}

$crops = @(
    [ordered]@{ n='spinach';        ref='beet';    zh='菠菜';     en='Spinach' }
    [ordered]@{ n='lettuce';        ref='onion';   zh='生菜';     en='Lettuce' }
    [ordered]@{ n='celery';         ref='onion';   zh='芹菜';     en='Celery' }
    [ordered]@{ n='kale';           ref='cabbage'; zh='羽衣甘蓝'; en='Kale' }
    [ordered]@{ n='napa_cabbage';   ref='cabbage'; zh='大白菜';   en='Napa Cabbage' }
    [ordered]@{ n='mustard_greens'; ref='beet';    zh='芥菜';     en='Mustard Greens' }
    [ordered]@{ n='broccoli';       ref='cabbage'; zh='西兰花';   en='Broccoli' }
    [ordered]@{ n='cauliflower';    ref='cabbage'; zh='花椰菜';   en='Cauliflower' }
)

# ---------------- ① 作物枯萎方块 ----------------
foreach ($c in $crops) {
    $n = $c['n']; $ref = $c['ref']
    $deadId = "${ns}:dead_crop/$n"

    # 方块状态：mature=true/false（照 TFC 的 dead_crop/<name>）
    Save-Json "assets/$ns/blockstates/dead_crop/${n}.json" ([ordered]@{
        variants = [ordered]@{
            'mature=true'  = [ordered]@{ model = "${ns}:block/dead_crop/$n" }
            'mature=false' = [ordered]@{ model = "${ns}:block/dead_crop/${n}_young" }
        }
    })
    # 模型：借用 TFC 的枯死作物贴图（十字模型父级 block/crop）
    Save-Json "assets/$ns/models/block/dead_crop/${n}.json" ([ordered]@{
        parent = 'block/crop'; textures = [ordered]@{ crop = "tfc:block/crop/${ref}_dead" }
    })
    Save-Json "assets/$ns/models/block/dead_crop/${n}_young.json" ([ordered]@{
        parent = 'block/crop'; textures = [ordered]@{ crop = "tfc:block/crop/${ref}_dead_young" }
    })
    # 掉落表：照 TFC —— mature 掉 1~3 个种子，未成熟掉 1 个
    Save-Json "data/$ns/loot_table/blocks/dead_crop/${n}.json" ([ordered]@{
        type  = 'minecraft:block'
        pools = @(
            [ordered]@{
                name       = 'loot_pool'
                rolls      = 1
                entries    = @(
                    [ordered]@{
                        type     = 'minecraft:alternatives'
                        children = @(
                            [ordered]@{
                                type       = 'minecraft:item'
                                name       = "${ns}:seeds/$n"
                                conditions = @([ordered]@{
                                    condition  = 'minecraft:block_state_property'
                                    block      = $deadId
                                    properties = [ordered]@{ mature = 'true' }
                                })
                                functions  = @([ordered]@{
                                    function = 'minecraft:set_count'
                                    count    = [ordered]@{ min = 1; max = 3; type = 'minecraft:uniform' }
                                })
                            },
                            [ordered]@{
                                type       = 'minecraft:item'
                                name       = "${ns}:seeds/$n"
                                conditions = @([ordered]@{
                                    condition  = 'minecraft:block_state_property'
                                    block      = $deadId
                                    properties = [ordered]@{ mature = 'false' }
                                })
                            }
                        )
                    }
                )
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            }
        )
    })
}
Write-Host "[1] 作物枯萎方块: $($crops.Count) 种 × (blockstate + 2 模型 + 掉落表)"

# ---------------- ② 枯死灌木 ----------------
$stageVariants = [ordered]@{}
for ($i = 0; $i -le 2; $i++) { $stageVariants["stage=$i"] = [ordered]@{ model = "${ns}:block/plant/dead_berry_bush_$i" } }
Save-Json "assets/$ns/blockstates/plant/dead_berry_bush.json" ([ordered]@{ variants = $stageVariants })
for ($i = 0; $i -le 2; $i++) {
    Save-Json "assets/$ns/models/block/plant/dead_berry_bush_$i.json" ([ordered]@{ parent = "tfc:block/plant/dead_berry_bush_$i" })
}
Save-Json "data/$ns/loot_table/blocks/plant/dead_berry_bush.json" ([ordered]@{
    type  = 'minecraft:block'
    pools = @(
        [ordered]@{
            name       = 'loot_pool'
            rolls      = 1
            entries    = @([ordered]@{ type = 'minecraft:item'; name = 'minecraft:stick' })
            conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
        }
    )
})
Write-Host "[2] 枯死灌木: blockstate(3 stage) + 3 模型 + 掉落表(木棍)"

# ---------------- ③ 灌木自然生成 ----------------
# high = 蔓生形态（会长出 *_bush_cane 藤蔓），false = 矮丛形态（最高 1 格）
# 必须与 crop\FarmingBushes.java 的分组、以及 gen-high-bushes.ps1 / gen-tags.ps1 的清单一致
$bushes = @(
    [ordered]@{ n='lingonberry';  high=$false }
    [ordered]@{ n='bearberry';    high=$false }
    [ordered]@{ n='crowberry';    high=$false }
    [ordered]@{ n='bilberry';     high=$false }
    [ordered]@{ n='blackcurrant'; high=$true }
    [ordered]@{ n='redcurrant';   high=$true }
    [ordered]@{ n='haskap';       high=$true }
    [ordered]@{ n='goji';         high=$true }
    [ordered]@{ n='serviceberry'; high=$true }
    [ordered]@{ n='aronia';       high=$true }
    [ordered]@{ n='tea';          high=$true }
    [ordered]@{ n='coffee';       high=$true }
)

$patchRefs = @()
foreach ($b in $bushes) {
    $n = $b['n']
    $blockId = "${ns}:plant/${n}_bush"
    $climate = Get-Json "data/$ns/tfc/climate_range/plant/${n}_bush.json"

    # configured_feature：单株（两种形态用不同的 feature 类型）
    #   矮丛 → minecraft:simple_block：就地放一个方块，之后不再改变外形
    #   蔓生 → tfc:spreading_bush：TFC 的专用 feature，放下主丛后由它自行向四周/向上长藤
    #          （config 只有 block 一个字段，照 TFC 的 plant/blackberry_bush.json）
    if ($b['high']) {
        Save-Json "data/$ns/worldgen/configured_feature/plant/${n}_bush.json" ([ordered]@{
            type   = 'tfc:spreading_bush'
            config = [ordered]@{ block = $blockId }
        })
    } else {
        Save-Json "data/$ns/worldgen/configured_feature/plant/${n}_bush.json" ([ordered]@{
            type   = 'minecraft:simple_block'
            config = [ordered]@{
                to_place = [ordered]@{
                    type  = 'minecraft:simple_state_provider'
                    state = [ordered]@{
                        Name       = $blockId
                        Properties = [ordered]@{ lifecycle = 'healthy'; stage = '0' }
                    }
                }
            }
        })
    }
    # configured_feature：成片（tries=4，灌木比作物稀疏）
    Save-Json "data/$ns/worldgen/configured_feature/plant/${n}_bush_patch.json" ([ordered]@{
        type   = 'minecraft:random_patch'
        config = [ordered]@{ tries = 4; xz_spread = 4; y_spread = 1; feature = "${ns}:plant/${n}_bush" }
    })
    # placed_feature：单株
    Save-Json "data/$ns/worldgen/placed_feature/plant/${n}_bush.json" ([ordered]@{
        feature   = "${ns}:plant/${n}_bush"
        placement = @(
            [ordered]@{ type = 'minecraft:heightmap'; heightmap = 'WORLD_SURFACE_WG' },
            [ordered]@{ type = 'minecraft:block_predicate_filter'; predicate = [ordered]@{ type = 'tfc:replaceable' } },
            [ordered]@{ type = 'minecraft:block_predicate_filter'
                        predicate = [ordered]@{ type = 'would_survive'
                                                state = [ordered]@{ Name = $blockId
                                                                    Properties = [ordered]@{ lifecycle = 'healthy'; stage = '0' } } } }
        )
    })
    # placed_feature：成片（照 TFC 的顺序：climate → in_square → rarity_filter）
    Save-Json "data/$ns/worldgen/placed_feature/plant/${n}_bush_patch.json" ([ordered]@{
        feature   = "${ns}:plant/${n}_bush_patch"
        placement = @(
            [ordered]@{
                type            = 'tfc:climate'
                min_temperature = [double]$climate['min_temperature']
                max_temperature = [double]$climate['max_temperature']
                min_groundwater = [int]($climate['min_hydration'] * 4)
                max_groundwater = [int]($climate['max_hydration'] * 4)
                min_forest      = 2
                max_forest      = 4
            },
            [ordered]@{ type = 'minecraft:in_square' },
            [ordered]@{ type = 'minecraft:rarity_filter'; chance = 30 }
        )
    })
    $patchRefs += "${ns}:plant/${n}_bush_patch"
}
Save-Json 'data/tfc/tags/worldgen/placed_feature/feature/berry_bushes.json' ([ordered]@{
    replace = $false
    values  = $patchRefs
    remove = @('tfc:plant/strawberry_bush_patch')
})
Write-Host "[3] 灌木自然生成: $($bushes.Count) 种 × 4 个 JSON + 标签注入 berry_bushes"

# ---------------- ④ 清理旧的共享死株资源 ----------------
$stale = @(
    "assets/$ns/blockstates/dead_crop.json",
    "assets/$ns/models/block/dead_crop.json",
    "assets/$ns/models/block/dead_crop_young.json",
    "data/$ns/loot_table/blocks/dead_crop.json"
)
foreach ($s in $stale) {
    $p = Join-Path $root $s
    if (Test-Path $p) { Remove-Item $p -Force; Write-Host "    已清理旧文件: $s" }
}

# ---------------- ⑤ 语言文件 ----------------
foreach ($lang in @('en_us','zh_cn')) {
    $rel  = "assets/$ns/lang/${lang}.json"
    $dict = Get-Json $rel
    $out  = [ordered]@{}
    foreach ($k in $dict.Keys) {
        if ($k -eq "block.$ns.dead_crop") { continue }   # 共享死株已废弃
        $out[$k] = $dict[$k]
    }
    $out["block.$ns.plant.dead_berry_bush"] = $(if ($lang -eq 'zh_cn') { '枯死灌木' } else { 'Dead Berry Bush' })
    # 蔓生灌木的枯藤（无方块物品，但方块名仍需要 lang，否则调试界面显示原始键）
    $out["block.$ns.plant.dead_cane"] = $(if ($lang -eq 'zh_cn') { '枯死藤蔓' } else { 'Dead Cane' })
    foreach ($c in $crops) {
        $name = if ($lang -eq 'zh_cn') { "枯死的$($c['zh'])" } else { "Dead $($c['en'])" }
        $out["block.$ns.dead_crop.$($c['n'])"] = $name
    }
    [System.IO.File]::WriteAllText((Join-Path $root $rel), $ser.Serialize($out), $utf8)
    $script:count++
    Write-Host "    lang $lang : $($out.Keys.Count) 条"
}

Write-Host "本次写入 $script:count 个文件"
