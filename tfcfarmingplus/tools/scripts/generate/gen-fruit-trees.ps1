# ============================================================
# 果树资源生成器 —— 照 TFC 的果树「四件套」
# ------------------------------------------------------------
# TFC 的果树由四个方块组成（net.dries007.tfc.common.blocks.plant.fruit）：
#   树苗   FruitTreeSaplingBlock          saplings=1..4（长成后变成枝干）
#   枝干   FruitTreeBranchBlock           multipart：core + down/up + 四方向 side
#   生长枝干 GrowingFruitTreeBranchBlock  模型同枝干，另带 saplings/natural 属性
#   树叶   FruitTreeLeavesBlock           lifecycle=dormant/healthy/flowering/fruiting
# **产物挂在「结果期」的树叶上**，没有独立的果实方块。
#
# 贴图与模型全部借 TFC 的某一种原版果树（占位美术），结构照抄
# assets/tfc/blockstates/plant/cherry_*.json 与 models/block/plant/cherry_*。
# ============================================================
param([string]$OutputRoot = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $env:TFC_TOOLS_ROOT 'cocoa-data-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $OutputRoot
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
$utf8 = New-Object System.Text.UTF8Encoding($false)
$NS = 'tfcfarmingplus'
$script:count = 0

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($obj), $utf8)
    $script:count++
}

