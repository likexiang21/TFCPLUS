from pathlib import Path
from hashlib import sha256
from PIL import Image,ImageDraw,ImageFont
import json,csv
root=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');out=Path(__file__).resolve().parent;backup=root/'moddev/backups/ar4x-special-food-icons-20261026';a=root/'moddev/tfcfarmingplus';res=a/'src/main/resources';names=['rhubarb','sunflower','agave']
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
prior=root/'moddev/inventory/nut-icons-20261026'
refs=load(prior/'current-item-icon-references.json')
for row in refs:
    row['ChangedInAR4X']=row['Family']=='food' and row['Name'] in names
    if row['ChangedInAR4X']:
        p=res/row['Path'];row['Texture']=load(p)['textures']['layer0'];row['ModelSha256']=digest(p)
    assert digest(res/row['Path'])==row['ModelSha256']
save(out/'current-item-icon-references.json',refs)
triage=load(prior/'item-icon-triage.json')
for row in triage:
    row['ChangedInAR4W']=row.pop('ChangeInThisSlice',False)
    changed=row['Family']=='food' and row['Name'] in names
    row['ChangedInAR4X']=changed;row['ChangeInThisSlice']=changed
    if changed:
        row['AR4XPreviousStatus']=row['Status'];row['Status']='AR4-X新增16×16特殊产物候选，最终美术/实机未验'
        row['CurrentSourceTexture']=load(res/f'assets/tfcfarmingplus/models/item/food/{row["Name"]}.json')['textures']['layer0']
        p=res/f'assets/tfcfarmingplus/models/item/food/{row["Name"]}.json';row['CurrentSourceModelSha256']=digest(p)
        row['AR4XObservation']='已实际查看16×16原生及放大图，替代旧水果外形；叶柄/食用籽/中心收获物仅图形表达，ID及现有流程保持'
        row['LastReview']='AR4-X'
save(out/'item-icon-triage.json',triage)
fields=list(dict.fromkeys(k for r in triage for k in r))
with (out/'item-icon-triage.csv').open('w',encoding='utf-8-sig',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=fields);writer.writeheader()
    for row in triage:writer.writerow({k:json.dumps(v,ensure_ascii=False) if isinstance(v,(dict,list)) else v for k,v in row.items()})

sizes=[]
for family in ['food','seeds']:
    for p in sorted((res/'assets/tfcfarmingplus/textures/item'/family).glob('*.png')):
        with Image.open(p) as im: assert im.size==(16,16);size=list(im.size)
        sizes.append({'Path':p.relative_to(root).as_posix(),'Size':size,'SHA256':digest(p)})
assert len(sizes)==255;save(out/'item-texture-sizes.json',sizes)
save(out/'triage-summary.json',{'ModelsReconciled':229,'TFCTextureModels':sum(r['Texture'].startswith('tfc:') for r in refs),'OwnTextureModels':sum(r['Texture'].startswith('tfcfarmingplus:') for r in refs),'TFCSeedTextureModels':sum(r['Family']=='seeds' and r['Texture'].startswith('tfc:') for r in refs),'ChangedFoodModels':3,'NewPNGs':3,'ExistingPNGsModified':0,'ItemFoodSeedPNGsSizeChecked':255,'AR4VConfirmedFoodMismatchesRemaining':[r['Name'] for r in triage if r['Status']=='AR4-V确认图像内容错配；待独立美术'],'OtherArtAndLifecycleBacklogRemains':True,'VisualAccepted':False,'RuntimeVerified':False})

diff={'Changed':[],'Added':[],'Removed':[],'Counts':{}}
for prefix in ['moddev/tfcfarmingplus/src','moddev/tfcfarmingplus/tools','moddev/tfcagricultureplus/src','moddev/tfcagricultureplus/tools']:
    old={p.relative_to(backup).as_posix():p for p in (backup/prefix).rglob('*') if p.is_file()}
    now={p.relative_to(root).as_posix():p for p in (root/prefix).rglob('*') if p.is_file()}
    diff['Changed']+=sorted(p for p in old.keys()&now.keys() if digest(old[p])!=digest(now[p]))
    diff['Added']+=sorted(now.keys()-old.keys());diff['Removed']+=sorted(old.keys()-now.keys());diff['Counts'][prefix.removeprefix('moddev/')]=len(now)
for k in ['Changed','Added','Removed']:diff[k].sort()
assert len(diff['Changed'])==9 and len(diff['Added'])==3 and not diff['Removed'];save(out/'review-manifest.json',diff)

canvas=Image.new('RGB',(696,300),'#202428');draw=ImageDraw.Draw(canvas)
font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',16);small=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',12)
for i,name in enumerate(names):
    model=load(res/f'assets/tfcfarmingplus/models/item/food/{name}.json');texture=model['textures']['layer0'].split(':',1)[1]
    icon=Image.open(res/'assets/tfcfarmingplus/textures'/(texture+'.png')).convert('RGBA')
    for cy in range(16):
        for cx in range(16):draw.rectangle((i*232+12+cx*12,12+cy*12,i*232+23+cx*12,23+cy*12),fill=('#30363b' if (cx+cy)%2 else '#282e33'))
    image=icon.resize((192,192),Image.Resampling.NEAREST);canvas.paste(image,(i*232+12,12),image)
    draw.text((i*232+12,219),name,font=font,fill='white')
    draw.text((i*232+12,248),Path(texture).name,font=small,fill='white')
    draw.text((i*232+12,271),'16×16；最终美术/实机未验',font=small,fill='#ddd5c4')
canvas.save(out/'AR4X-current-source-icons.png')
print(json.dumps({'ChangedExisting':9,'AddedPNG':3,'Models':43,'ProtectedPNG':72,'FoodData':40,'ItemPNGs16x16':255,'Counts':diff['Counts']},ensure_ascii=False))
