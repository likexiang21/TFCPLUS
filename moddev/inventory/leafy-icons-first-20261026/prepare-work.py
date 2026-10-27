from pathlib import Path
from hashlib import sha256
import json, shutil

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
backup = root / 'moddev/backups/ar4y-leafy-icons-first-20261026'
backup.mkdir(exist_ok=False)
names = ['arugula', 'garland_chrysanthemum', 'mustard_greens', 'perilla']
(out / 'work-plan.txt').write_text('AR4-Y，预期复杂度5/5。输入：四现有叶菜food注册、食品/掉落/用途/手册、kale共享图标和旧同名图、43路线及六页/六模板合同。先全量备份逐文件核哈希。\n仅修改四个食品模型及图标合同，新增四独立16×16透明图，不改原PNG、Java/B、食品/腐烂、标签/配方、生长/采收、种子、植株、盆栽、手册、生成工具业务或ID/NBT/存档。\n使用内置image_gen，原稿单独保留，最近邻等比导出，先看16×16及放大候选再采用；低辨识候选另留重试。\n输出263号、当前分诊/来源/提示词/尺寸/源包差异和README/217/218。四共享/旧图/串图/缺图及B覆盖、食品、前片、尺寸、六说明/模板回退负例和43份安全复制通过，完整verify/台账/构建后核JAR仅四模型改、四图新增，再部署A到两mods，B保持。全农业与最终TXT/233号未完成，实机仍延期。\n', encoding='utf-8')
paths = [root / x for x in ['README.md','AGENTS.md','INBOX.md','DEVELOPMENT_RULES.md','moddev/tfcagricultureplus/OVERRIDE-REGISTRY.md']]
docs = root / 'moddev/docs'
paths += [p for p in docs.glob('*.md') if p.name.startswith(('217-', '218-', '253-', '254-', '255-', '256-', '257-', '258-', '259-', '260-', '261-', '262-'))]
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
