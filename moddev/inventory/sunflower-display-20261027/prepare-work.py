from pathlib import Path
from hashlib import sha256
import json, shutil

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
backup = root / 'moddev/backups/ar4aa-sunflower-display-20261027'
backup.mkdir(exist_ok=False)
(out/'work-plan.txt').write_text('AR4-AA，预期5/5。核对sunflower两格状态、野生单格/枯死两格与Firmalife盆栽实际接口。先备份A/B源工具包及安装包，保存全部旧图。修改范围限向日葵显示模型/状态和盆栽纹理及必要保护工具；不改Java、食品/种子与采收产量、气候、NBT/ID。先看原素材和真实模型整株离线预览，按证据决定接入方案，禁止虚构top2/top3方块。补回退负例与安全复制校验，完整verify、台账、构建和精确包差异通过后只部署A。交接265及当前入口更新，实机/最终美术待用户。',encoding='utf-8')
paths = [root / x for x in ['README.md','AGENTS.md','INBOX.md','DEVELOPMENT_RULES.md','moddev/tfcagricultureplus/OVERRIDE-REGISTRY.md']]
docs = root / 'moddev/docs'
paths += [p for p in docs.glob('*.md') if p.name.startswith(('217-', '218-', '253-', '254-', '255-', '256-', '257-', '258-', '259-', '260-', '261-', '262-', '263-', '264-'))]
for module in ['tfcfarmingplus','tfcagricultureplus']:
    for sub in ['src','tools','build/libs']:
        paths += [p for p in (root / 'moddev' / module / sub).rglob('*') if p.is_file()]
paths += [root / 'mods' / name for name in ['TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar','TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar']]
manifest = []
for p in paths:
    rel = p.relative_to(root)
    dest = backup / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, dest)
    value = sha256(p.read_bytes()).hexdigest().upper()
    assert sha256(dest.read_bytes()).hexdigest().upper() == value
    manifest.append({'path':rel.as_posix(),'sha256':value})
for p in Path(r'D:\TFC农业重置\PCL_TFC\mods').glob('*Plus-NeoForge-1.21.1-0.1.0.jar'):
    dest = backup / 'pcl-mods' / p.name
    dest.parent.mkdir(exist_ok=True)
    shutil.copy2(p,dest)
    value = sha256(p.read_bytes()).hexdigest().upper()
    assert sha256(dest.read_bytes()).hexdigest().upper() == value
    manifest.append({'path':'pcl-mods/'+p.name,'sha256':value})
(backup/'backup-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'BackupEntries':len(manifest),'Backup':str(backup)},ensure_ascii=False))
