from pathlib import Path
from hashlib import sha256
import json, shutil

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
backup = root / 'moddev/backups/ar4w-nut-icons-20261026'
backup.mkdir(exist_ok=False)
names = ['almond', 'hazelnut', 'macadamia', 'pecan', 'walnut']
(out / 'work-plan.txt').write_text('''AR4-W，预期复杂度5/5。输入：五坚果注册、食品、采收/盆栽/用途、原图、模型、260号及图标保护合同。
计划修改五个models/item/food/{almond,hazelnut,macadamia,pecan,walnut}.json和tools/reviewed-item-icon-routes.json，新增五张独立16×16透明harvest_v1候选。所有原PNG、食品/腐烂、Java、B、掉落/采收/树体、ID/NBT/存档不改。
先逐文件备份并核哈希。内置image_gen逐物种制作，原稿单独保留，等比最近邻导出；查看原生尺寸和放大图，不合适就重试留档。
输出：五模型接线、新图、保护合同、分诊/证据、261号交接和README/217/218状态。
完成：旧图/供体回退、缺图、B覆盖、食品数据改变和尺寸负例被拦下；安全复制仅规范模型JSON；完整检查/台账/离线构建通过；JAR仅五模型改、五PNG新增；核旧包后部署A到两mods，B不变。实机/最终美术待验，不启动游戏、不打PCL包、不提前做233号整理或最终农业TXT。
''', encoding='utf-8')
paths = [root / x for x in ['README.md','AGENTS.md','INBOX.md','DEVELOPMENT_RULES.md','moddev/tfcagricultureplus/OVERRIDE-REGISTRY.md']]
docs = root / 'moddev/docs'
paths += [p for p in docs.glob('*.md') if p.name.startswith(('217-', '218-', '253-', '254-', '255-', '256-', '257-', '258-', '259-', '260-'))]
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
