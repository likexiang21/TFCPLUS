from pathlib import Path
from hashlib import sha256
from zipfile import ZipFile
from io import BytesIO
from PIL import Image
import json, shutil

root=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out=Path(__file__).resolve().parent;bak=root/'moddev/backups/ar4x-special-food-icons-20261026'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(name,data):(out/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert 'BUILD SUCCESSFUL' in (out/'build-a.log').read_text(encoding='utf-8-sig')
assert all(r['Passed'] for r in load(out/'check-results.json'))
assert load(out/'book-draft-comparison.json')['PassedForSixReviewedPages'] is True
name='TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar';built=root/'moddev/tfcfarmingplus/build/libs'/name;previous=bak/'moddev/tfcfarmingplus/build/libs'/name
with ZipFile(built) as new,ZipFile(previous) as old:
    now=set(new.namelist());before=set(old.namelist())
    diff={'Modified':sorted(n for n in now&before if new.read(n)!=old.read(n)),'Added':sorted(now-before),'Removed':sorted(before-now)}
    targets=['rhubarb','sunflower','agave']
    art=load(out/'imagegen-asset-manifest.json')
    guides=sorted({g['Path'] for g in load(root/'moddev/tfcfarmingplus/tools/reviewed-item-icon-routes.json')['GuidePages']})
    assert diff['Modified']==sorted([f'assets/tfcfarmingplus/models/item/food/{n}.json' for n in targets]+guides),diff
    assert diff['Added']==sorted(Path(row['AdoptedSourcePath']).relative_to(root/'moddev/tfcfarmingplus/src/main/resources').as_posix() for row in art) and not diff['Removed'],diff
    for key in diff['Modified']+diff['Added']:assert new.read(key)==(root/'moddev/tfcfarmingplus/src/main/resources'/key).read_bytes()
    images=[key for key in now if key.startswith(('assets/tfcfarmingplus/textures/item/food/','assets/tfcfarmingplus/textures/item/seeds/')) and key.endswith('.png')]
    assert len(images)==255
    for key in images:
        with Image.open(BytesIO(new.read(key))) as im:assert im.size==(16,16),key
    for n in targets:
        key=f'assets/tfcfarmingplus/textures/item/food/{n}.png';assert new.read(key)==old.read(key)
save('jar-entry-diff.json',diff)
preflight=[]
for filename in [name,'TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar']:
    for directory,old_directory in [(root/'mods',bak/'mods'),(Path(r'D:\TFC农业重置\PCL_TFC\mods'),bak/'pcl-mods')]:
        path=directory/filename;expected=digest(old_directory/filename)
        assert digest(path)==expected,('Installed package changed since backup',path)
        preflight.append({'Path':str(path),'SHA256':expected,'MatchedBackup':True})
for directory in [root/'mods',Path(r'D:\TFC农业重置\PCL_TFC\mods')]:shutil.copy2(built,directory/name)
packages=[]
for module,filename in [('tfcfarmingplus',name),('tfcagricultureplus','TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar')]:
    paths=[root/'moddev'/module/'build/libs'/filename,root/'mods'/filename,Path(r'D:\TFC农业重置\PCL_TFC\mods')/filename]
    expected=digest(paths[0]);assert all(digest(p)==expected for p in paths)
    if module=='tfcagricultureplus':assert expected=='EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3'
    packages.append({'Module':module,'SHA256':expected,'Files':[str(p) for p in paths]})
save('delivery-manifest.json',{'Preflight':preflight,'PackagedFoodSeedPNGsChecked':255,'AllItemPNGs16x16':True,'Packages':packages})
print(json.dumps({'JarModified':5,'JarAdded':3,'JarRemoved':0,'PackagedFoodSeedPNGs16x16':255,'Packages':packages},ensure_ascii=False))
