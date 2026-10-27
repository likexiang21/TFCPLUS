"""Reconcile reviewed semantic groups, current visual references and old backlog."""
from pathlib import Path
from hashlib import sha256
from collections import Counter
from zipfile import ZipFile
import csv, json

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
a = root / 'moddev/tfcfarmingplus/src/main/resources'
b = root / 'moddev/tfcagricultureplus/src/main/resources'

def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def save(name, data):
    (out / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def table(name, rows):
    fields = list(dict.fromkeys(k for row in rows for k in row))
    with (out / name).open('w', encoding='utf-8-sig', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: json.dumps(value, ensure_ascii=False) if isinstance(value, (dict, list)) else value for key, value in row.items()})

products = load(out / 'product-semantics-evidence.json')
nuts = ['almond', 'hazelnut', 'macadamia', 'pecan', 'walnut']
food_findings = {
    'almond': ('当前图像呈桃形，不是杏仁辨识', '沿用现有food/almond可食用坚果产物；新图表现杏仁，不增加去壳状态'),
    'hazelnut': ('当前图像呈双樱桃形，不是榛子辨识', '沿用现有food/hazelnut；新图表现榛子'),
    'macadamia': ('当前图像呈柠檬形，不是夏威夷果辨识', '沿用现有food/macadamia；新图表现夏威夷果'),
    'pecan': ('当前图像呈橙子形，不是碧根果辨识', '沿用现有food/pecan；新图表现碧根果'),
    'walnut': ('当前图像呈绿苹果形，不是核桃辨识', '沿用现有food/walnut；新图表现核桃'),
    'agave': ('当前为甜菜，保存图仍红色根形；不适合直接接回', '历史70号产物为agave_heart，当前ID/成熟结果态及模板仍支持中心收获物方向；绘制龙舌兰心候选，不创建新ID或擅加榨汁配方'),
    'sunflower': ('当前大麦穗，保存图为完整花盘；食品与播种种子为不同ID', '70号明确sunflower_seed，现说明籽，按可食用葵花籽表现food/sunflower；保留seeds/sunflower播种用途，不画成整朵花或擅改食品数值'),
    'rhubarb': ('当前黄豆荚，保存图为泛黄细长形；未表现手册明确的叶柄', '当前中英文手册明确食用叶柄；采用红绿叶柄候选，不表现可食叶片，不改现有采摘行为')
}
verdicts = []
for row in products:
    observation, action = food_findings[row['Name']]
    verdicts.append({'编号': 'VF-' + row['Name'], '物种': row['Name'], '名称': row['ChineseName'], '物品ID': row['ItemID'],
                     '当前纹理': row['CurrentTexture'], '图像观察': observation, '产物语义与动作': action,
                     '状态': '确认图像内容错配；待独立美术', '下一批': 'AR4-W' if row['Name'] in nuts else '后续三项特殊产物图标',
                     '保留': 'ID、原PNG、食品/腐烂值、成熟收获与现有用途', '本片修改游戏资源': False, '实机通过': False})
save('product-verdicts.json', verdicts)
table('product-verdicts.csv', verdicts)

triage = load(root / 'moddev/inventory/remaining-food-icons-20261026/item-icon-triage.json')
refs = load(root / 'moddev/inventory/remaining-food-icons-20261026/current-item-icon-references.json')
shared = ['arugula', 'garland_chrysanthemum', 'lettuce', 'mustard_greens', 'perilla', 'purslane', 'spinach', 'swiss_chard']
viewed = set(nuts + ['agave', 'sunflower', 'rhubarb'] + shared)
for row in triage:
    row['ReviewedInAR4V'] = row['Family'] == 'food' and row['Name'] in viewed
    row['AR4VVisualAccepted'] = False
    row['AR4VRuntimeVerified'] = False
    if row['Family'] == 'food' and row['Name'] in food_findings:
        row['AR4VPriorStatus'] = row['Status']
        row['Status'] = 'AR4-V确认图像内容错配；待独立美术'
        row['AR4VObservation'], row['AR4VNextAction'] = food_findings[row['Name']]
    elif row['Family'] == 'food' and row['Name'] in shared:
        row['AR4VObservation'] = '本片实际查看；当前同用kale叶束，优于保存根/果图，但物种区分不足；不是新的断链或最终美术验收'
        row['AR4VNextAction'] = '按实际叶形逐项制作独立16×16候选；保留旧PNG和共享暂代直到候选合格'
    path = a / 'assets/tfcfarmingplus/models/item' / row['Family'] / (row['Name'] + '.json')
    # Family is "seeds" in the source-derived inventory.
    assert path.exists(), path
    assert sha256(path.read_bytes()).hexdigest().upper() == row['CurrentSourceModelSha256'], path
save('item-icon-triage.json', triage)
table('item-icon-triage.csv', triage)
save('current-item-icon-references.json', refs)

