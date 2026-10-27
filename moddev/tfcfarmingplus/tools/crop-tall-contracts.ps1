# Helpers for the source/resource audit. No world simulation or game mutation.
function Resolve-CropVariant($definition, [hashtable]$values) {
    $matched = @($definition.variants.PSObject.Properties | Where-Object {
        $valid = $true
        foreach ($pair in ($_.Name -split ',')) {
            $kv = $pair -split '=', 2
            if ($kv.Count -ne 2 -or -not $values.ContainsKey($kv[0])) { throw "Unsupported variant key: $pair" }
            if ($values[$kv[0]] -notin ($kv[1] -split '\|')) { $valid = $false }
        }
        $valid
    })
    if ($matched.Count -ne 1) { throw "Expected exactly one model for $($values | ConvertTo-Json -Compress); found $($matched.Count)" }
    if (-not $matched[0].Value.model) { throw 'Expected a reviewed single-model variant.' }
    return [string]$matched[0].Value.model
}
function Get-CropLootItems($nodes, [string]$blockId, [hashtable]$values) {
    foreach ($node in $nodes) {
        $eligible = $true
        foreach ($condition in @($node.conditions)) {
            if ($null -eq $condition) { continue }
            switch ($condition.condition) {
                'minecraft:survives_explosion' { }
                'minecraft:block_state_property' {
                    if ($condition.block -ne $blockId) { throw "Wrong loot condition block: $($condition.block); expected $blockId" }
                    foreach ($property in $condition.properties.PSObject.Properties) {
                        if (-not $values.ContainsKey($property.Name)) { throw "Unknown loot property: $($property.Name)" }
                        if ([string]$values[$property.Name] -cne [string]$property.Value) { $eligible = $false }
                    }
                }
                default { throw "Unreviewed loot condition: $($condition.condition)" }
            }
        }
        if (-not $eligible) { continue }
        if ($node.type -eq 'minecraft:item') { Write-Output ([string]$node.name) }
        elseif ($node.type -eq 'minecraft:alternatives') {
            foreach ($child in $node.children) {
                $items = @(Get-CropLootItems @($child) $blockId $values)
                if ($items.Count) { $items; break }
            }
        } elseif ($node.pools) { Get-CropLootItems $node.pools $blockId $values }
        elseif ($node.entries) { Get-CropLootItems $node.entries $blockId $values }
        else { throw 'Unreviewed loot node.' }
    }
}
function Assert-TallCrop([string]$name, [string]$class, [string]$call, $state, $cropLoot, [int]$maxAge, [string]$product, $rowErrors) {
    $climbing = $class -eq 'MyClimbingCropBlock'
    $ageMatch = [regex]::Match($call, '(?:dbl|climb)\("[a-z_]+",\s*(\d+),\s*(\d+)')
    if (-not $ageMatch.Success) { throw "Unreviewed tall crop factory: $name" }
    $firstTall = [int]$ageMatch.Groups[1].Value
    $factory = Get-Content -LiteralPath (Join-Path $module "src/main/java/com/example/tfcfarmingplus/common/blocks/$class.java") -Raw -Encoding UTF8
    if ($factory -notmatch ('new ' + $class + '\(properties, singleStages - 1, maxAge, dead')) { $rowErrors.Add('single stage count is not converted to last single age') }
    if ($firstTall -le 1 -or $firstTall -gt $maxAge) { $rowErrors.Add('invalid first tall age') }
    $deadField = [regex]::Match($call, 'MyCrops\.(DEAD_[A-Z_]+)\.get').Groups[1].Value
    $deadCall = [regex]::Match($source, ('DeferredHolder<Block, [^>]+>\s+' + $deadField + '\s*=\s*([^;]+);')).Groups[1].Value
    $deadClass = if ($climbing) { 'DeadClimbingCropBlock' } else { 'DeadDoubleCropBlock' }
    $helper = if ($climbing) { 'deadClimbing' } else { 'deadDouble' }
    $usesHelper = $deadCall -match ('\b' + $helper + '\("' + $name + '"')
    if (-not $usesHelper -and $deadCall -notmatch ('new ' + $deadClass + '\(')) { $rowErrors.Add("dead block must expose $deadClass properties") }
    if ($usesHelper) {
        $body = [regex]::Match($source, ('(?s)private static DeferredHolder<Block, DeadCropBlock> ' + $helper + '\(.*?\n    \}')).Value
        if ($body -notmatch ('new ' + $deadClass + '\(MyBlocks.deadProps\(\), climateRange\)')) { $rowErrors.Add('dead registration helper has incompatible implementation') }
    }
    $deadState = Read-Resource "assets/tfcfarmingplus/blockstates/dead_crop/$name.json"
    $deadLoot = Read-Resource "data/tfcfarmingplus/loot_table/blocks/dead_crop/$name.json"
    $seed = "tfcfarmingplus:seeds/$name"
    $stickValues = if ($climbing) { @('false','true') } else { @('false') }
    $statesChecked = 0
    foreach ($age in 0..$maxAge) { foreach ($part in @('bottom','top')) { foreach ($stick in $stickValues) {
        $values = @{ age=[string]$age; part=$part }
        if ($climbing) { $values.stick = $stick }
        $model = Resolve-CropVariant $state $values
        $expected = if ($age -ge $firstTall) { "tfcfarmingplus:block/crop/${name}_age_${age}_${part}" }
            elseif ($climbing -and $stick -eq 'true' -and $part -eq 'top') { 'tfc:block/crop/stick' }
            elseif ($climbing -and $stick -eq 'true') { "tfcfarmingplus:block/crop/${name}_age_${age}_stick" }
            else { "tfcfarmingplus:block/crop/${name}_age_$age" }
        if ($model -ne $expected) { $rowErrors.Add("age/part/support model mismatch: $age/$part/$stick") }
        $items = @(Get-CropLootItems @($cropLoot) "tfcfarmingplus:crop/$name" $values)
        $expectedItems = @()
        if ($part -eq 'bottom') {
            $expectedItems += $seed
            if ($age -eq $maxAge) { $expectedItems += $product }
            if ($climbing -and $stick -eq 'true') { $expectedItems += 'minecraft:stick' }
        }
        if (@(Compare-Object @($expectedItems | Sort-Object) @($items | Sort-Object)).Count) { $rowErrors.Add("crop loot mismatch: $age/$part/$stick") }
        $statesChecked++
    } } }
    foreach ($mature in @('false','true')) { foreach ($part in @('bottom','top')) { foreach ($stick in $stickValues) {
        $values = @{ mature=$mature; part=$part }
        if ($climbing) { $values.stick = $stick }
        $model = Resolve-CropVariant $deadState $values
        if ($part -eq 'top' -and ($mature -eq 'true' -or ($climbing -and $stick -eq 'true'))) {
            $bottomValues = $values.Clone(); $bottomValues.part = 'bottom'
            if ($model -eq (Resolve-CropVariant $deadState $bottomValues)) { $rowErrors.Add('dead upper part reuses lower plant model') }
            if ($mature -eq 'false' -and $model -ne 'tfc:block/crop/stick') { $rowErrors.Add('dead supported seedling lacks upper stick') }
        }
        $items = @(Get-CropLootItems @($deadLoot) "tfcfarmingplus:dead_crop/$name" $values)
        $expectedItems = @()
        if ($part -eq 'bottom') {
            $expectedItems += $seed
            if ($climbing -and $stick -eq 'true') { $expectedItems += 'minecraft:stick' }
        }
        if (@(Compare-Object @($expectedItems | Sort-Object) @($items | Sort-Object)).Count) { $rowErrors.Add("dead loot mismatch: $mature/$part/$stick") }
        $statesChecked++
    } } }
    foreach ($lang in @('zh_cn','en_us')) {
        $page = @($guides[$lang].pages | Where-Object { $_.anchor -eq $name })
        $required = if ($lang -eq 'zh_cn') { '右键下半株' } else { 'right-click the lower' }
        if ($page.Count -ne 1 -or ($climbing -and $page[0].text -notmatch $required) -or $page[0].text -match '是单格作物|is a single block crop') { $rowErrors.Add("inaccurate tall crop guide: $lang") }
    }
    return [pscustomobject]@{ FirstTallAge=$firstTall; DeadClass=$deadClass; StateCombinations=$statesChecked }
}
