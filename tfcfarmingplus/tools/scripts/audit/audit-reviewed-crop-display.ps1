param([Parameter(Mandatory=$true)][ValidateSet('chili','fenugreek','spinach')][string]$Species, [string]$SourceInstance='', [string]$ReportDirectory='')
# Check current model routes and protected art, not visual or gameplay acceptance.
$ErrorActionPreference='Stop'
try { Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop } catch { Add-Type -AssemblyName System.Drawing }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$live=Split-Path (Split-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$live}
$resources=Join-Path $instance 'mod_rebuild/tfcfarmingplus/src/main/resources'
$other=Join-Path $instance 'mod_rebuild/tfcagricultureplus/src/main/resources'
$contract=Get-Content -LiteralPath (Join-Path $env:TFC_TOOLS_ROOT "contracts/${Species}-display-contract.json") -Raw -Encoding UTF8|ConvertFrom-Json
$errors=New-Object 'System.Collections.Generic.List[string]'
$rows=New-Object 'System.Collections.Generic.List[object]'
$textures=@{}
function Check([bool]$ok,[string]$message){if(-not $ok){$errors.Add($message)}}
function Read-Json([string]$key){
    $path=Join-Path $resources $key
    Check (-not(Test-Path -LiteralPath (Join-Path $other $key))) "B shadows ${Species} display resource: $key"
    if(-not(Test-Path -LiteralPath $path)){$errors.Add("Missing ${Species} resource: $key");return $null}
    try{return Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}catch{$errors.Add("Invalid ${Species} JSON: $key");return $null}
}
function Canonical([string]$id){if($id -notmatch ':'){return 'minecraft:'+$id};return $id}
function Get-Model([string]$id,[string[]]$trail=@()){
    $id=Canonical $id
    if($id -in $trail){$errors.Add("${Species} parent cycle: $id");return @{} }
    $ns,$path=$id.Split(':',2)
    if($id -eq 'minecraft:block/crop'){return @{crop='';particle='#crop'}}
    $j=Read-Json "assets/$ns/models/$path.json"
    if(-not $j){return @{}}
    if($j.elements){
        $trim=$contract.ClippedModels.$id
        Check ($trim -eq 5) "Unreviewed crop geometry override: $id"
        if($trim -eq 5){
            $workspace=Split-Path (Split-Path $live -Parent) -Parent
            $clientPath=Join-Path $workspace '.tooling/game/versions/1.21.1/1.21.1.jar'
            $client=[IO.Compression.ZipFile]::OpenRead($clientPath)
            try{
                $reader=[IO.StreamReader]::new($client.GetEntry('assets/minecraft/models/block/crop.json').Open(),[Text.Encoding]::UTF8)
                try{$native=$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
            }finally{$client.Dispose()}
            foreach($element in $native.elements){
                $element.to[1]=[double]$element.to[1]-$trim
                foreach($face in $element.faces.PSObject.Properties){$face.Value.uv[1]=[double]$face.Value.uv[1]+$trim}
            }
            Check (Same-Value @($j.elements) @($native.elements)) "Crop clip differs from native geometry with matching UV scale: $id"
        }
    }elseif($contract.ClippedModels.$id){
        Check $false "Reviewed crop clip missing: $id"
    }
    $map=@{}
    if($j.parent){$map=Get-Model ([string]$j.parent) (@($trail)+@($id))}
    foreach($prop in $j.textures.PSObject.Properties){$map[$prop.Name]=[string]$prop.Value}
    return $map
}
function Resolve-Texture([string]$value,$map){
    $seen=@()
    while($value.StartsWith('#')){
        if($value -in $seen){$errors.Add("${Species} texture alias cycle");return ''}
        $seen+=$value;$value=[string]$map[$value.Substring(1)]
    }
    return $value
}
function Model-Case([string]$form,[string]$state,[string]$id,[string]$texture){
    $map=Get-Model $id
    $visible=Resolve-Texture '#crop' $map
    $particle=Resolve-Texture '#particle' $map
    Check ($visible -eq $texture) "${Species} face uses wrong atlas: $form/$state ($visible)"
    Check ($particle -eq $texture) "${Species} particle uses wrong atlas: $form/$state ($particle)"
    Check ($textures.ContainsKey($texture)) "${Species} face atlas was not checked as protected art: $texture"
    $rows.Add([pscustomobject]@{Form=$form;State=$state;Model=$id;Texture=$visible;Particle=$particle;VisualAccepted=$false;RuntimeVerified=$false})
}
function Same-Value($left,$right){
    if($null -eq $left -or $null -eq $right){return ($null -eq $left -and $null -eq $right)}
    if($left -is [pscustomobject] -and $right -is [pscustomobject]){
        $keys=@($left.PSObject.Properties.Name|Sort-Object);$otherKeys=@($right.PSObject.Properties.Name|Sort-Object)
        if(($keys -join '|') -cne ($otherKeys -join '|')){return $false}
        foreach($key in $keys){if(-not(Same-Value $left.$key $right.$key)){return $false}};return $true
    }
    if($left -is [array] -or $right -is [array]){
        if(@($left).Count -ne @($right).Count){return $false}
        for($i=0;$i -lt @($left).Count;$i++){if(-not(Same-Value $left[$i] $right[$i])){return $false}};return $true
    }
    return ($left -ceq $right)
}
foreach($entry in $contract.ProtectedTextureSha256.PSObject.Properties){
    $path=Join-Path $resources $entry.Name
    Check (-not(Test-Path -LiteralPath (Join-Path $other $entry.Name))) "B shadows protected ${Species} PNG: $($entry.Name)"
    if(-not(Test-Path -LiteralPath $path)){$errors.Add("Missing protected ${Species} PNG: $($entry.Name)");continue}
    Check ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $entry.Value) "Protected ${Species} PNG changed: $($entry.Name)"
    $sprite=[Drawing.Bitmap]::new($path)
    try{
        Check ($sprite.Width -eq 16 -and $sprite.Height -eq 16) "Unexpected ${Species} sprite dimensions: $($entry.Name)"
        $visible=0
        for($y=0;$y -lt $sprite.Height;$y++){for($x=0;$x -lt $sprite.Width;$x++){if($sprite.GetPixel($x,$y).A -gt 0){$visible++}}}
        Check ($visible -gt 0) "Empty ${Species} sprite: $($entry.Name)"
    }finally{$sprite.Dispose()}
    $textures['tfcfarmingplus:'+($entry.Name -replace '^assets/tfcfarmingplus/textures/','' -replace '\.png$','')]=$true
}
$state=Read-Json "assets/tfcfarmingplus/blockstates/crop/${Species}.json"
$keys=@($state.variants.PSObject.Properties.Name|Sort-Object)
Check (($keys -join '|') -eq 'age=0|age=1|age=2|age=3|age=4|age=5') "${Species} crop age variants changed"
foreach($age in 0..5){
    $id="tfcfarmingplus:block/crop/${Species}_age_$age"
    Check ($state.variants."age=$age".model -eq $id) "${Species} crop state route changed: $age"
    $wrapper=Read-Json "assets/tfcfarmingplus/models/block/crop/${Species}_age_$age.json"
    Check ((Canonical ([string]$wrapper.parent)) -eq 'minecraft:block/crop') "${Species} crop parent changed: $age"
    Model-Case 'crop' "age=$age" $id "tfcfarmingplus:block/crop/${Species}_age_$age"
}
foreach($form in @('wild_crop','dead_crop')){
    $state=Read-Json "assets/tfcfarmingplus/blockstates/$form/${Species}.json"
    Check ((@($state.variants.PSObject.Properties.Name|Sort-Object) -join '|') -eq 'mature=false|mature=true') "${Species} $form maturity variants changed"
    foreach($mature in @($true,$false)){
        $key=if($mature){'mature=true'}else{'mature=false'}
        $suffix=if($mature){''}else{'_young'}
        $id="tfcfarmingplus:block/$form/${Species}$suffix"
        Check ($state.variants.$key.model -eq $id) "${Species} $form state uses borrowed/wrong model: $key"
        $wrapper=Read-Json "assets/tfcfarmingplus/models/block/$form/${Species}$suffix.json"
        $expectedParent=if($form -eq 'wild_crop' -and -not $mature){"tfcfarmingplus:block/crop/${Species}_age_1"}elseif($form -eq 'wild_crop' -and $contract.WildMatureUsesCropAge5){"tfcfarmingplus:block/crop/${Species}_age_5"}else{'minecraft:block/crop'}
        Check ((Canonical ([string]$wrapper.parent)) -eq $expectedParent) "${Species} $form parent changed: $key"
        $atlas=if($form -eq 'wild_crop' -and -not $mature){"tfcfarmingplus:block/crop/${Species}_age_1"}elseif($form -eq 'wild_crop' -and $contract.WildMatureUsesCropAge5){"tfcfarmingplus:block/crop/${Species}_age_5"}else{"tfcfarmingplus:block/$form/${Species}$suffix"}
        Model-Case $form $key $id $atlas
    }
}
foreach($kind in @('seeds','food')){
    $item=Read-Json "assets/tfcfarmingplus/models/item/$kind/${Species}.json"
    $icon=if($contract.ItemTextures){[string]$contract.ItemTextures.$kind}else{"tfcfarmingplus:item/$kind/${Species}"}
    Check ((Canonical ([string]$item.parent)) -eq 'minecraft:item/generated' -and $item.textures.layer0 -eq $icon) "${Species} $kind icon uses wrong model/atlas"
}
$wildItem=Read-Json "assets/tfcfarmingplus/models/item/wild_crop/${Species}.json"
Check ($wildItem.parent -eq "tfcfarmingplus:block/wild_crop/${Species}") "${Species} wild inventory model no longer follows its block"
$planter=Read-Json "data/firmalife/firmalife/plantable/${Species}.json"
$expected=if($contract.PlanterTextures){@($contract.PlanterTextures)}else{@(0..5|ForEach-Object{"tfcfarmingplus:block/crop/${Species}_age_$_"})}
Check ((@($planter.textures) -join '|') -ceq ($expected -join '|')) "${Species} planter stage textures do not match the six crop stages"
if($planter){$copy=$planter|Select-Object * -ExcludeProperty textures;Check (Same-Value $copy $contract.PlanterFieldsExceptTextures) "${Species} planter gameplay fields changed"}

