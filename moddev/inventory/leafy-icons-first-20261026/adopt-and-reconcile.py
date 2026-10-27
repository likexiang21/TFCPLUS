from pathlib import Path
from hashlib import sha256
from PIL import Image, ImageDraw, ImageFont
import json, shutil, csv

root=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out=Path(__file__).resolve().parent
backup=root/'moddev/backups/ar4y-leafy-icons-first-20261026'
a=root/'moddev/tfcfarmingplus'; res=a/'src/main/resources'
names=['arugula','garland_chrysanthemum','mustard_greens','perilla']
def digest(p): return sha256(p.read_bytes()).hexdigest().upper()
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v): p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

before=load(backup/'backup-manifest.json'); assert len(before)==9163
for row in before:
    current=Path(r'D:\TFC农业重置\PCL_TFC\mods')/Path(row['path']).name if row['path'].startswith('pcl-mods/') else root/row['path']
    assert digest(current)==row['sha256']==digest(backup/row['path']), row['path']

evidence=load(out/'product-semantics-evidence.json')
for r in evidence:
    for entry in [r['CurrentModel'],r['FoodData']]:
        assert digest(res/entry['Path'])==entry['SHA256'],entry['Path']
    for entry in r['DeclaredReferences']:
        assert digest(root/entry['Path'])==entry['SHA256'],entry['Path']

contract_path=a/'tools/reviewed-item-icon-routes.json';contract=load(contract_path)
assert contract['Version']==9 and len(contract['Routes'])==43 and len(contract['ProtectedTextureSha256'])==72 and len(contract['FoodDataSha256'])==40
art=load(out/'imagegen-asset-manifest.json')
for row in art:
    name=row['Name']; model=Path(row['ModelPath']); old=load(model)
    assert old['textures']=={'layer0':'tfcfarmingplus:item/food/kale'}
    target=Path(row['AdoptedSourcePath']); assert not target.exists()
    export=root/row['Export']; assert digest(export)==row['ExportSha256']
    with Image.open(export) as im: assert im.size==(16,16) and im.mode=='RGBA'
    shutil.copy2(export,target)
    old['textures']['layer0']=f'tfcfarmingplus:item/food/{name}_harvest_v1';save(model,old)
    route=next(v for v in contract['Routes'] if v['Path']==model.relative_to(res).as_posix());assert route['Texture']=='tfcfarmingplus:item/food/kale';route['Texture']=old['textures']['layer0']
    for p in [res/f'assets/tfcfarmingplus/textures/item/food/{name}.png',target]:
        contract['ProtectedTextureSha256'][p.relative_to(res).as_posix()]=digest(p)
    food=res/f'data/tfcfarmingplus/tfc/food/{name}.json'
    contract['FoodDataSha256'][food.relative_to(res).as_posix()]=digest(food)
    row['Adopted']=True
contract['Version']=10
contract['AR4YArtReview']=[{'Name':n,'Origin':'built-in image_gen candidate, exported to 16x16','Status':'reviewed offline; final art and runtime acceptance pending','VisualAccepted':False,'RuntimeVerified':False} for n in names]
assert len(contract['Routes'])==43 and len(contract['ProtectedTextureSha256'])==76 and len(contract['FoodDataSha256'])==40
save(contract_path,contract);save(out/'imagegen-asset-manifest.json',art)

prior=root/'moddev/inventory/special-food-icons-20261026'
refs=load(prior/'current-item-icon-references.json')
for row in refs:
    row['ChangedInAR4Y']=row['Family']=='food' and row['Name'] in names
    if row['ChangedInAR4Y']:
        p=res/row['Path'];row['Texture']=load(p)['textures']['layer0'];row['ModelSha256']=digest(p)
    assert digest(res/row['Path'])==row['ModelSha256']
