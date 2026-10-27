from pathlib import Path
import json,subprocess,shutil,os
from PIL import Image
r=Path.cwd();out=r/'moddev/inventory/underground-icons-20261026';a=r/'moddev/tfcfarmingplus';tools=a/'tools';c=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8'));names=['taro','yam','lotus','arrowhead'];results=[]
env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules');inputs=[x['Path'] for x in c['Routes']]+list(c['ProtectedTextureSha256'])+list(c['FoodDataSha256'])
cases=['valid']+[kind+'-'+n for kind in ['old-supplier','wrong-stored','missing-art'] for n in names]+['wrong-food-id','b-shadows-art','prior-snake-gourd-regression','taro-nutrition-regression','unprotected-32']
for case in cases:
 base=out/'fixtures'/case;dest=base/'moddev/tfcfarmingplus/src/main/resources';dest.mkdir(parents=True,exist_ok=False)
 for rel in inputs:
  p=dest/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
 for n in names:
  if case in ['old-supplier-'+n,'wrong-stored-'+n]:
   p=dest/f'assets/tfcfarmingplus/models/item/food/{n}.json';j=json.loads(p.read_text(encoding='utf-8'));j['textures']['layer0']=('tfc:item/food/'+('tomato' if n=='yam' else 'rice')) if case.startswith('old-supplier') else 'tfcfarmingplus:item/food/'+n;p.write_text(json.dumps(j),encoding='utf-8')
  if case=='missing-art-'+n:(dest/f'assets/tfcfarmingplus/textures/item/food/{n}_harvest_v1.png').unlink()
 rel='assets/tfcfarmingplus/textures/item/food/lotus_harvest_v1.png'
 if case=='wrong-food-id':
  p=dest/'data/tfcfarmingplus/tfc/food/lotus.json';j=json.loads(p.read_text(encoding='utf-8'));j['ingredient']['item']='tfc:food/tomato';p.write_text(json.dumps(j),encoding='utf-8')
 if case=='b-shadows-art':
  p=base/'moddev/tfcagricultureplus/src/main/resources'/rel;p.parent.mkdir(parents=True);shutil.copy2(dest/rel,p)
 if case=='prior-snake-gourd-regression':
  p=dest/'assets/tfcfarmingplus/models/item/food/snake_gourd.json';j=json.loads(p.read_text(encoding='utf-8'));j['textures']['layer0']='tfc:item/food/tomato';p.write_text(json.dumps(j),encoding='utf-8')
 if case=='taro-nutrition-regression':
  p=dest/'data/tfcfarmingplus/tfc/food/taro.json';j=json.loads(p.read_text(encoding='utf-8'));j['grain']=1.5;p.write_text(json.dumps(j),encoding='utf-8')
 if case=='unprotected-32':Image.new('RGBA',(32,32),(30,100,20,255)).save(dest/'assets/tfcfarmingplus/textures/item/food/size_fixture.png')
 process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/('fixture-'+case+'.log')).write_bytes(process.stdout);passed=(process.returncode==0)==(case=='valid');assert passed,(case,process.stdout)
 if case=='unprotected-32':assert b'16x16' in process.stdout and b'32x32' in process.stdout and b'findings: 1' in process.stdout,process.stdout
 results.append({'Case':case,'ExitCode':process.returncode,'Passed':passed})
draft=r/'moddev/.probe/generator-output/ar4t-item-icons';assert not draft.exists();process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(tools/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/'draft-item-icons.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
actual=[p for p in draft.rglob('*') if p.is_file()];assert len(actual)==27 and set(p.relative_to(draft).as_posix() for p in actual)==set(x['Path'] for x in c['Routes']);assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(draft)).read_bytes() for p in actual)
results.append({'Case':'safe-copy-twentyseven-json-only','Files':27,'ByteIdentical':True,'Passed':True});(out/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8');print('Passed',len(results),'checks:',len(cases),'fixtures and 27 byte-identical safe-copy JSONs; independent 32x32 size rejection retained.')
