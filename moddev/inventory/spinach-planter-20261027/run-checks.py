from pathlib import Path
import json,os,subprocess,shutil
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;a=r/'moddev/tfcfarmingplus';t=a/'tools';s=a/'src/main/resources'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v),encoding='utf-8')
c=load(t/'spinach-display-contract.json');files=load(t/'spinach-display-files.json');env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
cases=['valid','repeat','white-flower','all-six-mature','missing-new','changed-new','changed-old','b-shadow','reward','crop-clip','food-route','seed-route']
results=[]
for index,case in enumerate(cases):
    base=o/'fixtures'/str(index);res=base/'moddev/tfcfarmingplus/src/main/resources';res.mkdir(parents=True,exist_ok=False)
    for rel in files+list(c['ProtectedTextureSha256']):
        dest=res/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(s/rel,dest)
    p=res/'data/firmalife/firmalife/plantable/spinach.json';v=load(p)
    if case=='repeat':v['textures'][-1]=v['textures'][-2];save(p,v)
    if case=='white-flower':v['textures'][-1]='tfcfarmingplus:block/crop/spinach_age_5';save(p,v)
    if case=='all-six-mature':v['textures']=[v['textures'][-1]]*6;save(p,v)
    if case=='reward':v['crop']['count']=2;save(p,v)
    new='assets/tfcfarmingplus/textures/block/crop/spinach_planter_mature_v1.png'
    if case=='missing-new':(res/new).unlink()
    if case in ['changed-new','changed-old']:
        p=res/(new if case=='changed-new' else 'assets/tfcfarmingplus/textures/block/crop/spinach_age_4.png');p.write_bytes(p.read_bytes()+b'changed')
    if case=='b-shadow':
        p=base/'moddev/tfcagricultureplus/src/main/resources'/new;p.parent.mkdir(parents=True);shutil.copy2(res/new,p)
    if case=='crop-clip':
        p=res/'assets/tfcfarmingplus/models/block/crop/spinach_age_5.json';v=load(p);v.pop('elements');save(p,v)
    if case in ['food-route','seed-route']:
        kind='food' if case=='food-route' else 'seeds';p=res/f'assets/tfcfarmingplus/models/item/{kind}/spinach.json';v=load(p);v['textures']['layer0']=f'tfcfarmingplus:item/{kind}/spinach';save(p,v)
    process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(t/'audit-spinach-display.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (o/f'fixture-{index}-{case}.log').write_bytes(process.stdout);assert (process.returncode==0)==(case=='valid'),(case,process.stdout)
    results.append({'Case':case,'ExitCode':process.returncode,'Passed':True})
for flag,slug,paths in [('SpinachDisplayOnly','spinach',files),('SunflowerDisplayOnly','sunflower',load(t/'sunflower-display-files.json')),('ItemIconsOnly','icons',[v['Path'] for v in load(t/'reviewed-item-icon-routes.json')['Routes']])]:
    dest=r/f'moddev/.probe/generator-output/ar4ab-{slug}';assert not dest.exists()
    process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(t/'gen-crops.ps1'),'-Root',str(dest),'-'+flag],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (o/f'safe-{slug}.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
    actual=[p for p in dest.rglob('*') if p.is_file()];assert {p.relative_to(dest).as_posix() for p in actual}==set(paths);assert all(p.read_bytes()==(s/p.relative_to(dest)).read_bytes() for p in actual)
    results.append({'Case':'safe-'+slug,'Files':len(actual),'ByteIdentical':True,'Passed':True})
(o/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8');print('Passed',len(results),'checks: 12 fixtures and 17/21/44 JSON copies.')
