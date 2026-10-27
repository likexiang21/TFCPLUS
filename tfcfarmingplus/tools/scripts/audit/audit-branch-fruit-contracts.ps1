param([string]$ReportDirectory='', [string]$Resources='', [string]$ModuleDirectory='')
# Read-only source/resource contracts; no simulated ticks or gameplay.
$ErrorActionPreference='Stop'
$live=Split-Path $env:TFC_TOOLS_ROOT -Parent
$module=if($ModuleDirectory){(Resolve-Path -LiteralPath $ModuleDirectory).Path}else{$live}
$res=if($Resources){(Resolve-Path -LiteralPath $Resources).Path}else{Join-Path $module 'src/main/resources'}
$common=Join-Path $module 'src/main/java/io/github/likexiang21/tfcplus/farming/common'
$errors=New-Object 'System.Collections.Generic.List[string]'
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Read-Data([string]$relative){$p=Join-Path $res $relative;if(-not(Test-Path -LiteralPath $p)){throw "Missing resource: $relative"};Get-Content -LiteralPath $p -Raw -Encoding UTF8|ConvertFrom-Json}
$trunkSpecies=@('jabuticaba','soursop','mangosteen','cupuacu','bael','canistel','black_pepper')
$trees=Get-Content -LiteralPath (Join-Path $common 'tree\FarmingFruitTrees.java') -Raw -Encoding UTF8
$branches=Get-Content -LiteralPath (Join-Path $common 'tree\FarmingBranchFruits.java') -Raw -Encoding UTF8
$code=Get-Content -LiteralPath (Join-Path $common 'block/FarmingFruitingBranchBlock.java') -Raw -Encoding UTF8
$growing=Get-Content -LiteralPath (Join-Path $common 'block/FarmingGrowingFruitTreeBranchBlock.java') -Raw -Encoding UTF8
$manifest=Get-Content -LiteralPath (Join-Path $module 'tools/contracts/fruit-trees-manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
Check ($code -match 'SolarCalculator.getInNorthernHemisphere\(root, level\)' -and $code -notmatch 'getHemispheralCalendarMonthOfYear\(true\)') 'Branch seasons must follow the actual hemisphere.'
Check ($code -match 'checkBoth\(FarmingGrowingFruitTreeBranchBlock.rootHydration' -and $growing -match 'return getFruitBranchHydration\(level, pos\)') 'Branch fruit needs native root hydration and temperature.'
Check ($growing -match 'super.grow\(state, level, pos, random, cyclesLeft\)' -and $growing -match 'mature.setStemPos\(root\)' -and $growing -match 'mature.getLastUpdateTick\(\) == UNINITIALIZED_TICK') 'Mature branch transition must preserve root and initialize the project counter.'
Check ($code -match 'depth < 64' -and $code -match 'level.hasChunkAt\(below\)' -and $code -match 'counter.getStemPos\(\).equals\(pos\)') 'Legacy root repair must be bounded and preserve explicit roots.'
Check ($code -match 'counter.getLastUpdateTick\(\) == UNINITIALIZED_TICK' -and $code -match 'Math.min\(2 - current.ordinal\(\), elapsed / interval\)' -and $code -match 'counter.setLastUpdateTick\(counter.getLastUpdateTick\(\) \+ steps \* interval\)') 'Fruit stages need sentinel recovery, bounded elapsed stages and fractional time.'
$harvest=$code.Substring($code.IndexOf('protected ItemInteractionResult useItemOn'))
Check ($harvest -match '(?:now|currentState).getValue\(FRUIT\) != FruitState.RIPE' -and $harvest.IndexOf('if (!level.setBlock') -ge 0 -and $harvest.IndexOf('if (!level.setBlock') -lt $harvest.IndexOf('giveItemToPlayer') -and $harvest -match 'counter.resetLastPickedCounter\(\)') 'Harvest must commit fruit removal before reward and reset the instance counters.'
Check ($code -match 'defaultBlockState\(\).setValue\(FRUIT, FruitState.NONE\)') 'Trunk fruit default must explicitly be none.'
$fruits=(Read-Data 'data/c/tags/item/foods/fruit.json').values
$world=(Read-Data 'data/tfc/tags/worldgen/placed_feature/feature/fruit_trees.json').values
$books=@{};foreach($lang in @('zh_cn','en_us')){$books[$lang]=Read-Data "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/fruit_trees.json"}
$dirs=@('down','up','north','south','west','east');$rot=@{down=0;up=0;north=90;south=270;west=0;east=180}
$rows=New-Object 'System.Collections.Generic.List[object]'
foreach($n in @($trunkSpecies)+@('cocoa')){
    $legacy=$n -eq 'cocoa';$product=if($n -in @('cupuacu','cocoa')){'firmalife:food/cocoa_beans'}else{"tfcfarmingplus:food/$n"}
    $d=@($manifest.trees|Where-Object{$_.name -eq $n})[0]
    $match=[regex]::Match($trees,('(?s)new FruitTreeDefinition\("'+$n+'".*?new Lifecycle\[\]\{([^}]+)\},\s*0x[0-9A-Fa-f]+,\s*(-?\d+),\s*(-?\d+)\)'))
    $leafLife=@($match.Groups[1].Value -split ','|ForEach-Object{$_.Trim()})
    Check ($leafLife.Count -eq 12 -and 'FRUITING' -notin $leafLife) "Normal branch-fruit leaves must not produce fruit: $n"
    $life=if($legacy){@()}else{@([regex]::Matches([regex]::Match($branches,('(?s)"'+$n+'", new Lifecycle\[\]\{([^}]+)\}')).Groups[1].Value,'Lifecycle\.([A-Z]+)')|ForEach-Object{$_.Groups[1].Value})}
    if(-not $legacy){Check ($life.Count -eq 12 -and 'FRUITING' -in $life) "Missing trunk calendar: $n"}
    $cl=Read-Data "data/tfcfarmingplus/tfc/climate_range/plant/${n}_tree.json"
    Check ($cl.min_temperature -eq [int]$match.Groups[2].Value -and $cl.max_temperature -eq [int]$match.Groups[3].Value -and $d.minT -eq $cl.min_temperature -and $d.maxT -eq $cl.max_temperature) "Tree climate declarations disagree: $n"
    $sapling=Read-Data "assets/tfcfarmingplus/blockstates/plant/${n}_sapling.json"
    foreach($i in 1..4){Check ($sapling.variants."saplings=$i".model -eq "tfcfarmingplus:block/plant/${n}_sapling_$i") "Sapling model: $n/$i"}
    $leaf=Read-Data "assets/tfcfarmingplus/blockstates/plant/${n}_leaves.json"
    foreach($phase in @('dormant','healthy','flowering','fruiting')){
        $selected=@($leaf.variants.PSObject.Properties|Where-Object{$_.Name -eq "lifecycle=$phase"})
        $suffix=switch($phase){dormant{'dry_leaves'};healthy{'leaves'};default{"${phase}_leaves"}}
        Check ($selected.Count -eq 1 -and $selected[0].Value.model -eq "tfcfarmingplus:block/plant/${n}_$suffix") "Leaf lifecycle model: $n/$phase"
    }
    $cases=0
    foreach($part in @('branch','growing_branch')){
        $definition=Read-Data "assets/tfcfarmingplus/blockstates/plant/${n}_$part.json"
        $hasFruit=$part -eq 'branch' -and -not $legacy
        Check (@($definition.multipart).Count -eq $(if($hasFruit){9}else{7})) "Branch model parts: $n/$part"
        foreach($node in $definition.multipart){foreach($key in $node.when.PSObject.Properties.Name){if($key -and $key -notin @($dirs)+@('fruit')){throw "Unreviewed model selector: $key"}}}
        $phases=if($hasFruit){@('none','unripe','ripe')}else{@('none')}
        foreach($phase in $phases){foreach($mask in 0..63){
            $values=@{fruit=$phase};foreach($i in 0..5){$values[$dirs[$i]]=[bool]($mask -band (1 -shl $i))}
            $actual=@();foreach($node in $definition.multipart){$include=$true;foreach($c in $node.when.PSObject.Properties){if([string]$values[$c.Name] -ine [string]$c.Value){$include=$false}};if($include){$actual+="$($node.apply.model)@$([int]$node.apply.y)"}}
            $expected=@("tfcfarmingplus:block/plant/${n}_branch_core@0")
            foreach($dir in $dirs){if($values[$dir]){$suffix=if($dir -in @('up','down')){$dir}else{'side'};$expected+="tfcfarmingplus:block/plant/${n}_branch_$suffix@$($rot[$dir])"}}
            if($hasFruit -and $phase -ne 'none'){$expected+="tfcfarmingplus:block/plant/${n}_branch_fruit_$phase@0"}
            Check (@(Compare-Object @($expected|Sort-Object) @($actual|Sort-Object)).Count -eq 0) "Branch selection mismatch: $n/$part/$phase/$mask"
            $cases++
        }}
    }
    if(-not $legacy){
        $loot=Read-Data "data/tfcfarmingplus/loot_table/blocks/plant/${n}_branch.json"
        $extension=@($loot.pools|Where-Object{$_.name -eq 'tfcfarmingplus_branch_fruit'})
        Check ($extension.Count -eq 1 -and @($loot.pools).Count -eq 3) "Missing reviewed ripe-fruit pool: $n"
        if($extension.Count -eq 1){$e=$extension[0];Check ($e.rolls -eq 1 -and @($e.entries).Count -eq 1 -and $e.entries[0].name -eq $product -and @($e.conditions).Count -eq 2 -and $e.conditions[0].condition -eq 'minecraft:survives_explosion' -and $e.conditions[1].block -eq "tfcfarmingplus:plant/${n}_branch" -and $e.conditions[1].properties.fruit -eq 'ripe') "Ripe-fruit drop contract mismatch: $n"}
        if($extension.Count -eq 1){
            $e=$extension[0]
            Check (@($e.PSObject.Properties).Count -eq 4 -and @($e.entries[0].PSObject.Properties).Count -eq 2 -and
                $e.entries[0].type -eq 'minecraft:item' -and $e.conditions[1].condition -eq 'minecraft:block_state_property' -and
                @($e.conditions[1].properties.PSObject.Properties).Count -eq 1) "Unexpected modifiers or conditions in ripe drop: $n"
        }
        if($n -notin @('cupuacu','black_pepper')){$food=Read-Data "data/tfcfarmingplus/tfc/food/$n.json";Check ($food.ingredient.item -eq $product -and $food.fruit -gt 0 -and $product -in $fruits) "Trunk fruit food/use classification: $n"}
        $planter=Read-Data "data/firmalife/firmalife/plantable/fpt_$n.json"
        Check ($planter.crop.id -eq $product -and $planter.ingredient.item -eq "tfcfarmingplus:plant/${n}_sapling") "Trunk fruit planter mismatch: $n"
        $feature=Read-Data "data/tfcfarmingplus/worldgen/configured_feature/plant/${n}_tree.json"
        Check ($feature.type -eq 'tfc:fruit_trees' -and $feature.config.state -eq "tfcfarmingplus:plant/${n}_growing_branch" -and "tfcfarmingplus:plant/${n}_tree" -in $world) "Trunk tree generation path: $n"
        $placed=Read-Data "data/tfcfarmingplus/worldgen/placed_feature/plant/${n}_tree.json"
        $filter=@($placed.placement|Where-Object{$_.type -eq 'tfc:climate'})
        Check ($placed.feature -eq "tfcfarmingplus:plant/${n}_tree" -and $filter.Count -eq 1 -and $filter[0].min_temperature -eq $cl.min_temperature -and $filter[0].max_temperature -eq $cl.max_temperature -and $filter[0].min_groundwater -eq 100 -and $filter[0].max_groundwater -eq 400 -and $filter[0].max_forest -eq 3) "Trunk placement climate mismatch: $n"
        Check (@($placed.placement|Where-Object{$_.type -eq 'minecraft:heightmap' -and $_.heightmap -eq 'WORLD_SURFACE_WG'}).Count -eq 1 -and @($placed.placement|Where-Object{$_.type -eq 'minecraft:rarity_filter' -and $_.chance -eq 60}).Count -eq 1 -and @($placed.placement|Where-Object{$_.type -eq 'minecraft:in_square'}).Count -eq 1) "Trunk surface/rarity placement changed: $n"
        foreach($binding in @(@('saplings',"${n}_sapling"),@('leaves',"${n}_leaves"),@('branches',"${n}_branch"),@('branches',"${n}_growing_branch"))){
            $tag=Read-Data "data/tfc/tags/block/fruit_tree_$($binding[0]).json"
            Check ("tfcfarmingplus:plant/$($binding[1])" -in $tag.values) "Trunk native tag binding missing: $n/$($binding[0])"
        }
        Check ($planter.planter -eq 'bonsai' -and $planter.seed.id -eq "tfcfarmingplus:plant/${n}_sapling") "Trunk planter seed/type mismatch: $n"
        foreach($lang in @('zh_cn','en_us')){
            $page=@($books[$lang].pages|Where-Object{$_.anchor -eq $n});Check ($page.Count -eq 1) "Guide missing: $n/$lang"
            $keywords=if($lang -eq 'zh_cn'){@('物品提示','根部温湿度','两阶段','余量','成熟后右键','南半球')}else{@('tooltip','Root climate','two stages','fractional','Right-click','south')}
            foreach($word in $keywords){Check ($page[0].text.Contains($word)) "Guide behavior missing: $n/$lang/$word"}
            $fl=@();$fr=@();foreach($i in 0..11){if($life[$i] -eq 'FLOWERING'){$fl+=[string]($i+1)};if($life[$i] -eq 'FRUITING'){$fr+=[string]($i+1)}}
            $period=if($lang -eq 'zh_cn'){'北半球枝干开花月：'+($fl -join '、')+'；结果月：'+($fr -join '、')+'。'}else{'Northern trunk flowering months: '+($fl -join ', ')+'; fruiting months: '+($fr -join ', ')+'.'}
            Check ($page[0].text.Contains($period)) "Guide trunk months differ: $n/$lang"
        }
    }else{
        Check ('tfcfarmingplus:plant/cocoa_tree' -notin $world) 'Legacy cocoa must remain excluded from natural generation.'
        foreach($lang in @('zh_cn','en_us')){Check (@($books[$lang].pages|Where-Object{$_.anchor -eq 'cocoa'}).Count -eq 0) 'Legacy cocoa guide must remain hidden.'}
        Check ($trees -match 'legacyCocoa \? \(\) -> BRANCHES.get\("cupuacu"\)' -and $trees -match 'legacyCocoa \? \(\) -> GROWING_BRANCHES.get\("cupuacu"\)') 'Legacy cocoa continuation must target cupuacu.'
    }
    $rows.Add([pscustomobject]@{Name=$n;ChineseName=$d.zh;Legacy=$legacy;Product=$product;LeafLifecycle=($leafLife -join ',');TrunkLifecycle=($life -join ',');DirectionCases=$cases;RepresentedBlockStates=$(if($legacy){2324}else{2836});RuntimeVerified=$false})
}
# B is inspected read-only; A has no game-code dependency on B.
$instance=Split-Path (Split-Path $live -Parent) -Parent
$agriculture=Join-Path $instance 'mod_rebuild/tfcagricultureplus'
$br=Join-Path $agriculture 'src/main/resources'
$bc=Join-Path $agriculture 'src/main/java/io/github/likexiang21/tfcplus/agriculture'
$pepper='tfcfarmingplus:food/black_pepper';$powder='tfcagricultureplus:food/ground_black_pepper'
$grind=Get-Content -LiteralPath (Join-Path $br 'data/tfcagricultureplus/recipe/mortar/ground_black_pepper.json') -Raw -Encoding UTF8|ConvertFrom-Json
Check ($grind.type -eq 'tfcagricultureplus:mortar' -and $grind.ingredient.item -eq $pepper -and $grind.result.id -eq $powder -and $grind.result.count -eq 1 -and $grind.grind_time -eq 3) 'Pepper grinding declaration must be one bean to one powder, three strikes.'
$spices=Get-Content -LiteralPath (Join-Path $br 'data/tfcagricultureplus/tags/item/foods/ground_spices.json') -Raw -Encoding UTF8|ConvertFrom-Json
Check ($spices.replace -eq $false -and $powder -in $spices.values -and $pepper -notin $fruits -and $powder -notin $fruits) 'Pepper uses the spice route, not the general fruit crafting tag.'
$mortar=Get-Content -LiteralPath (Join-Path $bc 'common/interaction/MortarInteractions.java') -Raw -Encoding UTF8
$recipe=Get-Content -LiteralPath (Join-Path $bc 'common/recipe/MortarRecipe.java') -Raw -Encoding UTF8
Check ($mortar.IndexOf('FoodCapability.isRotten(mortar.getContent())') -ge 0 -and $mortar.IndexOf('FoodCapability.isRotten(mortar.getContent())') -lt $mortar.IndexOf('mortar.advanceGrinding') -and $mortar.IndexOf('mortar.advanceGrinding') -lt $mortar.IndexOf('pestle.hurtAndBreak')) 'Mortar must reject rotten inputs before progress and durability consumption.'
Check ($recipe -match 'FoodCapability.updateFoodFromPrevious\(input.item\(\), output\)' -and $recipe -match '!FoodCapability.isRotten\(input.item\(\)\)') 'Mortar food information must be inherited and rotten input refused.'
$jei=Get-Content -LiteralPath (Join-Path $bc 'compat/jei/AgricultureJeiPlugin.java') -Raw -Encoding UTF8
Check ($jei -match 'new MortarRecipeCategory\(guiHelper\)' -and $jei -match 'registration.addRecipes\(MORTAR,' -and $jei -match 'manager.getAllRecipesFor\(AgricultureRecipeTypes.MORTAR.get\(\)\)') 'Mortar JEI declaration must include all mortar recipes.'
$soup=Get-Content -LiteralPath (Join-Path $br 'data/tfcagricultureplus/recipe/crafting/seasoned_vegetable_soup.json') -Raw -Encoding UTF8|ConvertFrom-Json
Check ($soup.type -eq 'tfc:advanced_shapeless_crafting' -and $soup.ingredients[0].type -eq 'tfc:and' -and $soup.ingredients[0].children[0].tag -eq 'tfcagricultureplus:foods/seasonable_soups' -and $soup.ingredients[0].children[1].type -eq 'tfc:not_rotten' -and $soup.ingredients[0].children[2].type -eq 'tfc:lacks_trait' -and $soup.ingredients[0].children[2].trait -eq 'tfcagricultureplus:seasoned' -and $soup.ingredients[1].children[0].tag -eq 'tfcagricultureplus:foods/ground_spices' -and $soup.ingredients[1].children[1].type -eq 'tfc:not_rotten') 'Soup seasoning must use fresh soup and fresh ground spice, without repeated seasoning.'
Check (($soup.primary_ingredient|ConvertTo-Json -Depth 10 -Compress) -ceq ($soup.ingredients[0]|ConvertTo-Json -Depth 10 -Compress)) 'Seasoning primary input must be the original soup.'
Check ($soup.result.modifiers.Count -eq 2 -and $soup.result.modifiers[0].type -eq 'tfc:copy_input' -and $soup.result.modifiers[1].type -eq 'tfc:add_trait' -and $soup.result.modifiers[1].trait -eq 'tfcagricultureplus:seasoned') 'Seasoning must copy soup data before adding its trait.'
$pan=Get-Content -LiteralPath (Join-Path $br 'data/tfcagricultureplus/recipe/pan/seasoned_vegetable_pan.json') -Raw -Encoding UTF8|ConvertFrom-Json
Check ($pan.type -eq 'tfcagricultureplus:pan' -and $pan.spice.tag -eq 'tfcagricultureplus:foods/ground_spices') 'Existing seasoned pan recipe must accept the powder tag.'
foreach($lang in @('zh_cn','en_us')){
    $page=@($books[$lang].pages|Where-Object{$_.anchor -eq 'black_pepper'})[0]
    foreach($word in $(if($lang -eq 'zh_cn'){@('石臼','三次','胡椒粉','合成','未腐烂','调味')}else{@('mortar','three','powder','crafting','fresh','season')})) {Check ($page.text.Contains($word)) "Pepper processing guide missing: $lang/$word"}
}
$report=[ordered]@{Reviewed=$rows.Count;TrunkSpecies=$trunkSpecies.Count;LegacySpecies=1;DirectionCases=($rows|Measure-Object DirectionCases -Sum).Sum;RepresentedBlockStates=($rows|Measure-Object RepresentedBlockStates -Sum).Sum;Findings=$errors.ToArray();Trees=$rows.ToArray();Module=$module;RuntimeVerified=$false}
if($ReportDirectory){[void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory));[IO.File]::WriteAllText((Join-Path $ReportDirectory 'branch-fruit-contracts.json'),($report|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false));$csv=$rows|Select-Object @{n='树种';e={$_.ChineseName}},@{n='编号';e={$_.Name}},@{n='旧树兼容';e={$_.Legacy}},@{n='产物';e={$_.Product}},@{n='枝干物候';e={$_.TrunkLifecycle}},@{n='树叶物候';e={$_.LeafLifecycle}},@{n='方向组合';e={$_.DirectionCases}},@{n='覆盖状态';e={$_.RepresentedBlockStates}},@{n='实机确认';e={$_.RuntimeVerified}}|ConvertTo-Csv -NoTypeInformation;[IO.File]::WriteAllText((Join-Path $ReportDirectory 'branch-fruit-contracts.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))}
Write-Output "[INFO] trunk species=$($trunkSpecies.Count); legacy=1; model cases=$($report.DirectionCases); represented states=$($report.RepresentedBlockStates); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1};Write-Output '[OK] branch contracts checked; runtime remains unverified';exit 0