foreach($texture in @($planter.textures)){
    Check ($textures.ContainsKey([string]$texture)) "${Species} planter atlas is not protected: $texture"
}
if($contract.PlanterMature){
    $mature=$contract.PlanterMature
    Check ($planter.textures[$mature.StageIndex] -ceq $mature.Texture) "${Species} mature planter atlas changed"
    Check ($planter.textures[$mature.StageIndex-1] -cne $mature.Texture) "${Species} mature planter repeats its prior stage"
    $relative='assets/'+(([string]$mature.Texture) -replace ':','/textures/')+'.png'
    $path=Join-Path $resources $relative
    if(Test-Path -LiteralPath $path){
        $bitmap=[Drawing.Bitmap]::new($path)
        try{
            $grounded=$false
            for($y=0;$y -lt $bitmap.Height;$y++){for($x=0;$x -lt $bitmap.Width;$x++){
                if($bitmap.GetPixel($x,$y).A -ge 26){
                    Check ($x -ge $mature.VisibleColumns[0] -and $x -le $mature.VisibleColumns[1]) "${Species} mature planter loses visible pixels to native UV crop"
                    if($y -eq 15){$grounded=$true}
                }
            }}
            Check $grounded "${Species} mature planter sprite is not grounded"
        }finally{$bitmap.Dispose()}
    }
}

$report=[pscustomobject]@{Scope="Reviewed ten ${Species} block-state cases, two icons and one planter";StateCases=$rows.ToArray();ProtectedPNGs=$contract.ProtectedTextureSha256.PSObject.Properties.Name.Count;Findings=$errors.ToArray();VisualAccepted=$false;RuntimeVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory "${Species}-display-contracts.json"),($report|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
    $csv=$rows|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory "${Species}-display-contracts.csv"),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output "[INFO] ${Species} display: states=$($rows.Count); protected PNGs=$($report.ProtectedPNGs); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "  [FAIL] $_"};exit 1}
Write-Output "[OK] ${Species} display routes checked; gameplay and final appearance remain unverified"
exit 0
