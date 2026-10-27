param([string]$SourceInstance='', [string]$ReportDirectory='')
# Read-only current model/texture contracts, never visual or gameplay acceptance.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
try{Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop}catch{Add-Type -AssemblyName System.Drawing -ErrorAction Stop}
$liveInstance=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$liveInstance}
$a=Join-Path $instance 'moddev/tfcfarmingplus';$resources=Join-Path $a 'src/main/resources'
$ancestor=[IO.DirectoryInfo]::new($liveInstance);$minecraft=''
while($ancestor){$candidate=Join-Path $ancestor.FullName '.tooling/game/versions/1.21.1/1.21.1.jar';if(Test-Path -LiteralPath $candidate){$minecraft=$candidate;break};$ancestor=$ancestor.Parent}
if(-not $minecraft){throw 'Minecraft 1.21.1 client asset jar not found under workspace tooling.'}
$jars=@((Join-Path $liveInstance 'mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar'),$minecraft)
$archives=@();$modelCache=@{};$bitmapCache=@{};$origins=@{};$errors=New-Object 'System.Collections.Generic.List[string]';$rows=New-Object 'System.Collections.Generic.List[object]'
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Explicit-ID([string]$id){if($id -match ':'){return $id};return 'minecraft:'+$id}
function Asset-Bytes([string]$relative){
    $local=Join-Path $resources $relative
    if(Test-Path -LiteralPath $local){$origins[$relative]=$local;return ,([IO.File]::ReadAllBytes($local))}
    for($i=0;$i -lt $archives.Count;$i++){
        $entry=$archives[$i].GetEntry($relative)
        if($entry){$stream=$entry.Open();$memory=[IO.MemoryStream]::new();try{$stream.CopyTo($memory);$origins[$relative]=$jars[$i]+'!/'+$relative;return ,($memory.ToArray())}finally{$stream.Dispose();$memory.Dispose()}}
    }
    throw "Model/texture resource missing: $relative"
}
function Read-Model([string]$id,[string[]]$trail=@()){
    $id=Explicit-ID $id
    if($id -in $trail){throw "Model parent cycle: $($trail -join ' -> ') -> $id"}
    if($modelCache.ContainsKey($id)){return $modelCache[$id]}
    $ns,$path=$id.Split(':',2);$data=([Text.Encoding]::UTF8.GetString((Asset-Bytes "assets/$ns/models/$path.json"))|ConvertFrom-Json)
    $map=@{};$elements=@();$chain=@()
    if($data.parent){$parent=Read-Model $data.parent @($trail+$id);foreach($key in $parent.Textures.Keys){$map[$key]=$parent.Textures[$key]};$elements=@($parent.Elements);$chain=$parent.Chain}
    if($data.textures){foreach($property in $data.textures.PSObject.Properties){$map[$property.Name]=[string]$property.Value}}
    if($data.PSObject.Properties['elements']){$elements=@($data.elements)}
    $resolved=[pscustomobject]@{ID=$id;Textures=$map;Elements=$elements;Chain=@($id)+@($chain)};$modelCache[$id]=$resolved;return $resolved
}
function Resolve-Texture([string]$value,$map){
    $seen=@()
    while($value.StartsWith('#')){if($value -in $seen){throw 'Texture alias cycle'};$seen+=$value;$key=$value.Substring(1);if(-not $map.ContainsKey($key)){throw "Unresolved texture alias: $value"};$value=[string]$map[$key]}
    if(-not $value){throw 'Empty resolved texture identifier'}
    return Explicit-ID $value
}
function Get-Bitmap([string]$id){
    if(-not $bitmapCache.ContainsKey($id)){
        $ns,$path=$id.Split(':',2);$bytes=Asset-Bytes "assets/$ns/textures/$path.png";$stream=[IO.MemoryStream]::new([byte[]]$bytes);$image=$null
        try{$image=[Drawing.Bitmap]::new($stream);$bitmapCache[$id]=[Drawing.Bitmap]::new($image)}finally{if($image){$image.Dispose()};$stream.Dispose()}
    }
    return $bitmapCache[$id]
}
function Count-SampledPixels($image,$uv){
    $minX=0;$maxX=$image.Width;$minY=0;$maxY=$image.Height
    if($uv -and @($uv).Count -eq 4){
        $minX=[Math]::Max(0,[Math]::Floor([Math]::Min($uv[0],$uv[2])*$image.Width/16));$maxX=[Math]::Min($image.Width,[Math]::Ceiling([Math]::Max($uv[0],$uv[2])*$image.Width/16))
        $minY=[Math]::Max(0,[Math]::Floor([Math]::Min($uv[1],$uv[3])*$image.Height/16));$maxY=[Math]::Min($image.Height,[Math]::Ceiling([Math]::Max($uv[1],$uv[3])*$image.Height/16))
    }
    $count=0;for($y=$minY;$y -lt $maxY;$y++){for($x=$minX;$x -lt $maxX;$x++){if($image.GetPixel($x,$y).A -ge 8){$count++}}};return $count
}
try{
    foreach($jar in $jars){$archives+=,[IO.Compression.ZipFile]::OpenRead($jar)}
    foreach($species in @('broccoli','kale','lettuce','cauliflower','napa_cabbage','cabbage')){
        $forms=if($species -eq 'cabbage'){@('crop')}else{@('crop','dead','wild')}
        foreach($form in $forms){
            $relative=if($form -eq 'crop'){"assets/tfcfarmingplus/blockstates/crop/$species.json"}elseif($form -eq 'wild'){"assets/tfcfarmingplus/blockstates/wild_crop/$species.json"}elseif($species -eq 'kale'){'assets/tfcfarmingplus/blockstates/dead_rosette.json'}else{"assets/tfcfarmingplus/blockstates/dead_crop/$species.json"}
            if($species -eq 'cabbage'){$relative='assets/tfc/blockstates/crop/cabbage.json'}
            $state=[Text.Encoding]::UTF8.GetString((Asset-Bytes $relative))|ConvertFrom-Json
            $expected=if($form -eq 'crop'){if($species -eq 'kale'){@(foreach($flag in @('false','true')){foreach($age in 0..5){"age=$age,fruiting=$flag"}})}else{@(0..5|ForEach-Object{"age=$_"})}}else{@('mature=true','mature=false')}
            $actual=@($state.variants.PSObject.Properties.Name|Sort-Object)
            Check (($actual -join '|') -ceq (@($expected|Sort-Object) -join '|')) "State-space mismatch: $species/$form"
            foreach($key in $expected){
                $id=[string]$state.variants.$key.model;$model=Read-Model $id;$textures=@();$faces=0;$sampled=0;$boxHeads=0
                Check ($model.Elements.Count -gt 0) "No resolved model elements: $id"
                foreach($element in $model.Elements){
                    Check (@($element.from).Count -eq 3 -and @($element.to).Count -eq 3) "Malformed element coordinates: $id"
                    $flat=@(0..2|Where-Object{[double]$element.from[$_] -eq [double]$element.to[$_]})
                    Check ($flat.Count -lt 2) "Degenerate model element: $id"
                    if($flat.Count -eq 0){$boxHeads++}
                    if($element.rotation){Check ($element.rotation.axis -in @('x','y','z') -and $element.rotation.angle -in @(-45,-22.5,0,22.5,45)) "Invalid element rotation: $id"}
                    foreach($face in $element.faces.PSObject.Properties){
                        $faces++;if($flat.Count -eq 1){$allowed=@(@('west','east'),@('down','up'),@('north','south'))[$flat[0]];Check ($face.Name -in $allowed) "Zero-thickness face axis mismatch: $id/$($face.Name)"}
                        $texture=Resolve-Texture ([string]$face.Value.texture) $model.Textures;$textures+=$texture
                        if((Count-SampledPixels (Get-Bitmap $texture) @($face.Value.uv)) -gt 0){$sampled++}
                    }
                }
                $particle=Resolve-Texture ([string]$model.Textures['particle']) $model.Textures
                Check ((Count-SampledPixels (Get-Bitmap $particle) @()) -gt 0 -and $sampled -gt 0) "Particle/face texture samples are empty: $id"
                if($form -eq 'crop'){
                    $foliage=Resolve-Texture '#0' $model.Textures
                    Check ($particle -eq $foliage) "Crop particle uses generic rather than species foliage: $id ($particle != $foliage)"
                    $age=[int]([regex]::Match($key,'age=(\d+)').Groups[1].Value)
                    if($species -eq 'kale'){Check (($boxHeads -gt 0) -eq ($key -eq 'age=5,fruiting=true')) "Kale cube fruit must appear only in its mature fruiting model: $key"}
                    else{Check (($boxHeads -gt 0) -eq ($age -ge 2)) "Existing cube-head stages must remain age2..5: $id"}
                }
                # AR4-D/E: species-specific wild/dead forms, without changing crop or loot contracts.
                if($species -in @('broccoli','lettuce','cauliflower','napa_cabbage') -and $form -ne 'crop'){
                    $mature=$key -eq 'mature=true'
                    $expectedID='tfcfarmingplus:block/'+$(if($form -eq 'wild'){'wild_crop/'}else{'dead_crop/'})+$species+$(if($mature){''}else{'_young'})
                    Check ($id -eq $expectedID) "$species form uses a borrowed or wrong state model: $form/$key"
                    Check (@($model.Chain|Where-Object{$_ -notlike 'tfcfarmingplus:*'}).Count -eq 0) "$species form inherits native crop/grass geometry: $id"
                    foreach($texture in @($textures)+@($particle)){
                        Check ($texture -match ('^tfcfarmingplus:block/(crop|dead_crop)/'+[regex]::Escape($species)+'(?:_|$)')) "$species form uses non-species texture: $id/$texture"
                    }
                    $heads=@($model.Elements|Where-Object{([double]$_.to[0]-[double]$_.from[0]) -ge 3 -and ([double]$_.to[1]-[double]$_.from[1]) -ge 3 -and ([double]$_.to[2]-[double]$_.from[2]) -ge 3})
                    Check ($heads.Count -eq $(if($mature){1}else{0})) "$species head must exist only in mature forms: $id"
                    foreach($head in $heads){
                        Check (([double]$head.from[0]+[double]$head.to[0]) -eq 16 -and ([double]$head.from[2]+[double]$head.to[2]) -eq 16 -and [double]$head.from[1] -gt 0) "$species head is off-centre or rests on ground: $id"
                        Check ($head.faces.PSObject.Properties.Name.Count -eq 6) "$species head must have all six faces: $id"
                        foreach($side in $head.faces.PSObject.Properties){
                            $sprite=Get-Bitmap (Resolve-Texture ([string]$side.Value.texture) $model.Textures);$uv=@($side.Value.uv)
                            $left=[int][Math]::Floor([Math]::Min($uv[0],$uv[2])*$sprite.Width/16);$right=[int][Math]::Ceiling([Math]::Max($uv[0],$uv[2])*$sprite.Width/16)
                            $top=[int][Math]::Floor([Math]::Min($uv[1],$uv[3])*$sprite.Height/16);$bottom=[int][Math]::Ceiling([Math]::Max($uv[1],$uv[3])*$sprite.Height/16)
                            $opaque=$true
                            for($y=$top;$y -lt $bottom;$y++){for($x=$left;$x -lt $right;$x++){if($sprite.GetPixel($x,$y).A -ne 255){$opaque=$false}}}
                            Check $opaque "$species head face samples transparent pixels: $id/$($side.Name)"
                        }
                    }
                }
                # AR4-F wild kale uses its whole wild leaf atlas, not a crop fruit cube or native grass.
                if($species -eq 'kale' -and $form -eq 'wild'){
                    $expectedID='tfcfarmingplus:block/wild_crop/kale'+$(if($key -eq 'mature=true'){''}else{'_young'})
                    Check ($id -eq $expectedID) "Kale wild model points to a borrowed or wrong form: $key"
                    Check (@($model.Chain|Where-Object{$_ -notlike 'tfcfarmingplus:*'}).Count -eq 0) "Kale wild model inherits native grass geometry: $id"
                    Check ($boxHeads -eq 0 -and $model.Elements.Count -ge 4) "Kale wild form must be a leafy clump without a fruit cube: $id"
                    foreach($texture in @($textures|Sort-Object -Unique)+@($particle)){
                        Check ($texture -eq 'tfcfarmingplus:block/wild_crop/kale') "Kale wild form uses a non-wild-leaf texture: $id/$texture"
                    }
                    foreach($element in $model.Elements){foreach($face in $element.faces.PSObject.Properties){
                        Check ((@($face.Value.uv) -join ',') -eq '0,0,16,16') "Kale wild leaf must retain the full atlas outline: $id"
                    }}
                }
                $rows.Add([pscustomobject][ordered]@{Species=$species;Form=$form;State=$key;Model=$id;ParentChain=$model.Chain;FaceTextures=@($textures|Sort-Object -Unique);ParticleTexture=$particle;FaceCount=$faces;NonemptySampledFaces=$sampled;SolidElements=$boxHeads;NativeBelowGroundGeometryAllowed=($form -ne 'crop');VisualAccepted=$false;RuntimeVerified=$false})
            }
        }
    }
    Check ($rows.Count -eq 62 -and @($rows|Where-Object{$_.Form -eq 'crop'}).Count -eq 42) 'Expected 42 crop plus 20 dead/wild state cases.'
}finally{foreach($image in $bitmapCache.Values){$image.Dispose()};foreach($zip in $archives){$zip.Dispose()}}
$report=[ordered]@{Schema=1;Scope='AR4-B..J: five custom vegetables plus native cabbage crop override, 62 states';Findings=$errors.ToArray();StateCases=$rows.ToArray();AssetOrigins=$origins;VisualAccepted=$false;RuntimeVerified=$false;ExternalResourcePacksVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'leaf-vegetable-model-contracts.json'),($report|ConvertTo-Json -Depth 40),[Text.UTF8Encoding]::new($false))
    $csv=$rows|Select-Object @{n='作物';e={$_.Species}},@{n='形态';e={$_.Form}},@{n='状态';e={$_.State}},Model,@{n='表面贴图';e={$_.FaceTextures -join ';'}},@{n='破坏粒子';e={$_.ParticleTexture}},VisualAccepted,RuntimeVerified|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'leaf-vegetable-model-contracts.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output "[INFO] leaf-vegetable state cases=$($rows.Count); resolved models=$($modelCache.Count); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] model/particle source contracts checked; appearance and gameplay acceptance remain pending'
exit 0
