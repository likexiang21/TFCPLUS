param([string]$SourceInstance='', [string]$ReportDirectory='')
# Reviewed source geometry and resources; this is not runtime or visual acceptance.
$ErrorActionPreference='Stop'
$live=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$live}
$module=Join-Path $instance 'moddev/tfcfarmingplus'
$resources=Join-Path $module 'src/main/resources'
$other=Join-Path $instance 'moddev/tfcagricultureplus/src/main/resources'
$contract=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'sunflower-display-contract.json') -Raw -Encoding UTF8|ConvertFrom-Json
$errors=New-Object 'System.Collections.Generic.List[string]'
$cases=New-Object 'System.Collections.Generic.List[object]'
function Check([bool]$Ok,[string]$Message){if(-not $Ok){$errors.Add($Message)}}
function Read-Json([string]$Relative){
    $p=Join-Path $resources $Relative
    if(-not(Test-Path -LiteralPath $p)){return $null}
    try{return Get-Content -LiteralPath $p -Raw -Encoding UTF8|ConvertFrom-Json}catch{$errors.Add("Invalid JSON: $Relative");return $null}
}
function Pin-Files($Pins,[string]$Base,[bool]$CheckOther){
    foreach($entry in $Pins.PSObject.Properties){
        $path=Join-Path $Base $entry.Name
        if($CheckOther){Check (-not(Test-Path -LiteralPath (Join-Path $other $entry.Name))) "B shadows sunflower resource: $($entry.Name)"}
        if(-not(Test-Path -LiteralPath $path)){$errors.Add("Missing protected sunflower input: $($entry.Name)");continue}
        Check ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $entry.Value) "Reviewed sunflower file changed: $($entry.Name)"
    }
}
Pin-Files $contract.ReviewedJsonSha256 $resources $true
Pin-Files $contract.ProtectedTextureSha256 $resources $true
Pin-Files $contract.ProtectedGameplaySha256 $module $false
function State-Case([string]$Form,$Values,[string]$Expected){
    $j=Read-Json "assets/tfcfarmingplus/blockstates/$Form/sunflower.json"
    if(-not $j){return}
    $matches=@()
    foreach($variant in $j.variants.PSObject.Properties){
        $selected=$true
        foreach($clause in $variant.Name.Split(',')){
            $pair=$clause.Split('=',2)
            if($pair.Count -ne 2 -or $Values[$pair[0]] -cne $pair[1]){$selected=$false}
        }
        if($selected){$matches+=@($variant.Value)}
    }
    Check ($matches.Count -eq 1) "Sunflower ambiguous/missing state: $Form $($Values|ConvertTo-Json -Compress)"
    if($matches.Count -eq 1){Check ($matches[0].model -ceq $Expected) "Sunflower wrong state model: $Expected"}
    $cases.Add([pscustomobject]@{Form=$Form;Properties=$Values;Model=$Expected})
}
foreach($age in 0..5){foreach($part in @('bottom','top')){
    $suffix=if($age -ge 3){"_$part"}else{''}
    State-Case 'crop' @{age=[string]$age;part=$part} "tfcfarmingplus:block/crop/sunflower_age_${age}$suffix"
}}
foreach($mature in @('false','true')){foreach($part in @('bottom','top')){
    $suffix=if($mature -eq 'false'){'_young'}elseif($part -eq 'top'){'_top'}else{''}
    State-Case 'dead_crop' @{mature=$mature;part=$part} "tfcfarmingplus:block/dead_crop/sunflower$suffix"
}}
foreach($mature in @('false','true')){
    $suffix=if($mature -eq 'false'){'_young'}else{''}
    State-Case 'wild_crop' @{mature=$mature} "tfcfarmingplus:block/wild_crop/sunflower$suffix"
}
# Check independently meaningful geometry constraints in addition to reviewed hashes.
foreach($relative in $contract.ReviewedJsonSha256.PSObject.Properties.Name){
    if($relative -notlike 'assets/*/models/block/*'){continue}
    $j=Read-Json $relative
    foreach($element in $j.elements){
        foreach($end in @('from','to')){Check (@($element.$end).Count -eq 3) "Invalid sunflower coordinates: $relative"}
        if($element.rotation){Check ($element.rotation.angle -in @(-45,-22.5,0,22.5,45)) "Invalid sunflower rotation: $relative"}
        foreach($face in $element.faces.PSObject.Properties){
            $axis=switch($face.Name){'east'{0};'west'{0};'up'{1};'down'{1};'north'{2};'south'{2}}
            foreach($index in 0..2){if($index -ne $axis){Check ($element.to[$index] -gt $element.from[$index]) "Degenerate sunflower face: $relative/$($face.Name)"}}
            Check (@($face.Value.uv).Count -eq 4) "Missing sunflower UV: $relative"
        }
    }
}
foreach($age in 3..5){
    $j=Read-Json "assets/tfcfarmingplus/models/block/crop/sunflower_age_${age}_top.json"
    if(-not $j){continue}
    $heads=@($j.elements|Where-Object{@($_.faces.PSObject.Properties.Value.texture) -contains '#head'})
    $stems=@($j.elements|Where-Object{@($_.faces.PSObject.Properties.Value.texture) -contains '#crop'})
    Check ($heads.Count -eq 1 -and $stems.Count -eq 2) "Sunflower head/stem layout changed at age $age"
    if($heads.Count -eq 1){foreach($stem in $stems){Check ($stem.to[1] -le $heads[0].from[1]) "Sunflower leaves occlude head at age $age"}}
}
$planter=Read-Json 'data/firmalife/firmalife/plantable/sunflower.json'
Check ($planter.stages -eq 5 -and @($planter.textures).Count -eq 6) 'Sunflower planter stage mapping changed'
Check ((@($planter.textures)-join '|') -ceq (@($contract.PlanterStageTextures)-join '|')) 'Sunflower planter reverted to borrowed atlas'
$report=[pscustomobject]@{StateCases=$cases.ToArray();ReviewedJSONs=$contract.ReviewedJsonSha256.PSObject.Properties.Name.Count;ProtectedPNGs=$contract.ProtectedTextureSha256.PSObject.Properties.Name.Count;ProtectedGameplay=$contract.ProtectedGameplaySha256.PSObject.Properties.Name.Count;Findings=$errors.ToArray();VisualAccepted=$false;RuntimeVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'sunflower-display-contracts.json'),($report|ConvertTo-Json -Depth 25),[Text.UTF8Encoding]::new($false))
}
Write-Output "[INFO] sunflower display: states=$($cases.Count); JSONs=$($report.ReviewedJSONs); PNGs=$($report.ProtectedPNGs); gameplay=$($report.ProtectedGameplay); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "  [FAIL] $_"};exit 1}
Write-Output '[OK] Sunflower display contracts passed; appearance and runtime await player review.'
exit 0
