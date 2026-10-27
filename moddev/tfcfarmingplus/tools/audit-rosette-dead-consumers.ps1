param([string]$SourceInstance='', [string]$ReportDirectory='')
# Read-only shared death routing inventory. It neither simulates ticks nor accepts artwork.
$ErrorActionPreference='Stop'
$live=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$live}
$module=Join-Path $instance 'moddev/tfcfarmingplus'
$resources=Join-Path $module 'src/main/resources'
$java=Join-Path $module 'src/main/java/com/example/tfcfarmingplus'
$errors=New-Object 'System.Collections.Generic.List[string]'
$rows=New-Object 'System.Collections.Generic.List[object]'
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Read-Json([string]$relative){return Get-Content -LiteralPath (Join-Path $resources $relative) -Raw -Encoding UTF8|ConvertFrom-Json}
$source=Get-Content -LiteralPath (Join-Path $java 'common/MyCrops.java') -Raw -Encoding UTF8
$species=@([regex]::Matches($source,'\brosette\("([a-z_]+)"')|ForEach-Object{$_.Groups[1].Value}|Sort-Object)
$expected=@('agave','cardoon','kale','purslane','sisal')
Check (($species -join '|') -eq ($expected -join '|')) 'Shared rosette consumer set changed: update the scope review before modifying shared artwork.'
$factory=[regex]::Match($source,'(?s)private static DeferredHolder<Block, RosetteCropBlock> rosette\(.*?\n    \}').Value
Check ($factory -match 'MyBlocks\.DEAD_ROSETTE.get\(\), seedFor\(name\)') 'Rosette factory must route all declared species to shared dead block and species seed.'
$registry=Get-Content -LiteralPath (Join-Path $java 'common/MyBlocks.java') -Raw -Encoding UTF8
Check ($registry -match '(?s)DEAD_ROSETTE = BLOCKS.register\("dead_rosette",\s*\(\) -> new DeadCropBlock\(deadProps\(\), \(\) -> ClimateRange.NOOP\)\)') 'Shared dead registration changed: reassess state/storage and migration scope.'
$death=Get-Content -LiteralPath (Join-Path $java 'common/blocks/RosetteCropBlock.java') -Raw -Encoding UTF8
$method=[regex]::Match($death,'(?s)public void die\(.*?\n    \}').Value
Check ($method -match 'level.isClientSide\(\) \|\| !level.getBlockState\(pos\).is\(this\)') 'Shared death must guard client-side and already-replaced plants.'
Check ($method -match '(?s)if \(level.setBlockAndUpdate\(pos, dead.get\(\).defaultBlockState\(\).*?setValue\(DeadCropBlock.MATURE, fullyGrown\)\)\) \{\s*Block.popResource\(level, pos, new ItemStack\(seeds.get\(\)\)\)') 'Seed must be returned only after successful shared-block replacement.'
Check ([regex]::Matches($method,'Block.popResource').Count -eq 1) 'Death must have one source seed-return operation.'
$loot=Read-Json 'data/tfcfarmingplus/loot_table/blocks/dead_rosette.json'
Check (@($loot.pools).Count -eq 0) 'Shared dead loot must not duplicate the seed returned during death.'
$state=Read-Json 'assets/tfcfarmingplus/blockstates/dead_rosette.json'
Check ((@($state.variants.PSObject.Properties.Name|Sort-Object) -join '|') -eq 'mature=false|mature=true') 'Shared dead state space must be reviewed before adding species/fruit data.'
foreach($name in $species){foreach($mature in @('false','true')){
    $model=if($mature -eq 'true'){'tfcfarmingplus:block/dead_rosette'}else{'tfcfarmingplus:block/dead_rosette_young'}
    Check ($state.variants."mature=$mature".model -eq $model) "Shared dead model routing changed: $name/$mature"
    $rows.Add([pscustomobject][ordered]@{Species=$name;LiveBlock="tfcfarmingplus:crop/$name";DeadBlock='tfcfarmingplus:dead_rosette';Mature=$mature;Model=$model;SpeciesRetained=$false;SeedReturn='during successful server-side death transition';VisualAccepted=$false;RuntimeVerified=$false})
}}
# Find unexpected direct uses, including B, instead of assuming that five known plants are the whole scope.
$directJava=@();$stateRefs=@();$modelRefs=@()
foreach($side in @('tfcfarmingplus','tfcagricultureplus')){
    $base=Join-Path $instance "moddev/$side/src/main"
    foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $base 'java') -Recurse -File -Filter '*.java')){
        if((Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8) -match 'MyBlocks\.DEAD_ROSETTE'){$directJava+=$file.FullName.Substring($instance.Length+1).Replace('\','/')}
    }
    foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $base 'resources/assets') -Recurse -File -Filter '*.json')){
        $relative=$file.FullName.Substring($instance.Length+1).Replace('\','/')
        $body=Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        if($relative -match '/blockstates/' -and $body -match 'tfcfarmingplus:block/dead_rosette'){$stateRefs+=$relative}
        if($relative -match '/models/'){
            $definition=$body|ConvertFrom-Json
            # Only parent is a model ID; the same text in textures denotes a PNG, not a consumer.
            if($definition.parent -match '^tfcfarmingplus:block/(crop/rosette_dead|dead_rosette)(_young)?$'){$modelRefs+=$relative}
        }
    }
}
$expectedJava=@('moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/client/TFCFarmingPlusClient.java','moddev/tfcfarmingplus/src/main/java/com/example/tfcfarmingplus/common/MyCrops.java')
$expectedStates=@('moddev/tfcfarmingplus/src/main/resources/assets/tfcfarmingplus/blockstates/dead_rosette.json')
$expectedModels=@('moddev/tfcfarmingplus/src/main/resources/assets/tfcfarmingplus/models/block/dead_rosette.json','moddev/tfcfarmingplus/src/main/resources/assets/tfcfarmingplus/models/block/dead_rosette_young.json')
Check ((@($directJava|Sort-Object) -join '|') -eq (@($expectedJava|Sort-Object) -join '|')) 'Unexpected direct shared dead Java consumer.'
Check ((@($stateRefs|Sort-Object) -join '|') -eq (@($expectedStates|Sort-Object) -join '|')) 'Unexpected shared dead blockstate consumer.'
Check ((@($modelRefs|Sort-Object) -join '|') -eq (@($expectedModels|Sort-Object) -join '|')) 'Unexpected shared dead model alias/consumer.'
$hashes=@{}
foreach($relative in @('assets/tfcfarmingplus/blockstates/dead_rosette.json','data/tfcfarmingplus/loot_table/blocks/dead_rosette.json','assets/tfcfarmingplus/models/block/dead_rosette.json','assets/tfcfarmingplus/models/block/dead_rosette_young.json','assets/tfcfarmingplus/models/block/crop/rosette_dead.json','assets/tfcfarmingplus/models/block/crop/rosette_dead_young.json','assets/tfcfarmingplus/textures/block/crop/rosette_dead.png','assets/tfcfarmingplus/textures/block/crop/rosette_dead_young.png')){
    $hashes[$relative]=(Get-FileHash -LiteralPath (Join-Path $resources $relative) -Algorithm SHA256).Hash
}
Check ($rows.Count -eq 10) 'Expected five source species times two shared dead cases (only two distinct blockstates).'
# AR4-G: validate the two real model states, not ten duplicate geometry copies.
try{Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop}catch{Add-Type -AssemblyName System.Drawing -ErrorAction Stop}
$modelCases=New-Object 'System.Collections.Generic.List[object]'
foreach($young in @($false,$true)){
    $suffix=if($young){'_young'}else{''}
    $relative="assets/tfcfarmingplus/models/block/crop/rosette_dead$suffix.json"
    $geometry=Read-Json $relative
    $atlas="tfcfarmingplus:block/crop/rosette_dead$suffix"
    Check ($geometry.textures.'0' -eq $atlas) "Shared dry geometry must retain neutral shared atlas: $relative"
    $particle=[string]$geometry.textures.particle
    Check ($particle -eq '#0' -or $particle -eq $atlas) "Shared dry particle must match its neutral atlas: $relative"
    Check (@($geometry.elements).Count -eq $(if($young){2}else{4})) "Shared dry leaf layout changed: $relative"
    $bitmap=[Drawing.Bitmap]::new((Join-Path $resources "assets/tfcfarmingplus/textures/block/crop/rosette_dead$suffix.png"))
    $faces=0;$nonempty=0;$samples=New-Object 'System.Collections.Generic.List[object]'
    try{
        foreach($element in $geometry.elements){
            Check (@($element.from).Count -eq 3 -and @($element.to).Count -eq 3) "Malformed dry geometry: $relative"
            $flat=@(0..2|Where-Object{[double]$element.from[$_] -eq [double]$element.to[$_]})
            Check ($flat.Count -eq 1 -and $flat[0] -in @(0,2)) "Shared dry shape must remain vertical leaf planes, not a new species fruit: $relative"
            Check ($element.rotation.axis -in @('x','z') -and $element.rotation.angle -in @(-45,-22.5,0,22.5,45)) "Invalid dry leaf rotation: $relative"
            $allowed=if($flat[0] -eq 0){@('east','west')}else{@('north','south')}
            Check ((@($element.faces.PSObject.Properties.Name|Sort-Object) -join '|') -eq (@($allowed|Sort-Object) -join '|')) "Dry plane must have both matching face directions: $relative"
            foreach($side in $element.faces.PSObject.Properties){
                $faces++;$uv=@($side.Value.uv)
                Check ($side.Value.texture -eq '#0' -and $uv.Count -eq 4) "Dry face must sample the shared leaf atlas: $relative"
                $u0=[Math]::Min($uv[0],$uv[2]);$u1=[Math]::Max($uv[0],$uv[2]);$v0=[Math]::Min($uv[1],$uv[3]);$v1=[Math]::Max($uv[1],$uv[3])
                $leftSlot=$young -or $flat[0] -eq 2
                $expectedU=if($leftSlot){'0,8'}else{'8,16'}
                $expectedV=if($young){'8,16'}else{'0,16'}
                Check (("$u0,$u1" -eq $expectedU) -and ("$v0,$v1" -eq $expectedV)) "Dry UV must preserve the complete allocated silhouette region: $relative/$($side.Name)"
                $widthAxis=if($flat[0] -eq 0){2}else{0}
                $worldWidth=[double]$element.to[$widthAxis]-[double]$element.from[$widthAxis]
                $worldHeight=[double]$element.to[1]-[double]$element.from[1]
                Check ([Math]::Abs($worldWidth-($u1-$u0)) -lt 0.000001 -and [Math]::Abs($worldHeight-($v1-$v0)) -lt 0.000001) "Shared dry UV must remain 1:1 with the model plane: $relative/$($side.Name)"
                $opaque=0
                if($u0 -ge 0 -and $u1 -le 16 -and $v0 -ge 0 -and $v1 -le 16){
                    for($y=[int][Math]::Floor($v0*$bitmap.Height/16);$y -lt [Math]::Ceiling($v1*$bitmap.Height/16);$y++){
                        for($x=[int][Math]::Floor($u0*$bitmap.Width/16);$x -lt [Math]::Ceiling($u1*$bitmap.Width/16);$x++){if($bitmap.GetPixel($x,$y).A -ge 8){$opaque++}}
                    }
                }
                if($opaque -gt 0){$nonempty++}
                Check ($opaque -gt 0) "Shared dry face samples an empty atlas region: $relative/$($side.Name)"
                $samples.Add([pscustomobject]@{Face=$side.Name;UV=$uv;OpaqueSamples=$opaque})
            }
        }
    }finally{$bitmap.Dispose()}
    $modelCases.Add([pscustomobject]@{Model="tfcfarmingplus:block/crop/rosette_dead$suffix";Mature=(-not $young);FaceCount=$faces;NonemptyFaces=$nonempty;FaceSamples=$samples.ToArray();VisualAccepted=$false;RuntimeVerified=$false})
}
$report=[ordered]@{Schema=1;Scope='AR4-F/G five sources, ten logical death cases, two shared model states with per-face UV checks';Findings=$errors.ToArray();StateCases=$rows.ToArray();ModelCases=$modelCases.ToArray();DirectJava=$directJava;BlockstateConsumers=$stateRefs;ModelConsumers=$modelRefs;SharedResourceHashes=$hashes;SpeciesRetained=$false;VisualAccepted=$false;RuntimeVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'shared-dead-rosette-scope.json'),($report|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
    $csv=$rows|Select-Object @{n='来源作物';e={$_.Species}},@{n='活株';e={$_.LiveBlock}},@{n='共享死株';e={$_.DeadBlock}},Mature,Model,@{n='保留物种';e={$_.SpeciesRetained}},SeedReturn,VisualAccepted,RuntimeVerified|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'shared-dead-rosette-scope.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output "[INFO] shared dead rosette: species=$($species.Count); logical cases=$($rows.Count); distinct states=2; findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] shared death routing/seed contracts inventoried; shared UV/model contracts checked, appearance and gameplay unverified'
exit 0
