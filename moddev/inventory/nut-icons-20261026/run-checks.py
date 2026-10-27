from pathlib import Path
from PIL import Image
import json, subprocess, shutil, os

root=Path.cwd();out=root/'moddev/inventory/nut-icons-20261026';a=root/'moddev/tfcfarmingplus';tools=a/'tools'
contract=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8'))
names=['almond','hazelnut','macadamia','pecan','walnut'];native={'almond':'peach','hazelnut':'cherry','macadamia':'lemon','pecan':'orange','walnut':'green_apple'}
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
inputs=[r['Path'] for r in contract['Routes']]+list(contract['ProtectedTextureSha256'])+list(contract['FoodDataSha256'])
cases=['valid']+[kind+'-'+name for kind in ['old-fruit','native-fruit','cross-nut','missing-art'] for name in names]+['b-shadow','nutrition','prior-water-shield','unprotected-32']
results=[]
for case in cases:
    base=out/'fixtures'/case;dest=base/'moddev/tfcfarmingplus/src/main/resources';dest.mkdir(parents=True,exist_ok=False)
    for rel in inputs:
        p=dest/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
    for i,name in enumerate(names):
        if case in [k+'-'+name for k in ['old-fruit','native-fruit','cross-nut']]:
            p=dest/f'assets/tfcfarmingplus/models/item/food/{name}.json';data=json.loads(p.read_text(encoding='utf-8'))
            data['textures']['layer0']=f'tfcfarmingplus:item/food/{name}' if case.startswith('old-fruit') else 'tfc:item/food/'+native[name] if case.startswith('native-fruit') else f'tfcfarmingplus:item/food/{names[(i+1)%len(names)]}_harvest_v1'
            p.write_text(json.dumps(data),encoding='utf-8')
        if case=='missing-art-'+name:(dest/f'assets/tfcfarmingplus/textures/item/food/{name}_harvest_v1.png').unlink()
    if case=='b-shadow':
        rel='assets/tfcfarmingplus/textures/item/food/walnut_harvest_v1.png';p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(dest/rel,p)
    if case=='nutrition':
        p=dest/'data/tfcfarmingplus/tfc/food/almond.json';data=json.loads(p.read_text(encoding='utf-8'));data['protein']=2.5;p.write_text(json.dumps(data),encoding='utf-8')
    if case=='prior-water-shield':
        p=dest/'assets/tfcfarmingplus/models/item/food/water_shield.json';data=json.loads(p.read_text(encoding='utf-8'));data['textures']['layer0']='tfc:item/food/rice';p.write_text(json.dumps(data),encoding='utf-8')
    if case=='unprotected-32':Image.new('RGBA',(32,32),(50,80,25,255)).save(dest/'assets/tfcfarmingplus/textures/item/food/size_fixture.png')
    process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (out/('fixture-'+case+'.log')).write_bytes(process.stdout)
    passed=(process.returncode==0)==(case=='valid');assert passed,(case,process.stdout)
    if case=='unprotected-32':assert b'16x16' in process.stdout and b'32x32' in process.stdout and b'findings: 1' in process.stdout
    results.append({'Case':case,'ExitCode':process.returncode,'Passed':True})
draft=root/'moddev/.probe/generator-output/ar4w-item-icons';assert not draft.exists()
process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(out/'draft-item-icons.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
actual=[p for p in draft.rglob('*') if p.is_file()]
assert len(actual)==40 and {p.relative_to(draft).as_posix() for p in actual}=={r['Path'] for r in contract['Routes']}
assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(draft)).read_bytes() for p in actual)
results.append({'Case':'safe-copy-forty-json-only','Files':40,'ByteIdentical':True,'Passed':True})
(out/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
print('Passed',len(results),'checks:',len(cases),'fixtures, plus 40 byte-identical safe-copy JSONs.')
