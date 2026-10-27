# Read-only source/resource checks; this does not simulate world ticks.
function Assert-RosetteCrop([string]$name, $state, $cropLoot, [int]$maxAge, [string]$product, $rowErrors) {
    $java = Get-Content -LiteralPath (Join-Path $module 'src/main/java/com/example/tfcfarmingplus/common/blocks/RosetteCropBlock.java') -Raw -Encoding UTF8
    if ($java -notmatch 'extends CropBlock' -or $java -match 'void growthTick\(') { $rowErrors.Add('rosette must retain native growth/calendar processing') }
    if ($java -notmatch 'registerDefaultState\(defaultBlockState\(\).setValue\(AGE, 0\).setValue\(FRUITING, false\)\)') { $rowErrors.Add('seedling default must explicitly disable fruiting') }
    if ($java -notmatch 'setValue\(FRUITING, growth >= 1.0f\)') { $rowErrors.Add('fruiting must follow actual maturity, including legacy inconsistent states') }
    if ($java -notmatch 'level.isClientSide\(\) \|\| !level.getBlockState\(pos\).is\(this\)' -or
        $java -notmatch '(?s)if \(level.setBlockAndUpdate\(pos, dead.get\(\).*?Block.popResource\(level, pos, new ItemStack\(seeds.get\(\)\)\)') { $rowErrors.Add('death must return one species seed only after a server-side live-to-dead transition') }
    $factory = [regex]::Match($source, '(?s)private static DeferredHolder<Block, RosetteCropBlock> rosette\(.*?\n    \}').Value
    if ($factory -notmatch 'blockEntity\(MyBlockEntities.CROP\)' -or $factory -notmatch 'serverTicks\(CropBlockEntity::serverTick\)' -or
        $factory -notmatch 'MyBlocks.DEAD_ROSETTE.get\(\), seedFor\(name\)') { $rowErrors.Add('rosette factory crop/dead/seed/ticker contract mismatch') }
    $entities = Get-Content -LiteralPath (Join-Path $module 'src/main/java/com/example/tfcfarmingplus/common/MyBlockEntities.java') -Raw -Encoding UTF8
    if ($entities -notmatch 'new CropBlockEntity\(MyBlockEntities.CROP.get\(\), pos, state\)') { $rowErrors.Add('crop save reload factory must use project BE type') }
    if (@($state.variants.PSObject.Properties).Count -ne 12) { $rowErrors.Add('rosette needs all twelve age/fruiting variants') }
    $seed = "tfcfarmingplus:seeds/$name"
    $count = 0
    foreach ($age in 0..$maxAge) { foreach ($fruiting in @('false','true')) {
        $values = @{age=[string]$age; fruiting=$fruiting}
        $modelId = Resolve-CropVariant $state $values
        $suffix = if ($fruiting -eq 'true') { '_fruiting' } else { '' }
        if ($modelId -ne "tfcfarmingplus:block/crop/${name}_age_${age}$suffix") { $rowErrors.Add("rosette model mismatch: $age/$fruiting") }
        $model = Read-Resource ("assets/tfcfarmingplus/models/" + $modelId.Split(':')[1] + '.json')
        $ripe = $age -eq $maxAge -and $fruiting -eq 'true'
        $parentSuffix = if ($ripe) { '_fruiting' } else { '' }
        if ($model.parent -ne "tfcfarmingplus:block/crop/rosette_age_${age}$parentSuffix" -or $model.textures.'0' -ne "tfcfarmingplus:block/crop/${name}_rosette_${age}$parentSuffix") { $rowErrors.Add("rosette geometry/leaf texture mismatch: $age/$fruiting") }
        if ($ripe -and ($model.textures.'1' -ne "tfcfarmingplus:block/crop/${name}_rosette_fruit_top" -or $model.textures.'2' -ne "tfcfarmingplus:block/crop/${name}_rosette_fruit")) { $rowErrors.Add('ripe centre must retain its independent top/side textures') }
        $items = @(Get-CropLootItems @($cropLoot) "tfcfarmingplus:crop/$name" $values)
        $expected = @($seed); if ($ripe) { $expected += $product }
        if (@(Compare-Object @($expected | Sort-Object) @($items | Sort-Object)).Count) { $rowErrors.Add("rosette harvest mismatch: $age/$fruiting") }
        $count++
    } }
    $seedNodes = @(Get-JsonObjects $cropLoot | Where-Object { $_.type -eq 'minecraft:item' -and $_.name -eq $seed })
    $seedFunctions = @($seedNodes.functions)
    if ($seedNodes.Count -ne 1 -or $seedFunctions.Count -ne 1 -or $seedFunctions[0].function -ne 'minecraft:set_count' -or
        $seedFunctions[0].count.type -ne 'minecraft:uniform' -or $seedFunctions[0].count.min -ne 1 -or $seedFunctions[0].count.max -ne 2) { $rowErrors.Add('live rosette harvest must return one to two sidebuds') }
    $wildLoot = Read-Resource "data/tfcfarmingplus/loot_table/blocks/wild_crop/$name.json"
    foreach ($mature in @('false','true')) {
        $items = @(Get-CropLootItems @($wildLoot) "tfcfarmingplus:wild_crop/$name" @{mature=$mature})
        $expected = @($seed); if ($mature -eq 'true') { $expected += $product }
        if (@(Compare-Object @($expected | Sort-Object) @($items | Sort-Object)).Count) { $rowErrors.Add("wild rosette harvest mismatch: $mature") }
        $count++
    }
    $deadState = Read-Resource 'assets/tfcfarmingplus/blockstates/dead_rosette.json'
    $deadLoot = Read-Resource 'data/tfcfarmingplus/loot_table/blocks/dead_rosette.json'
    if (@($deadLoot.pools).Count) { $rowErrors.Add('shared dead rosette must not duplicate the seed already returned on death') }
    foreach ($mature in @('false','true')) {
        $model = Resolve-CropVariant $deadState @{mature=$mature}
        $expected = if ($mature -eq 'true') { 'tfcfarmingplus:block/dead_rosette' } else { 'tfcfarmingplus:block/dead_rosette_young' }
        if ($model -ne $expected) { $rowErrors.Add('shared dead rosette model mismatch') }
    }
    foreach ($lang in @('zh_cn','en_us')) {
        $book = $guides[$lang]; $index = -1
        for ($i=0; $i -lt $book.pages.Count; $i++) { if ($book.pages[$i].anchor -eq $name) { $index=$i; break } }
        if ($index -lt 0) { $rowErrors.Add("missing rosette guide: $lang"); continue }
        $required = if ($lang -eq 'zh_cn') { @('莲座','1至2','枯死','右键') } else { @('rosette','one to two','dies','right-click') }
        foreach ($word in $required) { if ($book.pages[$index].text -notmatch [regex]::Escape($word)) { $rowErrors.Add("missing rosette control/death guidance: $lang/$word") } }
        $frames = @($book.pages[$index+1].multiblocks)
        if ($frames.Count -ne 7) { $rowErrors.Add("guide must show six leaf stages plus fruiting: $lang"); continue }
        foreach ($age in 0..5) { if ($frames[$age].mapping.X -ne "tfcfarmingplus:crop/$name[age=$age,fruiting=false]") { $rowErrors.Add("wrong guide unripe stage: $lang/$age") } }
        if ($frames[6].mapping.X -ne "tfcfarmingplus:crop/$name[age=5,fruiting=true]") { $rowErrors.Add("missing guide fruiting frame: $lang") }
    }
    return [pscustomobject]@{DeadClass='DeadCropBlock (shared dead_rosette)'; StateCombinations=$count}
}
