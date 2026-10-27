from pathlib import Path
from hashlib import sha256
import json
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;b=r/'moddev/backups/ar4aa-sunflower-display-20261027'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
p=r/'moddev/docs/218-agriculture-audit-baseline-20261023.md';text=p.read_text(encoding='utf-8-sig')
old='> **2026-10-26当前入口：**AR4-Z共享叶菜组图标完成静态交付，见[264号](264-ar4z-leafy-food-icons-second-batch-20261026.md)；向日葵显示后续见265号；下一片AR4-AB菠菜盆栽，预期4/5。'
assert text.count(old)==1
text=text.replace(old,'> **2026-10-27当前入口：**AR4-AA向日葵显示接线静态交付，见[265号](265-ar4aa-sunflower-whole-display-20261027.md)；独立播种图标与盆栽分龄美术仍待后续，实机/最终外观未验。下一片AR4-AB菠菜盆栽，预期4/5。');p.write_text(text,encoding='utf-8')
expected=set(load(o/'source-diff.json')['Modified']) | {'README.md','moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md','moddev/docs/218-agriculture-audit-baseline-20261023.md'}
name='TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar';expected|={f'moddev/tfcfarmingplus/build/libs/{name}',f'mods/{name}',f'pcl-mods/{name}'}
changed=[];checked=0
for row in load(b/'backup-manifest.json'):
    rel=row['path'];assert digest(b/rel)==row['sha256'],('Backup changed',rel)
    path=Path('D:/TFC农业重置/PCL_TFC/mods')/Path(rel).name if rel.startswith('pcl-mods/') else r/rel
    assert path.is_file(),('Unexpected removal',rel)
    if digest(path)!=row['sha256']:changed.append(rel)
    checked+=1
assert set(changed)==expected,(set(changed)-expected,expected-set(changed))
for package in load(o/'delivery-manifest.json')['Packages']:
    assert all(digest(Path(p))==package['SHA256'] for p in package['Files'])
for module in ['tfcfarmingplus','tfcagricultureplus']:
    for folder in ['src','tools']:
        actual=sum(p.is_file() for p in (r/f'moddev/{module}/{folder}').rglob('*'))
        target={('tfcfarmingplus','src'):5923,('tfcfarmingplus','tools'):104,('tfcagricultureplus','src'):3107,('tfcagricultureplus','tools'):19}[(module,folder)]
        assert actual==target,(module,folder,actual)
assert len(load(o/'check-results.json'))==21 and all(row['Passed'] for row in load(o/'check-results.json'))
assert not load(o/'blockstate-references.json')['Findings']
assert len(load(o/'tfc-only-cultivated-crops.json')['Species'])==73
assert '静态资源健康检查：通过' in (o/'health.log').read_text(encoding='utf-8-sig')
for path in [r/'README.md',r/'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md',p]:assert 'AR4-AB' in path.read_text(encoding='utf-8-sig')
state={'Status':'completed-static-delivery','BackupEntriesReverified':checked,'ChangedExistingEntries':sorted(changed),'SourceDelta':load(o/'source-diff.json'),'Packages':load(o/'delivery-manifest.json')['Packages'],
       'Checks':21,'JarDelta':load(o/'jar-entry-diff.json'),'Handoff':'moddev/docs/265-ar4aa-sunflower-whole-display-20261027.md','Next':'AR4-AB spinach planter mature display','NextExpectedComplexity':'4/5','ActualComplexity':'5/5','RemainingSunflowerArt':['Planting icon remains native barley','Planter stages 2/3 and 4/5 share textures','Final artwork/plane side appearance await user review'],
       'VisualAccepted':False,'RuntimeVerified':False,'GameLaunched':False,'PCLZipCreated':False,'AgricultureFullyComplete':False}
(o/'final-state.json').write_text(json.dumps(state,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Final state passed:',checked,'backup entries reverified; source/package scope exact; next AR4-AB 4/5.')
