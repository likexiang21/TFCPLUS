from pathlib import Path
import json,subprocess,shutil,os
from PIL import Image
r=Path.cwd();out=r/'moddev/inventory/bean-icons-20261026';a=r/'moddev/tfcfarmingplus';tools=a/'tools';c=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8'));names=['common_bean','cowpea','pea','winged_bean'];files={x['Name']:Path(x['Export']).name for x in json.loads((out/'imagegen-asset-manifest.json').read_text(encoding='utf-8'))};results=[]
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules');inputs=[x['Path'] for x in c['Routes']]+list(c['ProtectedTextureSha256'])+list(c['FoodDataSha256'])
cases=['valid']+[k+'-'+n for k in ['old-tomato','wrong-stored','missing-art'] for n in names]+['wrong-food-id','b-shadows-art','prior-celtuce-regression','protected-32','unprotected-32','invalid-png']
for case in cases:
 base=out/'fixtures'/case;dest=base/'moddev/tfcfarmingplus/src/main/resources';dest.mkdir(parents=True,exist_ok=False)
 for rel in inputs:
  p=dest/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
 for n in names:
  if case in ['old-tomato-'+n,'wrong-stored-'+n]:
   p=dest/f'assets/tfcfarmingplus/models/item/food/{n}.json';j=json.loads(p.read_text(encoding='utf-8'));j['textures']['layer0']='tfc:item/food/tomato' if case.startswith('old-tomato') else 'tfcfarmingplus:item/food/'+n;p.write_text(json.dumps(j),encoding='utf-8')
  if case=='missing-art-'+n:(dest/f'assets/tfcfarmingplus/textures/item/food/{files[n]}').unlink()
 rel='assets/tfcfarmingplus/textures/item/food/'+files['pea']
 if case=='wrong-food-id':
  p=dest/'data/tfcfarmingplus/tfc/food/pea.json';j=json.loads(p.read_text(encoding='utf-8'));j['ingredient']['item']='tfc:food/tomato';p.write_text(json.dumps(j),encoding='utf-8')
 if case=='b-shadows-art':
  p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(dest/rel,p)
 if case=='prior-celtuce-regression':
  p=dest/'assets/tfcfarmingplus/models/item/food/celtuce.json';j=json.loads(p.read_text(encoding='utf-8'));j['textures']['layer0']='tfc:item/food/onion';p.write_text(json.dumps(j),encoding='utf-8')
 if case in ['protected-32','unprotected-32']:
  p=dest/rel if case=='protected-32' else dest/'assets/tfcfarmingplus/textures/item/food/size_fixture.png';Image.new('RGBA',(32,32),(30,100,20,255)).save(p)
 if case=='invalid-png':
  p=dest/rel;data=p.read_bytes();p.write_bytes(b'badimage'+data[8:])
 process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/('fixture-'+case+'.log')).write_bytes(process.stdout);passed=(process.returncode==0)==(case=='valid');assert passed,(case,process.stdout)
 if case in ['protected-32','unprotected-32']:assert b'16x16' in process.stdout and b'32x32' in process.stdout,(case,process.stdout)
 if case=='unprotected-32':assert b'findings: 1' in process.stdout,process.stdout
 results.append({'Case':case,'ExitCode':process.returncode,'Passed':passed})
draft=r/'moddev/.probe/generator-output/ar4r-item-icons';assert not draft.exists();process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/'draft-item-icons.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
actual=[p for p in draft.rglob('*') if p.is_file()];assert len(actual)==19 and set(p.relative_to(draft).as_posix() for p in actual)==set(x['Path'] for x in c['Routes']);assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(draft)).read_bytes() for p in actual)
results.append({'Case':'safe-copy-nineteen-json-only','Files':19,'ByteIdentical':True,'Passed':True});(out/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8');print('Passed',len(results),'checks:',len(cases),'fixtures and nineteen byte-identical safe-copy JSONs; unprotected 32x32 PNG rejected by size alone.')
