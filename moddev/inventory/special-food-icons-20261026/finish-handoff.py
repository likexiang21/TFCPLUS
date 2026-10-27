from pathlib import Path
import json,csv
r=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');o=Path(__file__).resolve().parent;docs=r/'moddev/docs';name='262-ar4x-special-food-icons-and-guide-20261026.md'
status='AR4-X（2026-10-26）三特殊食品图标及六页中英文说明静态交付完成：大黄叶柄/食用葵花籽/龙舌兰心，原图/食品/玩法/Java/B保持；两图重做后采用，五检查页/五原稿已看。33隔离/复制检查、六页模板内容、255源/包尺寸、418台账及A构建部署/体检通过；43模型/72PNG/40食品及六说明/六模板保护。整书草稿仍额外有草莓两页，已隔离未发布，正式174页保持；实机/最终美术未验。预期/实际5/5。'
next_step='下一步AR4-Y：芝麻菜、茼蒿、芥菜、紫苏独立食品图标，预期5/5。按实际叶菜产物逐图制作16×16候选，保留原图/食品/玩法，沿用图标、六说明/模板保护和负例/构建交付；不直接回接旧根果形存图。其他共享叶菜、生命周期、整书再生差异、农业/AR5/最终TXT及233号继续按260/262号队列，开始前报告复杂度。'
p=docs/'217-agriculture-repair-next-phase-plan-20261023.md';t=p.read_text(encoding='utf-8-sig');lines=t.splitlines();old=next(x for x in lines if x.startswith('**下一步AR4-X：'));t=t.replace(old,f'**{status}见[262号交接]({name})。**\n\n**{next_step}**');p.write_text(t,encoding='utf-8')
p=docs/'218-agriculture-audit-baseline-20261023.md';t=p.read_text(encoding='utf-8-sig');long_old=old.strip('*');assert t.count(long_old)==1;t=t.replace(long_old,f'三项后续已施工，见[262号]({name})。')
t=t.replace('下一片AR4-X三项特殊食品图标与说明，预期5/5。','下一片AR4-Y四叶菜独立图标，预期5/5。')
t=t.replace('AR4-W五坚果图标完成静态交付，见[261号](261-ar4w-nut-food-icons-20261026.md)',f'AR4-X三项图标及说明完成静态交付，见[262号]({name})')
t+=f'\n- **{status}** 见[262号交接]({name})和当前分诊。{next_step}\n';p.write_text(t,encoding='utf-8')
p=r/'README.md';t=p.read_text(encoding='utf-8-sig');old='下一片AR4-X大黄/向日葵/龙舌兰食品图标与说明，预期5/5。';assert t.count(old)==1;t=t.replace(old,f'三项后续见[262号](moddev/docs/{name})。')
entry=f'- [AR4-X 三特殊食品图标与准确说明](moddev/docs/{name})：三张16×16新图、六页中英文说明及模板保护，原图/食品/玩法/Java/B保持。33检查、六页模板对照、255源/包尺寸、418台账及A构建部署/体检通过；整书草稿的草莓额外两页保留为未发布差异，实机/最终美术待验。附[新图正式路径/来源](moddev/inventory/special-food-icons-20261026/imagegen-asset-manifest.json)、[初始提示词](moddev/inventory/special-food-icons-20261026/imagegen-prompts.json)及[重做提示词](moddev/inventory/special-food-icons-20261026/imagegen-retry-prompts.json)。下一片AR4-Y芝麻菜/茼蒿/芥菜/紫苏图标，预期5/5。\n'
anchor='- [K3 烤炉计时与黄油蛋糕修复记录]';assert t.count(anchor)==1;t=t.replace(anchor,entry+anchor);p.write_text(t,encoding='utf-8')
queue=json.loads((r/'moddev/inventory/nut-icons-20261026/next-work-queue.json').read_text(encoding='utf-8'))
for row in queue:
    if row['顺序']=='V02':row['当前状态']='AR4-X静态交付完成，实机/最终美术待验';row['后续证据']='262号及special-food-icons-20261026'
    if row['顺序']=='V03':row['当前状态']='下一片AR4-Y先四种，其余四种随后，预期每片5/5'
    if row['顺序']=='V09':row['完成判据与边界']+='；整书再生176/174页差异另核，禁止直接整树发布'
(o/'next-work-queue.json').write_text(json.dumps(queue,ensure_ascii=False,indent=2),encoding='utf-8')
def csvsave(path,rows):
    keys=list(dict.fromkeys(k for row in rows for k in row))
    with path.open('w',encoding='utf-8-sig',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=keys);writer.writeheader()
        for row in rows:writer.writerow({k:json.dumps(v,ensure_ascii=False) if isinstance(v,(dict,list)) else v for k,v in row.items()})
csvsave(o/'next-work-queue.csv',queue)
triage=json.loads((o/'item-icon-triage.json').read_text(encoding='utf-8'))
for row in triage:
    if row.get('ChangedInAR4X'):row['AR4XObservation']='已查看原生16×16和放大图，分别表现叶柄、食用籽和中心收获物；ID与现有流程保持，最终美术/实机未验'
(o/'item-icon-triage.json').write_text(json.dumps(triage,ensure_ascii=False,indent=2),encoding='utf-8');csvsave(o/'item-icon-triage.csv',triage)
print('README/217/218 and current queue updated; next AR4-Y, expected complexity 5/5.')