save(out/'current-item-icon-references.json',refs)
triage=load(prior/'item-icon-triage.json')
for row in triage:
    row['ChangedInAR4X']=row.pop('ChangeInThisSlice',False)
    changed=row['Family']=='food' and row['Name'] in names
    row['ChangedInAR4Y']=changed;row['ChangeInThisSlice']=changed
    if changed:
        row['AR4YPreviousStatus']=row['Status'];row['Status']='AR4-Y新增16×16独立叶菜候选，最终美术/实机未验'
        row['CurrentSourceTexture']=f'tfcfarmingplus:item/food/{row["Name"]}_harvest_v1'
        p=res/f'assets/tfcfarmingplus/models/item/food/{row["Name"]}.json';row['CurrentSourceModelSha256']=digest(p)
        row['AR4YObservation']='已实际查看16×16原生及放大图，替代共享叶束；叶片构图只作辨识表达，不新增食品或产量'
        row['LastReview']='AR4-Y'
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
assert len(sizes)==259;save(out/'item-texture-sizes.json',sizes)
save(out/'triage-summary.json',{'ModelsReconciled':229,'TFCTextureModels':sum(r['Texture'].startswith('tfc:') for r in refs),'OwnTextureModels':sum(r['Texture'].startswith('tfcfarmingplus:') for r in refs),'TFCSeedTextureModels':sum(r['Family']=='seeds' and r['Texture'].startswith('tfc:') for r in refs),'ChangedFoodModels':4,'NewPNGs':4,'ExistingPNGsModified':0,'ItemFoodSeedPNGsSizeChecked':259,'AR4VConfirmedFoodMismatchesRemaining':[r['Name'] for r in triage if r['Status']=='AR4-V确认图像内容错配；待独立美术'],'OtherArtAndLifecycleBacklogRemains':True,'VisualAccepted':False,'RuntimeVerified':False})

diff={'Changed':[],'Added':[],'Removed':[],'Counts':{}}
for prefix in ['moddev/tfcfarmingplus/src','moddev/tfcfarmingplus/tools','moddev/tfcagricultureplus/src','moddev/tfcagricultureplus/tools']:
    old={p.relative_to(backup).as_posix():p for p in (backup/prefix).rglob('*') if p.is_file()}
    now={p.relative_to(root).as_posix():p for p in (root/prefix).rglob('*') if p.is_file()}
    diff['Changed']+=sorted(p for p in old.keys()&now.keys() if digest(old[p])!=digest(now[p]))
    diff['Added']+=sorted(now.keys()-old.keys());diff['Removed']+=sorted(old.keys()-now.keys());diff['Counts'][prefix.removeprefix('moddev/')]=len(now)
for k in ['Changed','Added','Removed']:diff[k].sort()
assert len(diff['Changed'])==5 and len(diff['Added'])==4 and not diff['Removed'];save(out/'review-manifest.json',diff)

canvas=Image.new('RGB',(928,300),'#202428');draw=ImageDraw.Draw(canvas)
font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',16);small=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',12)
for i,name in enumerate(names):
    model=load(res/f'assets/tfcfarmingplus/models/item/food/{name}.json');texture=model['textures']['layer0'].split(':',1)[1]
    icon=Image.open(res/'assets/tfcfarmingplus/textures'/(texture+'.png')).convert('RGBA')
    for cy in range(16):
        for cx in range(16):draw.rectangle((i*232+12+cx*12,12+cy*12,i*232+23+cx*12,23+cy*12),fill=('#30363b' if (cx+cy)%2 else '#282e33'))
    image=icon.resize((192,192),Image.Resampling.NEAREST);canvas.paste(image,(i*232+12,12),image)
    draw.text((i*232+12,219),name,font=font,fill='white')
    draw.text((i*232+12,248),'harvest_v1 / 16x16',font=small,fill='white')
    draw.text((i*232+12,271),'16×16；最终美术/实机未验',font=small,fill='#ddd5c4')
canvas.save(out/'AR4Y-current-source-icons.png')
print(json.dumps({'ChangedExistingJSON':5,'AddedPNG':4,'IconModels':43,'ProtectedPNGs':76,'ProtectedFoodData':40,'ItemPNGs16x16':259,'Counts':diff['Counts']},ensure_ascii=False))
