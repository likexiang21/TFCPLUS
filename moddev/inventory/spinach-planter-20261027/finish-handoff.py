from pathlib import Path
from hashlib import sha256
import json,csv
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;docs=r/'moddev/docs'
name='266-ar4ab-spinach-planter-mature-20261027.md'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert '静态资源健康检查：通过' in (o/'health.log').read_text(encoding='utf-8-sig')
delivery=load(o/'delivery-manifest.json');asset=load(o/'asset-manifest.json');a_hash=delivery['Packages'][0]['SHA256']
status='AR4-AB（2026-10-27）菠菜盆栽成熟显示静态交付：参考已安装TFC四种原版作物，新添一张16×16成熟叶株图，仅替换盆栽最后纹理；原作物/野生/死株、食品、种子与玩法保持。15项检查、17/21/44安全复制、完整资源校验/418台账、构建/部署/体检通过，最终美术及实机未验；预期/实际复杂度4/5。'
next_step='下一步AR4-AC：牛皮菜采收说明与生命周期一致性复核，预期复杂度4/5。重读基本需求、当前注册/采收和中英文手册，核“割了还会再长”具体含义，再按证据修正文案或登记确需处理的行为；不能仅凭文字歧义就新增反复采收。若涉及全龄美术再单独预估，绘图继续先看原版。其余73种来源统计、种子/向日葵盆栽美术、树/灌木、加工闭环与AR5仍保留。'
doc=f'''# AR4-AB 菠菜盆栽成熟显示修复

2026-10-27。接265号的下一片。任务预期复杂度4/5，实际4/5；完成静态实现、离线查看、构建和部署，最终美术与实机仍待用户评价。

## 用户补充要求已落地

用户要求“绘制新贴图的时候参考原版贴图”。已将此要求写入根目录DEVELOPMENT_RULES：先实际查看对应Minecraft/TFC原版贴图和模型，以已安装TFC同类作物为农业风格参考，保存来源并检查最终尺寸和真实裁切效果。该要求适用于后续绘图，不只适用于本张菠菜。

本片从已安装TerraFirmaCraft JAR原样提取cabbage_5、beet_5、soybean_5、lentil_5，组成TFC-native-crop-reference并实际查看，与当前菠菜六龄表并排分析。卷心菜是低矮、落地的叶团；甜菜叶面有明暗相间的绿色，底部为红根；大豆和兵豆表现分层枝叶。新菠菜只借鉴叶团结构、离散色阶和生长表现，不把甜菜红根、兵豆豆荚或食物图标当菠菜器官。

四张参考均与已安装JAR字节相同，资源路径与哈希写入asset-manifest.json。使用内置image_gen制作一张独立候选，没有CLI或第三方业务代码复制。原生接口只用于确认UV、阶段索引和资源加载方式。

## 为什么需要独立盆栽图

当前菠菜age5原图顶部有白花，已通过栽培/野生/死株模型的几何和UV剪裁避开。Firmalife的quad盆每株直接读取一张纹理，UV取[2,0,14,16]，不会读取栽培模型的剪裁。原盆栽为了避免白花，最后两项均使用age4，导致成熟时与前一阶段没有区别。

本片保留age0～4五个原入口，只把第5项（从0计数、完全成熟时）改为tfcfarmingplus:block/crop/spinach_planter_mature_v1。stages仍5；按现有Plantable.getTexture，完全成熟进入最后项，成熟前仍使用对应旧阶段。产物、数量、种子、养分、盆类型、成熟时间和交互都未改变。

新图表现低矮的深绿成熟叶丛，叶片从共同基部展开；颜色与参考图保持植物绿，并保留清晰的叶面深浅。它比原来两片小叶更紧密，成熟与未成熟可区分，无白花。它只用于盆栽，不替换六龄栽培、野生或死株图，也不影响已修食品图标。

正式文件：

`{asset['FinalPath']}`

正式图为RGBA16×16，源与JAR字节相同、尺寸相同。大原稿保留在默认generated_images和本片imagegen-source；提示词与模式见imagegen-prompt.json，来源、最终路径与哈希见asset-manifest.json。原稿有几乎透明的边缘杂点，第一版按任意非零alpha框定时把大量空白也算进来，导出后叶株过小，未采用。最终按客户端cutout可见边界定位内容，原图内颜色与alpha保留、最近邻等比适配12列可见窗口并底对齐，不程序重画叶片；全部原稿保留。原生cutout shader的alpha<0.1丢弃规则已从Minecraft1.21.1客户端核实。

新图放在block/crop纹理目录，符合客户端blocks图集的block目录加载规则；native-blocks-atlas.json留档，没有为显示另造方块或物品。

## 实际查看与保护

查看原版参考、菠菜旧六龄、最终16×16放大对照，然后按原生quad单元边界、对角交叉面、UV和四株位移做离线预览，查看p28、p5、p70。正式接入后再从src重新读取纹理与盆栽数据，查看AR4AB-current三图；每图包括原六阶段、现六阶段、前后四株排列，共14格。

实际观察：旧末两格都是两片小叶；新末格为一丛较密、低矮的绿色叶片，底部落地，普通视角能与上一格区分，没有白花或根块，四株布局各自占单元。俯视时原生竖直交叉面的叶株会显得扁，属于该显示方式的限制。本片预览不含盆底和温室环境，不代表真实光照、交互、生长、重进存档或美术验收。VisualAccepted/RuntimeVerified均false。

菠菜保护合同保留原13张图，再追加新图，现14张。增加成熟入口、末项区别、原生可见列范围及落地检查，前五入口与其他菠菜模型保护保持。gen-crops的SpinachDisplayOnly先完整审查菠菜，再做原有17份JSON安全复制，缺图、错误路线或奖励漂移时会在复制前拒绝。PNG依旧不由旧生成器重绘，完整草稿也不直接发布。

## 检查结果和交付

施工前全量备份9179条目至moddev/backups/ar4ab-spinach-planter-20261027，复制后核哈希；施工前再次确认源/工具未被外部改动。包括A/B源、工具、构建包、四旧安装包、根规则和当前文档。

15项检查通过：正确隔离版1个；11个负例分别覆盖重复成熟、旧白花图、六阶段全改成熟、缺新图、新图改变、旧图改变、B覆盖、误改产量、移除栽培剪裁、旧食品图回退和播种图串线；另3个安全复制检查分别输出17菠菜、21向日葵、44食品/种子模型JSON，路径/字节与正式源一致，不产额外PNG。

完整verify和418项外部覆盖台账通过。新PNG及包内新PNG16×16，263张食品/种子图仍16×16。全部原PNG、Java、B源码/工具、食品、种子、气候、掉落、ID/NBT和已完成的向日葵修复保持。A源5924文件、工具104，B源3107、工具19。

A离线assemble成功，51秒，Java编译up-to-date。JAR精确差异只有1份盆栽JSON修改和1张PNG新增，零删除；原包全部PNG保持，两个变化均等于正式源。源/工具范围为4份既有文件修改和1份PNG新增；根开发规则另新增用户绘图要求。

部署前核四旧安装包与备份一致，仅更新A到工作区mods和D:/TFC农业重置/PCL_TFC/mods。A三份SHA-256：{a_hash}。B三份仍为EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3；B未构建/部署。部署后完整静态健康检查通过，历史闲置空图按原范围保留。

本片未启动游戏、改存档或制作PCL压缩包。以后用户正常放种后可观察成熟前后的区别，检查一株/四株、光照和盆底衔接，确认成熟收获数量及重进状态。此前延期实机和封窑由用户负责的安排保持。

## 交接和后续

证据位于moddev/inventory/spinach-planter-20261027，含原版参考、原稿/提示词、正式路径/导出记录、二维及三视角预览、隔离案例、安全复制、源/JAR差异、构建和交付哈希。

回滚前先保存当前工作，恢复备份盆栽JSON、菠菜合同和两份工具，将新图另存后从源撤回；删除源资源后clean build防残留。也可直接恢复旧A（D96EF118FEE0B1D806399BB99F7ED75C49BF462DB8994DBA0DEB5C776C330E92）至两mods。新的用户绘图要求继续保留；B和存档无需迁移。

{next_step}

整书再生176/174页差异继续单独待核，不发布旧整书草稿。全农业完成后再生成完整自然语言TXT总结；233号命名、结构与代码可读性整理仍在全部既定工作完成之后。
'''
(docs/name).write_text(doc,encoding='utf-8')
p=docs/'217-agriculture-repair-next-phase-plan-20261023.md';text=p.read_text(encoding='utf-8-sig');old=next(line for line in text.splitlines() if line.startswith('**下一步AR4-AB：'));text=text.replace(old,f'**{status}见[266号]({name})。**\n\n**{next_step}**');p.write_text(text,encoding='utf-8')
p=docs/'218-agriculture-audit-baseline-20261023.md';text=p.read_text(encoding='utf-8-sig');old=next(line for line in text.splitlines() if line.startswith('> **2026-10-27当前入口：**'));tail='下面AR0'+old.split('下面AR0',1)[1] if '下面AR0' in old else ''
text=text.replace(old,f'> **2026-10-27当前入口：**AR4-AB菠菜盆栽成熟显示静态交付，见[266号]({name})，最终外观和实机未验；下一片AR4-AC牛皮菜采收说明与生命周期核对，预期4/5。{tail}');text+=f'\n- **{status}** 见[266号]({name})。{next_step}\n';p.write_text(text,encoding='utf-8')
p=r/'README.md';text=p.read_text(encoding='utf-8-sig');text=text.replace('下一片AR4-AB菠菜盆栽成熟显示，预期4/5。',f'菠菜盆栽后续见[266号](moddev/docs/{name})。')
anchor='- [K3 烤炉计时与黄油蛋糕修复记录]';assert text.count(anchor)==1;text=text.replace(anchor,f'- [AR4-AB 菠菜盆栽成熟显示](moddev/docs/{name})：参考已安装TFC原版作物，新增16×16成熟叶株图并接入最后阶段；15项检查、构建/两处部署/体检通过，实机与最终美术未验。绘图先看原版的要求已写入开发规则。附[正式贴图](moddev/tfcfarmingplus/src/main/resources/assets/tfcfarmingplus/textures/block/crop/spinach_planter_mature_v1.png)、[提示词](moddev/inventory/spinach-planter-20261027/imagegen-prompt.json)和[源预览](moddev/inventory/spinach-planter-20261027/AR4AB-current-p28.png)。下一片AR4-AC牛皮菜采收说明与生命周期核对，预期4/5。\n'+anchor);p.write_text(text,encoding='utf-8')
queue=load(r/'moddev/inventory/sunflower-display-20261027/next-work-queue.json')
for row in queue:
    if row['顺序']=='V05':row['当前状态']='AR4-AB菠菜盆栽成熟图静态交付，实机/最终美术未验';row['后续证据']='266号及spinach-planter-20261027'
    if row['顺序']=='V06':row['当前状态']='下一片AR4-AC先核牛皮菜采收文案/生命周期，预期4/5，后续全龄美术另评估'
save(o/'next-work-queue.json',queue)
keys=list(dict.fromkeys(key for row in queue for key in row))
with (o/'next-work-queue.csv').open('w',encoding='utf-8-sig',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=keys);writer.writeheader();writer.writerows(queue)
save(o/'visual-observations.json',{'ActualViewed':['TFC-native-crop-reference.png','spinach-current-ages.png','candidate-16x16-review.png','AR4AB-planter-p28.png','AR4AB-planter-p5.png','AR4AB-planter-p70.png','AR4AB-current-p28.png','AR4AB-current-p5.png','AR4AB-current-p70.png'],'Observation':'原版叶面色阶和贴地植株作为参考；新末阶段为深绿较密的低矮叶株，与原两小叶阶段可区分，无白花。原生竖直交叉面在俯视下显得扁。','FinalArtworkAccepted':False,'RuntimeVerified':False})
print('266 and current README/217/218/queue updated; next AR4-AC, complexity 4/5.')
