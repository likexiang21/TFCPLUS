from pathlib import Path
from hashlib import sha256
import json,csv
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;docs=r/'moddev/docs'
name='265-ar4aa-sunflower-whole-display-20261027.md'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,value):p.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
delivery=load(o/'delivery-manifest.json');a_hash=delivery['Packages'][0]['SHA256'];b_hash=delivery['Packages'][1]['SHA256']
assert '静态资源健康检查：通过' in (o/'health.log').read_text(encoding='utf-8-sig')
status='AR4-AA（2026-10-27）向日葵显示接线已静态交付：六龄/两格整株、花苞与花盘、野生和死株接入保存的自有素材，保留原生野草底座，盆栽改用完整矮株图。15份旧JSON修改、2份JSON新增，全部PNG/Java/食品/采收及B保持；18状态保护、21项检查、21/17/44安全复制、完整校验/418台账/构建/部署/体检通过，最终美术与实机未验，实际复杂度5/5。'
next_step='下一步AR4-AB：菠菜盆栽成熟阶段显示修复，预期复杂度4/5。核Firmalife实际UV和六阶段映射，保留已修栽培/野生/死株和食品图标，解决末两阶段共age4的成熟表现；不把旧白花图直接接回。按实际素材决定是否需要独立盆栽图，补保护和回退检查后构建交付。向日葵播种图标、盆栽重复阶段与最终外观继续在后续图标/美术复核，其他农业与AR5/最终TXT、233号整理均保留。'
doc=f'''# AR4-AA 向日葵完整显示链审查与修复

2026-10-27。接264号下一步。预期复杂度5/5，实际5/5。本片完成显示接线、离线查看、静态检查、构建和部署；最终美术及实机均未验，全农业尚未完成。

## 当前问题与解决方式

重新读取MyCrops、MyDoubleCropBlock、MyWildCrops及TFC公开接口对应行为：sunflower的singleStages=3、maxAge=5，age0～2单格、age3～5上下两格；野生注册为普通单格WildCropBlock；死株是DeadDoubleCropBlock。不存在top_2/top_3方块属性。Java、注册和这套生长/采收行为完全保留。

实际源原来是幼苗大麦、成熟甘蔗，野生大麦、成熟死株下半大麦上半玉米，盆栽六阶段大麦。当前源码、真实依赖和旧自有图逐一反查并渲染，不能沿用旧121号把贴图后缀当额外方块的建议。

本片使用保存的向日葵苗、茎叶与花盘图片，未生成或重绘任何PNG。栽培模型使用独立设计的两片中心茎叶面；两格相接，主茎不再显示为多根甘蔗。上半格增设花盘面，age3使用原绿色花苞，age4黄花、age5较大且棕色中心花盘。原*_top_2图片是上半格内花盘纹理，*_5_top_3在此用作花苞纹理，绝不增第三/四格。

候选最初只接整张花盘，茎叶挡住花盘下半，实看像黄色小帽，未采用。定位后茎叶止于上格y8，花盘从y8向上，UV只取原图有花的[4,4,12,12]，再重渲染三种俯角。没有为了衔接去改原始PNG的边缘或全局运行seam修图。

野生保持一格，成熟使用旧完整向日葵矮株图，幼株用自有age1；增加独立幼株模型。成熟主花面配下半叶面，避免整张花图交叉后出现多块花盘互相遮盖。父级继续tfc:block/wild_crop/crop，不覆盖槽1；原生wild_crop_grass及其四片草面/tintindex保留。草面是已安装TFC标准资源数据的原样复用，主作物几何为本项目独立设计；没有复制第三方业务代码。

成熟死株改为自有两格茎叶与顶部枯黄花盘，增加sunflower_top模型；原枯株图按UV分出茎叶和头部，原年轻枯株图保持。上格不再借玉米。破坏、成熟掉落与返种由原有代码和掉落表处理。

## 盆栽和种子边界

核对Firmalife Plantable.getTexture和QuadPlanterBlockModel/RenderUtils公开实现对应的数据含义：quad每株只读取一张图，不读取耕地两格模型。stages仍5，六个纹理入口改为自有age0、age1、age2、age2、完整野生矮株、完整野生矮株；种子、产物、数量、养分、盆类型等字段保持。

这里已去除大麦错图，成熟时可见完整矮株花朵；第2/3项（从0计数）和第4/5项各共图是本片明确保留的美术限制，未声称六项全部具有独立画面。精细的分龄盆栽美术仍待后续，不为显示修复改写Firmalife容器/生长代码。

播种种子模型仍为tfc:item/seeds/barley。保存的旧sunflower种子图是偏红碎粒，本片实看后未盲目接回，也未把食用籽图直接冒充新播种图。独立播种图列后续美术项。已修food/sunflower_harvest_v2及食品数据完全保持：hunger4、saturation1、decay_modifier0.5，不增加营养或榨油配方。

## 实际查看与兼容保护

查看AR4AA-live-textures、stored-textures、before-p28及候选；最终从正式src重新解析全部模型和依赖，输出并查看AR4AA-current-p28/p5/p70。六龄始终按整株看，野生两态、死株两态以及盆栽六入口共16格；另有mature-before-after同相机/同10px世界单位对照。

实际观察：原成熟株是一束紫褐甘蔗，没有花盘；当前成熟株为绿茎侧叶、顶部黄色且有棕色中心的花盘，age3顶部是绿色花苞；死株为褐色茎叶并保留枯色花盘。野生保留外围深绿原生草，正面可辨黄色花和棕色中心。俯视时竖直花面会变窄，沿面侧视有平面作物的边缘效果，未称为实体厚花模型。盆栽为原生单元大小的矮株花图，两个重复阶段仍可见。

预览中的两格合成模型仅在inventory，y16平移上半格用于审查，未把这个合成模型作为游戏新方块。盆栽预览只有单个种植单元，不含盆底，不代表真实温室、多株排列或生长交互验证。所有VisualAccepted/RuntimeVerified仍false。

新增sunflower-display-contract/files与audit-sunflower-display.ps1，覆盖21份显示JSON、19张旧PNG及12份玩法/Java输入；18个完整属性组合（crop12、dead4、wild2）都只有一条匹配路线。额外检查非退化面、合法角度、花盘与叶高度分离、盆栽阶段映射及B覆盖。正式verify调用该检查。

gen-crops新增SunflowerDisplayOnly，先完整检查再复制21份正式JSON到受限草稿；整树旧生成草稿末尾也会恢复这21份。其他分支和旧模板文字保持，保护既有六页说明/六行模板；没有发布全生成草稿或重建手册。262号整书176/174页差异继续待核。

## 检查和交付

施工前备份9173条目到moddev/backups/ar4aa-sunflower-display-20261027，每条复制核哈希；包含A/B源、工具、构建包、四旧安装包及根规则/当前文档。施工前再次核对源和工具未发生外部改动。

21项检查通过：1正确隔离版、17负例（甘蔗回退、花盘删除、叶挡花、虚构part、死株玉米、野生大麦/草覆盖、盆栽大麦/奖励改变、缺花图、闲置原图改动、食用籽/播种路线改变、B覆盖、Java分龄改变、非法角度和退化面），另3项安全复制。Sunflower21、Spinach17、ItemIcons44输出的路径及字节分别与正式源一致，均无额外PNG或玩法文件。

完整资源verify、418外部覆盖台账通过；A离线assemble成功，用时50秒，Java编译up-to-date。源/工具全量差异只有17份既有文件修改、5份新增（资源15改2增，工具2改3增），零删除，其他A/B源工具均与备份一致；所有原PNG、Java/B、食品/种子、掉落、气候、ID/NBT保持。

JAR精确差异15份JSON改、2份JSON增、零删除，与正式源字节相符，全部原包PNG保持。源及包内263张食品/种子图仍16×16；没有对方块/GUI/动画图集盲目缩放。当前A源5923、工具104，B源3107、工具19。482个参考blockstate/2839个模型应用均解析成功；87种栽培作物中仅使用TFC可见纹理的统计从74降为73，这只是来源统计，不是73个已确认故障；49树/196树叶状态仍为整块叶。

部署前核四旧安装包与备份一致，仅将新A复制到工作区mods和D:/TFC农业重置/PCL_TFC/mods。A三份SHA-256：{a_hash}。

B未构建/部署，三份仍为：{b_hash}。部署后完整静态健康检查通过；历史两张闲置透明图按原规则保留。

未启动游戏、未改存档、未重新打PCL ZIP。实机以后需正常播种，观察六龄及两格衔接，成熟采收和破坏任一半只结算一次，野生两态、死株成熟/幼态、盆栽完整花株、种子与食用籽区分，退出重进；这些结果不能由静态检查代替。封窑完整操作继续由用户负责。

## 证据、回滚及下一步

证据目录为moddev/inventory/sunflower-display-20261027，含备份/方案、当前引用、来源、候选/正式渲染、18隔离版和日志、3安全输出检查、源/包差异、构建/体检、交付哈希、当前队列。图片和字段限制均已记录，不把参考程序成功当玩家验收。

回滚先保存当前工作，再按备份恢复15份既有资源和gen-crops/verify，撤回本片2份新增模型及3份新增保护工具，删除源文件后clean build防旧文件残留；或恢复备份旧A（9218D5B069A013C2A616AD3603EE4D7CEE75999335346BC9D7284C271CC81B39）至两mods。B和存档无需迁移，不用旧整树生成器回滚。

{next_step}

用户要求的全农业自然语言TXT总结在全阶段完成后再出，本片不提前宣告全部农业完成。
'''
(docs/name).write_text(doc,encoding='utf-8')
p=docs/'217-agriculture-repair-next-phase-plan-20261023.md';text=p.read_text(encoding='utf-8-sig');old=next(line for line in text.splitlines() if line.startswith('**下一步AR4-AA：'))
text=text.replace(old,f'**{status}见[265号交接]({name})。**\n\n**{next_step}**');p.write_text(text,encoding='utf-8')
p=docs/'218-agriculture-audit-baseline-20261023.md';text=p.read_text(encoding='utf-8-sig')
text=text.replace('下一片AR4-AA向日葵两格显示链，预期5/5。','向日葵显示后续见265号；下一片AR4-AB菠菜盆栽，预期4/5。')
# Keep chronological statements as history; add the authoritative new entry.
text+=f'\n- **{status}** 见[265号]({name})。{next_step}\n';p.write_text(text,encoding='utf-8')
p=r/'README.md';text=p.read_text(encoding='utf-8-sig');text=text.replace('## 本地开发入口（更新于 2026-10-26）','## 本地开发入口（更新于 2026-10-27）')
text=text.replace('下一片AR4-AA向日葵完整两格显示链，预期5/5。',f'向日葵显示交付见[265号](moddev/docs/{name})。')
anchor='- [K3 烤炉计时与黄油蛋糕修复记录]';assert text.count(anchor)==1
text=text.replace(anchor,f'- [AR4-AA 向日葵整株显示与防回退](moddev/docs/{name})：两格茎叶/花盘、野生/枯株与盆栽错图修复，全部原图及玩法保持；21项检查、构建和两处部署/体检通过，实机与最终美术未验。附[同条件对照](moddev/inventory/sunflower-display-20261027/AR4AA-mature-before-after.png)及[下一步队列](moddev/inventory/sunflower-display-20261027/next-work-queue.csv)。播种图标、盆栽重复阶段仍待美术复核；下一片AR4-AB菠菜盆栽成熟显示，预期4/5。\n'+anchor);p.write_text(text,encoding='utf-8')
queue=load(r/'moddev/inventory/leafy-icons-second-20261026/next-work-queue.json')
for row in queue:
    if row['顺序']=='V04':row['当前状态']='AR4-AA显示接线静态交付，最终美术/实机未验';row['后续证据']='265号及sunflower-display-20261027';row['仍待后续']='播种图标仍为TFC大麦；盆栽2/3、4/5分别共图；平面花盘侧视及最终美术由用户评价'
    if row['顺序']=='V05':row['当前状态']='下一片AR4-AB，预期4/5'
    if row['顺序']=='V06':row['事项']='其余73种栽培、野生/死株/盆栽和种子';row['依据']='当前crop-visual-references.json与tfc-only-cultivated-crops.json；来源数量不是缺陷数'
