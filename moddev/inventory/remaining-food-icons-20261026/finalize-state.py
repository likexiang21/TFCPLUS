from pathlib import Path
from hashlib import sha256
from io import BytesIO
from zipfile import ZipFile
from PIL import Image
import json

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
inv = root / 'moddev/inventory/remaining-food-icons-20261026'
bak = root / 'moddev/backups/ar4u-remaining-food-icons-20261026'
a = root / 'moddev/tfcfarmingplus'
b = root / 'moddev/tfcagricultureplus'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def digest(path):
    return sha256(path.read_bytes()).hexdigest().upper()

backup = read(bak / 'backup-manifest.json')
assert len(backup) == 9145, len(backup)
for row in backup:
    assert digest(bak / row['path']) == row['sha256'], row['path']

diff = {'Changed': [], 'Added': [], 'Removed': [], 'Counts': {}}
for sub in ['moddev/tfcfarmingplus/src', 'moddev/tfcfarmingplus/tools', 'moddev/tfcagricultureplus/src', 'moddev/tfcagricultureplus/tools']:
    old = {p.relative_to(bak).as_posix(): p for p in (bak / sub).rglob('*') if p.is_file()}
    now = {p.relative_to(root).as_posix(): p for p in (root / sub).rglob('*') if p.is_file()}
    diff['Changed'] += [p for p in old.keys() & now.keys() if digest(old[p]) != digest(now[p])]
    diff['Added'] += list(now.keys() - old.keys())
    diff['Removed'] += list(old.keys() - now.keys())
    diff['Counts'][sub.removeprefix('moddev/')] = len(now)
for key in ['Changed', 'Added', 'Removed']:
    diff[key].sort()
assert diff == read(inv / 'review-manifest.json'), diff
assert len(diff['Changed']) == 9 and len(diff['Added']) == 6 and not diff['Removed']
assert all(p.endswith('.json') for p in diff['Changed'])
assert all('/tfcfarmingplus/' in p for p in diff['Changed'] + diff['Added'])
assert diff['Counts'] == {'tfcfarmingplus/src': 5905, 'tfcfarmingplus/tools': 101, 'tfcagricultureplus/src': 3107, 'tfcagricultureplus/tools': 19}

allowed_doc_changes = {'README.md', 'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md', 'moddev/docs/218-agriculture-audit-baseline-20261023.md'}
protected_docs = [row for row in backup if not row['path'].startswith(('moddev/tfcfarmingplus/', 'moddev/tfcagricultureplus/src/', 'moddev/tfcagricultureplus/tools/', 'moddev/tfcagricultureplus/build/', 'mods/', 'pcl-mods/')) and row['path'] not in allowed_doc_changes]
for row in protected_docs:
    assert digest(root / row['path']) == row['sha256'], row['path']

generated = read(inv / 'imagegen-asset-manifest.json')
reused = read(inv / 'reused-asset-manifest.json')
assert len(generated) == 6 and len(reused) == 2
for row in generated:
    adopted = Path(row['AdoptedSourcePath'])
    assert digest(adopted) == row['ExportSha256'] == digest(root / row['Export'])
    assert digest(root / row['PreservedSource']) == row['GeneratedSha256'] == digest(Path(row['OriginalGeneratedPath']))
    with Image.open(adopted) as im:
        assert im.size == (16, 16) and im.mode == 'RGBA'
        assert list(im.getchannel('A').getextrema()) == row['AlphaRange']
    assert row['VisualAccepted'] is False and row['RuntimeVerified'] is False
for row in reused:
    assert digest(Path(row['AdoptedSourcePath'])) == row['SourceSha256']

pngs = [p for family in ['food', 'seeds'] for p in (a / 'src/main/resources/assets/tfcfarmingplus/textures/item' / family).glob('*.png')]
assert len(pngs) == 247
for p in pngs:
    with Image.open(p) as im:
        assert im.size == (16, 16), p

refs = read(inv / 'current-item-icon-references.json')
assert len(refs) == 229 and sum(r['ChangedInAR4U'] for r in refs) == 8
for row in refs:
    assert digest(a / 'src/main/resources' / row['Path']) == row['ModelSha256'], row['Path']
    assert row['RuntimeVerified'] is False and row['VisualAccepted'] is False
