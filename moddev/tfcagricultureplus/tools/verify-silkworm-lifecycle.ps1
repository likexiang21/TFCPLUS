$ErrorActionPreference = 'Stop'

$projectDir = Split-Path $PSScriptRoot -Parent
$srcRoot = Join-Path $projectDir 'src/main'

function Require-File([string]$relativePath) {
    $path = Join-Path $srcRoot $relativePath
    if (-not (Test-Path $path)) { throw "Missing silkworm lifecycle file: $relativePath" }
    return Get-Content -Raw $path
}

function Require-Text([string]$text, [string]$needle, [string]$label) {
    if (-not $text.Contains($needle)) { throw "Missing silkworm lifecycle contract: $label" }
}

$rack = Require-File 'java/com/example/tfcfarmingplus/expansion/common/blockentities/SilkwormRackBlockEntity.java'
$data = Require-File 'java/com/example/tfcfarmingplus/expansion/common/SilkwormData.java'
$adult = Require-File 'java/com/example/tfcfarmingplus/expansion/common/AdultSilkwormItem.java'
$events = Require-File 'java/com/example/tfcfarmingplus/expansion/common/SilkwormContainerEvents.java'
$menu = Require-File 'java/com/example/tfcfarmingplus/expansion/common/container/SilkwormRackMenu.java'
$screen = Require-File 'java/com/example/tfcfarmingplus/expansion/client/SilkwormRackScreen.java'
$feedTagPath = Join-Path $srcRoot 'resources/data/tfcagricultureplus/tags/item/silkworm_feed.json'
$feedTag = Get-Content -Raw $feedTagPath

foreach ($contract in @(
    @($rack, 'BIOLOGICAL_SLOTS = 8', 'eight biological slots'),
    @($rack, 'FEED_START = 8', 'feed start slot'),
    @($rack, 'FEED_SLOTS = 2', 'two feed slots'),
    @($rack, 'OUTPUT_SLOT = 10', 'single output slot'),
    @($rack, 'TickableInventoryBlockEntity<ItemStackHandler>', 'TFC inventory base'),
    @($rack, 'Climate.getInstantTemperature', 'TFC climate temperature'),
    @($rack, 'temperature >= 0.0F', 'egg hatch lower temperature bound'),
    @($rack, 'HATCH_MIN_DAYS = 2', 'egg hatch minimum'),
    @($rack, 'COCOON_MIN_DAYS = 3', 'cocoon minimum'),
    @($rack, 'return slot < BIOLOGICAL_SLOTS ? 1 : 64;', 'stacked feed and single biological slots'),
    @($rack, 'SilkwormData.ageAdult', 'adult ageing'),
    @($rack, 'produceEggs', 'adult breeding'),
    @($rack, 'setStackInSlot(OUTPUT_SLOT', 'output insertion'),
    @($rack, 'isItemValid', 'slot validation'),
    @($data, 'BIRTH_DAY', 'birth day data'),
    @($data, 'GROWTH', 'growth data'),
    @($data, 'HUNGER', 'hunger data'),
    @($data, 'CUSTOM_DATA', 'persistent custom data'),
    @($adult, 'LIFE_DAYS = 7', 'seven day adult lifespan'),
    @($adult, 'durability(LIFE_DAYS)', 'durability lifespan'),
    @($adult, 'adult_silkworm_remaining', 'remaining lifespan tooltip'),
    @($events, 'PlayerContainerEvent.Open', 'container open event'),
    @($events, 'ageAdult', 'open container ageing'),
    @($events, 'ItemStack.EMPTY', 'expired adult removal'),
    @($menu, 'BlockEntityContainer', 'TFC block entity menu'),
    @($menu, 'CallbackSlot', 'TFC callback slots'),
    @($menu, 'FEED_START + i, 8 + i * 18, 54', 'feed slots aligned with feed texture row'),
    @($menu, 'OUTPUT_SLOT, 152, 54', 'output slot aligned with the output row'),
    @($screen, 'this.imageWidth = 176', 'reference-width screen'),
    @($screen, 'this.imageHeight = 168', 'compact chest-height screen'),
    @($screen, 'for (int column = 0; column < 8; column++)', 'eight biological slots'),
    @($screen, 'for (int row = 0; row < 3; row++)', 'three player inventory rows'),
    @($screen, 'for (int column = 0; column < 9; column++)', 'nine-column player inventory'),
    @($screen, 'silkworm_slot.png', 'reference slot texture'),
    @($screen, 'silkworm_biological', 'biological slot label'),
    @($screen, 'silkworm_feed', 'feed slot label'),
    @($screen, 'silkworm_output', 'output slot label'),
    @($screen, 'player_inventory', 'player inventory title'),
    @($feedTag, 'firmalife:fruit_leaf', 'Firmalife feed'),
    @($feedTag, 'tfcfarmingplus:plant/mulberry_leaves', 'mulberry feed')
)) {
    Require-Text $contract[0] $contract[1] $contract[2]
}

if (-not (Test-Path (Join-Path $srcRoot 'resources/assets/tfcagricultureplus/textures/gui/silkworm_slot.png'))) {
    throw 'Missing silkworm slot texture'
}

if ($rack.Contains('while (rack.lastProcessedDay < end)')) { throw 'Silkworm lifecycle must not use the old unbounded replay loop' }
if ($rack.Contains('growthTemperature')) { throw 'Silkworm larvae and cocoons must not have growth temperature restrictions' }
if (-not $rack.Contains('settled++ < 32')) { throw 'Silkworm lifecycle must cap catch-up work per tick' }
if ($rack.Contains('food/cooked_silkworm')) { throw 'Cooked silkworm must not use a food namespace path' }
if ($rack.Contains('tfcagricultureplus:food/cooked_silkworm')) { throw 'Cooked silkworm must not be treated as food' }

foreach ($recipe in @(
    'data/tfcagricultureplus/recipe/crafting/silkworm_hatch.json',
    'data/tfcagricultureplus/recipe/pot/cocoon_to_silk_thread.json',
    'data/tfcagricultureplus/recipe/crafting/cooked_silkworm_to_silk_thread.json',
    'data/tfcagricultureplus/recipe/loom/silk_cloth.json'
)) {
    if (-not (Test-Path (Join-Path $srcRoot "resources/$recipe"))) { throw "Missing silkworm recipe: $recipe" }
    Get-Content -Raw (Join-Path $srcRoot "resources/$recipe") | ConvertFrom-Json | Out-Null
}

Write-Output '[OK] silkworm lifecycle contract: slots, climate, ageing, persistence, UI and post-processing'
