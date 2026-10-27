from pathlib import Path
from hashlib import sha256
from PIL import Image
from zipfile import ZipFile
from io import BytesIO
import json, re

root=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');out=Path(__file__).resolve().parent;bak=root/'moddev/backups/ar4y-leafy-icons-first-20261026';a=root/'moddev/tfcfarmingplus'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(name,data):(out/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
backup=load(bak/'backup-manifest.json');assert len(backup)==9163
review=load(out/'review-manifest.json');assert len(review['Changed'])==5 and len(review['Added'])==4 and not review['Removed']
allowed=set(review['Changed'])|{'README.md','moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md','moddev/docs/218-agriculture-audit-baseline-20261023.md','moddev/tfcfarmingplus/build/libs/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar','mods/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar','pcl-mods/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar'}
changed=[]
for row in backup:
    assert digest(bak/row['path'])==row['sha256'],row['path']
    current=Path(r'D:\TFC农业重置\PCL_TFC\mods')/Path(row['path']).name if row['path'].startswith('pcl-mods/') else root/row['path']
    assert current.is_file(),current
    if digest(current)!=row['sha256']:changed.append(row['path'])
assert set(changed)==allowed,(set(changed)-allowed,allowed-set(changed))
counts={}
for module in ['tfcfarmingplus','tfcagricultureplus']:
    for subtree in ['src','tools']:
        prefix=f'moddev/{module}/{subtree}'
        old={r['path'] for r in backup if r['path'].startswith(prefix+'/')}
        now={p.relative_to(root).as_posix() for p in (root/prefix).rglob('*') if p.is_file()}
        expected_added={p for p in review['Added'] if p.startswith(prefix+'/')}
        assert now-old==expected_added and not old-now
        counts[module+'/'+subtree]=len(now)
assert counts=={'tfcfarmingplus/src':5917,'tfcfarmingplus/tools':101,'tfcagricultureplus/src':3107,'tfcagricultureplus/tools':19}

contract=load(a/'tools/reviewed-item-icon-routes.json');previous=load(bak/'moddev/tfcfarmingplus/tools/reviewed-item-icon-routes.json')
assert contract['Version']==10 and len(contract['Routes'])==43 and len(contract['ProtectedTextureSha256'])==76 and len(contract['FoodDataSha256'])==40
for key in ['ProtectedTextureSha256','FoodDataSha256']:
    assert all(contract[key][p]==v for p,v in previous[key].items())
    for p,v in contract[key].items():assert digest(a/'src/main/resources'/p)==v,p
target_names={'arugula','garland_chrysanthemum','mustard_greens','perilla'}
for route in previous['Routes']:
    current=next(v for v in contract['Routes'] if v['Path']==route['Path'])
    if route['Family']=='food' and route['Name'] in target_names:
        assert current['Texture']=='tfcfarmingplus:item/food/'+route['Name']+'_harvest_v1'
        assert {k:v for k,v in current.items() if k!='Texture'}=={k:v for k,v in route.items() if k!='Texture'}
    else:assert current==route
assert contract['GuidePages']==previous['GuidePages'] and contract['ReviewedTemplateRows']==previous['ReviewedTemplateRows'] and contract['FoodDataSha256']==previous['FoodDataSha256']
assert contract['NativeTexture']==previous['NativeTexture']
art=load(out/'imagegen-asset-manifest.json');prompts=load(out/'imagegen-prompts.json');assert len(art)==len(prompts)==4
assert {r['Name'] for r in art}=={r['Name'] for r in prompts}
for row in art:
    assert row['Adopted'] and row['VisualAccepted'] is False and row['RuntimeVerified'] is False
    assert digest(Path(row['AdoptedSourcePath']))==digest(root/row['Export'])==row['ExportSha256']
    assert digest(Path(row['OriginalGeneratedPath']))==digest(root/row['PreservedSource'])==row['GeneratedSha256']
    with Image.open(Path(row['AdoptedSourcePath'])) as im:
        assert im.size==(16,16) and im.mode=='RGBA' and list(im.getchannel('A').getextrema())==row['AlphaRange']

refs=load(out/'current-item-icon-references.json');triage=load(out/'item-icon-triage.json');assert len(refs)==len(triage)==229
assert sum(r['ChangedInAR4Y'] for r in refs)==sum(r['ChangeInThisSlice'] for r in triage)==4
for row in refs:assert digest(a/'src/main/resources'/row['Path'])==row['ModelSha256']
for row in triage:
    path=a/f'src/main/resources/assets/tfcfarmingplus/models/item/{row["Family"]}/{row["Name"]}.json'
    assert digest(path)==row['CurrentSourceModelSha256']
