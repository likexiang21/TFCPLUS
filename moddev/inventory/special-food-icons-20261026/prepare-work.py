from pathlib import Path
from hashlib import sha256
import json, shutil

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
backup = root / 'moddev/backups/ar4x-special-food-icons-20261026'
backup.mkdir(exist_ok=False)
names = ['rhubarb', 'sunflower', 'agave']
(out / 'work-plan.txt').write_text('AR4-X，预期复杂度5/5。先全量备份并逐文件核哈希。三食品图标：大黄叶柄、向日葵食用籽、龙舌兰心，沿用food及seeds ID，不改原PNG、食品属性、Java、B、掉落/生长、存档。\n计划改三模型、新增三16×16PNG，改中英文crops.json中三文字页并同步gen-patchouli-book/gen-crops准确文案；扩现有图标合同及audit-item-icon-routes的六页说明保护，不另建业务框架。\n先实际查看原稿及16×16导出再接入；源/包尺寸全量核对；回退/缺图/串图/B覆盖/食品/说明负例、43份安全复制、手册生成草稿对照、完整verify/台账/构建通过；仅部署A到两mods，B不动。\n输出262号交接及README/217/218，保留实机和最终美术待验，全农业TXT和233号仍延期。\n', encoding='utf-8')
paths = [root / x for x in ['README.md','AGENTS.md','INBOX.md','DEVELOPMENT_RULES.md','moddev/tfcagricultureplus/OVERRIDE-REGISTRY.md']]
docs = root / 'moddev/docs'
paths += [p for p in docs.glob('*.md') if p.name.startswith(('217-', '218-', '253-', '254-', '255-', '256-', '257-', '258-', '259-', '260-', '261-'))]
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
evidence = json.loads((root/'moddev/inventory/visual-status-review-20261026/product-semantics-evidence.json').read_text(encoding='utf-8'))
(out/'product-semantics-evidence.json').write_text(json.dumps([r for r in evidence if r['Name'] in names],ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'BackupEntries':len(manifest),'Backup':str(backup),'Products':names},ensure_ascii=False))