save(o/'next-work-queue.json',queue)
keys=list(dict.fromkeys(key for row in queue for key in row))
with (o/'next-work-queue.csv').open('w',encoding='utf-8-sig',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=keys);writer.writeheader();writer.writerows(queue)
save(o/'visual-observations.json',{'ActualViewed':['AR4AA-live-textures.png','AR4AA-stored-textures.png','AR4AA-before-p28.png','AR4AA-candidate-p28.png','AR4AA-candidate-p5.png','AR4AA-candidate-p70.png','AR4AA-current-p28.png','AR4AA-current-p5.png','AR4AA-current-p70.png','AR4AA-mature-before-after.png'],
     'Observation':'原图显示大麦/紫褐甘蔗；当前整株有绿茎侧叶、顶部绿苞或黄色棕心花盘，枯株保留枯色花盘。野生保留原生外围草，盆栽为矮株花；重复阶段和竖面侧视效果待用户评价。',
     'RejectedCandidateIssue':'第一次花盘被上半茎叶挡成黄色小帽，缩短上部叶面并按实际花盘区域取UV后重看；首次候选缺PNG仅为离线导出遗漏，未接入源。',
     'VisualAccepted':False,'RuntimeVerified':False})
print('265 and README/217/218/current queue updated; next AR4-AB, expected 4/5.')
