param([string]$ModuleDirectory='', [string]$ReportDirectory='')
# Read-only declarations and source contracts; no tick simulation, game launch or asset writes.
$ErrorActionPreference='Stop'
$live=Split-Path $env:TFC_TOOLS_ROOT -Parent
$module=if($ModuleDirectory){(Resolve-Path -LiteralPath $ModuleDirectory).Path}else{$live}
$res=Join-Path $module 'src/main/resources';$common=Join-Path $module 'src/main/java/io/github/likexiang21/tfcplus/farming/common'
$errors=New-Object 'System.Collections.Generic.List[string]'
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Read-BushJson([string]$relative){Get-Content -LiteralPath (Join-Path $res $relative) -Raw -Encoding UTF8|ConvertFrom-Json}
function Code([string]$relative){Get-Content -LiteralPath (Join-Path $common $relative) -Raw -Encoding UTF8}
$names=@('lingonberry','bearberry','crowberry','bilberry','blackcurrant','redcurrant','haskap','goji','serviceberry','aronia','tea','coffee')
$donors=@('cloudberry','cloudberry','cloudberry','cloudberry','elderberry','raspberry','blueberry','blackberry','elderberry','blackberry','blueberry','elderberry')
$source=Code 'crop\FarmingBushes.java';$helper=Code 'support/SeasonalPlantTimers.java'
$be=Code 'blockentity/FarmingBerryBushBlockEntity.java';$entities=Code 'registry\FarmingBlockEntities.java';$climates=Code 'registry\FarmingClimateRanges.java';$items=Code 'registry\FarmingItems.java'
Check ($be -match 'super\(FarmingBlockEntities.BERRY_BUSH.get\(\), pos, state\)' -and $entities -match 'FarmingBushes.bushBlocks\(\)') 'Bush BE reload must use the project type and include every bush host.'
Check ($helper -match 'bush.getLastUpdateTick\(\) == Integer.MIN_VALUE' -and $helper -match 'bush.resetCounter\(\)' -and $helper -match 'bush.getStemPos\(\).equals\(pos\)' -and $helper -match 'depth < 32' -and $helper -match 'level.isLoaded' -and $helper -match 'support.getBlock\(\) != state.getBlock\(\)' -and $helper -match '!= cane.getCane\(\)') 'Missing-age/root recovery must be bounded, family-specific and preserve explicit roots.'
Check ($helper -match '!level.isClientSide\(\) && result.consumesAction\(\)' -and $helper -match 'be.resetLastPickedCounter\(\)') 'Successful harvest must reset the project picked counter.'
foreach($class in @('FarmingBerryBushBlock','FarmingSpreadingBushBlock','FarmingSpreadingCaneBlock')){
    $s=Code "block/$class.java"
    foreach($method in @('randomTick','tick')){
        $body=[regex]::Match($s,('(?s)(?:protected|public) void '+$method+'\(.*?\n    \}')).Value
        Check ($body -match 'SeasonalPlantTimers.prepareBush\(level, pos\)' -and $body.IndexOf('prepareBush') -lt $body.IndexOf("super.$method")) "Bush must initialize before native $method`: $class"
    }
    Check ($s -match 'SeasonalPlantTimers.afterUse' -and $s -match 'FarmingBlocks.DEAD_') "Native harvest/dead-state bridge missing: $class"
    if($class -ne 'FarmingSpreadingCaneBlock'){Check ($s -match 'void setPlacedBy\(' -and $s -match 'SeasonalPlantTimers.afterPlace\(level, pos\)') "Player placement counter missing: $class"}
    else {Check ($s -match 'SpreadingCaneBlock.FACING, state.getValue\(SpreadingCaneBlock.FACING\)') 'Dead cane must retain facing.'}
}
$world=Read-BushJson 'data/tfc/tags/worldgen/placed_feature/feature/berry_bushes.json'
$expected=@($names|ForEach-Object{"tfcfarmingplus:plant/${_}_bush_patch"})
Check ($world.replace -eq $false -and @($world.values).Count -eq 12 -and @(Compare-Object @($expected|Sort-Object) @($world.values|Sort-Object)).Count -eq 0 -and @($world.remove).Count -eq 1 -and $world.remove[0] -eq 'tfc:plant/strawberry_bush_patch') 'World tag must append exactly 12 project patches and remove only the native strawberry patch.'
$living=Read-BushJson 'data/tfc/tags/block/spreading_bushes/living.json';$fruit=Read-BushJson 'data/c/tags/item/foods/fruit.json'
$hoe=Read-BushJson 'data/minecraft/tags/block/mineable/hoe.json';$fox=Read-BushJson 'data/tfc/tags/block/fox_raidable.json'
$books=@{};foreach($lang in @('zh_cn','en_us')){foreach($kind in @('bushes','bushes_high')){
    $books["$lang/$kind"]=Read-BushJson "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/$kind.json"
    $book=$books["$lang/$kind"]
    Check ($book.pages.Count -eq $(if($kind -eq 'bushes'){12}else{20}) -and $book.pages[2].type -eq 'tfc:table' -and $book.pages[3].type -eq 'patchouli:empty') "Bush calendar spread changed: $lang/$kind"
    foreach($word in $(if($lang -eq 'zh_cn'){@('计时','右键','冷却','锋利','南半球','新生成')}else{@('settings','right-click','cooldown','Sharp','south','newly generated')})) {Check ($book.pages[0].text.Contains($word)) "Missing operation guidance: $lang/$kind/$word"}
}}
foreach($tool in @('gen-wild-injection.ps1','gen-dead-and-wild-bushes.ps1')){
    $template=Get-Content -LiteralPath (Join-Path $module "tools/scripts/generate/$tool") -Raw -Encoding UTF8
    Check ($template -match 'Resolve-LegacyGeneratorOutput \$OutputRoot' -and $template -match "remove = @\('tfc:plant/strawberry_bush_patch'\)") "Generator must require scratch output and retain targeted strawberry removal: $tool"
}
$template=Get-Content -LiteralPath (Join-Path $module 'tools/scripts/generate/gen-wild-injection.ps1') -Raw -Encoding UTF8
Check ($template -match 'Where-Object \{ \$_ -ne \(Read-CocoaPolicy\).legacy_tree \}') 'World generation draft must not reintroduce legacy cocoa.'
$rows=New-Object 'System.Collections.Generic.List[object]'
for($i=0;$i -lt $names.Count;$i++){
    $n=$names[$i];$high=$i -ge 4;$donor=$donors[$i];$product=if($n -eq 'tea'){'tea_leaf'}elseif($n -eq 'coffee'){'coffee_bean'}else{$n}
    $factory=if($high){'highBush'}else{'bush'}
    $lifecycleConst=if($n -eq 'tea'){'TEA_LIFECYCLE'}else{$n.ToUpperInvariant()}
    Check ($source -match ($factory+'\("'+$n+'", FarmingItems.'+$product.ToUpperInvariant()+', '+$lifecycleConst+', FarmingClimateRanges.'+$n.ToUpperInvariant()+'_BUSH')) "Bush registration/product wiring: $n"
    $life=@([regex]::Match($source,('(?s)Lifecycle\[\] '+$lifecycleConst+' = \{([^}]+)\}')).Groups[1].Value -split ','|ForEach-Object{$_.Trim()})
    Check ($life.Count -eq 12 -and 'FRUITING' -in $life) "Missing 12-month harvest calendar: $n"
    Check ($climates -match ('register\("plant/'+$n+'_bush"\)')) "Missing climate binding: $n"
    $cl=Read-BushJson "data/tfcfarmingplus/tfc/climate_range/plant/${n}_bush.json"
    $single=Read-BushJson "data/tfcfarmingplus/worldgen/configured_feature/plant/${n}_bush.json"
    if($high){Check ($single.type -eq 'tfc:spreading_bush' -and $single.config.block -eq "tfcfarmingplus:plant/${n}_bush") "Spreading world feature mismatch: $n"}
    else {Check ($single.type -eq 'minecraft:simple_block' -and $single.config.to_place.state.Name -eq "tfcfarmingplus:plant/${n}_bush" -and $single.config.to_place.state.Properties.stage -eq '0') "Stationary world feature mismatch: $n"}
    $patch=Read-BushJson "data/tfcfarmingplus/worldgen/configured_feature/plant/${n}_bush_patch.json"
    Check ($patch.type -eq 'minecraft:random_patch' -and $patch.config.feature -eq "tfcfarmingplus:plant/${n}_bush" -and $patch.config.tries -eq 4) "Bush patch feature mismatch: $n"
    $placed=Read-BushJson "data/tfcfarmingplus/worldgen/placed_feature/plant/${n}_bush.json"
    Check ($placed.feature -eq "tfcfarmingplus:plant/${n}_bush" -and @($placed.placement|Where-Object{$_.predicate.type -eq 'would_survive' -and $_.predicate.state.Name -eq "tfcfarmingplus:plant/${n}_bush"}).Count -eq 1) "Wild placement survival missing: $n"
    $placed=Read-BushJson "data/tfcfarmingplus/worldgen/placed_feature/plant/${n}_bush_patch.json"
    $climate=@($placed.placement|Where-Object{$_.type -eq 'tfc:climate'})
    Check ($placed.feature -eq "tfcfarmingplus:plant/${n}_bush_patch" -and $climate.Count -eq 1 -and $climate[0].min_temperature -eq $cl.min_temperature -and $climate[0].max_temperature -eq $cl.max_temperature -and $climate[0].min_groundwater -eq $cl.min_hydration*4 -and $climate[0].max_groundwater -eq $cl.max_hydration*4) "Wild climate/hydration mismatch: $n"
    $parts=if($high){@('bush','bush_cane')}else{@('bush')};$cases=0
    foreach($part in $parts){
        $state=Read-BushJson "assets/tfcfarmingplus/blockstates/plant/${n}_$part.json"
        Check (@($state.variants.PSObject.Properties).Count -eq $(if($part -eq 'bush'){12}else{48})) "Bush state count mismatch: $n/$part"
        foreach($phase in @('healthy','dormant','flowering','fruiting')){foreach($stage in 0..2){foreach($dir in $(if($part -eq 'bush'){@('')}else{@('north','east','south','west')})){
            $key=if($dir){"lifecycle=$phase,facing=$dir,stage=$stage"}else{"lifecycle=$phase,stage=$stage"}
            $value=$state.variants.$key;$prefix=if($phase -eq 'healthy'){''}elseif($phase -eq 'dormant'){'dry_'}else{"${phase}_"};$suffix=if($dir){"side_$stage"}else{[string]$stage}
            Check ($value.model -eq "tfc:block/plant/${prefix}${donor}_bush_$suffix" -and [int]$value.y -eq $(switch($dir){east{90};south{180};west{270};default{0}})) "Bush model selection mismatch: $n/$part/$key";$cases++
        }}}
        Check ("tfcfarmingplus:plant/${n}_$part" -in $hoe.values) "Missing hoe tag: $n/$part"
        if($high){Check ("tfcfarmingplus:plant/${n}_$part" -in $living.values) "Missing living spreading tag: $n/$part"}
        $loot=Read-BushJson "data/tfcfarmingplus/loot_table/blocks/plant/${n}_$part.json"
        if($part -eq 'bush_cane'){Check ($loot.pools[0].entries[0].name -eq 'minecraft:stick' -and $loot.pools.Count -eq 1) "Cane must preserve native stick-only removal: $n"}
        else {Check (($loot|ConvertTo-Json -Depth 30 -Compress).Contains('#tfc:tools/sharp') -and ($loot|ConvertTo-Json -Depth 30 -Compress).Contains("tfcfarmingplus:plant/${n}_bush")) "Bush sharp-tool recovery missing: $n"}
    }
    Check ("tfcfarmingplus:plant/${n}_bush" -in $fox.values) "Missing fox interaction tag: $n"
    $food=Read-BushJson "data/tfcfarmingplus/tfc/food/$product.json"
    Check ($food.ingredient.item -eq "tfcfarmingplus:food/$product" -and $food.hunger -gt 0 -and $food.decay_modifier -gt 0) "Bush food definition/use missing: $n"
    if($n -notin @('tea','coffee')){Check ("tfcfarmingplus:food/$product" -in $fruit.values) "Berry fruit classification missing: $n"}
    $planter=Read-BushJson "data/firmalife/firmalife/plantable/$n.json"
    Check ($planter.ingredient.item -eq "tfcfarmingplus:plant/${n}_bush" -and $planter.seed.id -eq "tfcfarmingplus:plant/${n}_bush" -and $planter.crop.id -eq "tfcfarmingplus:food/$product") "Bush planter input/output mismatch: $n"
    foreach($lang in @('zh_cn','en_us')){$book=$books["$lang/$(if($high){'bushes_high'}else{'bushes'})"];$page=@($book.pages|Where-Object{$_.anchor -eq $n});Check ($page.Count -eq 1 -and $page[0].text.Contains($(if($lang -eq 'zh_cn'){'地下水'}else{'Groundwater'}))) "Bush habitat guide missing: $n/$lang"}
    $rows.Add([pscustomobject]@{Name=$n;Form=$(if($high){'蔓生'}else{'矮丛'});Product="tfcfarmingplus:food/$product";Lifecycle=($life -join ',');Temperature="$($cl.min_temperature)..$($cl.max_temperature)";Hydration="$($cl.min_hydration)..$($cl.max_hydration)";StateCases=$cases;RuntimeVerified=$false;Use=$(if($n -in @('tea','coffee')){'已有食品定义可食用；饮品流程未开发，本批不新增'}else{'水果分类接入既有配方；实机待验'})})
}
$report=[ordered]@{Species=12;BushBlocks=20;StateCases=($rows|Measure-Object StateCases -Sum).Sum;Findings=$errors.ToArray();Bushes=$rows.ToArray();RuntimeVerified=$false;Module=$module}
if($ReportDirectory){[void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory));[IO.File]::WriteAllText((Join-Path $ReportDirectory 'bush-contracts.json'),($report|ConvertTo-Json -Depth 25),[Text.UTF8Encoding]::new($false));$csv=$rows|Select-Object @{n='物种';e={$_.Name}},@{n='形态';e={$_.Form}},@{n='产物';e={$_.Product}},@{n='十二月物候';e={$_.Lifecycle}},@{n='温度';e={$_.Temperature}},@{n='水合';e={$_.Hydration}},@{n='状态组合';e={$_.StateCases}},@{n='用途';e={$_.Use}},@{n='实机';e={$_.RuntimeVerified}}|ConvertTo-Csv -NoTypeInformation;[IO.File]::WriteAllText((Join-Path $ReportDirectory 'bush-contracts.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))}
Write-Output "[INFO] bushes=12; blocks=20; state cases=$($report.StateCases); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1};Write-Output '[OK] bush declarations checked; gameplay remains unverified';exit 0
