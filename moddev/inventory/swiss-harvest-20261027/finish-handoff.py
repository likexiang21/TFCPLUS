from pathlib import Path
import json,csv
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;docs=r/'moddev/docs';name='267-ar4ac-swiss-chard-harvest-guide-20261027.md'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
assert '静态资源健康检查：通过' in (o/'health.log').read_text(encoding='utf-8-sig')
a_hash=load(o/'delivery-manifest.json')['Packages'][0]['SHA256']
status='AR4-AC（2026-10-27）牛皮菜采收文案已静态交付：基本需求和代码均为普通单格整株收获，纠正中文“割了还会再长”，中英文明确采后重新播种；两生成行同步修正，保护增至八文字页/八模板行。11项检查、完整校验/418台账、构建/部署/体检通过；玩法/Java/所有贴图/B保持，实机未验；预期4/5，实际3/5。'
next_step='下一步AR4-AD：牛皮菜完整显示链审查与修复，预期复杂度5/5。先看已安装TFC原版同类贴图、当前六龄/野生/死株/盆栽真实模型与保存素材，再按完整叶株核器官、UV和各龄表现，逐图处理；保留已修食品图和本片整株采收规则，不用食品图替代植株，也不盲接同名旧图。其他73种来源统计、种子/向日葵盆栽、树/灌木、加工闭环和AR5继续保留。'
doc=f'''# AR4-AC 牛皮菜采收说明与生命周期一致性核对

2026-10-27。接266号下一片。预期复杂度4/5；实际3/5，原因是确认需要修复的为文案及生成源，没有新增或重写采收行为。

## 核对结论

70号§3.2把swiss_chard列为普通单格作物，§3.3的可采摘列表不含它。117号把其产物归为叶菜，没有要求该物种独立实现割叶退龄。当前MyCrops以crop("swiss_chard",5,...)注册，MyCropBlock只同步生长年龄和转死株，没有割叶采摘分支；TFC父类的使用入口处理施肥，没有为这个普通作物提供采摘退龄。核对TFC右键事件入口和A/B相关事件后，未发现牛皮菜专属再生覆盖。由此确认普通农田采收行为与既定形态相符，不因一句旧描述把普通作物改成可采摘作物。

中文栽培手册却写“叶柄肥厚、叶片宽大，割了还会再长”。gen-patchouli-book中文描述相同，gen-crops中英文备注也宣称割后继续生产；英文正式页原来只写形态，未明确重新播种。此为已确认的说明不一致。

现在中英文栽培页均明确：成熟后破坏整株收获，然后重新播种。保留厚叶柄、宽叶的形态说明，气候、养分、产物、种子和农田链接。两份生成脚本中仅修正牛皮菜该行，防止下次生成又恢复错误承诺。

## 生命周期与适用边界

记录当前链条：野生植株提供种子；野生成熟时另有对应食品掉落。种子播在农田，普通单格作物有age0～5六龄，成熟食品掉落以age5为条件，破坏时返种；枯死转对应DeadCropBlock，成熟死株返1～3种子，未成熟死株返1种子。食品仍为food/swiss_chard，hunger4、saturation1、vegetables2、water3、decay_modifier4，未改变新鲜度或加工用途。数量仍由原有掉落函数结算，手册没有新增固定保底产量承诺。

Firmalife盆栽是另一条原生容器交互入口：quad通过LargePlanterBlock的槽位收获和resetGrowthTo处理，不是把农田方块的破坏逻辑直接套进容器。此处只修农田栽培页，没有改容器交互、种子库存、收获次数或plantable定义。本片也没有把普通注册推导为“所有容器操作必须左键破坏”。

在A自有手册中找到中英栽培、野生共四个牛皮菜文字锚点；修改栽培两页，野生两页保持。栽培锚点仍在第20项（从0计数），第21项六龄示意、六个age映射、所有跳转和其他页面完全保持。直接替换目标文字载荷，书文件其他字节没有批量重排。

## 保护与检查

施工前备份9181条目至moddev/backups/ar4ac-swiss-harvest-20261027，逐项核哈希；修改前再次核A/B源与工具没有外部漂移。包含源、工具、构建与四旧安装包、根规则和当前交接文档。

复用现有图标/说明保护工具，合同版本12，在原六页/六模板行基础上增加牛皮菜中英两页和两生成行，现八页/八行。44个模型、81张图、41食品数据的既有保护不变；没有以改文案为由放宽图标或玩法保护。

11项检查通过：正确隔离版1个，中文再生承诺、英文再生承诺、gen-crops行回退、手册生成行回退、缺锚点、重复锚点、前批龙舌兰说明回退及牛皮菜食品图回退等8个负例；另44份安全图标JSON复制路径/字节一致；最后一项为受限整书草稿的八保护页比对。

完整手册生成仅在moddev/.probe/generator-output/ar4ac-book-review运行。八保护页的文本及页码与正式源相同。旧生成器仍产生176页，而正式书174页，差异仍是草莓文字/示意一对；这不是本片引入，也没有通过覆盖正式书来消除差异。草稿未发布，整书生成/合并问题继续列待办。

完整资源verify、418项外部覆盖台账和部署后健康检查通过。菠菜10状态/14图、向日葵18状态/19图及新绘图规范均保持；263张食品/种子图源与JAR仍16×16。本片未绘图，所有原PNG、Java、食品/掉落/气候、方块模型、ID/NBT与B均保持。

## 构建、交付及回滚

A离线assemble成功，26秒，Java编译up-to-date。源/工具差异恰5份既有文件修改（两份书、两份生成脚本、一个保护合同），无新增/删除；A源5924、工具104，B源3107、工具19。

JAR精确差异恰中英文两份crops.json修改，零新增/删除，均与正式源一致；包中所有原PNG完全保持。两个书中各只有牛皮菜文字改变，页序、结构和其他内容保持。

部署前四旧安装包与备份一致，仅部署A到工作区mods和D:/TFC农业重置/PCL_TFC/mods。A在build/libs和两mods三份SHA-256：{a_hash}。

B未构建/部署，三份仍为EC9B98AD52DB334DA6E7E7CED3C89943800B0B1DC1EDC8FE4279BFF7B0CECDE3。静态检查不代表本轮玩家已验证采收或手册实际排版；本片没有启动游戏、改存档或打PCL ZIP。实机以后看中英文字、跳转和六龄示意，并正常播种/成熟破坏/返种重播；封窑完整操作继续由用户负责。

回滚先保存当前工作，再从本片备份恢复两书、两脚本和保护合同；也可把旧A（9BE06BF00667EC886614B088AB39B6B4323B4D35208B7337AB80480B3BE25253）恢复至两mods。没有删除源资源，不需要为本片回滚清理资源残留；B和存档无需迁移。不要发布整书草稿作回滚。

## 后续

{next_step}

用户要求的新贴图先参考原版的规则继续执行。全农业完成后再交完整自然语言TXT总结；233号命名/文件结构和可读性整理仍在全部既定工作完成后。证据目录为moddev/inventory/swiss-harvest-20261027，含基本需求/当前四页和10项玩法数据、修改清单、回退案例、草稿比较、源/JAR差异、构建/体检及交付哈希。
'''
(docs/name).write_text(doc,encoding='utf-8')
p=docs/'217-agriculture-repair-next-phase-plan-20261023.md';text=p.read_text(encoding='utf-8-sig');old=next(line for line in text.splitlines() if line.startswith('**下一步AR4-AC：'));text=text.replace(old,f'**{status}见[267号]({name})。**\n\n**{next_step}**');p.write_text(text,encoding='utf-8')
p=docs/'218-agriculture-audit-baseline-20261023.md';text=p.read_text(encoding='utf-8-sig');old=next(line for line in text.splitlines() if line.startswith('> **2026-10-27当前入口：**'));tail='下面AR0'+old.split('下面AR0',1)[1] if '下面AR0' in old else '';text=text.replace(old,f'> **2026-10-27当前入口：**AR4-AC牛皮菜采收说明已静态交付，见[267号]({name})；当前普通整株收获规则保持，实机未验。下一片AR4-AD牛皮菜完整显示链，预期5/5。{tail}');text+=f'\n- **{status}** 见[267号]({name})。{next_step}\n';p.write_text(text,encoding='utf-8')
p=r/'README.md';text=p.read_text(encoding='utf-8-sig');text=text.replace('下一片AR4-AC牛皮菜采收说明与生命周期核对，预期4/5。',f'牛皮菜采收说明核对见[267号](moddev/docs/{name})。');anchor='- [K3 烤炉计时与黄油蛋糕修复记录]';assert text.count(anchor)==1;text=text.replace(anchor,f'- [AR4-AC 牛皮菜采收说明与生命周期核对](moddev/docs/{name})：纠正割后再生承诺，明确农田整株采收后重新播种；玩法和贴图保持。八文字页/八模板保护、11项检查、构建部署/体检通过，实机未验。整书草稿176/174页差异继续待核，未发布。下一片AR4-AD牛皮菜完整显示链，预期5/5。\n'+anchor);p.write_text(text,encoding='utf-8')
queue=load(r/'moddev/inventory/spinach-planter-20261027/next-work-queue.json')
for row in queue:
 if row['顺序']=='V06':row['当前状态']='AR4-AC牛皮菜采收文案静态修正；下一片AR4-AD牛皮菜完整显示链，预期5/5';row['待复核文字']='267号已纠正再生承诺：普通农田成熟后整株收获，再播种；实际交互仍待实机';row['后续证据']='267号及swiss-harvest-20261027'
save(o/'next-work-queue.json',queue);keys=list(dict.fromkeys(key for row in queue for key in row))
with (o/'next-work-queue.csv').open('w',encoding='utf-8-sig',newline='') as stream:
 writer=csv.DictWriter(stream,fieldnames=keys);writer.writeheader();writer.writerows(queue)
print('267 and current README/217/218/queue updated; actual complexity 3/5, next AR4-AD 5/5.')
