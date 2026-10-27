"""Create a verified backup and isolate existing read-only reference inventory."""
from pathlib import Path
from hashlib import sha256
import shutil
import json

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
backup = root / 'moddev/backups/ar4v-visual-status-review-20261026'
backup.mkdir(exist_ok=False)
plan = '''AR4-V；预期复杂度4/5。只读复核当前源码，不改A/B游戏资源、Java、工具或JAR。
输入：217/218/249/259、229/237/238/252及当前229模型分诊；当前A/B和已安装依赖。
输出：五坚果与龙舌兰/向日葵/大黄的产物语义及图标对照；当前87作物显示引用、盆栽及历史22项状态更新；下一施工切片和260号交接，更新README/217/218。
先保存A/B源、工具、构建包、四安装包及文档，逐文件核哈希。
完成条件：新清单与当前源一致；未将旧供体来源或边界像素差直接判作缺陷；源/工具/JAR不变；人工、实机和最终美术未通过；农业TXT与233号整理仍延期。
'''
(out / 'work-plan.txt').write_text(plan, encoding='utf-8')
files = [root / name for name in ['README.md', 'AGENTS.md', 'INBOX.md', 'DEVELOPMENT_RULES.md']]
files += [root / 'moddev/docs' / name for name in ['217-agriculture-repair-next-phase-plan-20261023.md', '218-agriculture-audit-baseline-20261023.md', '249-ar4k-current-visual-backlog-review-20261025.md', '259-ar4u-remaining-food-icons-20261026.md']]
files += [root / 'moddev/tfcagricultureplus/OVERRIDE-REGISTRY.md']
for module in ['tfcfarmingplus', 'tfcagricultureplus']:
    for subtree in ['src', 'tools', 'build/libs']:
        files += [p for p in (root / 'moddev' / module / subtree).rglob('*') if p.is_file()]
for name in ['TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar', 'TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar']:
    files.append(root / 'mods' / name)
manifest = []
for p in files:
    rel = p.relative_to(root)
    dest = backup / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, dest)
    expected = sha256(p.read_bytes()).hexdigest().upper()
    assert sha256(dest.read_bytes()).hexdigest().upper() == expected
    manifest.append({'path': rel.as_posix(), 'sha256': expected})
for p in Path(r'D:\TFC农业重置\PCL_TFC\mods').glob('*Plus-NeoForge-1.21.1-0.1.0.jar'):
    dest = backup / 'pcl-mods' / p.name
    dest.parent.mkdir(exist_ok=True)
    shutil.copy2(p, dest)
    expected = sha256(p.read_bytes()).hexdigest().upper()
    assert sha256(dest.read_bytes()).hexdigest().upper() == expected
    manifest.append({'path': 'pcl-mods/' + p.name, 'sha256': expected})
(backup / 'backup-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
collector = root / 'moddev/inventory/visual-backlog-20261025/collect-current-references.py'
shutil.copy2(collector, out / collector.name)
(out / 'collector-provenance.json').write_text(json.dumps({'CopiedFrom': str(collector), 'SourceSHA256': sha256(collector.read_bytes()).hexdigest().upper(), 'UnmodifiedProjectReadOnlyScript': True}, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'BackupFiles': len(manifest), 'Backup': str(backup), 'Collector': str(out / collector.name)}, ensure_ascii=False))
