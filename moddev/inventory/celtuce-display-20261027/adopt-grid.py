from pathlib import Path
from hashlib import sha256
import json, shutil, zipfile

o=Path(__file__).resolve().parent;r=o.parents[2];a=r/'moddev/tfcfarmingplus';s=a/'src/main/resources';t=a/'tools';b=r/'moddev/backups/ar4af-celtuce-display-20261027'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for row in load(b/'backup-manifest.json'):
    if row['path'].startswith(('moddev/tfcfarmingplus/src/','moddev/tfcfarmingplus/tools/','moddev/tfcagricultureplus/src/','moddev/tfcagricultureplus/tools/')):
        assert digest(r/row['path'])==row['sha256'],row['path']
paths=load(o/'candidate-paths.json')
for rel in paths:
    p=s/rel;p.parent.mkdir(parents=True,exist_ok=True)
    if p.suffix=='.png':assert not p.exists(),p
    shutil.copy2(o/'candidate-v2-resources'/rel,p)
files=[v.replace('swiss_chard','celtuce') for v in load(t/'swiss_chard-display-files.json')]
pngs=sorted((s/'assets/tfcfarmingplus/textures').rglob('celtuce*.png'))
gameplay=sorted(p for p in (s/'data').rglob('celtuce*.json') if '/plantable/' not in p.as_posix())+[a/'src/main/java/com/example/tfcfarmingplus/common'/n for n in ['MyCrops.java','MyWildCrops.java','blocks/MyCropBlock.java']]
jar=next((r/'mods').glob('TerraFirmaCraft-*.jar'));native=[]
with zipfile.ZipFile(jar) as archive:
    for key in ['assets/tfc/models/block/wild_crop/crop.json','assets/tfc/textures/block/crop/wild_crop_grass.png']:
        native.append({'Path':key,'SHA256':sha256(archive.read(key)).hexdigest().upper()})
c={'Schema':1,'Scope':'AR4-AF native16 celtuce complete display; artwork/runtime approval pending','ReviewedJsonSha256':{rel:digest(s/rel) for rel in files},'ProtectedTextureSha256':{p.relative_to(s).as_posix():digest(p) for p in pngs},'ProtectedGameplaySha256':{p.relative_to(a).as_posix():digest(p) for p in gameplay},'PlanterStageTextures':load(s/'data/firmalife/firmalife/plantable/celtuce.json')['textures'],'NativeDependency':{'Jar':jar.name,'Files':native},'PixelSourceRule':'Eight explicit 16x16 grids;64 is exact4x nearest preview,workspace only.','VisualAccepted':False,'RuntimeVerified':False}
save(t/'celtuce-display-contract.json',c);save(t/'celtuce-display-files.json',files)
text=(t/'audit-swiss-chard-display.ps1').read_text(encoding='utf-8-sig').replace('Swiss chard','Celtuce').replace('swiss_chard','celtuce')
(t/'audit-celtuce-display.ps1').write_text(text,encoding='utf-8-sig')
p=t/'gen-crops.ps1';text=p.read_text(encoding='utf-8-sig')
edits={
    '[switch]$CeleryDisplayOnly, [switch]$ItemIconsOnly':'[switch]$CeleryDisplayOnly, [switch]$CeltuceDisplayOnly, [switch]$ItemIconsOnly',
    "[ValidateSet('chili','fenugreek','spinach','sunflower','swiss_chard','celery')]":"[ValidateSet('chili','fenugreek','spinach','sunflower','swiss_chard','celery','celtuce')]",
    "    if($Species -eq 'swiss_chard'){":"    if($Species -eq 'celtuce'){\n        & (Join-Path $PSScriptRoot 'audit-celtuce-display.ps1')\n        if($LASTEXITCODE -ne 0){throw 'Celtuce display preflight failed; no files copied.'}\n    }\n    if($Species -eq 'swiss_chard'){",
    '$CeleryDisplayOnly,$ItemIconsOnly)':'$CeleryDisplayOnly,$CeltuceDisplayOnly,$ItemIconsOnly)',
    "if($SwissChardDisplayOnly){Copy-ReviewedCropDisplay 'swiss_chard';exit 0}":"if($SwissChardDisplayOnly){Copy-ReviewedCropDisplay 'swiss_chard';exit 0}\nif($CeltuceDisplayOnly){Copy-ReviewedCropDisplay 'celtuce';exit 0}",
    "Copy-ReviewedCropDisplay 'celery'\nCopy-ReviewedItemIcons":"Copy-ReviewedCropDisplay 'celery'\nCopy-ReviewedCropDisplay 'celtuce'\nCopy-ReviewedItemIcons",
}
for before,after in edits.items():assert text.count(before)==1,before;text=text.replace(before,after)
p.write_text(text,encoding='utf-8-sig')
p=t/'verify.ps1';text=p.read_text(encoding='utf-8-sig');anchor="& (Join-Path $PSScriptRoot 'audit-item-icon-routes.ps1')";assert text.count(anchor)==1
text=text.replace(anchor,"& (Join-Path $PSScriptRoot 'audit-celtuce-display.ps1')\nif ($LASTEXITCODE -ne 0) { [void]$errors.Add('Celtuce display contracts failed.') }\n\n"+anchor);p.write_text(text,encoding='utf-8-sig')
manifest=load(o/'native-grid-manifest.json');listing=['莴笋正式贴图路径（16×16原图；64×64仅工作区预览）','']
for row in manifest['Assets']:
    folder='crop' if '_age_' in row['Name'] else 'dead_crop';row['FinalPath']=str(s/f"assets/tfcfarmingplus/textures/block/{folder}/{row['Name']}.png")
    listing.extend([row['Name'],row['FinalPath'],'64预览：'+row['Preview64'],'16格像素源：'+row['EditableSource'],''])
save(o/'asset-manifest.json',manifest);(o/'贴图文件路径.txt').write_text('\n'.join(listing),encoding='utf-8-sig')
save(o/'adoption-manifest.json',{'ModifiedAndAddedResources':paths,'ProtectedDisplayJSONs':len(files),'ProtectedPNGs':len(pngs),'ProtectedGameplay':len(gameplay),'NoOldArtOverwritten':True,'NativeGrid16':True,'WorkspacePreviews64Only':True,'VisualAccepted':False,'RuntimeVerified':False})
print('Adopted12JSON+8newPNG; protected',len(files),len(pngs),len(gameplay))
