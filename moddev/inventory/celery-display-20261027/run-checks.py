from pathlib import Path
from PIL import Image
import json,os,shutil,subprocess
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;a=r/'moddev/tfcfarmingplus';s=a/'src/main/resources';t=a/'tools'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v),encoding='utf-8')
c=load(t/'celery-display-contract.json');env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules');results=[]
cases=['valid','root-model','missing-new','new64','extra64','old-art','wild-young','no-grass-parent','grass-override','b-shadow','native-b-shadow','loot','planter-repeat','java-age','empty-geometry','degenerate-face']
for i,case in enumerate(cases):
 base=o/'fixtures'/str(i);module=base/'moddev/tfcfarmingplus';res=module/'src/main/resources';res.mkdir(parents=True,exist_ok=False)
 for rel in list(c['ReviewedJsonSha256'])+list(c['ProtectedTextureSha256']):
  dest=res/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(s/rel,dest)
 for rel in c['ProtectedGameplaySha256']:
  dest=module/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/rel,dest)
 mature=res/'assets/tfcfarmingplus/models/block/crop/celery_age_5.json';v=load(mature)
 if case=='root-model':v['textures']['crop']='tfc:block/crop/onion_5';save(mature,v)
 if case=='empty-geometry':v['elements']=[];save(mature,v)
 if case=='degenerate-face':v['elements'][0]['faces']={'up':{'uv':[0,0,16,16],'texture':'#crop'}};save(mature,v)
 png='assets/tfcfarmingplus/textures/block/crop/celery_age_5_stalks_v1.png'
 if case=='missing-new':(res/png).unlink()
 if case=='new64':Image.new('RGBA',(64,64),(60,90,40,255)).save(res/png)
 if case=='extra64':Image.new('RGBA',(64,64),(60,90,40,255)).save(res/'assets/tfcfarmingplus/textures/block/crop/unprotected_preview.png')
 if case=='old-art':
  p=res/'assets/tfcfarmingplus/textures/block/crop/celery_age_5.png';p.write_bytes(p.read_bytes()+b'changed')
 if case=='wild-young':
  p=res/'assets/tfcfarmingplus/blockstates/wild_crop/celery.json';v=load(p);v['variants']['mature=false']['model']='tfc:block/dead_crop/onion_young';save(p,v)
 if case in ['no-grass-parent','grass-override']:
  p=res/'assets/tfcfarmingplus/models/block/wild_crop/celery.json';v=load(p)
  if case=='no-grass-parent':v['parent']='minecraft:block/crop'
  else:v['textures']['1']='tfcfarmingplus:block/crop/celery_age_5_stalks_v1'
  save(p,v)
 if case in ['b-shadow','native-b-shadow']:
  rel='assets/tfcfarmingplus/models/block/crop/celery_age_5.json' if case=='b-shadow' else 'assets/tfc/models/block/wild_crop/crop.json';p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);p.write_text('{}',encoding='utf-8')
 if case=='loot':
  p=res/'data/tfcfarmingplus/loot_table/blocks/crop/celery.json';v=load(p);v['pools']=[];save(p,v)
 if case=='planter-repeat':
  p=res/'data/firmalife/firmalife/plantable/celery.json';v=load(p);v['textures'][-1]=v['textures'][-2];save(p,v)
 if case=='java-age':
  p=module/'src/main/java/com/example/tfcfarmingplus/common/MyCrops.java';text=p.read_text(encoding='utf-8');assert 'crop("celery", 5,' in text;p.write_text(text.replace('crop("celery", 5,','crop("celery", 4,'),encoding='utf-8')
 process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(t/'audit-celery-display.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(o/f'fixture-{i}-{case}.log').write_bytes(process.stdout);assert (process.returncode==0)==(case=='valid'),(case,process.stdout);results.append({'Case':case,'ExitCode':process.returncode,'Passed':True})
for flag,slug,files in [('CeleryDisplayOnly','celery',load(t/'celery-display-files.json')),('SwissChardDisplayOnly','swiss',load(t/'swiss_chard-display-files.json')),('SunflowerDisplayOnly','sunflower',load(t/'sunflower-display-files.json')),('SpinachDisplayOnly','spinach',load(t/'spinach-display-files.json')),('ItemIconsOnly','icons',[v['Path'] for v in load(t/'reviewed-item-icon-routes.json')['Routes']])]:
 dest=r/f'moddev/.probe/generator-output/ar4ae-{slug}';assert not dest.exists();process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(t/'gen-crops.ps1'),'-Root',str(dest),'-'+flag],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(o/f'safe-{slug}.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
 actual=[p for p in dest.rglob('*') if p.is_file()];assert {p.relative_to(dest).as_posix() for p in actual}==set(files);assert all(p.read_bytes()==(s/p.relative_to(dest)).read_bytes() for p in actual);results.append({'Case':'safe-'+slug,'Files':len(actual),'ByteIdentical':True,'Passed':True})
for row in load(o/'asset-manifest.json')['Assets']:
 lines=Path(row['EditableSource']).read_text(encoding='utf-8').splitlines();grid=[x for x in lines if len(x)==16 and '=' not in x];assert len(grid)==16
 with Image.open(row['FinalPath']) as original,Image.open(row['Preview64']) as preview:
  assert original.size==(16,16) and preview.size==(64,64);assert preview.tobytes()==original.resize((64,64),Image.Resampling.NEAREST).tobytes()
results.append({'Case':'eight-base16-and-preview64','Assets':8,'Passed':True});save(o/'check-results.json',results);print('Passed',len(results),'checks; 16 fixtures, 5 safe copies, native16/preview64 verification.')
