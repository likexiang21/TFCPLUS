param([string]$ReportDirectory = '', [string]$Resources = '', [string]$ModuleDirectory = '')
# Read-only contract audit. No simulated ticks, game commands or asset writes.
$ErrorActionPreference = 'Stop'
$liveModule = Split-Path $PSScriptRoot -Parent
$module = if ($ModuleDirectory) { (Resolve-Path -LiteralPath $ModuleDirectory).Path } else { $liveModule }
$resourceRoot = if ($Resources) { (Resolve-Path -LiteralPath $Resources).Path } else { Join-Path $module 'src/main/resources' }
$instance = Split-Path (Split-Path $liveModule -Parent) -Parent
$common = Join-Path $module 'src/main/java/com/example/tfcfarmingplus/common'
$sourcePath = Join-Path $common 'MyFruitTrees.java'
$source = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
$manifestPath = Join-Path $liveModule 'tools/fruit-trees-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$errors = New-Object 'System.Collections.Generic.List[string]'
$deferred = New-Object 'System.Collections.Generic.List[string]'
$cache = @{}
function Read-TreeResource([string]$relative) {
    if (-not $cache.ContainsKey($relative)) {
        $path = Join-Path $resourceRoot $relative
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing tree resource: $relative" }
        $cache[$relative] = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    return $cache[$relative]
}
function Get-TreeObjects($value) {
    if ($value -is [array]) { foreach ($v in $value) { Get-TreeObjects $v } }
    elseif ($value -is [pscustomobject]) { $value; foreach ($p in $value.PSObject.Properties) { Get-TreeObjects $p.Value } }
}
function Resolve-TreeVariant($definition, [hashtable]$values) {
    $matches = @($definition.variants.PSObject.Properties | Where-Object {
        $valid = $true
        foreach ($pair in ($_.Name -split ',')) {
            $parts = $pair -split '=',2
            if ($parts.Count -ne 2 -or -not $values.ContainsKey($parts[0])) { throw "Unknown tree variant condition: $pair" }
            if ([string]$values[$parts[0]] -notin ($parts[1] -split '\|')) { $valid=$false }
        }
        $valid
    })
    if ($matches.Count -ne 1 -or -not $matches[0].Value.model) { throw 'Tree state must select exactly one reviewed model.' }
    $model = [string]$matches[0].Value.model
    if ($model -like 'tfcfarmingplus:*') { [void](Read-TreeResource ('assets/tfcfarmingplus/models/' + $model.Split(':')[1] + '.json')) }
    return $model
}
function Assert-TreeRule([bool]$condition, [string]$message) { if (-not $condition) { $errors.Add($message) } }
$pattern = 'new Tree\("(?<name>[a-z_]+)",\s*"(?<en>[^"]+)",\s*"(?<donor>[a-z_]+)",\s*new Lifecycle\[\]\{(?<life>[^}]+)\},\s*(?<color>0x[0-9A-Fa-f]+),\s*(?<min>-?\d+),\s*(?<max>-?\d+)\)'
$definitions = @([regex]::Matches($source,$pattern))
$names = @($definitions | ForEach-Object { $_.Groups['name'].Value })
Assert-TreeRule ($names.Count -eq 49 -and @($names | Sort-Object -Unique).Count -eq 49) 'Tree source declarations must contain the reviewed 49 unique IDs.'
Assert-TreeRule (@(Compare-Object @($names | Sort-Object) @($manifest.trees.name | Sort-Object)).Count -eq 0) 'Source and manifest species sets differ.'
$temperate = @('pear','apricot','quince','persimmon','pomegranate','loquat','sorb','mulberry','jujube','hawthorn','medlar','pawpaw','crabapple','cornelian_cherry')
Assert-TreeRule (($names[0..13] -join ',') -ceq ($temperate -join ',')) 'Reviewed temperate group changed; review scope before extending checks.'
$tropical = @('mango','papaya','guava','lychee','longan','avocado','starfruit','tamarind','sapodilla','cherimoya','rambutan','durian','jackfruit','breadfruit')
Assert-TreeRule (($names[14..27] -join ',') -ceq ($tropical -join ',')) 'Reviewed tropical group changed; review scope before extending checks.'
$nuts = @('walnut','hazelnut','almond','pecan','macadamia')
Assert-TreeRule (($names[28..32] -join ',') -ceq ($nuts -join ',')) 'Reviewed nut group changed; review scope before extending checks.'
$remaining = @('waxberry','lime','grapefruit','kiwi','wax_apple','wampee','amla','sea_buckthorn')
Assert-TreeRule (($names[41..48] -join ',') -ceq ($remaining -join ',')) 'Reviewed remaining fruit group changed.'
$reviewed = @($temperate) + @($tropical) + @($nuts) + @($remaining)
$sapling = Get-Content -LiteralPath (Join-Path $common 'blocks/MyFruitTreeSaplingBlock.java') -Raw -Encoding UTF8
$item = Get-Content -LiteralPath (Join-Path $common 'items/MyFruitTreeSaplingItem.java') -Raw -Encoding UTF8
$leaves = Get-Content -LiteralPath (Join-Path $common 'blocks/MyFruitTreeLeavesBlock.java') -Raw -Encoding UTF8
$growing = Get-Content -LiteralPath (Join-Path $common 'blocks/MyGrowingFruitTreeBranchBlock.java') -Raw -Encoding UTF8
$entities = Get-Content -LiteralPath (Join-Path $common 'MyBlockEntities.java') -Raw -Encoding UTF8
$berry = Get-Content -LiteralPath (Join-Path $common 'blockentities/MyBerryBushBlockEntity.java') -Raw -Encoding UTF8
$seasonal = Get-Content -LiteralPath (Join-Path $common 'blocks/MySeasonalPlantFix.java') -Raw -Encoding UTF8
$template = Get-Content -LiteralPath (Join-Path $module 'tools/gen-patchouli-book.ps1') -Raw -Encoding UTF8
$tagTemplate = Get-Content -LiteralPath (Join-Path $module 'tools/gen-tags.ps1') -Raw -Encoding UTF8
Assert-TreeRule ($tagTemplate -match '\$vegCropNames =[^\r\n]+-ne ''strawberry''') 'Retired project strawberry must not return through vegetable tag generation.'
Assert-TreeRule ($sapling -match 'void setPlacedBy\(' -and $sapling -match 'prepareSapling\(level, pos, true\)') 'Normal sapling placement must initialize its own counter immediately.'
Assert-TreeRule ($sapling -match 'prepareSapling\(level, pos, false\)' -and $sapling -match 'newlyPlaced \|\| counter.getLastUpdateTick\(\) == UNINITIALIZED_TICK') 'Legacy fallback must preserve already initialized sapling age.'
Assert-TreeRule ($sapling -match 'findBaseOfTree\(level, belowPos, support\)' -and $sapling -match 'counter.setStemPos\(root\)') 'Grafted saplings must resolve and store their native tree root.'
Assert-TreeRule ($sapling -match 'public void createTree\(' -and $sapling -match 'super.createTree\(level, pos, state, random, ticksToAdd, stemPos\)' -and
    $sapling -match 'branch.increaseCounter\(Math.max\(0L, ticksToAdd\)\)' -and $sapling -notmatch 'getTicksSinceUpdate\(\) - getTicksToGrow\(\)') 'Branch transition must consume the native remaining-time argument exactly once.'
Assert-TreeRule ($item -notmatch 'ticks\s*/\s*24000' -and $item -match 'Math.min\(ticks, Integer.MAX_VALUE\)') 'Growth tooltip interface expects ticks, not days.'
Assert-TreeRule ($source -match '\(\(FruitTreeSaplingBlock\) b\).getTicksToGrow\(\)') 'Sapling tooltip must use the configured growth threshold.'
Assert-TreeRule ($growing -match '!state.getValue\(NATURAL\)' -and $growing -match 'be.resetCounter\(\)' -and $growing -match 'super.randomTick') 'Cultivated branch climate pause/native delegation was removed.'
$naturalTick = [regex]::Match($growing, '(?s)public void tick\(.*?super\.tick\(state, level, pos, random\);').Value
Assert-TreeRule ($naturalTick -match 'state.getValue\(NATURAL\)' -and $naturalTick -match 'counter.getLastUpdateTick\(\) == UNINITIALIZED_TICK' -and
    $naturalTick -match 'counter.resetCounter\(\);\s*counter.increaseCounter\(NATURAL_INITIAL_TICKS\)' -and
    $growing -match 'UNINITIALIZED_TICK = Integer.MIN_VALUE' -and $growing -match 'NATURAL_INITIAL_TICKS = 7_200_000L') 'Natural scheduled growth needs a finite initial age only for the uninitialized sentinel.'
Assert-TreeRule ($growing -notmatch '(?m)^\s*TickingPlantBlockEntity\.(reset|addTicks|setStemPos)\(') 'Tree bridge must use project entity instances, not native typed helpers.'
Assert-TreeRule ($leaves -match 'super.animateTick\(state, level, pos, random\)' -and $leaves -match 'Lifecycle.FLOWERING' -and $leaves -match 'state.is\(BUZZING_LEAVES\)') 'Native leaf effects and tagged flowering gate must be retained.'
Assert-TreeRule ($leaves -match 'MySeasonalPlantFix.afterUse' -and $seasonal -match 'result.consumesAction\(\)' -and $seasonal -match 'be.resetLastPickedCounter\(\)') 'Successful harvest must update its own entity pick counter.'
Assert-TreeRule ($entities -match 'new TickingPlantBlockEntity\(MyBlockEntities.TICK_COUNTING_PLANT.get\(\), pos, state\)' -and
    $entities -match 'MyFruitTrees.tickingBlocks\(\)' -and $entities -match 'MyFruitTrees.fruitingBlocks\(\)' -and $berry -match 'super\(MyBlockEntities.BERRY_BUSH.get\(\), pos, state\)') 'Saved tree entities must recreate valid project types.'
foreach ($rule in @('new MyFruitTreeSaplingBlock\(saplingProps\(\)', 'new MyGrowingFruitTreeBranchBlock\(growingProps\(\)',
    'new MyFruitTreeLeavesBlock\(leavesProps\(\)', 'SAPLINGS.values\(\)', 'GROWING_BRANCHES.values\(\)', 'LEAVES.values\(\)')) {
    Assert-TreeRule ($source -match $rule) "Missing tree factory/valid-host wiring: $rule"
}
$guides = @{}; foreach ($lang in @('zh_cn','en_us')) { $guides[$lang]=Read-TreeResource "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/fruit_trees.json" }
$tags = @{}; foreach ($kind in @('branches','leaves','saplings')) { $tags[$kind]=Read-TreeResource "data/tfc/tags/block/fruit_tree_$kind.json" }
$worldTrees = Read-TreeResource 'data/tfc/tags/worldgen/placed_feature/feature/fruit_trees.json'
Assert-TreeRule ($worldTrees.replace -eq $false) 'World tree feature tag must append rather than replace other trees.'
$foodTags = (Read-TreeResource 'data/c/tags/item/foods/fruit.json').values
$nutTagRelative = 'data/tfcfarmingplus/tags/item/foods/nuts.json'
$nutValues = @()
if (Test-Path -LiteralPath (Join-Path $resourceRoot $nutTagRelative)) {
    $nutDefinition = Read-TreeResource $nutTagRelative
    $nutValues = @($nutDefinition.values)
    $expectedNuts = @($nuts | ForEach-Object {"tfcfarmingplus:food/$_"})
    Assert-TreeRule ($nutDefinition.replace -eq $false -and $nutValues.Count -eq 5 -and
        @(Compare-Object @($nutValues | Sort-Object) @($expectedNuts | Sort-Object)).Count -eq 0) 'Nut classification must contain exactly the five reviewed products and append.'
} else { Assert-TreeRule $false 'Missing project nut classification tag.' }
$nutUseTags = @('data/c/tags/item/foods.json','data/tfc/tags/item/usable_in_soup.json','data/tfc/tags/item/usable_in_salad.json','data/tfc/tags/item/usable_in_sandwich.json')
$nutRoutesReady = $true
foreach ($relative in $nutUseTags) {
    if (Test-Path -LiteralPath (Join-Path $resourceRoot $relative)) {
        $bridge = Read-TreeResource $relative
        $validBridge = $bridge.replace -eq $false -and @($bridge.values).Count -eq 1 -and $bridge.values[0] -eq '#tfcfarmingplus:foods/nuts'
        Assert-TreeRule $validBridge "Nut food/use bridge must append only the project group: $relative"
        if (-not $validBridge) {$nutRoutesReady=$false}
    } else { Assert-TreeRule $false "Missing nut food/use bridge: $relative"; $nutRoutesReady=$false }
}
$directions = @('down','up','north','south','west','east')
$rotations = @{down=0; up=0; north=90; south=270; west=0; east=180}
$rows = New-Object 'System.Collections.Generic.List[object]'
foreach ($definition in $definitions) {
    $name = $definition.Groups['name'].Value; $detailed = $name -in $reviewed
    $group = if ($name -in $temperate) {'温带'} elseif ($name -in $tropical) {'热带'} elseif ($name -in $nuts) {'坚果'} elseif ($name -in $remaining) {'其他果树'} else {'待深入审查'}
    $species = @($manifest.trees | Where-Object { $_.name -eq $name })[0]
    $lifecycle = @($definition.Groups['life'].Value -split ',' | ForEach-Object { $_.Trim() })
    Assert-TreeRule ($lifecycle.Count -eq 12 -and @($lifecycle | Where-Object { $_ -notin @('DORMANT','HEALTHY','FLOWERING','FRUITING') }).Count -eq 0) "Invalid lifecycle: $name"
    $climate = Read-TreeResource "data/tfcfarmingplus/tfc/climate_range/plant/${name}_tree.json"
    $climateMatches = $climate.min_temperature -eq [int]$definition.Groups['min'].Value -and $climate.max_temperature -eq [int]$definition.Groups['max'].Value -and
        $species.minT -eq $climate.min_temperature -and $species.maxT -eq $climate.max_temperature
    if ($detailed) { Assert-TreeRule $climateMatches "Source/manifest/climate mismatch: $name" }
    elseif (-not $climateMatches) { $deferred.Add("$name : source/manifest/climate differ; outside the reviewed temperate/tropical/nut groups; requires its own compatibility review") }
    $directionCases=0; $stateSpace=0; $worldChecked=$false
    if ($detailed) {
        $saplingId="tfcfarmingplus:plant/${name}_sapling"; $fruit="tfcfarmingplus:food/$name"
        $state=Read-TreeResource "assets/tfcfarmingplus/blockstates/plant/${name}_sapling.json"
        foreach ($count in 1..4) {
            $model=Resolve-TreeVariant $state @{saplings=[string]$count}
            Assert-TreeRule ($model -eq "tfcfarmingplus:block/plant/${name}_sapling_$count") "Wrong sapling model: $name/$count"
        }
        $state=Read-TreeResource "assets/tfcfarmingplus/blockstates/plant/${name}_leaves.json"
        foreach ($phase in @('dormant','healthy','flowering','fruiting')) { foreach ($persistent in @('false','true')) { foreach ($fluid in @('empty','water')) {
            $model=Resolve-TreeVariant $state @{lifecycle=$phase; persistent=$persistent; fluid=$fluid}
            $suffix = switch ($phase) { dormant {'dry_leaves'}; healthy {'leaves'}; default {"${phase}_leaves"} }
            Assert-TreeRule ($model -eq "tfcfarmingplus:block/plant/${name}_$suffix") "Wrong leaf model: $name/$phase/$persistent/$fluid"
        } } }
        foreach ($part in @('branch','growing_branch')) {
            $state=Read-TreeResource "assets/tfcfarmingplus/blockstates/plant/${name}_$part.json"
            Assert-TreeRule (@($state.multipart).Count -eq 7) "Expected core plus six connection models: $name/$part"
            # Only direction keys are allowed. Omitted stage/saplings/natural are
            # wildcards; the 64 direction evaluations therefore cover all their values.
            foreach ($node in $state.multipart) { foreach ($key in $node.when.PSObject.Properties.Name) {
                if ($key -and $key -notin $directions) { throw "Unreviewed branch selector: $name/$part/$key" }
            } }
            foreach ($mask in 0..63) {
                $values=@{}; foreach ($i in 0..5) { $values[$directions[$i]] = [bool]($mask -band (1 -shl $i)) }
                $actual=@()
                foreach ($node in $state.multipart) {
                    $include=$true
                    foreach ($condition in $node.when.PSObject.Properties) { if ([string]$values[$condition.Name] -ine [string]$condition.Value) { $include=$false } }
                    if ($include) { $actual += "$($node.apply.model)@$([int]$node.apply.y)" }
                }
                $expected=@("tfcfarmingplus:block/plant/${name}_branch_core@0")
                foreach ($direction in $directions) { if ($values[$direction]) {
                    $suffix = if ($direction -in @('down','up')) {$direction} else {'side'}
                    $expected += "tfcfarmingplus:block/plant/${name}_branch_$suffix@$($rotations[$direction])"
                } }
                Assert-TreeRule (@(Compare-Object @($actual|Sort-Object) @($expected|Sort-Object)).Count -eq 0) "Branch connection model mismatch: $name/$part/$mask"
                $directionCases++
            }
        }
        $stateSpace = 4 + 16 + 64*4 + 64*4*4*2
        foreach ($binding in @(@('saplings',$saplingId),@('leaves',"tfcfarmingplus:plant/${name}_leaves"),@('branches',"tfcfarmingplus:plant/${name}_branch"),@('branches',"tfcfarmingplus:plant/${name}_growing_branch"))) {
            Assert-TreeRule ($binding[1] -in $tags[$binding[0]].values) "Missing native tree block tag: $($binding[1])"
        }
        $configured=Read-TreeResource "data/tfcfarmingplus/worldgen/configured_feature/plant/${name}_tree.json"
        $placed=Read-TreeResource "data/tfcfarmingplus/worldgen/placed_feature/plant/${name}_tree.json"
        Assert-TreeRule ($configured.type -eq 'tfc:fruit_trees' -and $configured.config.state -eq "tfcfarmingplus:plant/${name}_growing_branch") "Natural feature must create the registered growth branch: $name"
        Assert-TreeRule ($placed.feature -eq "tfcfarmingplus:plant/${name}_tree" -and "tfcfarmingplus:plant/${name}_tree" -in $worldTrees.values) "Natural tree placed-feature/tag entry missing: $name"
        $filter=@($placed.placement | Where-Object {$_.type -eq 'tfc:climate'})
        Assert-TreeRule ($filter.Count -eq 1 -and $filter[0].min_temperature -eq $climate.min_temperature -and $filter[0].max_temperature -eq $climate.max_temperature -and
            $filter[0].min_groundwater -eq 100 -and $filter[0].max_groundwater -eq 400 -and $filter[0].max_forest -eq 3) "Tree world climate filter differs from reviewed range: $name"
        $height=@($placed.placement | Where-Object {$_.type -eq 'minecraft:heightmap'})
        $rarity=@($placed.placement | Where-Object {$_.type -eq 'minecraft:rarity_filter'})
        Assert-TreeRule ($height.Count -eq 1 -and $height[0].heightmap -eq 'WORLD_SURFACE_WG' -and $rarity.Count -eq 1 -and $rarity[0].chance -eq 60 -and
            @($placed.placement | Where-Object {$_.type -eq 'minecraft:in_square'}).Count -eq 1) "Tree surface/rarity placement contract changed: $name"
        $worldChecked=$true
        $food=Read-TreeResource "data/tfcfarmingplus/tfc/food/$name.json"
        if ($name -in $nuts) {
            Assert-TreeRule ($food.ingredient.item -eq $fruit -and $food.hunger -eq 4 -and $food.protein -eq 1.5 -and
                [double]$food.fruit -eq 0 -and $food.saturation -eq 0.5 -and $food.decay_modifier -eq $species.decay -and
                $fruit -in $nutValues -and $fruit -notin $foodTags) "Nut protein food/classification mismatch: $name"
        } else {
            Assert-TreeRule ($food.ingredient.item -eq $fruit -and $food.hunger -gt 0 -and $food.fruit -gt 0 -and $food.decay_modifier -gt 0 -and $fruit -in $foodTags) "Fruit food/classification mismatch: $name"
        }
        $planter=Read-TreeResource "data/firmalife/firmalife/plantable/fpt_$name.json"
        Assert-TreeRule ($planter.ingredient.item -eq $saplingId -and $planter.seed.id -eq $saplingId -and $planter.crop.id -eq $fruit -and $planter.planter -eq 'bonsai') "Planter input/output mismatch: $name"
        foreach ($part in @('sapling','leaves','branch','growing_branch')) {
            $loot=Read-TreeResource "data/tfcfarmingplus/loot_table/blocks/plant/${name}_$part.json"
            foreach ($condition in @(Get-TreeObjects $loot | Where-Object {$_.condition -eq 'minecraft:block_state_property'})) {
                Assert-TreeRule ($condition.block -eq "tfcfarmingplus:plant/${name}_$part") "Wrong tree loot block condition: $name/$part"
            }
        }
        $leafLoot=Read-TreeResource "data/tfcfarmingplus/loot_table/blocks/plant/${name}_leaves.json"
        $fruitEntry=@(Get-TreeObjects $leafLoot | Where-Object {$_.type -eq 'minecraft:item' -and $_.name -eq $fruit})
        Assert-TreeRule ($fruitEntry.Count -eq 1 -and $fruitEntry[0].conditions[0].properties.lifecycle -eq 'fruiting') "Fruit harvest must require fruiting leaves: $name"
        $templateLife=[regex]::Match($template, ('(?m)^\s*'+[regex]::Escape($name)+'\s*=\s*@\(([^\r\n]+)\)')).Groups[1].Value
        $templateMonths=@([regex]::Matches($templateLife,"'([A-Z]+)'" )|ForEach-Object {$_.Groups[1].Value})
        Assert-TreeRule (($templateMonths -join ',') -ceq ($lifecycle -join ',')) "Guide lifecycle template drift: $name"
        foreach ($lang in @('zh_cn','en_us')) {
            $page=@($guides[$lang].pages | Where-Object {$_.anchor -eq $name})
            $required=if ($lang -eq 'zh_cn') {@('物品提示','活动月份','右键','冷却','南半球')} else {@('tooltip','active month','Right-click','cooldown','south')}
            if ($name -in $nuts) {
                $required += $(if ($lang -eq 'zh_cn') {@('蛋白质','汤','沙拉','三明治','未腐烂')} else {@('protein','soup','salad','sandwich','fresh')})
            }
            Assert-TreeRule ($page.Count -eq 1) "Missing tree guide anchor: $name/$lang"
            foreach ($word in $required) { Assert-TreeRule ($page[0].text -match [regex]::Escape($word)) "Missing tree guidance: $name/$lang/$word" }
            $flower=@();$fruitMonths=@()
            foreach ($i in 0..11) {if ($lifecycle[$i] -eq 'FLOWERING') {$flower += [string]($i+1)};if ($lifecycle[$i] -eq 'FRUITING') {$fruitMonths += [string]($i+1)}}
            $period = if ($lang -eq 'zh_cn') { '北半球开花月：'+($flower -join '、')+'；结果月：'+($fruitMonths -join '、')+'。' }
                else {'Northern flowering months: '+($flower -join ', ')+'; fruiting months: '+($fruitMonths -join ', ')+'.'}
            Assert-TreeRule ($page[0].text.Contains($period)) "Guide months differ from runtime lifecycle: $name/$lang"
        }
    }
    $rows.Add([pscustomobject][ordered]@{
        Name=$name; ChineseName=$species.zh; Group=$group; Detailed=$detailed; RuntimeVerified=$false
        WorldGenerationChecked=$worldChecked; NaturalInitialTicks=7200000
        FoodNutrition=$(if ($name -in $nuts) {'protein 1.5; hunger 4; saturation 0.5'} elseif ($detailed) {'fruit'} else {'待深入核对'})
        Processing=$(if ($name -in $nuts) {if ($nutRoutesReady -and "tfcfarmingplus:food/$name" -in $nutValues) {'可直接食用；原生汤/沙拉/三明治标签静态接通，实机待验'} else {'坚果用途标签未接通'}} else {'参照所属切片，未在本项核对全部加工'})
        Sapling="tfcfarmingplus:plant/${name}_sapling"; Leaves="tfcfarmingplus:plant/${name}_leaves"
        GrowthBranch="tfcfarmingplus:plant/${name}_growing_branch"; Branch="tfcfarmingplus:plant/${name}_branch"
        Lifecycle=($lifecycle -join ','); Temperature="$($climate.min_temperature)..$($climate.max_temperature)"; ClimateConsistent=$climateMatches
        Hydration=$(if ($null -eq $climate.min_hydration -and $null -eq $climate.max_hydration) {'沿用TFC气候范围默认水合边界'} else {"$($climate.min_hydration)..$($climate.max_hydration)"})
        DirectionCases=$directionCases; RepresentedBlockStates=$stateSpace
        Harvest=$(if ($detailed) {'结果期右键树叶采果；采后恢复健康态并重置原生开花冷却'} else {'基础登记；物种专有流程待后续切片'})
        Growth=$(if ($detailed) {'正常种植即计时；嫁接根定位；转枝按TFC剩余tick结转；自然未初始化枝补有限初值；枝叶与物候沿用TFC'} else {'共享接线随本批修正；物种专有流程待深查'})
        Scope=$(if ($detailed) {$group+'深入静态核对；实机待验证'} else {'仅注册/物候/气候基础核对；未完成深入审查'})
    })
}
$dependency=@(Get-ChildItem -LiteralPath (Join-Path $instance 'mods') -File -Filter 'TerraFirmaCraft-NeoForge-*.jar')
if ($dependency.Count -ne 1) {throw 'Expected one installed TFC jar.'}
$report=[ordered]@{
    Total=$rows.Count; Detailed=@($rows|Where-Object {$_.Detailed}).Count
    TemperateDetailed=@($rows|Where-Object {$_.Detailed -and $_.Group -eq '温带'}).Count
    TropicalDetailed=@($rows|Where-Object {$_.Detailed -and $_.Group -eq '热带'}).Count
    NutDetailed=@($rows|Where-Object {$_.Detailed -and $_.Group -eq '坚果'}).Count
    RemainingFruitDetailed=@($rows|Where-Object {$_.Detailed -and $_.Group -eq '其他果树'}).Count
    NutFoodRoutesReady=$nutRoutesReady
    WorldGenerationChecked=@($rows|Where-Object {$_.WorldGenerationChecked}).Count
    DirectionCases=($rows|Measure-Object -Property DirectionCases -Sum).Sum
    RepresentedBlockStates=($rows|Measure-Object -Property RepresentedBlockStates -Sum).Sum
    SourceSha256=(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    ManifestSha256=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
    TfcJar=$dependency[0].Name; TfcSha256=(Get-FileHash -LiteralPath $dependency[0].FullName -Algorithm SHA256).Hash
    ModuleDirectory=$module; ResourceRoot=$resourceRoot; Findings=$errors.ToArray(); DeferredFindings=$deferred.ToArray(); Trees=$rows.ToArray()
}
if ($ReportDirectory) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'tree-contracts.json'),($report|ConvertTo-Json -Depth 25),[Text.UTF8Encoding]::new($false))
    $csv=$rows|Select-Object @{n='树种';e={$_.ChineseName}},@{n='编号';e={$_.Name}},@{n='分组';e={$_.Group}},@{n='生成静态接线';e={$_.WorldGenerationChecked}},@{n='深入核对';e={$_.Detailed}},@{n='实机确认';e={$_.RuntimeVerified}},
        @{n='温度';e={$_.Temperature}},@{n='温度数据一致';e={$_.ClimateConsistent}},@{n='水合';e={$_.Hydration}},@{n='一至十二月物候';e={$_.Lifecycle}},@{n='方向模型核对';e={$_.DirectionCases}},
        @{n='覆盖方块状态';e={$_.RepresentedBlockStates}},@{n='树苗';e={$_.Sapling}},@{n='生长枝';e={$_.GrowthBranch}},@{n='成熟枝';e={$_.Branch}},
        @{n='树叶';e={$_.Leaves}},@{n='采收';e={$_.Harvest}},@{n='生长';e={$_.Growth}},@{n='食品营养';e={$_.FoodNutrition}},@{n='加工用途';e={$_.Processing}},@{n='范围';e={$_.Scope}}|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'tree-contracts.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output ("[INFO] trees={0}; detailed={1}; direction cases={2}; represented block states={3}; findings={4}" -f $report.Total,$report.Detailed,$report.DirectionCases,$report.RepresentedBlockStates,$errors.Count)
$deferred | ForEach-Object { Write-Output "[DEFERRED] $_" }
if ($errors.Count) {$errors|ForEach-Object {Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] tree source/resource contracts checked; runtime gameplay remains unverified'
exit 0
