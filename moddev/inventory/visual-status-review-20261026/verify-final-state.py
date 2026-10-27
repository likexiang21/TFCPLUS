"""Confirm this review changed documents only and preserve current deliveries."""
from pathlib import Path
from hashlib import sha256
from zipfile import ZipFile
from PIL import Image
from io import BytesIO
import json, re

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
bak = root / 'moddev/backups/ar4v-visual-status-review-20261026'

def digest(path):
    return sha256(path.read_bytes()).hexdigest().upper()

def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def save(name, value):
    (out / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

manifest = load(bak / 'backup-manifest.json')
assert len(manifest) == 9147
allowed = {'README.md', 'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md', 'moddev/docs/218-agriculture-audit-baseline-20261023.md'}
changed = []
for row in manifest:
    assert digest(bak / row['path']) == row['sha256'], row['path']
    current = Path(r'D:\TFC农业重置\PCL_TFC\mods') / Path(row['path']).name if row['path'].startswith('pcl-mods/') else root / row['path']
    assert current.is_file(), current
    if digest(current) != row['sha256']:
        changed.append(row['path'])
assert set(changed) == allowed, changed
counts = {}
for module in ['tfcfarmingplus', 'tfcagricultureplus']:
    for sub in ['src', 'tools', 'build/libs']:
        prefix = f'moddev/{module}/{sub}'
        before = {row['path'] for row in manifest if row['path'].startswith(prefix + '/')}
        now = {p.relative_to(root).as_posix() for p in (root / prefix).rglob('*') if p.is_file()}
        assert before == now, (prefix, sorted(before ^ now))
        counts[module + '/' + sub] = len(now)
assert counts['tfcfarmingplus/src'] == 5905 and counts['tfcagricultureplus/src'] == 3107
assert counts['tfcfarmingplus/tools'] == 101 and counts['tfcagricultureplus/tools'] == 19
assert digest(out / 'collect-current-references.py') == load(out / 'collector-provenance.json')['SourceSHA256']
summary = load(out / 'status-summary.json')
assert summary['TFCOnlyCultivatedSpecies'] == 74 and summary['FoodModelsViewedThisSlice'] == 16
assert summary['PlanterDefinitions'] == 156 and summary['PlanterTextureItems'] == 902
assert summary['PlanterTextureNamespaces'] == {'tfc': 884, 'tfcfarmingplus': 18}
assert summary['AllSourceResourceComparisonsEqual'] is True
scan = load(out / 'blockstate-references.json')
assert scan['Blockstates'] == 482 and len(scan['Applications']) == 2839 and not scan['Findings'] and not scan['SourceCollisions']
triage = load(out / 'item-icon-triage.json')
assert len(triage) == 229 and sum(r['ReviewedInAR4V'] for r in triage) == 16
refs = load(out / 'current-item-icon-references.json')
assert len(refs) == 229
for row in refs:
    assert digest(root / 'moddev/tfcfarmingplus/src/main/resources' / row['Path']) == row['ModelSha256']
assert len(load(out / 'remaining-visual-backlog.json')['Items']) == 22
assert len(load(out / 'next-work-queue.json')) == 10

pngs = []
item_root = root / 'moddev/tfcfarmingplus/src/main/resources/assets/tfcfarmingplus/textures/item'
for family in ['food', 'seeds']:
    for path in sorted((item_root / family).glob('*.png')):
        with Image.open(path) as im:
            assert im.size == (16, 16), path
            pngs.append({'Path': path.relative_to(root).as_posix(), 'Size': list(im.size), 'SHA256': digest(path)})
assert len(pngs) == 247
save('item-texture-sizes.json', pngs)
packages = []
for name, expected in [('TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar', '41540A6E8505BE4A4626F9D29715D5B6DFEE56A355332ACD87777DB2A3F66F16'), ('TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar', 'EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3')]:
    module = 'tfcfarmingplus' if name.startswith('TFCFarming') else 'tfcagricultureplus'
    paths = [root / 'moddev' / module / 'build/libs' / name, root / 'mods' / name, Path(r'D:\TFC农业重置\PCL_TFC\mods') / name]
    assert all(digest(p) == expected for p in paths)
    packages.append({'Module': module, 'Files': [str(p) for p in paths], 'SHA256': expected})
with ZipFile(root / 'mods/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar') as jar:
    for row in pngs:
        path = row['Path'].removeprefix('moddev/tfcfarmingplus/src/main/resources/')
        raw = jar.read(path)
        assert sha256(raw).hexdigest().upper() == row['SHA256']
        with Image.open(BytesIO(raw)) as im:
            assert im.size == (16, 16)

bush_tag = load(root / 'moddev/tfcfarmingplus/src/main/resources/data/tfc/tags/worldgen/placed_feature/feature/berry_bushes.json')
assert bush_tag['replace'] is False and len(bush_tag['values']) == 12 and bush_tag['remove'] == ['tfc:plant/strawberry_bush_patch']
assert '静态资源健康检查：通过' in (out / 'healthcheck.log').read_text(encoding='utf-8-sig')
comparisons = load(out / 'source-installed-resource-comparison.json')
assert [r['SourceResourcesCompared'] for r in comparisons] == [5867, 3031] and all(not r['Differences'] for r in comparisons)
guide_evidence = load(out / 'product-semantics-evidence.json')
assert len(guide_evidence) == 8 and all(any('/zh_cn/' in g['Path'] for g in r['Guides']) for r in guide_evidence)
assert all(g['Path'].startswith('moddev/tfcfarmingplus/src/main/resources/assets/tfc/patchouli_books/') for r in guide_evidence for g in r['Guides'])

sheets = ['AR4V-nuts-p1.png', 'AR4V-nuts-and-products-p2.png', 'AR4V-shared-leaf-p1.png', 'AR4V-shared-leaf-p2.png']
observations = [
    '四种坚果当前及保存图相同，呈桃、双樱桃、柠檬、橙子形态；当前接线本身不是缺文件。',
    '核桃呈绿苹果；龙舌兰为红色根形；向日葵当前穗/保存整花；大黄当前豆荚/保存泛黄细长形。',
    '芝麻菜、茼蒿、生菜、芥菜当前同叶束，保存图为根形/果形，不应直接回接。',
    '紫苏、马齿苋、菠菜、牛皮菜当前同叶束，保存图为根形/果形，物种专用美术仍缺。'
]
save('visual-observations.json', [{'Sheet': s, 'SHA256': digest(out / s), 'ActuallyViewed': True, 'Observation': note, 'Scope': '四食品各当前/保存图对照，共八格；离线二维', 'VisualAccepted': False, 'RuntimeVerified': False} for s, note in zip(sheets, observations)])
docs = [root / 'README.md', root / 'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md', root / 'moddev/docs/218-agriculture-audit-baseline-20261023.md', root / 'moddev/docs/260-ar4v-visual-backlog-and-agriculture-status-20261026.md']
for path in docs:
    data = path.read_bytes()
    text = data.decode('utf-8')
    assert not data.startswith(b'\xef\xbb\xbf') and '\ufffd' not in text and 'AR4-W' in text, path
    # Validate all links newly introduced by this slice, without adjudicating old historical links.
    for target in re.findall(r'\]\(([^)]+)\)', text):
        if any(t in target for t in ['260-ar4v-', 'visual-status-review-20261026/']):
            assert (path.parent / target).resolve().exists(), (path, target)

result = {'Stage': 'AR4-V', 'ExpectedComplexity': '4/5', 'ActualComplexity': '4/5', 'ReviewComplete': True,
          'BackupFilesVerified': len(manifest), 'ChangedExistingFiles': sorted(changed), 'SourceToolCounts': counts,
          'SourceToolsJARsUnchanged': True, 'Packages': packages, 'SourceInstalledResourcesCompared': comparisons,
          'ReadOnlyReferenceInventory': {'Blockstates': 482, 'ModelApplications': 2839, 'Findings': 0},
          'VisualSheetsActuallyViewed': sheets, 'FoodPairsActuallyViewed': 16, 'CurrentFoodSeedModelsReconciled': 229,
          'FoodSeedPNGSizeChecked': 247, 'PackagedFoodSeedPNGsByteEqualAnd16x16': 247,
          'HistoricalVisualItemsReconciled': 22, 'NextQueueItems': 10, 'HealthcheckPassed': True,
          'GameSourceOrToolsChanged': False, 'BuildRun': False, 'DeployRun': False, 'GameLaunched': False, 'PCLArchiveCreated': False,
          'VisualAccepted': False, 'RuntimeVerified': False, 'AgricultureComplete': False,
          'AgricultureTXTDeferredUntilComplete': True, 'NamingCleanup233Deferred': True,
          'NextStage': 'AR4-W', 'NextExpectedComplexity': '5/5', 'NextScope': 'Five nut food icons only; original PNGs, gameplay, food data, IDs and saves protected'}
save('final-state.json', result)
print(json.dumps({'AllPassed': True, 'BackupFilesVerified': len(manifest), 'OnlyExistingDocumentsChanged': sorted(changed), 'GameAndToolsUnchanged': True, 'SourceResourceComparison': [5867,3031], 'Next': 'AR4-W', 'Complexity': '5/5'}, ensure_ascii=False))
