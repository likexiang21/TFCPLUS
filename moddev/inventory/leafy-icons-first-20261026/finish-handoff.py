from pathlib import Path
import json,csv
r=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');o=Path(__file__).resolve().parent;docs=r/'moddev/docs';name='263-ar4y-leafy-food-icons-first-batch-20261026.md'
status='AR4-Y（2026-10-26）四叶菜食品独立图标静态交付完成：芝麻菜/茼蒿/芥菜/紫苏四张16×16候选，原图/食品/玩法/Java/B及手册/模板保持。三查看页/四原稿实看，24检查、259源/包尺寸、418台账及A构建部署/体检通过；43模型/76PNG/40食品和六说明/六模板保护。来源计数仍TFC125/A104，实机/最终美术未验，预期/实际5/5。'
next_step='下一步AR4-Z：生菜、菠菜、牛皮菜、马齿苋独立食品图标，预期5/5。按宽叶、菠菜叶片、明显叶脉/叶柄、肉质小叶逐项制作16×16候选，保留原图/食品/种子/植株/盆栽，延续当前图标与六说明/模板保护、负例和构建交付，不接回旧根果形图。其他生命周期、整书再生差异、农业/AR5/最终TXT及233号仍按260/263号队列保留，开始前报告复杂度。'
p=docs/'217-agriculture-repair-next-phase-plan-20261023.md';t=p.read_text(encoding='utf-8-sig');old=next(x for x in t.splitlines() if x.startswith('**下一步AR4-Y：'));t=t.replace(old,f'**{status}见[263号交接]({name})。**\n\n**{next_step}**');p.write_text(t,encoding='utf-8')
p=docs/'218-agriculture-audit-baseline-20261023.md';t=p.read_text(encoding='utf-8-sig');long_old=old.strip('*');assert t.count(long_old)==1;t=t.replace(long_old,f'四项后续已施工，见[263号]({name})。')
t=t.replace('下一片AR4-Y四叶菜独立图标，预期5/5。','下一片AR4-Z其余四叶菜独立图标，预期5/5。').replace('AR4-X三项图标及说明完成静态交付，见[262号](262-ar4x-special-food-icons-and-guide-20261026.md)',f'AR4-Y首批四叶菜图标完成静态交付，见[263号]({name})')
t+=f'\n- **{status}** 见[263号交接]({name})及当前分诊。{next_step}\n';p.write_text(t,encoding='utf-8')
p=r/'README.md';t=p.read_text(encoding='utf-8-sig');old='下一片AR4-Y芝麻菜/茼蒿/芥菜/紫苏图标，预期5/5。';assert t.count(old)==1;t=t.replace(old,f'四叶菜后续见[263号](moddev/docs/{name})。')
entry=f'- [AR4-Y 首批四叶菜独立食品图标](moddev/docs/{name})：四张独立16×16新候选替代共享叶束，原图/食品/玩法/Java/B和手册/模板保持。24检查、259源/包尺寸、418台账及A构建部署/体检通过，实机/最终美术待验。附[正式路径与来源](moddev/inventory/leafy-icons-first-20261026/imagegen-asset-manifest.json)、[生成提示词](moddev/inventory/leafy-icons-first-20261026/imagegen-prompts.json)和[当前分诊](moddev/inventory/leafy-icons-first-20261026/item-icon-triage.csv)。下一片AR4-Z生菜/菠菜/牛皮菜/马齿苋图标，预期5/5。\n'
anchor='- [K3 烤炉计时与黄油蛋糕修复记录]';assert t.count(anchor)==1;t=t.replace(anchor,entry+anchor);p.write_text(t,encoding='utf-8')
queue=json.loads((r/'moddev/inventory/special-food-icons-20261026/next-work-queue.json').read_text(encoding='utf-8'))
for row in queue:
    if row['顺序']=='V03':row['当前状态']='AR4-Y首四种静态交付；下一片AR4-Z其余四种，预期5/5';row['后续证据']='263号及leafy-icons-first-20261026'
(o/'next-work-queue.json').write_text(json.dumps(queue,ensure_ascii=False,indent=2),encoding='utf-8')
def csvsave(path,rows):
    keys=list(dict.fromkeys(k for v in rows for k in v))
    with path.open('w',encoding='utf-8-sig',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=keys);writer.writeheader()
        for row in rows:writer.writerow({k:json.dumps(v,ensure_ascii=False) if isinstance(v,(dict,list)) else v for k,v in row.items()})
csvsave(o/'next-work-queue.csv',queue)
triage=json.loads((o/'item-icon-triage.json').read_text(encoding='utf-8'))
for row in triage:
    if row.get('ChangedInAR4Y'):row['AR4YObservation']='已查看当前共享图/旧存图/16×16新图和实际源，分别表现裂叶、分裂叶束、宽叶主脉及紫色叶片；最终美术/实机未验'
(o/'item-icon-triage.json').write_text(json.dumps(triage,ensure_ascii=False,indent=2),encoding='utf-8');csvsave(o/'item-icon-triage.csv',triage)
print('README/217/218 and current queue updated; next AR4-Z, expected complexity 5/5.')
