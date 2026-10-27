param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$assets=Join-Path $Workspace 'moddev/tfcfarmingplus/src/main/resources/assets'
$out=Join-Path $Workspace 'moddev/inventory/seedling-visuals-20261025'
$files=@()
foreach($name in @('broccoli_age_0','kale_age_0','lettuce_age_0','broccoli_leafball_0','kale_rosette_0','lettuce_leafball_0')){$files+=Join-Path $assets "tfcfarmingplus/textures/block/crop/$name.png"}
& ./.probe/texture-design/contact.ps1 -Files $files -Cols 3 -Scale 12 -Out (Join-Path $out 'AR4A-textures.png') -Title 'Top: legacy age0; Bottom: active seedling textures'
foreach($pitch in @(28,5,70)){
    $name="AR4A-seedlings-p$pitch-20261025.png"
    $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($name))
    if(Test-Path -LiteralPath $temp){throw "Preview temp folder already exists: $temp"}
    & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out 'models.txt') -Out (Join-Path $out $name) -AssetRoot $assets -Pitch $pitch -Yaw 40 -Scale 24 -Per 3 -Cell 244
}
