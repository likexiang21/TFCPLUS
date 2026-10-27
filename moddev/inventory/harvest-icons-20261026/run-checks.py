from pathlib import Path
import json,subprocess,shutil,os
r=Path.cwd();out=r/'moddev/inventory/harvest-icons-20261026';a=r/'moddev/tfcfarmingplus';tools=a/'tools';c=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8'));results=[]
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
inputs=[x['Path'] for x in c['Routes']]+list(c['ProtectedTextureSha256'])+list(c['FoodDataSha256'])
cases=['valid']+[kind+'-'+n for kind in ['old-route','other-species','missing-art'] for n in ['asparagus','eggplant','okra']]+['b-shadows-art','wrong-food-id','prior-leaf-regression']
for case in cases:
 base=out/'fixtures'/case;dest=base/'moddev/tfcfarmingplus/src/main/resources';dest.mkdir(parents=True,exist_ok=False)
 for rel in inputs:
  target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,target)
 for n,old,other in [('asparagus','barley','eggplant'),('eggplant','wheat','okra'),('okra','oat','asparagus')]:
  p=dest/f'assets/tfcfarmingplus/models/item/food/{n}.json'
  if case in ['old-route-'+n,'other-species-'+n]:
   model=json.loads(p.read_text(encoding='utf-8'));model['textures']['layer0']='tfc:item/food/'+old if case.startswith('old-') else 'tfcfarmingplus:item/food/'+other;p.write_text(json.dumps(model),encoding='utf-8')
  if case=='missing-art-'+n:(dest/f'assets/tfcfarmingplus/textures/item/food/{n}.png').unlink()
 if case=='b-shadows-art':
  rel='assets/tfcfarmingplus/textures/item/food/okra.png';p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(dest/rel,p)
 if case=='wrong-food-id':
  p=dest/'data/tfcfarmingplus/tfc/food/asparagus.json';j=json.loads(p.read_text(encoding='utf-8'));j['ingredient']['item']='tfc:food/barley';p.write_text(json.dumps(j),encoding='utf-8')
 if case=='prior-leaf-regression':
  p=dest/'assets/tfcfarmingplus/models/item/food/arugula.json';j=json.loads(p.read_text(encoding='utf-8'));j['textures']['layer0']='tfc:item/food/beet';p.write_text(json.dumps(j),encoding='utf-8')
 process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 (out/('fixture-'+case+'.log')).write_bytes(process.stdout);passed=(process.returncode==0)==(case=='valid');results.append({'Case':case,'ExitCode':process.returncode,'Passed':passed});assert passed,(case,process.stdout)
draft=r/'moddev/.probe/generator-output/ar4p-item-icons';assert not draft.exists()
process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(out/'draft-item-icons.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
actual=[p for p in draft.rglob('*') if p.is_file()];assert len(actual)==9
assert set(p.relative_to(draft).as_posix() for p in actual)==set(x['Path'] for x in c['Routes'])
assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(draft)).read_bytes() for p in actual)
results.append({'Case':'safe-copy-all-nine','Files':9,'ByteIdentical':True,'Passed':True})
(out/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8');print('Passed',len(results),'checks: 13 fixtures and 9 byte-identical safe-copy files.')
