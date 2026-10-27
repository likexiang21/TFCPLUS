from pathlib import Path
import json,subprocess,shutil,hashlib,os
r=Path.cwd(); out=r/'moddev/inventory/item-icons-20261026'; a=r/'moddev/tfcfarmingplus'; tools=a/'tools'; c=json.loads((tools/'reviewed-item-icon-routes.json').read_text(encoding='utf-8')); results=[]
env=os.environ.copy();env["PSModulePath"]=str(Path(os.environ["SystemRoot"])/"System32/WindowsPowerShell/v1.0/Modules")
def run(label,args,expected):
 p=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',*map(str,args)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 (out/(label+'.log')).write_bytes(p.stdout)
 ok=(p.returncode==0)==expected
 results.append({'Case':label,'ExitCode':p.returncode,'ExpectedSuccess':expected,'Passed':ok})
 if not ok: raise AssertionError((label,p.stdout.decode('utf-8',errors='replace')))
 return p
fixture=out/'fixtures-v2';fixture.mkdir(exist_ok=True)
inputs=[x['Path'] for x in c['Routes']]+list(c['ProtectedTextureSha256'])+list(c['FoodDataSha256'])
cases=['valid','beet-route','wrong-food-id','missing-shared-art','changed-stored-art','b-shadow','extra-layer','geometry','native-atlas-override','missing-model']
for case in cases:
 base=fixture/case; dest=base/'moddev/tfcfarmingplus/src/main/resources'; dest.mkdir(parents=True,exist_ok=False)
 for rel in inputs:
  p=dest/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/'src/main/resources'/rel,p)
 model=dest/c['Routes'][0]['Path'];data=json.loads(model.read_text(encoding='utf-8'))
 if case=='beet-route': data['textures']['layer0']='tfc:item/food/beet'
 if case=='extra-layer':data['textures']['layer1']='tfc:item/food/beet'
 if case=='geometry':data['elements']=[]
 if case in ['beet-route','extra-layer','geometry']:model.write_text(json.dumps(data),encoding='utf-8')
 if case=='wrong-food-id':
  p=dest/next(iter(c['FoodDataSha256']));j=json.loads(p.read_text(encoding='utf-8'));j['ingredient']['item']='tfc:food/beet';p.write_text(json.dumps(j),encoding='utf-8')
 if case=='missing-shared-art':(dest/'assets/tfcfarmingplus/textures/item/food/kale.png').unlink()
 if case=='changed-stored-art':
  p=dest/next(iter(c['ProtectedTextureSha256']));p.write_bytes(p.read_bytes()+b'fixture')
 if case=='b-shadow':
  p=base/'moddev/tfcagricultureplus/src/main/resources'/c['Routes'][0]['Path'];p.parent.mkdir(parents=True);shutil.copy2(model,p)
 if case=='native-atlas-override':
  p=dest/c['NativeTexture']['Path'];p.parent.mkdir(parents=True);p.write_bytes(b'fixture')
 if case=='missing-model':model.unlink()
 run('fixture-'+case,[tools/'audit-item-icon-routes.ps1','-SourceInstance',base],case=='valid')
for mode,expectedCount in [('ItemIconsOnly',6),('ChiliDisplayOnly',17),('FenugreekDisplayOnly',17),('SpinachDisplayOnly',17)]:
 dest=r/'moddev/.probe/generator-output'/('ar4o-'+mode.lower());assert not dest.exists(),dest
 run('draft-'+mode,[tools/'gen-crops.ps1','-Root',dest,'-'+mode],True)
 actual=[p for p in dest.rglob('*') if p.is_file()];assert len(actual)==expectedCount,(mode,len(actual))
 assert all(p.read_bytes()==(a/'src/main/resources'/p.relative_to(dest)).read_bytes() for p in actual)
 results[-1]['Files']=len(actual);results[-1]['ByteIdentical']=True
run('guard-no-root',[tools/'gen-crops.ps1','-ItemIconsOnly'],False)
run('guard-live-root',[tools/'gen-crops.ps1','-Root',a/'src/main/resources','-ItemIconsOnly'],False)
for old in ['BroccoliFormsOnly','LettuceFormsOnly','KaleWildFormsOnly','CauliflowerFormsOnly','NapaCabbageFormsOnly','ChiliDisplayOnly','FenugreekDisplayOnly','SpinachDisplayOnly']:
 dest=r/'moddev/.probe/generator-output'/('ar4o-conflict-'+old.lower())
 run('guard-'+old,[tools/'gen-crops.ps1','-Root',dest,'-ItemIconsOnly','-'+old],False)
 assert not any(p.is_file() for p in dest.rglob('*'))
(out/'check-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
print('Passed:',len(results),'cases; 10 fixture checks, 4 byte-identical safe copy modes, 10 output/mode rejection checks.')
