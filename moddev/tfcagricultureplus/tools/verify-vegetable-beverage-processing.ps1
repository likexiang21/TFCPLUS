param([string]$SourceInstance='', [string]$ReportDirectory='')
# Read-only declarations and reachability audit; not a runtime recipe or inventory test.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$liveInstance=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$liveInstance}
$a=Join-Path $instance 'moddev/tfcfarmingplus';$b=Join-Path $instance 'moddev/tfcagricultureplus'
$ar=Join-Path $a 'src/main/resources';$br=Join-Path $b 'src/main/resources'
$errors=New-Object 'System.Collections.Generic.List[string]'
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Read-Json([string]$path){if(Test-Path -LiteralPath $path){Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}}
$manifest=Read-Json (Join-Path $a 'tools/crops-manifest.json')
$earlier=@('millet','foxtail_millet','buckwheat','fonio','spelt','emmer','einkorn','pearl_millet','amaranth','quinoa','finger_millet','jobs_tears','sorghum','chickpea','faba_bean','lupin','adzuki','bambara_nut','fenugreek','pea','cowpea','common_bean','winged_bean','pigeon_pea','sesame','safflower','sunflower','flax','hemp','ramie','sisal','cotton','hops','winter_melon','cantaloupe','bottle_gourd','strawberry')
$crops=@($manifest.crops|Where-Object{$_.name -notin $earlier}|ForEach-Object{$_.name})
Check ($crops.Count -eq 50 -and $manifest.crops.Count -eq 87) 'Crop audit scope changed; review the remaining-crop inventory.'
$veg=Read-Json (Join-Path $ar 'data/c/tags/item/foods/vegetable.json')
$preparedTag=Read-Json (Join-Path $br 'data/c/tags/item/foods/vegetable.json')
$low=Read-Json (Join-Path $ar 'data/tfc/tags/item/compost_greens/low.json')
$expectedLow=@('tfcfarmingplus:hops','tfcfarmingplus:food/tea_leaf','tfcfarmingplus:food/coffee_bean')
Check ($null -ne $low -and $low.replace -eq $false -and ($null -eq $low.remove -or @($low.remove).Count -eq 0) -and (@($low.values|Sort-Object) -join '|') -ceq (@($expectedLow|Sort-Object) -join '|')) 'Shared low-green compost inputs must preserve hops and include both raw bush products.'
Check ($veg.replace -eq $false) 'Existing crop vegetable tag must remain additive.'
$nativeJar=Join-Path $liveInstance 'mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar'
$zip=[IO.Compression.ZipFile]::OpenRead($nativeJar)
function Read-Native([string]$name){$entry=$zip.GetEntry($name);if($null -eq $entry){throw "Native resource missing: $name"};$reader=[IO.StreamReader]::new($entry.Open());try{return $reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}}
$rows=New-Object 'System.Collections.Generic.List[object]'
$preparedRows=New-Object 'System.Collections.Generic.List[object]'
try{
    foreach($use in @('soup','salad','sandwich')){
        $tag=Read-Native "data/tfc/tags/item/usable_in_$use.json"
        Check ('#c:foods/vegetable' -in $tag.values) "Native $use vegetable entry changed."
    }
    $tag=Read-Native 'data/tfc/tags/item/compost_greens/high.json';Check ('#c:foods/vegetable' -in $tag.values) 'Native high-green compost no longer accepts the vegetable category.'
    $tag=Read-Native 'data/tfc/tags/item/compost_greens.json';Check ('#tfc:compost_greens/low' -in $tag.values) 'Native low-green compost entry changed.'
    $zh=Read-Json (Join-Path $ar 'assets/tfcfarmingplus/lang/zh_cn.json')
    $recipes=@(Get-ChildItem -LiteralPath (Join-Path $br 'data/tfcagricultureplus/recipe') -Recurse -File -Filter '*.json'|ForEach-Object{[pscustomobject]@{Path=$_.FullName;Text=Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8}})
    foreach($name in @($crops+@('tea_leaf','coffee_bean'))){
        $bush=$name -in @('tea_leaf','coffee_bean');$id="tfcfarmingplus:food/$name"
        $food=Read-Json (Join-Path $ar "data/tfcfarmingplus/tfc/food/$name.json")
        Check ($null -ne $food -and $food.ingredient.item -eq $id -and $food.decay_modifier -gt 0 -and $food.hunger -gt 0) "Food definition missing/invalid: $name"
        if(-not $bush){
            Check ($id -in $veg.values) "Existing vegetable harvest lost its public food entry: $name"
            $loot=Read-Json (Join-Path $ar "data/tfcfarmingplus/loot_table/blocks/crop/$name.json")
            $wild=Read-Json (Join-Path $ar "data/tfcfarmingplus/loot_table/blocks/wild_crop/$name.json")
            $planter=Read-Json (Join-Path $ar "data/firmalife/firmalife/plantable/$name.json")
            Check (($loot|ConvertTo-Json -Depth 40 -Compress).Contains('"name":"'+$id+'"') -and ($wild|ConvertTo-Json -Depth 40 -Compress).Contains('"name":"'+$id+'"') -and $planter.crop.id -eq $id) "Crop/wild/planter harvest identity differs: $name"
        }else{
            $plant=if($name -eq 'tea_leaf'){'tea'}else{'coffee'}
            $source=Get-Content -LiteralPath (Join-Path $a 'src/main/java/com/example/tfcfarmingplus/common/MyBushes.java') -Raw -Encoding UTF8
            $symbol=$name.ToUpperInvariant()
            $items=Get-Content -LiteralPath (Join-Path $a 'src/main/java/com/example/tfcfarmingplus/common/MyItems.java') -Raw -Encoding UTF8
            Check ($source.Contains('highBush("'+$plant+'", MyItems.'+$symbol) -and $source.Contains('highCane("'+$plant+'", MyItems.'+$symbol) -and $items.Contains($symbol+' = food("'+$name+'")')) "Bush canonical harvest registration missing: $name"
            $planter=Read-Json (Join-Path $ar "data/firmalife/firmalife/plantable/$plant.json")
            Check ($planter.crop.id -eq $id) "Bush planter harvest identity differs: $name"
            Check (Test-Path -LiteralPath (Join-Path $ar "data/tfcfarmingplus/loot_table/blocks/plant/${plant}_bush.json")) "Bush loot missing: $plant"
            Check ($id -in $low.values -and $id -notin $veg.values) "Raw bush product must use its explicit compost entry without becoming a vegetable: $name"
        }
        $local=@($recipes|Where-Object{$_.Text.Contains($id)}|ForEach-Object{$_.Path.Substring((Resolve-Path $br).Path.Length+1).Replace('\','/')})
        $route=if($bush){'既有可食用设定、低档绿料堆肥；完整饮品加工链未开发'}else{'原生汤/沙拉/三明治候选、直接食用、高档绿料堆肥'}
        if($name -in @('ginger','turmeric')){$route+='；B石臼磨粉调味、案板切片'}
        if($name -eq 'napa_cabbage'){$route+='；B案板切白菜丝'}
        $nutrients=@('grain','vegetables','protein','fruit','dairy'|Where-Object{$food.PSObject.Properties[$_] -and $food.$_ -ne 0}|ForEach-Object{"${_}=$($food.$_)"})
        $rows.Add([pscustomobject][ordered]@{名称=$zh.('item.tfcfarmingplus.food.'+$name);ID=$id;类别=$(if($bush){'特用灌木产物'}else{'现有作物蔬菜'});食品营养=$nutrients -join ';';腐烂系数=$food.decay_modifier;用途=$route;直接引用的B配方=$local -join ';';NativeMealTagCandidate=(-not $bush);RuntimeVerified=$false})
    }
    $prepared=@(@('ginger_slices','ginger',2),@('turmeric_slices','turmeric',2),@('napa_cabbage_shreds','napa_cabbage',3))
    $expectedPrepared=@($prepared|ForEach-Object{"tfcagricultureplus:food/$($_[0])"}|Sort-Object)
    Check ($null -ne $preparedTag -and $preparedTag.replace -eq $false -and ($null -eq $preparedTag.remove -or @($preparedTag.remove).Count -eq 0) -and (@($preparedTag.values|Sort-Object) -join '|') -ceq ($expectedPrepared -join '|')) 'Three prepared vegetables need an additive public vegetable tag.'
    foreach($tuple in $prepared){
        $name=$tuple[0];$raw=$tuple[1];$count=$tuple[2];$id="tfcagricultureplus:food/$name"
        $recipe=Read-Json (Join-Path $br "data/tfcagricultureplus/recipe/cutting_board/$name.json")
        $food=Read-Json (Join-Path $br "data/tfcagricultureplus/tfc/food/$name.json")
        Check ($recipe.type -eq 'tfcagricultureplus:cutting_board' -and $recipe.ingredient.item -eq "tfcfarmingplus:food/$raw" -and $recipe.result.stack.id -eq $id -and $recipe.result.stack.count -eq $count -and @($recipe.result.modifiers).Count -eq 1 -and $recipe.result.modifiers[0].type -eq 'tfc:copy_food') "Prepared vegetable recipe loses identity/yield/food history: $name"
        Check ($food.ingredient.item -eq $id -and $food.vegetables -gt 0 -and $food.decay_modifier -gt 0) "Prepared food definition is missing: $name"
        $preparedRows.Add([pscustomobject]@{ID=$id;Source="tfcfarmingplus:food/$raw";OutputCount=$count;NativeMealTagCandidate=($id -in $preparedTag.values);RuntimeVerified=$false})
    }
    $common=Join-Path $b 'src/main/java/com/example/tfcfarmingplus/expansion/common'
    $board=Get-Content -LiteralPath (Join-Path $common 'recipe/CuttingBoardRecipe.java') -Raw -Encoding UTF8
    Check ($board -match '!FoodCapability.isRotten\(input.ingredient\(\)\)' -and $board -match 'result.getSingleStack\(input.ingredient\(\)\)') 'Prepared food must reject rotten input and apply its food provider.'
    $mortar=Get-Content -LiteralPath (Join-Path $common 'recipe/MortarRecipe.java') -Raw -Encoding UTF8
    Check ($mortar -match '!FoodCapability.isRotten\(input.item\(\)\)' -and $mortar -match 'FoodCapability.updateFoodFromPrevious\(input.item\(\), output\)') 'Spice grinding must reject rotten input and retain food history.'
    $spices=Read-Json (Join-Path $br 'data/tfcagricultureplus/tags/item/foods/ground_spices.json')
    foreach($name in @('ginger','turmeric')){
        $recipe=Read-Json (Join-Path $br "data/tfcagricultureplus/recipe/mortar/ground_$name.json")
        Check ($recipe.type -eq 'tfcagricultureplus:mortar' -and $recipe.ingredient.item -eq "tfcfarmingplus:food/$name" -and $recipe.result.id -eq "tfcagricultureplus:food/ground_$name" -and $recipe.result.count -eq 1 -and $recipe.grind_time -eq 4 -and $recipe.result.id -in $spices.values) "Spice flow is broken: $name"
    }
    $season=Read-Json (Join-Path $br 'data/tfcagricultureplus/recipe/crafting/seasoned_vegetable_soup.json')
    Check ($season.type -eq 'tfc:advanced_shapeless_crafting' -and @($season.ingredients).Count -eq 2 -and $season.ingredients[0].children[0].tag -eq 'tfcagricultureplus:foods/seasonable_soups' -and $season.ingredients[0].children[1].type -eq 'tfc:not_rotten' -and $season.ingredients[0].children[2].type -eq 'tfc:lacks_trait' -and $season.ingredients[0].children[2].trait -eq 'tfcagricultureplus:seasoned' -and $season.ingredients[1].children[0].tag -eq 'tfcagricultureplus:foods/ground_spices' -and $season.ingredients[1].children[1].type -eq 'tfc:not_rotten') 'Soup seasoning must reject rotten or already-seasoned food.'
    Check (($season.primary_ingredient|ConvertTo-Json -Depth 10 -Compress) -ceq ($season.ingredients[0]|ConvertTo-Json -Depth 10 -Compress) -and $season.result.modifiers[0].type -eq 'tfc:copy_input' -and $season.result.modifiers[1].type -eq 'tfc:add_trait' -and $season.result.modifiers[1].trait -eq 'tfcagricultureplus:seasoned') 'Seasoning must retain the original soup rather than replacing its dynamic food data.'
    foreach($lang in @('zh_cn','en_us')){
        $guide=Read-Json (Join-Path $ar "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/intro.json")
        Check (@($guide.pages).Count -ge 8 -and $guide.pages[3].anchor -eq 'materials' -and $guide.pages[4].anchor -eq 'grain_processing' -and $guide.pages[5].anchor -eq 'beans_oilseeds' -and $guide.pages[6].anchor -eq 'vegetables_seasoning' -and $guide.pages[7].anchor -eq 'tea_coffee_status') "Guide pages displaced earlier anchors: $lang"
    }
}finally{$zip.Dispose()}
$report=[ordered]@{Schema=1;Scope='AR2-E remaining 50 crops and 2 bush harvests';RuntimeVerified=$false;Findings=$errors.ToArray();Harvests=$rows.ToArray();PreparedVegetables=$preparedRows.ToArray();DedicatedTeaCoffeeChainImplemented=$false;SourceInstance=$instance;NativeReference=$nativeJar}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'vegetable-beverage-contracts.json'),($report|ConvertTo-Json -Depth 35),[Text.UTF8Encoding]::new($false))
    $csv=$rows|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'vegetable-beverage-processing.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output ("[INFO] remaining crops={0}; bush products=2; prepared vegetables=3; findings={1}" -f $crops.Count,$errors.Count)
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] static vegetable, spice and raw beverage-harvest declarations checked; gameplay remains unverified'
exit 0
