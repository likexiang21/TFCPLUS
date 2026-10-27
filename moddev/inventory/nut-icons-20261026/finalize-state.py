from pathlib import Path
from hashlib import sha256
from PIL import Image
from zipfile import ZipFile
from io import BytesIO
import json, re

root=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');out=Path(__file__).resolve().parent;bak=root/'moddev/backups/ar4w-nut-icons-20261026';a=root/'moddev/tfcfarmingplus'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(name,data):(out/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
backup=load(bak/'backup-manifest.json');assert len(backup)==9153
review=load(out/'review-manifest.json');assert len(review['Changed'])==6 and len(review['Added'])==5 and not review['Removed']
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
assert counts=={'tfcfarmingplus/src':5910,'tfcfarmingplus/tools':101,'tfcagricultureplus/src':3107,'tfcagricultureplus/tools':19}

contract=load(a/'tools/reviewed-item-icon-routes.json');previous=load(bak/'moddev/tfcfarmingplus/tools/reviewed-item-icon-routes.json')
assert contract['Version']==8 and len(contract['Routes'])==40 and len(contract['ProtectedTextureSha256'])==66 and len(contract['FoodDataSha256'])==37
for key in ['ProtectedTextureSha256','FoodDataSha256']:
    assert all(contract[key][p]==v for p,v in previous[key].items())
    for p,v in contract[key].items():assert digest(a/'src/main/resources'/p)==v,p
assert all(route in contract['Routes'] for route in previous['Routes'])
assert contract['NativeTexture']==previous['NativeTexture']
art=load(out/'imagegen-asset-manifest.json');prompts=load(out/'imagegen-prompts.json');assert len(art)==len(prompts)==5
assert {r['Name'] for r in art}=={r['Name'] for r in prompts}
for row in art:
    assert row['Adopted'] and row['VisualAccepted'] is False and row['RuntimeVerified'] is False
    assert digest(Path(row['AdoptedSourcePath']))==digest(root/row['Export'])==row['ExportSha256']
    assert digest(Path(row['OriginalGeneratedPath']))==digest(root/row['PreservedSource'])==row['GeneratedSha256']
    with Image.open(Path(row['AdoptedSourcePath'])) as im:
        assert im.size==(16,16) and im.mode=='RGBA' and list(im.getchannel('A').getextrema())==row['AlphaRange']

refs=load(out/'current-item-icon-references.json');triage=load(out/'item-icon-triage.json');assert len(refs)==len(triage)==229
assert sum(r['ChangedInAR4W'] for r in refs)==sum(r['ChangeInThisSlice'] for r in triage)==5
for row in refs:assert digest(a/'src/main/resources'/row['Path'])==row['ModelSha256']
for row in triage:
    path=a/f'src/main/resources/assets/tfcfarmingplus/models/item/{row["Family"]}/{row["Name"]}.json'
    assert digest(path)==row['CurrentSourceModelSha256']
summary=load(out/'triage-summary.json');assert summary['TFCTextureModels']==128 and summary['OwnTextureModels']==101 and summary['TFCSeedTextureModels']==85
assert set(summary['AR4VConfirmedFoodMismatchesRemaining'])=={'agave','rhubarb','sunflower'}
checks=load(out/'check-results.json');assert len(checks)==26 and all(r['Passed'] for r in checks) and checks[-1]['Files']==40 and checks[-1]['ByteIdentical']
audit=load(out/'audit-icons/item-icon-contracts.json');assert audit=={'Models':40,'ProtectedPNGs':66,'ProtectedFoodData':37,'ItemTextureSize':'16x16','ItemPNGsSizeChecked':252,'Findings':[],'VisualAccepted':False,'RuntimeVerified':False}
sizes=load(out/'item-texture-sizes.json');assert len(sizes)==252
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
assert delivery['Packages'][0]['SHA256']=='8853AAA79B608F8A2B0395183BC556536CA3022AB41CF39E8364DEA1149FAF9B'
assert delivery['Packages'][1]['SHA256']=='EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3'
with ZipFile(delivery['Packages'][0]['Files'][0]) as archive:
    for row in sizes:
        key=row['Path'].removeprefix('moddev/tfcfarmingplus/src/main/resources/');data=archive.read(key)
        assert sha256(data).hexdigest().upper()==row['SHA256']
        with Image.open(BytesIO(data)) as im:assert im.size==(16,16)
    for row in art:
        p=Path(row['AdoptedSourcePath']);key=p.relative_to(a/'src/main/resources').as_posix();assert archive.read(key)==p.read_bytes()
jar_diff=load(out/'jar-entry-diff.json');assert len(jar_diff['Modified'])==len(jar_diff['Added'])==5 and not jar_diff['Removed']

sheets=['AR4W-before-and-candidates-p1.png','AR4W-before-and-candidates-p2.png','AR4W-exported-nut-candidates.png','AR4W-current-source-icons.png']
save('visual-observations.json',[{'File':name,'SHA256':digest(out/name),'ActuallyViewed':True,'Scope':'Offline candidate/source food icon inspection, including native 16x16 and enlarged comparisons','VisualAccepted':False,'RuntimeVerified':False} for name in sheets])
docs=[root/'README.md',root/'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md',root/'moddev/docs/218-agriculture-audit-baseline-20261023.md',root/'moddev/docs/261-ar4w-nut-food-icons-20261026.md']
for p in docs:
    raw=p.read_bytes();text=raw.decode('utf-8');assert not raw.startswith(b'\xef\xbb\xbf') and '\ufffd' not in text and 'AR4-X' in text
    for target in re.findall(r'\]\(([^)]+)\)',text):
        if '261-ar4w-' in target or 'nut-icons-20261026/' in target:assert (p.parent/target).resolve().exists(),target
queue=load(out/'next-work-queue.json');assert len(queue)==10 and 'AR4-W静态交付完成' in queue[0]['当前状态'] and 'AR4-X' in queue[1]['当前状态']
save('final-state.json',{'Stage':'AR4-W','StaticDeliveryComplete':True,'ExpectedComplexity':'5/5','ActualComplexity':'5/5','BackupEntriesVerified':9153,'ChangedExistingFiles':sorted(changed),'SourceDiff':review,'Counts':counts,'NewFoodPNGs':5,'ExistingPNGsModified':0,'SourceFoodSeedPNGs16x16':252,'PackagedFoodSeedPNGs16x16':252,'ModelsReconciled':229,'ChecksPassed':26,'SafeCopyJSONs':40,'IconProtection':{'Models':40,'PNGs':66,'FoodData':37,'Findings':0},'LedgerRows':418,'VerifyPassed':True,'BuildPassed':True,'BuildSeconds':27,'HealthcheckPassed':True,'JarDiff':jar_diff,'Packages':delivery['Packages'],'VisualSheetsActuallyViewed':sheets,'OriginalGeneratedImagesActuallyViewed':5,'VisualAccepted':False,'RuntimeVerified':False,'GameLaunched':False,'PCLArchiveCreated':False,'AgricultureComplete':False,'AgricultureTXTDeferredUntilComplete':True,'NamingCleanup233Deferred':True,'NextStage':'AR4-X','NextExpectedComplexity':'5/5','Handoff':str(docs[-1])})
print(json.dumps({'AllPassed':True,'Backup':9153,'SourceChanged':6,'SourceAdded':5,'Checks':26,'ItemPNGs16x16':252,'PackageA':delivery['Packages'][0]['SHA256'],'Next':'AR4-X','Complexity':'5/5'},ensure_ascii=False))
