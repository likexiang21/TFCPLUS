# ============================================================
# 作物批量生成器 —— 数据驱动，一次产出「一株作物」的全部文件
# ============================================================
# 本脚本把「新增一种作物」的所有经验固化下来。新增作物时只需在下方 $crops
# 数据表里加一行，然后跑本脚本 + 在 MyCrops.java 里加对应的 Java 字段。
#
# ── 新增一种作物必须齐备的清单（每一步都是踩过坑的） ──────────────
#  [1] data/<ns>/tfc/climate_range/crop/<name>.json        气候数据
#  [2] data/<ns>/tfc/food/<name>.json                      产物营养与保质期
#  [3] data/<ns>/loot_table/blocks/crop/<name>.json        作物掉落（含 tfc:crop_yield_uniform）
#  [4] data/<ns>/loot_table/blocks/dead_crop/<name>.json   枯萎掉落（掉回对应种子）
#  [5] data/<ns>/loot_table/blocks/wild_crop/<name>.json   野生掉落
#  [6] assets/<ns>/blockstates/crop/<name>.json            方块状态（age 0..maxAge）
#  [7] assets/<ns>/models/block/crop/<name>_age_<i>.json   方块模型（父级 block/crop）
#  [8] assets/<ns>/models/block/dead_crop/<name>[_young].json
#  [9] assets/<ns>/models/item/food/<name>.json + seeds/<name>.json
# [10] data/<ns>/worldgen/configured_feature/plant/wild_crop/<name>.json        单株
# [11] data/<ns>/worldgen/configured_feature/plant/wild_crop/<name>_patch.json  成片
# [12] data/<ns>/worldgen/placed_feature/plant/wild_crop/<name>.json            单株放置
# [13] data/<ns>/worldgen/placed_feature/plant/wild_crop/<name>_patch.json      成片放置
#      ⚠️ random_patch 的 config.feature 引用的是【placed_feature】而不是 configured_feature
# [14] 追加进 TFC 的 tag（全部 replace:false 合并式）：
#        minecraft:mineable/hoe   ← 加这一个即可自动继承 tfc:mineable/{hoe,knife,scythe}
#        tfc:crops                ← 作物类判定
#        tfc:can_be_snow_piled + item:c:/tfc:wild_crops  ← 仅野生作物
# [15] data/firmalife/firmalife/plantable/<name>.json      Firmalife 种植盆（quad 盆）
# [16] lang：item.<ns>.food.<name> / item.<ns>.seeds.<name> / block.<ns>.crop.<name>
#              block.<ns>.wild_crop.<name> / block.<ns>.dead_crop.<name> / block.<ns>.dead_berry_bush
# [17] Java 侧（MyCrops.java）：
#        climate 引用、DEAD_<NAME> 死株、食物、种子、<NAME>_CROP 方块
#        ⚠️ 种子字段要用【限定名】MyCrops.<NAME>_CROP.get() 规避 Java 前向引用限制
#        ⚠️ 作物方块必须走 MyCropBlock.create()（age 属性需在 new 之前由匿名子类捕获）
#        ⚠️ BE 类型必须用自建的 MyBlockEntities.CROP，且新方块要加进 cropBlocks()
# [18] 客户端 TFCFarmingPlusClient.cutoutBlocks()：加入作物方块 + 野生作物 + 死株
# [19] 手册：gen-patchouli-book.ps1 的 $crops 表加一行 + 重跑 + polish-book.ps1 生成跳转映射
#     ⚠️ 手册条目是「文字页 + tfc:multimultiblock 页」两页，页码会影响 extra_recipe_mappings
# [20] 名称用【简短俗名】，并检查是否与 TFC 现有物品撞名
#
# ── 通用陷阱 ────────────────────────────────────────────────
#  · PowerShell 双引号里 "`$ns:xxx" 会被当成带作用域的变量 → 一律写 ${ns}
#  · .ps1 必须存为 UTF-8 with BOM，否则 PS 5.1 按 GBK 解码中文会炸
#  · JavaScriptSerializer 序列化，避免 PS 5.1 ConvertTo-Json 的单元素数组缺陷
# ============================================================
param([string]$Root = '', [switch]$BroccoliFormsOnly, [switch]$LettuceFormsOnly, [switch]$KaleWildFormsOnly, [switch]$CauliflowerFormsOnly, [switch]$NapaCabbageFormsOnly, [switch]$ChiliDisplayOnly, [switch]$FenugreekDisplayOnly, [switch]$SpinachDisplayOnly, [switch]$SunflowerDisplayOnly, [switch]$SwissChardDisplayOnly, [switch]$CeleryDisplayOnly, [switch]$CeltuceDisplayOnly, [switch]$RhubarbDisplayOnly, [switch]$ItemIconsOnly)
# -Root must be a child of moddev/.probe/generator-output; never publish the whole draft.
# 2026-09-28 lesson: $root used to be a HARD-CODED absolute path, so running this script
# inside a shadow sandbox still rewrote the real resource tree (2416 files had to be
# rolled back from a snapshot). Any script you want to dry-run must allow relocating root.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

. (Join-Path $PSScriptRoot 'cocoa-data-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $Root
$NS = 'tfcfarmingplus'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:count = 0

# 合并式 tag 写入：读取现有条目后追加去重（与 gen-tags.ps1 产出的内容共存，不丢数据）
# ⚠️ 不要用 Select-Object -Unique —— 它会给结果附加 PowerShell 元数据（PSParameterizedProperty），
#    JavaScriptSerializer 序列化时会报 "circular reference"。这里用纯 List[string]。
function Merge-Tag([string]$rel, $newValues) {
    $path = Join-Path $root $rel
    $list = New-Object System.Collections.Generic.List[string]
    $seen = New-Object System.Collections.Generic.HashSet[string]
    if (Test-Path $path) {
        $j = $ser.DeserializeObject([System.IO.File]::ReadAllText($path, $utf8))
        # ⚠️ 不要用 $j.ContainsKey(...)：PS 对反序列化结果的类型包装会让它失效，
        #    改用 try 取值 + foreach，实测可靠。
        try { $vals = @($j['values']) } catch { $vals = @() }
        foreach ($v in $vals) { if ($null -ne $v) { if ($seen.Add([string]$v)) { $list.Add([string]$v) } } }
    }
    $added = 0
    foreach ($v in @($newValues)) { if ($seen.Add([string]$v)) { $list.Add([string]$v); $added++ } }
    Save-Json $rel ([ordered]@{ replace = $false; values = $list.ToArray() })
    Write-Host ("  合并 tag {0,-52} 新增 {1} 项 -> 共 {2} 项" -f $rel, $added, $list.Count)
}
function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($obj), $utf8)
    $script:count++
}

# Reviewed AR4-D/E/F source JSON is canonical for the selected species/forms.
# Other full legacy draft content remains obsolete; never publish it wholesale.
function Copy-ReviewedCropForms([ValidateSet('broccoli','lettuce','cauliflower','napa_cabbage')][string]$Species) {
    $source=Join-Path (Split-Path $PSScriptRoot -Parent) 'src/main/resources'
    $reviewed=@(
        "assets/tfcfarmingplus/blockstates/wild_crop/$Species.json"
        "assets/tfcfarmingplus/models/block/wild_crop/$Species.json"
        "assets/tfcfarmingplus/models/block/wild_crop/${Species}_young.json"
        "assets/tfcfarmingplus/models/block/dead_crop/$Species.json"
        "assets/tfcfarmingplus/models/block/dead_crop/${Species}_young.json"
    )
    foreach($relative in $reviewed){
        $sourcePath=Join-Path $source $relative
        if(-not (Test-Path -LiteralPath $sourcePath)){throw "Reviewed $Species source missing: $relative"}
        $output=Join-Path $root $relative
        [void][IO.Directory]::CreateDirectory((Split-Path $output -Parent))
        [IO.File]::WriteAllBytes($output,[IO.File]::ReadAllBytes($sourcePath))
    }
    Write-Host "Copied five reviewed $Species form JSONs to restricted draft output."
}
function Copy-ReviewedKaleWildForms {
    $source=Join-Path (Split-Path $PSScriptRoot -Parent) 'src/main/resources'
    foreach($relative in @('assets/tfcfarmingplus/blockstates/wild_crop/kale.json','assets/tfcfarmingplus/models/block/wild_crop/kale.json','assets/tfcfarmingplus/models/block/wild_crop/kale_young.json')){
        $sourcePath=Join-Path $source $relative
        if(-not(Test-Path -LiteralPath $sourcePath)){throw "Reviewed kale source missing: $relative"}
        $output=Join-Path $root $relative
        [void][IO.Directory]::CreateDirectory((Split-Path $output -Parent))
        [IO.File]::WriteAllBytes($output,[IO.File]::ReadAllBytes($sourcePath))
    }
    Write-Host 'Copied three reviewed kale wild-form JSONs to restricted draft output; shared dead resources untouched.'
}
function Copy-ReviewedCropDisplay([ValidateSet('chili','fenugreek','spinach','sunflower','swiss_chard','celery','celtuce','rhubarb')][string]$Species) {
    if($Species -eq 'celery'){
        & (Join-Path $PSScriptRoot 'audit-celery-display.ps1')
        if($LASTEXITCODE -ne 0){throw 'Celery display preflight failed; no files copied.'}
    }
    if($Species -eq 'celtuce'){
        & (Join-Path $PSScriptRoot 'audit-celtuce-display.ps1')
        if($LASTEXITCODE -ne 0){throw 'Celtuce display preflight failed; no files copied.'}
    }
    if($Species -eq 'rhubarb'){
        & (Join-Path $PSScriptRoot 'audit-rhubarb-display.ps1')
        if($LASTEXITCODE -ne 0){throw 'Rhubarb display preflight failed; no files copied.'}
    }
    if($Species -eq 'swiss_chard'){
        & (Join-Path $PSScriptRoot 'audit-swiss-chard-display.ps1')
        if($LASTEXITCODE -ne 0){throw 'Swiss chard display preflight failed; no files copied.'}
    }
    if($Species -eq 'spinach'){
        & (Join-Path $PSScriptRoot 'audit-spinach-display.ps1')
        if($LASTEXITCODE -ne 0){throw 'Spinach display preflight failed; no files copied.'}
    }
    if($Species -eq 'sunflower'){
        & (Join-Path $PSScriptRoot 'audit-sunflower-display.ps1')
        if($LASTEXITCODE -ne 0){throw 'Sunflower display preflight failed; no files copied.'}
    }
    $source=Join-Path (Split-Path $PSScriptRoot -Parent) 'src/main/resources'
    $files=Get-Content -LiteralPath (Join-Path $PSScriptRoot "${Species}-display-files.json") -Raw -Encoding UTF8|ConvertFrom-Json
    $contract=Get-Content -LiteralPath (Join-Path $PSScriptRoot "${Species}-display-contract.json") -Raw -Encoding UTF8|ConvertFrom-Json
    # Preflight every input before writing any reviewed file.
    foreach($relative in $files){
        if(-not(Test-Path -LiteralPath (Join-Path $source $relative))){throw "Reviewed ${Species} JSON missing: $relative"}
    }
    foreach($entry in $contract.ProtectedTextureSha256.PSObject.Properties){
        $sprite=Join-Path $source $entry.Name
        if(-not(Test-Path -LiteralPath $sprite)){throw "Reviewed ${Species} PNG missing: $($entry.Name)"}
        if((Get-FileHash -LiteralPath $sprite -Algorithm SHA256).Hash -ne $entry.Value){throw "Reviewed ${Species} PNG changed: $($entry.Name)"}
    }
    foreach($relative in $files){
        $output=Join-Path $root $relative
        [void][IO.Directory]::CreateDirectory((Split-Path $output -Parent))
        [IO.File]::WriteAllBytes($output,[IO.File]::ReadAllBytes((Join-Path $source $relative)))
    }
    Write-Host "Copied $($files.Count) reviewed ${Species} display JSONs to restricted draft; PNGs untouched."
}
function Copy-ReviewedItemIcons {
    $source=Join-Path (Split-Path $PSScriptRoot -Parent) 'src/main/resources'
    # Audit every input before writing any output, including retained art and native atlas.
    & (Join-Path $PSScriptRoot 'audit-item-icon-routes.ps1')
    if($LASTEXITCODE -ne 0){throw 'Reviewed icon preflight failed; no icon files copied.'}
    $contract=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'reviewed-item-icon-routes.json') -Raw -Encoding UTF8|ConvertFrom-Json
    foreach($route in $contract.Routes){
        $output=Join-Path $root $route.Path
        [void][IO.Directory]::CreateDirectory((Split-Path $output -Parent))
        [IO.File]::WriteAllBytes($output,[IO.File]::ReadAllBytes((Join-Path $source $route.Path)))
    }
    Write-Host "Copied $($contract.Routes.Count) reviewed item icon JSONs; PNGs and gameplay data untouched."
}
$safeModes=@($BroccoliFormsOnly,$LettuceFormsOnly,$KaleWildFormsOnly,$CauliflowerFormsOnly,$NapaCabbageFormsOnly,$ChiliDisplayOnly,$FenugreekDisplayOnly,$SpinachDisplayOnly,$SunflowerDisplayOnly,$SwissChardDisplayOnly,$CeleryDisplayOnly,$CeltuceDisplayOnly,$RhubarbDisplayOnly,$ItemIconsOnly)|Where-Object{$_}
if(@($safeModes).Count -gt 1){throw 'Select only one species-specific safe mode.'}
if($ItemIconsOnly){Copy-ReviewedItemIcons;exit 0}
if($KaleWildFormsOnly){Copy-ReviewedKaleWildForms;exit 0}

