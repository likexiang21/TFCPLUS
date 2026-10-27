"""Publish the visually reviewed JSON candidate, preserving all PNGs and gameplay."""
from pathlib import Path
from hashlib import sha256
import json,shutil
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent
a=r/'moddev/tfcfarmingplus';s=a/'src/main/resources';t=a/'tools';b=r/'moddev/backups/ar4aa-sunflower-display-20261027'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
paths=load(o/'candidate-paths.json')
# Protect against external changes since backup before the first publication.
for row in load(b/'backup-manifest.json'):
    if row['path'].startswith(('moddev/tfcfarmingplus/src/','moddev/tfcfarmingplus/tools/','moddev/tfcagricultureplus/src/','moddev/tfcagricultureplus/tools/')):
        assert digest(r/row['path'])==row['sha256'],row['path']
for rel in paths:
    p=s/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(o/'candidate-resources'/rel,p)
files=sorted(set(paths+['assets/tfcfarmingplus/blockstates/crop/sunflower.json']+[f'assets/tfcfarmingplus/models/item/{kind}/sunflower.json' for kind in ['food','seeds','wild_crop']]))
textures=sorted(p for p in (s/'assets/tfcfarmingplus/textures').rglob('sunflower*.png'))
gameplay=sorted(p for p in (s/'data').rglob('sunflower*.json') if '/plantable/' not in p.as_posix())
gameplay += [a/'src/main/java/com/example/tfcfarmingplus/common'/name for name in ['MyCrops.java','MyWildCrops.java','blocks/MyDoubleCropBlock.java']]
contract={'Schema':1,'Scope':'AR4-AA sunflower display; whole cultivated/dead two-block plant, single-block wild, quad planter; visual/runtime acceptance pending',
          'ReviewedJsonSha256':{rel:digest(s/rel) for rel in files},
          'ProtectedTextureSha256':{p.relative_to(s).as_posix():digest(p) for p in textures},
          'ProtectedGameplaySha256':{p.relative_to(a).as_posix():digest(p) for p in gameplay},
          'PlanterStageTextures':load(s/'data/firmalife/firmalife/plantable/sunflower.json')['textures'],
          'PlanterNote':'Native quad renders one atlas sprite, not two crop blocks. Slots 2/3 and 4/5 intentionally share preserved whole-plant artwork; growth mechanics unchanged.',
          'SeedIconNote':'Planting icon remains native TFC barley; stored red generic seed debris is not adopted. Food sunflower_harvest_v2 remains distinct and unchanged.',
          'VisualAccepted':False,'RuntimeVerified':False}
write(t/'sunflower-display-contract.json',contract);write(t/'sunflower-display-files.json',files)
p=t/'gen-crops.ps1';text=p.read_text(encoding='utf-8-sig')
text=text.replace('[switch]$SpinachDisplayOnly, [switch]$ItemIconsOnly','[switch]$SpinachDisplayOnly, [switch]$SunflowerDisplayOnly, [switch]$ItemIconsOnly')
text=text.replace("[ValidateSet('chili','fenugreek','spinach')]","[ValidateSet('chili','fenugreek','spinach','sunflower')]")
anchor="function Copy-ReviewedCropDisplay([ValidateSet('chili','fenugreek','spinach','sunflower')][string]$Species) {"
assert text.count(anchor)==1
text=text.replace(anchor,anchor+"\n    if($Species -eq 'sunflower'){\n        & (Join-Path $PSScriptRoot 'audit-sunflower-display.ps1')\n        if($LASTEXITCODE -ne 0){throw 'Sunflower display preflight failed; no files copied.'}\n    }")
text=text.replace('$SpinachDisplayOnly,$ItemIconsOnly)','$SpinachDisplayOnly,$SunflowerDisplayOnly,$ItemIconsOnly)')
text=text.replace("if($SpinachDisplayOnly){Copy-ReviewedCropDisplay 'spinach';exit 0}","if($SpinachDisplayOnly){Copy-ReviewedCropDisplay 'spinach';exit 0}\nif($SunflowerDisplayOnly){Copy-ReviewedCropDisplay 'sunflower';exit 0}")
text=text.replace("Copy-ReviewedCropDisplay 'spinach'\nCopy-ReviewedItemIcons","Copy-ReviewedCropDisplay 'spinach'\nCopy-ReviewedCropDisplay 'sunflower'\nCopy-ReviewedItemIcons")
p.write_text(text,encoding='utf-8-sig')
p=t/'verify.ps1';text=p.read_text(encoding='utf-8-sig');anchor="& (Join-Path $PSScriptRoot 'audit-item-icon-routes.ps1')"
assert text.count(anchor)==1
text=text.replace(anchor,"& (Join-Path $PSScriptRoot 'audit-sunflower-display.ps1')\nif ($LASTEXITCODE -ne 0) { [void]$errors.Add('Sunflower display contracts failed.') }\n\n"+anchor)
p.write_text(text,encoding='utf-8-sig')
write(o/'adoption-manifest.json',{'Resources':paths,'ReviewedDisplayJSONs':files,'ProtectedPNGs':len(textures),'ProtectedGameplayFiles':len(gameplay),'NoPNGChanges':True,'VisualAccepted':False,'RuntimeVerified':False})
print('Published',len(paths),'display JSONs; canonical',len(files),'PNGs',len(textures),'gameplay',len(gameplay))
