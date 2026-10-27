# Static multipart, lifecycle wiring, harvest and processing contracts.
function Assert-SpreadingCrop([string]$name, [string]$call, $state, $cropLoot, [int]$maxAge, $rowErrors) {
    $fruit = "tfcfarmingplus:$name"; $slice = "tfcfarmingplus:food/${name}_slice"; $seed = "tfcfarmingplus:seeds/$name"
    $field = $name.ToUpperInvariant()
    if ($call -notmatch ('\(\) -> MyCrops\.' + $field + '\)')) { $rowErrors.Add('vine fruit binding mismatch') }
    $factory = [regex]::Match($source, '(?s)private static DeferredHolder<Block, MySpreadingCropBlock> spread\(.*?\n    \}').Value
    if ($factory -notmatch 'blockEntity\(MyBlockEntities.CROP\)' -or $factory -notmatch 'serverTicks\(CropBlockEntity::serverTick\)') { $rowErrors.Add('vine BE/ticker binding mismatch') }
    $count=0
    foreach ($age in 0..$maxAge) { foreach ($mask in 0..15) {
        $values=@{age=[string]$age}; $rotations=@{north=0;east=90;south=180;west=270}; $directions=@('north','east','south','west')
        for ($i=0;$i -lt 4;$i++) { $values[$directions[$i]] = ([bool]($mask -band (1 -shl $i))).ToString().ToLowerInvariant() }
        $models=@(foreach ($part in $state.multipart) {
            $eligible=$true
            foreach ($condition in $part.when.PSObject.Properties) {
                if (-not $values.ContainsKey($condition.Name)) { throw 'Unreviewed spreading multipart condition' }
                if ($values[$condition.Name] -ne ([string]$condition.Value).ToLowerInvariant()) { $eligible=$false }
            }
            if ($eligible) { "$($part.apply.model)@$([int]$part.apply.y)" }
        })
        $expected=@("tfcfarmingplus:block/crop/${name}_age_$age@0")
        foreach ($d in $directions) { if ($values[$d] -eq 'true') { $expected += "tfcfarmingplus:block/crop/${name}_side@$($rotations[$d])" } }
        if (@(Compare-Object @($models | Sort-Object) @($expected | Sort-Object)).Count) { $rowErrors.Add("multipart mismatch: $age/$mask") }
        $items=@(Get-CropLootItems @($cropLoot) "tfcfarmingplus:crop/$name" $values)
        if ($items.Count -ne 1 -or $items[0] -ne $seed) { $rowErrors.Add("vine must drop only its seed: $age/$mask") }
        $count++
    } }
    foreach ($kind in @('wild_crop','dead_crop')) {
        $loot=Read-Resource "data/tfcfarmingplus/loot_table/blocks/$kind/$name.json"
        foreach ($mature in @('false','true')) {
            $items=@(Get-CropLootItems @($loot) "tfcfarmingplus:$kind/$name" @{mature=$mature})
            $expected=@($seed); if ($kind -eq 'wild_crop' -and $mature -eq 'true') { $expected += $fruit }
            if (@(Compare-Object @($items | Sort-Object) @($expected | Sort-Object)).Count) { $rowErrors.Add("$kind harvest mismatch: $mature") }
            $count++
        }
    }
    $fruitLoot=Read-Resource "data/tfcfarmingplus/loot_table/blocks/$name.json"
    if (@($fruitLoot.pools).Count) { $rowErrors.Add('whole fruit loot duplicates the native stored-stack return') }
    $foodRelative="data/tfcfarmingplus/tfc/food/$name.json"
    if (-not (Test-Path -LiteralPath (Join-Path $resourceRoot $foodRelative))) { $rowErrors.Add('whole fruit lacks its decay food definition') }
    else {
        $food=Read-Resource $foodRelative
        $decay=if ($name -eq 'winter_melon') {0.3} else {0.5}
        if ($food.ingredient.item -ne $fruit -or $food.edible -ne $false -or [double]$food.decay_modifier -ne $decay) { $rowErrors.Add('whole fruit food/decay contract mismatch') }
    }
    $sliceFood=Read-Resource "data/tfcfarmingplus/tfc/food/${name}_slice.json"
    if ($sliceFood.ingredient.item -ne $slice -or [double]$sliceFood.decay_modifier -ne 2.5 -or $slice -notin $foodTags) { $rowErrors.Add('slice food or classification mismatch') }
    $bridgePath=Join-Path $instance "moddev/tfcagricultureplus/src/main/resources/data/tfcagricultureplus/recipe/cutting_board/$name.json"
    $bridge=Get-Content -LiteralPath $bridgePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($bridge.type -ne 'tfcagricultureplus:cutting_board' -or $bridge.ingredient.item -ne $fruit -or $bridge.result.stack.id -ne $slice -or
        $bridge.result.stack.count -ne 4 -or 'tfc:copy_food' -notin @($bridge.result.modifiers.type)) { $rowErrors.Add('existing board processing bridge mismatch') }
    $entities=Get-Content -LiteralPath (Join-Path $module 'src/main/java/com/example/tfcfarmingplus/common/MyBlockEntities.java') -Raw -Encoding UTF8
    if ($entities -notmatch '\.<DecayingBlockEntity>of\(MyDecayingBlockEntity::new, MyCrops.fruitBlocks\(\)\)') { $rowErrors.Add('saved fruit BE recreates the wrong native type') }
    $entity=Get-Content -LiteralPath (Join-Path $module 'src/main/java/com/example/tfcfarmingplus/common/blockentities/MyDecayingBlockEntity.java') -Raw -Encoding UTF8
    if ($entity -notmatch '(?s)void setStack\(ItemStack stack\).*?super.setStack\(stack\);\s*setChanged\(\);') { $rowErrors.Add('fruit food-state mutations are not marked for saving') }
    $fruitBlocks=[regex]::Match($source,'(?s)public static Block\[\] fruitBlocks\(\).*?\n    \}').Value
    if ($fruitBlocks -notmatch ($field + '\.get\(\)')) { $rowErrors.Add('missing valid fruit block registration') }
    $block=Get-Content -LiteralPath (Join-Path $module 'src/main/java/com/example/tfcfarmingplus/common/blocks/MyDecayingBlock.java') -Raw -Encoding UTF8
    if ($block -notmatch 'new MyDecayingBlockEntity\(pos, state\)' -or $block -notmatch 'FoodCapability.setCreatedNow' -or $block -notmatch 'DecayingBlockEntity.serverTick') { $rowErrors.Add('fruit BE/ticker or legacy empty-stack recovery mismatch') }
    foreach ($lang in @('zh_cn','en_us')) {
        $page=@($guides[$lang].pages | Where-Object {$_.anchor -eq $name})
        $required=if ($lang -eq 'zh_cn') {'案板'} else {'cutting board'}
        if ($page.Count -ne 1 -or $page[0].text -notmatch $required) { $rowErrors.Add("missing whole-fruit processing guide: $lang") }
    }
    return [pscustomobject]@{ FruitId=$fruit; SliceId=$slice; StateCombinations=$count; DeadClass='DeadCropBlock' }
}
