from pathlib import Path
import json,shutil,subprocess,os
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;a=r/'moddev/tfcfarmingplus';s=a/'src/main/resources';t=a/'tools'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False),encoding='utf-8')
c=load(t/'reviewed-item-icon-routes.json');env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
inputs=[v['Path'] for v in c['Routes']]+list(c['ProtectedTextureSha256'])+list(c['FoodDataSha256'])+list({v['Path'] for v in c['GuidePages']});results=[]
cases=['valid','zh-regrowth','en-regrowth','crop-template','book-template','missing-anchor','duplicate-anchor','prior-agave','food-route']
for i,case in enumerate(cases):
 base=o/'fixtures'/str(i);res=base/'moddev/tfcfarmingplus/src/main/resources';res.mkdir(parents=True,exist_ok=False)
 for rel in inputs:
  p=res/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(s/rel,p)
 for rel in {v['Path'] for v in c['ReviewedTemplateRows']}:
  p=base/'moddev/tfcfarmingplus'/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/rel,p)
 if case in ['zh-regrowth','en-regrowth','missing-anchor','duplicate-anchor','prior-agave']:
  locale='en_us' if case=='en-regrowth' else 'zh_cn';p=res/f'assets/tfc/patchouli_books/field_guide/{locale}/entries/farming_plus/crops.json';v=load(p);page=next(x for x in v['pages'] if x.get('anchor')==('agave' if case=='prior-agave' else 'swiss_chard'))
  if case in ['zh-regrowth','en-regrowth','prior-agave']:page['text']+=' 割了还会再长。' if locale=='zh_cn' else ' It regrows after cutting.'
  if case=='missing-anchor':page.pop('anchor')
  if case=='duplicate-anchor':v['pages'].append(dict(page))
  save(p,v)
 if case in ['crop-template','book-template']:
  p=base/'moddev/tfcfarmingplus/tools'/('gen-crops.ps1' if case=='crop-template' else 'gen-patchouli-book.ps1');lines=p.read_text(encoding='utf-8-sig').splitlines();lines=[line+' # regrowth fixture' if "n='swiss_chard';" in line else line for line in lines];p.write_text('\n'.join(lines)+'\n',encoding='utf-8-sig')
 if case=='food-route':
  p=res/'assets/tfcfarmingplus/models/item/food/swiss_chard.json';v=load(p);v['textures']['layer0']='tfcfarmingplus:item/food/kale';save(p,v)
 process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(t/'audit-item-icon-routes.ps1'),'-SourceInstance',str(base)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(o/f'fixture-{i}-{case}.log').write_bytes(process.stdout);assert (process.returncode==0)==(case=='valid'),(case,process.stdout)
 results.append({'Case':case,'ExitCode':process.returncode,'Passed':True})
draft=r/'moddev/.probe/generator-output/ar4ac-icons';assert not draft.exists()
process=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(t/'gen-crops.ps1'),'-Root',str(draft),'-ItemIconsOnly'],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(o/'safe-icons.log').write_bytes(process.stdout);assert process.returncode==0,process.stdout
files=[p for p in draft.rglob('*') if p.is_file()];assert len(files)==44 and {p.relative_to(draft).as_posix() for p in files}=={v['Path'] for v in c['Routes']};assert all(p.read_bytes()==(s/p.relative_to(draft)).read_bytes() for p in files)
results.append({'Case':'safe-44-icons','Files':44,'ByteIdentical':True,'Passed':True});save(o/'check-results.json',results);print('Passed',len(results),'checks: 9 fixtures and safe 44 JSON copy.')
