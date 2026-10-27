# Static source/resource contracts. The host audit supplies parsers and findings.
function Assert-FloodedCrop([string]$name, [string]$call, $state, $cropLoot, [int]$maxAge, [string]$product, $rowErrors) {
    $wildSource = Get-Content -LiteralPath (Join-Path $module 'src/main/java/io/github/likexiang21/tfcplus/farming/common/crop\FarmingWildCrops.java') -Raw -Encoding UTF8
    $factory = Get-Content -LiteralPath (Join-Path $module 'src/main/java/io/github/likexiang21/tfcplus/farming/common/block/FarmingFloodedCropBlock.java') -Raw -Encoding UTF8
    if ($factory -notmatch 'extends FloodedCropBlock' -or $factory -notmatch 'new FarmingFloodedCropBlock\(properties, maxAge, dead, seeds') { $rowErrors.Add('unreviewed flooded crop inheritance or age contract') }
    if ($factory -match '(?m)^\s*(?:public|protected)\s+(?:void|boolean|float|BlockState|FluidState|FluidProperty)\s+(?:die|growthTick|postGrowthTick|getGrowthLimit|getStateForPlacement|canSurvive|updateShape|getFluidState|getFluidProperty)\(') {
        $rowErrors.Add('flooded crop overrides a native lifecycle method; requires review')
    }
    $cropFactory = [regex]::Match($source, '(?s)private static DeferredHolder<Block, FarmingFloodedCropBlock> flooded\(.*?\n    \}').Value
    if ($cropFactory -notmatch 'blockEntity\(FarmingBlockEntities.CROP\)' -or $cropFactory -notmatch 'serverTicks\(CropBlockEntity::serverTick\)') { $rowErrors.Add('missing flooded crop BE/ticker binding') }
    $deadField = [regex]::Match($call, 'FarmingCrops\.(DEAD_[A-Z_]+)\.get').Groups[1].Value
    $deadCall = [regex]::Match($source, ('DeferredHolder<Block, [^>]+>\s+' + $deadField + '\s*=\s*([^;]+);')).Groups[1].Value
    if ($deadCall -notmatch ('deadFlooded\("' + $name + '"')) { $rowErrors.Add('flooded dead crop class mismatch') }
    $deadFactory = [regex]::Match($source, '(?s)private static DeferredHolder<Block, DeadCropBlock> deadFlooded\(.*?\n    \}').Value
    if ($deadFactory -notmatch 'new FloodedDeadCropBlock\(FarmingBlocks.deadProps\(\), climateRange\)') { $rowErrors.Add('unreviewed flooded dead crop factory') }
    if ($wildSource -notmatch ('wildFlooded\("' + $name + '"\)') -or $wildSource -notmatch 'new FloodedWildCropBlock\(FarmingBlocks.deadProps\(\)\)') { $rowErrors.Add('flooded wild crop class mismatch') }
    $meta = @($manifest.crops | Where-Object { $_.name -eq $name })
    if ($meta.Count -ne 1 -or -not $meta[0].flooded) { $rowErrors.Add('flooded manifest shape mismatch') }
    $seed = "tfcfarmingplus:seeds/$name"
    $count = 0
    foreach ($age in 0..$maxAge) { foreach ($fluid in @('empty','water')) {
        $values = @{ age=[string]$age; fluid=$fluid }
        $model = Resolve-CropVariant $state $values
        if ($model -ne "tfcfarmingplus:block/crop/${name}_age_$age") { $rowErrors.Add("flooded model/age mismatch: $age/$fluid") }
        $items = @(Get-CropLootItems @($cropLoot) "tfcfarmingplus:crop/$name" $values)
        $expected = @($seed)
        if ($age -eq $maxAge) { $expected += $product }
        if (@(Compare-Object @($expected | Sort-Object) @($items | Sort-Object)).Count) { $rowErrors.Add("flooded harvest mismatch: $age/$fluid") }
        $count++
    } }
    foreach ($kind in @('dead_crop','wild_crop')) {
        $definition = Read-Resource "assets/tfcfarmingplus/blockstates/$kind/$name.json"
        $loot = Read-Resource "data/tfcfarmingplus/loot_table/blocks/$kind/$name.json"
        foreach ($mature in @('false','true')) { foreach ($fluid in @('empty','water')) {
            $values = @{ mature=$mature; fluid=$fluid }
            $null = Resolve-CropVariant $definition $values
            $items = @(Get-CropLootItems @($loot) "tfcfarmingplus:$kind/$name" $values)
            $expected = @($seed)
            if ($kind -eq 'wild_crop' -and $mature -eq 'true') { $expected += $product }
            if (@(Compare-Object @($expected | Sort-Object) @($items | Sort-Object)).Count) { $rowErrors.Add("flooded $kind loot mismatch: $mature/$fluid") }
            $count++
        } }
    }
    $feature = Read-Resource "data/tfcfarmingplus/worldgen/configured_feature/plant/wild_crop/$name.json"
    if ($feature.type -ne 'tfc:block_with_fluid') { $rowErrors.Add('wild flooded feature does not retain the existing fluid') }
    if ($feature.config.to_place.type -ne 'minecraft:simple_state_provider' -or $feature.config.to_place.state.Name -ne "tfcfarmingplus:wild_crop/$name") { $rowErrors.Add('wild flooded feature places the wrong state') }
    if ($null -ne $feature.config.to_place.state.Properties.fluid) { $rowErrors.Add('wild generation forces fluid instead of inheriting the water at the position') }
    $placement = Read-Resource "data/tfcfarmingplus/worldgen/placed_feature/plant/wild_crop/$name.json"
    if ($placement.feature -ne "tfcfarmingplus:plant/wild_crop/$name") { $rowErrors.Add('wrong flooded placement feature reference') }
    $steps = @($placement.placement)
    if ($steps.Count -ne 3 -or $steps[0].type -ne 'minecraft:heightmap' -or $steps[0].heightmap -ne 'OCEAN_FLOOR_WG') { $rowErrors.Add('wild flooded placement does not start at the submerged ground surface') }
    if ($steps.Count -lt 3 -or $steps[1].type -ne 'minecraft:block_predicate_filter' -or $steps[1].predicate.type -ne 'minecraft:matching_fluids' -or
        @($steps[1].predicate.fluids).Count -ne 1 -or $steps[1].predicate.fluids[0] -ne 'minecraft:water') { $rowErrors.Add('wild flooded placement lacks the reviewed fresh-water source filter') }
    if ($steps.Count -lt 3 -or $steps[2].type -ne 'minecraft:block_predicate_filter' -or $steps[2].predicate.type -ne 'minecraft:would_survive' -or
        $steps[2].predicate.state.Name -ne "tfcfarmingplus:wild_crop/$name") { $rowErrors.Add('wild flooded placement lacks its soil/depth survival check') }
    $patch = Read-Resource "data/tfcfarmingplus/worldgen/configured_feature/plant/wild_crop/${name}_patch.json"
    if ($patch.type -ne 'minecraft:random_patch' -or $patch.config.feature -ne "tfcfarmingplus:plant/wild_crop/$name") { $rowErrors.Add('wild flooded patch reference mismatch') }
    $tag = Read-Resource 'data/tfc/tags/worldgen/placed_feature/feature/crops.json'
    if ($tag.replace -ne $false -or "tfcfarmingplus:plant/wild_crop/${name}_patch" -notin $tag.values) { $rowErrors.Add('wild flooded patch missing from the additive worldgen tag') }
    foreach ($lang in @('zh_cn','en_us')) {
        $page = @($guides[$lang].pages | Where-Object { $_.anchor -eq $name })
        $needed = if ($lang -eq 'zh_cn') { '先.*开垦.*淡水水源.*最后.*播种' } else { 'Prepare.*farmland.*fresh water source.*then sow' }
        if ($page.Count -ne 1 -or $page[0].text -notmatch $needed) { $rowErrors.Add("incorrect flooded sowing order: $lang") }
        $wildGuide = Read-Resource "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/wild_crops.json"
        $page = @($wildGuide.pages | Where-Object { $_.anchor -eq $name })
        $needed = if ($lang -eq 'zh_cn') { '一格深.*淡水' } else { 'one-block-deep fresh water' }
        if ($page.Count -ne 1 -or $page[0].text -notmatch $needed) { $rowErrors.Add("wild flooded habitat missing from guide: $lang") }
        $diagrams = @($guides[$lang].pages | Where-Object { $_.type -eq 'tfc:multimultiblock' -and $_.multiblocks.mapping.X -match ("^tfcfarmingplus:crop/" + $name + '\[') })
        if ($diagrams.Count -ne 1 -or @($diagrams[0].multiblocks).Count -ne $maxAge + 1) { $rowErrors.Add("flooded handbook stage count mismatch: $lang") }
        else {
            $diagramAges = @()
            foreach ($example in $diagrams[0].multiblocks) {
                $m = [regex]::Match($example.mapping.X, ('^tfcfarmingplus:crop/' + $name + '\[age=(\d+),fluid=water\]$'))
                if (-not $m.Success) { $rowErrors.Add("flooded diagram missing water state: $lang") } else { $diagramAges += [int]$m.Groups[1].Value }
            }
            if (@(Compare-Object @(0..$maxAge) $diagramAges).Count) { $rowErrors.Add("flooded diagram ages mismatch: $lang") }
        }
    }
    return [pscustomobject]@{ DeadClass='FloodedDeadCropBlock'; FluidStates='empty,water'; StateCombinations=$count; WildRule='一格深淡水水源；原生野生作物土壤；顶部无水' }
}
