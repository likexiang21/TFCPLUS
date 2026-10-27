param([string]$SourceInstance='', [string]$ReportDirectory='', [switch]$PassThru)
# Read-only source reference/geometry checks. Pixel counts never constitute visual acceptance.
$ErrorActionPreference='Stop'
try{Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop}catch{Add-Type -AssemblyName System.Drawing -ErrorAction Stop}
$liveInstance=Split-Path (Split-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$liveInstance}
$a=Join-Path $instance 'mod_rebuild/tfcfarmingplus';$assets=Join-Path $a 'src/main/resources/assets'
$errors=New-Object 'System.Collections.Generic.List[string]'
$rows=New-Object 'System.Collections.Generic.List[object]'
$bitmaps=@{}
$cases=@(
    [pscustomobject]@{Name='broccoli';Shape='leafball';LegacyHash='7074F74F39A8AD752DB14A876089E9867D92B2425C37A6D44A74660F900A877D';ExpectedLegacyPixels=0},
    [pscustomobject]@{Name='kale';Shape='rosette';LegacyHash='7074F74F39A8AD752DB14A876089E9867D92B2425C37A6D44A74660F900A877D';ExpectedLegacyPixels=0},
    [pscustomobject]@{Name='lettuce';Shape='leafball';LegacyHash='B0C3647C0BB254A0CAA93FC6EE92E35A5FD17FB4D74D588A16A0B28BBF888A25';ExpectedLegacyPixels=2}
)
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Read-Json([string]$path){Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}
function Normalize-Texture([string]$id){
    if(-not $id -or $id.StartsWith('#')){return $id}
    if($id -notmatch ':'){$id='minecraft:'+$id}
    return ($id -replace ':textures/',':' -replace '\.png$','')
}
$consumers=@{}
foreach($case in $cases){$consumers["tfcfarmingplus:block/crop/$($case.Name)_age_0"]=New-Object 'System.Collections.Generic.List[string]'}
function Find-Consumer($value,[string]$path,[string]$origin){
    if($null -eq $value){return}
    if($value -is [string]){
        # model and parent fields identify model files, not texture files with the same ID.
        if($path -match '(?:^|\.)(?:model|parent)$'){return}
        $id=Normalize-Texture $value
        if($consumers.ContainsKey($id)){$consumers[$id].Add("${origin}:$path")}
        return
    }
    if($value -is [System.Array]){for($i=0;$i -lt $value.Count;$i++){Find-Consumer $value[$i] "$path[$i]" $origin};return}
    if($value -is [pscustomobject]){foreach($property in $value.PSObject.Properties){Find-Consumer $property.Value "$path.$($property.Name)" $origin}}
}
function Get-Bitmap([string]$id){
    $id=Normalize-Texture $id
    if(-not $bitmaps.ContainsKey($id)){
        $parts=$id.Split(':',2);$path=Join-Path $assets "$($parts[0])/textures/$($parts[1]).png"
        if(-not(Test-Path -LiteralPath $path)){throw "Seedling texture missing: $id"}
        $bitmaps[$id]=[System.Drawing.Bitmap]::new($path)
    }
    return $bitmaps[$id]
}
function Count-Pixels($bitmap,[double[]]$uv){
    $x0=0;$x1=$bitmap.Width;$y0=0;$y1=$bitmap.Height
    if($uv -and $uv.Count -eq 4){
        $x0=[Math]::Max(0,[Math]::Floor([Math]::Min($uv[0],$uv[2])*$bitmap.Width/16))
        $x1=[Math]::Min($bitmap.Width,[Math]::Ceiling([Math]::Max($uv[0],$uv[2])*$bitmap.Width/16))
        $y0=[Math]::Max(0,[Math]::Floor([Math]::Min($uv[1],$uv[3])*$bitmap.Height/16))
        $y1=[Math]::Min($bitmap.Height,[Math]::Ceiling([Math]::Max($uv[1],$uv[3])*$bitmap.Height/16))
    }
    $count=0
    for($y=$y0;$y -lt $y1;$y++){for($x=$x0;$x -lt $x1;$x++){if($bitmap.GetPixel($x,$y).A -ge 8){$count++}}}
    return $count
}
function Read-Model([string]$id,[string[]]$trail=@()){
    if($id -in $trail){throw "Model parent cycle: $($trail -join ' -> ') -> $id"}
    $parts=$id.Split(':',2)
    if($parts.Count -ne 2){throw "Explicit model namespace required in this audit: $id"}
    $path=Join-Path $assets "$($parts[0])/models/$($parts[1]).json"
    $data=Read-Json $path;$map=@{};$elements=@();$chain=@()
    if($data.parent){$parent=Read-Model $data.parent @($trail+$id);foreach($key in $parent.Textures.Keys){$map[$key]=$parent.Textures[$key]};$elements=$parent.Elements;$chain=$parent.Chain}
    if($data.textures){foreach($property in $data.textures.PSObject.Properties){$map[$property.Name]=[string]$property.Value}}
    if($data.PSObject.Properties['elements']){$elements=@($data.elements)}
    return [pscustomobject]@{ID=$id;Textures=$map;Elements=$elements;Chain=@($id)+@($chain)}
}
function Resolve-Texture([string]$value,$map){
    $seen=@()
    while($value.StartsWith('#')){
        if($value -in $seen){throw 'Texture alias cycle'}
        $seen+=$value;$key=$value.Substring(1)
        if(-not $map.ContainsKey($key)){throw "Texture alias missing: $value"}
        $value=[string]$map[$key]
    }
    return Normalize-Texture $value
}
try{
    foreach($side in @('tfcfarmingplus','tfcagricultureplus')){
        $module=Join-Path $instance "mod_rebuild/$side"
        foreach($file in Get-ChildItem -LiteralPath (Join-Path $module 'src/main/resources') -Recurse -File -Filter '*.json'){
            $raw=Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
            if($raw -match 'broccoli_age_0|kale_age_0|lettuce_age_0'){
                $origin=$file.FullName.Substring($instance.Length+1).Replace('\','/')
                Find-Consumer ($raw|ConvertFrom-Json) '' $origin
            }
        }
        foreach($file in Get-ChildItem -LiteralPath (Join-Path $module 'src/main/java') -Recurse -File -Filter '*.java'){
            $raw=Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
            foreach($case in $cases){if($raw.Contains($case.Name+'_age_0')){$consumers["tfcfarmingplus:block/crop/$($case.Name)_age_0"].Add('java:'+ $file.FullName)}}
        }
    }
    foreach($case in $cases){
        $name=$case.Name;$legacy="tfcfarmingplus:block/crop/${name}_age_0";$active="tfcfarmingplus:block/crop/${name}_$($case.Shape)_0"
        $legacyRelative="tfcfarmingplus/textures/block/crop/${name}_age_0.png"
        $legacyPixels=Count-Pixels (Get-Bitmap $legacy) @()
        $hash=(Get-FileHash -LiteralPath (Join-Path $assets $legacyRelative) -Algorithm SHA256).Hash
        Check ($hash -ceq $case.LegacyHash -and $legacyPixels -eq $case.ExpectedLegacyPixels) "Reviewed historical texture changed; review its classification again: $legacy"
        Check ($consumers[$legacy].Count -eq 0) "Historical texture has a declared consumer; cannot exempt it: $legacy"
        $state=Read-Json (Join-Path $assets "tfcfarmingplus/blockstates/crop/$name.json")
        $keys=if($name -eq 'kale'){@('age=0,fruiting=false','age=0,fruiting=true')}else{@('age=0')}
        $modelRows=New-Object 'System.Collections.Generic.List[object]'
        foreach($key in $keys){
            $id=[string]$state.variants.$key.model
            Check ($id -eq "tfcfarmingplus:block/crop/${name}_age_0$(if($key.EndsWith('true')){'_fruiting'})") "Unexpected age-zero state model: $name/$key"
            $model=Read-Model $id
            Check ($model.Elements.Count -gt 0 -and "tfcfarmingplus:block/crop/$($case.Shape)_age_0" -in $model.Chain) "Seedling parent geometry missing: $name/$key"
            $textures=@();$visibleFaces=0
            foreach($element in $model.Elements){
                $zeroAxes=@(0..2|Where-Object{[double]$element.from[$_] -eq [double]$element.to[$_]})
                Check ($zeroAxes.Count -lt 2) "Degenerate seedling element: $id"
                if($element.rotation){Check ($element.rotation.angle -in @(-45,-22.5,0,22.5,45)) "Unsupported model rotation: $id"}
                foreach($face in $element.faces.PSObject.Properties){
                    if($zeroAxes.Count -eq 1){$allowed=@(@('west','east'),@('down','up'),@('north','south'))[$zeroAxes[0]];Check ($face.Name -in $allowed) "Seedling face is parallel to the zero-thickness axis: $id/$($face.Name)"}
                    $texture=Resolve-Texture ([string]$face.Value.texture) $model.Textures;$textures+=$texture
                    if((Count-Pixels (Get-Bitmap $texture) @($face.Value.uv)) -gt 0){$visibleFaces++}
                }
            }
            Check ($active -in $textures -and $legacy -notin $textures -and $visibleFaces -gt 0) "Seedling does not sample its reviewed active texture: $id"
            $modelRows.Add([pscustomobject]@{State=$key;Model=$id;ParentChain=$model.Chain;FaceTextures=@($textures|Sort-Object -Unique);SampledNonemptyFaces=$visibleFaces})
        }
        $activePixels=Count-Pixels (Get-Bitmap $active) @()
        Check ($activePixels -gt 0) "Active seedling texture is empty: $active"
        $planter=Read-Json (Join-Path $a "src/main/resources/data/firmalife/firmalife/plantable/$name.json")
        Check ($planter.crop.id -eq "tfcfarmingplus:food/$name" -and @($planter.textures).Count -eq 6 -and $planter.textures[0] -notmatch 'broccoli_age_0|kale_age_0|lettuce_age_0') "Planter must retain its separate native texture set: $name"
        $rows.Add([pscustomobject][ordered]@{Name=$name;LegacyTexture=$legacy;LegacyRelativePath=$legacyRelative;LegacySHA256=$hash;LegacyNonemptyPixels=$legacyPixels;DeclaredLegacyConsumers=$consumers[$legacy].ToArray();ActiveTexture=$active;ActiveNonemptyPixels=$activePixels;States=$modelRows.ToArray();PlanterTextures=@($planter.textures);Classification='Historical texture has no declared A/B source consumer; current seedling uses another texture';VisualAccepted=$false;RuntimeVerified=$false})
    }
}finally{foreach($bitmap in $bitmaps.Values){$bitmap.Dispose()}}
$reviewed=@()
if($errors.Count -eq 0){$reviewed=@($rows|Where-Object{$_.LegacyNonemptyPixels -eq 0 -and $_.DeclaredLegacyConsumers.Count -eq 0}|ForEach-Object{$_.LegacyRelativePath})}
$report=[pscustomobject][ordered]@{Schema=1;Scope='Three seedling models and their historical textures in current A/B sources';Findings=$errors.ToArray();ReviewedUnusedEmptyPaths=$reviewed;Seedlings=$rows.ToArray();SourceInstance=$instance;ExternalResourcePacksVerified=$false;VisualAccepted=$false;RuntimeVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'seedling-texture-contracts.json'),($report|ConvertTo-Json -Depth 35),[Text.UTF8Encoding]::new($false))
    $csv=$rows|Select-Object @{n='作物';e={$_.Name}},@{n='历史贴图';e={$_.LegacyTexture}},@{n='当前贴图';e={$_.ActiveTexture}},@{n='历史声明引用数';e={$_.DeclaredLegacyConsumers.Count}},@{n='状态模型';e={($_.States|ForEach-Object{$_.Model}) -join ';'}},@{n='判定范围';e={'当前A/B源码；外部资源包及动态引用未实机确认'}},VisualAccepted,RuntimeVerified|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'seedling-texture-contracts.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
if($PassThru){return $report}
Write-Output "[INFO] reviewed seedlings=3; state models=4; reviewed unused empty files=$($reviewed.Count); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] source texture/model contracts checked; visual and gameplay acceptance remain pending'
exit 0
