# ============================================================
# tfcfarmingplus 资源生成脚本（蔓生形态灌木：8 种主丛 + 枝叶）
# ------------------------------------------------------------
# TFC 的浆果丛有**两种形态**，是两个不同的方块类、外观与采摘方式都不同：
#   矮丛  StationaryBerryBushBlock  最高 1 格        云莓 / 矮丛蓝莓 / 雪果
#   蔓生  SpreadingBushBlock        会长出 *_bush_cane 藤蔓   黑莓 / 树莓 / 蓝莓 / 接骨木莓
# 本脚本处理**蔓生**的 8 种（对应 FarmingBushes 的 highBush / highCane）：
#   blackcurrant / redcurrant / haskap / goji / serviceberry / aronia
#   tea / coffee（茶树、咖啡树：不是浆果，但同为多年生灌木，借用同一套蔓生机制）
# 另外 4 种（lingonberry / bearberry / crowberry / bilberry）是矮丛，
# 其 blockstate 是手写文件、物品模型由 generate-vegetable-crop-models.ps1 生成，本脚本不碰。
#
# 生成清单（每种）：
#   assets/<ns>/blockstates/plant/<n>_bush.json          12 变体（lifecycle × stage）
#   assets/<ns>/blockstates/plant/<n>_bush_cane.json     48 变体（lifecycle × facing × stage）
#   assets/<ns>/models/item/plant/<n>_bush.json          物品模型（藤蔓没有物品）
#   data/<ns>/loot_table/blocks/plant/<n>_bush.json      需锋利工具：stage 2 必掉、否则 50%，另掉木棍
#   data/<ns>/loot_table/blocks/plant/<n>_bush_cane.json 只掉木棍
# 共用：
#   assets/<ns>/blockstates/plant/dead_cane.json         12 变体（facing × stage）
#
# ⚠️ 世界生成（configured_feature / placed_feature）**不在本脚本**：
#    蔓生形态要用 tfc:spreading_bush 而不是 minecraft:simple_block，
#    由 gen-dead-and-wild-bushes.ps1 按 high 标记分派生成。
#
# 结构照 TFC 4.2.10（对照 tfc:blockstates/plant/blackberry_bush.json、
# blackberry_bush_cane.json、loot_table/blocks/plant/blackberry_bush*.json）：
#   blockstate 直接引用 TFC 的模型，模型内部再用 TFC 的 berry_bush 贴图 ——
#   这是本工程一贯的「占位借用」美术策略；将来换自有贴图时，
#   只需把 $high 表里的 donor 换成自有模型前缀（或改写模型 JSON），blockstate 结构不动。
#
# 环境说明：本机 PowerShell 为 5.1，ConvertTo-Json 对「单元素数组」有展开缺陷，
# 统一用 .NET 的 JavaScriptSerializer 序列化。
# 注意本文件必须保存为 **UTF-8 带 BOM**，否则 PS 5.1 会按 GBK 解码、中文注释里的
# 引号会被吃掉导致语法错误。
# ============================================================
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

$root = "D:\111\最强服务器\.minecraft\versions\Essential TerraFirmaCraft (TFC)\mod_rebuild\tfcfarmingplus\src\main\resources"
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

# ------------------------------------------------------------
# 6 种蔓生灌木：donor = 借用的 TFC 高灌木外观，maxHeight = 藤蔓能爬升的格数
# donor 与 maxHeight 必须和 crop\FarmingBushes.java 里的 highBush/highCane 调用保持一致：
#   blackberry=4  raspberry=3  blueberry=2  elderberry=3
# ------------------------------------------------------------
$high = @(
    [ordered]@{ n = 'blackcurrant'; donor = 'elderberry' }
    [ordered]@{ n = 'redcurrant';   donor = 'raspberry'  }
    [ordered]@{ n = 'haskap';       donor = 'blueberry'  }
    [ordered]@{ n = 'goji';         donor = 'blackberry' }
    [ordered]@{ n = 'serviceberry'; donor = 'elderberry' }
    [ordered]@{ n = 'aronia';       donor = 'blackberry' }
    [ordered]@{ n = 'tea';          donor = 'blueberry'  }
    [ordered]@{ n = 'coffee';       donor = 'elderberry' }
)

# lifecycle → 模型名前缀（TFC 的命名规律：健康无前缀，其余加前缀）
$lifecycles = @(
    [ordered]@{ key = 'healthy';   prefix = '' }
    [ordered]@{ key = 'dormant';   prefix = 'dry_' }
    [ordered]@{ key = 'fruiting';  prefix = 'fruiting_' }
    [ordered]@{ key = 'flowering'; prefix = 'flowering_' }
)

# facing → 模型 y 旋转（照 TFC：north 为 0 故省略 y 字段）
$facings = @(
    [ordered]@{ key = 'east';  y = 90 }
    [ordered]@{ key = 'north'; y = 0 }
    [ordered]@{ key = 'south'; y = 180 }
    [ordered]@{ key = 'west';  y = 270 }
)

