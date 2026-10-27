param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/leafball-support-20261025'
foreach($view in @(@(28,40),@(5,40),@(5,220),@(70,40))){
 foreach($phase in @('before','candidate')){
  $pitch=$view[0];$yaw=$view[1];$file="AR4J-five-$phase-all-p$pitch-y$yaw.png"
  $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
  if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
  & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out 'all-five-models.txt') -Out (Join-Path $out $file) -AssetRoot (Join-Path $out "assets-$phase") -Pitch $pitch -Yaw $yaw -Scale 14 -Per 4 -Cell 235 -Title 'Rows broccoli/lettuce/cauliflower/napa/TFC cabbage; columns ages2/3/4/5'
 }
}
foreach($yaw in @(40,220)){
 foreach($phase in @('before','candidate','opaque','leaves-only','head-only')){
  $file="AR4J-five-$phase-age2-p5-y$yaw.png"
  $temp=Join-Path $Workspace ('.probe/texture-design/px/_rr/'+[IO.Path]::GetFileNameWithoutExtension($file))
  if(Test-Path -LiteralPath $temp){throw "Existing preview temp: $temp"}
  & ./.probe/texture-design/rr-review.ps1 -ModelFile (Join-Path $out 'age2-five-models.txt') -Out (Join-Path $out $file) -AssetRoot (Join-Path $out "assets-$phase") -Pitch 5 -Yaw $yaw -Scale 20 -Per 5 -Cell 290 -Title "Age2 ${phase}: broccoli | lettuce | cauliflower | napa | TFC cabbage"
 }
}