crop_data = load(out / 'crop-visual-references.json')
crops = crop_data['Crops']
tfc_only = [r for r in crops if r['Textures'] and all(t.startswith('tfc:') for t in r['Textures'])]
save('tfc-only-cultivated-crops.json', tfc_only)
table('tfc-only-cultivated-crops.csv', tfc_only)
planters = []
for path in sorted((a / 'data/firmalife/firmalife/plantable').glob('*.json')):
    data = load(path)
    planters.append({'Path': path.relative_to(root).as_posix(), 'SHA256': sha256(path.read_bytes()).hexdigest().upper(),
                    'Ingredient': data.get('ingredient'), 'Crop': data.get('crop'), 'Stages': data.get('stages'), 'Textures': data.get('textures', []),
                    'VisualAccepted': False, 'RuntimeVerified': False})
save('planter-display-references.json', planters)
spinach = next(r for r in planters if r['Path'].endswith('/spinach.json'))
assert spinach['Stages'] == 5 and len(spinach['Textures']) == 6 and spinach['Textures'][-1] == spinach['Textures'][-2]

old = load(root / 'moddev/inventory/visual-backlog-20261025/remaining-visual-backlog.json')['Items']
changes = {
    'VK01': ('部分已修；剩余逐物种复核', '87种中现74种栽培可见面仅TFC，较K减少辣椒/葫芦巴/菠菜三种；不是74个玩法故障。', '优先向日葵整株，再按形态分批核候选、UV和野生/死株/盆栽。'),
    'VK02': ('AR4-L已修复；待实机/最终美术', '辣椒完整显示链已由250号修复，当前含自有六龄、野生/死株、种子及盆栽。', '保护当前接线，保留用户实机。'),
    'VK03': ('AR4-M已修复；待实机/最终美术', '葫芦巴完整显示链已由251号修复；不再写作当前仍用兵豆的待施工项。', '保护当前接线及原生TFC种子图集复用，保留实机。'),
    'VK04': ('两项自有种子已接入；其余按语义复核', '87种子模型中85取TFC、2取自有；食品修图不等于种子修图。', '共享散粒可复用，先查辨识需求，不把85条全部判错。'),
    'VK05': ('三物种已修；其余仍待分批核', '辣椒/葫芦巴/菠菜盆栽已接入本物种图；菠菜末两个纹理项同用age4，成熟辨识未收口。', '随生命周期复核盆栽；菠菜先看六龄候选并渲染，不直接接旧age5白花。'),
    'VK06': ('已修物种保留；其余逐物种核', '五叶菜及辣椒/葫芦巴/菠菜等已有修订；当前扫描自有wild_crop与dead_crop实际消费者数量见最新统计，非全部完工。', '逐物种核幼态/成熟、父模型、UV和角度，不能因存图存在就上线。'),
    'VK07': ('27种双段/攀爬整株仍待视觉核对', '仍98条纹理配对及边界差异；旧像素边界检查不能自动判定接缝缺陷。', '先向日葵两格，依据实际part/年龄/几何/UV整株查看，不用-Fix凑像素。'),
    'VK08': ('当前替代显示与图标内容待修', '向日葵仍两格，成熟top取sugarcane；食品取barley、存图整花；70号和说明支持籽产物。', '食品独立葵花籽图；植株另片做bottom/top花盘和整株，不加第三格；榨油说明与未实现长链要分开。'),
    'VK17': ('旧问题部分已替代；长尾保留', '菠菜旧白花显示已由252号接线修复，末期盆栽同图仍待改善；其余边界物种须按现有引用看。', '不恢复菠菜旧白花；蒿菜/丝瓜/姜黄/马齿苋等依当前源逐批核。'),
    'VK18': ('当前已审路线受保护；历史全量模板仍受限', '已有三物种完整显示保护和35食品/种子图标路线保护、16×16目录检查；历史模板仍含供体输出。', '每一新批同步合同/安全复制和反例，禁止整树旧草稿发布。'),
    'VK22': ('农业长链/AR5/最终TXT及233号均保留', '现有基础用途已接入，但10非小麦谷物专属磨粉、三油料榨油、完整沤麻纺织和饮品等仍有后续边界。', '按需求与依赖真实缺口分批排期；最终农业TXT待全农业收尾，233号在全部既定工作后。')
}
for row in old:
    row['AR4K历史状态'] = row['状态']
    row['AR4K历史事实'] = row['当前事实']
    if row['编号'] in changes:
        row['状态'], row['当前事实'], row['下一动作'] = changes[row['编号']]
    else:
        row['状态'] += '；本片未新增该项视觉验收'
    row['本片证据'] = '260号；当前crop/blockstate/texture/planter清单；旧图观察仍按249号证据边界'
    row['实机通过'] = False
save('remaining-visual-backlog.json', {'Scope': 'AR4-V current-source reconciliation; historical observations not re-accepted', 'Items': old})
table('remaining-visual-backlog.csv', old)