summary = read(inv / 'triage-summary.json')
assert summary['CurrentTFCTextureModels'] == 128 and summary['CurrentOwnTextureModels'] == 101 and summary['TFCSeedTextureModels'] == 85
assert summary['ClearlyWrongGroupRemaining'] == [] and summary['OtherArtAndLifecycleBacklogRemains'] is True
checks = read(inv / 'check-results.json')
assert len(checks) == 28 and all(r['Passed'] for r in checks)
assert checks[-1]['Files'] == 35 and checks[-1]['ByteIdentical']
assert read(inv / 'audit-icons/item-icon-contracts.json') == {'Models': 35, 'ProtectedPNGs': 56, 'ProtectedFoodData': 32, 'ItemTextureSize': '16x16', 'ItemPNGsSizeChecked': 247, 'Findings': [], 'VisualAccepted': False, 'RuntimeVerified': False}
assert 'BUILD SUCCESSFUL in 26s' in (inv / 'build-a.log').read_text(encoding='utf-8-sig')
assert '全部交叉引用有效' in (inv / 'verify-a.log').read_text(encoding='utf-8-sig')
assert '[OK] coverage ledger matches' in (inv / 'ledger.log').read_text(encoding='utf-8-sig')
assert '静态资源健康检查：通过' in (inv / 'healthcheck.log').read_text(encoding='utf-8-sig')

delivery = read(inv / 'delivery-manifest.json')
for package in delivery['Packages']:
    for p in package['Files']:
        assert digest(Path(p)) == package['Sha256'], p
assert delivery['Packages'][0]['Sha256'] == '41540A6E8505BE4A4626F9D29715D5B6DFEE56A355332ACD87777DB2A3F66F16'
assert delivery['Packages'][1]['Sha256'] == 'EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3'
jar_diff = read(inv / 'jar-entry-diff.json')
with ZipFile(delivery['Packages'][0]['Files'][0]) as current, ZipFile(bak / 'moddev/tfcfarmingplus/build/libs/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar') as previous:
    old_names, now_names = set(previous.namelist()), set(current.namelist())
    actual = {'Modified': sorted(n for n in old_names & now_names if previous.read(n) != current.read(n)), 'Added': sorted(now_names - old_names), 'Removed': sorted(old_names - now_names)}
    assert actual == jar_diff
    assert len(actual['Modified']) == 8 and len(actual['Added']) == 6 and not actual['Removed']
    for n in actual['Modified'] + actual['Added']:
        assert current.read(n) == (a / 'src/main/resources' / n).read_bytes(), n
    packaged = [n for n in now_names if n.startswith(('assets/tfcfarmingplus/textures/item/food/', 'assets/tfcfarmingplus/textures/item/seeds/')) and n.endswith('.png')]
    assert len(packaged) == 247
    for n in packaged:
        with Image.open(BytesIO(current.read(n))) as im:
            assert im.size == (16, 16), n

handoff_name = '259-ar4u-remaining-food-icons-20261026.md'
doc_paths = [root / 'README.md', root / 'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md', root / 'moddev/docs/218-agriculture-audit-baseline-20261023.md', root / 'moddev/docs' / handoff_name]
for p in doc_paths:
    text = p.read_text(encoding='utf-8-sig')
    assert 'AR4-V' in text and '\ufffd' not in text
    if p.name != handoff_name:
        assert handoff_name in text
    assert not p.read_bytes().startswith(b'\xef\xbb\xbf'), p

result = {
    'Stage': 'AR4-U', 'StaticDeliveryComplete': True, 'ExpectedComplexity': '5/5', 'ActualComplexity': '5/5',
    'BackupFilesVerified': len(backup), 'SourceDiff': diff,
    'ProtectedHistoricalDocumentsVerified': len(protected_docs),
    'GeneratedAdopted': 6, 'ExistingImagesReused': 2, 'ExistingPNGsChanged': 0,
    'ItemFoodSeedPNGs16x16': 247, 'PackagedItemFoodSeedPNGs16x16': 247,
    'CurrentModelsReconciled': 229, 'ChecksPassed': 28, 'SafeCopyJSONsByteIdentical': 35,
    'IconContracts': {'Models': 35, 'PNGs': 56, 'FoodData': 32, 'Findings': 0},
    'VerifyPassed': True, 'LedgerRows': 418, 'LedgerPassed': True, 'BuildPassed': True, 'HealthcheckPassed': True,
    'JarDiff': jar_diff, 'Packages': delivery['Packages'],
    'Handoff': str(root / 'moddev/docs' / handoff_name),
    'UpdatedDocuments': [str(p) for p in doc_paths[:3]],
    'VisualAccepted': False, 'RuntimeVerified': False, 'GameLaunched': False, 'PCLArchiveCreated': False,
    'AgricultureStageComplete': False, 'AgricultureTXTDeferredUntilStageComplete': True, 'NamingCleanup233Deferred': True,
    'NextStage': 'AR4-V', 'NextExpectedComplexity': '4/5', 'NextScope': 'Remaining visual and agriculture status review; read-only consolidation before the next implementation batch'
}
(inv / 'final-state.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'FinalState': str(inv / 'final-state.json'), 'Backup': len(backup), 'Changed': len(diff['Changed']), 'Added': len(diff['Added']), 'Checks': len(checks), 'AllPassed': True}, ensure_ascii=False))
