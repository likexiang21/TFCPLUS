from pathlib import Path
from hashlib import sha256
import json, shutil

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
backup = root / 'moddev/backups/ar4z-leafy-icons-second-20261026'
backup.mkdir(exist_ok=False)
names = ['lettuce', 'spinach', 'swiss_chard', 'purslane']
(out / 'work-plan.txt').write_text('AR4-Z，预期复杂度5/5。先全量备份逐文件核哈希。四叶菜：生菜/菠菜/牛皮菜/马齿苋，当前共享kale食品图。计划改四食品模型、统一图标合同及spinach-display-contract的食品入口/新PNG保护，新增四16×16独立候选。所有原PNG、食品/腐烂、Java/B、种子/植株/盆栽、ID/NBT、手册及模板保持。\n菠菜原食品未在统一合同，须新增路线及食品/旧图保护，同时保留原完整显示链其他约束。目标统一44模型/81PNG/41食品，菠菜13PNG；双保护一致。\n内置image_gen逐图生成，保留原稿/来源/提示词，最近邻等比导出，实际看原生16×16再采用；未合格者重试留档。共享/旧图/串图/缺图/B覆盖/食品/前片/尺寸/说明/模板负例、44安全模型及17菠菜安全JSON复制、完整verify/台账/构建通过，核JAR恰四模型改/四PNG新增后仅部署A到两mods。\n输出264号和README/217/218与当前分诊；实机和最终美术仍未验，全农业TXT与233号延期，整书草稿不发布。\n',encoding='utf-8')
paths = [root / x for x in ['README.md','AGENTS.md','INBOX.md','DEVELOPMENT_RULES.md','moddev/tfcagricultureplus/OVERRIDE-REGISTRY.md']]
docs = root / 'moddev/docs'
paths += [p for p in docs.glob('*.md') if p.name.startswith(('217-', '218-', '253-', '254-', '255-', '256-', '257-', '258-', '259-', '260-', '261-', '262-', '263-'))]
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
evidence = []
(out/'product-semantics-evidence.json').write_text(json.dumps([r for r in evidence if r['Name'] in names],ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'BackupEntries':len(manifest),'Backup':str(backup),'Products':names},ensure_ascii=False))
