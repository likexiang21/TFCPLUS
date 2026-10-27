from pathlib import Path
from hashlib import sha256
import json
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;a=r/'moddev/tfcfarmingplus';s=a/'src/main/resources';t=a/'tools';b=r/'moddev/backups/ar4ac-swiss-harvest-20261027'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
for row in load(b/'backup-manifest.json'):
 if row['path'].startswith(('moddev/tfcfarmingplus/src/','moddev/tfcfarmingplus/tools/','moddev/tfcagricultureplus/src/','moddev/tfcagricultureplus/tools/')):assert digest(r/row['path'])==row['sha256'],row['path']
descriptions={'zh_cn':'叶柄肥厚、叶片宽大；成熟后破坏整株收获，之后需要重新播种','en_us':'thick stalks and broad leaves; break the mature plant to harvest, then sow seeds again'}
changed=[];pages=[]
for locale,old in [('zh_cn','叶柄肥厚、叶片宽大，割了还会再长'),('en_us','thick stalks and broad leaves')]:
 rel=f'assets/tfc/patchouli_books/field_guide/{locale}/entries/farming_plus/crops.json';p=s/rel;original=p.read_text(encoding='utf-8-sig');book=load(p);page=next(v for v in book['pages'] if v.get('anchor')=='swiss_chard')
 assert page['text'].count(old)==1;before=page['text'];page['text']=before.replace(old,descriptions[locale]);assert original.count(before)==1
 # Replace the one text payload in-place, preserving every other byte in the book.
 old_payload=json.dumps(before,ensure_ascii=False)[1:-1];new_payload=json.dumps(page['text'],ensure_ascii=False)[1:-1]
 assert original.count(old_payload)==1;p.write_text(original.replace(old_payload,new_payload),encoding='utf-8')
 baseline=load(b/'moddev/tfcfarmingplus/src/main/resources'/rel);current=load(p)
 for index,(prior,now) in enumerate(zip(baseline['pages'],current['pages'])):
  if prior!=now:assert prior.get('anchor')=='swiss_chard' and {k:v for k,v in prior.items() if k!='text'}=={k:v for k,v in now.items() if k!='text'}
 baseline['pages']=current['pages'];assert baseline==current
 pages.append({'Path':rel,'Name':'swiss_chard','Locale':locale,'Text':page['text']});changed.append(rel)
templates=[]
for filename in ['gen-crops.ps1','gen-patchouli-book.ps1']:
 p=t/filename;lines=p.read_text(encoding='utf-8-sig').splitlines();matches=[i for i,line in enumerate(lines) if "n='swiss_chard';" in line];assert len(matches)==1;index=matches[0];line=lines[index]
 if filename=='gen-crops.ps1':
  line=line.replace('叶柄肥厚、叶片宽大，割了还会再长。',descriptions['zh_cn']+'。').replace('Thick stalks and broad leaves; it keeps producing after cutting.','Thick stalks and broad leaves; break the mature plant to harvest, then sow seeds again.')
 else:
  line=line.replace("zhDesc='叶柄肥厚、叶片宽大，割了还会再长'","zhDesc='"+descriptions['zh_cn']+"'").replace("enDesc='thick stalks and broad leaves'","enDesc='"+descriptions['en_us']+"'")
 assert line!=lines[index];lines[index]=line;p.write_text('\n'.join(lines)+'\n',encoding='utf-8-sig')
 templates.append({'Path':'tools/'+filename,'Name':'swiss_chard','LineSha256':sha256(line.encode('utf-8')).hexdigest().upper()})
p=t/'reviewed-item-icon-routes.json';c=load(p);assert c['Version']==11;c['Version']=12;c['GuidePages']+=pages;c['ReviewedTemplateRows']+=templates;c['HarvestGuideRevision']='AR4-AC swiss chard ordinary whole-plant harvest; pages and generator rows protected; no gameplay change'
p.write_text(json.dumps(c,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(o/'change-manifest.json').write_text(json.dumps({'ModifiedResources':changed,'ModifiedTools':['gen-crops.ps1','gen-patchouli-book.ps1','reviewed-item-icon-routes.json'],'ReviewedGuidePages':8,'ReviewedTemplateRows':8,'OnlyTwoProsePayloadsChanged':True,'GameplayChanged':False,'NoArtworkChanges':True},ensure_ascii=False,indent=2),encoding='utf-8');print('Updated two prose payloads, two generator rows; contract now 8 guide pages and 8 template rows.')
