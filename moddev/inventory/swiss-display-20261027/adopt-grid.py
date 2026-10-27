from pathlib import Path
from hashlib import sha256
import json,shutil,zipfile
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;a=r/'moddev/tfcfarmingplus';s=a/'src/main/resources';t=a/'tools';b=r/'moddev/backups/ar4ad-swiss-display-20261027'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for row in load(b/'backup-manifest.json'):
 if row['path'].startswith(('moddev/tfcfarmingplus/src/','moddev/tfcfarmingplus/tools/','moddev/tfcagricultureplus/src/','moddev/tfcagricultureplus/tools/')):assert digest(r/row['path'])==row['sha256'],row['path']
paths=load(o/'candidate-paths.json')
for rel in paths:
 p=s/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(o/'candidate-v2-resources'/rel,p)
files=[v.replace('spinach','swiss_chard') for v in load(t/'spinach-display-files.json')]
pngs=sorted(p for p in (s/'assets/tfcfarmingplus/textures').rglob('swiss_chard*.png'))
gameplay=sorted(p for p in (s/'data').rglob('swiss_chard*.json') if '/plantable/' not in p.as_posix())+[a/'src/main/java/com/example/tfcfarmingplus/common'/n for n in ['MyCrops.java','MyWildCrops.java','blocks/MyCropBlock.java']]
jar=next((r/'mods').glob('TerraFirmaCraft-*.jar'))
native=[]
with zipfile.ZipFile(jar) as archive:
 for key in ['assets/tfc/models/block/wild_crop/crop.json','assets/tfc/textures/block/crop/wild_crop_grass.png']:native.append({'Path':key,'SHA256':sha256(archive.read(key)).hexdigest().upper()})
