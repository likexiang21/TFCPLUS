from pathlib import Path
import json, csv

root=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');out=Path(__file__).resolve().parent;docs=root/'moddev/docs'
name='261-ar4w-nut-food-icons-20261026.md'
status='AR4-W（2026-10-26）五坚果食品图标静态交付完成：五独立16×16候选及五模型，原PNG/食品/玩法/Java/B保持。四检查页/五原稿实看，26检查、252源/包尺寸、418台账及A构建部署/体检通过；40模型/66PNG/37食品保护，实机/最终美术未验。229模型来源仍TFC128/A101，不因本片计数不变而漏记图像修复。预期/实际5/5。'
next_step='下一步AR4-X：大黄、向日葵、龙舌兰食品图标及准确说明，预期5/5。按已核语义制作叶柄、食用籽、中心收获物三图，保留播种ID、原图、食品和采收；核手册/模板中榨油等未实现愿景，准确说明当前用途，不擅加物种、设备或ID。逐图16×16查看、同一保护/负例和构建交付。其余共享叶菜、生命周期、农业/AR5/最终TXT及233号按260/261号队列保留，开始前报告复杂度。'
old='下一步AR4-W：五种坚果食品图标修复，预期5/5。杏仁、榛子、夏威夷果、碧根果、核桃制作五张独立16×16候选，接五模型与同一保护/尺寸检查、负例及构建部署；保留原PNG、食品/腐烂、用途、树体和ID。后续三特殊产物、八共享叶菜、生命周期及其他农业/AR5/最终TXT/233号按260号队列推进，开始前报告复杂度。'
path=docs/'217-agriculture-repair-next-phase-plan-20261023.md';text=path.read_text(encoding='utf-8-sig');assert text.count('**'+old+'**')==1
text=text.replace('**'+old+'**',f'**{status}见[261号交接]({name})。**\n\n**{next_step}**');path.write_text(text,encoding='utf-8')
path=docs/'218-agriculture-audit-baseline-20261023.md';text=path.read_text(encoding='utf-8-sig');assert text.count(old)==1
text=text.replace(old,f'五坚果后续已静态交付，见[261号]({name})。')
short='下一片AR4-W五坚果图标，预期5/5。';assert text.count(short)==2;text=text.replace(short,f'五坚果后续见[261号]({name})。')
intro='> **2026-10-26当前入口：**AR4-V完成，后续按[260号](260-ar4v-visual-backlog-and-agriculture-status-20261026.md)，下一片五坚果食品图标，预期5/5。'
assert text.count(intro)==1;text=text.replace(intro,f'> **2026-10-26当前入口：**AR4-W五坚果图标完成静态交付，见[261号]({name})；下一片AR4-X三项特殊食品图标与说明，预期5/5。')
text+=f'\n- **{status}** 见[261号交接]({name})及当前分诊。{next_step}\n';path.write_text(text,encoding='utf-8')
path=root/'README.md';text=path.read_text(encoding='utf-8-sig');short='下一片AR4-W五坚果食品图标，预期5/5。';assert text.count(short)==1
text=text.replace(short,f'五坚果后续见[261号](moddev/docs/{name})。')
anchor='- [K3 烤炉计时与黄油蛋糕修复记录]';assert text.count(anchor)==1
entry=f'- [AR4-W 五种坚果食品图标](moddev/docs/{name})：五张独立16×16新候选替代水果外形，原图/食品/玩法/Java/B保持。26检查、252源/包尺寸、418台账及A构建部署/体检通过，实机/最终美术待验。附[新图正式路径/来源](moddev/inventory/nut-icons-20261026/imagegen-asset-manifest.json)、[生成提示词](moddev/inventory/nut-icons-20261026/imagegen-prompts.json)和[当前分诊](moddev/inventory/nut-icons-20261026/item-icon-triage.csv)。下一片AR4-X大黄/向日葵/龙舌兰食品图标与说明，预期5/5。\n'
text=text.replace(anchor,entry+anchor);path.write_text(text,encoding='utf-8')

queue=json.loads((root/'moddev/inventory/visual-status-review-20261026/next-work-queue.json').read_text(encoding='utf-8'))
for row in queue:
    row['实机通过']=False
    if row['顺序']=='V01':row['当前状态']='AR4-W静态交付完成，最终美术/实机未验';row['后续证据']='261号及nut-icons-20261026'
    elif row['顺序']=='V02':row['当前状态']='下一步AR4-X，预期5/5'
    else:row['当前状态']='继续按原队列保留'
(out/'next-work-queue.json').write_text(json.dumps(queue,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
fields=list(dict.fromkeys(k for r in queue for k in r))
with (out/'next-work-queue.csv').open('w',encoding='utf-8-sig',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=fields);writer.writeheader();writer.writerows(queue)
print(json.dumps({'Updated':['README.md','217','218'],'Handoff':name,'Next':'AR4-X','ExpectedComplexity':'5/5'},ensure_ascii=False))
