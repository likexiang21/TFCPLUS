from pathlib import Path
import json,subprocess,shutil,os
from PIL import Image
r=Path.cwd();out=r/'moddev/inventory/remaining-food-icons-20261026';a=r/'moddev/tfcfarmingplus';tools=a/'tools';c=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8'));names=['brussels_sprouts','chive','malabar_spinach','water_dropwort','water_caltrop','water_chestnut','water_shield','water_spinach'];reuse={'chive','water_caltrop'};files={x['Name']:Path(x['Export']).name for x in json.loads((out/'imagegen-asset-manifest.json').read_text(encoding='utf-8'))};files.update({n:n+'.png' for n in reuse});results=[]
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules');inputs=[x['Path'] for x in c['Routes']]+list(c['ProtectedTextureSha256'])+list(c['FoodDataSha256'])
cases=['valid']+['old-supplier-'+n for n in names]+['wrong-stored-'+n for n in names if n not in reuse]+['missing-art-'+n for n in names]+['b-shadows-art','water-caltrop-nutrition','prior-lotus-regression','unprotected-32']
for case in cases:
 base=out/'fixtures'/case;dest=base/'moddev/tfcfarmingplus/src/main/resources';dest.mkdir(parents=True,exist_ok=False)
 for rel in inputs:
  p=dest/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
 for n in names:
  if case in ['old-supplier-'+n,'wrong-stored-'+n]:
   p=dest/f'assets/tfcfarmingplus/models/item/food/{n}.json';j=json.loads(p.read_text(encoding='utf-8'));supplier='onion' if n=='brussels_sprouts' else 'rye' if n=='chive' else 'tomato' if n=='malabar_spinach' else 'rice';j['textures']['layer0']='tfc:item/food/'+supplier if case.startswith('old-supplier') else 'tfcfarmingplus:item/food/'+n;p.write_text(json.dumps(j),encoding='utf-8')
  if case=='missing-art-'+n:(dest/'assets/tfcfarmingplus/textures/item/food'/files[n]).unlink()
 if case=='b-shadows-art':
  rel='assets/tfcfarmingplus/textures/item/food/'+files['water_shield'];p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(dest/rel,p)
 if case=='water-caltrop-nutrition':
  p=dest/'data/tfcfarmingplus/tfc/food/water_caltrop.json';j=json.loads(p.read_text(encoding='utf-8'));j['grain']=1.4;p.write_text(json.dumps(j),encoding='utf-8')
 if case=='prior-lotus-regression':
  p=dest/'assets/tfcfarmingplus/models/item/food/lotus.json';j=json.loads(p.read_text(encoding='utf-8'));j['textures']['layer0']='tfc:item/food/rice';p.write_text(json.dumps(j),encoding='utf-8')
 if case=='unprotected-32':Image.new('RGBA',(32,32),(30,100,20,255)).save(dest/'assets/tfcfarmingplus/textures/item/food/size_fixture.png')
 process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/('fixture-'+case+'.log')).write_bytes(process.stdout);passed=(process.returncode==0)==(case=='valid');assert passed,(case,process.stdout)
 if case=='unprotected-32':assert b'16x16' in process.stdout and b'32x32' in process.stdout and b'findings: 1' in process.stdout,process.stdout
 results.append({'Case':case,'ExitCode':process.returncode,'Passed':passed})
draft=r/'moddev/.probe/generator-output/ar4u-item-icons';assert not draft.exists();process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/'draft-item-icons.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
actual=[p for p in draft.rglob('*') if p.is_file()];assert len(actual)==35 and set(p.relative_to(draft).as_posix() for p in actual)==set(x['Path'] for x in c['Routes']);assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(draft)).read_bytes() for p in actual)
results.append({'Case':'safe-copy-thirtyfive-json-only','Files':35,'ByteIdentical':True,'Passed':True});(out/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8');print('Passed',len(results),'checks:',len(cases),'fixtures and 35 byte-identical safe-copy JSONs. Reused source art is tested as valid, not mislabeled a negative.')
