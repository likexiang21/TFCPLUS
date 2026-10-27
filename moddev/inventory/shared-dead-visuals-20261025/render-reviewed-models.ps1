param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/shared-dead-visuals-20261025'
foreach($pitch in @(28,5,70)){
 foreach($phase in @('before','whole','slots')){
  $file="AR4G-$phase-p$pitch.png"
  $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
  if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
  & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out 'models.txt') -Out (Join-Path $out $file) -AssetRoot (Join-Path $out "assets-$phase") -Pitch $pitch -Yaw 40 -Scale 20 -Per 2 -Cell 360 -Title 'Shared dead rosette: mature | young (same block for five source crops)'
 }
}
