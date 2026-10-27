param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/broccoli-wild-dead-20261025'
foreach($pitch in @(28,5,70)){
 foreach($phase in @('before','candidate')){
  $file="AR4D-$phase-p$pitch.png"
  $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
  if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
  & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out "$phase-models.txt") -Out (Join-Path $out $file) -AssetRoot (Join-Path $out "assets-$phase") -Pitch $pitch -Yaw 40 -Scale 20 -Per 4 -Cell 310 -Title 'Broccoli: wild mature | wild young | dead mature | dead young'
 }
}
