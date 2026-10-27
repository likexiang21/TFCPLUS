from pathlib import Path
import json

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
docs = root / 'moddev/docs'
name = '260-ar4v-visual-backlog-and-agriculture-status-20261026.md'
v_status = 'AR4-V（2026-10-26）只读状态复核完成：四页十六食品实际复看，确认五坚果及龙舌兰/向日葵/大黄八项图像内容错配，八叶菜共享图另列待美术；87作物仍74种栽培仅TFC纹理，156盆栽/902纹理项中18自有。22条历史问题和十项队列已更新，草莓世界生成整表替换旧待办更正为234号已修待实机。A/B全部5867/3031源资源等于已安装包、源码/工具/JAR不变，完整静态体检通过；实机/最终美术及农业整体未完成。预期/实际4/5。'
next_step = '下一步AR4-W：五种坚果食品图标修复，预期5/5。杏仁、榛子、夏威夷果、碧根果、核桃制作五张独立16×16候选，接五模型与同一保护/尺寸检查、负例及构建部署；保留原PNG、食品/腐烂、用途、树体和ID。后续三特殊产物、八共享叶菜、生命周期及其他农业/AR5/最终TXT/233号按260号队列推进，开始前报告复杂度。'

path = docs / '217-agriculture-repair-next-phase-plan-20261023.md'
text = path.read_text(encoding='utf-8-sig')
old = '**下一步AR4-V：剩余视觉待办与农业阶段状态统一复核，预期4/5。先核五坚果及agave/sunflower/rhubarb产物定义，重排共享图标、菠菜盆栽后期共图及74种栽培等生命周期优先级，区分已修待验、待美术和实际错误，给出下一批施工清单；本片只读盘点，不盲换图、不额外构建。全农业TXT、其他农业/AR5及233号仍保留，开始前报告复杂度。**'
assert text.count(old) == 1
text = text.replace(old, f'**{v_status}见[260号交接]({name})。**\n\n**{next_step}**')
old = '- 后续缺口：草莓世界生成通过整表替换 tag 关闭的兼容风险、重复草莓旧物品台账，以及其余现有作物的实际闭环。旧 cocoa 的叶片季节表不含 FRUITING，不能再沿用“常规可收获的第二棵可可树”这一审计误判。每个切片开始时按当前实际文件复核旧结论，再动手。'
assert text.count(old) == 1
text = text.replace(old, '- 后续缺口按当前源复核：草莓世界生成整表替换风险已由234号改为追加项目灌木、定向remove原生草莓patch，运行兼容待验，不再列待重新施工；旧草莓隐藏物品保留兼容台账，其余物种按真实闭环和260号队列推进。旧cocoa叶片无FRUITING，不再误写为常规可收获的第二棵树。历史AR1-D/E/F的空图体检失败已在239号按实际消费者更正归类，当前完整静态体检通过，原图继续保留。')
path.write_text(text, encoding='utf-8')

path = docs / '218-agriculture-audit-baseline-20261023.md'
text = path.read_text(encoding='utf-8-sig')
old = '下一步AR4-V：剩余视觉待办与农业阶段状态统一复核，预期4/5。先核五坚果及agave/sunflower/rhubarb产物定义，重排共享图标、菠菜盆栽后期共图及74种栽培等生命周期优先级，区分已修待验、待美术和实际错误，给出下一批施工清单；本片只读盘点，不盲换图、不额外构建。全农业TXT、其他农业/AR5及233号仍保留，开始前报告复杂度。'
assert text.count(old) == 2
text = text.replace(old, f'AR4-V当前复核已完成，见[260号]({name})；下一片AR4-W五坚果图标，预期5/5。')
lines = text.splitlines()
matches = [i for i, line in enumerate(lines) if line.startswith('| AR0-04 |')]
assert len(matches) == 1
lines[matches[0]] = '| AR0-04 | **P2，AR3-F已修复待实机** | 初版整表replace:true风险已由234号处理；当前标签replace:false，追加十二种项目灌木patch，仅remove tfc:plant/strawberry_bush_patch。 | 保留草莓灌木不自然生成，继续核最终数据包/新增模组兼容及实机生成；不重复整表替换施工。AR4-V已对当前源和部署资源复核，见260。 |'
text = '\n'.join(lines) + '\n'
intro = f'> **2026-10-26当前入口：**AR4-V完成，后续按[260号]({name})，下一片五坚果食品图标，预期5/5。下面AR0原始规模与历史发现保留日期口径，不能当作所有条目仍未修复；87作物/49树类/12灌木的本轮静态交付、视觉长尾与用户实机状态分开管理。\n\n'
first_break = text.index('\n') + 1
text = text[:first_break] + '\n' + intro + text[first_break:]
text += f'\n- **{v_status}** 见[260号交接]({name})与本片22条分诊、十项队列。{next_step}\n'
path.write_text(text, encoding='utf-8')

path = root / 'README.md'
text = path.read_text(encoding='utf-8-sig')
old = '下一片AR4-V剩余视觉及农业状态复核，预期4/5。'
assert text.count(old) == 1
text = text.replace(old, f'当前复核见[260号](moddev/docs/{name})。')
anchor = '- [K3 烤炉计时与黄油蛋糕修复记录]'
assert text.count(anchor) == 1
entry = f'- [AR4-V 剩余视觉与农业阶段状态](moddev/docs/{name})：只读复核四页十六食品、八项产物定义与22条历史待办，纠正草莓世界生成旧状态；87作物/49树类/12灌木的静态交付、待美术和实机分开记录。A/B源/工具/JAR不改，完整体检及全部源资源/安装包比对通过。附[下一批队列](moddev/inventory/visual-status-review-20261026/next-work-queue.csv)和[产物判断](moddev/inventory/visual-status-review-20261026/product-verdicts.csv)。下一片AR4-W五坚果食品图标，预期5/5。\n'
text = text.replace(anchor, entry + anchor)
path.write_text(text, encoding='utf-8')
print(json.dumps({'Updated': ['README.md', '217', '218'], 'Handoff': name, 'Next': 'AR4-W', 'ExpectedComplexity': '5/5'}, ensure_ascii=False))
