param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/napa-cabbage-lifecycle-20261025'
foreach($pitch in @(28,5,70)){
 $file="AR4I-crop-p$pitch.png"
 $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
 if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
 & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out 'crop-models.txt') -Out (Join-Path $out $file) -AssetRoot (Join-Path $out 'assets-before') -Pitch $pitch -Yaw 40 -Scale 20 -Per 3 -Cell 330 -Title 'Napa cabbage crop age0/1/2 top row, age3/4/5 bottom; face geometry unchanged'
 foreach($phase in @('before','candidate')){
  $file="AR4I-$phase-p$pitch.png"
  $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
  if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
  & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out "$phase-models.txt") -Out (Join-Path $out $file) -AssetRoot (Join-Path $out "assets-$phase") -Pitch $pitch -Yaw 40 -Scale 20 -Per 4 -Cell 330 -Title 'Napa cabbage: wild mature | wild young | dead mature | dead young'
 }
}
