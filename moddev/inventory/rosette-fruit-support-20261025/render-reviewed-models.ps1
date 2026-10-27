param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/rosette-fruit-support-20261025'
$files=Get-Content -LiteralPath (Join-Path $out 'textures.txt') -Encoding UTF8
& ./.probe/texture-design/contact.ps1 -Files $files -Cols 6 -Scale 10 -PerPage 30 -Out (Join-Path $out 'AR4C-textures.png') -Title 'Existing foliage and fruit sprites; no PNG edits'
foreach($pitch in @(28,5,70)){
    foreach($kind in @('before','lower-only','supported','vegetative')){
        $root=if($kind -eq 'vegetative'){'assets-before'}else{"assets-$kind"}
        $list=if($kind -eq 'vegetative'){'vegetative-models.txt'}else{'fruiting-models.txt'}
        $name="AR4C-$kind-p$pitch.png"
        $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($name))
        if(Test-Path -LiteralPath $temp){throw "Preview temp already exists: $temp"}
        & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out $list) -Out (Join-Path $out $name) -AssetRoot (Join-Path $out $root) -Pitch $pitch -Yaw 40 -Scale 24 -Per 5 -Cell 310 -Title "AR4C $kind : kale / cardoon / agave / purslane / sisal"
    }
}
