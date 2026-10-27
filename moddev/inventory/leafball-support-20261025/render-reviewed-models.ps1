param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/leafball-support-20261025'
foreach($view in @(@(28,40),@(5,40),@(5,220),@(70,40))){
 $pitch=$view[0];$yaw=$view[1]
 foreach($phase in @('before','candidate')){
  $file="AR4J-$phase-all-p$pitch-y$yaw.png"
  $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
  if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
  & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out 'all-models.txt') -Out (Join-Path $out $file) -AssetRoot (Join-Path $out "assets-$phase") -Pitch $pitch -Yaw $yaw -Scale 14 -Per 4 -Cell 235 -Title 'Rows: broccoli/lettuce/cauliflower/napa; columns: age2/3/4/5'
 }
}
foreach($yaw in @(40,220)){
 foreach($phase in @('before','candidate','opaque','leaves-only','head-only')){
  $file="AR4J-$phase-age2-p5-y$yaw.png"
  $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
  if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
  & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out 'age2-models.txt') -Out (Join-Path $out $file) -AssetRoot (Join-Path $out "assets-$phase") -Pitch 5 -Yaw $yaw -Scale 22 -Per 4 -Cell 320 -Title "Age2 $phase diagnostic: broccoli | lettuce | cauliflower | napa cabbage"
 }
}
