param([switch]$Check, [switch]$DryRun)
$ErrorActionPreference = 'Stop'
if ($Check -and $DryRun) { throw 'Choose either -Check or -DryRun.' }
. (Join-Path $PSScriptRoot 'cocoa-data-policy.ps1')
$policy = Read-CocoaPolicy
$root = (Resolve-Path -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) 'src/main/resources')).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$plans = @()
function Add-Plan([string]$relative, $value) {
    $script:plans += [pscustomobject]@{
        Relative = $relative
        Path = Join-Path $root $relative
        Text = (($value | ConvertTo-Json -Depth 100).Replace("`r`n", "`n") + "`n")
    }
}
function Read-Resource([string]$relative) {
    return (Get-Content -LiteralPath (Join-Path $root $relative) -Raw -Encoding UTF8 | ConvertFrom-Json)
}
function Update-LegacyLoot($value) {
    if ($null -eq $value) { return }
    if ($value -is [System.Array]) {
        foreach ($child in $value) { Update-LegacyLoot $child }
    } elseif ($value -is [pscustomobject]) {
        if ($value.type -eq 'minecraft:item') {
            switch ($value.name) {
                'tfcfarmingplus:food/cocoa' { $value.name = $policy.product }
                'tfcfarmingplus:plant/cocoa_sapling' { $value.name = $policy.sapling }
                'tfcfarmingplus:plant/cocoa_leaves' { $value.name = $policy.leaves }
            }
        }
        foreach ($property in $value.PSObject.Properties) { Update-LegacyLoot $property.Value }
    }
}
$plantablePath = 'data/firmalife/firmalife/plantable/fpt_cupuacu.json'
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root 'data/firmalife/firmalife/plantable') -File -Filter '*.json') {
    $definition = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($definition.ingredient.item -eq 'tfcfarmingplus:plant/cocoa_sapling') {
        throw ('A planter must not reintroduce the legacy cocoa tree: ' + $file.Name)
    }
}
$plantable = Read-Resource $plantablePath
if ($plantable.ingredient.item -ne $policy.sapling -or $plantable.planter -ne 'bonsai') {
    throw 'Unexpected cupuacu planter input/type.'
}
$plantable.crop.id = $policy.product
Add-Plan $plantablePath $plantable
foreach ($kind in @('leaves', 'sapling', 'branch')) {
    $relative = "data/tfcfarmingplus/loot_table/blocks/plant/cocoa_$kind.json"
    $loot = Read-Resource $relative
    if ($loot.type -ne 'minecraft:block') { throw "Unexpected legacy loot type: $kind" }
    Update-LegacyLoot $loot
    Add-Plan $relative $loot
}
foreach ($lang in @('en_us', 'zh_cn')) {
    $relative = "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus/fruit_trees.json"
    $book = Read-Resource $relative
    $indices = @(0..($book.pages.Count - 1) | Where-Object { $book.pages[$_].anchor -eq $policy.tree })
    if ($indices.Count -ne 1) { throw "Expected one cupuacu guide page: $lang" }
    $at = $indices[0]
    if ($at + 1 -ge $book.pages.Count) { throw "Missing cupuacu diagram: $lang" }
    $book.pages[$at].text = $policy.guide_text.$lang
    $book.pages[$at + 1].text = $policy.diagram_text.$lang
    Set-CupuacuDiagram $book.pages[$at + 1]
    # Keep Firmalife's own cocoa-bean handbook jump authoritative. The cupuacu
    # sapling/leaf mappings remain the entry points to this tree guide.
    foreach ($id in @($policy.retired_product, $policy.legacy_product)) {
        $book.extra_recipe_mappings.PSObject.Properties.Remove($id)
    }
    Add-Plan $relative $book
}
$differences = @()
# Prepare all six resources before touching any live file.
foreach ($plan in $plans) {
    $existing = Get-Content -LiteralPath $plan.Path -Raw -Encoding UTF8 | ConvertFrom-Json
    $normalized = (($existing | ConvertTo-Json -Depth 100).Replace("`r`n", "`n") + "`n")
    if ($normalized -cne $plan.Text) {
        $differences += $plan.Relative
        if (-not $Check -and -not $DryRun) { [IO.File]::WriteAllText($plan.Path, $plan.Text, $utf8) }
    }
}
Write-Output ("[INFO] reviewed cocoa data files = {0}; differences = {1}" -f $plans.Count, $differences.Count)
if ($Check -and $differences.Count) { throw ('Cocoa data policy mismatch: ' + ($differences -join ', ')) }
if ($DryRun) { $differences | ForEach-Object { Write-Output "[PLAN] $_" } }
if ($Check) { Write-Output '[OK] cocoa planter, legacy drops and tree guide match the reviewed policy' }
