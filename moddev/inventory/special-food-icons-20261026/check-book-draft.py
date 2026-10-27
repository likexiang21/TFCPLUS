from pathlib import Path
import json,shutil,subprocess,os,sys
r=Path.cwd();o=r/'moddev/inventory/special-food-icons-20261026';a=r/'moddev/tfcfarmingplus';draft=r/'moddev/.probe/generator-output/ar4x-book-review'
if '--compare-existing' not in sys.argv:
    assert not draft.exists();shutil.copytree(a/'src/main/resources',draft)
    env=os.environ.copy();env['PSModulePath']=str(Path(os.environ['SystemRoot'])/'System32/WindowsPowerShell/v1.0/Modules')
    p=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(a/'tools/gen-patchouli-book.ps1'),'-OutputRoot',str(draft)],cwd=r,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (o/'book-draft.log').write_bytes(p.stdout);assert p.returncode==0,p.stdout[-3000:]
c=json.loads((a/'tools/reviewed-item-icon-routes.json').read_text(encoding='utf-8'));rows=[]
for g in c['GuidePages']:
    doc=json.loads((draft/g['Path']).read_text(encoding='utf-8-sig'));pages=[p for p in doc['pages'] if p.get('anchor')==g['Name']];assert len(pages)==1
    assert pages[0]['text']==g['Text'],(g['Locale'],g['Name'],pages[0]['text'],g['Text'])
    current=json.loads((a/'src/main/resources'/g['Path']).read_text(encoding='utf-8'));assert len(current['pages'])==174 and len(doc['pages'])==176
    extra={p['anchor'] for p in doc['pages'] if 'anchor' in p}-{p['anchor'] for p in current['pages'] if 'anchor' in p};assert extra=={'strawberry'}
    assert next(i for i,p in enumerate(doc['pages']) if p.get('anchor')==g['Name'])==next(i for i,p in enumerate(current['pages']) if p.get('anchor')==g['Name'])
    rows.append({'Locale':g['Locale'],'Name':g['Name'],'TextEqualsSource':True,'SourcePages':174,'DraftPages':176,'LegacyDraftExtraAnchor':'strawberry','ReviewedPageIndexEqualsSource':True})
(o/'book-draft-comparison.json').write_text(json.dumps({'PassedForSixReviewedPages':True,'GuidePages':rows,'FullDraftMatchesSource':False,'PublishedWholeDraft':False},ensure_ascii=False,indent=2),encoding='utf-8')
print('Six reviewed prose pages equal source at the same indices. Legacy draft has 176 pages vs source 174 (extra strawberry pair); whole draft not published.')