queue = [
    ('V01', '五种坚果食品图标', 'AR4-W', '5/5', '五张独立16×16坚果候选、五模型、合同与尺寸/负例/构建交付；不改ID/食品/去壳流程', 'product-verdicts.json；AR4V-nuts-p1/p2'),
    ('V02', '大黄、向日葵、龙舌兰食品图标与准确说明', 'W后', '5/5', '叶柄、食用籽、中心收获物三图；保留播种ID和所有玩法，核文案不宣称未开发榨油已可用', 'product-semantics-evidence.json；70号；237号'),
    ('V03', '八种共享叶束的物种辨识', '随后分两批', '每批5/5', '芝麻菜/茼蒿/芥菜/紫苏及生菜/菠菜/牛皮菜/马齿苋；逐张16×16观察、独立美术后才替代共享图', 'AR4V-shared-leaf-p1/p2；当前分诊'),
    ('V04', '向日葵两格完整显示链', '生命周期首片', '5/5', '按当前6龄/part核整株、花盘、野生/死株/种子与盆栽；禁止虚造第三/四格', 'crop-visual-references.json；VK07/VK08'),
    ('V05', '菠菜盆栽成熟阶段与其他已修形态尾项', '与生命周期交叉推进', '4/5', '末两项共age4的改进需核候选/UV/实际阶段；保留已修白花接线与几何裁决', 'planter-display-references.json；252号'),
    ('V06', '其余74种栽培、野生/死株/盆栽和种子', '按形态分批', '每片4～5/5', '先可采摘/单格/莲座样板，再双格攀爬、水生/蔓延；来源复用不自动是缺陷，保持完整物种链', 'tfc-only-cultivated-crops.csv；VK01/VK04/VK06'),
    ('V07', '49树类和12灌木的外观长尾', '作物样板后', '每片4～5/5', '按物种对现图/连冠/花果；49树含旧cocoa兼容，保留整块叶和允许的树皮复用', 'tree-leaf-cubes.json；VK11～VK15'),
    ('V08', '完整农业加工长链边界', '结合需求另切片', '5/5', '10非小麦谷物磨粉、三油料榨油、沤麻纺织与饮品等，先核已有依赖与实际新增需求', '236～238号；VK22'),
    ('V09', 'AR5综合验收、交付及最终农业TXT', '当前开发收尾后', '5/5', '汇总保护与实机清单，用户延期继续遵守；仅全阶段完成后出最终总结', '217号AR5；VK21/VK22'),
    ('V10', '变量/文件命名与结构整理', '全部既定工作后', '5/5', '233号计划，先新旧映射，保护注册与存档，不提前施工', 'DEVELOPMENT_RULES；233号')
]
queue_rows = [{'顺序': x[0], '事项': x[1], '安排': x[2], '任务预期复杂度': x[3], '完成判据与边界': x[4], '依据': x[5]} for x in queue]
save('next-work-queue.json', queue_rows)
table('next-work-queue.csv', queue_rows)

resources = []
for module in ['tfcfarmingplus', 'tfcagricultureplus']:
    jar_name = 'TFCFarmingPlus-NeoForge-1.21.1-0.1.0.jar' if module == 'tfcfarmingplus' else 'TFCAgriculturePlus-NeoForge-1.21.1-0.1.0.jar'
    base = root / 'moddev' / module / 'src/main/resources'
    with ZipFile(root / 'mods' / jar_name) as archive:
        paths = [p for p in base.rglob('*') if p.is_file()]
        differences = [p.relative_to(base).as_posix() for p in paths if p.relative_to(base).as_posix() not in archive.namelist() or archive.read(p.relative_to(base).as_posix()) != p.read_bytes()]
        resources.append({'Module': module, 'SourceResourcesCompared': len(paths), 'Differences': differences})
save('source-installed-resource-comparison.json', resources)

provenance = load(out / 'texture-provenance.json')
visible = {directory: sum(r['UsedByScannedBlockstates'] for r in provenance if '/textures/' + directory + '/' in r['Path']) for directory in ['block/crop', 'block/wild_crop', 'block/dead_crop', 'block/fruit_tree']}
textures = [texture for row in planters for texture in row['Textures']]
summary = {'CropSpecies': len(crops), 'TFCOnlyCultivatedSpecies': len(tfc_only), 'OwnTextureCultivatedSpecies': len(crops)-len(tfc_only),
           'TreeKindsIncludingLegacy': 49, 'BushKindsPer234': 12,
           'FoodSeedModelsReconciled': len(triage), 'FoodModelsViewedThisSlice': 16, 'NewlyConfirmedFoodArtMismatches': 8,
           'SharedLeafFoodModels': shared, 'SeedTextureNamespaces': load(out / 'reference-summary.json')['SeedTextureNamespaces'],
           'PlanterDefinitions': len(planters), 'PlanterTextureItems': len(textures), 'PlanterTextureNamespaces': dict(Counter(t.split(':')[0] for t in textures)),
           'SpinachPlanterLastTwoTextureItemsEqual': True, 'OwnTexturesUsedByScannedBlockstates': visible,
           'HistoricalVisualItemsReconciled': len(old), 'QueueItems': len(queue_rows),
           'AllSourceResourceComparisonsEqual': all(not r['Differences'] for r in resources),
           'GameSourceOrToolsChanged': False, 'BuildRun': False, 'DeployRun': False, 'GameLaunched': False,
           'RuntimeVerified': False, 'VisualAccepted': False, 'AgricultureComplete': False}
save('status-summary.json', summary)
print(json.dumps(summary, ensure_ascii=False))
print(json.dumps(resources, ensure_ascii=False))