if($BroccoliFormsOnly){Copy-ReviewedCropForms 'broccoli';exit 0}
if($LettuceFormsOnly){Copy-ReviewedCropForms 'lettuce';exit 0}
if($CauliflowerFormsOnly){Copy-ReviewedCropForms 'cauliflower';exit 0}
if($NapaCabbageFormsOnly){Copy-ReviewedCropForms 'napa_cabbage';exit 0}
if($ChiliDisplayOnly){Copy-ReviewedCropDisplay 'chili';exit 0}
if($FenugreekDisplayOnly){Copy-ReviewedCropDisplay 'fenugreek';exit 0}
if($SpinachDisplayOnly){Copy-ReviewedCropDisplay 'spinach';exit 0}
if($SunflowerDisplayOnly){Copy-ReviewedCropDisplay 'sunflower';exit 0}
if($SwissChardDisplayOnly){Copy-ReviewedCropDisplay 'swiss_chard';exit 0}
if($RhubarbDisplayOnly){Copy-ReviewedCropDisplay 'rhubarb';exit 0}
if($CeltuceDisplayOnly){Copy-ReviewedCropDisplay 'celtuce';exit 0}
if($CeleryDisplayOnly){Copy-ReviewedCropDisplay 'celery';exit 0}

# ------------------------------------------------------------
# 作物数据表
#   n=id  zh/en=名称  ref=借用的 TFC crop 贴图  age=最大 age（阶段数-1）
#   t=温度区间  h=水合区间  npk=氮/磷/钾（正=消耗，负=补充）
#   decay=保质期修饰  sat=饱和度  veg=蔬菜营养(可空)  grain=谷物营养(可空)  water=水分(可空)
#   zhNote/enNote=手册里的一句话描述
# ------------------------------------------------------------
$crops = @(
    # ── 已有（批次 2 的 8 种叶菜，数值已对齐 TFC 同类作物）──
    [ordered]@{ n='spinach'; zh='菠菜'; en='Spinach'; ref='beet'; age=5; tMin=-12; tMax=25; hMin=10; hMax=70; npk='0.7/-0.2/-0.2'; decay=1.2; sat=1.0; veg=2.0; grain=$null; water=$null; zhNote='最耐寒的叶菜之一，霜降前都还能长。'; enNote='One of the hardiest greens, still growing until the first hard frost.' }
    [ordered]@{ n='lettuce'; zh='生菜'; en='Lettuce'; ref='onion'; age=5; tMin=-6; tMax=24; hMin=15; hMax=75; npk='0.6/-0.2/-0.2'; decay=1.5; sat=1.0; veg=1.5; grain=$null; water=5.0; zhNote='含水量很高，同时补充水分与蔬菜营养。'; enNote='Very watery, topping up both hunger and thirst.' }
    [ordered]@{ n='celery'; zh='芹菜'; en='Celery'; ref='onion'; age=5; tMin=-5; tMax=24; hMin=20; hMax=85; npk='0.7/0.3/0.4'; decay=1.0; sat=1.0; veg=1.5; grain=$null; water=5.0; zhNote='耗水较多，茎秆清脆多汁。'; enNote='Thirsty, with crisp and juicy stalks.' }
    [ordered]@{ n='kale'; zh='羽衣甘蓝'; en='Kale'; ref='cabbage'; rosette=$true; age=5; tMin=-20; tMax=18; hMin=10; hMax=70; npk='0.7/0.2/0.3'; decay=1.2; sat=1.0; veg=2.0; grain=$null; water=$null; zhNote='能扛 -20 °C，是寒带农场最可靠的蔬菜。'; enNote='Survives -20 °C, the most reliable vegetable of the far north.' }
    [ordered]@{ n='napa_cabbage'; zh='白菜'; en='Napa Cabbage'; ref='cabbage'; age=5; tMin=-8; tMax=24; hMin=10; hMax=70; npk='0.7/0.2/0.4'; decay=1.2; sat=1.0; veg=2.0; grain=$null; water=$null; zhNote='与卷心菜同级的当家菜。'; enNote='A staple on par with TFC cabbage.' }
    [ordered]@{ n='mustard_greens'; zh='芥菜'; en='Mustard Greens'; ref='beet'; age=5; tMin=-5; tMax=25; hMin=15; hMax=75; npk='0.3/0.25/0.35'; decay=1.5; sat=0.5; veg=1.5; grain=$null; water=$null; zhNote='带辛辣味，略耐热。'; enNote='Peppery and a little more heat-tolerant.' }
    [ordered]@{ n='broccoli'; zh='西兰花'; en='Broccoli'; ref='cabbage'; age=5; tMin=-5; tMax=22; hMin=15; hMax=80; npk='0.8/0.3/0.4'; decay=1.5; sat=1.0; veg=1.75; grain=$null; water=$null; zhNote='产量与营养俱佳的温带蔬菜。'; enNote='A temperate vegetable with good yield and nutrition.' }
    [ordered]@{ n='cauliflower'; zh='花菜'; en='Cauliflower'; ref='cabbage'; age=5; tMin=-4; tMax=23; hMin=15; hMax=80; npk='0.8/0.3/0.4'; decay=1.5; sat=1.0; veg=1.75; grain=$null; water=$null; zhNote='与西兰花同源，更喜凉爽湿润。'; enNote="Broccoli's close relative, preferring cooler and damper weather." }
    # ── 批次 3 新增：蔬菜 / 块根（14 种）──
    [ordered]@{ n='brussels_sprouts'; zh='芽甘蓝'; en='Brussels Sprouts'; ref='onion'; age=6; tMin=-6; tMax=22; hMin=45; hMax=85; npk='0.8/0.3/0.4'; decay=0.6; sat=1.0; veg=2.0; grain=$null; water=$null; zhNote='茎上结满小球，耐寒，冬前采收最甜。'; enNote='Little cabbages along a tall stem; frost sweetens them.' }
    [ordered]@{ n='swiss_chard'; zh='牛皮菜'; en='Swiss Chard'; ref='beet'; age=5; tMin=-5; tMax=26; hMin=40; hMax=80; npk='0.6/0.2/0.4'; decay=4.0; sat=1.0; veg=2.0; grain=$null; water=3.0; zhNote='叶柄肥厚、叶片宽大；成熟后破坏整株收获，之后需要重新播种。'; enNote='Thick stalks and broad leaves; break the mature plant to harvest, then sow seeds again.' }
    [ordered]@{ n='celtuce'; zh='莴笋'; en='Celtuce'; ref='onion'; age=5; tMin=5; tMax=24; hMin=50; hMax=90; npk='0.6/-0.2/-0.2'; decay=3.5; sat=1.0; veg=1.5; grain=$null; water=4.0; zhNote='茎秆脆嫩，可炒可腌。'; enNote='A crisp stem vegetable, good stir-fried or pickled.' }
    [ordered]@{ n='garland_chrysanthemum'; zh='茼蒿'; en='Garland Chrysanthemum'; ref='beet'; age=5; tMin=5; tMax=26; hMin=50; hMax=90; npk='0.6/-0.2/-0.2'; decay=4.0; sat=0.5; veg=1.6; grain=$null; water=$null; zhNote='气味独特的速生叶菜，涮锅首选。'; enNote='A fast, aromatic green, a favourite for hotpot.' }
    [ordered]@{ n='perilla'; zh='紫苏'; en='Perilla'; ref='beet'; age=5; tMin=12; tMax=32; hMin=45; hMax=85; npk='0.6/-0.2/-0.2'; decay=3.5; sat=0.5; veg=1.2; grain=$null; water=$null; zhNote='喜温，叶片带特殊香气。'; enNote='Heat-loving, with strongly aromatic leaves.' }
    [ordered]@{ n='arugula'; zh='芝麻菜'; en='Arugula'; ref='beet'; age=5; tMin=-5; tMax=26; hMin=45; hMax=85; npk='0.5/-0.2/-0.2'; decay=4.0; sat=0.5; veg=1.3; grain=$null; water=$null; zhNote='带辛辣芝麻香，生长极快。'; enNote='Peppery and nutty; one of the fastest greens to grow.' }
    [ordered]@{ n='turnip'; zh='芜菁'; en='Turnip'; ref='beet'; age=5; tMin=-12; tMax=20; hMin=20; hMax=70; npk='0.3/0.3/0.4'; decay=0.4; sat=2.0; veg=1.2; grain=$null; water=$null; zhNote='耐寒的根菜，地窖里能放很久。'; enNote='A hardy root vegetable that keeps well in a cellar.' }
    [ordered]@{ n='parsnip'; zh='防风'; en='Parsnip'; ref='beet'; age=5; tMin=-10; tMax=22; hMin=25; hMax=75; npk='0.4/0.25/0.5'; decay=0.4; sat=2.0; veg=1.5; grain=$null; water=$null; zhNote='霜打之后更甜的白色根菜。'; enNote='A white root that turns sweet after a frost.' }
    [ordered]@{ n='sunchoke'; zh='洋姜'; en='Sunchoke'; ref='potato'; age=5; double=$true; singleAge=3; tMin=-12; tMax=24; hMin=20; hMax=70; npk='0.3/0.2/0.6'; decay=0.35; sat=0.5; veg=1.0; grain=0.3; water=$null; zhNote='地下块茎，产量极高且极耐寒。'; enNote='A prolific, very hardy tuber.' }
    [ordered]@{ n='shallot'; zh='红葱'; en='Shallot'; ref='onion'; age=5; tMin=0; tMax=26; hMin=15; hMax=65; npk='0.35/0.3/0.45'; decay=0.4; sat=1.0; veg=2.0; grain=$null; water=$null; zhNote='香味细腻的小葱头，耐储存。'; enNote='A fine-flavoured small onion that stores well.' }
    [ordered]@{ n='celeriac'; zh='根芹'; en='Celeriac'; ref='beet'; age=5; tMin=5; tMax=24; hMin=45; hMax=85; npk='0.6/0.3/0.5'; decay=0.5; sat=1.0; veg=1.3; grain=$null; water=$null; zhNote='芹菜的地下版本，球茎可炖可泥。'; enNote="Celery's underground cousin; the bulb is good mashed or stewed." }
    [ordered]@{ n='salsify'; zh='鸦葱'; en='Salsify'; ref='beet'; age=5; tMin=-10; tMax=24; hMin=25; hMax=75; npk='0.4/0.3/0.5'; decay=0.4; sat=1.0; veg=1.4; grain=$null; water=$null; zhNote='细长白根，煮熟有牡蛎般的鲜味。'; enNote='A long white root with a faint oyster-like savour.' }
    # ── 香料类根茎（批次 13）── 姜科，喜温；作为蔬菜营养接入 TFC 食物体系（TFC 没有单独的香料机制）
    [ordered]@{ n='ginger'; zh='生姜'; en='Ginger'; ref='beet'; age=5; tMin=20; tMax=35; hMin=40; hMax=85; npk='0.5/0.3/0.6'; decay=0.4; sat=1.0; veg=1.2; grain=$null; water=$null; zhNote='喜温的辛香根茎，晒干后能存很久。'; enNote='A warm-climate pungent rhizome that keeps well once dried.' }
    [ordered]@{ n='turmeric'; zh='姜黄'; en='Turmeric'; ref='beet'; age=5; tMin=22; tMax=38; hMin=45; hMax=90; npk='0.5/0.25/0.6'; decay=0.4; sat=1.0; veg=1.3; grain=$null; water=$null; zhNote='比生姜更怕冷，根茎切开是明亮的橙黄色。'; enNote='Less cold-hardy than ginger, with a bright orange rhizome.' }
    [ordered]@{ n='yacon'; zh='雪莲果'; en='Yacón'; ref='potato'; age=5; tMin=8; tMax=28; hMin=30; hMax=75; npk='0.35/0.3/0.5'; decay=0.5; sat=0.5; veg=1.2; grain=$null; water=5.0; zhNote='块根清甜多汁，可当水果吃。'; enNote='A sweet, juicy tuber that can be eaten like fruit.' }
    [ordered]@{ n='chicory_root'; zh='菊苣'; en='Chicory Root'; ref='beet'; age=5; tMin=-8; tMax=26; hMin=30; hMax=75; npk='0.4/0.2/0.5'; decay=0.4; sat=0.5; veg=1.1; grain=$null; water=$null; zhNote='根可烘焙代咖啡，叶可作沙拉。'; enNote='The root can be roasted as a coffee substitute.' }
    # ── 批次 3 新增：谷物（12 种）──
    #    ⚠️ TFC 的谷物本身【不给营养】（要吃它得先磨粉→和面→烤面包），
    #       我们没有那套加工链，因此这里直接给 grain 营养（数值对齐 TFC 的面包 1.2~1.5，略低）。
    #    ref 只借用 TFC 有 food/seeds 贴图的 5 种谷物（wheat/rye/barley/oat/rice）。
    #    ⚠️ 不能用 maize（玉米）：TFC 的玉米是【双格高秆作物】，贴图叫 maize_bottom_*/maize_top_*，
    #       既没有 maize_0..7 也没有 maize_dead / maize_wild，借用会在游戏里报贴图缺失（已实测）。
    [ordered]@{ n='millet'; zh='黍'; en='Millet'; ref='barley'; age=7; double=$true; singleAge=4; dblRef='sugarcane'; tMin=-7; tMax=23; hMin=10; hMax=70; npk='0.7/-0.2/-0.2'; decay=2.0; sat=1.0; veg=$null; grain=1.0; water=$null; zhNote='耐旱耐贫瘠，最早熟的谷物之一，古时北方的主粮。'; enNote='Drought hardy and quick to ripen; a staple grain of the dry north.' }
    [ordered]@{ n='foxtail_millet'; zh='谷子'; en='Foxtail Millet'; ref='wheat'; age=7; double=$true; singleAge=4; dblRef='sugarcane'; tMin=-7; tMax=22; hMin=15; hMax=85; npk='0.7/-0.2/-0.2'; decay=2.0; sat=1.0; veg=$null; grain=1.2; water=$null; zhNote='脱壳就是小米，熬粥最香，耐储存。'; enNote='Hulled it becomes millet; it keeps very well.' }
    [ordered]@{ n='buckwheat'; zh='荞麦'; en='Buckwheat'; ref='rye'; age=7; tMin=-2; tMax=25; hMin=25; hMax=90; npk='0.6/0.2/0.3'; decay=1.8; sat=1.0; veg=$null; grain=1.2; water=$null; zhNote='生长期短，贫地也能收，磨粉做面食。'; enNote='Short seasoned and tolerant of poor soil.' }
    [ordered]@{ n='fonio'; zh='福尼奥米'; en='Fonio'; ref='rice'; age=7; tMin=11; tMax=31; hMin=20; hMax=80; npk='0.6/-0.2/-0.2'; decay=2.0; sat=1.0; veg=$null; grain=1.0; water=$null; zhNote='西非的古老谷物，极耐旱，六十天就能收。'; enNote='An ancient West African grain, extremely drought tolerant.' }
    [ordered]@{ n='spelt'; zh='斯佩耳特麦'; en='Spelt'; ref='wheat'; age=7; double=$true; singleAge=4; dblRef='sugarcane'; tMin=-7; tMax=22; hMin=15; hMax=85; npk='0.7/0.1/0.3'; decay=2.0; sat=1.0; veg=$null; grain=1.5; water=$null; zhNote='古老的小麦近亲，壳硬难脱，但麦香浓郁。'; enNote='An old wheat relative with a tough husk and rich flavour.' }
    [ordered]@{ n='emmer'; zh='二粒麦'; en='Emmer'; ref='wheat'; age=7; double=$true; singleAge=4; dblRef='sugarcane'; tMin=-7; tMax=22; hMin=15; hMax=85; npk='0.7/0.1/0.3'; decay=2.0; sat=1.0; veg=$null; grain=1.5; water=$null; zhNote='新月沃地最早的栽培小麦之一，今天做意大利面仍用它。'; enNote='One of the first wheats ever farmed.' }
    [ordered]@{ n='einkorn'; zh='单粒麦'; en='Einkorn'; ref='barley'; age=7; tMin=-7; tMax=20; hMin=10; hMax=70; npk='0.6/0.1/0.3'; decay=2.0; sat=1.0; veg=$null; grain=1.3; water=$null; zhNote='最古老的小麦，穗小粒少，却极耐瘠薄。'; enNote='The oldest wheat of all; small ears, but very hardy.' }
    [ordered]@{ n='pearl_millet'; zh='珍珠粟'; en='Pearl Millet'; ref='rye'; age=7; double=$true; singleAge=4; dblRef='sugarcane'; tMin=11; tMax=31; hMin=20; hMax=80; npk='0.7/-0.2/-0.2'; decay=2.0; sat=1.0; veg=$null; grain=1.2; water=$null; zhNote='萨赫勒地区的耐热主粮，穗大粒圆。'; enNote='A heat loving staple of the Sahel, with heavy round grain.' }
    [ordered]@{ n='amaranth'; zh='苋米'; en='Amaranth'; ref='oat'; age=7; double=$true; singleAge=4; dblRef='sugarcane'; tMin=5; tMax=30; hMin=20; hMax=80; npk='0.6/0.2/0.3'; decay=1.5; sat=1.0; veg=$null; grain=1.4; water=$null; zhNote='籽粒极小的伪谷物，穗子像火把一样红。'; enNote='A tiny seeded pseudo cereal with torch red plumes.' }
    [ordered]@{ n='quinoa'; zh='藜麦'; en='Quinoa'; ref='oat'; age=7; double=$true; singleAge=4; dblRef='sugarcane'; tMin=-5; tMax=20; hMin=15; hMax=70; npk='0.6/0.2/0.3'; decay=2.0; sat=1.0; veg=$null; grain=1.5; water=$null; zhNote='高原谷物，耐霜耐旱，籽粒营养很全面。'; enNote='A highland grain that shrugs off frost and drought.' }
    [ordered]@{ n='finger_millet'; zh='穇子'; en='Finger Millet'; ref='rice'; age=7; tMin=8; tMax=31; hMin=25; hMax=85; npk='0.6/-0.2/-0.2'; decay=2.0; sat=1.0; veg=$null; grain=1.0; water=$null; zhNote='穗像手指一样张开，耐储存，可酿酒。'; enNote='Its seed head spreads like fingers; stores very well.' }
    [ordered]@{ n='jobs_tears'; zh='薏苡'; en='Job''s Tears'; ref='rice'; age=7; double=$true; singleAge=4; dblRef='sugarcane'; tMin=8; tMax=30; hMin=30; hMax=90; npk='0.7/0.2/0.4'; decay=2.0; sat=1.0; veg=$null; grain=1.3; water=3.0; zhNote='籽粒外包一层硬壳，可煮粥，也可串珠子。'; enNote='Hard shelled grain, eaten in soups or strung as beads.' }
    # ── 批次 3：豆类（6 种）──
    #    ⚠️ 豆类在 TFC 手册里的类别词是「豆类 / Legume」（不是蔬菜）。
    #    营养给 protein + vegetables，数值照 TFC 的 soybean（protein 1.0 + vegetables 0.5）。
    #    ⚠️ NPK 的**氮为负**：豆科根瘤菌固氮，种一季反而会补充土壤里的氮。
    [ordered]@{ n='chickpea'; zh='鹰嘴豆'; en='Chickpea'; ref='soybean'; age=5; tMin=-5; tMax=25; hMin=15; hMax=70; npk='-0.6/0.2/0.3'; decay=2.5; sat=2.0; veg=0.5; grain=$null; protein=1.2; water=$null; zhNote='中东与南亚的当家豆，耐旱，鹰嘴状的小豆粒。'; enNote='A drought tolerant staple of the Middle East and South Asia.' }
    [ordered]@{ n='faba_bean'; zh='蚕豆'; en='Faba Bean'; ref='soybean'; age=5; double=$true; singleAge=3; tMin=-5; tMax=22; hMin=25; hMax=90; npk='-0.7/0.15/0.25'; decay=3.0; sat=2.0; veg=0.5; grain=$null; protein=1.2; water=$null; zhNote='豆粒肥大，最耐寒的豆类之一，秋播也能越冬。'; enNote='Big flat beans and one of the hardiest legumes.' }
    [ordered]@{ n='lupin'; zh='羽扇豆'; en='Lupin'; ref='soybean'; age=5; tMin=-5; tMax=25; hMin=20; hMax=80; npk='-0.5/0.15/0.2'; decay=2.5; sat=2.0; veg=0.3; grain=$null; protein=1.5; water=$null; zhNote='蛋白含量数一数二，花穗像烛台一样立着。'; enNote='Very high in protein, with candle like flower spikes.' }
    [ordered]@{ n='adzuki'; zh='红小豆'; en='Adzuki Bean'; ref='soybean'; age=5; tMin=5; tMax=28; hMin=25; hMax=85; npk='-0.6/0.2/0.3'; decay=3.0; sat=2.0; veg=0.5; grain=$null; protein=1.2; water=$null; zhNote='东亚的红皮小豆，煮豆沙最香。'; enNote='The small red bean of East Asia, the classic filling for sweet pastes.' }
    [ordered]@{ n='bambara_nut'; zh='班巴拉豆'; en='Bambara Nut'; ref='peanut'; age=5; tMin=11; tMax=31; hMin=20; hMax=80; npk='-0.6/0.15/0.25'; decay=3.0; sat=2.0; veg=0.5; grain=$null; protein=1.5; water=$null; zhNote='非洲的地下结荚豆，耐旱又顶饱。'; enNote='An African legume that pods underground; drought hardy and filling.' }
    [ordered]@{ n='fenugreek'; zh='胡卢巴'; en='Fenugreek'; ref='lentil'; age=5; tMin=-5; tMax=25; hMin=15; hMax=60; npk='-0.7/0.2/0.3'; decay=2.5; sat=2.0; veg=0.8; grain=$null; protein=1.0; water=$null; zhNote='籽与嫩叶都能吃，带一股焦糖似的香气。'; enNote='Both the seeds and the greens are eaten, with a maple like aroma.' }

    # ── 批次 3：油料 / 纤维（4 种）—— 类别照 TFC：油菜是「覆盖作物」、黄麻是「杂项」──
    #    ⚠️ 亚麻/苎麻的产物是纤维（自家非食物物品），没有可食用的籽；见 docs §5.19。
    [ordered]@{ n='flax'; zh='亚麻'; en='Flax'; ref='canola'; prod='fiber/flax'; zhProd='亚麻纤维'; enProd='Flax Fibre'; prodTex='tfc:item/jute_fiber'; age=5; tMin=-7; tMax=22; hMin=20; hMax=75; npk='0.6/0.2/0.3'; decay=1.5; sat=1.0; veg=$null; grain=0.8; protein=$null; water=$null; zhNote='茎皮纤维坚韧，可织亚麻布'; enNote='its bast fibre is woven into linen' }
    [ordered]@{ n='sesame'; zh='芝麻'; en='Sesame'; ref='canola'; prodTex='tfc:item/canola'; age=5; tMin=11; tMax=31; hMin=20; hMax=75; npk='0.6/0.2/0.3'; decay=1.2; sat=1.0; veg=$null; grain=0.9; protein=$null; water=$null; zhNote='籽粒极小，香气浓，怕冷'; enNote='tiny aromatic seeds; it hates the cold' }
    [ordered]@{ n='safflower'; zh='红花'; en='Safflower'; ref='canola'; prodTex='tfc:item/canola'; age=5; tMin=5; tMax=30; hMin=15; hMax=70; npk='0.6/0.2/0.3'; decay=1.5; sat=1.0; veg=$null; grain=0.8; protein=$null; water=$null; zhNote='花可作红色染料，籽可榨油，耐旱'; enNote='a red dye from the flowers, oil from the seed' }
    [ordered]@{ n='ramie'; zh='苎麻'; en='Ramie'; ref='canola'; prod='fiber/ramie'; zhProd='苎麻纤维'; enProd='Ramie Fibre'; prodTex='tfc:item/jute_fiber'; age=5; double=$true; singleAge=3; tMin=2; tMax=25; hMin=15; hMax=90; npk='0.5/0.2/0.4'; decay=1.0; sat=1.0; veg=$null; grain=$null; protein=$null; water=$null; zhNote='茎皮纤维坚韧，可织夏布'; enNote='a tough bast fibre, woven into summer cloth' }

    # ── 批次 4：多年生可采摘蔬菜（7 种）· Java 侧用 MyPickableCropBlock ──
    #    「多年生」由采摘退回状态实现（芦笋/韭菜/大黄/洋蓟等），气候合适就会继续长。
    #    ⚠️ 棉花是**一年生**：成熟后连秆收割、只收一茬，走普通作物 CropBlock，
    #       所以这一行不带 pickable 标记；产物棉铃由掉落表给出。
    [ordered]@{ n='chili'; zh='辣椒'; en='Chili'; ref='rice'; pickable=$true; age=5; tMin=12; tMax=36; hMin=25; hMax=80; npk='0.3/0.4/0.5'; decay=2.5; sat=2.0; veg=1.5; grain=$null; protein=$null; water=$null; zhNote='越热越辣，红透后更香'; enNote='the hotter the summer, the fiercer the fruit' }
    [ordered]@{ n='eggplant'; zh='茄子'; en='Eggplant'; ref='wheat'; pickable=$true; age=5; tMin=14; tMax=36; hMin=30; hMax=85; npk='0.35/0.4/0.5'; decay=3.0; sat=2.0; veg=1.8; grain=$null; protein=$null; water=$null; zhNote='喜高温，果皮紫亮，烤着吃最香'; enNote='heat loving, with glossy purple skin' }
    [ordered]@{ n='okra'; zh='秋葵'; en='Okra'; ref='oat'; pickable=$true; age=5; tMin=16; tMax=38; hMin=25; hMax=70; npk='0.4/0.35/0.5'; decay=3.5; sat=2.0; veg=1.6; grain=$null; protein=$null; water=3.0; zhNote='嫩荚多汁，切开有黏液'; enNote='tender juicy pods' }
    [ordered]@{ n='cotton'; zh='棉花'; en='Cotton'; ref='canola'; prod='cotton_boll'; zhProd='棉铃'; enProd='Cotton Boll'; prodTex='tfc:item/wool_yarn'; age=5; double=$true; singleAge=3; tMin=15; tMax=38; hMin=30; hMax=80; npk='0.6/0.3/-0.3'; decay=0.3; sat=1.0; veg=$null; grain=$null; protein=$null; water=$null; zhNote='采收棉铃可得纤维，织布纺线都靠它'; enNote='the bolls give the fibre; spin it into yarn' }
    [ordered]@{ n='asparagus'; zh='芦笋'; en='Asparagus'; ref='barley'; pickable=$true; age=5; tMin=-8; tMax=28; hMin=40; hMax=80; npk='0.6/0.3/0.4'; decay=4.0; sat=2.0; veg=1.5; grain=$null; protein=$null; water=$null; zhNote='嫩茎割了还会再长，能连收好几年'; enNote='cut the shoots and they keep coming back for years' }
    [ordered]@{ n='chive'; zh='韭菜'; en='Chive'; ref='rye'; pickable=$true; age=5; tMin=-10; tMax=26; hMin=40; hMax=80; npk='0.6/-0.2/-0.2'; decay=4.5; sat=2.0; veg=1.6; grain=$null; protein=$null; water=$null; zhNote='割一茬长一茬，最省心的多年生'; enNote='cut and come again, the easiest perennial' }
    [ordered]@{ n='rhubarb'; zh='大黄'; en='Rhubarb'; ref='soybean'; pickable=$true; age=5; tMin=-12; tMax=24; hMin=45; hMax=85; npk='0.5/0.2/0.3'; decay=4.0; sat=2.0; veg=1.0; grain=$null; protein=$null; water=$null; zhNote='叶柄可直接食用或用于原生汤、沙拉和三明治；使用未腐烂原料。'; enNote='Eat the stalks or use them in native soup, salads and sandwiches; use unrotten ingredients.' }
    [ordered]@{ n='artichoke'; zh='洋蓟'; en='Artichoke'; ref='lentil'; pickable=$true; age=5; tMin=5; tMax=26; hMin=40; hMax=80; npk='0.7/0.3/0.5'; decay=3.5; sat=2.0; veg=1.4; grain=$null; protein=$null; water=$null; zhNote='吃的是花苞，剥到芯才见嫩'; enNote='you eat the flower buds, down to the heart' },
    # ── 批次 5：水田作物（10 种）· Java 侧用 MyFloodedCropBlock（含水方块）──
    #    贴图统一借 TFC 的 rice（8 阶段 age 0~7，正好覆盖本批 6~8 阶段）。
    #    ⚠️ 莲藕在设定上有两个产物（藕 + 莲子），本轮先只给 lotus_root，双产物留到产物体系深化时做。
    [ordered]@{ n='taro';           zh='芋头';   en='Taro';           ref='rice'; flooded=$true; age=6; tMin=16; tMax=38; hMin=45; hMax=100; npk='0.45/0.35/0.6';  decay=3.0; sat=1.0; veg=$null;  grain=0.5; protein=$null; water=$null; zhNote='水田里的淀粉块茎，煮熟后绵软'; enNote='a starchy tuber grown in paddies' }
    [ordered]@{ n='water_chestnut'; zh='荸荠';   en='Water Chestnut'; ref='rice'; flooded=$true; age=5; tMin=14; tMax=34; hMin=60; hMax=100; npk='0.4/0.3/0.6';      decay=3.5; sat=1.0; veg=1.2;   grain=$null; protein=$null; water=$null; zhNote='球茎脆甜，生吃炒菜都行'; enNote='a crisp, sweet corm' }
    [ordered]@{ n='water_caltrop';  zh='菱角';   en='Water Caltrop';  ref='rice'; flooded=$true; age=5; tMin=15; tMax=35; hMin=70; hMax=100; npk='0.35/0.3/0.55';  decay=3.0; sat=1.0; veg=0.6;   grain=0.4; protein=$null; water=$null; zhNote='两角尖尖的坚果，煮粉了最好吃'; enNote='a two horned nut, best boiled soft' }
    [ordered]@{ n='wild_rice_stem'; zh='茭白';   en='Wild Rice Stem'; ref='rice'; flooded=$true; age=5; tMin=12; tMax=32; hMin=65; hMax=100; npk='0.5/0.3/0.5';     decay=2.0; sat=1.0; veg=1.5;   grain=$null; protein=$null; water=3.0;   zhNote='被菌感染后膨大的嫩茎，鲜嫩多汁'; enNote='the swollen shoot, tender and juicy' }
    [ordered]@{ n='lotus';          zh='莲藕';   en='Lotus';          ref='rice'; flooded=$true; age=7; tMin=16; tMax=38; hMin=70; hMax=100; npk='0.45/0.35/0.6';  decay=3.0; sat=1.0; veg=1.3;   grain=$null; protein=$null; water=$null; zhNote='淤泥里的藕节，切开满是孔洞'; enNote='a rhizome riddled with air channels' }
    [ordered]@{ n='water_dropwort'; zh='水芹';   en='Water Dropwort'; ref='rice'; flooded=$true; age=5; tMin=5;  tMax=25; hMin=70; hMax=100; npk='0.5/0.3/0.4';     decay=1.5; sat=1.0; veg=1.8;   grain=$null; protein=$null; water=4.0;   zhNote='水边丛生的香芹，越冷越嫩'; enNote='a fragrant celery relative that prefers the cold' }
    [ordered]@{ n='water_spinach';  zh='空心菜'; en='Water Spinach';  ref='rice'; flooded=$true; age=5; tMin=18; tMax=38; hMin=65; hMax=100; npk='0.8/-0.2/-0.2';  decay=1.2; sat=1.0; veg=2.0;   grain=$null; protein=$null; water=4.0;   zhNote='茎中空的速生叶菜，割了又发'; enNote='a fast hollow stemmed green' }
    [ordered]@{ n='arrowhead';      zh='慈菇';   en='Arrowhead';      ref='rice'; flooded=$true; age=5; tMin=14; tMax=34; hMin=60; hMax=100; npk='0.45/0.35/0.55'; decay=3.5; sat=1.0; veg=0.8;   grain=0.4; protein=$null; water=$null; zhNote='带尖芽的球茎，微苦回甘'; enNote='a beaked tuber with a bitter edge' }
    [ordered]@{ n='gorgon_nut';     zh='芡实';   en='Gorgon Nut';     ref='rice'; flooded=$true; age=5; tMin=16; tMax=36; hMin=70; hMax=100; npk='0.4/0.3/0.55';   decay=5.0; sat=1.0; veg=$null;  grain=0.7; protein=$null; water=$null; zhNote='满身尖刺的睡莲籽，晒干能放很久'; enNote='the spiny seed of a water lily, keeps very well' }
    # ── 批次 6：瓜类（蔓延型·产物挂在结果方块上）──
    #    prod 指向**结果方块物品**（整瓜），所以藤成熟时掉的是整瓜而不是可食切片；
    #    整瓜再掉切片（见生成器的 [7b] 分支）。贴图借 TFC 的 melon（西瓜，同为瓜类外形）。
    [ordered]@{ n='winter_melon'; zh='冬瓜'; en='Winter Melon'; ref='melon'; spread=$true; simRef='melon'; fruitRef='minecraft:block/melon'; rottenRef='minecraft:block/melon'; prod='winter_melon'; prodTex='minecraft:item/melon'; age=6; tMin=15; tMax=35; hMin=40; hMax=90; npk='0.5/0.35/0.55'; decay=0.3; sat=1.5; veg=$null; grain=$null; protein=$null; water=6.0; zhNote='表皮挂霜的大瓜，能存到冬天'; enNote='a big frosted gourd that keeps into winter' }
    # 佛手瓜是**攀爬型**：要插木棍才能爬。它现实只有 10~15cm，**不做整瓜方块** ——
    # 走普通作物的形态：产物就是可食的整个瓜（food/chayote），丢弃了结果方块与腐烂那一套。
    # ── 批次 7：攀爬作物（6 种）· 全部走 MyClimbingCropBlock（需木棍）──
    #    ⚠️ 计划表写的是「攀爬 6+6」，但 TFC 的攀爬贴图（tomato 那套）只有 age 0~7 共 8 个阶段，
    #       所以统一采用与 TFC 番茄相同的 **4+4** 切分（singleAge=4 / maxAge=7）。
    [ordered]@{ n='hops';             zh='啤酒花'; en='Hops';             ref='tomato'; climb=$true; simRef='tomato'; prod='hops'; prodTex='tfc:item/food/barley'; age=7; singleAge=4; tMin=6;  tMax=24; hMin=40; hMax=85; npk='0.9/0.2/-0.3'; decay=4.0; sat=1.0; veg=$null; grain=$null; protein=$null; water=$null; zhNote='雌花酿啤酒，苦香扑鼻'; enNote='the cones that bitter a beer' }
    [ordered]@{ n='loofah';          zh='丝瓜';   en='Loofah';          ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=15; tMax=36; hMin=40; hMax=85; npk='0.45/0.3/0.5'; decay=2.0; sat=1.0; veg=1.4;   grain=$null; protein=$null; water=4.0;   zhNote='嫩时做汤，老了只剩一团纤维'; enNote='tender in soup, nothing but fibre when old' }
    [ordered]@{ n='bitter_melon';    zh='苦瓜';   en='Bitter Melon';    ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=16; tMax=38; hMin=35; hMax=80; npk='0.4/0.35/0.5';  decay=2.5; sat=1.0; veg=1.3;   grain=$null; protein=$null; water=4.0;   zhNote='苦味来自瓜肉，越熟越苦'; enNote='the bitterness is in the flesh, stronger as it ripens' }
    [ordered]@{ n='snake_gourd';     zh='蛇瓜';   en='Snake Gourd';     ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=18; tMax=38; hMin=40; hMax=85; npk='0.4/0.35/0.5';  decay=2.0; sat=1.0; veg=1.3;   grain=$null; protein=$null; water=4.5;   zhNote='能垂到两米长的细长瓜'; enNote='a gourd that hangs two meters long' }
    [ordered]@{ n='yam';             zh='山药';   en='Yam';             ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=15; tMax=36; hMin=40; hMax=85; npk='0.5/0.3/0.6';   decay=4.0; sat=1.5; veg=1.2;   grain=$null; protein=$null; water=$null; zhNote='地下长条块茎，削皮手会痒'; enNote='a long underground tuber' }
    [ordered]@{ n='malabar_spinach'; zh='木耳菜'; en='Malabar Spinach'; ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=18; tMax=38; hMin=45; hMax=90; npk='0.7/-0.2/-0.2'; decay=1.2; sat=1.0; veg=1.8;   grain=$null; protein=$null; water=3.0;   zhNote='叶片肥厚发黏，越热越旺'; enNote='thick, mucilaginous leaves that love the heat' }
    [ordered]@{ n='chayote'; zh='佛手瓜'; en='Chayote'; ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=15; tMax=34; hMin=40; hMax=90; npk='0.4/0.35/0.5'; decay=2.5; sat=1.5; veg=1.5; grain=$null; protein=$null; water=4.0; zhNote='爬满架子才结瓜，一株能收一夏'; enNote='climbs a trellis and fruits all summer' }
    [ordered]@{ n='bottle_gourd'; zh='瓠瓜'; en='Bottle Gourd'; ref='melon'; spread=$true; simRef='melon'; fruitRef='minecraft:block/melon'; rottenRef='minecraft:block/melon'; prod='bottle_gourd'; prodTex='minecraft:item/melon'; age=5; tMin=15; tMax=36; hMin=35; hMax=85; npk='0.4/0.3/0.5'; decay=0.5; sat=1.5; veg=$null; grain=$null; protein=$null; water=5.0; zhNote='嫩时做菜，老了当水瓢'; enNote='eaten young, dried into a ladle when old' }
    [ordered]@{ n='cantaloupe'; zh='哈密瓜'; en='Cantaloupe'; ref='melon'; spread=$true; simRef='melon'; fruitRef='minecraft:block/melon'; rottenRef='minecraft:block/melon'; prod='cantaloupe'; prodTex='minecraft:item/melon'; age=5; tMin=18; tMax=38; hMin=30; hMax=80; npk='0.4/0.35/0.55'; decay=0.5; sat=1.5; veg=$null; grain=$null; protein=$null; water=5.0; zhNote='网纹瓜皮，切开满是甜汁'; enNote='netted skin, sweet juicy flesh' }
    [ordered]@{ n='water_shield';   zh='莼菜';   en='Water Shield';   ref='rice'; flooded=$true; age=5; tMin=10; tMax=30; hMin=80; hMax=100; npk='0.4/0.2/0.3';    decay=1.0; sat=1.0; veg=1.0;   grain=$null; protein=$null; water=5.0;   zhNote='裹着透明胶质的嫩叶，最娇气'; enNote='tender leaves in a clear jelly' }
    # ── 批次 12：莲座类 3 种（第 7 种作物形状）──
    #    选种过程见 §33.2：设计注释里的首选 pineapple（菠萝）**已被 Firmalife 占用**，
    #    三方对照（TFC / Firmalife / afc）后改用下面三种 —— 都是真实存在的「莲座叶丛」植物，
    #    而且中心能抽出可收的部分，正好对应 FRUITING 状态。
    #    ⚠️ ref 用 beet：TFC 没有莲座形态的贴图，只能借单格作物的 6 个阶段做占位；
    #       真正的形态差异由 RosetteCropBlock 的两个状态 + localize 后的自有贴图体现。
    [ordered]@{ n='cardoon';  zh='刺菜蓟'; en='Cardoon';  ref='beet'; rosette=$true; age=5; tMin=-5; tMax=28; hMin=30; hMax=75; npk='0.6/0.3/0.5';  decay=1.0; sat=1.0; veg=1.5; grain=$null; protein=$null; water=$null; zhNote='叶丛贴地轮生，中心抽出肥嫩的花苞——朝鲜蓟的近亲。'; enNote='A ground-hugging rosette whose heart sends up a tender bud; the artichoke''s close cousin.' }
    [ordered]@{ n='agave';    zh='龙舌兰'; en='Agave';    ref='beet'; rosette=$true; age=5; tMin=12; tMax=40; hMin=5;  hMax=45; npk='0.3/0.2/0.5';  decay=0.3; sat=1.5; veg=1.0; grain=$null; protein=$null; water=3.0;   zhNote='食材是龙舌兰心，侧芽用于播种。当前没有专属烤制或榨汁配方。'; enNote='The harvested food is the agave heart; sidebuds are for planting. No dedicated roasting or juice recipe is connected.' }
    [ordered]@{ n='purslane'; zh='马齿苋'; en='Purslane'; ref='beet'; rosette=$true; age=5; tMin=10; tMax=38; hMin=20; hMax=70; npk='0.4/0.2/0.3';  decay=4.0; sat=0.5; veg=1.5; grain=$null; protein=$null; water=4.0;   zhNote='肉质叶片贴地铺开，越热长得越旺，酸脆多汁。'; enNote='Fleshy leaves spread flat on the ground; thrives in heat, tart and juicy.' }
    # ── 补齐物种缺口（2026-09-26）：豆科攀爬 4 + 木豆 + 向日葵 + 大麻 + 高粱 + 剑麻 ──
    [ordered]@{ n='pea';          zh='豌豆';   en='Pea';          ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=-8; tMax=20; hMin=25; hMax=80; npk='-0.7/0.3/0.3';  decay=1.0; sat=2.0; veg=0.8; grain=$null; protein=1.0; water=$null; zhNote='豆科攀爬作物，根瘤固氮，卷须攀架而上。'; enNote='A climbing legume that fixes nitrogen and twines up a trellis.' }
    [ordered]@{ n='cowpea';       zh='豇豆';   en='Cowpea';       ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=12; tMax=35; hMin=15; hMax=60; npk='-0.8/0.4/0.3';  decay=1.0; sat=2.0; veg=0.5; grain=$null; protein=1.2; water=$null; zhNote='耐热耐旱的攀爬豆，长荚垂挂。'; enNote='A heat-loving climbing bean with long hanging pods.' }
    [ordered]@{ n='common_bean';  zh='菜豆';   en='Common Bean';  ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=10; tMax=30; hMin=30; hMax=80; npk='-0.8/0.4/0.4';  decay=1.0; sat=2.0; veg=0.6; grain=$null; protein=1.2; water=$null; zhNote='最常见的攀爬豆类，荚嫩豆香。'; enNote='The everyday climbing bean.' }
    [ordered]@{ n='winged_bean';  zh='四棱豆'; en='Winged Bean';  ref='tomato'; climb=$true; simRef='tomato'; age=7; singleAge=4; tMin=18; tMax=36; hMin=40; hMax=90; npk='-1.0/0.3/0.4';  decay=1.0; sat=2.0; veg=0.7; grain=$null; protein=1.3; water=$null; zhNote='荚有四条棱翅，热带藤本，全株可食。'; enNote='Pods with four winged edges; a tropical vine, every part edible.' }
    [ordered]@{ n='pigeon_pea';   zh='木豆';   en='Pigeon Pea';   ref='soybean'; age=5; double=$true; singleAge=3; tMin=15; tMax=38; hMin=20; hMax=65; npk='-0.9/0.4/0.4'; decay=1.0; sat=2.0; protein=1.3; veg=$null; grain=$null; water=$null; zhNote='半木质的耐旱豆类，可连年生长。'; enNote='A semi-woody drought-hardy legume.' }
    [ordered]@{ n='sunflower';    zh='向日葵'; en='Sunflower';    ref='barley'; age=5; double=$true; singleAge=3; dblRef='sugarcane'; tMin=5; tMax=30; hMin=20; hMax=70; npk='0.8/-0.3/-0.4'; decay=0.5; sat=1.0; veg=$null; grain=$null; protein=$null; water=$null; zhNote='食用籽可直接食用或用于原生餐食；当前没有专属榨油配方。'; enNote='Eat the food seeds or use them in native meals. Dedicated oil extraction is not connected.' }
    [ordered]@{ n='hemp';         zh='大麻';   en='Hemp';         ref='canola'; prod='fiber/hemp'; zhProd='大麻纤维'; enProd='Hemp Fibre'; prodTex='tfc:item/jute_fiber'; age=5; double=$true; singleAge=3; tMin=2; tMax=28; hMin=25; hMax=80; npk='0.7/-0.3/-0.3'; decay=0.2; sat=1.0; veg=$null; grain=$null; protein=$null; water=$null; zhNote='茎皮纤维最韧，可搓绳织布。'; enNote='The toughest bast fibre; rope and cloth.' }
    [ordered]@{ n='sorghum';      zh='高粱';   en='Sorghum';      ref='barley'; age=5; double=$true; singleAge=3; dblRef='sugarcane'; tMin=12; tMax=34; hMin=10; hMax=60; npk='1.0/-0.3/-0.3'; decay=2.0; sat=1.0; grain=1.2; veg=$null; protein=$null; water=$null; zhNote='耐旱高秆谷物，穗大粒密。'; enNote='A drought-hardy tall grain with a dense head.' }
    [ordered]@{ n='sisal';        zh='剑麻';   en='Sisal';        ref='beet'; rosette=$true; prod='fiber/sisal'; zhProd='剑麻纤维'; enProd='Sisal Fibre'; prodTex='tfc:item/jute_fiber'; age=5; tMin=18; tMax=40; hMin=5; hMax=45; npk='0.4/-0.4/-0.4'; decay=0.2; sat=1.0; veg=$null; grain=$null; protein=$null; water=$null; zhNote='极耐旱的硬叶莲座，叶纤维可制绳索。'; enNote='A drought-proof hard-leaved rosette; its fibre makes rope.' }
    # ── 第 14 步：草莓普通作物（先做一个独立闭环）──
    [ordered]@{ n='strawberry'; zh='草莓'; en='Strawberry'; ref='beet'; prodTex='tfc:item/food/strawberry'; age=5; tMin=5; tMax=28; hMin=35; hMax=85; npk='0.5/0.3/0.4'; decay=2.5; sat=1.2; veg=$null; grain=$null; protein=$null; water=2.0; zhNote='温带草莓作物，成熟后采收鲜果，可进一步干燥。'; enNote='A temperate strawberry crop; harvest the fresh fruit and dry it for storage.' }
)

