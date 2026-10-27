from pathlib import Path
import json,subprocess,shutil,os
r=Path.cwd();out=r/'moddev/inventory/leaf-stem-icons-20261026';a=r/'moddev/tfcfarmingplus';tools=a/'tools';c=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8'));results=[]
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
inputs=[x['Path'] for x in c['Routes']]+list(c['ProtectedTextureSha256'])+list(c['FoodDataSha256']);names=['lettuce','celery','celtuce','garland_chrysanthemum','perilla','purslane']
cases=['valid']+[k+'-'+n for k in ['old-donor','wrong-stored'] for n in names]+['missing-celery-new','missing-celtuce-new','new-art-changed','b-shadows-new-art','wrong-food-id','prior-asparagus-regression']
for case in cases:
 base=out/'fixtures-v2'/case;dest=base/'moddev/tfcfarmingplus/src/main/resources';dest.mkdir(parents=True,exist_ok=False)
 for rel in inputs:
  p=dest/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
 for n in names:
  if case in ['old-donor-'+n,'wrong-stored-'+n]:
   p=dest/f'assets/tfcfarmingplus/models/item/food/{n}.json';j=json.loads(p.read_text(encoding='utf-8'));j['textures']['layer0']=('tfc:item/food/'+('onion' if n in names[:3] else 'beet')) if case.startswith('old-donor') else 'tfcfarmingplus:item/food/'+n;p.write_text(json.dumps(j),encoding='utf-8')
 for n,filename in [('celery','celery_stalks_v1'),('celtuce','celtuce_stem_v1')]:
  if case=='missing-'+n+'-new':(dest/f'assets/tfcfarmingplus/textures/item/food/{filename}.png').unlink()
 rel='assets/tfcfarmingplus/textures/item/food/celery_stalks_v1.png'
 if case=='new-art-changed':
  p=dest/rel;p.write_bytes(p.read_bytes()+b'fixture')
 if case=='b-shadows-new-art':
  p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(dest/rel,p)
 if case=='wrong-food-id':
  p=dest/'data/tfcfarmingplus/tfc/food/celtuce.json';j=json.loads(p.read_text(encoding='utf-8'));j['ingredient']['item']='tfc:food/onion';p.write_text(json.dumps(j),encoding='utf-8')
 if case=='prior-asparagus-regression':
  p=dest/'assets/tfcfarmingplus/models/item/food/asparagus.json';j=json.loads(p.read_text(encoding='utf-8'));j['textures']['layer0']='tfc:item/food/barley';p.write_text(json.dumps(j),encoding='utf-8')
 process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 (out/('fixture-'+case+'.log')).write_bytes(process.stdout);ok=(process.returncode==0)==(case=='valid');results.append({'Case':case,'ExitCode':process.returncode,'Passed':ok});assert ok,(case,process.stdout)
draft=r/'moddev/.probe/generator-output/ar4q-item-icons';assert not draft.exists()
process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/'draft-item-icons.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
actual=[p for p in draft.rglob('*') if p.is_file()];assert len(actual)==15
assert set(p.relative_to(draft).as_posix() for p in actual)==set(x['Path'] for x in c['Routes'])
assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(draft)).read_bytes() for p in actual)
results.append({'Case':'safe-copy-fifteen-json-only','Files':15,'ByteIdentical':True,'Passed':True})
(out/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8');print('Passed',len(results),'checks:',len(cases),'fixtures and fifteen byte-identical safe-copy model JSONs.')
