from pathlib import Path
from hashlib import sha256
import json, shutil

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
backup = root / 'moddev/backups/ar4ac-swiss-harvest-20261027'
backup.mkdir(exist_ok=False)
(out/'work-plan.txt').write_text('AR4-AC，预期4/5。70号将牛皮菜列普通单格、当前MyCropBlock一致，无专属采摘退龄；中文手册和中英文生成表错误宣称割后再生。先备份并核哈希；只修中英文牛皮菜文字页和两生成表该行，再将两页/两行纳入已有图标/说明保护。页序/示意图/跳转、所有玩法/Java/PNG/B保持。隔离回退、八保护页/八模板、受限整书草稿只比目标不发布、完整verify/台账/构建/包差异后部署A。267交接及当前计划更新，实机延期，新贴图原版参考规则保持。',encoding='utf-8')
paths = [root / x for x in ['README.md','AGENTS.md','INBOX.md','DEVELOPMENT_RULES.md','moddev/tfcagricultureplus/OVERRIDE-REGISTRY.md']]
docs = root / 'moddev/docs'
paths += [p for p in docs.glob('*.md') if p.name.startswith(('217-', '218-', '253-', '254-', '255-', '256-', '257-', '258-', '259-', '260-', '261-', '262-', '263-', '264-', '265-', '266-'))]
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
