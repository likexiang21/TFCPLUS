param([string]$SourceInstance='', [string]$ReportDirectory='')
# Read-only five-species contracts. Geometry checks do not imply visual acceptance.
$ErrorActionPreference='Stop'
try{Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop}catch{Add-Type -AssemblyName System.Drawing -ErrorAction Stop}
if(-not ('Ar4cRosetteGeometry' -as [type])){
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
public static class Ar4cRosetteGeometry {
    public static double[] Corners(double[] lo,double[] hi,double[] origin,string axis,double angle) {
        int flat=-1;
        for(int i=0;i<3;i++) if(lo[i]==hi[i]) {if(flat!=-1) throw new ArgumentException("Degenerate leaf");flat=i;}
        if(flat==-1) throw new ArgumentException("Expected a flat leaf");
        double[][] p;
        if(flat==0) p=new double[][]{new double[]{lo[0],lo[1],lo[2]},new double[]{lo[0],hi[1],lo[2]},new double[]{lo[0],hi[1],hi[2]},new double[]{lo[0],lo[1],hi[2]}};
        else if(flat==1) p=new double[][]{new double[]{lo[0],lo[1],lo[2]},new double[]{hi[0],lo[1],lo[2]},new double[]{hi[0],lo[1],hi[2]},new double[]{lo[0],lo[1],hi[2]}};
        else p=new double[][]{new double[]{lo[0],lo[1],lo[2]},new double[]{hi[0],lo[1],lo[2]},new double[]{hi[0],hi[1],lo[2]},new double[]{lo[0],hi[1],lo[2]}};
        double radians=angle*Math.PI/180,c=Math.Cos(radians),s=Math.Sin(radians);double[] result=new double[12];
        for(int i=0;i<4;i++) {
            double x=p[i][0],y=p[i][1],z=p[i][2];
            if(angle!=0) {
                x-=origin[0];y-=origin[1];z-=origin[2];double nx=x,ny=y,nz=z;
                if(axis=="x"){ny=y*c-z*s;nz=y*s+z*c;}
                else if(axis=="y"){nx=x*c+z*s;nz=-x*s+z*c;}
                else if(axis=="z"){nx=x*c-y*s;ny=x*s+y*c;}
                else throw new ArgumentException("Unknown rotation axis");
                x=nx+origin[0];y=ny+origin[1];z=nz+origin[2];
            }
            result[3*i]=x;result[3*i+1]=y;result[3*i+2]=z;
        }
        return result;
    }
    private static List<double[]> Clip(List<double[]> input,int axis,double bound,bool greater) {
        List<double[]> output=new List<double[]>();if(input.Count==0) return output;
        double[] previous=input[input.Count-1];double last=(greater?1:-1)*(previous[axis]-bound);
        foreach(double[] current in input) {
            double distance=(greater?1:-1)*(current[axis]-bound);
            if((distance>=0)!=(last>=0)) {
                double t=last/(last-distance);double[] point=new double[3];
                for(int k=0;k<3;k++) point[k]=previous[k]+t*(current[k]-previous[k]);output.Add(point);
            }
            if(distance>=0) output.Add(current);previous=current;last=distance;
        }
        return output;
    }
    public static bool Penetrates(double[] quad,double[] lo,double[] hi) {
        List<double[]> p=new List<double[]>();for(int i=0;i<4;i++) p.Add(new double[]{quad[3*i],quad[3*i+1],quad[3*i+2]});
        for(int axis=0;axis<3;axis++){p=Clip(p,axis,lo[axis]+0.000001,true);p=Clip(p,axis,hi[axis]-0.000001,false);}
        if(p.Count<3) return false;double ax=0,ay=0,az=0;
        for(int i=1;i<p.Count-1;i++) {
            double[] u=new double[3],v=new double[3];for(int k=0;k<3;k++){u[k]=p[i][k]-p[0][k];v[k]=p[i+1][k]-p[0][k];}
            ax+=u[1]*v[2]-u[2]*v[1];ay+=u[2]*v[0]-u[0]*v[2];az+=u[0]*v[1]-u[1]*v[0];
        }
        return ax*ax+ay*ay+az*az>0.000000000001;
    }
}
'@
}
$liveInstance=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$liveInstance}
$module=Join-Path $instance 'moddev/tfcfarmingplus';$assets=Join-Path $module 'src/main/resources/assets';$species=@('kale','cardoon','agave','purslane','sisal')
$errors=New-Object 'System.Collections.Generic.List[string]';$rows=New-Object 'System.Collections.Generic.List[object]';$cache=@{};$pixels=@{}
function Check([bool]$condition,[string]$message){if(-not $condition){$errors.Add($message)}}
function Json([string]$path){Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json}
function Model([string]$id,[string[]]$trail=@()){
    if($id -in $trail){throw "Model cycle: $id"};if($cache.ContainsKey($id)){return $cache[$id]}
    $ns,$path=$id.Split(':',2);$data=Json (Join-Path $assets "$ns/models/$path.json");$textures=@{};$elements=@();$chain=@()
    if($data.parent){$parent=Model $data.parent @($trail+$id);foreach($key in $parent.Textures.Keys){$textures[$key]=$parent.Textures[$key]};$elements=$parent.Elements;$chain=$parent.Chain}
    foreach($property in $data.textures.PSObject.Properties){$textures[$property.Name]=[string]$property.Value}
    if($data.PSObject.Properties['elements']){$elements=@($data.elements)}
    $result=[pscustomobject]@{Textures=$textures;Elements=$elements;Chain=@($id)+@($chain)};$cache[$id]=$result;return $result
}
function Texture([string]$value,$map){$seen=@();while($value.StartsWith('#')){if($value -in $seen){throw 'Texture alias cycle'};$seen+=$value;$value=[string]$map[$value.Substring(1)]};if(-not $value){throw 'Missing texture binding'};return $value}
function Visible-Pixels([string]$id){
    if(-not $pixels.ContainsKey($id)){$ns,$path=$id.Split(':',2);$image=[Drawing.Bitmap]::new((Join-Path $assets "$ns/textures/$path.png"));try{$count=0;for($y=0;$y -lt $image.Height;$y++){for($x=0;$x -lt $image.Width;$x++){if($image.GetPixel($x,$y).A -ge 8){$count++}}};$pixels[$id]=$count}finally{$image.Dispose()}}
    return $pixels[$id]
}
$sharedID='tfcfarmingplus:block/crop/rosette_age_5_fruiting';$shared=Json (Join-Path $assets 'tfcfarmingplus/models/block/crop/rosette_age_5_fruiting.json')
$leaves=@($shared.elements|Where-Object{($_.from[0] -eq $_.to[0]) -or ($_.from[1] -eq $_.to[1]) -or ($_.from[2] -eq $_.to[2])})
$heads=@($shared.elements|Where-Object{($_.from[0] -ne $_.to[0]) -and ($_.from[1] -ne $_.to[1]) -and ($_.from[2] -ne $_.to[2])})
Check ($heads.Count -eq 1 -and $leaves.Count -eq 12 -and @($shared.elements).Count -eq 13) 'Mature shared model must contain one cube and twelve intact leaves.'
$head=$heads[0]
Check (($head.from -join ',') -eq '6,7,6' -and ($head.to -join ',') -eq '10,12,10') 'Reviewed fruit cube must be centered with bounds [6,7,6]..[10,12,10].'
$penetrating=@();$index=0;$vertical=@();$inside=$true
foreach($leaf in $leaves){
    $origin=if($leaf.rotation){[double[]]$leaf.rotation.origin}else{[double[]]@(0,0,0)};$axis=if($leaf.rotation){[string]$leaf.rotation.axis}else{'x'};$angle=if($leaf.rotation){[double]$leaf.rotation.angle}else{0}
    Check ($angle -in @(-45,-22.5,0,22.5,45) -and -not $leaf.rotation.rescale) 'Unsupported leaf rotation or rescale.'
    $flat=@(0..2|Where-Object{$leaf.from[$_] -eq $leaf.to[$_]});Check ($flat.Count -eq 1) 'Each leaf must be one non-degenerate plane.'
    $quad=[Ar4cRosetteGeometry]::Corners([double[]]$leaf.from,[double[]]$leaf.to,$origin,$axis,$angle)
    if([Ar4cRosetteGeometry]::Penetrates($quad,[double[]]$head.from,[double[]]$head.to)){$penetrating+=$index}
    foreach($coordinate in $quad){if($coordinate -lt -0.000001 -or $coordinate -gt 16.000001){$inside=$false}}
    if($angle -eq 0){$vertical+=,$leaf}
    foreach($face in $leaf.faces.PSObject.Properties){$allowed=@(@('west','east'),@('down','up'),@('north','south'))[$flat[0]];Check ($face.Name -in $allowed) 'Leaf face type mismatches its flat axis.'}
    $index++
}
Check ($inside) 'Transformed leaves must remain inside the block.'
Check ($penetrating.Count -eq 0) ("Leaf polygons penetrate the fruit interior: {0}" -f ($penetrating -join ','))
Check ($vertical.Count -eq 4) 'Four whole vertical support leaves are required.'
$planes=@()
foreach($leaf in $vertical){
    Check ($leaf.from[1] -eq 0 -and $leaf.to[1] -eq 10) 'Support leaf height must remain ten units.'
    if($leaf.from[0] -eq $leaf.to[0]){Check ($leaf.from[2] -eq 4 -and $leaf.to[2] -eq 12) 'Support leaf width must remain eight units.';$planes+='x='+$leaf.from[0]}
    elseif($leaf.from[2] -eq $leaf.to[2]){Check ($leaf.from[0] -eq 4 -and $leaf.to[0] -eq 12) 'Support leaf width must remain eight units.';$planes+='z='+$leaf.from[2]}
}
Check ((@($planes|Sort-Object) -join '|') -eq 'x=10.02|x=5.98|z=10.02|z=5.98') 'Support planes must flank all four cube sides with a 0.02-unit gap.'
$consumerRoot=(Resolve-Path -LiteralPath (Join-Path $assets 'tfcfarmingplus/models')).Path
$consumers=@(Get-ChildItem -LiteralPath $consumerRoot -Recurse -File -Filter '*.json'|Where-Object{(Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8).Contains($sharedID)}|ForEach-Object{'tfcfarmingplus:'+ $_.FullName.Substring($consumerRoot.Length+1).Replace('\','/').Replace('.json','')})
$expectedConsumers=@($species|ForEach-Object{"tfcfarmingplus:block/crop/${_}_age_5_fruiting"}|Sort-Object)
Check ((@($consumers|Sort-Object) -join '|') -ceq ($expectedConsumers -join '|')) 'Shared fruit consumers differ from the five reviewed mature wrappers.'
foreach($name in $species){
    $states=Json (Join-Path $assets "tfcfarmingplus/blockstates/crop/$name.json")
    Check (@($states.variants.PSObject.Properties).Count -eq 12) "Expected twelve declared states: $name"
    foreach($flag in @('false','true')){foreach($age in 0..5){
        $key="age=$age,fruiting=$flag";$id=[string]$states.variants.$key.model;$resolved=Model $id;$fruiting=($age -eq 5 -and $flag -eq 'true')
        Check (($sharedID -in $resolved.Chain) -eq $fruiting) "Mature shared geometry reached by wrong state: $name/$key"
        $leafTexture=Texture '#0' $resolved.Textures;$particle=Texture ([string]$resolved.Textures['particle']) $resolved.Textures
        Check ((Visible-Pixels $leafTexture) -gt 0) "State foliage texture is empty: $name/$key"
        if($fruiting){
            Check ($particle -eq $leafTexture) "Mature particle must inherit species foliage: $name"
            foreach($slot in @('1','2')){Check ((Visible-Pixels (Texture ('#'+$slot) $resolved.Textures)) -gt 0) "Mature fruit texture is empty: $name/$slot"}
        }
        $rows.Add([pscustomobject][ordered]@{Species=$name;State=$key;Model=$id;UsesSharedMatureGeometry=$fruiting;FoliageTexture=$leafTexture;ParticleTexture=$particle;VisualAccepted=$false;RuntimeVerified=$false})
    }}
}
$report=[ordered]@{Schema=1;Scope='AR4-C 5 rosette species / 60 declared states';Findings=$errors.ToArray();FruitBounds=@{From=@($head.from);To=@($head.to)};LeafCount=$leaves.Count;SupportPlanes=$planes;PenetratingLeafIndices=$penetrating;ConsumerModels=$consumers;StateCases=$rows.ToArray();VisualAccepted=$false;RuntimeVerified=$false;ExternalResourcePacksVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($ReportDirectory))
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'rosette-fruit-contracts.json'),($report|ConvertTo-Json -Depth 35),[Text.UTF8Encoding]::new($false))
    $csv=$rows|Select-Object @{n='作物';e={$_.Species}},@{n='状态';e={$_.State}},Model,@{n='使用本批共享结果几何';e={$_.UsesSharedMatureGeometry}},@{n='叶片贴图';e={$_.FoliageTexture}},@{n='粒子贴图';e={$_.ParticleTexture}},VisualAccepted,RuntimeVerified|ConvertTo-Csv -NoTypeInformation
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'rosette-fruit-contracts.csv'),(($csv -join "`r`n")+"`r`n"),[Text.UTF8Encoding]::new($true))
}
Write-Output "[INFO] rosette states=$($rows.Count); mature consumers=$($consumers.Count); penetrating leaves=$($penetrating.Count); findings=$($errors.Count)"
if($errors.Count){$errors|ForEach-Object{Write-Output "[FAIL] $_"};exit 1}
Write-Output '[OK] mature fruit support source contracts checked; appearance and gameplay remain pending'
exit 0
