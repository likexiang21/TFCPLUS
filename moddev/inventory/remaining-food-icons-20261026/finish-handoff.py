from pathlib import Path
import json

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
docs = root / 'moddev/docs'
name = '259-ar4u-remaining-food-icons-20261026.md'
next_step = '下一步AR4-V：剩余视觉待办与农业阶段状态统一复核，预期4/5。先核五坚果及agave/sunflower/rhubarb产物定义，重排共享图标、菠菜盆栽后期共图及74种栽培等生命周期优先级，区分已修待验、待美术和实际错误，给出下一批施工清单；本片只读盘点，不盲换图、不额外构建。全农业TXT、其他农业/AR5及233号仍保留，开始前报告复杂度。'
u_status = 'AR4-U（2026-10-26）八项食品图标本片修复完成：韭菜/菱角接回既有图，另六项新增16×16候选，八模型改线；全部原图/营养/玩法/Java/B保持。五对照图/七生成图实看，莼菜v1未采用、v2接入。28检查、247源/包尺寸、418台账及A构建部署/体检通过，实机/最终美术未验。229模型来源TFC128/A101、85原生来源种子不变；明确错配子组清空不等于全农业完成。预期/实际5/5。'

path = docs / '217-agriculture-repair-next-phase-plan-20261023.md'
text = path.read_text(encoding='utf-8-sig')
old = '**下一步AR4-U：剩余八项明确错配食品图标集中核对与修复，预期5/5。芽甘蓝、韭菜、木耳菜、菱角、荸荠、水芹、莼菜、空心菜；先核食用部位和已有候选，按实图决定复用/新美术，不盲接同名错图，合格后接同一保护及16×16检查，逐批构建部署。该组处理完仍保留专用美术、生命周期及其他农业/AR5/233号，开始前报告复杂度。**'
assert text.count(old) == 1
text = text.replace(old, f'**{u_status}见[259号交接]({name})。**\n\n**{next_step}**')
path.write_text(text, encoding='utf-8')

path = docs / '218-agriculture-audit-baseline-20261023.md'
text = path.read_text(encoding='utf-8-sig')
old = '当前下一步AR4-U剩余八项明确错配食品图标，预计5/5，先核食用部位与候选，不盲接同名错图；其他美术/生命周期待办继续保留。'
assert text.count(old) == 1
text = text.replace(old, 'AR4-U实际5/5，八项食品图标静态交付完成，六新增/两复用，实机/最终美术未验。' + next_step)
old = '下一片AR4-U剩余八项明确错配食品图标，预期5/5。'
assert text.count(old) == 1
text = text.replace(old, f'八项后续见[259号交接]({name})。')
text += f'\n- **{u_status}** 见[259号交接]({name})和本片当前分诊。{next_step}\n'
path.write_text(text, encoding='utf-8')

path = root / 'README.md'
text = path.read_text(encoding='utf-8-sig')
old = '下一片剩余八项明确错配食品图标集中核对，预期5/5。'
assert text.count(old) == 1
text = text.replace(old, f'八项食品图标后续见[259号](moddev/docs/{name})。')
anchor = '- [K3 烤炉计时与黄油蛋糕修复记录]'
assert text.count(anchor) == 1
entry = f'- [AR4-U 八项食品图标修复与交付](moddev/docs/{name})：韭菜/菱角复用既有图，其余六项新增16×16候选，原图/玩法/Java/B保持。28检查、247源/包尺寸、418台账及A构建部署/体检通过，实机/最终美术待验；明确错配子组清空，其他农业/美术仍待办。附[当前分诊](moddev/inventory/remaining-food-icons-20261026/item-icon-triage.csv)、[来源及正式路径](moddev/inventory/remaining-food-icons-20261026/imagegen-asset-manifest.json)、[初始提示词](moddev/inventory/remaining-food-icons-20261026/imagegen-prompts.json)和[莼菜重做提示](moddev/inventory/remaining-food-icons-20261026/imagegen-water-shield-retry-prompt.json)。下一片AR4-V剩余视觉及农业状态复核，预期4/5。\n'
text = text.replace(anchor, entry + anchor)
path.write_text(text, encoding='utf-8')
print(json.dumps({'Updated': ['README.md', 'moddev/docs/217-agriculture-repair-next-phase-plan-20261023.md', 'moddev/docs/218-agriculture-audit-baseline-20261023.md'], 'Created': 'moddev/docs/' + name, 'Next': 'AR4-V', 'ExpectedComplexity': '4/5'}, ensure_ascii=False))