c={'Schema':1,'Scope':'AR4-AD native16 Swiss chard complete display; player artwork/runtime approval pending','ReviewedJsonSha256':{rel:digest(s/rel) for rel in files},'ProtectedTextureSha256':{p.relative_to(s).as_posix():digest(p) for p in pngs},'ProtectedGameplaySha256':{p.relative_to(a).as_posix():digest(p) for p in gameplay},'PlanterStageTextures':load(s/'data/firmalife/firmalife/plantable/swiss_chard.json')['textures'],'NativeDependency':{'Jar':jar.name,'Files':native},'PixelSourceRule':'Eight 16-row x16-column editable sources; 64 previews are exact 4x nearest-neighbor and workspace-only. AI drafts not adopted.','VisualAccepted':False,'RuntimeVerified':False}
save(t/'swiss_chard-display-contract.json',c);save(t/'swiss_chard-display-files.json',files)
# Reuse the project's reviewed canonical-file checker, with the actual single-block
# property space and without sunflower-specific head geometry.
text=(t/'audit-sunflower-display.ps1').read_text(encoding='utf-8-sig').replace('Sunflower','Swiss chard').replace('sunflower','swiss_chard')
start=text.index('foreach($age in 0..5)');end=text.index("foreach($mature in @('false','true')){",start)
text=text[:start]+'''foreach($age in 0..5){
    State-Case 'crop' @{age=[string]$age} "tfcfarmingplus:block/crop/swiss_chard_age_$age"
}
'''+text[end:]
start=text.index("foreach($mature in @('false','true')){");end=text.index("foreach($mature in @('false','true')){",start+10)
text=text[:start]+'''foreach($mature in @('false','true')){
    $suffix=if($mature -eq 'false'){'_young'}else{''}
    State-Case 'dead_crop' @{mature=$mature} "tfcfarmingplus:block/dead_crop/swiss_chard$suffix"
}
'''+text[end:]
start=text.index('foreach($age in 3..5)');end=text.index('$planter=Read-Json',start);text=text[:start]+text[end:]
anchor='Pin-Files $contract.ProtectedGameplaySha256 $module $false';assert text.count(anchor)==1
native_code='''
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
'''
text=text.replace(anchor,anchor+'\n'+native_code);(t/'audit-swiss-chard-display.ps1').write_text(text,encoding='utf-8-sig')
p=t/'gen-crops.ps1';text=p.read_text(encoding='utf-8-sig').replace('[switch]$SunflowerDisplayOnly, [switch]$ItemIconsOnly','[switch]$SunflowerDisplayOnly, [switch]$SwissChardDisplayOnly, [switch]$ItemIconsOnly').replace("[ValidateSet('chili','fenugreek','spinach','sunflower')]","[ValidateSet('chili','fenugreek','spinach','sunflower','swiss_chard')]")
anchor="    if($Species -eq 'spinach'){";assert text.count(anchor)==1;text=text.replace(anchor,"    if($Species -eq 'swiss_chard'){\n        & (Join-Path $PSScriptRoot 'audit-swiss-chard-display.ps1')\n        if($LASTEXITCODE -ne 0){throw 'Swiss chard display preflight failed; no files copied.'}\n    }\n"+anchor)
text=text.replace('$SunflowerDisplayOnly,$ItemIconsOnly)','$SunflowerDisplayOnly,$SwissChardDisplayOnly,$ItemIconsOnly)').replace("if($SunflowerDisplayOnly){Copy-ReviewedCropDisplay 'sunflower';exit 0}","if($SunflowerDisplayOnly){Copy-ReviewedCropDisplay 'sunflower';exit 0}\nif($SwissChardDisplayOnly){Copy-ReviewedCropDisplay 'swiss_chard';exit 0}").replace("Copy-ReviewedCropDisplay 'sunflower'\nCopy-ReviewedItemIcons","Copy-ReviewedCropDisplay 'sunflower'\nCopy-ReviewedCropDisplay 'swiss_chard'\nCopy-ReviewedItemIcons");p.write_text(text,encoding='utf-8-sig')
p=t/'verify.ps1';text=p.read_text(encoding='utf-8-sig');anchor="& (Join-Path $PSScriptRoot 'audit-item-icon-routes.ps1')";assert text.count(anchor)==1;text=text.replace(anchor,"& (Join-Path $PSScriptRoot 'audit-swiss-chard-display.ps1')\nif ($LASTEXITCODE -ne 0) { [void]$errors.Add('Swiss chard display contracts failed.') }\n\n"+anchor);p.write_text(text,encoding='utf-8-sig')
p=r/'DEVELOPMENT_RULES.md';text=p.read_text(encoding='utf-8-sig');anchor='- 绘制新贴图前，';assert text.count(anchor)==1;text=text.replace(anchor,'- 新农业单张作物贴图必须从16×16实际像素网格起稿，保留16行×16列可编辑像素源；64×64仅作为工作区四倍最近邻预览，不进入正式资源或JAR，不能用高分辨率画稿缩小来冒充16格起稿。GUI槽、动画图集按已有专用规格单独登记，不随作物规则盲目缩放。\n'+anchor);p.write_text(text,encoding='utf-8')
manifest=load(o/'native-grid-manifest.json');listing=['本轮牛皮菜贴图路径（正式原图均16×16；64预览仅供工作区查看）','']
for row in manifest['Assets']:
 folder='crop' if '_age_' in row['Name'] else 'dead_crop';row['FinalPath']=str(s/f"assets/tfcfarmingplus/textures/block/{folder}/{row['Name']}.png");listing += [row['Name'],row['FinalPath'],'64预览：'+row['Preview64'],'16格像素源：'+row['EditableSource'],'']
save(o/'asset-manifest.json',manifest);(o/'贴图文件路径.txt').write_text('\n'.join(listing),encoding='utf-8-sig')
save(o/'adoption-manifest.json',{'ModifiedAndAddedResources':paths,'ProtectedDisplayJSONs':17,'ProtectedPNGs':len(pngs),'ProtectedGameplay':len(gameplay),'NoOldArtOverwritten':True,'NativeGrid16':True,'WorkspacePreviews64Only':True,'VisualAccepted':False,'RuntimeVerified':False});print('Adopted native16 grid sources: 12 display JSONs /8 new PNGs; contract',len(files),len(pngs),len(gameplay))
