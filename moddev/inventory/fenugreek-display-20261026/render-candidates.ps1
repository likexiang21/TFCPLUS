param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/fenugreek-display-20261026'
foreach($phase in @('before','candidate')){
 foreach($pitch in @(28,5,70)){
  & '.\.probe\texture-design\rr-review.ps1' -ModelFile (Join-Path $out "$phase-models.txt") -Out (Join-Path $out "AR4M-$phase-p$pitch.png") -AssetRoot (Join-Path $out "assets-$phase") -Pitch $pitch -Yaw 40 -Scale 20 -Per 5 -Cell 300 -Title "$phase rows: crop ages0..4 | crop5,wild mature/young,dead mature/young" *> (Join-Path $out "render-$phase-p$pitch.log")
  if(-not(Test-Path -LiteralPath (Join-Path $out "AR4M-$phase-p$pitch.png"))){throw "Missing preview: $phase $pitch"}
 }
}