foreach ($h in $high) {
    $n = $h['n']
    $d = $h['donor']

    # ---- ① 主丛 blockstate：lifecycle × stage = 12 变体 ----
    $variants = [ordered]@{}
    foreach ($l in $lifecycles) {
        for ($i = 0; $i -le 2; $i++) {
            $variants["lifecycle=$($l['key']),stage=$i"] =
                [ordered]@{ model = "tfc:block/plant/$($l['prefix'])$($d)_bush_$i" }
        }
    }
    Save-Json "assets/$ns/blockstates/plant/${n}_bush.json" ([ordered]@{ variants = $variants })

    # ---- ② 藤蔓 blockstate：lifecycle × facing × stage = 48 变体 ----
    $variants = [ordered]@{}
    foreach ($l in $lifecycles) {
        foreach ($f in $facings) {
            for ($i = 0; $i -le 2; $i++) {
                $model = [ordered]@{ model = "tfc:block/plant/$($l['prefix'])$($d)_bush_side_$i" }
                if ($f['y'] -ne 0) { $model['y'] = $f['y'] }
                $variants["lifecycle=$($l['key']),facing=$($f['key']),stage=$i"] = $model
            }
        }
    }
    Save-Json "assets/$ns/blockstates/plant/${n}_bush_cane.json" ([ordered]@{ variants = $variants })

    # ---- ③ 物品模型：照 TFC 的**蔓生**灌木，用平面物品图标（一根藤蔓），而不是方块模型 ----
    #    TFC 对两种形态用的是**不同的**物品模型（对照 tfc 的 raspberry_bush 与 cloudberry_bush）：
    #      矮丛  {"parent":"tfc:block/plant/<n>_bush_2"}                  ← 直接渲染立体方块模型
    #      蔓生  {"parent":"item/generated","layer0":"..._<n>_cane"}      ← 一根藤蔓的平面图标
    #    我们这 6 种都是蔓生，必须用后者；用前者会让物品栏里出现一坨立体的灌木方块。
    Save-Json "assets/$ns/models/item/plant/${n}_bush.json" ([ordered]@{
        parent   = 'item/generated'
        textures = [ordered]@{ layer0 = "tfc:block/berry_bush/${d}_cane" }
    })

    # ---- ④ 主丛掉落表（照 TFC blackberry_bush：锋利工具 + stage 2 必掉，否则 50%；另掉木棍）----
    $blockId = "${ns}:plant/${n}_bush"
    Save-Json "data/$ns/loot_table/blocks/plant/${n}_bush.json" ([ordered]@{
        type  = 'minecraft:block'
        pools = @(
            [ordered]@{
                name    = 'loot_pool'
                rolls   = 1
                entries = @([ordered]@{
                    type     = 'minecraft:alternatives'
                    children = @(
                        [ordered]@{
                            type       = 'minecraft:item'
                            name       = $blockId
                            conditions = @(
                                [ordered]@{ condition = 'minecraft:match_tool'; predicate = [ordered]@{ items = '#tfc:tools/sharp' } },
                                [ordered]@{ condition = 'minecraft:block_state_property'; block = $blockId; properties = [ordered]@{ stage = '2' } }
                            )
                        },
                        [ordered]@{
                            type       = 'minecraft:item'
                            name       = $blockId
                            conditions = @(
                                [ordered]@{ condition = 'minecraft:match_tool'; predicate = [ordered]@{ items = '#tfc:tools/sharp' } },
                                [ordered]@{ condition = 'minecraft:random_chance'; chance = 0.5 }
                            )
                        }
                    )
                })
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            },
            [ordered]@{
                name       = 'loot_pool'
                rolls      = 1
                entries    = @([ordered]@{ type = 'minecraft:item'; name = 'minecraft:stick' })
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            }
        )
    })

    # ---- ⑤ 藤蔓掉落表（照 TFC blackberry_bush_cane：只掉木棍，无可挖回的物品）----
    Save-Json "data/$ns/loot_table/blocks/plant/${n}_bush_cane.json" ([ordered]@{
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
}
Write-Host "[1] $($high.Count) 种蔓生灌木: 主丛 blockstate(12) + 枝叶 blockstate(48) + item model + 2 张掉落表 = $($script:count) 个文件"

# ------------------------------------------------------------
# ⑥ 枯死藤蔓 blockstate：facing × stage = 12 变体
#    对应 FarmingBlocks.DEAD_CANE（直接实例化 TFC 的 DeadCaneBlock），
#    模型借用 TFC 的 dead_berry_bush_side_*（侧向枯枝）。
# ------------------------------------------------------------
$variants = [ordered]@{}
foreach ($f in $facings) {
    for ($i = 0; $i -le 2; $i++) {
        $model = [ordered]@{ model = "tfc:block/plant/dead_berry_bush_side_$i" }
        if ($f['y'] -ne 0) { $model['y'] = $f['y'] }
        $variants["facing=$($f['key']),stage=$i"] = $model
    }
}
Save-Json "assets/$ns/blockstates/plant/dead_cane.json" ([ordered]@{ variants = $variants })
Write-Host "[2] 枯死藤蔓 blockstate: 12 变体"
Write-Host "完成，共写出 $($script:count) 个 JSON"
