from pathlib import Path
from PIL import Image
import json, subprocess, shutil, os

root=Path.cwd();out=root/'moddev/inventory/special-food-icons-20261026';a=root/'moddev/tfcfarmingplus';tools=a/'tools'
contract=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8'))
names=['rhubarb','sunflower','agave'];native={'rhubarb':'soybean','sunflower':'barley','agave':'beet'}
files={row['Name']:Path(row['AdoptedSourcePath']).name for row in json.loads((out/'imagegen-asset-manifest.json').read_text(encoding='utf-8'))}
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
inputs=[r['Path'] for r in contract['Routes']]+list(contract['ProtectedTextureSha256'])+list(contract['FoodDataSha256'])+list({row['Path'] for row in contract['GuidePages']})
cases=['valid']+[kind+'-'+name for kind in ['old-fruit','native-fruit','cross-nut','missing-art'] for name in names]+['b-shadow','nutrition','prior-walnut','unprotected-32']
cases += ['old-guide-'+locale+'-'+name for locale in ['zh_cn','en_us'] for name in names]+['duplicate-anchor','missing-guide','b-guide-shadow']+['old-template-'+str(i) for i in range(6)]
results=[]
for case in cases:
    base=out/'fixtures'/case;dest=base/'moddev/tfcfarmingplus/src/main/resources';dest.mkdir(parents=True,exist_ok=False)
    for rel in inputs:
        p=dest/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
    for row in contract['ReviewedTemplateRows']:
        p=base/'moddev/tfcfarmingplus'/row['Path'];p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/row['Path'],p)
    for i,name in enumerate(names):
        if case in [k+'-'+name for k in ['old-fruit','native-fruit','cross-nut']]:
            p=dest/f'assets/tfcfarmingplus/models/item/food/{name}.json';data=json.loads(p.read_text(encoding='utf-8'))
            data['textures']['layer0']=f'tfcfarmingplus:item/food/{name}' if case.startswith('old-fruit') else 'tfc:item/food/'+native[name] if case.startswith('native-fruit') else 'tfcfarmingplus:item/food/'+Path(files[names[(i+1)%len(names)]]).stem
            p.write_text(json.dumps(data),encoding='utf-8')
        if case=='missing-art-'+name:(dest/'assets/tfcfarmingplus/textures/item/food'/files[name]).unlink()
    if case=='b-shadow':
        rel='assets/tfcfarmingplus/textures/item/food/'+files['agave'];p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(dest/rel,p)
    if case=='nutrition':
        p=dest/'data/tfcfarmingplus/tfc/food/agave.json';data=json.loads(p.read_text(encoding='utf-8'));data['water']=4.0;p.write_text(json.dumps(data),encoding='utf-8')
    if case=='prior-walnut':
        p=dest/'assets/tfcfarmingplus/models/item/food/walnut.json';data=json.loads(p.read_text(encoding='utf-8'));data['textures']['layer0']='tfcfarmingplus:item/food/walnut';p.write_text(json.dumps(data),encoding='utf-8')
    if case.startswith('old-guide-'):
        _,_,locale,name=case.split('-');rel=f'assets/tfc/patchouli_books/field_guide/{locale}/entries/farming_plus/crops.json'
        p=dest/rel;data=json.loads(p.read_text(encoding='utf-8'));old=json.loads((root/'moddev/backups/ar4x-special-food-icons-20261026/moddev/tfcfarmingplus/src/main/resources'/rel).read_text(encoding='utf-8'))
        next(x for x in data['pages'] if x.get('anchor')==name)['text']=next(x for x in old['pages'] if x.get('anchor')==name)['text'];p.write_text(json.dumps(data),encoding='utf-8')
    if case in ['duplicate-anchor','missing-guide','b-guide-shadow']:
        rel='assets/tfc/patchouli_books/field_guide/zh_cn/entries/farming_plus/crops.json';p=dest/rel
        if case=='missing-guide':p.unlink()
        elif case=='duplicate-anchor':
            data=json.loads(p.read_text(encoding='utf-8'));data['pages'].append(next(x for x in data['pages'] if x.get('anchor')=='agave'));p.write_text(json.dumps(data),encoding='utf-8')
        else:
            target=base/'moddev/tfcagricultureplus/src/main/resources'/rel;target.parent.mkdir(parents=True);shutil.copy2(p,target)
    if case.startswith('old-template-'):
        row=contract['ReviewedTemplateRows'][int(case.split('-')[-1])];p=base/'moddev/tfcfarmingplus'/row['Path'];old=root/'moddev/backups/ar4x-special-food-icons-20261026/moddev/tfcfarmingplus'/row['Path'];lines=p.read_text(encoding='utf-8-sig').splitlines();oldlines=old.read_text(encoding='utf-8-sig').splitlines();needle="n='"+row['Name']+"';";replace=next(x for x in oldlines if needle in x);lines=[replace if needle in x else x for x in lines];p.write_text('\n'.join(lines)+'\n',encoding='utf-8-sig')
    if case=='unprotected-32':Image.new('RGBA',(32,32),(50,80,25,255)).save(dest/'assets/tfcfarmingplus/textures/item/food/size_fixture.png')
    process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (out/('fixture-'+case+'.log')).write_bytes(process.stdout)
    passed=(process.returncode==0)==(case=='valid');assert passed,(case,process.stdout)
    if case=='unprotected-32':assert b'16x16' in process.stdout and b'32x32' in process.stdout and b'findings: 1' in process.stdout
    results.append({'Case':case,'ExitCode':process.returncode,'Passed':True})
draft=root/'moddev/.probe/generator-output/ar4x-item-icons';assert not draft.exists()
process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(out/'draft-item-icons.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
actual=[p for p in draft.rglob('*') if p.is_file()]
assert len(actual)==43 and {p.relative_to(draft).as_posix() for p in actual}=={r['Path'] for r in contract['Routes']}
assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(draft)).read_bytes() for p in actual)
results.append({'Case':'safe-copy-fortythree-json-only','Files':43,'ByteIdentical':True,'Passed':True})
(out/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
print('Passed',len(results),'checks:',len(cases),'fixtures, plus 43 byte-identical safe-copy JSONs.')