Write-Host "作物表: $($crops.Count) 种"

$mineableHoe = @(); $cropTag = @(); $snowPiled = @(); $wildItems = @(); $vegItems = @(); $seedItems = @()

# 供其它脚本读取的**作物清单（单一数据源）**。
# ⚠️ 这份名单以前散落在四个脚本里（gen-crops / gen-tags / gen-patchouli-book / polish-book），
#    加一种作物要改四处，漏一处**不报错、只静默少东西** —— §5.34 连续踩了两次：
#    批次 6 的四种瓜从未进任何标签、三种蔓延瓜又漏出 $noFoodCrops 导致 15 条 TagLoader 错误。
#    现在由本脚本的权威表导出，其余脚本一律读它。
$script:manifest = @()

foreach ($c in $crops) {
    $n = $c['n']; $ref = $c['ref']; $age = [int]$c['age']
    # 双格作物：栽培高度常态超过 1 米的（高粱、苋米、珍珠粟、棉花、洋姜…）占上下两格。
    # singleAge = 还能用单格模型表示的最后一个 age + 1（照 TFC 玉米的 3）。
    # 双格阶段的贴图 donor。TFC 里只有 maize / jute / papyrus 的双格贴图是 age 3~5，
    # 与我们的 singleAge=3 对得上；缺省借玉米（禾本科高秆形态最通用），将来换自有美术只改模型。
    $dblRef    = if ($c['dblRef']) { $c['dblRef'] } else { 'maize' }
    # 蔓延型作物（瓜类）：藤向四方向铺开，产物挂在**结果方块**上而不是作物自己身上。
    # 资源侧要多生成：结果方块 + 腐烂变体的 blockstate/模型/掉落表，且作物掉落表**只掉种子**。
    $spread    = [bool]$c['spread']
    # 攀爬型作物（佛手瓜）：需要木棍才能爬，方块状态是 age × stick × part 三维
    $climb     = [bool]$c['climb']
    $flooded   = [bool]$c['flooded']
    # 蔓延藤的贴图 donor（TFC 只有 melon/pumpkin 两套藤蔓贴图），以及整瓜/腐烂瓜借用的模型
    $simRef    = if ($c['simRef']) { $c['simRef'] } else { 'melon' }
    $fruitRef  = if ($c['fruitRef']) { $c['fruitRef'] } else { 'minecraft:block/melon' }
    $rottenRef = if ($c['rottenRef']) { $c['rottenRef'] } else { 'minecraft:block/melon' }
    $double    = [bool]$c['double']
    # 莲座型作物（**本模组的第 7 种作物形状**，由 RosetteCropBlock 实现）：
    # 叶丛贴地、叶片自中心向外轮生，AGE 表示**叶片轮数**（横向规模），
    # 另有一个独立的 FRUITING 状态表示「中心是否已结出果实」。
    # TFC 现有 6 种形态（单格 / 双格 / 水田 / 蔓延 / 攀爬 / 可采摘）全是「线性拔高」，
    # 表达不了菠萝、龙舌兰、马齿苋这类植物。
    $rosette   = [bool]$c['rosette']
    # ⚠️ climb 也要用 singleAge：攀爬作物的 age 切分同样是「前几个单格、之后双格」。
    #    早期只判断 $double，攀爬型拿到 0，于是给 age 0~3 也生成了 _bottom/_top 贴图（TFC 没有这些图）。
    $singleAge = if ($double -or $climb) { [int]$c['singleAge'] } else { 0 }
    # 死株 / 野生的模型 donor。普通作物是 tfc:block/dead_crop/<ref> 与 tfc:block/crop/<ref>_wild；
    # 而攀爬作物（番茄那一套）的死株叫 <ref>_dead_bottom / _dead_young、野生叫 <ref>_wild_bottom，
    # 名字对不上会直接报「模型不存在」。
    # 死株贴图的 donor：普通作物叫 crop/<ref>_dead，攀爬作物（番茄那套）叫 crop/<ref>_dead_bottom。
    # ⚠️ 它们只影响「我们的死株模型引用哪张 TFC 贴图」，不要去改 blockstate 里指向**我们自己的**模型路径。
    $deadTexRef      = if ($climb) { "crop/${simRef}_dead_bottom" } else { "crop/${ref}_dead" }
    $deadYoungTexRef = if ($climb) { "crop/${simRef}_dead_young" }  else { "crop/${ref}_dead_young" }
    $deadRef      = "dead_crop/${ref}"
    $deadYoungRef = if ($climb) { "dead_crop/${simRef}_young" }  else { "dead_crop/${ref}_young" }
    $wildRef      = if ($climb) { "crop/${simRef}_wild_bottom" } else { "crop/${ref}_wild" }
    $npk = $c['npk'] -split '/'
    # 产物物品三种来源：①缺省=自家食物物品 ②含冒号=外部物品（全跳过） ③不含冒号=自家非食物物品
    $prod     = $c['prod']
    $external = $false
    $noFood   = $false
    if (-not $prod) {
        $prod = "${NS}:food/$n"
    } elseif ($prod -match ':') {
        $external = $true
    } else {
        $noFood = $true
        $prod   = "${NS}:$prod"
    }
    $ownItem = (-not $external)
    $prodTex = $c['prodTex']
    if (-not $prodTex) { $prodTex = "tfc:item/food/${ref}" }
    $nV = [double]$npk[0]; $pV = [double]$npk[1]; $kV = [double]$npk[2]

    # [1] 气候
    Save-Json "data/$NS/tfc/climate_range/crop/${n}.json" ([ordered]@{
        max_hydration = [int]$c['hMax']; max_temperature = [double]$c['tMax']
        min_hydration = [int]$c['hMin']; min_temperature = [double]$c['tMin']
    })
    # [2] 食物
    $food = [ordered]@{ decay_modifier = [double]$c['decay']; hunger = 4 }
    $food['ingredient'] = [ordered]@{ item = "${NS}:food/$n" }
    $food['saturation'] = [double]$c['sat']
    if ($null -ne $c['veg'])     { $food['vegetables'] = [double]$c['veg'] }
    if ($null -ne $c['grain'])   { $food['grain'] = [double]$c['grain'] }
    if ($null -ne $c['protein']) { $food['protein'] = [double]$c['protein'] }
    if ($null -ne $c['water'])   { $food['water'] = [double]$c['water'] }
    if (-not $external -and -not $noFood) { Save-Json "data/$NS/tfc/food/${n}.json" $food }

    # [3] 作物掉落（照 TFC：成熟才掉产物，用 tfc:crop_yield_uniform；种子必掉）
    #     ⚠️ 双格作物的产物与种子都只从**下格**掉（照 TFC 的玉米掉落表），
    #        否则上下两格各触发一次，产量翻倍。
    #    莲座作物的产物只从「中心结果」那一刻掉（fruiting=true），而且 age 必定是满级
    #    —— RosetteCropBlock.postGrowthTick 里 growth>=1.0 才置 fruiting 并把 age 钉在 5。
    $prodProps = if ($rosette) { [ordered]@{ age="$age"; fruiting='true' } }
                 elseif ($double -or $climb) { [ordered]@{ age="$age"; part='bottom' } }
                 else { [ordered]@{ age="$age" } }
    Save-Json "data/$NS/loot_table/blocks/crop/${n}.json" ([ordered]@{
        type = 'minecraft:block'
        pools = @(
            [ordered]@{
                name = 'loot_pool'; rolls = 1
                entries = @([ordered]@{
                    type = 'minecraft:item'; name = $prod
                    conditions = @([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:crop/$n"; properties=$prodProps })
                    functions = @([ordered]@{ function='minecraft:set_count'
                        count=[ordered]@{ type='tfc:crop_yield_uniform'; min=0; max=[ordered]@{ type='minecraft:uniform'; min=6; max=10 } } })
                })
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            },
            [ordered]@{
                name = 'loot_pool'; rolls = 1
                entries = @($(
                    if ($double -or $climb) {
                        [ordered]@{ type='minecraft:item'; name="${NS}:seeds/$n"
                            conditions = @([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:crop/$n"; properties=[ordered]@{ part='bottom' } }) }
                    } else {
                        $seedEntry = [ordered]@{ type='minecraft:item'; name="${NS}:seeds/$n" }
                        if ($rosette) {
                            $seedEntry['functions'] = @([ordered]@{ function='minecraft:set_count'; count=[ordered]@{ type='minecraft:uniform'; min=1; max=2 } })
                        }
                        $seedEntry
                    }
                ))
                conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
            }
        )
    })
    if ($spread) {
        Save-Json "data/$NS/loot_table/blocks/crop/${n}.json" ([ordered]@{
            type='minecraft:block'; pools=@([ordered]@{ rolls=1
                entries=@([ordered]@{ type='minecraft:item'; name="${NS}:seeds/$n" })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' })
            })
        })
        Save-Json "data/$NS/tfc/food/${n}.json" ([ordered]@{
            decay_modifier=[double]$c['decay']; edible=$false; hunger=4
            ingredient=[ordered]@{ item="${NS}:$n" }
        })
    }
    # [4] 枯萎掉落（成熟枯死掉 1~3 种子，未成熟掉 1）
    # ⚠️ 莲座作物**跳过**这一节：RosetteCropBlock.die() 把侧芽直接弹到地上，
    #    死株用的是共享的 tfcfarmingplus:dead_rosette，根本不经过 per-crop 的 dead_crop 方块。
    #    这里若不跳过，会留下 3 个永远不会被引用的孤儿掉落表 + 孤儿模型（§8.3-4 的老毛病）。
    if (-not $rosette) {
    Save-Json "data/$NS/loot_table/blocks/dead_crop/${n}.json" ([ordered]@{
        type = 'minecraft:block'
        pools = @([ordered]@{
            name = 'loot_pool'; rolls = 1
            entries = @([ordered]@{
                type = 'minecraft:alternatives'
                children = @(
                    [ordered]@{ type='minecraft:item'; name="${NS}:seeds/$n"
                        conditions=@([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:dead_crop/$n"; properties=[ordered]@{ mature='true' } })
                        functions=@([ordered]@{ function='minecraft:set_count'; count=[ordered]@{ min=1; max=3; type='minecraft:uniform' } }) }
                    [ordered]@{ type='minecraft:item'; name="${NS}:seeds/$n"
                        conditions=@([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:dead_crop/$n"; properties=[ordered]@{ mature='false' } }) }
                )
            })
            conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
        })
    })
    }   # end if (-not $rosette) —— 莲座的枯萎掉落
    # Tall crop loot is settled on the lower plant; support is returned once.
    foreach ($kind in @('crop','dead_crop')) {
        if ($rosette -and $kind -eq 'dead_crop') { continue }
        $lootPath = "data/$NS/loot_table/blocks/$kind/${n}.json"
        $loot = $ser.DeserializeObject([IO.File]::ReadAllText((Join-Path $root $lootPath), $utf8))
        if ($double -or $climb) {
            foreach ($pool in $loot['pools']) {
                $pool['conditions'] = @($pool['conditions']) + @([ordered]@{
                    condition='minecraft:block_state_property'; block="${NS}:$kind/$n"; properties=[ordered]@{ part='bottom' }
                })
            }
        }
        if ($climb) {
            $loot['pools'] = @($loot['pools']) + @([ordered]@{
                rolls=1; entries=@([ordered]@{ type='minecraft:item'; name='minecraft:stick'
                    conditions=@([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:$kind/$n"; properties=[ordered]@{ part='bottom'; stick='true' } }) })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' })
            })
        }
        Save-Json $lootPath $loot
    }
    # [5] 野生掉落
    Save-Json "data/$NS/loot_table/blocks/wild_crop/${n}.json" ([ordered]@{
        type = 'minecraft:block'
        pools = @(
            [ordered]@{
                name='loot_pool'; rolls=1
                entries=@([ordered]@{
                    type='minecraft:item'; name=$prod
                    conditions=@([ordered]@{ condition='minecraft:block_state_property'; block="${NS}:wild_crop/$n"; properties=[ordered]@{ mature='true' } })
                    functions=@([ordered]@{ function='minecraft:set_count'; count=[ordered]@{ min=1; max=3; type='minecraft:uniform' } })
                })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' })
            },
            [ordered]@{ name='loot_pool'; rolls=1
                entries=@([ordered]@{ type='minecraft:item'; name="${NS}:seeds/$n" })
                conditions=@([ordered]@{ condition='minecraft:survives_explosion' }) }
        )
    })
    # [6] 方块状态
    # ⚠️ 双格化之后，age >= singleAge 的**单格**模型就作废了（blockstate 已改用 _bottom/_top）。
    #    生成器不会自动删旧文件，这里顺手清掉，避免残留模型误导。
    if ($double) {
        for ($i = $singleAge; $i -le $age; $i++) {
            $stale = Join-Path $root "assets/$NS/models/block/crop/${n}_age_$i.json"
            if (Test-Path $stale) { Remove-Item $stale -Force }
        }
    }
    #     双格作物：age < singleAge 是单格苗，之后每个 age 拆成 part=bottom / part=top 两个变体
    #     （照 TFC 的 crop/maize.json：age=0~2 单模型，age=3~5 各带 bottom 与 top）
    $variants = [ordered]@{}
    if ($rosette) {
        # 莲座：age 0~5（叶片轮数）× fruiting（中心是否结果）—— 对应 RosetteCropBlock 的两个状态属性。
        # fruiting=true 实际只在 age=5 出现，但这里给全 12 个组合：
        # 缺变体不会崩，但会在日志里刷 "Unable to load blockstate variant"，且日后改了生长逻辑就会踩坑。
        for ($i = 0; $i -le $age; $i++) {
            $variants["age=$i,fruiting=false"] = [ordered]@{ model = "${NS}:block/crop/${n}_age_$i" }
            $variants["age=$i,fruiting=true"]  = [ordered]@{ model = "${NS}:block/crop/${n}_age_${i}_fruiting" }
        }
    } elseif ($climb) {
        # 攀爬藤：三维方块状态（age × stick × part），照 TFC 的 crop/tomato.json ——
        # age < singleAge 时可以是「没插棍的单格」或「插了棍的上下两格」，插棍由 ClimbingCropBlock 的 useItemOn 完成。
        $variants = [ordered]@{}
        for ($i = 0; $i -lt $singleAge; $i++) {
            $variants["age=$i,stick=false"]            = [ordered]@{ model = "${NS}:block/crop/${n}_age_$i" }
            $variants["age=$i,stick=true,part=bottom"] = [ordered]@{ model = "${NS}:block/crop/${n}_age_${i}_stick" }
            $variants["age=$i,stick=true,part=top"]    = [ordered]@{ model = 'tfc:block/crop/stick' }
        }
        for ($i = $singleAge; $i -le $age; $i++) {
            $variants["age=$i,part=bottom"] = [ordered]@{ model = "${NS}:block/crop/${n}_age_${i}_bottom" }
            $variants["age=$i,part=top"]    = [ordered]@{ model = "${NS}:block/crop/${n}_age_${i}_top" }
        }
        Save-Json "assets/$NS/blockstates/crop/${n}.json" ([ordered]@{ variants = $variants })
    } elseif ($spread) {
        # 蔓延藤：照 TFC 的 crop/melon.json 用 **multipart** —— age 决定本体模型，
        # 四个水平方向各挂一条 side 模型（SpreadingCropBlock 实现 HorizontalPipeBlock 的连接属性）。
        $mp = @()
        for ($i = 0; $i -le $age; $i++) {
            $mp += [ordered]@{ when = [ordered]@{ age = $i }; apply = [ordered]@{ model = "${NS}:block/crop/${n}_age_$i" } }
        }
        $rot = @{ east = 90; north = 0; south = 180; west = 270 }
        foreach ($d in @('east','north','south','west')) {
            $apply = [ordered]@{ model = "${NS}:block/crop/${n}_side" }
            if ($rot[$d] -ne 0) { $apply['y'] = $rot[$d] }
            $mp += [ordered]@{ when = [ordered]@{ $d = $true }; apply = $apply }
        }
        Save-Json "assets/$NS/blockstates/crop/${n}.json" ([ordered]@{ multipart = $mp })
    } elseif ($double) {
        for ($i = 0; $i -lt $singleAge; $i++) { $variants["age=$i"] = [ordered]@{ model = "${NS}:block/crop/${n}_age_$i" } }
        for ($i = $singleAge; $i -le $age; $i++) {
            $variants["age=$i,part=bottom"] = [ordered]@{ model = "${NS}:block/crop/${n}_age_${i}_bottom" }
            $variants["age=$i,part=top"]    = [ordered]@{ model = "${NS}:block/crop/${n}_age_${i}_top" }
        }
    } else {
        for ($i = 0; $i -le $age; $i++) { $variants["age=$i"] = [ordered]@{ model = "${NS}:block/crop/${n}_age_$i" } }
    }
    # ⚠️ 蔓延作物在上面已用 multipart 写过同一个文件，这里不能再用 variants 覆盖
    #    （否则 multipart 被冲成 {"variants":{}}，游戏里藤蔓变成隐形方块）
    if (-not $spread) {
        Save-Json "assets/$NS/blockstates/crop/${n}.json" ([ordered]@{ variants = $variants })
    }
    # [7] 作物模型（借用 TFC 贴图占位）
    # 🛑 自定义几何的物种必须在这里短路（docs/112 §3.1，第 42~48 轮反复踩过）：
    #    莲座 -> gen-rosette-models.ps1（几何 rosette_age_N）
    #    叶球 -> gen-leafball-models.ps1（几何 leafball_age_N）
    #    本脚本**没有任何几何参数**，只能写 "parent: block/crop" 的普通十字；
    #    历史上正是在这里把已改好的自定义几何静默打回原形（谁后跑谁赢）。
    #    ⇒ 这两个族只由本脚本写 blockstate / 掉落表 / 物品模型，模型交给专用生成器。
    $leafballSpecies = @('lettuce', 'cauliflower', 'broccoli', 'napa_cabbage')
    if ($rosette) {
        # 莲座：12 个模型（6 龄 × fruiting）由 gen-rosette-models.ps1 生成。
        # 本脚本只负责上面的 12 个 blockstate 变体 —— 不要在这里写模型。
    } elseif ($leafballSpecies -contains $n) {
        # 叶球：6 个模型由 gen-leafball-models.ps1 生成
        # （含 tfc 命名空间下 cabbage 的跨命名空间覆盖）—— 同样不要在这里写。
    } elseif ($climb) {
        # 清掉 age < singleAge 的陈旧 _bottom/_top 模型：早期 singleAge 被错算成 0 时生成过这些文件，
        # 生成器不会自动删旧文件，留着会让 verify 一直报「贴图不存在」。
        for ($i = 0; $i -lt $singleAge; $i++) {
            foreach ($part in @('bottom','top')) {
                $stale = Join-Path $root "assets/$NS/models/block/crop/${n}_age_${i}_${part}.json"
                if (Test-Path $stale) { Remove-Item $stale -Force }
            }
        }
        for ($i = 0; $i -lt $singleAge; $i++) {
            Save-Json "assets/$NS/models/block/crop/${n}_age_$i.json" ([ordered]@{
                parent='block/crop'; textures=[ordered]@{ crop="tfc:block/crop/${simRef}_$i" }
            })
            Save-Json "assets/$NS/models/block/crop/${n}_age_${i}_stick.json" ([ordered]@{
                parent='block/crop'; textures=[ordered]@{ crop="tfc:block/crop/${simRef}_${i}_stick" }
            })
        }
        for ($i = $singleAge; $i -le $age; $i++) {
            foreach ($part in @('bottom','top')) {
                Save-Json "assets/$NS/models/block/crop/${n}_age_${i}_${part}.json" ([ordered]@{
                    parent='block/crop'; textures=[ordered]@{ crop="tfc:block/crop/${simRef}_${i}_${part}" }
                })
            }
        }
    } elseif ($spread) {
        for ($i = 0; $i -le $age; $i++) {
            Save-Json "assets/$NS/models/block/crop/${n}_age_$i.json" ([ordered]@{
                parent='block/crop'; textures=[ordered]@{ crop="tfc:block/crop/${simRef}_$i" }
            })
        }
        Save-Json "assets/$NS/models/block/crop/${n}_side.json" ([ordered]@{
            parent='block/crop'; textures=[ordered]@{ crop="tfc:block/crop/${simRef}_side" }
        })
    } elseif ($double) {
        for ($i = 0; $i -lt $singleAge; $i++) {
            Save-Json "assets/$NS/models/block/crop/${n}_age_$i.json" ([ordered]@{
                parent='block/crop'; textures=[ordered]@{ crop="tfc:block/crop/${ref}_$i" }
            })
        }
        for ($i = $singleAge; $i -le $age; $i++) {
            foreach ($part in @('bottom','top')) {
                Save-Json "assets/$NS/models/block/crop/${n}_age_${i}_${part}.json" ([ordered]@{
                    parent='block/crop'; textures=[ordered]@{ crop="tfc:block/crop/${dblRef}_${i}_${part}" }
                })
            }
        }
    } else {
        for ($i = 0; $i -le $age; $i++) {
            Save-Json "assets/$NS/models/block/crop/${n}_age_$i.json" ([ordered]@{
                parent='block/crop'; textures=[ordered]@{ crop="tfc:block/crop/${ref}_$i" }
            })
        }
    }
    # [7b] 蔓延作物的**结果方块**（整瓜）+ 腐烂变体 —— 照 TFC 的 melon / rotten_melon。
    #      整瓜由原生BE返还；案板负责切片。藤只掉种子；腐烂瓜掉腐肉。
    if ($spread) {
        Save-Json "assets/$NS/blockstates/${n}.json" ([ordered]@{
            variants = [ordered]@{ "" = [ordered]@{ model = "${NS}:block/${n}" } } })
        Save-Json "assets/$NS/models/block/${n}.json" ([ordered]@{ parent = $fruitRef })
        Save-Json "assets/$NS/blockstates/rotten_${n}.json" ([ordered]@{
            variants = [ordered]@{ "" = [ordered]@{ model = "${NS}:block/rotten_${n}" } } })
        Save-Json "assets/$NS/models/block/rotten_${n}.json" ([ordered]@{ parent = $rottenRef })
        # The native BE returns the stored whole fruit; no second drop path.
        Save-Json "data/$NS/loot_table/blocks/${n}.json" ([ordered]@{ type='minecraft:block'; pools=@() })
        $rotPool = @([ordered]@{
            name = 'loot_pool'; rolls = 1
            entries = @([ordered]@{ type='minecraft:item'; name = 'minecraft:rotten_flesh' })
            conditions = @([ordered]@{ condition = 'minecraft:survives_explosion' })
        })
        Save-Json "data/$NS/loot_table/blocks/rotten_${n}.json" ([ordered]@{ type = 'minecraft:block'; pools = $rotPool })
    }
    # [8a] 枯萎方块状态（⚠️ 少了它游戏会报 "Exception loading blockstate definition"）
    # [8b] 枯萎模型
    # ⚠️ 莲座作物整段跳过：它们的死株是**共享的** tfcfarmingplus:dead_rosette
    #    （RosetteCropBlock.die() 里写死），根本不存在 tfcfarmingplus:dead_crop/<n> 这个方块。
    #    只跳过 [4] 枯萎掉落而漏掉这里，会生成「模型引用了不存在贴图」的孤儿文件
    #    —— verify.ps1 实测抓到过 dead_crop/purslane 与 dead_crop/purslane_young 两条。
    if (-not $rosette) {
    $deadVariants = if ($climb) { [ordered]@{
        'mature=false,stick=false' = [ordered]@{ model="${NS}:block/dead_crop/${n}_young" }
        'mature=false,stick=true,part=bottom' = [ordered]@{ model='tfc:block/dead_crop/tomato_young_stick' }
        'mature=false,stick=true,part=top' = [ordered]@{ model='tfc:block/crop/stick' }
        'mature=true,part=bottom' = [ordered]@{ model="${NS}:block/dead_crop/$n" }
        'mature=true,part=top' = [ordered]@{ model='tfc:block/dead_crop/tomato_top' }
    } } elseif ($double) { [ordered]@{
        'mature=false' = [ordered]@{ model="${NS}:block/dead_crop/${n}_young" }
        'mature=true,part=bottom' = [ordered]@{ model="${NS}:block/dead_crop/$n" }
        'mature=true,part=top' = [ordered]@{ model='tfc:block/dead_crop/maize_top' }
    } } else { [ordered]@{
        'mature=true' = [ordered]@{ model="${NS}:block/dead_crop/$n" }
        'mature=false' = [ordered]@{ model="${NS}:block/dead_crop/${n}_young" }
    } }
    Save-Json "assets/$NS/blockstates/dead_crop/${n}.json" ([ordered]@{ variants=$deadVariants })
    Save-Json "assets/$NS/models/block/dead_crop/${n}.json" ([ordered]@{
        parent='block/crop'; textures=[ordered]@{ crop="tfc:block/${deadTexRef}" } })
    Save-Json "assets/$NS/models/block/dead_crop/${n}_young.json" ([ordered]@{
        parent='block/crop'; textures=[ordered]@{ crop="tfc:block/${deadYoungTexRef}" } })
    }   # end if (-not $rosette) —— 莲座的枯萎方块状态与模型
    # [9] 物品模型
    $prodPath = ($prod -replace "^${NS}:", "")   # tfcfarmingplus:fiber/flax -> fiber/flax
    if ($spread) {
        # 整瓜是**方块**，物品模型直接继承方块模型（方块物品的标准做法）。
        # ⚠️ 不能走 item/generated + minecraft:item/melon —— 原版根本没有这张贴图，
        #    实机日志会报 "Missing textures in model tfcfarmingplus:cantaloupe#inventory"。
        Save-Json "assets/$NS/models/item/${n}.json" ([ordered]@{ parent = "${NS}:block/${n}" })
    } elseif ($ownItem) { Save-Json "assets/$NS/models/item/${prodPath}.json" ([ordered]@{ parent='item/generated'; textures=[ordered]@{ layer0=$prodTex } }) }
    Save-Json "assets/$NS/models/item/seeds/${n}.json" ([ordered]@{ parent='item/generated'; textures=[ordered]@{ layer0="tfc:item/seeds/${ref}" } })
    # [10][11] configured_feature：单株 + 成片
    Save-Json "data/$NS/worldgen/configured_feature/plant/wild_crop/${n}.json" ([ordered]@{
        type=$(if ($flooded) { 'tfc:block_with_fluid' } else { 'minecraft:simple_block' })
        config=[ordered]@{ to_place=[ordered]@{ type='minecraft:simple_state_provider'; state=[ordered]@{ Name="${NS}:wild_crop/$n" } } }
    })
    Save-Json "data/$NS/worldgen/configured_feature/plant/wild_crop/${n}_patch.json" ([ordered]@{
        type='minecraft:random_patch'
        config=[ordered]@{ tries=6; xz_spread=5; y_spread=1; feature="${NS}:plant/wild_crop/$n" }
    })
    # Water crops use the submerged ground height and retain the existing fresh water.
    $singlePlacement = if ($flooded) { @(
        [ordered]@{ type='minecraft:heightmap'; heightmap='OCEAN_FLOOR_WG' }
        [ordered]@{ type='minecraft:block_predicate_filter'; predicate=[ordered]@{ type='minecraft:matching_fluids'; fluids=@('minecraft:water') } }
        [ordered]@{ type='minecraft:block_predicate_filter'; predicate=[ordered]@{ type='minecraft:would_survive'; state=[ordered]@{ Name="${NS}:wild_crop/$n" } } }
    ) } else { @(
        [ordered]@{ type='minecraft:heightmap'; heightmap='WORLD_SURFACE_WG' }
        [ordered]@{ type='minecraft:block_predicate_filter'; predicate=[ordered]@{ type='tfc:replaceable' } }
        [ordered]@{ type='minecraft:block_predicate_filter'; predicate=[ordered]@{ type='would_survive'; state=[ordered]@{ Name="${NS}:wild_crop/$n" } } }
    ) }
    Save-Json "data/$NS/worldgen/placed_feature/plant/wild_crop/${n}.json" ([ordered]@{
        feature="${NS}:plant/wild_crop/$n"; placement=$singlePlacement
    })
    # [13] placed_feature：成片（⚠️ climate → in_square → rarity_filter，照 TFC 的顺序）
    Save-Json "data/$NS/worldgen/placed_feature/plant/wild_crop/${n}_patch.json" ([ordered]@{
        feature="${NS}:plant/wild_crop/${n}_patch"
        placement=@(
            [ordered]@{ type='tfc:climate'
                        min_temperature=[double]$c['tMin']; max_temperature=[double]$c['tMax']
                        min_groundwater=([int]$c['hMin']*4); max_groundwater=([int]$c['hMax']*4) }
            [ordered]@{ type='minecraft:in_square' }
            [ordered]@{ type='minecraft:rarity_filter'; chance=90 }
        )
    })
    # [14b] 野生作物的资源（方块状态 + 方块模型 + 物品模型）—— 缺了会在游戏里变成紫黑格
    Save-Json "assets/$NS/blockstates/wild_crop/${n}.json" ([ordered]@{
        variants = [ordered]@{
            'mature=true'  = [ordered]@{ model = "${NS}:block/wild_crop/$n" }
            'mature=false' = [ordered]@{ model = "tfc:block/${deadYoungRef}" }
        }
    })
    Save-Json "assets/$NS/models/block/wild_crop/${n}.json" ([ordered]@{
        parent = 'tfc:block/wild_crop/crop'
        textures = [ordered]@{ crop = "tfc:block/${wildRef}" }
    })
    Save-Json "assets/$NS/models/item/wild_crop/${n}.json" ([ordered]@{
        parent = "${NS}:block/wild_crop/$n"
    })
    # [15] Firmalife 种植盆（作物 → 四格盆）
    # ⚠️ 蔓延型瓜类**不进种植盆**：藤要向四周铺开，四格盆放不下，而且它们本来就该种在农田上。
    #    顺手把上一轮可能留下的旧文件清掉（否则 Firmalife 加载期仍会读到它）。
    if ($spread) {
        $stalePf = Join-Path $root "data/firmalife/firmalife/plantable/${n}.json"
        if (Test-Path $stalePf) { Remove-Item $stalePf -Force }
    } else {
    $tex = @(); for ($i = 0; $i -le $age; $i++) { $tex += "tfc:block/crop/${ref}_$i" }
    Save-Json "data/firmalife/firmalife/plantable/${n}.json" ([ordered]@{
        crop=[ordered]@{ count=1; id=$prod }
        ingredient=[ordered]@{ item="${NS}:seeds/$n" }
        nutrient=[ordered]@{ nitrogen=$nV; phosphorous=$pV; potassium=$kV }
        planter='quad'
        seed=[ordered]@{ count=1; id="${NS}:seeds/$n" }
        specials=@()
        stages=$age
        textures=$tex
    })
    }

    # 收集 tag 与语言
    $mineableHoe += "${NS}:crop/$n", "${NS}:wild_crop/$n", "${NS}:dead_crop/$n"
    $cropTag     += "${NS}:crop/$n", "${NS}:wild_crop/$n", "${NS}:dead_crop/$n"
    $snowPiled   += "${NS}:wild_crop/$n"
    $wildItems   += "$NS:wild_crop/$n"
    $vegItems    += "$NS:food/$n"
    $seedItems   += "$NS:seeds/$n"
    # ⚠️ rosette 必须一起导出：gen-tags 要据此**不给莲座写 dead_crop/<n>** ——
    #    莲座用共享的 dead_rosette，根本没有 tfcfarmingplus:dead_crop/<n> 这个方块，
    #    无条件写进 tag 会让 tfc:crops 与 minecraft:mineable/hoe **整个标签加载失败**
    #    （并级联拖垮 tfc:mineable/scythe / knife；实测日志 10 条 TagLoader ERROR）。
    $script:manifest += [ordered]@{ name = $n; noFood = $noFood; double = $double; spread = $spread; climb = $climb; flooded = $flooded; rosette = $rosette }
}

# [14] tag 已集中到 tools/gen-tags.ps1 统一生成（避免两个脚本互相覆盖）

# [15b] 导出作物清单（单一数据源，供 gen-tags / polish-book 等读取）
$manifestPath = Join-Path $root 'crops-manifest.json'
[System.IO.File]::WriteAllText($manifestPath,
    (([ordered]@{ crops = $script:manifest }) | ConvertTo-Json -Depth 5 -Compress),
    (New-Object System.Text.UTF8Encoding($false)))
Write-Host "[15b] crop manifest: $($script:manifest.Count) species -> $manifestPath"

# [16] 语言文件
foreach ($lang in @('en_us','zh_cn')) {
    $p = Join-Path $root "assets/$NS/lang/$lang.json"
    $d = $ser.DeserializeObject([System.IO.File]::ReadAllText($p, $utf8))
    $out = [ordered]@{}
    foreach ($k in $d.Keys) { $out[$k] = $d[$k] }
    foreach ($c in $crops) {
        $n = $c['n']
        $name = if ($lang -eq 'zh_cn') { $c['zh'] } else { $c['en'] }
        # ⚠️ 必须在这里重算：循环外的 $prod/$noFood/$ownItem 是上一个作物的残留值，
        #    直接用会把非食物产物（纤维/棉铃）也写出食物 lang 键。
        # ⚠️ $spread / $double 等标记也必须在这里重算：主循环结束后它们保留的是**最后一个作物**
        #    的值（本例是 water_shield 的 false），直接读会让蔓延作物的额外语言键全部写不出来
        #    —— 与上面 $prod 那段注释是同一类陷阱，本轮又踩了一次。
        $spread = [bool]$c['spread']
        $climb  = [bool]$c['climb']
        $prod   = $c['prod']
        $noFood = $false
        if (-not $prod) { $prod = "${NS}:food/$n" }
        elseif ($prod -notmatch ':') { $noFood = $true; $prod = "${NS}:$prod" }
        $ownItem = ($prod -notmatch '^tfc:')
        if ($ownItem -and -not $noFood) { $out["item.$NS.food.$n"] = $name }
        if ($ownItem -and $noFood) {
            # 产物不是食物的作物（纤维 / 棉铃 / 啤酒花）：键名由 prod 推导，名字用 zhProd/enProd。
            #
            # ⚠️⚠️ 这里必须兜底 —— 曾经写成
            #     `$out["item.…"] = if ($lang -eq 'zh_cn') { $c['zhProd'] } else { $c['enProd'] }`
            #     而 hops 这行表里**没有 zhProd/enProd 字段**，于是键值成了 PowerShell 的 $null，
            #     ConvertTo-Json 照实输出 JSON `null`：
            #         "item.tfcfarmingplus.hops":null
            #     后果极其隐蔽：MC 用 Gson 逐键灌语言表，读到 JsonNull.getAsString() 抛异常被 catch，
            #     **该键之后的所有键全部丢弃** —— 表现为「hops 之前的作物名正常，
            #     之后的 14 种果树名全是原始键名 block.tfcfarmingplus.plant.pear_sapling」。
            #     排查时误以为是 lan文件没打包／资源包覆盖，绕了很大一圈。
            #     （已同步在 verify.ps1 加检查：lang 值不得为 null。）
            $probeKey = "item." + (($prod -replace ':','.') -replace '/','.')
            $probeVal = if ($lang -eq 'zh_cn') { if ($c['zhProd']) { $c['zhProd'] } else { $c['zh'] } }
                        else                   { if ($c['enProd']) { $c['enProd'] } else { $c['en'] } }
            $out[$probeKey] = "$probeVal"
        }
        $out["item.$NS.seeds.$n"]         = if ($lang -eq 'zh_cn') { "$name" + "种子" } else { "$name Seeds" }
        $out["block.$NS.crop.$n"]         = if ($lang -eq 'zh_cn') { "$name" + "作物" } else { "$name Crop" }
        $out["block.$NS.wild_crop.$n"]    = if ($lang -eq 'zh_cn') { "野生$name" } else { "Wild $name" }
        $out["block.$NS.dead_crop.$n"]    = if ($lang -eq 'zh_cn') { "枯死的$name" } else { "Dead $name" }
        # 蔓延作物额外四类名字：切片（砍开整瓜得到）、整瓜的方块与物品、腐烂瓜。
        # ⚠️ 少了 item.$NS.<n>，方块物品会直接显示原始键名（同 §5.28.1 的物品栏键名事故）。
        if ($spread) {
            $out["item.$NS.food.${n}_slice"] = if ($lang -eq 'zh_cn') { "$name" + "切片" } else { "$name Slice" }
            $out["item.$NS.$n"]              = $name
            $out["block.$NS.$n"]             = $name
            $out["block.$NS.rotten_$n"]      = if ($lang -eq 'zh_cn') { "腐烂的$name" } else { "Rotten $name" }
        }
    }
    [System.IO.File]::WriteAllText($p, $ser.Serialize($out), $utf8)
    $script:count++
    Write-Host "lang $lang : $($out.Keys.Count) 条"
}

# Restore reviewed form geometry after the legacy draft templates.
Copy-ReviewedCropForms 'broccoli'
Copy-ReviewedCropForms 'lettuce'
Copy-ReviewedCropForms 'cauliflower'
Copy-ReviewedCropForms 'napa_cabbage'
Copy-ReviewedKaleWildForms
Copy-ReviewedCropDisplay 'chili'
Copy-ReviewedCropDisplay 'fenugreek'
Copy-ReviewedCropDisplay 'spinach'
Copy-ReviewedCropDisplay 'sunflower'
Copy-ReviewedCropDisplay 'swiss_chard'
Copy-ReviewedCropDisplay 'celery'
Copy-ReviewedCropDisplay 'celtuce'
Copy-ReviewedCropDisplay 'rhubarb'
Copy-ReviewedItemIcons
Write-Host "完成：本次写入 $script:count 个文件"










