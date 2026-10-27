param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/leaf-vegetable-visuals-20261025'
$paths=Get-Content -LiteralPath (Join-Path $out 'textures.txt') -Encoding UTF8
& ./.probe/texture-design/contact.ps1 -Files $paths -Cols 6 -Scale 8 -PerPage 30 -Out (Join-Path $out 'AR4B-textures.png') -Title 'Actual model-bound textures plus existing per-species candidates'
foreach($pitch in @(28,5,70)){
    foreach($group in @('broccoli','kale','lettuce','other')){
        $file="AR4B-current-$group-p$pitch.png"
        $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
        if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
        & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out "$group-models.txt") -Out (Join-Path $out $file) -AssetRoot (Join-Path $out 'render-assets-current') -Pitch $pitch -Yaw 40 -Scale 20 -Per $(if($group -eq 'other'){4}else{6}) -Cell 250
    }
    $file="AR4B-candidate-other-p$pitch.png"
    $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
    if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
    & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out 'other-models.txt') -Out (Join-Path $out $file) -AssetRoot (Join-Path $out 'render-assets-candidate') -Pitch $pitch -Yaw 40 -Scale 20 -Per 4 -Cell 250
}
