from pathlib import Path
from hashlib import sha256
from PIL import Image,ImageOps,ImageDraw,ImageFont
import json,shutil
r=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');o=Path(__file__).resolve().parent;a=r/'moddev/tfcfarmingplus';res=a/'src/main/resources'
names=['arugula','garland_chrysanthemum','mustard_greens','perilla'];labels=['芝麻菜','茼蒿','芥菜','紫苏']
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def save(name,v):(o/name).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
evidence=[]
java=a/'src/main/java/com/example/tfcfarmingplus/common/MyCrops.java';lines=java.read_text(encoding='utf-8').splitlines()
for name in names:
    model=res/f'assets/tfcfarmingplus/models/item/food/{name}.json';food=res/f'data/tfcfarmingplus/tfc/food/{name}.json'
    guides=[];refs=[]
    for locale in ['zh_cn','en_us']:
        p=res/f'assets/tfc/patchouli_books/field_guide/{locale}/entries/farming_plus/crops.json'
        guides.append({'Path':p.relative_to(r).as_posix(),'SHA256':digest(p),'Pages':[v for v in load(p)['pages'] if v.get('anchor')==name]})
    for base in [res/'data',r/'moddev/tfcagricultureplus/src/main/resources/data']:
        for p in base.rglob('*.json'):
            text=p.read_text(encoding='utf-8-sig')
            if f'tfcfarmingplus:food/{name}' in text:
                refs.append({'Path':p.relative_to(r).as_posix(),'SHA256':digest(p),'JSON':json.loads(text)})
    evidence.append({'Name':name,'CurrentModel':{'Path':model.relative_to(res).as_posix(),'SHA256':digest(model),'JSON':load(model)},'FoodData':{'Path':food.relative_to(res).as_posix(),'SHA256':digest(food),'JSON':load(food)},'Guides':guides,'DeclaredReferences':refs,'JavaSource':str(java),'JavaSHA256':digest(java),'RegistrationLines':[{'Line':i+1,'Text':v} for i,v in enumerate(lines) if name in v or name.upper() in v],'VisualAccepted':False,'RuntimeVerified':False})
save('product-semantics-evidence.json',evidence)
sources=load(o/'generated-source-paths.json');art=[]
for name in names:
    original=Path(sources[name]);preserved=o/'imagegen-source'/(name+'.png');preserved.parent.mkdir(exist_ok=True);shutil.copy2(original,preserved)
    export=o/'exported-candidates'/(name+'_harvest_v1.png');export.parent.mkdir(exist_ok=True)
    with Image.open(original) as im:
        raw_size=list(im.size);small=ImageOps.contain(im.convert('RGBA'),(16,16),Image.Resampling.NEAREST);icon=Image.new('RGBA',(16,16));icon.paste(small,((16-small.width)//2,(16-small.height)//2));icon.save(export)
    art.append({'Name':name,'Tool':'built-in image_gen','OriginalGeneratedPath':str(original),'PreservedSource':preserved.relative_to(r).as_posix(),'OriginalSize':raw_size,'GeneratedSha256':digest(original),'Export':export.relative_to(r).as_posix(),'ExportSize':[16,16],'ExportSha256':digest(export),'AlphaRange':list(icon.getchannel('A').getextrema()),'ExportMethod':'Nearest-neighbor contain to 16x16; preserve aspect ratio and alpha, center on transparent canvas; no recolor or repaint','AdoptedSourcePath':str(res/'assets/tfcfarmingplus/textures/item/food'/export.name),'ModelPath':str(res/f'assets/tfcfarmingplus/models/item/food/{name}.json'),'PromptSet':str(o/'imagegen-prompts.json'),'Adopted':False,'VisualAccepted':False,'RuntimeVerified':False})
save('imagegen-asset-manifest.json',art)
font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',15);smallfont=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',12)
def show(canvas,im,x,y,scale=12):
    d=ImageDraw.Draw(canvas)
    for cy in range(16):
        for cx in range(16):d.rectangle((x+cx*scale,y+cy*scale,x+(cx+1)*scale-1,y+(cy+1)*scale-1),fill=('#30363b' if (cx+cy)%2 else '#282e33'))
    im=im.resize((16*scale,16*scale),Image.Resampling.NEAREST);canvas.paste(im,(x,y),im)
canvas=Image.new('RGB',(1248,4*274),'#202428');d=ImageDraw.Draw(canvas)
for i,name in enumerate(names):
    current=load(res/f'assets/tfcfarmingplus/models/item/food/{name}.json')['textures']['layer0'];texture=current.split(':',1)[1]
    paths=[res/'assets/tfcfarmingplus/textures'/(texture+'.png'),res/f'assets/tfcfarmingplus/textures/item/food/{name}.png',o/f'exported-candidates/{name}_harvest_v1.png']
    for col,path in enumerate(paths):
        x=col*416;y=i*274;im=Image.open(path).convert('RGBA');show(canvas,im,x+12,y+12)
        title=['当前共享图','原同名存图（保留）','16×16新候选'][col];d.text((x+218,y+20),labels[i],font=font,fill='white');d.text((x+218,y+52),title,font=smallfont,fill='white')
        if col==2:show(canvas,im,x+218,y+86,1)
        d.text((x+12,y+218),name,font=font,fill='white');d.text((x+12,y+246),path.name,font=smallfont,fill='#ddd5c4')
canvas.save(o/'AR4Y-current-stored-candidates.png')
canvas=Image.new('RGB',(928,284),'#202428');d=ImageDraw.Draw(canvas)
for i,name in enumerate(names):
    im=Image.open(o/f'exported-candidates/{name}_harvest_v1.png').convert('RGBA');show(canvas,im,i*232+12,12)
    d.text((i*232+12,216),labels[i],font=font,fill='white');show(canvas,im,i*232+12,246,1);d.text((i*232+42,246),'16×16；实机/最终美术未验',font=smallfont,fill='white')
canvas.save(o/'AR4Y-exported-leafy-candidates.png')
print(json.dumps([{'Name':v['Name'],'OriginalSize':v['OriginalSize'],'Alpha':v['AlphaRange']} for v in art],ensure_ascii=False))
