param([string]$SourceInstance='', [string]$ReportDirectory='')
# Read-only material flow declarations. No recipe execution, game launch or simulated inventory.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$liveInstance=Split-Path (Split-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$liveInstance}
$a=Join-Path $instance 'mod_rebuild/tfcfarmingplus';$b=Join-Path $instance 'mod_rebuild/tfcagricultureplus'
$ar=Join-Path $a 'src/main/resources';$br=Join-Path $b 'src/main/resources'
$errors=New-Object 'System.Collections.Generic.List[string]'
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Read-MaterialJson([string]$root,[string]$relative){$p=Join-Path $root $relative;if(Test-Path -LiteralPath $p){Get-Content -LiteralPath $p -Raw -Encoding UTF8|ConvertFrom-Json}}
$names=@('flax','hemp','ramie','sisal','cotton','hops')
$products=@('fiber/flax','fiber/hemp','fiber/ramie','fiber/sisal','cotton_boll','hops')
$fibers=@($products[0..3]|ForEach-Object{"tfcfarmingplus:$_"})
$category='tfcfarmingplus:materials/plant_fibers'
$source=Get-Content -LiteralPath (Join-Path $a 'src/main/java/io/github/likexiang21/tfcplus/farming/common/crop/FarmingCrops.java') -Raw -Encoding UTF8
function Check-MaterialTag([string]$path,[string[]]$members){
    $t=Read-MaterialJson $ar $path
    Check ($null -ne $t -and $t.replace -eq $false -and ($null -eq $t.remove -or @($t.remove).Count -eq 0) -and @($t.values).Count -eq $members.Count) "Missing or invalid additive material tag: $path"
    if($null -ne $t){Check (@(Compare-Object @($members|Sort-Object) @($t.values|Sort-Object)).Count -eq 0) "Material tag members differ: $path"}
}
Check-MaterialTag 'data/tfcfarmingplus/tags/item/materials/plant_fibers.json' $fibers
Check-MaterialTag 'data/tfc/tags/item/compost_browns/high.json' (@($fibers)+@('tfcfarmingplus:cotton_boll'))
# This shared category also serves tea/coffee; the material audit owns the hops membership.
$lowGreen=Read-MaterialJson $ar 'data/tfc/tags/item/compost_greens/low.json'
Check ($null -ne $lowGreen -and $lowGreen.replace -eq $false -and ($null -eq $lowGreen.remove -or @($lowGreen.remove).Count -eq 0) -and 'tfcfarmingplus:hops' -in $lowGreen.values) 'Hops must remain additive low-green compost material.'
$loom=Read-MaterialJson $br 'data/tfcagricultureplus/recipe/loom/plant_fiber_burlap.json'
Check ($null -ne $loom -and $loom.type -eq 'tfc:loom' -and $loom.ingredient.tag -eq $category -and $loom.ingredient.count -eq 12 -and $loom.result.id -eq 'tfc:burlap_cloth' -and $loom.result.count -eq 1 -and $loom.steps -eq 12 -and $loom.texture -eq 'tfc:block/burlap') 'Fiber loom route must be 12 of one fiber stack -> one burlap, 12 steps.'
$rope=Read-MaterialJson $br 'data/tfcagricultureplus/recipe/crafting/materials/plant_fiber_rope.json'
Check ($null -ne $rope -and $rope.type -eq 'minecraft:crafting_shaped' -and ($rope.pattern -join '/') -ceq 'F / F' -and $rope.key.F.tag -eq $category -and $rope.result.id -eq 'tfc:rope' -and $rope.result.count -eq 2) 'Rope route must consume two fibers for two ropes.'
$cotton=Read-MaterialJson $br 'data/tfcagricultureplus/recipe/crafting/materials/cotton_string.json'
Check ($null -ne $cotton -and $cotton.type -eq 'tfc:advanced_shapeless_crafting' -and @($cotton.ingredients).Count -eq 2 -and $cotton.ingredients[0].item -eq 'tfcfarmingplus:cotton_boll' -and $cotton.ingredients[1].item -eq 'tfc:spindle' -and $cotton.primary_ingredient.item -eq 'tfc:spindle' -and @($cotton.remainder.modifiers).Count -eq 1 -and $cotton.remainder.modifiers[0].type -eq 'tfc:damage_crafting_remainder' -and $cotton.result.id -eq 'minecraft:string' -and $cotton.result.count -eq 1) 'Cotton route must preserve/damage the spindle and consume one boll for one generic string.'
$rows=New-Object 'System.Collections.Generic.List[object]'
for($i=0;$i -lt 6;$i++){
    $name=$names[$i];$product="tfcfarmingplus:$($products[$i])"
    $method=if($name -eq 'hops'){'material'}else{'fibre'}
    Check ($source.Contains($method+'("'+$products[$i]+'")')) "Material registration missing: $product"
    $crop=Read-MaterialJson $ar "data/tfcfarmingplus/loot_table/blocks/crop/$name.json"
    $wild=Read-MaterialJson $ar "data/tfcfarmingplus/loot_table/blocks/wild_crop/$name.json"
    $planter=Read-MaterialJson $ar "data/firmalife/firmalife/plantable/$name.json"
    $entry=$crop.pools[0].entries[0];$yield=$entry.functions[0].count
    Check ($entry.name -eq $product -and $yield.type -eq 'tfc:crop_yield_uniform' -and $yield.min -eq 0 -and $yield.max.min -eq 6 -and $yield.max.max -eq 10) "Cultivated material/yield changed: $name"
    Check ($wild.pools[0].entries[0].name -eq $product -and $wild.pools[0].entries[0].conditions[0].properties.mature -eq 'true' -and $wild.pools[0].entries[0].functions[0].count.min -eq 1 -and $wild.pools[0].entries[0].functions[0].count.max -eq 3) "Wild material harvest changed: $name"
    Check ($planter.crop.id -eq $product -and $planter.crop.count -eq 1 -and $planter.ingredient.item -eq "tfcfarmingplus:seeds/$name") "Planter material output changed: $name"
    $poolJson=$crop|ConvertTo-Json -Depth 35 -Compress
    if($name -in @('hemp','ramie','cotton','hops')){Check ($poolJson.Contains('"part":"bottom"')) "Tall harvest must retain lower-part restrictions: $name"}
    if($name -eq 'sisal'){Check ($entry.conditions[0].properties.fruiting -eq 'true') 'Sisal harvest must require fruiting.'}
    $rows.Add([pscustomobject]@{Name=$name;Product=$product;Cultivated='原生crop_yield_uniform，0至动态6～10上限';Wild='成熟1～3份；未熟不出材料';Planter=1;Uses=$(if($i -lt 4){'12份同种纤维织麻布；两份纤维制两绳；高档棕料'}elseif($name -eq 'cotton'){'棉铃＋纺锤制一份通用线；高档棕料'}else{'低档绿料；酿酒链仍后续'});RuntimeVerified=$false})
}
# Confirm the native formats and downstream ingredient routes from current dependency data.
$tfc=@(Get-ChildItem -LiteralPath (Join-Path $liveInstance 'mods') -File -Filter 'TerraFirmaCraft-NeoForge-*.jar')
if($tfc.Count -ne 1){throw 'Expected one current TFC dependency jar.'}
$zip=[IO.Compression.ZipFile]::OpenRead($tfc[0].FullName)
function Read-MaterialEntry([string]$path){$e=$zip.GetEntry($path);if($null -eq $e){throw "Missing native data: $path"};$reader=[IO.StreamReader]::new($e.Open());try{$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}}
try {
    $native=Read-MaterialEntry 'data/tfc/recipe/loom/burlap_cloth.json'
    Check ($native.ingredient.count -eq 12 -and $native.steps -eq 12 -and $native.result.id -eq 'tfc:burlap_cloth') 'Pinned native burlap precedent changed.'
    $native=Read-MaterialEntry 'data/tfc/recipe/crafting/rope.json'
    Check ($native.result.count -eq 2 -and ((($native.pattern -join '') -replace ' ','').Length -eq 2)) 'Pinned native rope cost changed.'
    $native=Read-MaterialEntry 'data/tfc/recipe/crafting/wool_yarn.json'
    Check ($native.primary_ingredient.item -eq 'tfc:spindle' -and $native.remainder.modifiers[0].type -eq 'tfc:damage_crafting_remainder') 'Native spindle remainder schema changed.'
    $native=Read-MaterialEntry 'data/tfc/tags/item/compost_browns/high.json';Check ('tfc:jute_fiber' -in $native.values) 'Native high-brown fiber precedent missing.'
    $native=Read-MaterialEntry 'data/tfc/tags/item/compost_browns.json';Check ('#tfc:compost_browns/high' -in $native.values) 'Native high-brown category must reach the composter.'
    $native=Read-MaterialEntry 'data/tfc/tags/item/compost_greens.json';Check ('#tfc:compost_greens/low' -in $native.values) 'Native low-green category must reach the composter.'
    $native=Read-MaterialEntry 'data/minecraft/recipe/bow.json';Check ($native.key.S.tag -eq 'c:strings') 'Generic string downstream ingredient changed.'
    Check ($null -ne $zip.GetEntry('assets/tfc/textures/block/burlap.png')) 'Native loom in-progress texture missing.'
} finally {$zip.Dispose()}
$cursor=[IO.DirectoryInfo]::new($liveInstance);$tooling=''
while($null -ne $cursor){$candidate=Join-Path $cursor.FullName '.tooling';if(Test-Path -LiteralPath (Join-Path $candidate 'game/libraries/net/neoforged/neoforge/21.1.248/neoforge-21.1.248-universal.jar')){$tooling=$candidate;break};$cursor=$cursor.Parent}
$platform=Join-Path $tooling 'game/libraries/net/neoforged/neoforge/21.1.248/neoforge-21.1.248-universal.jar'
$zip=[IO.Compression.ZipFile]::OpenRead($platform)
try{$native=Read-MaterialEntry 'data/c/tags/item/strings.json';Check ('minecraft:string' -in $native.values) 'Current NeoForge generic-string tag must already include vanilla string.'}finally{$zip.Dispose()}
foreach($lang in @('zh_cn','en_us')){
    $intro=Read-MaterialJson $ar "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/intro.json"
    $page=@($intro.pages|Where-Object{$_.anchor -eq 'materials'});Check ($page.Count -eq 1) "Material guide page missing: $lang"
    if($page.Count -eq 1){foreach($word in $(if($lang -eq 'zh_cn'){@('12','2','纺锤','棕料','啤酒花','B')}else{@('12','2','spindle','brown','hops','B')})){Check ($page[0].text.IndexOf($word,[StringComparison]::OrdinalIgnoreCase) -ge 0) "Material guide missing: $lang/$word"}}
}
$report=[ordered]@{Materials=6;Rows=$rows.ToArray();Recipes=3;Findings=$errors.ToArray();RuntimeVerified=$false;SourceInstance=$instance;NativeTfcSha256=(Get-FileHash -LiteralPath $tfc[0].FullName -Algorithm SHA256).Hash;NeoForgeTagJar=$platform}
if($ReportDirectory){[void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory));[IO.File]::WriteAllText((Join-Path $ReportDirectory 'material-contracts.json'),($report|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false));$csv=$rows|Select-Object @{n='作物';e={$_.Name}},@{n='材料编号';e={$_.Product}},@{n='栽培产量规则';e={$_.Cultivated}},@{n='野生产量';e={$_.Wild}},@{n='盆栽产量';e={$_.Planter}},@{n='用途';e={$_.Uses}},@{n='实机确认';e={$_.RuntimeVerified}}|ConvertTo-Csv -NoTypeInformation;[IO.File]::WriteAllText((Join-Path $ReportDirectory 'agricultural-materials.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))}
Write-Output "[INFO] agricultural materials=6; intended new recipes=3; findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1};Write-Output '[OK] material source/data contracts checked; runtime remains unverified';exit 0
