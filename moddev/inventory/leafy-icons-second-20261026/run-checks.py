from pathlib import Path
from PIL import Image
import json,shutil,subprocess,os
r=Path.cwd();o=r/'moddev/inventory/leafy-icons-second-20261026';a=r/'moddev/tfcfarmingplus';tools=a/'tools'
c=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8'));names=['lettuce','spinach','swiss_chard','purslane']
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
inputs=[x['Path'] for x in c['Routes']]+list(c['ProtectedTextureSha256'])+list(c['FoodDataSha256'])+list({x['Path'] for x in c['GuidePages']})
cases=['valid']+[kind+'-'+n for kind in ['shared','stored','cross','missing'] for n in names]+['b-shadow','nutrition','prior-rhubarb','unprotected-32','prior-guide','prior-template'];results=[]
for case in cases:
    base=o/'fixtures'/case;res=base/'moddev/tfcfarmingplus/src/main/resources';res.mkdir(parents=True,exist_ok=False)
    for rel in inputs:
        p=res/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
    for row in c['ReviewedTemplateRows']:
        p=base/'moddev/tfcfarmingplus'/row['Path'];p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/row['Path'],p)
    for i,n in enumerate(names):
        if case in [kind+'-'+n for kind in ['shared','stored','cross']]:
            p=res/f'assets/tfcfarmingplus/models/item/food/{n}.json';doc=json.loads(p.read_text(encoding='utf-8'))
            doc['textures']['layer0']='tfcfarmingplus:item/food/kale' if case.startswith('shared') else f'tfcfarmingplus:item/food/{n}' if case.startswith('stored') else f'tfcfarmingplus:item/food/{names[(i+1)%4]}_harvest_v1';p.write_text(json.dumps(doc),encoding='utf-8')
        if case=='missing-'+n:(res/f'assets/tfcfarmingplus/textures/item/food/{n}_harvest_v1.png').unlink()
    if case=='b-shadow':
        rel='assets/tfcfarmingplus/textures/item/food/perilla_harvest_v1.png';p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(res/rel,p)
    if case=='nutrition':
        p=res/'data/tfcfarmingplus/tfc/food/lettuce.json';doc=json.loads(p.read_text(encoding='utf-8'));doc['water']=6;p.write_text(json.dumps(doc),encoding='utf-8')
    if case=='prior-rhubarb':
        p=res/'assets/tfcfarmingplus/models/item/food/rhubarb.json';doc=json.loads(p.read_text(encoding='utf-8'));doc['textures']['layer0']='tfc:item/food/soybean';p.write_text(json.dumps(doc),encoding='utf-8')
    if case=='unprotected-32':Image.new('RGBA',(32,32),(70,90,40,255)).save(res/'assets/tfcfarmingplus/textures/item/food/size_fixture.png')
    if case=='prior-guide':
        g=c['GuidePages'][0];p=res/g['Path'];doc=json.loads(p.read_text(encoding='utf-8'));next(v for v in doc['pages'] if v.get('anchor')==g['Name'])['text']+=' Unreviewed recipe claim.';p.write_text(json.dumps(doc),encoding='utf-8')
    if case=='prior-template':
        g=c['ReviewedTemplateRows'][0];p=base/'moddev/tfcfarmingplus'/g['Path'];lines=p.read_text(encoding='utf-8-sig').splitlines();needle="n='"+g['Name']+"';";lines=[line.replace('zhProductNote=','removedProductNote=') if needle in line else line for line in lines];p.write_text('\n'.join(lines)+'\n',encoding='utf-8-sig')
    p=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (o/('fixture-'+case+'.log')).write_bytes(p.stdout);assert (p.returncode==0)==(case=='valid'),(case,p.stdout)
    if case=='unprotected-32':assert b'findings: 1' in p.stdout and b'32x32' in p.stdout and b'16x16' in p.stdout
    results.append({'Case':case,'ExitCode':p.returncode,'Passed':True})
draft=r/'moddev/.probe/generator-output/ar4z-item-icons';assert not draft.exists()
p=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(o/'draft-item-icons.log').write_bytes(p.stdout);assert p.returncode==0,p.stdout
files=[p for p in draft.rglob('*') if p.is_file()];assert len(files)==44 and {p.relative_to(draft).as_posix() for p in files}=={v['Path'] for v in c['Routes']};assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(draft)).read_bytes() for p in files)
results.append({'Case':'safe-copy-fortyfour-json-only','Files':44,'ByteIdentical':True,'Passed':True});(o/'check-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
sc=json.loads((tools/'spinach-display-contract.json').read_text(encoding='utf-8'));sf=json.loads((tools/'spinach-display-files.json').read_text(encoding='utf-8'))
for case in ['valid','old-food','missing-food-art','planter-drift']:
    base=o/'spinach-fixtures'/case;res=base/'moddev/tfcfarmingplus/src/main/resources';res.mkdir(parents=True,exist_ok=False)
    for rel in sf+list(sc['ProtectedTextureSha256']):
        p=res/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
    if case=='old-food':
        p=res/'assets/tfcfarmingplus/models/item/food/spinach.json';doc=json.loads(p.read_text(encoding='utf-8'));doc['textures']['layer0']='tfcfarmingplus:item/food/kale';p.write_text(json.dumps(doc),encoding='utf-8')
    if case=='missing-food-art':(res/'assets/tfcfarmingplus/textures/item/food/spinach_harvest_v1.png').unlink()
    if case=='planter-drift':
        p=res/'data/firmalife/firmalife/plantable/spinach.json';doc=json.loads(p.read_text(encoding='utf-8'));doc['textures'][-1]='tfcfarmingplus:block/crop/spinach_age_5';p.write_text(json.dumps(doc),encoding='utf-8')
    p=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-spinach-display.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(o/('spinach-'+case+'.log')).write_bytes(p.stdout);assert (p.returncode==0)==(case=='valid'),(case,p.stdout)
    results.append({'Case':'spinach-'+case,'ExitCode':p.returncode,'Passed':True})
spinach_draft=r/'moddev/.probe/generator-output/ar4z-spinach-display';assert not spinach_draft.exists()
p=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(spinach_draft),'-SpinachDisplayOnly'],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(o/'draft-spinach-display.log').write_bytes(p.stdout);assert p.returncode==0,p.stdout
files=[p for p in spinach_draft.rglob('*') if p.is_file()];assert len(files)==17 and {p.relative_to(spinach_draft).as_posix() for p in files}==set(sf);assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(spinach_draft)).read_bytes() for p in files)
results.append({'Case':'safe-copy-spinach-seventeen-json-only','Files':17,'ByteIdentical':True,'Passed':True});(o/'check-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print('Passed',len(results),'checks; 44 icon JSONs and 17 spinach display JSONs copied byte-identically.')
