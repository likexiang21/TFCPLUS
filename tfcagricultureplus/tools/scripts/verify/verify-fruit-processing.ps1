param([string]$ReportDirectory = '', [string]$SourceInstance = '', [string]$DraftDirectory = '')
# Static tag declarations and source contracts only. No game or world simulation.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$liveInstance=Split-Path (Split-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) -Parent) -Parent
$instance=if ($SourceInstance) {(Resolve-Path -LiteralPath $SourceInstance).Path} else {$liveInstance}
$a=Join-Path $instance 'mod_rebuild/tfcfarmingplus';$b=Join-Path $instance 'mod_rebuild/tfcagricultureplus'
$ar=Join-Path $a 'src/main/resources';$br=Join-Path $b 'src/main/resources'
$errors=New-Object 'System.Collections.Generic.List[string]'
$definitions=@{};$resolved=@{};$rows=New-Object 'System.Collections.Generic.List[object]'
function Assert-FruitRule([bool]$condition,[string]$message) {if (-not $condition) {$errors.Add($message)}}
function Read-FruitJson([string]$path) {return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json}
function Get-FruitObjects($value,[string]$path='$') {
    if ($value -is [array]) {for ($i=0;$i -lt $value.Count;$i++) {Get-FruitObjects $value[$i] "$path[$i]"}}
    elseif ($value -is [pscustomobject]) {
        [pscustomobject]@{Path=$path;Value=$value}
        foreach ($p in $value.PSObject.Properties) {Get-FruitObjects $p.Value "$path.$($p.Name)"}
    }
}
function Add-FruitTag([string]$relative,[string]$raw,[string]$origin) {
    if ($relative -notmatch '^data/([^/]+)/tags/item/(.+)\.json$') {return}
    $id=$Matches[1]+':'+$Matches[2]
    if (-not $definitions.ContainsKey($id)) {$definitions[$id]=New-Object 'System.Collections.Generic.List[object]'}
    $definitions[$id].Add([pscustomobject]@{Origin=$origin;Raw=$raw})
}
$jars=@(Get-ChildItem -LiteralPath (Join-Path $liveInstance 'mods') -File -Filter '*.jar' |
    Where-Object {$_.Name -notmatch '^(TFCFarmingPlus|TFCAgriculturePlus)-NeoForge-'})
