from pathlib import Path
import json,os,shutil,subprocess
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent
a=r/'moddev/tfcfarmingplus';t=a/'tools';s=a/'src/main/resources'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,v):p.write_text(json.dumps(v),encoding='utf-8')
c=load(t/'sunflower-display-contract.json')
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
cases=['valid','borrowed-mature','missing-head','head-occlusion','third-part','dead-maize','wild-barley','wild-grass-override','planter-barley','planter-reward','missing-flower-png','changed-unused-art','old-food-icon','seed-route','b-shadow','java-age','invalid-rotation','degenerate-face']
results=[]
for i,case in enumerate(cases):
    base=o/'fixtures'/str(i);module=base/'moddev/tfcfarmingplus';res=module/'src/main/resources';res.mkdir(parents=True,exist_ok=False)
    for rel in list(c['ReviewedJsonSha256'])+list(c['ProtectedTextureSha256']):
        dest=res/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(s/rel,dest)
    for rel in c['ProtectedGameplaySha256']:
        dest=module/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/rel,dest)
    top=res/'assets/tfcfarmingplus/models/block/crop/sunflower_age_5_top.json'
    value=load(top)
    if case=='borrowed-mature':value={'parent':'block/crop','textures':{'crop':'tfc:block/crop/sugarcane_5_top'}};write(top,value)
    if case=='missing-head':value['elements'].pop();write(top,value)
    if case=='head-occlusion':value['elements'][0]['to'][1]=16;write(top,value)
    if case=='invalid-rotation':value['elements'][0]['rotation']={'origin':[8,8,8],'axis':'y','angle':15};write(top,value)
    if case=='degenerate-face':value['elements'][0]['faces']={'up':{'uv':[0,0,16,16],'texture':'#crop'}};write(top,value)
    if case=='third-part':
        p=res/'assets/tfcfarmingplus/blockstates/crop/sunflower.json';v=load(p);v['variants']['age=5,part=top_2']={'model':'tfcfarmingplus:block/crop/sunflower_age_5_top'};write(p,v)
    if case=='dead-maize':
        p=res/'assets/tfcfarmingplus/blockstates/dead_crop/sunflower.json';v=load(p);v['variants']['mature=true,part=top']['model']='tfc:block/dead_crop/maize_top';write(p,v)
    if case in ['wild-barley','wild-grass-override']:
        p=res/'assets/tfcfarmingplus/models/block/wild_crop/sunflower.json';v=load(p)
        if case=='wild-barley':v['textures']['crop']='tfc:block/crop/barley_wild'
        else:v['textures']['1']='tfcfarmingplus:block/wild_crop/sunflower'
        write(p,v)
    if case in ['planter-barley','planter-reward']:
        p=res/'data/firmalife/firmalife/plantable/sunflower.json';v=load(p)
        if case=='planter-barley':v['textures'][-1]='tfc:block/crop/barley_5'
        else:v['crop']['count']=64
        write(p,v)
    if case=='missing-flower-png':(res/'assets/tfcfarmingplus/textures/block/crop/sunflower_age_5_top_2.png').unlink()
    if case=='changed-unused-art':
        p=res/'assets/tfcfarmingplus/textures/block/crop/sunflower_age_3_top_2.png';p.write_bytes(p.read_bytes()+b'changed')
    if case in ['old-food-icon','seed-route']:
        kind='food' if case=='old-food-icon' else 'seeds';p=res/f'assets/tfcfarmingplus/models/item/{kind}/sunflower.json';v=load(p);v['textures']['layer0']='tfcfarmingplus:item/'+kind+'/sunflower';write(p,v)
    if case=='b-shadow':
        rel='assets/tfcfarmingplus/models/block/crop/sunflower_age_5_top.json';p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(res/rel,p)
    if case=='java-age':
        p=module/'src/main/java/com/example/tfcfarmingplus/common/MyCrops.java';text=p.read_text(encoding='utf-8');assert 'dbl("sunflower", 3, 5,' in text;p.write_text(text.replace('dbl("sunflower", 3, 5,','dbl("sunflower", 4, 5,'),encoding='utf-8')
    process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(t/'audit-sunflower-display.ps1'),'-SourceInstance',str(base)],env=env,cwd=r,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (o/f'fixture-{i}-{case}.log').write_bytes(process.stdout)
    assert (process.returncode==0)==(case=='valid'),(case,process.stdout)
    results.append({'Case':case,'ExitCode':process.returncode,'Passed':True})
for switch,slug,filelist in [('SunflowerDisplayOnly','sunflower',load(t/'sunflower-display-files.json')),('SpinachDisplayOnly','spinach',load(t/'spinach-display-files.json')),('ItemIconsOnly','icons',[v['Path'] for v in load(t/'reviewed-item-icon-routes.json')['Routes']])]:
    dest=r/f'moddev/.probe/generator-output/ar4aa-{slug}';assert not dest.exists()
    process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(t/'gen-crops.ps1'),'-Root',str(dest),'-'+switch],env=env,cwd=r,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (o/f'safe-{slug}.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
    files=[p for p in dest.rglob('*') if p.is_file()]
    assert {p.relative_to(dest).as_posix() for p in files}==set(filelist)
    assert all(p.read_bytes()==(s/p.relative_to(dest)).read_bytes() for p in files)
    results.append({'Case':'safe-'+slug,'Files':len(files),'ByteIdentical':True,'Passed':True})
(o/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
print('Passed',len(results),'checks: 18 fixtures + safe 21/17/44 JSON copies.')