# donor = 借用哪套 TFC 果树模型/贴图（占位）；lifecycle = 12 个月的物候
# 温带果树 14 种。
#   donor 只有 8 套可用（TFC 现有的 8 种果树模型：cherry/green_apple/lemon/olive/
#   orange/peach/plum/red_apple），所以循环复用 —— 这只是**占位美术**，
#   之后的美术工作只需要改 models/block/plant/<n>_*.json 的 parent 与贴图，结构不用动。
#   minT/maxT = 气候温度范围（°C）；decay = 果实腐烂速率（照 TFC 的 tfc:food 数据格式）。
$trees = @(
    [ordered]@{ n='pear';         zh='梨';     en='Pear';         donor='cherry';      minT=-14; maxT=28; decay=3.0 }
    [ordered]@{ n='apricot';      zh='杏';     en='Apricot';      donor='peach';       minT=-14; maxT=30; decay=3.0 }
    [ordered]@{ n='quince';       zh='木梨';   en='Quince';       donor='green_apple'; minT=-12; maxT=30; decay=3.0 }
    [ordered]@{ n='persimmon';    zh='柿';     en='Persimmon';    donor='orange';      minT=-10; maxT=32; decay=2.5 }
    [ordered]@{ n='pomegranate';  zh='石榴';   en='Pomegranate';  donor='red_apple';   minT= -8; maxT=34; decay=2.5 }
    [ordered]@{ n='loquat';       zh='枇杷';   en='Loquat';       donor='lemon';       minT= -6; maxT=32; decay=2.5 }
    # ⚠️ 这里**不能**放 fig 无花果、也不能放 elderberry 接骨木：
    #    · fig  已被 **Firmalife** 实现（firmalife:plant/fig_sapling + firmalife:food/fig）
    #    · elderberry 已被 **TFC** 实现（tfc:plant/elderberry_bush，是浆果灌木）
    #    最初我只把 plantable 文件名重名当成「文件撞车」，用 fpt_ 前缀绕了过去 —— 那是错判。
    #    重名恰恰是「该物种已被占用」的信号，正确做法是**不新增这个物种**，
    #    否则游戏里会同时存在两套无花果树 / 两种接骨木，玩家分不清该种哪个。
    #    改用两种两边都没占的温带树种：花楸（sorb）与山茱萸（cornelian_cherry）。
    [ordered]@{ n='sorb';            zh='花楸';   en='Sorb';            donor='cherry';      minT=-20; maxT=26; decay=3.0 }
    [ordered]@{ n='mulberry';     zh='桑';     en='Mulberry';     donor='cherry';      minT=-14; maxT=32; decay=2.5 }
    [ordered]@{ n='jujube';       zh='枣';     en='Jujube';       donor='red_apple';   minT=-10; maxT=34; decay=2.0 }
    [ordered]@{ n='hawthorn';     zh='山楂';   en='Hawthorn';     donor='cherry';      minT=-18; maxT=28; decay=3.0 }
    [ordered]@{ n='medlar';       zh='欧楂';   en='Medlar';       donor='green_apple'; minT=-14; maxT=28; decay=3.0 }
    [ordered]@{ n='pawpaw';       zh='巴婆果'; en='Pawpaw';       donor='lemon';       minT=-14; maxT=30; decay=2.5 }
    # ⚠️ 不能叫 serviceberry:唐棣 —— 那个名字已经被蔓生灌木占了（plant/serviceberry_bush
    #    与它的产物 food/serviceberry），果实物品会与灌木的产物**重复注册**而崩溃。
    [ordered]@{ n='crabapple';    zh='海棠';   en='Crabapple';    donor='red_apple';   minT=-20; maxT=28; decay=3.0 }
    [ordered]@{ n='cornelian_cherry'; zh='山茱萸'; en='Cornelian Cherry'; donor='plum'; minT=-18; maxT=30; decay=2.5 }

    # ---------------- 热带果树 14 种 ----------------
    # 温度区间整体偏暖（耐寒下限 5~16°C、上限 34~42°C），与温带那批形成互补：
    # 温带树种在热带会因温度越界枯死，反之亦然 —— 这正是 TFC 气候系统该有的样子。
    # donor 仍借用 TFC 现有的 8 套果树模型（占位美术），换美术时只改模型的 parent/贴图。
    # decay 比温带更小 = **烂得更快**（热带果不耐放），符合现实与游戏体验。
    # ⚠️ 排除的候选：banana（TFC 已实现）；柑橘类 pomelo/kumquat/mandarin（与 TFC 的
    #    lemon/orange 语义太近，会让玩家混淆）；coconut/date_palm（棕榈形态不适配现有分枝模型）；
    #    passionfruit（藤本，属攀爬作物机制）。脚本 §11 的物种冲突检查会自动兜住重名。
    [ordered]@{ n='mango';      zh='芒果';   en='Mango';      donor='orange';      minT= 10; maxT=40; decay=2.0 }
    [ordered]@{ n='papaya';     zh='木瓜';   en='Papaya';     donor='lemon';       minT= 12; maxT=42; decay=1.5 }
    [ordered]@{ n='guava';      zh='番石榴'; en='Guava';      donor='cherry';      minT=  8; maxT=40; decay=2.0 }
    [ordered]@{ n='lychee';     zh='荔枝';   en='Lychee';     donor='red_apple';   minT=  5; maxT=38; decay=1.5 }
    [ordered]@{ n='longan';     zh='龙眼';   en='Longan';     donor='peach';       minT=  5; maxT=38; decay=1.5 }
    [ordered]@{ n='avocado';    zh='鳄梨';   en='Avocado';    donor='plum';        minT=  8; maxT=36; decay=1.5 }
    [ordered]@{ n='starfruit';  zh='杨桃';   en='Starfruit';  donor='lemon';       minT= 12; maxT=40; decay=2.0 }
    [ordered]@{ n='tamarind';   zh='酸豆';   en='Tamarind';   donor='plum';        minT= 12; maxT=42; decay=2.5 }
    [ordered]@{ n='sapodilla';  zh='人心果'; en='Sapodilla';  donor='orange';      minT= 12; maxT=40; decay=1.5 }
    [ordered]@{ n='cherimoya';  zh='番荔枝'; en='Cherimoya';  donor='green_apple'; minT= 10; maxT=34; decay=1.5 }
    [ordered]@{ n='rambutan';   zh='红毛丹'; en='Rambutan';   donor='red_apple';   minT= 15; maxT=42; decay=1.5 }
    [ordered]@{ n='durian';     zh='榴莲';   en='Durian';     donor='green_apple'; minT= 16; maxT=42; decay=1.5 }
    [ordered]@{ n='jackfruit';  zh='菠萝蜜'; en='Jackfruit';  donor='orange';      minT= 15; maxT=42; decay=1.5 }
    [ordered]@{ n='breadfruit'; zh='面包果'; en='Breadfruit'; donor='olive';       minT= 16; maxT=42; decay=1.5 }

    # ---------------- 坚果 5 种（§7.1「坚果待改树」的落地） ----------------
    # 「待改树」= 坚果应当挂在树上，而不是像作物那样种在地里。
    # **TFC 里没有任何「树干果实 / 树冠果实」方块**（已反汇编确认：`TrunkConfig` 属于
    # world/feature/tree，是普通树木的生成配置，与果实无关；blocks/plant/fruit 下只有
    # FruitTree* 与 *BerryBush* 两族）。所以坚果就用**同一套果树四件套**实现：
    # 果实挂在树叶上，落地方式的差异交给物候（坚果大多秋季成熟）与营养字段来体现。
    #
    # 营养用 protein（照 TFC 自己给 peanut 的定义），decay 取 1.0（坚果耐放，
    # 与 TFC peanut 的 decay_modifier 一致），saturation 用 0.5 而不是水果的 1.5。
    #
    # ⚠️ 候选里**必须排除 chestnut（栗）**：TFC 已经有栗树（作为木材树），
    #    afc（ArborFirmaCraft）还有 hardy_chestnut，加进来就是两套栗树。
    #    同理排除 oak/pine/hickory —— 它们的果实（橡子/松子/山核桃）虽然名字没被占，
    #    但长在别人的树上，玩家会分不清。§11 的冲突检查已扩展到 afc，会自动兜住这类重名。
    [ordered]@{ n='walnut';    zh='核桃';   en='Walnut';    donor='green_apple'; minT=-20; maxT=30; decay=1.0; nutri='protein'; nutriValue=1.5; sat=0.5 }
    [ordered]@{ n='hazelnut';  zh='榛子';   en='Hazelnut';  donor='cherry';      minT=-24; maxT=26; decay=1.0; nutri='protein'; nutriValue=1.5; sat=0.5 }
    [ordered]@{ n='almond';    zh='杏仁';   en='Almond';    donor='peach';       minT= -6; maxT=36; decay=1.5; nutri='protein'; nutriValue=1.5; sat=0.5 }
    [ordered]@{ n='pecan';     zh='碧根果'; en='Pecan';     donor='orange';      minT=-10; maxT=34; decay=1.0; nutri='protein'; nutriValue=1.5; sat=0.5 }
    [ordered]@{ n='macadamia'; zh='夏威夷果'; en='Macadamia'; donor='lemon';     minT=  8; maxT=38; decay=1.5; nutri='protein'; nutriValue=1.5; sat=0.5 }
    # ── 批次 10：老茎结果（cauliflory）6 种 ──
    #    ⚠️ 这 6 种的果实在**树干**上（由 TrunkFruitBlock 承载），**不在树叶上** ——
    #       它们的 Lifecycle 刻意不含 FRUITING（见 tree\FarmingFruitTrees.java），树叶只开花不结果。
    #       所以这里不需要 nutri 之类的特殊字段，树本体走常规果树管线（树苗/枝干/树叶）即可。
    [ordered]@{ n='jabuticaba'; zh='嘉宝果';   en='Jabuticaba'; donor='cherry';      minT=12; maxT=38; decay=1.0 }
    [ordered]@{ n='soursop';    zh='刺果番荔枝'; en='Soursop';    donor='green_apple'; minT=15; maxT=40; decay=1.0 }
    [ordered]@{ n='mangosteen'; zh='山竹';     en='Mangosteen'; donor='red_apple';   minT=16; maxT=42; decay=1.5 }
    [ordered]@{ n='cupuacu';    zh='大花可可'; en='Cupuacu';    donor='orange';      minT=18; maxT=42; decay=0.8 }
    [ordered]@{ n='bael';       zh='木橘';     en='Bael';       donor='orange';      minT=14; maxT=40; decay=2.0 }
    [ordered]@{ n='canistel';   zh='蛋黄果';   en='Canistel';   donor='peach';       minT=15; maxT=40; decay=1.2 }
    [ordered]@{ n='black_pepper'; zh='黑胡椒'; en='Black Pepper'; donor='green_apple'; minT=18; maxT=38; decay=0.3 }
      [ordered]@{ n='waxberry'; zh='杨梅'; en='Waxberry'; donor='red_apple'; minT=5; maxT=30; decay=2.5 }
      [ordered]@{ n='lime'; zh='青柠'; en='Lime'; donor='lemon'; minT=12; maxT=38; decay=2.0 }
      [ordered]@{ n='grapefruit'; zh='葡萄柚'; en='Grapefruit'; donor='orange'; minT=10; maxT=36; decay=2.5 }
      [ordered]@{ n='kiwi'; zh='猕猴桃'; en='Kiwi'; donor='plum'; minT=-5; maxT=28; decay=2.0 }
      [ordered]@{ n='wax_apple'; zh='莲雾'; en='Wax Apple'; donor='red_apple'; minT=18; maxT=38; decay=2.5 }
      [ordered]@{ n='wampee'; zh='黄皮'; en='Wampee'; donor='lemon'; minT=12; maxT=34; decay=2.0 }
      [ordered]@{ n='amla'; zh='油柑'; en='Amla'; donor='green_apple'; minT=15; maxT=40; decay=3.0 }
      [ordered]@{ n='sea_buckthorn'; zh='沙棘'; en='Sea Buckthorn'; donor='orange'; minT=-15; maxT=24; decay=1.5 }
)

