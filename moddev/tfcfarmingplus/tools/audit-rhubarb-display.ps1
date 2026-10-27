param([string]$SourceInstance='', [string]$ReportDirectory='')
# Reviewed source geometry and resources; this is not runtime or visual acceptance.
$ErrorActionPreference='Stop'
$live=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$live}
$module=Join-Path $instance 'moddev/tfcfarmingplus'
$resources=Join-Path $module 'src/main/resources'
$other=Join-Path $instance 'moddev/tfcagricultureplus/src/main/resources'
$contract=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'rhubarb-display-contract.json') -Raw -Encoding UTF8|ConvertFrom-Json
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
        if($CheckOther){Check (-not(Test-Path -LiteralPath (Join-Path $other $entry.Name))) "B shadows rhubarb resource: $($entry.Name)"}
        if(-not(Test-Path -LiteralPath $path)){$errors.Add("Missing protected rhubarb input: $($entry.Name)");continue}
        Check ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $entry.Value) "Reviewed rhubarb file changed: $($entry.Name)"
    }
}
Pin-Files $contract.ReviewedJsonSha256 $resources $true
Pin-Files $contract.ProtectedTextureSha256 $resources $true
Pin-Files $contract.ProtectedGameplaySha256 $module $false

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive=[IO.Compression.ZipFile]::OpenRead((Join-Path $live ('mods/'+$contract.NativeDependency.Jar)))
try{
    foreach($native in $contract.NativeDependency.Files){
        foreach($base in @($resources,$other)){Check (-not(Test-Path -LiteralPath (Join-Path $base $native.Path))) "Source shadows native wild resource: $($native.Path)"}
        $entry=$archive.GetEntry($native.Path)
        Check ($null -ne $entry) "Missing native wild resource: $($native.Path)"
        if($entry){$stream=$entry.Open();$hasher=[Security.Cryptography.SHA256]::Create();try{$hash=[BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$hasher.Dispose()};Check ($hash -eq $native.SHA256) "Native wild dependency changed: $($native.Path)"}
    }
}finally{$archive.Dispose()}
foreach($relative in $contract.ProtectedTextureSha256.PSObject.Properties.Name){
    $path=Join-Path $resources $relative
    if(Test-Path -LiteralPath $path){$bytes=[IO.File]::ReadAllBytes($path);Check ($bytes.Length -ge 24 -and ($bytes[16..23] -join ',') -eq '0,0,0,16,0,0,0,16') "Sprite must be native16: $relative"}
}

# Single crop sprites use native16; GUI slots and declared animation atlases are separate.
foreach($folder in @('crop','wild_crop','dead_crop')){
    $directory=Join-Path $resources "assets/tfcfarmingplus/textures/block/$folder"
    if(Test-Path -LiteralPath $directory){foreach($sprite in Get-ChildItem -LiteralPath $directory -File -Recurse -Filter '*.png'){
        if(Test-Path -LiteralPath ($sprite.FullName+'.mcmeta')){continue}
        $bytes=[IO.File]::ReadAllBytes($sprite.FullName)
        Check ($bytes.Length -ge 24 -and ($bytes[16..23] -join ',') -eq '0,0,0,16,0,0,0,16') "Single crop sprite must be 16x16; preview does not belong in source: $($sprite.FullName)"
    }}
}
function State-Case([string]$Form,$Values,[string]$Expected){
    $j=Read-Json "assets/tfcfarmingplus/blockstates/$Form/rhubarb.json"
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
    Check ($matches.Count -eq 1) "Rhubarb ambiguous/missing state: $Form $($Values|ConvertTo-Json -Compress)"
    if($matches.Count -eq 1){Check ($matches[0].model -ceq $Expected) "Rhubarb wrong state model: $Expected"}
    $cases.Add([pscustomobject]@{Form=$Form;Properties=$Values;Model=$Expected})
}
foreach($age in 0..5){
    State-Case 'crop' @{age=[string]$age} "tfcfarmingplus:block/crop/rhubarb_age_$age"
}
foreach($mature in @('false','true')){
    $suffix=if($mature -eq 'false'){'_young'}else{''}
    State-Case 'dead_crop' @{mature=$mature} "tfcfarmingplus:block/dead_crop/rhubarb$suffix"
}
foreach($mature in @('false','true')){
    $suffix=if($mature -eq 'false'){'_young'}else{''}
    State-Case 'wild_crop' @{mature=$mature} "tfcfarmingplus:block/wild_crop/rhubarb$suffix"
}
# Check independently meaningful geometry constraints in addition to reviewed hashes.
foreach($relative in $contract.ReviewedJsonSha256.PSObject.Properties.Name){
    if($relative -notlike 'assets/*/models/block/*'){continue}
    $j=Read-Json $relative
    foreach($element in $j.elements){
        foreach($end in @('from','to')){Check (@($element.$end).Count -eq 3) "Invalid rhubarb coordinates: $relative"}
        if($element.rotation){Check ($element.rotation.angle -in @(-45,-22.5,0,22.5,45)) "Invalid rhubarb rotation: $relative"}
        foreach($face in $element.faces.PSObject.Properties){
            $axis=switch($face.Name){'east'{0};'west'{0};'up'{1};'down'{1};'north'{2};'south'{2}}
            foreach($index in 0..2){if($index -ne $axis){Check ($element.to[$index] -gt $element.from[$index]) "Degenerate rhubarb face: $relative/$($face.Name)"}}
            Check (@($face.Value.uv).Count -eq 4) "Missing rhubarb UV: $relative"
        }
    }
}
$planter=Read-Json 'data/firmalife/firmalife/plantable/rhubarb.json'
Check ($planter.stages -eq 5 -and @($planter.textures).Count -eq 6) 'Rhubarb planter stage mapping changed'
Check ((@($planter.textures)-join '|') -ceq (@($contract.PlanterStageTextures)-join '|')) 'Rhubarb planter reverted to borrowed atlas'
$report=[pscustomobject]@{StateCases=$cases.ToArray();ReviewedJSONs=$contract.ReviewedJsonSha256.PSObject.Properties.Name.Count;ProtectedPNGs=$contract.ProtectedTextureSha256.PSObject.Properties.Name.Count;ProtectedGameplay=$contract.ProtectedGameplaySha256.PSObject.Properties.Name.Count;Findings=$errors.ToArray();VisualAccepted=$false;RuntimeVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'rhubarb-display-contracts.json'),($report|ConvertTo-Json -Depth 25),[Text.UTF8Encoding]::new($false))
}
Write-Output "[INFO] rhubarb display: states=$($cases.Count); JSONs=$($report.ReviewedJSONs); PNGs=$($report.ProtectedPNGs); gameplay=$($report.ProtectedGameplay); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "  [FAIL] $_"};exit 1}
Write-Output '[OK] Rhubarb display contracts passed; appearance and runtime await player review.'
exit 0
