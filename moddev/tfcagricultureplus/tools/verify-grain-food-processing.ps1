param([string]$SourceInstance='', [string]$ReportDirectory='')
# Read-only contracts and declared flow inventory; does not execute recipes or launch Minecraft.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$liveInstance=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$liveInstance}
$a=Join-Path $instance 'moddev/tfcfarmingplus';$b=Join-Path $instance 'moddev/tfcagricultureplus'
$ar=Join-Path $a 'src/main/resources';$br=Join-Path $b 'src/main/resources'
$errors=New-Object 'System.Collections.Generic.List[string]'
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Read-Json([string]$path){if(Test-Path -LiteralPath $path){Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}}
$nativeJar=Join-Path $liveInstance 'mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar'
$zip=[IO.Compression.ZipFile]::OpenRead($nativeJar)
function Read-Native([string]$path){
    $entry=$zip.GetEntry($path)
    if($null -eq $entry){throw "Native resource not found: $path"}
    $reader=[IO.StreamReader]::new($entry.Open())
    try{return $reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
}
$rows=New-Object 'System.Collections.Generic.List[object]'
try{
    $grains=@('millet','foxtail_millet','buckwheat','fonio','spelt','emmer','einkorn','pearl_millet','amaranth','quinoa','finger_millet','jobs_tears','sorghum')
    $beans=@('chickpea','faba_bean','lupin','adzuki','bambara_nut','fenugreek','pea','cowpea','common_bean','winged_bean','pigeon_pea')
    $oils=@('sesame','safflower','sunflower')
    $wheats=@('spelt','emmer','einkorn')
    $grainTag=Read-Json (Join-Path $ar 'data/c/tags/item/foods/grain.json')
    $vegTag=Read-Json (Join-Path $ar 'data/c/tags/item/foods/vegetable.json')
    Check ($grainTag.replace -eq $false -and $vegTag.replace -eq $false) 'Public food tags must remain additive.'
    $declaredGrains=@($grainTag.values|Sort-Object -Unique)
    Check (($declaredGrains -join '|') -ceq (($grains|ForEach-Object{"tfcfarmingplus:food/$_"}|Sort-Object) -join '|')) 'Reviewed grain classification differs from the 13 existing crops.'
    foreach($use in @('soup','salad','sandwich')){
        $native=Read-Native "data/tfc/tags/item/usable_in_$use.json"
        Check ('#c:foods/vegetable' -in $native.values) "Native $use no longer accepts vegetable-tag foods; re-evaluate the inventory."
        Check ('#c:foods/grain' -notin $native.values) "Native $use grain behavior changed; re-evaluate the inventory."
    }
    $nativeSoup=Read-Native 'data/tfc/tags/item/usable_in_soup.json'
    Check ('tfc:food/lentil' -in $nativeSoup.remove) 'Native raw-lentil soup exclusion must be reviewed rather than removed.'
    $zh=Read-Json (Join-Path $ar 'assets/tfcfarmingplus/lang/zh_cn.json')
    foreach($name in @($grains+$beans+$oils)){
        $id="tfcfarmingplus:food/$name";$isGrain=$name -in $grains
        $food=Read-Json (Join-Path $ar "data/tfcfarmingplus/tfc/food/$name.json")
        $loot=Read-Json (Join-Path $ar "data/tfcfarmingplus/loot_table/blocks/crop/$name.json")
        $wild=Read-Json (Join-Path $ar "data/tfcfarmingplus/loot_table/blocks/wild_crop/$name.json")
        $planter=Read-Json (Join-Path $ar "data/firmalife/firmalife/plantable/$name.json")
        Check ($null -ne $food -and $food.ingredient.item -eq $id -and $food.decay_modifier -gt 0 -and $food.hunger -gt 0) "Food definition missing/invalid: $name"
        Check (($loot|ConvertTo-Json -Depth 40 -Compress).Contains('"name":"'+$id+'"') -and ($wild|ConvertTo-Json -Depth 40 -Compress).Contains('"name":"'+$id+'"') -and $planter.crop.id -eq $id) "Cultivated/wild/planter harvest identity broken: $name"
        Check ((($id -in $grainTag.values) -eq $isGrain) -and (($id -in $vegTag.values) -eq (-not $isGrain))) "Wrong grain/vegetable membership: $name"
        $route='直接食用、原生中档绿料堆肥；专属磨粉链待开发'
        if($name -in $beans){$route='直接食用、原生汤/沙拉/三明治及高档绿料堆肥'}
        if($name -in $oils){$route='直接食用、原生汤/沙拉/三明治及高档绿料堆肥；专属榨油链待开发'}
        if($name -in $wheats){$route='B配方：原生手磨1份→原生小麦粉1份→既有原生面团/搅拌碗；直接食用/中档绿料堆肥'}
        $nutrients=@('grain','vegetables','protein','fruit','dairy'|Where-Object{$food.PSObject.Properties[$_] -and $food.$_ -ne 0}|ForEach-Object{"${_}=$($food.$_)"})
        $rows.Add([pscustomobject][ordered]@{名称=$zh.('item.tfcfarmingplus.food.'+$name);ID=$id;类别=$(if($isGrain){'谷物'}elseif($name -in $beans){'豆类'}else{'油料'});食品营养=$nutrients -join ';';腐烂系数=$food.decay_modifier;现有路径=$route;NativeMealTagCandidate=(-not $isGrain);RuntimeVerified=$false})
    }
    foreach($name in $wheats){
        $recipe=Read-Json (Join-Path $br "data/tfcagricultureplus/recipe/quern/${name}_flour.json")
        Check ($null -ne $recipe -and $recipe.type -eq 'tfc:quern' -and $recipe.ingredient.type -eq 'tfc:and' -and @($recipe.ingredient.children).Count -eq 2 -and $recipe.ingredient.children[0].item -eq "tfcfarmingplus:food/$name" -and $recipe.ingredient.children[1].type -eq 'tfc:not_rotten' -and $recipe.result.stack.id -eq 'tfc:food/wheat_flour' -and $recipe.result.stack.count -eq 1 -and @($recipe.result.modifiers).Count -eq 1 -and $recipe.result.modifiers[0].type -eq 'tfc:copy_food') "Wheat-species milling loses identity/count/food history: $name"
    }
    $bowlDir=Join-Path $br 'data/tfcagricultureplus/recipe/mixing_bowl'
    $files=@(Get-ChildItem -LiteralPath $bowlDir -Filter '*.json' -File)
    Check ($files.Count -eq 13) 'Expected the 12 native grain dough recipes and one existing cake dough recipe.'
    foreach($file in $files){
        $recipe=Read-Json $file.FullName;$cake=$file.BaseName -eq 'cake_dough';$coarse=$file.BaseName.EndsWith('_coarse_dough')
        $grain=($file.BaseName -replace '_coarse_dough$','' -replace '_dough$','')
        $base=if($cake){@{tag='tfcagricultureplus:foods/cake_flour'}}else{@{item="tfc:food/${grain}_flour"}}
        $expectedOutput=if($cake){'tfcagricultureplus:food/cake_dough'}elseif($coarse){"tfc:food/${grain}_dough"}else{"firmalife:food/${grain}_dough"}
        $expectedFluid=if($coarse){'minecraft:water'}else{'firmalife:yeast_starter'}
        $expectedAmount=if($cake){300}else{100};$expectedCount=if($cake){5}elseif($coarse){1}else{2}
        Check ($recipe.type -eq 'tfcagricultureplus:food_mixing_bowl' -and $recipe.fluid_ingredients.fluid -eq $expectedFluid -and $recipe.fluid_ingredients.amount -eq $expectedAmount -and $recipe.result_item.id -eq $expectedOutput -and $recipe.result_item.count -eq 1 -and @($recipe.item_ingredients).Count -eq $expectedCount) "Bowl recipe identity/yield/fluid changed: $($file.Name)"
        for($i=0;$i -lt @($recipe.item_ingredients).Count;$i++){
            $ingredient=$recipe.item_ingredients[$i]
            Check ($ingredient.type -eq 'tfc:and' -and @($ingredient.children).Count -eq 2 -and $ingredient.children[1].type -eq 'tfc:not_rotten') "Bowl ingredient allows rotten food: $($file.Name) slot $i"
            $children=@($ingredient.children);$value=if($children.Count -gt 0){$children[0]}else{$null}
            if($i -eq 0 -or ($cake -and $i -lt 3)){
                Check (($(if($cake){$value.tag -eq $base['tag']}else{$value.item -eq $base['item']}))) "Bowl flour ingredient changed: $($file.Name) slot $i"
            }elseif($cake -and $i -eq 3){Check ($value.tag -eq 'firmalife:foods/raw_eggs') 'Cake dough lost its egg ingredient.'}
            else{Check ($value.tag -eq 'tfc:foods/sweeteners') "Bowl dough lost its sweetener: $($file.Name)"}
        }
    }
    $sourcePath=Join-Path $b 'src/main/java/com/example/tfcfarmingplus/expansion/common/recipe/FoodMixingBowlRecipe.java'
    $source=if(Test-Path -LiteralPath $sourcePath){Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8}else{''}
    Check ($source -match 'extends MixingBowlRecipe' -and $source -match 'return super.matches\(inventory, level\)' -and $source -notmatch 'RecipeType|FLRecipeTypes') 'Food recipes must retain the native mixing recipe type and matching.'
    Check ($source -match 'FoodCapability.isRotten\(stack\)' -and $source -match 'FoodCapability.updateFoodFromAllPrevious\(inputs, FoodCapability.setCreatedNow\(output.copy\(\)\)\)' -and $source -notmatch 'setStackInSlot|\.drain\(|\.shrink\(') 'Food history must use TFC API without duplicating native consumption.'
    Check ($source -match 'MapCodec<FoodMixingBowlRecipe>' -and $source -match 'StreamCodec<RegistryFriendlyByteBuf, FoodMixingBowlRecipe>' -and $source -match 'MyRecipeSerializers.FOOD_MIXING_BOWL.get\(\)') 'Data/network codec and serializer identity are required.'
    $registry=Get-Content -LiteralPath (Join-Path $b 'src/main/java/com/example/tfcfarmingplus/expansion/common/recipe/MyRecipeSerializers.java') -Raw -Encoding UTF8
    Check ($registry -match 'register\("food_mixing_bowl", FoodMixingBowlRecipe.Serializer::new\)') 'Project food bowl serializer is not registered.'
    foreach($lang in @('zh_cn','en_us')){
        $guide=Read-Json (Join-Path $ar "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/intro.json")
        Check (@($guide.pages).Count -ge 6 -and $guide.pages[3].anchor -eq 'materials' -and $guide.pages[4].anchor -eq 'grain_processing' -and $guide.pages[5].anchor -eq 'beans_oilseeds') "Food guide pages displaced earlier anchors: $lang"
    }
    $generator=Get-Content -LiteralPath (Join-Path $a 'tools/gen-tags.ps1') -Raw -Encoding UTF8
    Check ([regex]::Match($generator,'(?m)^\$grainNames\s*=\s*@\(([^\r\n]+)\)').Groups[1].Value -match "'sorghum'") 'Tag generator would regress sorghum classification.'
}finally{$zip.Dispose()}
$report=[ordered]@{Schema=1;Scope='AR2-D existing grains, beans, oilseeds and project bowl food metadata';RuntimeVerified=$false;Crops=$rows.ToArray();Findings=$errors.ToArray();NativeReference=$nativeJar}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'grain-food-contracts.json'),($report|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
    $csv=$rows|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'grain-food-processing.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output ("[INFO] grain/bean/oilseed declarations={0}; project bowl recipes={1}; findings={2}" -f $rows.Count,$files.Count,$errors.Count)
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] static food-processing contracts checked; runtime behavior remains unverified'
exit 0
