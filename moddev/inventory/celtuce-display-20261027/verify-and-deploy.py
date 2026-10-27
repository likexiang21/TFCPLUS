from pathlib import Path
from hashlib import sha256
from zipfile import ZipFile
from PIL import Image
from io import BytesIO
import json,shutil
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent
b=r/'moddev/backups/ar4af-celtuce-display-20261027'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(name,value):(o/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert 'BUILD SUCCESSFUL' in (o/'build-a.log').read_text(encoding='utf-8-sig')
assert all(row['Passed'] for row in load(o/'check-results.json'))
assert '结果: 全部交叉引用有效，未发现问题' in (o/'verify.log').read_text(encoding='utf-8-sig')
assert '[OK]' in (o/'ledger.log').read_text(encoding='utf-8-sig')
expected=load(o/'candidate-paths.json');src=r/'moddev/tfcfarmingplus/src/main/resources'
manifest=load(b/'backup-manifest.json')
oldmap={row['path']:row['sha256'] for row in manifest}
changed=[];added=[];removed=[]
for module in ['tfcfarmingplus','tfcagricultureplus']:
    for folder in ['src','tools']:
        prefix=f'moddev/{module}/{folder}/'
        paths={p.relative_to(r).as_posix():p for p in (r/f'moddev/{module}/{folder}').rglob('*') if p.is_file()}
        previous={key:value for key,value in oldmap.items() if key.startswith(prefix)}
        changed.extend(key for key in previous.keys() & paths.keys() if digest(paths[key])!=previous[key])
        added.extend(paths.keys()-previous.keys());removed.extend(previous.keys()-paths.keys())
resource_changes={f'moddev/tfcfarmingplus/src/main/resources/{key}' for key in expected}
tool_changes={f'moddev/tfcfarmingplus/tools/{name}' for name in ['gen-crops.ps1','verify.ps1','audit-celtuce-display.ps1','celtuce-display-contract.json','celtuce-display-files.json']}
assert set(changed+added)==resource_changes|tool_changes,(changed,added)
assert not removed
save('source-diff.json',{'Modified':sorted(changed),'Added':sorted(added),'Removed':removed,'AllOtherABSourceAndToolsUnchanged':True})
name='TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar';built=r/'moddev/tfcfarmingplus/build/libs'/name
with ZipFile(built) as new,ZipFile(b/'moddev/tfcfarmingplus/build/libs'/name) as old:
    now=set(new.namelist());before=set(old.namelist())
    diff={'Modified':sorted(key for key in now&before if new.read(key)!=old.read(key)),'Added':sorted(now-before),'Removed':sorted(before-now)}
    expected_modified=sorted(key for key in expected if (b/'moddev/tfcfarmingplus/src/main/resources'/key).exists())
    expected_added=sorted(set(expected)-set(expected_modified))
    assert diff=={'Modified':expected_modified,'Added':expected_added,'Removed':[]},diff
    for key in expected:assert new.read(key)==(src/key).read_bytes()
    for key in expected_added:
        if key.endswith('.png'):
            with Image.open(BytesIO(new.read(key))) as im:assert im.size==(16,16),key
    assert not any('preview-64' in key or 'pixel-source-16' in key or 'candidate-' in key for key in now)
    assert all(new.read(key)==old.read(key) for key in before if key.endswith('.png'))
    images=sorted(key for key in now if key.startswith(('assets/tfcfarmingplus/textures/item/food/','assets/tfcfarmingplus/textures/item/seeds/')) and key.endswith('.png'))
    assert len(images)==263
    for key in images:
        with Image.open(BytesIO(new.read(key))) as im:assert im.size==(16,16),key
save('jar-entry-diff.json',diff)
assert 'assets/tfcfarmingplus/textures.zip' not in now
assert digest(r/'moddev/tfcfarmingplus/build.gradle.kts')==oldmap['moddev/tfcfarmingplus/build.gradle.kts']
checks=load(o/'check-results.json');checks.append({'Case':'source-archive-excluded-build-config-protected','Passed':True});save('check-results.json',checks)
preflight=[]
for filename in [name,'TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar']:
    for directory,old_directory in [(r/'mods',b/'mods'),(Path('D:/TFC农业重置/PCL_TFC/mods'),b/'pcl-mods')]:
        path=directory/filename;expected_hash=digest(old_directory/filename)
        assert digest(path)==expected_hash,('Installed package changed since backup',path)
        preflight.append({'Path':str(path),'SHA256':expected_hash,'MatchedBackup':True})
for directory in [r/'mods',Path('D:/TFC农业重置/PCL_TFC/mods')]:shutil.copy2(built,directory/name)
packages=[]
for module,filename in [('tfcfarmingplus',name),('tfcagricultureplus','TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar')]:
    paths=[r/'moddev'/module/'build/libs'/filename,r/'mods'/filename,Path('D:/TFC农业重置/PCL_TFC/mods')/filename]
    value=digest(paths[0]);assert all(digest(p)==value for p in paths)
    if module=='tfcagricultureplus':assert value=='EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3'
    packages.append({'Module':module,'SHA256':value,'Files':[str(p) for p in paths]})
save('delivery-manifest.json',{'Preflight':preflight,'PackagedFoodSeedPNGsChecked':263,'AllItemPNGs16x16':True,'AllOldPackagedPNGsUnchanged':True,'Packages':packages,'VisualAccepted':False,'RuntimeVerified':False})
print(json.dumps({'JarModified':len(diff['Modified']),'JarAdded':len(diff['Added']),'JarRemoved':0,'Packages':packages},ensure_ascii=False))
