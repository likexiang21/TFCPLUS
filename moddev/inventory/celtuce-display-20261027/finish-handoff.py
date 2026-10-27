from pathlib import Path
from hashlib import sha256
import csv,json,re

o=Path(__file__).resolve().parent;r=o.parents[2];docs=r/'moddev/docs'
name='270-ar4af-celtuce-native16-display-20261027.md'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert '静态资源健康检查：通过' in (o/'health.log').read_text(encoding='utf-8-sig')
native=[v['Name'] for v in load(o/'crop-visual-references.json')['Crops'] if v['Textures'] and all(t.startswith('tfc:') for t in v['Textures'])]
assert len(native)==70
save(o/'tfc-only-cultivated-crops.json',{'Count':len(native),'Species':native,'SourceReuseAloneIsNotDefect':True})
packages=load(o/'delivery-manifest.json')['Packages'];assets=load(o/'asset-manifest.json')['Assets']
checks=load(o/'check-results.json');assert len(checks)==24 and all(v['Passed'] for v in checks)
backup=r/'moddev/backups/ar4af-celtuce-display-20261027';backup_count=len(load(backup/'backup-manifest.json'))
counts={f'{module}/{folder}':sum(p.is_file() for p in (r/'moddev'/module/folder).rglob('*')) for module in ['tfcfarmingplus','tfcagricultureplus'] for folder in ['src','tools']}
elapsed=re.search(r'BUILD SUCCESSFUL in (.+)',(o/'build-a.log').read_text(encoding='utf-8-sig')).group(1)
status='AR4-AF莴笋完整显示静态交付：六龄、野生两态、枯株两态及盆栽接线，八份原生16格像素稿，64仅工作区预览；24项检查、完整verify/418覆盖/构建/两处部署/体检通过，实机与最终美术未验。预期/实际复杂度5/5。'
next_step='下一步AR4-AG：大黄（rhubarb）完整显示链审查与必要修复，预期复杂度5/5。当前成熟模型仍借用soybean_5；先核当前玩法和保存图、已安装TFC同族参考，再审六龄/野生/枯株/盆栽及食品接线。红叶柄/绿叶的外观与牛皮菜区分，保护已修食品和既定采收逻辑；新图16格起稿、64仅预览。'
paths='\n'.join('- `'+v['FinalPath']+'`' for v in assets)
doc=f'''# AR4-AF 莴笋完整显示与原生16格贴图

2026-10-27。接269号，任务预期复杂度5/5，实际5/5。显示资源、保护检查、构建和部署已完成；最终美术和玩家实机未验。没有启动游戏、改存档或制作PCL压缩包。

## 当前问题与修改依据

本轮检查的栽培六龄、野生/死株、Firmalife六龄盆栽均借用TFC洋葱素材；幼野生直接引用dead_crop/onion_young，实际离线渲染呈褐色死苗。原栽培模型四片分散竖面在预览中表现成几根洋葱叶，成熟下部有亮色洋葱基部。

逐张查看保存的旧图：幼苗为浅绿点，中龄为顶端空心叶环和一根长柄，age3与4外形接近，成熟像数根细柱；野生/枯株为两根宽长柱。旧食物像圆洋葱，旧种子像根菜。未盲接这些同名图。既有食品模型继续用celtuce_stem_v1，种子仍借用TFC onion种子，未将食品图替代播种图。

参考已安装TFC JAR的onion0～5、carrot0～4、soybean0～5、原生野生草模型和贴图，导出路径及SHA256见native-reference-manifest.json，逐像素结构记录见native-pixel-dumps.txt。实际查看原版接触表和真实模型，学习幼苗稀疏度、器官延续和深浅叶片；没有复制第三方模组业务代码，没有靠原版换色生成本轮新图。

株形依据[康奈尔大学Celtuce品种说明](https://www.vegvariety.cce.cornell.edu/main/detail.php?variety_id=4752)中的食用粗茎和嫩叶；[佛罗里达大学推广资料](https://www.growables.org/informationVeg/documents/Celtuce.pdf)用于辨认中央伸长茎和外叶。此处只学习外观，未据现实资料新增抽薹、生长温度、气候、再生或收获机制。普通单格六龄和原有整株采收规则不变。

## 原生16格资源与模型

逐图编写八份16行×16列可编辑像素稿：六龄、成熟枯株和幼苗枯株。每一格直接指定颜色/透明位置，没有套参数批量绘制形状，没有调用AI画图或把高分辨率图缩小冒充16格原稿。pixel-source-16为绘制依据，native-grid-png为16×16原图，preview-64是四倍最近邻预览，逐像素对应。

正式路径如下；本片《贴图文件路径.txt》另逐张列出正式原图、64预览及可编辑稿绝对路径：

{paths}

六龄和两枯株采用两个居中垂直竖面，整张UV、面轴和合法旋转已核；成熟外观为中央较粗浅绿茎，两侧不同高度的深浅绿叶。与上一片芹菜的多根叶柄分开设计，未共用植株剪影。

野生两态复用第5/1龄，幼年不再是死洋葱；继承TFC野生父模型并保留四片外围原版草、tintindex及槽1，不自造/覆盖原版草。盆栽保持quad、stages5、原有养分/种子/产物及六入口，新图主体位于UV[2,0,14,16]可见列内。

实际查看八图16格接触表及正式src解析的p28、p5、p70，16格内容包含六龄、两野生、两枯株、六盆栽。幼株长为明显中央粗茎与两侧叶，成熟高于中龄，枯株褐色；低角度中央茎因两面叠加显得更厚，俯视竖直面变窄，野生幼苗会被原版外围草部分遮挡。盆栽预览未包含盆体。离线观察不等于用户美术认可或实际游戏操作通过。

## 保护与验证

施工前完整备份{backup_count}条目至moddev/backups/ar4af-celtuce-display-20261027，逐项核SHA256，接入前再核A/B源与工具无外部修改。本轮保留全部旧PNG、食品/播种/野生物品模型、栽培与死株blockstate、Java、注册ID、NBT、食物/掉落/气候/世界生成及B模块。

新增celtuce-display-contract/files与audit-celtuce-display，保护17份显示JSON、20张新旧PNG、12份玩法/Java输入，覆盖10状态和原版野生草依赖。verify接入新保护，gen-crops新增CeltuceDisplayOnly，复制前完整预检；完整旧草稿结尾也恢复莴笋正式显示，不发布全量旧草稿。

24项检查通过：16个隔离fixture（正确版及15负例：洋葱图回退、缺图、64替换原图、额外64误进资源、旧图变动、幼野生回死洋葱、丢野生父级/草槽被改、B覆盖A或原版、掉落/盆栽/Java年龄变动、空几何/退化面）；6种安全复制（17莴笋/17芹菜/17牛皮菜/21向日葵/17菠菜/44物品图标JSON），路径与字节完全等于正式源；八份16格原稿/64预览对应；历史textures.zip未入JAR且既有构建排除配置未变。

完整verify通过：索引模型16457/贴图7183；A资源blockstate481/模型2086/掉落481/configured246/placed246/物品435，引用均有效。418覆盖台账、44图标/81PNG/41食品保护通过。当前482参考blockstate/2839模型应用均解析成功，49树/196叶状态继续为整块。A源共1809张PNG，均16×16；B的18×18GUI槽按自身界面规格保留。

A离线assemble成功（{elapsed}），Java up-to-date。精确JAR差异11份既有JSON修改、1幼野生模型及8张PNG新增，零删除，全部新图16×16且与源相同；原包所有PNG字节保持，64预览/像素稿/草稿未入包。A/B源码和工具恰13既有文件修改、12新增，其余均保持。源/工具实际数量：{counts}。

A部署至工作区mods及D:/TFC农业重置/PCL_TFC/mods，与build/libs三份SHA256为{packages[0]['SHA256']}。B三份仍为{packages[1]['SHA256']}。静态健康检查通过。保留269号修复的textures.zip排除规则，源码历史压缩包保留，本轮没有修改构建配置。

## 实机待验与回滚

后续实际播种并观察六龄、成熟整株收获/返种重播、野生两态、两枯株、盆栽六龄和重进存档；最终美术需用户另行确认。封窑完整测试继续由用户负责，VisualAccepted/RuntimeVerified均false。

回滚前保存现状，恢复备份的11份既有显示JSON及gen-crops/verify，先另存后撤回9份新增源资源与3份保护工具，删除资源后clean build防残留。也可将旧A（6D9C304D9C5431973CFC4F3DE3A57D21872AA82F8825EC113AE1DEA969A7C3F5）恢复至两mods。原图与像素稿保留，B/存档无需迁移，既有压缩包排除规则不撤销。

## 下一步

{next_step}

仅使用TFC可见纹理的栽培来源统计由71降70，仅说明素材来源，不是70个确定故障。其余种子、向日葵盆栽、树/灌木、加工与AR5继续保留既定队列。完整农业自然语言TXT总结及233号全局命名/结构整理仍在全部既定工作完成后开展。
'''
(docs/name).write_text(doc,encoding='utf-8')
p=docs/'217-agriculture-repair-next-phase-plan-20261023.md';text=p.read_text(encoding='utf-8-sig');oldline=next(x for x in text.splitlines() if x.startswith('**下一步AR4-AF：'));text=text.replace(oldline,f'**{status}见[270号]({name})。**\n\n**{next_step}**');p.write_text(text,encoding='utf-8')
p=docs/'218-agriculture-audit-baseline-20261023.md';text=p.read_text(encoding='utf-8-sig');oldline=next(x for x in text.splitlines() if x.startswith('> **2026-10-27当前入口：**'));tail='下面AR0'+oldline.split('下面AR0',1)[1] if '下面AR0' in oldline else '';text=text.replace(oldline,f'> **2026-10-27当前入口：**AR4-AF莴笋原生16格显示静态交付，见[270号]({name})；实机/最终美术未验。下一片AR4-AG大黄显示链，预期5/5。{tail}');text+=f'\n- **{status}** 见[270号]({name})。{next_step}\n';p.write_text(text,encoding='utf-8')
p=r/'README.md';text=p.read_text(encoding='utf-8-sig').replace('下一片AR4-AF莴笋完整显示链，预期5/5。',f'莴笋显示已静态交付，见[270号](moddev/docs/{name})。');anchor='- [K3 烤炉计时与黄油蛋糕修复记录]';assert text.count(anchor)==1;text=text.replace(anchor,f'- [AR4-AF 莴笋原生16格完整显示](moddev/docs/{name})：六龄/野生/枯株/盆栽；八份16格新稿、64仅工作区预览；24项检查、构建/两处部署/体检通过，最终美术与实机待验。附[贴图路径](moddev/inventory/celtuce-display-20261027/贴图文件路径.txt)、[原图一览](moddev/inventory/celtuce-display-20261027/AR4AF-native16-authored.png)、[实际源模型预览](moddev/inventory/celtuce-display-20261027/AR4AF-current-p28.png)。下一片AR4-AG大黄完整显示链，预期5/5。\n'+anchor);p.write_text(text,encoding='utf-8')
queue=load(r/'moddev/inventory/celery-display-20261027/next-work-queue.json')
for row in queue:
    if row['顺序']=='V06':row['事项']='其余70种栽培、野生/死株/盆栽和种子';row['当前状态']='AR4-AF莴笋显示静态交付；下一片AR4-AG大黄完整显示链，预期5/5';row['后续证据']='270号与celtuce-display-20261027；新图16格起稿/64仅预览'
save(o/'next-work-queue.json',queue);keys=list(dict.fromkeys(k for row in queue for k in row))
with (o/'next-work-queue.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=keys);w.writeheader();w.writerows(queue)
save(o/'visual-observations.json',{'SourceGrid':[16,16],'PreviewOnly':[64,64],'ImagegenUsed':False,'ViewedNativeGrid':True,'ViewedThreeAnglesCurrentSource':True,'Observation':'中央浅绿粗茎，两侧不同高度绿叶；成熟增高，枯株褐色；低角度中央茎较厚，俯视竖面变窄，幼野生受外围草遮挡。','VisualAccepted':False,'RuntimeVerified':False})
print('270 handoff/current entry/queue written; next AR4-AG rhubarb5/5.')