foreach ($jar in $jars) {
    $zip=[IO.Compression.ZipFile]::OpenRead($jar.FullName)
    try {foreach ($entry in $zip.Entries) {
        if ($entry.FullName -notmatch '^data/[^/]+/tags/item/.+\.json$') {continue}
        $reader=[IO.StreamReader]::new($entry.Open())
        try {$raw=$reader.ReadToEnd()} finally {$reader.Dispose()}
        Add-FruitTag $entry.FullName $raw ($jar.Name+'!/'+$entry.FullName)
    }} finally {$zip.Dispose()}
}
foreach ($root in @($ar,$br)) {
    $canonical=(Resolve-Path -LiteralPath $root).Path
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root 'data') -Recurse -File -Filter '*.json') {
        $relative=$file.FullName.Substring($canonical.Length+1).Replace('\','/')
        if ($relative -match '^data/[^/]+/tags/item/.+\.json$') {Add-FruitTag $relative ([IO.File]::ReadAllText($file.FullName)) $file.FullName}
    }
}
function Resolve-FruitTag([string]$id,[string[]]$trail=@()) {
    if ($resolved.ContainsKey($id)) {return $resolved[$id]}
    if ($id -in $trail) {throw "Cyclic item tag: $(($trail+$id)-join ' -> ')"}
    if (-not $definitions.ContainsKey($id)) {
        return [pscustomobject]@{Members=@();Providers=@();Missing=@($id);Warnings=@()}
    }
    $members=@();$providers=@();$missing=@();$warnings=@();$fragments=@()
    foreach ($definition in $definitions[$id]) {
        $tag=$definition.Raw|ConvertFrom-Json;$providers+=$definition.Origin
        if (($tag.replace -eq $true -and $definitions[$id].Count -gt 1) -or $tag.'neoforge:conditions') {
            $warnings+="${id}: load-order/removal/conditional semantics need runtime review";continue
        }
        $fragmentMembers=@();$removed=@()
        foreach ($entry in @($tag.values)) {
            $required=$true
            if ($entry -is [string]) {$value=[string]$entry}
            elseif ($entry.id) {$value=[string]$entry.id;if ($entry.required -eq $false) {$required=$false}}
            else {throw "Unsupported item tag entry in ${id}: $entry"}
            if ($value.StartsWith('#')) {
                $child=Resolve-FruitTag $value.Substring(1) @($trail+$id)
                $fragmentMembers+=$child.Members;$providers+=$child.Providers;$warnings+=$child.Warnings
                if ($required) {$missing+=$child.Missing}
            } else {$fragmentMembers+=$value}
        }
        foreach ($removal in @($tag.remove)) {
            if ($null -eq $removal) {continue}
            if ($removal -isnot [string]) {throw "Unsupported tag removal in $id"}
            if ($removal.StartsWith('#')) {
                $child=Resolve-FruitTag $removal.Substring(1) @($trail+$id)
                $removed+=$child.Members;$warnings+=$child.Warnings
            } else {$removed+=$removal}
        }
        $fragmentMembers=@($fragmentMembers|Where-Object {$_ -notin $removed}|Sort-Object -Unique)
        $fragments+=[pscustomobject]@{Origin=$definition.Origin;Members=$fragmentMembers;Removed=$removed}
        $members+=$fragmentMembers
    }
    # Local removals are order-independent only when another source does not
    # reintroduce the removed member. Do not guess pack priority in conflicts.
    foreach ($fragment in $fragments) {foreach ($removed in $fragment.Removed) {
        foreach ($other in $fragments) {
            if ($other.Origin -ne $fragment.Origin -and $removed -in $other.Members) {$warnings+="${id}: removal/re-add conflict for $removed"}
        }
    }}
    $result=[pscustomobject]@{Members=@($members|Sort-Object -Unique);Providers=@($providers|Sort-Object -Unique);Missing=@($missing|Sort-Object -Unique);Warnings=@($warnings|Sort-Object -Unique)}
    $resolved[$id]=$result;return $result
}
foreach ($root in @($ar,$br)) {
    $owner=if ($root -eq $ar) {'A'} else {'B'}
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root 'data') -Recurse -File -Filter '*.json' | Where-Object {$_.FullName -match '\\recipe\\'}) {
        $recipe=Read-FruitJson $file.FullName
        foreach ($object in Get-FruitObjects $recipe) {
            $tag=[string]$object.Value.tag
            if ($tag -notmatch '^[a-z0-9_]+:foods/') {continue}
            $resolvedTag=Resolve-FruitTag $tag
            $ready=$resolvedTag.Members.Count -gt 0 -and $resolvedTag.Missing.Count -eq 0 -and $resolvedTag.Warnings.Count -eq 0
            Assert-FruitRule $ready "Unresolved food ingredient tag in $($file.Name) at $($object.Path): $tag"
            $rows.Add([pscustomobject][ordered]@{Owner=$owner;Recipe=$file.FullName.Substring((Resolve-Path $root).Path.Length+1).Replace('\','/');RecipeType=$recipe.type;IngredientPath=$object.Path;Tag=$tag;DeclaredItems=$resolvedTag.Members;Providers=$resolvedTag.Providers;Missing=$resolvedTag.Missing;Warnings=$resolvedTag.Warnings;StaticReady=$ready;RuntimeVerified=$false})
        }
    }
}
$fruit=Resolve-FruitTag 'c:foods/fruit';$dough=Resolve-FruitTag 'c:foods/dough';$sweeteners=Resolve-FruitTag 'tfc:foods/sweeteners'
Assert-FruitRule ('tfc:food/strawberry' -in $fruit.Members) 'Canonical TFC strawberry must remain a fruit ingredient.'
Assert-FruitRule ('tfcfarmingplus:food/strawberry' -notin $fruit.Members) 'Retired project strawberry must not return through public fruit tags.'
$generator=Get-Content -LiteralPath (Join-Path $a 'tools/scripts/generate/gen-tags.ps1') -Raw -Encoding UTF8
$berryList=[regex]::Match($generator,'(?m)^\$berryBushNames\s*=\s*@\(([^\r\n]+)\)').Groups[1].Value
Assert-FruitRule ($berryList -notmatch "'strawberry'") 'Legacy tag generator reintroduces retired project strawberry.'
$recipe=Read-FruitJson (Join-Path $br 'data/tfcagricultureplus/recipe/crafting/whole_pie.json')
Assert-FruitRule ($recipe.type -eq 'tfc:advanced_shaped_crafting' -and ($recipe.pattern -join '|') -eq 'FSF| D |   ') 'Whole pie must retain its pattern and use the TFC food-aware crafting serializer.'
foreach ($pair in @(@('F','c:foods/fruit'),@('S','tfc:foods/sweeteners'),@('D','c:foods/dough'))) {
    $ingredient=$recipe.key.($pair[0])
    Assert-FruitRule ($ingredient.type -eq 'tfc:and' -and @($ingredient.children).Count -eq 2 -and
        $ingredient.children[0].tag -eq $pair[1] -and $ingredient.children[1].type -eq 'tfc:not_rotten') "Whole pie ingredient lacks its canonical tag/rotten guard: $($pair[0])"
}
Assert-FruitRule ($recipe.result.stack.id -eq 'tfcagricultureplus:whole_pie' -and $recipe.result.stack.count -eq 1 -and
    @($recipe.result.modifiers).Count -eq 1 -and $recipe.result.modifiers[0].type -eq 'tfc:copy_oldest_food') 'Whole pie output must inherit native crafting food history.'
$foodPath=Join-Path $br 'data/tfcagricultureplus/tfc/food/whole_pie.json'
if (Test-Path -LiteralPath $foodPath) {
    $food=Read-FruitJson $foodPath;$slice=Read-FruitJson (Join-Path $br 'data/tfcagricultureplus/tfc/food/pie_slice.json')
    Assert-FruitRule ($food.ingredient.item -eq 'tfcagricultureplus:whole_pie' -and $food.edible -eq $false -and $food.decay_modifier -eq $slice.decay_modifier) 'Whole pie needs an inedible food record aligned with slice decay.'
} else {$errors.Add('Whole pie has no food definition to carry dates.')}
$common=Join-Path $b 'src/main/java/io/github/likexiang21/tfcplus/agriculture/common'
$block=Get-Content -LiteralPath (Join-Path $common 'block\PlaceableFoodBlock.java') -Raw -Encoding UTF8
$entity=Get-Content -LiteralPath (Join-Path $common 'blockentity/PlaceableFoodBlockEntity.java') -Raw -Encoding UTF8
Assert-FruitRule ($block -match 'FoodCapability.isRotten\(context.getItemInHand\(\)\)' -and $block -match 'state.is\(AgricultureBlocks.WHOLE_PIE.get\(\)\)' -and $block -match 'food.setPieFood\(stack\)') 'Pie placement must reject rotten pies and preserve the actual placed stack.'
Assert-FruitRule ($entity -match 'extends InventoryBlockEntity<ItemStackHandler>' -and $entity -match 'private ItemStack pieFood = ItemStack.EMPTY' -and
    $entity -match 'source.copyWithCount\(1\)' -and $entity -match 'FoodCapability.updateFoodFromPrevious\(pieFood, slice\)') 'Pie food snapshot and serving metadata transfer are missing.'
Assert-FruitRule ($entity -match 'FoodCapability.isRotten\(pieFood\)' -and $entity -match 'final ItemStack slice = newServing\(\)' -and
    $entity -match 'Containers.dropItemStack\([^\r\n]+newServing\(\)\)' -and $entity -match 'PIE_SERVINGS = 8') 'Pie serving/removal must retain the eight-serving count, food history and rotten rejection.'
Assert-FruitRule ($entity -match 'tag.put\("pie_food", pieFood.save\(registries\)\)' -and $entity -match 'ItemStack.parseOptional\(registries, tag.getCompound\("pie_food"\)\)' -and
    $entity -match 'isPie\(\) && pieFood.isEmpty\(\) && servings > 0' -and $entity -match 'onLoadAdditional\(') 'Pie metadata must survive save/reload with one-time legacy initialization.'
$constructor=[regex]::Match($entity,'(?s)public PlaceableFoodBlockEntity\(.*?\n    \}').Value
Assert-FruitRule ($constructor -notmatch 'setStackInSlot|setPieFood|setCreatedNow') 'Do not mutate or synchronize inventory during BE construction.'
Assert-FruitRule ($entity -notmatch 'inventory.setStackInSlot') 'Food metadata must not become an extractable duplicate whole pie.'
foreach ($lang in @('zh_cn','en_us')) {
    $book=Read-FruitJson (Join-Path $br "assets/tfc/patchouli_books/field_guide/$lang/entries/agriculture_plus_kitchen/intro.json")
    Assert-FruitRule (@($book.pages|Where-Object {$_.anchor -eq 'fruit_pie'}).Count -eq 1 -and $book.extra_recipe_mappings.'tfcagricultureplus:whole_pie' -eq 5) "Missing pie guide/mapping: $lang"
}
if ($DraftDirectory) {
    $published=Read-FruitJson (Join-Path $ar 'data/c/tags/item/foods/fruit.json')
    $draft=Read-FruitJson (Join-Path $DraftDirectory 'data/c/tags/item/foods/fruit.json')
    Assert-FruitRule ($published.replace -eq $false -and $draft.replace -eq $false -and
        @($draft.values|Sort-Object -Unique).Count -eq @($draft.values).Count -and
        @(Compare-Object @($published.values|Sort-Object) @($draft.values|Sort-Object)).Count -eq 0) 'Draft fruit tag membership differs from the reviewed published tag.'
}
$report=[ordered]@{RecipeFoodTagReferences=$rows.Count;DistinctFoodTags=@($rows.Tag|Sort-Object -Unique).Count;FruitDeclaredItems=$fruit.Members.Count;DoughDeclaredItems=$dough.Members.Count;SweetenerDeclaredItems=$sweeteners.Members.Count;
    RecipeSerializer=$recipe.type;Findings=$errors.ToArray();SourceInstance=$instance;DependencyJarCount=$jars.Count;RuntimeVerified=$false;
    EvidenceBoundary='Installed mod tag declarations plus A/B source resources; no selected-world datapack order, recipe execution, JEI or player interaction has been verified.';
    IngredientContracts=$rows.ToArray();FruitCandidates=$fruit.Members;DoughCandidates=$dough.Members;SweetenerCandidates=$sweeteners.Members}
if ($ReportDirectory) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'fruit-processing.json'),($report|ConvertTo-Json -Depth 35),[Text.UTF8Encoding]::new($false))
    $csv=$rows|Select-Object Owner,Recipe,RecipeType,IngredientPath,Tag,@{n='声明候选数';e={$_.DeclaredItems.Count}},@{n='声明候选';e={$_.DeclaredItems -join ','}},StaticReady,RuntimeVerified|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'fruit-processing.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output ("[INFO] food-tag references={0}; distinct tags={1}; declared fruit/dough/sweeteners={2}/{3}/{4}; findings={5}" -f $rows.Count,$report.DistinctFoodTags,$fruit.Members.Count,$dough.Members.Count,$sweeteners.Members.Count,$errors.Count)
if ($errors.Count) {$errors|ForEach-Object {Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] static fruit processing contracts checked; runtime recipes and gameplay remain unverified'
exit 0
