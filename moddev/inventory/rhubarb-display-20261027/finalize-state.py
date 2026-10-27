from pathlib import Path
from hashlib import sha256
from io import BytesIO
from zipfile import ZipFile
from PIL import Image
import json

o = Path(__file__).resolve().parent
r = o.parents[2]
b = r / 'moddev/backups/ar4ag-rhubarb-display-20261027'

def load(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))

def digest(p):
    return sha256(p.read_bytes()).hexdigest().upper()

manifest = load(b / 'backup-manifest.json')
diff = load(o / 'source-diff.json')
delivery = load(o / 'delivery-manifest.json')
allowed = set(diff['Modified']) | {
    'README.md',
    'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md',
    'moddev/docs/218-agriculture-audit-baseline-20261023.md',
    'moddev/tfcfarmingplus/build/libs/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar',
    'mods/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar',
    'pcl-mods/TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar',
}
changed = set()
for row in manifest:
    key = row['path']
    assert digest(b / key) == row['sha256'], ('backup', key)
    current = Path('D:/TFC农业重置/PCL_TFC/mods') / Path(key).name if key.startswith('pcl-mods/') else r / key
    assert current.is_file(), ('missing', key)
    if digest(current) != row['sha256']:
        changed.add(key)
assert changed == allowed, (sorted(changed - allowed), sorted(allowed - changed))
old = {row['path']: row['sha256'] for row in manifest}
actual_added = set()
counts = {}
for module in ['tfcfarmingplus', 'tfcagricultureplus']:
    for folder in ['src', 'tools']:
        files = [p for p in (r / 'moddev' / module / folder).rglob('*') if p.is_file()]
        counts[module + '/' + folder] = len(files)
        actual_added.update(p.relative_to(r).as_posix() for p in files if p.relative_to(r).as_posix() not in old)
assert actual_added == set(diff['Added'])
assert not diff['Removed']
for package in delivery['Packages']:
    for path in package['Files']:
        assert digest(Path(path)) == package['SHA256'], path
assets = load(o / 'asset-manifest.json')['Assets']
assert len(assets) == 8
for row in assets:
    p = Path(row['FinalPath'])
    assert Image.open(p).size == (16, 16)
    lines=Path(row['EditableSource']).read_text(encoding='utf-8').splitlines()
    palette={line.split('=')[0]:tuple(bytes.fromhex(line.split('=')[1]))+(255,) for line in lines if '=' in line}
    grid=[line for line in lines if len(line)==16 and '=' not in line]
    assert len(grid)==16
    actual=Image.open(p).convert('RGBA')
    for y,line in enumerate(grid):
        for x,symbol in enumerate(line):
            assert actual.getpixel((x,y))==((0,0,0,0) if symbol=='.' else palette[symbol])

    assert p.read_bytes() == (o / 'native-grid-png' / p.name).read_bytes()
    im = Image.open(p).convert('RGBA')
    preview = Image.open(o / 'preview-64' / p.name).convert('RGBA')
    assert preview.size == (64, 64)
    assert preview.tobytes() == im.resize((64, 64), Image.Resampling.NEAREST).tobytes()
a_textures = r / 'moddev/tfcfarmingplus/src/main/resources/assets/tfcfarmingplus/textures'
pngs = list(a_textures.rglob('*.png'))
assert len(pngs) == 1817 and all(Image.open(p).size == (16, 16) for p in pngs)
with ZipFile(delivery['Packages'][0]['Files'][0]) as jar:
    assert not any('preview-64' in name or 'pixel-source-16' in name or 'imagegen-source' in name for name in jar.namelist())
    for row in assets:
        p = Path(row['FinalPath'])
        name = p.relative_to(r / 'moddev/tfcfarmingplus/src/main/resources').as_posix()
        assert jar.read(name) == p.read_bytes()
        assert Image.open(BytesIO(jar.read(name))).size == (16, 16)
checks = load(o / 'check-results.json')
assert len(checks) == 26 and all(row['Passed'] for row in checks)
assert load(o / 'tfc-only-cultivated-crops.json')['Count'] == 69
assert '静态资源健康检查：通过' in (o / 'health.log').read_text(encoding='utf-8-sig')
assert 'BUILD SUCCESSFUL' in (o / 'build-a.log').read_text(encoding='utf-8-sig')
for relative in ['README.md', 'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md', 'moddev/docs/218-agriculture-audit-baseline-20261023.md']:
    assert 'AR4-AH' in (r / relative).read_text(encoding='utf-8-sig')
assert (r / 'moddev/docs/271-ar4ag-rhubarb-native16-display-20261027.md').is_file()
result = {
    'Status': 'completed-static-delivery', 'BackupEntriesVerified': len(manifest),
    'ExistingChanges': sorted(changed), 'SourceDiff': diff, 'SourceCounts': counts,
    'Packages': delivery['Packages'], 'ChecksPassed': len(checks),
    'FormalNewSprites': 8, 'Native16': True, 'Workspace64Only': True,
    'AIProposalsAdopted': False, 'VisualAccepted': False, 'RuntimeVerified': False,
    'GameLaunched': False, 'PCLZipCreated': False, 'AgricultureFullyComplete': False,
    'ActualComplexity': '5/5', 'NextStep': 'AR4-AH 芦笋完整显示链', 'NextComplexity': '5/5',
}
(o / 'final-state.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'BackupEntriesVerified': len(manifest), 'AllowedExistingChanges': len(changed), 'ChecksPassed': len(checks), 'SourceCounts': counts, 'Status': result['Status']}, ensure_ascii=False))
