param([string]$ReportDirectory = '', [string]$Resources = '')
# Read source contracts and resources; do not mutate game content.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$module = Split-Path $env:TFC_TOOLS_ROOT -Parent
$instance = Split-Path (Split-Path $module -Parent) -Parent
$resourceRoot = if ([string]::IsNullOrWhiteSpace($Resources)) { Join-Path $module 'src/main/resources' }
    else { (Resolve-Path -LiteralPath $Resources).Path }
. (Join-Path $env:TFC_TOOLS_ROOT 'crop-tall-contracts.ps1')
. (Join-Path $env:TFC_TOOLS_ROOT 'crop-flooded-contracts.ps1')
. (Join-Path $env:TFC_TOOLS_ROOT 'crop-spreading-contracts.ps1')
. (Join-Path $env:TFC_TOOLS_ROOT 'crop-rosette-contracts.ps1')
$sourcePath = Join-Path $module 'src/main/java/io/github/likexiang21/tfcplus/farming/common/crop\FarmingCrops.java'
$source = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
$manifestPath = Join-Path $env:TFC_TOOLS_ROOT 'contracts/crops-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$language = Get-Content -LiteralPath (Join-Path $resourceRoot 'assets/tfcfarmingplus/lang/zh_cn.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$errors = New-Object 'System.Collections.Generic.List[string]'
$cache = @{}
function Read-Resource([string]$relative) {
    if (-not $cache.ContainsKey($relative)) {
        $path = Join-Path $resourceRoot $relative
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing resource: $relative" }
        $cache[$relative] = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    return $cache[$relative]
}
function Get-JsonObjects($value) {
    if ($value -is [array]) {
        foreach ($child in $value) { Get-JsonObjects $child }
    } elseif ($value -is [pscustomobject]) {
        Write-Output $value
        foreach ($property in $value.PSObject.Properties) { Get-JsonObjects $property.Value }
    }
}
function Get-Nutrients([string]$call) {
    $match = [regex]::Match($call, '(-?\d+(?:\.\d+)?)f\s*,\s*(-?\d+(?:\.\d+)?)f\s*,\s*(-?\d+(?:\.\d+)?)f')
    if (-not $match.Success) { throw "Unrecognized nutrient declaration: $call" }
    return @([double]::Parse($match.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture),
        [double]::Parse($match.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture),
        [double]::Parse($match.Groups[3].Value, [Globalization.CultureInfo]::InvariantCulture))
}
$registrations = @([regex]::Matches($source,
    'public static final DeferredHolder<Block, (?<class>[^>]+)>\s+(?<field>[A-Z0-9_]+)\s*=\s*(?<call>[^;]+);') |
    Where-Object { $_.Groups['field'].Value -match '_CROP$' })
$names = @($registrations | ForEach-Object { [regex]::Match($_.Groups['call'].Value, '"([a-z_]+)"').Groups[1].Value })
if ($names.Count -ne @($names | Sort-Object -Unique).Count -or
    @(Compare-Object @($manifest.crops.name | Sort-Object) @($names | Sort-Object)).Count) {
    throw 'Source registrations and the crop manifest do not form the same unique species set.'
}
$seedCalls = @{}
foreach ($match in [regex]::Matches($source, 'seed\("(?<name>[a-z_]+)"(?<body>[^;]+)\);')) {
    $seedCalls[$match.Groups['name'].Value] = $match.Value
}
$validBlocks = [regex]::Match($source, '(?s)public static Block\[\] cropBlocks\(\)\s*\{(?<body>.*?)\n    \}').Groups['body'].Value
$pickableFactory = [regex]::Match($source, '(?s)private static DeferredHolder<Block, FarmingPickableCropBlock> pickable\((?<body>.*?)\n    \}').Groups['body'].Value
$pickableAgeMatch = [regex]::Match($pickableFactory, '(\d+),\s*dead,\s*seedFor')
if (-not $pickableAgeMatch.Success) { throw 'Cannot establish the pickable factory max age.' }
$groupNames = @{
    FarmingCropBlock = '普通单格'; FarmingPickableCropBlock = '可重复采收'; FarmingDoubleCropBlock = '双格'
    FarmingFloodedCropBlock = '水生'; FarmingClimbingCropBlock = '攀爬'; FarmingSpreadingCropBlock = '蔓延'; RosetteCropBlock = '莲座'
}
$foodTags = @()
foreach ($tag in @('vegetable', 'grain', 'fruit')) { $foodTags += (Read-Resource "data/c/tags/item/foods/$tag.json").values }
$guides = @{}
foreach ($lang in @('en_us', 'zh_cn')) {
    $guides[$lang] = Read-Resource "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/crops.json"
}
$tfcJars = @(Get-ChildItem -LiteralPath (Join-Path $instance 'mods') -File -Filter 'TerraFirmaCraft-NeoForge-*.jar')
if ($tfcJars.Count -ne 1) { throw 'Expected exactly one installed TFC dependency.' }
$tfc = [IO.Compression.ZipFile]::OpenRead($tfcJars[0].FullName)
$rows = New-Object 'System.Collections.Generic.List[object]'
try {
    foreach ($registration in $registrations) {
        $call = $registration.Groups['call'].Value
        $name = [regex]::Match($call, '"([a-z_]+)"').Groups[1].Value
        $class = $registration.Groups['class'].Value
        $field = $registration.Groups['field'].Value
        if (-not $groupNames.ContainsKey($class)) { throw "Unknown crop implementation: $class" }
        $tall = $class -in @('FarmingDoubleCropBlock', 'FarmingClimbingCropBlock')
        $flooded = $class -eq 'FarmingFloodedCropBlock'
        $spreading = $class -eq 'FarmingSpreadingCropBlock'
        $spreadInfo = $null
        $rosette = $class -eq 'RosetteCropBlock'
        $rosetteInfo = $null
        $detailed = $tall -or $flooded -or $spreading -or $rosette -or $class -in @('FarmingCropBlock', 'FarmingPickableCropBlock')
        $floodedInfo = $null
        $tallInfo = $null
        $rowErrors = New-Object 'System.Collections.Generic.List[string]'
        $seedCall = $seedCalls[$name]
        if (-not $seedCall) { throw "Missing seed registration: $name" }
        if ($seedCall -notmatch ('FarmingCrops\.' + [regex]::Escape($field) + '\.get\(\)')) { $rowErrors.Add('seed points to another crop') }
        if ($validBlocks -notmatch ('\b' + [regex]::Escape($field) + '\.get\(\)')) { $rowErrors.Add('missing crop BE valid-block registration') }
        $nutrients = Get-Nutrients $call
        $seedNutrients = Get-Nutrients $seedCall
        if (($nutrients -join ',') -cne ($seedNutrients -join ',')) { $rowErrors.Add('seed/crop nutrient mismatch') }
        $climateRef = [regex]::Match($call, '([A-Z_]+_CLIMATE)').Groups[1].Value
        if ($seedCall -notmatch ('\b' + [regex]::Escape($climateRef) + '\b')) { $rowErrors.Add('seed/crop climate reference mismatch') }
        $climate = Read-Resource "data/tfcfarmingplus/tfc/climate_range/crop/$name.json"
        if ($climate.min_temperature -ge $climate.max_temperature -or
            $climate.min_hydration -gt $climate.max_hydration) { $rowErrors.Add('invalid climate range') }
        $state = Read-Resource "assets/tfcfarmingplus/blockstates/crop/$name.json"
        $displayAges = @(@($state.variants.PSObject.Properties.Name | ForEach-Object {
            if ($_ -match '(?:^|,)age=(\d+)') { [int]$Matches[1] }
        }) + @(Get-JsonObjects $state | ForEach-Object {
            if ($null -ne $_.age) { foreach ($part in ([string]$_.age -split '\|')) { if ($part -match '^\d+$') { [int]$part } } }
        }) | Sort-Object -Unique)
        $cropLoot = Read-Resource "data/tfcfarmingplus/loot_table/blocks/crop/$name.json"
        $lootObjects = @(Get-JsonObjects $cropLoot)
        $products = @($lootObjects | Where-Object { $_.type -eq 'minecraft:item' -and $_.name -notlike 'tfcfarmingplus:seeds/*' -and $_.name -ne 'minecraft:stick' } |
            ForEach-Object { $_.name } | Sort-Object -Unique)
        $maxAge = $null
        $foodStatus = '待后续形态切片核查'
        $planterStatus = '待后续形态切片核查'
        $harvest = '待后续形态切片核查'
        if ($detailed) {
            $planterStatus = '当前无盆栽数据（可选桥接）'
            $maxAge = if ($class -eq 'FarmingPickableCropBlock') { [int]$pickableAgeMatch.Groups[1].Value }
                elseif ($rosette) { 5 }
                elseif ($tall) { [int][regex]::Match($call, '(?:dbl|climb)\("[a-z_]+",\s*\d+,\s*(\d+)').Groups[1].Value }
                elseif ($spreading) { [int][regex]::Match($call, 'spread\("[a-z_]+",\s*(\d+)').Groups[1].Value }
                elseif ($flooded) { [int][regex]::Match($call, 'flooded\("[a-z_]+",\s*(\d+)').Groups[1].Value }
                else { [int][regex]::Match($call, 'crop\("[a-z_]+",\s*(\d+)').Groups[1].Value }
            if (@(Compare-Object @(0..$maxAge) $displayAges).Count) { $rowErrors.Add('age model variants do not cover Java ages') }
            foreach ($kind in @('crop', 'wild_crop', 'dead_crop')) {
                if ($rosette -and $kind -eq 'dead_crop') { continue } # Shared dead_rosette returns its seed on death.
                $loot = Read-Resource "data/tfcfarmingplus/loot_table/blocks/$kind/$name.json"
                $objects = @(Get-JsonObjects $loot)
                foreach ($condition in @($objects | Where-Object { $_.condition -eq 'minecraft:block_state_property' })) {
                    if ($condition.block -ne "tfcfarmingplus:$kind/$name") { $rowErrors.Add("wrong $kind block-state condition") }
                }
                if (-not @($objects | Where-Object { $_.type -eq 'minecraft:item' -and $_.name -eq "tfcfarmingplus:seeds/$name" }).Count) {
                    $rowErrors.Add("missing $kind seed return")
                }
            }
            if (-not $spreading -and -not @($lootObjects | Where-Object { $_.condition -eq 'minecraft:block_state_property' -and $_.properties.age -eq [string]$maxAge }).Count) {
                $rowErrors.Add('no mature-age harvest condition')
            }
            if (-not $spreading -and $products.Count -ne 1) { $rowErrors.Add('expected one principal crop product') }
            $product = if ($spreading) { "tfcfarmingplus:$name" } else { $products[0] }
            if ($product -like 'tfcfarmingplus:food/*') {
                $food = Read-Resource ('data/tfcfarmingplus/tfc/food/' + $product.Split('/')[1] + '.json')
                if ($food.ingredient.item -ne $product -or [double]$food.hunger -le 0) { $rowErrors.Add('food definition does not cover the actual harvest') }
                if ($product -notin $foodTags) { $rowErrors.Add('food harvest lacks a fruit/vegetable/grain tag') }
                $foodStatus = '项目食品数据与分类已核对'
            } elseif ($product -eq 'tfc:food/strawberry') {
                $entry = $tfc.GetEntry('data/tfc/tfc/food/strawberry.json')
                if (-not $entry) { $rowErrors.Add('missing canonical TFC strawberry food definition') }
                $foodStatus = '沿用 TFC 原版草莓食品'
            } elseif ($product -in @('tfcfarmingplus:fiber/flax','tfcfarmingplus:fiber/ramie','tfcfarmingplus:fiber/hemp','tfcfarmingplus:fiber/sisal','tfcfarmingplus:cotton_boll','tfcfarmingplus:hops')) { $foodStatus = '非食品材料；用途深查归 AR2' }
            elseif ($spreading) { $foodStatus = '整瓜不可直接食用但参与腐烂；案板切片继承新鲜度' }
            else { $rowErrors.Add("unreviewed product: $product") }
            $planterRelative = "data/firmalife/firmalife/plantable/$name.json"
            if (Test-Path -LiteralPath (Join-Path $resourceRoot $planterRelative)) {
                $planter = Read-Resource $planterRelative
                if ($planter.ingredient.item -ne "tfcfarmingplus:seeds/$name" -or $planter.seed.id -ne "tfcfarmingplus:seeds/$name" -or
                    $planter.crop.id -ne $product) { $rowErrors.Add('planter input/seed/product mismatch') }
                $planterStatus = '盆栽输入输出已核对；显示阶段可独立于田间'
            }
            $harvest = if ($class -eq 'FarmingPickableCropBlock') { '右键近熟/成熟采收并回退；破坏拔除；寿命沿用TFC' } else { '完全成熟后破坏收获并返种' }
            if ($tall) {
                $tallInfo = Assert-TallCrop $name $class $call $state $cropLoot $maxAge $product $rowErrors
                $harvest = if ($class -eq 'FarmingClimbingCropBlock') { '木棍右键下半株搭架；成熟破坏采收；仅下半株结算并返棍' } else { '预留上格；长高成熟后破坏采收；仅下半株结算' }
            }
            if ($flooded) {
                $floodedInfo = Assert-FloodedCrop $name $call $state $cropLoot $maxAge $product $rowErrors
                $harvest = '先开垦并备好淡水水源，再播种；完全成熟后破坏收获并返种'
            }
            if ($spreading) {
                $spreadInfo = Assert-SpreadingCrop $name $call $state $cropLoot $maxAge $rowErrors
                $harvest = '藤只返种；采收相邻整瓜保留新鲜度；已有案板一瓜切四片'
            }
            if ($rosette) {
                $rosetteInfo = Assert-RosetteCrop $name $state $cropLoot $maxAge $product $rowErrors
                $harvest = '六龄生长；完全成熟且结果后破坏采收并返1至2份侧芽；枯死时返1份，死株不再掉落'
            }
            if ($class -eq 'FarmingPickableCropBlock') {
                foreach ($lang in @('en_us', 'zh_cn')) {
                    $page = @($guides[$lang].pages | Where-Object { $_.anchor -eq $name })
                    $required = if ($lang -eq 'zh_cn') { '右键' } else { 'right-click' }
                    if ($page.Count -ne 1 -or $page[0].text -notmatch $required) { $rowErrors.Add("missing explicit harvest control: $lang") }
                }
            }
        }
        foreach ($problem in $rowErrors) { $errors.Add("$name : $problem") }
        $titleKey = "block.tfcfarmingplus.crop.$name"
        $rows.Add([pscustomobject][ordered]@{
            Name = $name; ChineseName = $language.$titleKey; Shape = $groupNames[$class]; RuntimeClass = $class
            CropId = "tfcfarmingplus:crop/$name"; SeedId = "tfcfarmingplus:seeds/$name"
            FirstTallAge = $tallInfo.FirstTallAge; DeadClass = $(if ($rosette) { $rosetteInfo.DeadClass } elseif ($flooded) { $floodedInfo.DeadClass } elseif ($spreading) { $spreadInfo.DeadClass } else { $tallInfo.DeadClass }); StateCombinations = $(if ($rosette) { $rosetteInfo.StateCombinations } elseif ($flooded) { $floodedInfo.StateCombinations } elseif ($spreading) { $spreadInfo.StateCombinations } else { $tallInfo.StateCombinations })
            FruitId = $spreadInfo.FruitId; SliceId = $spreadInfo.SliceId
            FluidStates = $floodedInfo.FluidStates; WildRule = $floodedInfo.WildRule
            JavaMaxAge = $maxAge; ResourceAges = ($displayAges -join ','); N = $nutrients[0]; P = $nutrients[1]; K = $nutrients[2]
            Temperature = "$($climate.min_temperature)..$($climate.max_temperature)"; Hydration = "$($climate.min_hydration)..$($climate.max_hydration)"
            HarvestProducts = ($products -join ','); HarvestRule = $harvest; FoodStatus = $foodStatus; PlanterStatus = $planterStatus
            SoilRule = $(if ($flooded) { 'TFC耕地；作物所在格必须预先有淡水水源' } elseif ($detailed) { 'TFC耕地标签；正常放置仍待实机' } else { '按对应形态，待后续深查' })
            GrowthOwner = $(if ($detailed) { 'TFC CropHelpers/CropBlockEntity；原生光照、气候、养分、历法和枯死' } else { 'TFC基础类与项目形态逻辑；待后续深查' })
            AuditStatus = $(if ($rowErrors.Count) { '静态检查失败' } elseif ($detailed) { '本批静态检查通过；实机待验证' } else { '基础登记已查；深入闭环待后续切片' })
            RuntimeVerified = $false; Findings = ($rowErrors -join '; ')
        })
    }
} finally { $tfc.Dispose() }
$summary = [ordered]@{
    SourceSha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    ManifestSha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
    TfcJar = $tfcJars[0].Name; TfcSha256 = (Get-FileHash -LiteralPath $tfcJars[0].FullName -Algorithm SHA256).Hash
    ResourceRoot = $resourceRoot
    Total = $rows.Count; Detailed = @($rows | Where-Object { $_.JavaMaxAge -ne $null }).Count
    Tall = @($rows | Where-Object { $_.FirstTallAge -ne $null }).Count
    TallStateCombinations = ($rows | Where-Object { $_.FirstTallAge -ne $null } | Measure-Object -Property StateCombinations -Sum).Sum
    Flooded = @($rows | Where-Object { $_.FluidStates }).Count
    FloodedStateCombinations = ($rows | Where-Object { $_.FluidStates } | Measure-Object -Property StateCombinations -Sum).Sum
    Spreading = @($rows | Where-Object { $_.FruitId }).Count
    SpreadingStateCombinations = ($rows | Where-Object { $_.FruitId } | Measure-Object -Property StateCombinations -Sum).Sum
    Rosette = @($rows | Where-Object { $_.RuntimeClass -eq 'RosetteCropBlock' }).Count
    RosetteStateCombinations = ($rows | Where-Object { $_.RuntimeClass -eq 'RosetteCropBlock' } | Measure-Object -Property StateCombinations -Sum).Sum
    SharedRosetteDeadStates = 2
    Findings = $errors.ToArray(); Crops = $rows.ToArray()
}
if ($ReportDirectory) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'crop-contracts.json'), ($summary | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
    $csv = $rows | Select-Object @{n='作物';e={$_.ChineseName}},@{n='编号';e={$_.Name}},@{n='形态';e={$_.Shape}},@{n='Java最大龄';e={$_.JavaMaxAge}},
        @{n='开始双格龄';e={$_.FirstTallAge}},@{n='死株类型';e={$_.DeadClass}},@{n='核对状态组合';e={$_.StateCombinations}},
        @{n='果实方块';e={$_.FruitId}},@{n='加工产物';e={$_.SliceId}},
        @{n='流体状态';e={$_.FluidStates}},@{n='自然生成条件';e={$_.WildRule}},
        @{n='显示龄';e={$_.ResourceAges}},N,P,K,@{n='温度';e={$_.Temperature}},@{n='水合度';e={$_.Hydration}},
        @{n='本体掉落物';e={$_.HarvestProducts}},@{n='采收规则';e={$_.HarvestRule}},@{n='食品状态';e={$_.FoodStatus}},
        @{n='盆栽';e={$_.PlanterStatus}},@{n='土壤';e={$_.SoilRule}},@{n='生长逻辑';e={$_.GrowthOwner}},
        @{n='检查状态';e={$_.AuditStatus}},@{n='问题';e={$_.Findings}} |
        ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'crop-contracts.csv'), (($csv -join "`r`n") + "`r`n"), [Text.UTF8Encoding]::new($true))
}
Write-Output ("[INFO] species = {0}; detailed crops = {1}; findings = {2}" -f $rows.Count, $summary.Detailed, $errors.Count)
if ($errors.Count) { $errors | ForEach-Object { Write-Output "[FAIL] $_" }; exit 1 }
Write-Output '[OK] static crop contracts checked; runtime gameplay remains unverified'
exit 0