summary=load(out/'triage-summary.json');assert summary['TFCTextureModels']==125 and summary['OwnTextureModels']==104 and summary['TFCSeedTextureModels']==85
assert summary['AR4VConfirmedFoodMismatchesRemaining']==[]
assert set(summary['RemainingSharedLeafFoodModels'])=={'lettuce','spinach','swiss_chard','purslane'}
checks=load(out/'check-results.json');assert len(checks)==24 and all(r['Passed'] for r in checks) and checks[-1]['Files']==43 and checks[-1]['ByteIdentical']
audit=load(out/'audit-icons/item-icon-contracts.json');assert audit=={'Models':43,'ProtectedPNGs':76,'ProtectedFoodData':40,'ItemTextureSize':'16x16','ItemPNGsSizeChecked':259,'GuidePages':6,'TemplateRows':6,'Findings':[],'VisualAccepted':False,'RuntimeVerified':False}
sizes=load(out/'item-texture-sizes.json');assert len(sizes)==259
for row in sizes:
    path=root/row['Path'];assert digest(path)==row['SHA256']
    with Image.open(path) as im:assert im.size==(16,16)
assert '全部交叉引用有效' in (out/'verify-a.log').read_text(encoding='utf-8-sig')
assert '[OK] coverage ledger matches' in (out/'ledger.log').read_text(encoding='utf-8-sig')
assert 'BUILD SUCCESSFUL in 27s' in (out/'build-a.log').read_text(encoding='utf-8-sig')
assert '静态资源健康检查：通过' in (out/'healthcheck.log').read_text(encoding='utf-8-sig')
delivery=load(out/'delivery-manifest.json')
for package in delivery['Packages']:
    assert all(digest(Path(p))==package['SHA256'] for p in package['Files'])
assert delivery['Packages'][0]['SHA256']=='FC6773E088FCD8162C911387D429F4ABBD2621A530A74F6EAA8903CC8ABF0096'
assert delivery['Packages'][1]['SHA256']=='EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3'
with ZipFile(delivery['Packages'][0]['Files'][0]) as archive:
    for row in sizes:
        key=row['Path'].removeprefix('moddev/tfcfarmingplus/src/main/resources/');data=archive.read(key)
        assert sha256(data).hexdigest().upper()==row['SHA256']
        with Image.open(BytesIO(data)) as im:assert im.size==(16,16)
    for row in art:
        p=Path(row['AdoptedSourcePath']);key=p.relative_to(a/'src/main/resources').as_posix();assert archive.read(key)==p.read_bytes()
jar_diff=load(out/'jar-entry-diff.json');assert len(jar_diff['Modified'])==len(jar_diff['Added'])==4 and not jar_diff['Removed']

sheets=['AR4Y-current-stored-candidates.png','AR4Y-exported-leafy-candidates.png','AR4Y-current-source-icons.png']
save('visual-observations.json',[{'File':name,'SHA256':digest(out/name),'ActuallyViewed':True,'Scope':'Offline candidate/source food icon inspection, including native 16x16 and enlarged comparisons','VisualAccepted':False,'RuntimeVerified':False} for name in sheets])
docs=[root/'README.md',root/'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md',root/'moddev/docs/218-agriculture-audit-baseline-20261023.md',root/'moddev/docs/263-ar4y-leafy-food-icons-first-batch-20261026.md']
for p in docs:
    raw=p.read_bytes();text=raw.decode('utf-8');assert not raw.startswith(b'\xef\xbb\xbf') and '\ufffd' not in text and 'AR4-Z' in text
    for target in re.findall(r'\]\(([^)]+)\)',text):
        if '263-ar4y-' in target or 'leafy-icons-first-20261026/' in target:assert (p.parent/target).resolve().exists(),target
queue=load(out/'next-work-queue.json');assert len(queue)==10 and 'AR4-Y' in queue[2]['当前状态'] and 'AR4-Z' in queue[2]['当前状态']
result={'Stage':'AR4-Y','StaticDeliveryComplete':True,'ExpectedComplexity':'5/5','ActualComplexity':'5/5','BackupEntriesVerified':9163,'ChangedExistingFiles':sorted(changed),'SourceDiff':review,'Counts':counts,'NewFoodPNGs':4,'ExistingPNGsModified':0,'SourceFoodSeedPNGs16x16':259,'PackagedFoodSeedPNGs16x16':259,'ModelsReconciled':229,'ChecksPassed':24,'SafeCopyJSONs':43,'IconProtection':{'Models':43,'PNGs':76,'FoodData':40,'GuidePages':6,'TemplateRows':6,'Findings':0},'GuideAndTemplateContractsUnchanged':True,'LedgerRows':418,'VerifyPassed':True,'BuildPassed':True,'BuildSeconds':27,'HealthcheckPassed':True,'JarDiff':jar_diff,'Packages':delivery['Packages'],'VisualSheetsActuallyViewed':sheets,'OriginalGeneratedImagesActuallyViewed':4,'VisualAccepted':False,'RuntimeVerified':False,'GameLaunched':False,'PCLArchiveCreated':False,'AgricultureComplete':False,'AgricultureTXTDeferredUntilComplete':True,'NamingCleanup233Deferred':True,'RemainingSharedLeafFoodModels':summary['RemainingSharedLeafFoodModels'],'NextStage':'AR4-Z','NextExpectedComplexity':'5/5','Handoff':str(docs[-1])}
save('final-state.json',result)
print(json.dumps({'AllPassed':True,'Backup':9163,'SourceChanged':5,'SourceAdded':4,'Checks':24,'ItemPNGs16x16':259,'PackageA':delivery['Packages'][0]['SHA256'],'Next':'AR4-Z','Complexity':'5/5'},ensure_ascii=False))