foreach ($t in $trees) {
    $n = $t['n']; $d = $t['donor']
    $product = if ($n -in @('cupuacu', 'cocoa')) { (Read-CocoaPolicy).product } else { "${NS}:food/$n" }
    # [1] 树苗：saplings=1..4（没有 0 —— 0 表示已经长成枝干）
    $v = [ordered]@{}
    for ($i = 1; $i -le 4; $i++) { $v["saplings=$i"] = [ordered]@{ model = "${NS}:block/plant/${n}_sapling_$i" } }
    Save-Json "assets/$NS/blockstates/plant/${n}_sapling.json" ([ordered]@{ variants = $v })
    for ($i = 1; $i -le 4; $i++) {
        Save-Json "assets/$NS/models/block/plant/${n}_sapling_$i.json" ([ordered]@{ parent = "tfc:block/plant/${d}_sapling_$i" })
    }
    # [2][3] 枝干 / 生长枝干：multipart，模型完全一样（SAPLINGS/NATURAL 不进模型）
    $mp = @(
        [ordered]@{ apply = [ordered]@{ model = "${NS}:block/plant/${n}_branch_core" } }
        [ordered]@{ when = [ordered]@{ down = $true };  apply = [ordered]@{ model = "${NS}:block/plant/${n}_branch_down" } }
        [ordered]@{ when = [ordered]@{ up = $true };    apply = [ordered]@{ model = "${NS}:block/plant/${n}_branch_up" } }
        [ordered]@{ when = [ordered]@{ north = $true }; apply = [ordered]@{ model = "${NS}:block/plant/${n}_branch_side"; y = 90 } }
        [ordered]@{ when = [ordered]@{ south = $true }; apply = [ordered]@{ model = "${NS}:block/plant/${n}_branch_side"; y = 270 } }
        [ordered]@{ when = [ordered]@{ west = $true };  apply = [ordered]@{ model = "${NS}:block/plant/${n}_branch_side" } }
        [ordered]@{ when = [ordered]@{ east = $true };  apply = [ordered]@{ model = "${NS}:block/plant/${n}_branch_side"; y = 180 } }
    )
    Save-Json "assets/$NS/blockstates/plant/${n}_branch.json"         ([ordered]@{ multipart = $mp })
    Save-Json "assets/$NS/blockstates/plant/${n}_growing_branch.json" ([ordered]@{ multipart = $mp })
    foreach ($part in @('branch_core','branch_down','branch_up','branch_side')) {
        Save-Json "assets/$NS/models/block/plant/${n}_$part.json" ([ordered]@{ parent = "tfc:block/plant/${d}_$part" })
    }
    # [4] 树叶：4 个 lifecycle 变体
    Save-Json "assets/$NS/blockstates/plant/${n}_leaves.json" ([ordered]@{ variants = [ordered]@{
        'lifecycle=healthy'   = [ordered]@{ model = "${NS}:block/plant/${n}_leaves" }
        'lifecycle=dormant'   = [ordered]@{ model = "${NS}:block/plant/${n}_dry_leaves" }
        'lifecycle=flowering' = [ordered]@{ model = "${NS}:block/plant/${n}_flowering_leaves" }
        'lifecycle=fruiting'  = [ordered]@{ model = "${NS}:block/plant/${n}_fruiting_leaves" }
    } })
    foreach ($lc in @('leaves','dry_leaves','flowering_leaves','fruiting_leaves')) {
        Save-Json "assets/$NS/models/block/plant/${n}_$lc.json" ([ordered]@{ parent = "tfc:block/plant/${d}_$lc" })
    }
    # [5] 掉落表：树苗掉自己、枝干掉木棍、树叶掉树苗（照 TFC）
    Save-Json "data/$NS/loot_table/blocks/plant/${n}_sapling.json" ([ordered]@{
        type='minecraft:block'
        pools=@([ordered]@{ name='loot_pool'; rolls=1
            entries=@([ordered]@{ type='minecraft:item'; name="${NS}:plant/${n}_sapling"
                functions=@(
                    [ordered]@{ function='minecraft:set_count'; count=1; conditions=@([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:plant/${n}_sapling"; properties=[ordered]@{ saplings='1' } }) }
                    [ordered]@{ function='minecraft:set_count'; count=2; conditions=@([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:plant/${n}_sapling"; properties=[ordered]@{ saplings='2' } }) }
                    [ordered]@{ function='minecraft:set_count'; count=3; conditions=@([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:plant/${n}_sapling"; properties=[ordered]@{ saplings='3' } }) }
                    [ordered]@{ function='minecraft:set_count'; count=4; conditions=@([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:plant/${n}_sapling"; properties=[ordered]@{ saplings='4' } }) }
                    [ordered]@{ function='minecraft:explosion_decay' }
                ) })
            conditions=@([ordered]@{ condition='minecraft:survives_explosion' }) })
    })
    # 枝干掉落：**逐字照 TFC 的 cherry_branch** —— 两个池
    #   池 1：用**斧头**砍掉「向上 + 有水平分枝」的枝干时掉一棵树苗。
    #         这是果树唯一的自然繁殖途径（也是用户问的「树苗掉落」）。
    #   池 2：木棍 1~4。
    # ⚠️ properties 的值必须是**字符串** 'true' —— 写成 $true 会被序列化成布尔 true，
    #    方块状态匹配会静默失配（掉不出树苗）。
    Save-Json "data/$NS/loot_table/blocks/plant/${n}_branch.json" ([ordered]@{
        type='minecraft:block'
        pools=@(
            [ordered]@{ name='loot_pool'; rolls=1
                entries=@([ordered]@{ type='minecraft:item'; name="${NS}:plant/${n}_sapling"
                    conditions=@([ordered]@{ condition='minecraft:all_of'; terms=@(
                        [ordered]@{ condition='minecraft:any_of'; terms=@(
                            [ordered]@{ condition='minecraft:block_state_property'; block="${NS}:plant/${n}_branch"; properties=[ordered]@{ 'up'='true'; 'west'='true' } }
                            [ordered]@{ condition='minecraft:block_state_property'; block="${NS}:plant/${n}_branch"; properties=[ordered]@{ 'up'='true'; 'east'='true' } }
                            [ordered]@{ condition='minecraft:block_state_property'; block="${NS}:plant/${n}_branch"; properties=[ordered]@{ 'up'='true'; 'north'='true' } }
                            [ordered]@{ condition='minecraft:block_state_property'; block="${NS}:plant/${n}_branch"; properties=[ordered]@{ 'up'='true'; 'south'='true' } }
                        ) }
                        [ordered]@{ condition='minecraft:match_tool'; predicate=[ordered]@{ items='#minecraft:axes' } }
                    ) }) })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' }) },
            [ordered]@{ name='loot_pool'; rolls=1
                entries=@([ordered]@{ type='minecraft:item'; name='minecraft:stick'
                    functions=@([ordered]@{ function='minecraft:set_count'
                        count=[ordered]@{ type='minecraft:uniform'; min=1; max=4 } }) })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' }) }
        )
    })
    if ($n -in @('jabuticaba','soursop','mangosteen','cupuacu','bael','canistel','black_pepper')) {
        $branchPath = Join-Path $root "data/$NS/loot_table/blocks/plant/${n}_branch.json"
        $branchLoot = $ser.DeserializeObject([IO.File]::ReadAllText($branchPath,$utf8))
        $branchLoot['pools'] = @($branchLoot['pools']) + @([ordered]@{
            name='tfcfarmingplus_branch_fruit'; rolls=1
            entries=@([ordered]@{type='minecraft:item';name=$product})
            conditions=@([ordered]@{condition='minecraft:survives_explosion'},[ordered]@{
                condition='minecraft:block_state_property';block="${NS}:plant/${n}_branch";properties=[ordered]@{fruit='ripe'}})
        })
        Save-Json "data/$NS/loot_table/blocks/plant/${n}_branch.json" $branchLoot
    }
    Save-Json "data/$NS/loot_table/blocks/plant/${n}_growing_branch.json" ([ordered]@{
        type='minecraft:block'
        pools=@([ordered]@{ name='loot_pool'; rolls=1
            entries=@([ordered]@{ type='minecraft:item'; name='minecraft:stick'
                functions=@([ordered]@{ function='minecraft:set_count'
                    count=[ordered]@{ type='minecraft:uniform'; min=1; max=4 } }) })
            conditions=@([ordered]@{ condition='minecraft:survives_explosion' }) })
    })
    # 树叶掉落：照 TFC 的 cherry_leaves，**三个池** ——
    #   池 1：结果期掉自己的果实（TFC 的果树产物就挂在结果期的树叶上）
    #   池 2：剪刀 / 精准采集 → 掉树叶本身
    #   池 3：木棍 —— 用 `#tfc:tools/sharp` 锋利工具有 20% 概率，其它工具只有 5%，
    #         且**剪刀/精准采集时整池跳过**（inverted）。此前我们写成了无条件 1~2 根，是错的。
    Save-Json "data/$NS/loot_table/blocks/plant/${n}_leaves.json" ([ordered]@{
        type='minecraft:block'
        pools=@(
            [ordered]@{ name='loot_pool'; rolls=1
                entries=@([ordered]@{ type='minecraft:item'; name=$product
                    conditions=@([ordered]@{ condition='minecraft:block_state_property'
                        block="${NS}:plant/${n}_leaves"; properties=[ordered]@{ lifecycle='fruiting' } }) })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' }) },
            [ordered]@{ name='loot_pool'; rolls=1
                entries=@([ordered]@{ type='minecraft:item'; name="${NS}:plant/${n}_leaves"
                    conditions=@([ordered]@{ condition='minecraft:any_of'; terms=@(
                        [ordered]@{ condition='minecraft:match_tool'; predicate=[ordered]@{ items='#c:tools/shear' } }
                        [ordered]@{ condition='minecraft:match_tool'; predicate=[ordered]@{ predicates=[ordered]@{ 'minecraft:enchantments'=@([ordered]@{ enchantments='minecraft:silk_touch'; levels=[ordered]@{ min=1 } }) } } }
                    ) }) })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' }) },
            [ordered]@{ name='loot_pool'; rolls=1
                entries=@([ordered]@{ type='minecraft:alternatives'; children=@(
                    [ordered]@{ type='minecraft:item'; name='minecraft:stick'
                        conditions=@(
                            [ordered]@{ condition='minecraft:match_tool'; predicate=[ordered]@{ items='#tfc:tools/sharp' } }
                            [ordered]@{ condition='minecraft:random_chance'; chance=0.2 }
                        )
                        functions=@([ordered]@{ function='minecraft:set_count'
                            count=[ordered]@{ type='minecraft:uniform'; min=1; max=2 } }) }
                    [ordered]@{ type='minecraft:item'; name='minecraft:stick'
                        conditions=@([ordered]@{ condition='minecraft:random_chance'; chance=0.05 })
                        functions=@([ordered]@{ function='minecraft:set_count'
                            count=[ordered]@{ type='minecraft:uniform'; min=1; max=2 } }) }
                )
                # ⚠️ `inverted` 必须挂在**这个 alternatives 条目**上，而不是整个 pool 上 —— 照 TFC 原样。
                #    挂在池上时，条件不满足会**消耗掉这次 rolls**，语义与「本池本次不产出」不同。
                conditions=@([ordered]@{ condition='minecraft:inverted'; term=[ordered]@{ condition='minecraft:any_of'; terms=@(
                    [ordered]@{ condition='minecraft:match_tool'; predicate=[ordered]@{ items='#c:tools/shear' } }
                    [ordered]@{ condition='minecraft:match_tool'; predicate=[ordered]@{ predicates=[ordered]@{ 'minecraft:enchantments'=@([ordered]@{ enchantments='minecraft:silk_touch'; levels=[ordered]@{ min=1 } }) } } }
                ) } }) })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' }) }
        )
    })
    # [5b] Firmalife 的「果树叶」额外掉落 —— 与它给 TFC 那八种果树做的**完全一致**。
    #
    #   背景：Firmalife 用 `neoforge:add_table` 给 `tfc:blocks/plant/cherry_leaves` 等八张表
    #   额外挂了一张 `firmalife:blocks/fruit_leaves`，语义是：
    #     **「没用剪刀 / 精准采集时，50% 概率额外掉 1 个 firmalife:fruit_leaf」**。
    #   我们的 33 种果树树叶原本没有这个掉落 —— 等于比 TFC 原版那 8 种「少一样东西」。
    #
    #   ⚠️ 刻意**不往掉落表里加池**：verify.ps1 第 11 项会拿 `<n>_leaves` 与 TFC 的
    #   `cherry_leaves` 递归比对（忽略键序），直接改表会让那条回归保护失效。
    #   所以照 Firmalife 的做法走 loot modifier，把额外掉落挂在表**外面**。
    Save-Json "data/$NS/loot_modifiers/${n}_leaves.json" ([ordered]@{
        type = 'neoforge:add_table'
        conditions = @([ordered]@{
            condition = 'neoforge:loot_table_id'
            loot_table_id = "${NS}:blocks/plant/${n}_leaves"
        })
        table = 'firmalife:blocks/fruit_leaves'
    })
    # [6] 气候
    Save-Json "data/$NS/tfc/climate_range/plant/${n}_tree.json" ([ordered]@{
        max_temperature = [double]$t['maxT']; min_temperature = [double]$t['minT']
    })
    # [6b] 世界生成 —— configured_feature + placed_feature，逐字照 TFC 的 plant/cherry：
    #      feature 类型是 `tfc:fruit_trees`，它放的**不是成品树、而是「生长中的枝干」**，
    #      之后由枝干自己长成完整的树（反汇编 TFC 的 FruitTreeFeature 确认）。
    #      放置条件用 TFC 自己的 `tfc:climate` modifier，再叠原版的 heightmap / in_square / rarity_filter。
    Save-Json "data/$NS/worldgen/configured_feature/plant/${n}_tree.json" ([ordered]@{
        type = 'tfc:fruit_trees'
        config = [ordered]@{ state = "${NS}:plant/${n}_growing_branch" }
    })
    Save-Json "data/$NS/worldgen/placed_feature/plant/${n}_tree.json" ([ordered]@{
        feature = "${NS}:plant/${n}_tree"
        placement = @(
            [ordered]@{
                type = 'tfc:climate'
                min_temperature = [double]$t['minT']; max_temperature = [double]$t['maxT']
                min_groundwater = 100; max_groundwater = 400; max_forest = 3
            }
            [ordered]@{ type = 'minecraft:heightmap';    heightmap = 'WORLD_SURFACE_WG' }
            [ordered]@{ type = 'minecraft:in_square' }
            [ordered]@{ type = 'minecraft:rarity_filter'; chance = 60 }
        )
    })
    # [7] 果实食物数据。
    # 营养字段**可配置**：水果走 fruit，坚果走 protein（照 TFC 自己给 peanut 的定义
    # {"decay_modifier":1.0,"hunger":4,"protein":1.5,"saturation":0.5}）。
    # 表里不写就按水果处理，所以既有的 28 种树行为完全不变。
    $nutri = if ($t.Contains('nutri')) { $t['nutri'] } else { 'fruit' }
    $nutriValue = if ($t.Contains('nutriValue')) { [double]$t['nutriValue'] } else { 1.2 }
    $sat = if ($t.Contains('sat')) { [double]$t['sat'] } else { 1.5 }
    $food = [ordered]@{ decay_modifier = [double]$t['decay']; hunger = 4 }
    $food[$nutri] = $nutriValue
    $food['ingredient'] = [ordered]@{ item = "${NS}:food/$n" }
    $food['saturation'] = $sat
    Save-Json "data/$NS/tfc/food/${n}.json" $food
    # [8] 物品模型
    # 树叶**有方块物品**：照 TFC 的 cherry_leaves，物品模型直接继承方块模型（3D）。
    # 树苗**必须走 item/generated 平面图标**，不能继承方块模型 ——
    #   方块模型是 `{"parent":"block/cross"}`（3D 十字），直接拿来当物品模型，
    #   物品栏里会渲染成一个立体的十字架而不是图标。
    #   对照 TFC 的 models/item/plant/cherry_sapling.json：
    #       {"parent":"item/generated","textures":{"layer0":"tfc:block/fruit_tree/cherry_sapling"}}
    # 枝干与生长枝干**没有**物品（TFC 里也没有它们的物品模型），不生成。
    Save-Json "assets/$NS/models/item/plant/${n}_leaves.json" ([ordered]@{ parent = "${NS}:block/plant/${n}_leaves" })
    Save-Json "assets/$NS/models/item/plant/${n}_sapling.json" ([ordered]@{
        parent = 'item/generated'
        textures = [ordered]@{ layer0 = "tfc:block/fruit_tree/${d}_sapling" }
    })
    Save-Json "assets/$NS/models/item/food/${n}.json" ([ordered]@{ parent='item/generated'; textures=[ordered]@{ layer0="tfc:item/food/${d}" } })
}
# [9] 语言键（读-改-写，不覆盖其它脚本写的键）
foreach ($lang in @('en_us','zh_cn')) {
    $lf = Join-Path $root "assets/$NS/lang/$lang.json"
    $out = [ordered]@{}
    if (Test-Path $lf) {
        $d = [System.IO.File]::ReadAllText($lf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($pp in $d.PSObject.Properties) { $out[$pp.Name] = $pp.Value }
    }
    $zh = $lang -eq 'zh_cn'
    foreach ($tr in $trees) {
        $n = $tr['n']
        $out["item.$NS.food.$n"]              = if ($zh) { $tr['zh'] } else { $tr['en'] }
        $out["block.$NS.plant.${n}_sapling"]  = if ($zh) { "$($tr['zh'])树苗" } else { "$($tr['en']) Sapling" }
        $out["block.$NS.plant.${n}_leaves"]   = if ($zh) { "$($tr['zh'])树叶" } else { "$($tr['en']) Leaves" }
    }
    [void][IO.Directory]::CreateDirectory((Split-Path $lf -Parent))
    [System.IO.File]::WriteAllText($lf, ($out | ConvertTo-Json -Depth 5 -Compress), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  lang $lang : $($out.Keys.Count) 条"
}
# [9b] 全局战利品修饰器注册表 —— 把上面那批 `<n>_leaves` modifier 挂进去。
#   NeoForge 会扫描**每个模组各自的** `data/<ns>/loot_modifiers/global_loot_modifiers.json`
#   再合并，所以写在自己的命名空间下，不会与 Firmalife 的同名文件打架。
$glmEntries = @()
foreach ($tr in $trees) { $glmEntries += "${NS}:$($tr['n'])_leaves" }   # ⚠️ 必须是 ${NS}: —— "$NS:" 会被当成作用域变量（§8.2-1）
Save-Json "data/$NS/loot_modifiers/global_loot_modifiers.json" ([ordered]@{
    entries = $glmEntries
    replace = $false
})
Write-Host "  Firmalife 果树叶掉落 modifier: $($glmEntries.Count) 个（挂在各自 <n>_leaves 表上）"

# [10] 导出清单 —— 供 gen-tags.ps1 / gen-patchouli-book.ps1 等读取，保持「树名只有一处定义」。
# The legacy manifest is scratch output, never the live tools manifest.
$manifest = [ordered]@{ trees = @() }
foreach ($tr in $trees) {
    $manifest.trees += [ordered]@{
        name = $tr['n']; zh = $tr['zh']; en = $tr['en']; donor = $tr['donor']
        minT = $tr['minT']; maxT = $tr['maxT']; decay = $tr['decay']
    }
}
$manifestDir = Join-Path $root '_generated-manifests'
[void][IO.Directory]::CreateDirectory($manifestDir)
[System.IO.File]::WriteAllText((Join-Path $manifestDir 'fruit-trees-manifest.json'),
    $ser.Serialize($manifest), $utf8)
Write-Host "果树资源已生成: $($trees.Count) 种，共 $($script:count) 个文件"

# [11] 物种冲突检查 —— 树名不得与 TFC / Firmalife 已有的植物重名。
# 为什么需要：本工程踩过两次同类错误 ——
#   · serviceberry 撞了本模组自己的蔓生灌木（产物 food/serviceberry 重复注册，启动直接崩）
#   · fig 撞 Firmalife 的无花果树、elderberry 撞 TFC 的接骨木灌木
# 后两个最初只被当成「Firmalife plantable 文件名撞车」，我还用 fpt_ 前缀绕了过去 —— 那是错判：
# **重名恰恰说明该物种已被实现**，正确做法是换一个两边都没占的树种，
# 否则游戏里会同时存在两套无花果树、两种接骨木，玩家根本分不清该种哪个。
# 这里在**生成阶段**就把占用名单扫出来，撞车直接 throw，不再等到手测才发现。
# $root = <版本目录>\mod_rebuild\tfcfarmingplus\src\main\resources，要上溯 5 级才到版本目录
$modsDir = Join-Path (Split-Path (Split-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) -Parent) -Parent) 'mods'
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
$occupied = @{}
foreach ($pat in @('TerraFirmaCraft-*.jar', 'Firmalife-*.jar', 'afc-*.jar')) {  # afc = ArborFirmaCraft，62 个树种
    $jf = Get-ChildItem $modsDir -Filter $pat -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $jf) { continue }
    $mod = if ($jf.Name -match 'Firmalife') { 'firmalife' } elseif ($jf.Name -match '^afc') { 'afc' } else { 'tfc' }
    $zz = [System.IO.Compression.ZipFile]::OpenRead($jf.FullName)
    foreach ($en in $zz.Entries) {
        if ($en.FullName -match "^assets/$mod/blockstates/plant/([a-z_]+?)(?:_sapling|_bush|_plant)\.json$" -or $en.FullName -match "^assets/$mod/blockstates/wood/sapling/([a-z_]+)\.json$") {  # afc 的树走 wood/ 目录
            $occupied[$Matches[1]] = $mod
        }
    }
    $zz.Dispose()
}
if ($occupied.Count -eq 0) { Write-Host "[11] 警告：没能从 TFC/Firmalife 提取到物种名单，跳过冲突检查" }
else {
    $clash = @()
    foreach ($tr in $trees) {
        if ($occupied.ContainsKey($tr['n'])) { $clash += "$($tr['n'])（已被 $($occupied[$tr['n']]) 实现）" }
    }
    if ($clash.Count -gt 0) {
        throw "[11] 树名与 TFC/Firmalife 已有物种重名: $($clash -join '、') —— 重名说明该物种已被实现，请换用未占用的树种"
    }
    Write-Host "[11] 物种冲突检查通过: $($trees.Count) 种树名均未被 TFC/Firmalife 占用（已扫描 $($occupied.Count) 个物种）"
}
