param([string]$SourceInstance='', [string]$ReportDirectory='')
# Source geometry/alpha contracts. They do not constitute gameplay or visual acceptance.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
try{Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop}catch{Add-Type -AssemblyName System.Drawing -ErrorAction Stop}
$live=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$instance=if($SourceInstance){$SourceInstance}else{$live}
$instance=(Resolve-Path -LiteralPath $instance).Path
$res=Join-Path $instance 'moddev/tfcfarmingplus/src/main/resources'
$other=Join-Path $instance 'moddev/tfcagricultureplus/src/main/resources'
$nativeJar=Join-Path $live 'mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar'
$zip=[IO.Compression.ZipFile]::OpenRead($nativeJar)
$errors=New-Object 'System.Collections.Generic.List[string]'
$rows=New-Object 'System.Collections.Generic.List[object]'
$bitmaps=@{};$origins=@{};$expectedConsumers=@();$headedWrappers=@()
function Check([bool]$ok,[string]$message){if(-not $ok){$errors.Add($message)}}
function Read-Resource([string]$relative){
    $path=Join-Path $res $relative
    if(Test-Path -LiteralPath $path){$origins[$relative]=$path;return Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}
    $entry=$zip.GetEntry($relative)
    if(-not $entry){throw "Missing source resource: $relative"}
    $reader=[IO.StreamReader]::new($entry.Open(),[Text.Encoding]::UTF8)
    try{$origins[$relative]=$nativeJar+'!/'+$relative;return $reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
}
function Resolve-Atlas([string]$id,$map){
    $seen=@()
    while($id.StartsWith('#')){if($id -in $seen){throw 'Texture alias cycle'};$seen+=$id;$id=[string]$map[$id.Substring(1)]}
    if(-not $id){throw 'Missing atlas binding'}
    return $id
}
function Bitmap([string]$id){
    if(-not $bitmaps.ContainsKey($id)){$ns,$path=$id.Split(':',2);$bitmaps[$id]=[Drawing.Bitmap]::new((Join-Path $res "assets/$ns/textures/$path.png"))}
    return $bitmaps[$id]
}
function Bounds($element){
    $lo=@([double]::PositiveInfinity,[double]::PositiveInfinity,[double]::PositiveInfinity)
    $hi=@([double]::NegativeInfinity,[double]::NegativeInfinity,[double]::NegativeInfinity)
    for($bits=0;$bits -lt 8;$bits++){
        $x=[double]$element.from[0];$y=[double]$element.from[1];$z=[double]$element.from[2]
        if($bits -band 1){$x=[double]$element.to[0]};if($bits -band 2){$y=[double]$element.to[1]};if($bits -band 4){$z=[double]$element.to[2]}
        if($element.rotation){
            $rotation=$element.rotation;$ox=[double]$rotation.origin[0];$oy=[double]$rotation.origin[1];$oz=[double]$rotation.origin[2]
            $x-=$ox;$y-=$oy;$z-=$oz;$radians=[double]$rotation.angle*[Math]::PI/180;$c=[Math]::Cos($radians);$s=[Math]::Sin($radians)
            if($rotation.axis -eq 'x'){$ny=$y*$c-$z*$s;$nz=$y*$s+$z*$c;$y=$ny;$z=$nz}
            elseif($rotation.axis -eq 'z'){$nx=$x*$c-$y*$s;$ny=$x*$s+$y*$c;$x=$nx;$y=$ny}
            else{throw 'Leafball support audit expects cardinal x/z rotations.'}
            $x+=$ox;$y+=$oy;$z+=$oz
        }
        $point=@($x,$y,$z)
        for($i=0;$i -lt 3;$i++){$lo[$i]=[Math]::Min($lo[$i],$point[$i]);$hi[$i]=[Math]::Max($hi[$i],$point[$i])}
    }
    return [pscustomobject]@{Min=$lo;Max=$hi}
}
try{
    foreach($species in @('broccoli','lettuce','cauliflower','napa_cabbage','cabbage')){
        $ns=if($species -eq 'cabbage'){'tfc'}else{'tfcfarmingplus'}
        Check (-not(Test-Path -LiteralPath (Join-Path $other "assets/$ns/blockstates/crop/$species.json"))) "B shadows leafball blockstate: $species"
        $state=Read-Resource "assets/$ns/blockstates/crop/$species.json"
        Check ((@($state.variants.PSObject.Properties.Name|Sort-Object) -join '|') -eq 'age=0|age=1|age=2|age=3|age=4|age=5') "Leafball state space changed: $species"
        foreach($age in 0..5){
            $id="${ns}:block/crop/${species}_age_$age"
            Check ($state.variants."age=$age".model -eq $id) "Leafball state points to unexpected model: $species/$age"
            $relative="assets/$ns/models/block/crop/${species}_age_$age.json"
            $wrapper=Read-Resource $relative;$expectedConsumers+="moddev/tfcfarmingplus/src/main/resources/$relative"
            Check (-not(Test-Path -LiteralPath (Join-Path $other $relative))) "B shadows shared leafball wrapper: $relative"
            Check ($wrapper.parent -eq "tfcfarmingplus:block/crop/leafball_age_$age") "Leafball wrapper no longer uses reviewed parent: $id"
            $model=Read-Resource "assets/tfcfarmingplus/models/block/crop/leafball_age_$age.json"
            $map=@{};foreach($prop in $model.textures.PSObject.Properties){$map[$prop.Name]=$prop.Value};foreach($prop in $wrapper.textures.PSObject.Properties){$map[$prop.Name]=$prop.Value}
            $heads=@($model.elements|Where-Object{$_.from[0] -ne $_.to[0] -and $_.from[1] -ne $_.to[1] -and $_.from[2] -ne $_.to[2]})
            Check ($heads.Count -eq $(if($age -ge 2){1}else{0})) "Unexpected head/stem volume in shared model: $id"
            $contacts=@{};$leaves=@();$penetrating=0
            foreach($element in $model.elements){
                $bb=Bounds $element
                Check ((@($bb.Min|Where-Object{$_ -lt -0.000001}).Count -eq 0) -and (@($bb.Max|Where-Object{$_ -gt 16.000001}).Count -eq 0)) "Rotated leafball model exceeds block bounds: $id"
                if($element -notin $heads){$leaves+=,$element}
            }
            if($heads.Count -eq 1){
                $headedWrappers+=$id
                $head=$heads[0]
                Check (([double]$head.from[0]+[double]$head.to[0]) -eq 16 -and ([double]$head.from[2]+[double]$head.to[2]) -eq 16 -and $head.from[1] -eq 5) "Head must retain centred position and reviewed y5 base: $id"
                foreach($side in $head.faces.PSObject.Properties){
                    $image=Bitmap (Resolve-Atlas $side.Value.texture $map);$uv=@($side.Value.uv);$opaque=$true
                    for($v=[int][Math]::Floor([Math]::Min($uv[1],$uv[3])*$image.Height/16);$v -lt [Math]::Ceiling([Math]::Max($uv[1],$uv[3])*$image.Height/16);$v++){
                        for($u=[int][Math]::Floor([Math]::Min($uv[0],$uv[2])*$image.Width/16);$u -lt [Math]::Ceiling([Math]::Max($uv[0],$uv[2])*$image.Width/16);$u++){if($image.GetPixel($u,$v).A -ne 255){$opaque=$false}}
                    }
                    Check $opaque "Head face samples transparency: $id/$($side.Name)"
                }
                foreach($leaf in $leaves){
                    $bb=Bounds $leaf;$separate=$false
                    for($i=0;$i -lt 3;$i++){if($bb.Max[$i] -le [double]$head.from[$i]+0.000001 -or $bb.Min[$i] -ge [double]$head.to[$i]-0.000001){$separate=$true}}
                    if(-not $separate){$penetrating++;Check $false "Leaf is not provably outside the head interior: $id"}
                    if($leaf.rotation){continue}
                    $flat=if($leaf.from[0] -eq $leaf.to[0]){0}elseif($leaf.from[2] -eq $leaf.to[2]){2}else{-1}
                    if($flat -lt 0){continue}
                    $coordinate=[double]$leaf.from[$flat];$direction=''
                    if([Math]::Abs($coordinate-[double]$head.from[$flat]) -lt 0.05){$direction=if($flat -eq 0){'west'}else{'north'}}
                    elseif([Math]::Abs($coordinate-[double]$head.to[$flat]) -lt 0.05){$direction=if($flat -eq 0){'east'}else{'south'}}
                    if(-not $direction){continue}
                    Check (-not $contacts.ContainsKey($direction)) "Duplicate lower support plane: $id/$direction"
                    $widthAxis=if($flat -eq 0){2}else{0};$width=[double]$leaf.to[$widthAxis]-[double]$leaf.from[$widthAxis];$height=[double]$leaf.to[1]-[double]$leaf.from[1]
                    Check ($width -eq 8 -and [double]$leaf.from[1] -le 0.05) "Lower foliage must retain full width and ground connection: $id/$direction"
                    $reaches=[double]$leaf.to[1] -ge [double]$head.from[1]+0.01
                    Check $reaches "Lower support stops below the head base: $id/$direction"
                    $firstFace=@($leaf.faces.PSObject.Properties)[0];$uv=@($firstFace.Value.uv)
                    Check ([Math]::Abs([Math]::Abs($uv[2]-$uv[0])-$width) -lt 0.000001 -and [Math]::Abs([Math]::Abs($uv[3]-$uv[1])-$height) -lt 0.000001) "Support atlas/model scale must stay 1:1: $id/$direction"
                    $alpha=0
                    if($reaches){
                        $image=Bitmap (Resolve-Atlas $firstFace.Value.texture $map)
                        $v=$uv[3]-([double]$head.from[1]-[double]$leaf.from[1])*($uv[3]-$uv[1])/$height
                        $start=$uv[0]+([double]$head.from[$widthAxis]-[double]$leaf.from[$widthAxis])*($uv[2]-$uv[0])/$width
                        $end=$uv[0]+([double]$head.to[$widthAxis]-[double]$leaf.from[$widthAxis])*($uv[2]-$uv[0])/$width
                        $pixelY=[int][Math]::Floor($v*$image.Height/16)
                        for($u=[int][Math]::Floor([Math]::Min($start,$end)*$image.Width/16);$u -lt [Math]::Ceiling([Math]::Max($start,$end)*$image.Width/16);$u++){if($image.GetPixel($u,$pixelY).A -ge 8){$alpha++}}
                    }
                    Check ($alpha -gt 0) "Support contact band has no visible atlas pixels: $id/$direction"
                    $contacts[$direction]=[pscustomobject]@{Top=$leaf.to[1];HeadBase=$head.from[1];VisibleContactSamples=$alpha}
                }
                Check ((@($contacts.Keys|Sort-Object) -join '|') -eq 'east|north|south|west') "All four lower support sides are required: $id"
            }
            $rows.Add([pscustomobject][ordered]@{Species=$species;Namespace=$ns;Age=$age;Model=$id;HasHead=($heads.Count -eq 1);SupportSides=@($contacts.Keys|Sort-Object);ContactBands=$contacts;PenetratingLeaves=$penetrating;VisualAccepted=$false;RuntimeVerified=$false})
        }
    }
    $actualConsumers=@();$modelParents=New-Object 'System.Collections.Generic.List[object]'
    foreach($side in @('tfcfarmingplus','tfcagricultureplus')){
        foreach($file in Get-ChildItem -LiteralPath (Join-Path $instance "moddev/$side/src/main/resources/assets") -Recurse -File -Filter '*.json'){
            $relative=$file.FullName.Substring($instance.Length+1).Replace('\','/')
            if($relative -notmatch '/models/'){continue}
            $definition=Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8|ConvertFrom-Json
            if($definition.parent -match '^tfcfarmingplus:block/crop/leafball_age_[0-5]$'){$actualConsumers+=$relative}
            if($definition.parent -and $relative -match '^moddev/[^/]+/src/main/resources/assets/([^/]+)/models/(.+)\.json$'){
                $modelID=$Matches[1]+':'+$Matches[2]
                $modelParents.Add([pscustomobject]@{ID=$modelID;Parent=[string]$definition.parent;Path=$relative})
            }
        }
    }
    Check ((@($actualConsumers|Sort-Object) -join '|') -eq (@($expectedConsumers|Sort-Object) -join '|')) 'Shared leafball consumers changed; reassess every namespace before editing geometry.'
    $affected=New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($age in 2..5){[void]$affected.Add("tfcfarmingplus:block/crop/leafball_age_$age")}
    do{
        $expanded=$false
        foreach($entry in $modelParents){if($affected.Contains($entry.Parent) -and $affected.Add($entry.ID)){$expanded=$true}}
    }while($expanded)
    $indirect=@($modelParents|Where-Object{$affected.Contains($_.ID) -and $_.ID -notin $headedWrappers})
    Check ($indirect.Count -eq 0) 'Additional indirect headed-model consumers found; expand visual review before publishing shared geometry.'
    Check ($rows.Count -eq 30 -and @($rows|Where-Object{$_.HasHead}).Count -eq 20) 'Expected five species, thirty crop cases, twenty headed cases.'
}finally{foreach($image in $bitmaps.Values){$image.Dispose()};$zip.Dispose()}
$report=[ordered]@{Schema=1;Scope='AR4-J five active species including native cabbage override, 30 crop cases';Findings=$errors.ToArray();StateCases=$rows.ToArray();Consumers=$actualConsumers;AdditionalHeadedAliases=$indirect;Origins=$origins;VisualAccepted=$false;RuntimeVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'leafball-support-contracts.json'),($report|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
    $csv=$rows|Select-Object @{n='作物';e={$_.Species}},Namespace,Age,Model,@{n='承托方向';e={$_.SupportSides -join ';'}},PenetratingLeaves,VisualAccepted,RuntimeVerified|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'leafball-support-contracts.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output "[INFO] leafball support: species=5; crop cases=$($rows.Count); headed cases=20; findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] four-sided visible support and head separation checked; appearance/gameplay remain pending'
exit 0
