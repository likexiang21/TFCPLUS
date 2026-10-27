# Canonical shared dead-rosette bundle. Copy existing bytes; never regenerate its artwork.
. (Join-Path $PSScriptRoot 'cocoa-data-policy.ps1')
function Copy-ReviewedSharedDead([string]$OutputRoot, [switch]$ModelsOnly) {
    $target=Resolve-LegacyGeneratorOutput $OutputRoot
    $source=Join-Path (Split-Path $PSScriptRoot -Parent) 'src/main/resources'
    $selected=@(
        'assets/tfcfarmingplus/models/block/dead_rosette.json'
        'assets/tfcfarmingplus/models/block/dead_rosette_young.json'
        'assets/tfcfarmingplus/models/block/crop/rosette_dead.json'
        'assets/tfcfarmingplus/models/block/crop/rosette_dead_young.json'
        'assets/tfcfarmingplus/textures/block/crop/rosette_dead.png'
        'assets/tfcfarmingplus/textures/block/crop/rosette_dead_young.png'
    )
    if(-not $ModelsOnly){$selected+=@('assets/tfcfarmingplus/blockstates/dead_rosette.json','data/tfcfarmingplus/loot_table/blocks/dead_rosette.json')}
    foreach($relative in $selected){if(-not(Test-Path -LiteralPath (Join-Path $source $relative))){throw "Reviewed shared dead resource missing: $relative"}}
    foreach($relative in $selected){
        $output=Join-Path $target $relative
        [void][IO.Directory]::CreateDirectory((Split-Path $output -Parent))
        [IO.File]::WriteAllBytes($output,[IO.File]::ReadAllBytes((Join-Path $source $relative)))
    }
    Write-Output "[OK] copied $($selected.Count) reviewed shared dead resources byte-for-byte; no image generation"
}
