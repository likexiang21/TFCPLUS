param([string]$ModuleDirectory='', [string]$ReportDirectory='')
# Static source/data contracts only; no gameplay, simulated growth or world writes.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$live=Split-Path $env:TFC_TOOLS_ROOT -Parent
$instance=Split-Path (Split-Path $live -Parent) -Parent
$module=if($ModuleDirectory){(Resolve-Path -LiteralPath $ModuleDirectory).Path}else{$live}
$res=Join-Path $module 'src/main/resources';$common=Join-Path $module 'src/main/java/io/github/likexiang21/tfcplus/farming/common'
$errors=New-Object 'System.Collections.Generic.List[string]'
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Read-SoilJson([string]$relative){Get-Content -LiteralPath (Join-Path $res $relative) -Raw -Encoding UTF8|ConvertFrom-Json}
$source=Get-Content -LiteralPath (Join-Path $common 'crop\FarmingCrops.java') -Raw -Encoding UTF8
$num='-?\d+(?:\.\d+)?f'
$seeds=[regex]::Matches($source,('seed\("([a-z_]+)",.*?,\s*('+$num+'),\s*('+$num+'),\s*('+$num+')'))
$blocks=[regex]::Matches($source,('(crop|dbl|climb|flooded|spread|pickable|rosette)\("([a-z_]+)",\s*(?:\d+,\s*){0,2}('+$num+'),\s*('+$num+'),\s*('+$num+')'))
$manifest=Get-Content -LiteralPath (Join-Path $module 'tools/contracts/crops-manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
Check ($seeds.Count -eq 87 -and $blocks.Count -eq 87) 'Expected 87 seed/block nutrient declarations.'
$byName=@{};foreach($b in $blocks){$byName[$b.Groups[2].Value]=$b}
Check ($byName.Count -eq 87 -and @(Compare-Object @($byName.Keys|Sort-Object) @($manifest.crops.name|Sort-Object)).Count -eq 0) 'Nutrient scope must match 87 registered crop forms.'
$templates=@{};foreach($tool in @('gen-crops.ps1','gen-patchouli-book.ps1')){
    $s=Get-Content -LiteralPath (Join-Path $module "tools/scripts/generate/$tool") -Raw -Encoding UTF8;$table=@{}
    foreach($m in [regex]::Matches($s,"n='([a-z_]+)'[^\r\n]*?npk='([^']+)'")){$table[$m.Groups[1].Value]=@($m.Groups[2].Value -split '/'|ForEach-Object{[double]::Parse($_.Trim(),[Globalization.CultureInfo]::InvariantCulture)})};$templates[$tool]=$table
}
$seedCode=Get-Content -LiteralPath (Join-Path $common 'item/FarmingSeedItem.java') -Raw -Encoding UTF8
Check ($seedCode -match 'new PlantableInfo.PlantNutrients\(nitrogen, phosphorous, potassium\)' -and $seedCode -match 'return nutrients;') 'Seed tooltip must expose the same native nutrient values.'
$runtimeSource=[regex]::Replace($source,'(?s)/\*.*?\*/','')
Check (@([regex]::Matches($runtimeSource,'serverTicks\(CropBlockEntity::serverTick\)')).Count -eq 7) 'All seven crop factories must bind the native crop ticker.'
foreach($class in @('FarmingCropBlock','FarmingDoubleCropBlock','FarmingClimbingCropBlock','FarmingFloodedCropBlock','FarmingSpreadingCropBlock','FarmingPickableCropBlock','RosetteCropBlock')){
    $s=Get-Content -LiteralPath (Join-Path $common "block/$class.java") -Raw -Encoding UTF8
    Check ($s -match 'nitrogen, phosphorous, potassium' -and $s -notmatch '(?m)^\s*(?:public|protected)\s+(?:void|boolean)\s+growthTick\(' -and $s -notmatch '\.(?:setNutrient|addNutrient|consumeNutrients)\(') "Crop must delegate native nutrient accounting: $class"
}
$books=@{};foreach($lang in @('zh_cn','en_us')){$books[$lang]=Read-SoilJson "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/crops.json"}
$cropRows=New-Object 'System.Collections.Generic.List[object]'
foreach($seed in $seeds){
    $n=$seed.Groups[1].Value;$b=$byName[$n];$sv=@();$bv=@()
    foreach($i in 2..4){$sv+=[double]::Parse($seed.Groups[$i].Value.TrimEnd('f'),[Globalization.CultureInfo]::InvariantCulture);$bv+=[double]::Parse($b.Groups[$i+1].Value.TrimEnd('f'),[Globalization.CultureInfo]::InvariantCulture)}
    Check (($sv -join ',') -ceq ($bv -join ',')) "Seed and crop nutrients differ: $n"
    foreach($tool in $templates.Keys){Check (($sv -join ',') -ceq ($templates[$tool][$n] -join ',')) "Generator nutrient drift: $n/$tool"}
    Check (@($sv|Where-Object{$_ -gt 0}).Count -gt 0 -and @($sv|Where-Object{[double]::IsNaN($_) -or [double]::IsInfinity($_)}).Count -eq 0) "Unexpected nutrient coefficient: $n"
    foreach($lang in @('zh_cn','en_us')){
        if($n -eq 'strawberry') {
            $strawberry=Read-SoilJson "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/strawberry.json"
            Check ($strawberry.pages[0].anchor -eq 'strawberry') "Separate strawberry guide missing: $lang"
            continue
        }
        $page=@($books[$lang].pages|Where-Object{$_.anchor -eq $n});Check ($page.Count -eq 1) "Crop guide missing: $n/$lang"
        if($page.Count -ne 1){continue}
        $labels=if($lang -eq 'zh_cn'){@('氮','磷','钾')}else{@('Nitrogen','Phosphorous','Potassium')}
        foreach($j in 0..2){$value=$(if($sv[$j] -lt 0){'+'}else{''})+[string][Math]::Round([Math]::Abs($sv[$j])*100);Check ($page[0].text.Contains($labels[$j]+'$(): '+$value)) "Guide nutrient amount differs: $n/$lang/$($labels[$j])"}
    }
    $cropRows.Add([pscustomobject]@{Name=$n;Shape=$b.Groups[1].Value;N=$sv[0];P=$sv[1];K=$sv[2];NativeAccounting=$true;RuntimeVerified=$false})
}
# Resolve declared tag members from dependency packs, followed by A/B source overlays.
# This is a declaration view, not an in-game pack-order or registry observation.
$definitions=@{};$resolved=@{}
function Add-SoilTag([string]$path,[string]$raw){
    if($path -notmatch '^data/([^/]+)/tags/item/(.+)\.json$'){return}
    $id=$Matches[1]+':'+$Matches[2];if(-not $definitions.ContainsKey($id)){$definitions[$id]=New-Object 'System.Collections.Generic.List[object]'}
    $definitions[$id].Add(($raw|ConvertFrom-Json))
}
$fertilizers=New-Object 'System.Collections.Generic.List[object]';$soilNames=@()
foreach($jar in Get-ChildItem -LiteralPath (Join-Path $instance 'mods') -File -Filter '*.jar'|Where-Object{$_.Name -notmatch '^(TFCFarmingPlus|TFCAgriculturePlus)-NeoForge-'}){
    $zip=[IO.Compression.ZipFile]::OpenRead($jar.FullName)
    try{foreach($entry in $zip.Entries){
        $isTag=$entry.FullName -match '^data/[^/]+/tags/item/.+\.json$';$isFertilizer=$jar.Name -like 'TerraFirmaCraft-NeoForge-*' -and $entry.FullName -match '^data/tfc/tfc/fertilizer/.+\.json$'
        if($jar.Name -like 'TerraFirmaCraft-NeoForge-*' -and $entry.FullName -match '^assets/tfc/blockstates/farmland/([^/]+)\.json$'){$soilNames+=$Matches[1]}
        if($isTag -or $isFertilizer){$reader=[IO.StreamReader]::new($entry.Open());try{$raw=$reader.ReadToEnd()}finally{$reader.Dispose()};if($isTag){Add-SoilTag $entry.FullName $raw};if($isFertilizer){$v=$raw|ConvertFrom-Json;$fertilizers.Add([pscustomobject]@{Path=$entry.FullName;Item=$v.ingredient.item;N=[double]$v.nitrogen;P=[double]$v.phosphorus;K=[double]$v.potassium;RuntimeVerified=$false})}}
    }}finally{$zip.Dispose()}
}
foreach($root in @($res,(Join-Path $instance 'mod_rebuild/tfcagricultureplus/src/main/resources'))){foreach($p in Get-ChildItem -LiteralPath (Join-Path $root 'data') -Recurse -File -Filter '*.json'){
    $relative=$p.FullName.Substring($root.Length+1) -replace '\\','/';if($relative -match '/tags/item/') {Add-SoilTag $relative (Get-Content -LiteralPath $p.FullName -Raw -Encoding UTF8)}
}}
function Resolve-SoilTag([string]$id,[string[]]$trail=@()){
    if($resolved.ContainsKey($id)){return ,$resolved[$id]};if($id -in $trail){throw "Cyclic item tag: $id"}
    $set=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($definition in $definitions[$id]){
        if($definition.replace){$set.Clear()}
        foreach($entry in $definition.values){$key=if($entry -is [string]){$entry}else{$entry.id};if($key.StartsWith('#')){foreach($member in (Resolve-SoilTag $key.Substring(1) (@($trail)+@($id)))){[void]$set.Add($member)}}else{[void]$set.Add($key)}}
        foreach($entry in $definition.remove){$key=if($entry -is [string]){$entry}else{$entry.id};if($key.StartsWith('#')){foreach($member in (Resolve-SoilTag $key.Substring(1) (@($trail)+@($id)))){[void]$set.Remove($member)}}else{[void]$set.Remove($key)}}
    }
    $resolved[$id]=@($set|Sort-Object);return ,$resolved[$id]
}
$greens=Resolve-SoilTag 'tfc:compost_greens/high';$browns=Resolve-SoilTag 'tfc:compost_browns/low';$poisons=Resolve-SoilTag 'tfc:compost_poisons'
$melons=@('tfcfarmingplus:winter_melon','tfcfarmingplus:bottle_gourd','tfcfarmingplus:cantaloupe')
foreach($item in $melons){Check ($item -in $greens -and $item -notin $poisons) "Whole melon compost input missing or poisoned: $item"}
$tagPath='data/tfc/tags/item/compost_greens/high.json'
if(Test-Path -LiteralPath (Join-Path $res $tagPath)){$tag=Read-SoilJson $tagPath;Check ($tag.replace -eq $false -and ($null -eq $tag.remove -or @($tag.remove).Count -eq 0) -and @($tag.values).Count -eq 3 -and @(Compare-Object @($tag.values|Sort-Object) @($melons|Sort-Object)).Count -eq 0) 'Whole-melon compost tag must append exactly three items.'}else{Check $false 'Missing explicit whole-melon compost bridge.'}
Check ('tfc:pumpkin' -in $greens -and 'tfc:melon' -in $greens) 'Native whole fruit compost routes must remain.'
foreach($item in @('tfcagricultureplus:sawdust','tfcfarmingplus:plant/pear_leaves')){Check ($item -in $browns) "Existing brown compost route missing: $item"}
Check ('minecraft:bone_meal' -in $poisons) 'Do not remove the native bone-meal compost poison rule.'
Check ($fertilizers.Count -eq 10 -and $soilNames.Count -eq 8) 'Pinned TFC should expose ten fertilizers and eight farmland soil IDs.'
$compost=@($fertilizers|Where-Object{$_.Item -eq 'tfc:compost'})[0]
Check ($compost.N -eq 0.2 -and $compost.P -eq 0 -and $compost.K -eq 0.2) 'Native compost is N/K fertilizer, not a phosphorus source.'
foreach($lang in @('zh_cn','en_us')){
    $book=Read-SoilJson "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/intro.json"
    Check ($book.pages.Count -ge 3) "General guide must include nutrient and compost pages: $lang"
    if($book.pages.Count -ge 3){
        Check ($book.pages[0].text.Contains('87') -and -not $book.pages[0].text.Contains('86')) "Crop count must match 87 forms: $lang"
        $expected=if($lang -eq 'zh_cn'){@('养分','施肥','回补','磷')}else{@('nutrient','fertilizer','return','phosphorus')};foreach($word in $expected){Check ($book.pages[1].text.Contains($word)) "Nutrient guide missing: $lang/$word"}
        $expected=if($lang -eq 'zh_cn'){@('整瓜','木屑','绿料','棕料','骨粉')}else{@('whole','sawdust','green','brown','bone meal')};foreach($word in $expected){Check ($book.pages[2].text.IndexOf($word,[StringComparison]::OrdinalIgnoreCase) -ge 0) "Compost guide missing: $lang/$word"}
    }
}
$tagTemplate=Get-Content -LiteralPath (Join-Path $module 'tools/scripts/generate/gen-tags.ps1') -Raw -Encoding UTF8
Check ($tagTemplate.Contains("data/tfc/tags/item/compost_greens/high.json") -and $tagTemplate.Contains('$wholeMelonItems')) 'Tag generator must retain whole-melon compost data.'
$report=[ordered]@{CropForms=$cropRows.Count;NativeFertilizers=$fertilizers.Count;NativeFarmlandSoils=$soilNames;WholeMelons=$melons;Findings=$errors.ToArray();Crops=$cropRows.ToArray();Fertilizers=$fertilizers.ToArray();RuntimeVerified=$false;Module=$module;TagResolution='Declared dependency tags followed by project source overlays; runtime pack order not proven'}
if($ReportDirectory){[void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory));[IO.File]::WriteAllText((Join-Path $ReportDirectory 'soil-contracts.json'),($report|ConvertTo-Json -Depth 25),[Text.UTF8Encoding]::new($false));$csv=$cropRows|Select-Object @{n='作物';e={$_.Name}},@{n='形态';e={$_.Shape}},@{n='氮系数';e={$_.N}},@{n='磷系数';e={$_.P}},@{n='钾系数';e={$_.K}},@{n='原生核算';e={$_.NativeAccounting}},@{n='实机确认';e={$_.RuntimeVerified}}|ConvertTo-Csv -NoTypeInformation;[IO.File]::WriteAllText((Join-Path $ReportDirectory 'soil-crops.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true));$fertilizers|ConvertTo-Csv -NoTypeInformation|Set-Content -LiteralPath (Join-Path $ReportDirectory 'native-fertilizers.csv') -Encoding UTF8}
Write-Output "[INFO] nutrient crops=$($cropRows.Count); native fertilizers=$($fertilizers.Count); farmland soils=$($soilNames.Count); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1};Write-Output '[OK] soil source/data contracts checked; runtime remains unverified';exit 0
