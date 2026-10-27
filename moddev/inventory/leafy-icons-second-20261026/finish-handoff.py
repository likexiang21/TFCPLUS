from pathlib import Path
import json,csv
r=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');o=Path(__file__).resolve().parent;docs=r/'moddev/docs';name='264-ar4z-leafy-food-icons-second-batch-20261026.md'
status='AR4-Z（2026-10-26）后四叶菜食品图标静态交付完成：生菜/菠菜/牛皮菜/马齿苋四张16×16候选，原图/食品/玩法/Java/B及手册/模板保持。同步菠菜专用与统一保护，三查看页/四原稿实看，29检查、44图标/17菠菜安全JSON、263源/包尺寸、418台账及A构建部署/体检通过；44模型/81PNG/41食品、六说明/六模板及菠菜10状态/13PNG保护。八种共享叶束组静态接线完成，实机/最终美术未验，预期/实际5/5。'
next_step='下一步AR4-AA：向日葵完整两格显示链审查与修复，预期5/5。先核当前Java年龄/part、bottom/top实际模型及保存素材，再按两格整株查看六龄、花盘、野生/死株、种子/盆栽；保护已修食用籽图和玩法，不盲接旧图或虚造第三/四格。依据几何/UV和实际差异补保护、预览与构建交付。菠菜盆栽、牛皮菜文字歧义、其他农业/整书再生/AR5/最终TXT及233号继续保留，开始前报告复杂度。'
p=docs/'217-agriculture-repair-next-phase-plan-20261023.md';t=p.read_text(encoding='utf-8-sig');old=next(x for x in t.splitlines() if x.startswith('**下一步AR4-Z：'));t=t.replace(old,f'**{status}见[264号交接]({name})。**\n\n**{next_step}**');p.write_text(t,encoding='utf-8')
p=docs/'218-agriculture-audit-baseline-20261023.md';t=p.read_text(encoding='utf-8-sig');long_old=old.strip('*');assert t.count(long_old)==1;t=t.replace(long_old,f'后四项已静态交付，见[264号]({name})。')
t=t.replace('下一片AR4-Z其余四叶菜独立图标，预期5/5。','下一片AR4-AA向日葵两格显示链，预期5/5。').replace('AR4-Y首批四叶菜图标完成静态交付，见[263号](263-ar4y-leafy-food-icons-first-batch-20261026.md)',f'AR4-Z共享叶菜组图标完成静态交付，见[264号]({name})')
t+=f'\n- **{status}** 见[264号交接]({name})及当前分诊。{next_step}\n';p.write_text(t,encoding='utf-8')
p=r/'README.md';t=p.read_text(encoding='utf-8-sig');old='下一片AR4-Z生菜/菠菜/牛皮菜/马齿苋图标，预期5/5。';assert t.count(old)==1;t=t.replace(old,f'后四叶菜见[264号](moddev/docs/{name})。')
entry=f'- [AR4-Z 后四叶菜食品图标与菠菜双重保护](moddev/docs/{name})：四张16×16独立候选，原图/食品/玩法/Java/B保持；菠菜专用保护同步，八共享叶菜组静态接线完成。29检查、44/17安全JSON、263源/包尺寸、418台账及A构建部署/体检通过，实机/最终美术待验。附[正式路径与来源](moddev/inventory/leafy-icons-second-20261026/imagegen-asset-manifest.json)、[生成提示词](moddev/inventory/leafy-icons-second-20261026/imagegen-prompts.json)和[当前分诊](moddev/inventory/leafy-icons-second-20261026/item-icon-triage.csv)。下一片AR4-AA向日葵完整两格显示链，预期5/5。\n'
anchor='- [K3 烤炉计时与黄油蛋糕修复记录]';assert t.count(anchor)==1;t=t.replace(anchor,entry+anchor);p.write_text(t,encoding='utf-8')
queue=json.loads((r/'moddev/inventory/leafy-icons-first-20261026/next-work-queue.json').read_text(encoding='utf-8'))
for row in queue:
    if row['顺序']=='V03':row['当前状态']='AR4-Y/Z八种静态交付，实机/最终美术未验';row['后续证据']='263/264号'
    if row['顺序']=='V04':row['当前状态']='下一片AR4-AA，预期5/5'
    if row['顺序']=='V06':row['待复核文字']='牛皮菜“割了还会再长”与普通crop注册的交互含义；本片未判为玩法故障'
(o/'next-work-queue.json').write_text(json.dumps(queue,ensure_ascii=False,indent=2),encoding='utf-8')
def csvsave(path,rows):
    keys=list(dict.fromkeys(k for v in rows for k in v))
    with path.open('w',encoding='utf-8-sig',newline='') as stream:
        writer=csv.DictWriter(stream,fieldnames=keys);writer.writeheader()
        for row in rows:writer.writerow({k:json.dumps(v,ensure_ascii=False) if isinstance(v,(dict,list)) else v for k,v in row.items()})
csvsave(o/'next-work-queue.csv',queue)
triage=json.loads((o/'item-icon-triage.json').read_text(encoding='utf-8'))
for row in triage:
    if row.get('ChangedInAR4Z'):row['AR4ZObservation']='已查看共享图/旧图/原生16×16新图及实际源，分别表现浅色褶叶、深绿叶片、厚叶柄叶脉及圆厚小叶；最终美术/实机未验'
(o/'item-icon-triage.json').write_text(json.dumps(triage,ensure_ascii=False,indent=2),encoding='utf-8');csvsave(o/'item-icon-triage.csv',triage)
print('README/217/218 and current queue updated; next AR4-AA, expected complexity 5/5.')
