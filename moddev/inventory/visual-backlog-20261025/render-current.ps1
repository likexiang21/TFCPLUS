param([string]$Workspace)
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $Workspace
$out=Join-Path $Workspace 'moddev/inventory/visual-backlog-20261025'
foreach($pitch in @(28,5,70)){
 & '.\.probe\texture-design\rr-review.ps1' -ModelFile (Join-Path $out 'current-models.txt') -Out (Join-Path $out "AR4K-current-p$pitch.png") -AssetRoot (Join-Path $out 'assets-current') -Pitch $pitch -Yaw 40 -Scale 16 -Per 6 -Cell 260 -Title 'CURRENT source: chili6 | fenugreek6 | dead bush3 | papaya4' *> (Join-Path $out "winps-render-p$pitch.log")
 if(-not (Test-Path -LiteralPath (Join-Path $out "AR4K-current-p$pitch.png"))){throw "Render missing: $pitch"}
}