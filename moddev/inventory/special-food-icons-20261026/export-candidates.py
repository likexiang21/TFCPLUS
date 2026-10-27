from pathlib import Path
from hashlib import sha256
from PIL import Image, ImageOps, ImageDraw, ImageFont
import json, shutil, zipfile, io

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
res = root / 'moddev/tfcfarmingplus/src/main/resources'
names = ['rhubarb', 'sunflower', 'agave']
zh = ['大黄','向日葵','龙舌兰']
sources = json.loads((out / 'generated-source-paths.json').read_text(encoding='utf-8'))
manifest = []
for name in names:
    source = Path(sources[name])
    preserved = out / 'imagegen-source' / (name + '.png')
    preserved.parent.mkdir(exist_ok=True)
    shutil.copy2(source,preserved)
    exported = out / 'exported-candidates' / (name + '_harvest_v1.png')
    exported.parent.mkdir(exist_ok=True)
    with Image.open(source) as original:
        original_size = list(original.size)
        rgba = original.convert('RGBA')
        smaller = ImageOps.contain(rgba,(16,16),Image.Resampling.NEAREST)
        icon = Image.new('RGBA',(16,16))
        icon.paste(smaller,((16-smaller.width)//2,(16-smaller.height)//2))
        icon.save(exported)
    manifest.append({'Name':name,'Tool':'built-in image_gen','OriginalGeneratedPath':str(source),
                     'PreservedSource':preserved.relative_to(root).as_posix(),'OriginalSize':original_size,
                     'GeneratedSha256':sha256(source.read_bytes()).hexdigest().upper(),
                     'Export':exported.relative_to(root).as_posix(),'ExportSize':[16,16],
                     'ExportSha256':sha256(exported.read_bytes()).hexdigest().upper(),'AlphaRange':list(icon.getchannel('A').getextrema()),
                     'ExportMethod':'Nearest-neighbor contain to 16x16, preserve aspect ratio and alpha, centered transparent canvas; no recolor or repaint',
                     'AdoptedSourcePath':str(res/'assets/tfcfarmingplus/textures/item/food'/exported.name),
                     'ModelPath':str(res/'assets/tfcfarmingplus/models/item/food'/(name+'.json')),
                     'PromptSet':str(out/'imagegen-prompts.json'),'Adopted':False,'VisualAccepted':False,'RuntimeVerified':False})
(out/'imagegen-asset-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
font = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',17)
small = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',13)
def square(canvas, image, x,y,scale):
    draw=ImageDraw.Draw(canvas)
    for cy in range(16):
        for cx in range(16):
            draw.rectangle((x+cx*scale,y+cy*scale,x+(cx+1)*scale-1,y+(cy+1)*scale-1), fill=('#30363b' if (cx+cy)%2 else '#282e33'))
    image=image.resize((16*scale,16*scale),Image.Resampling.NEAREST)
    canvas.paste(image,(x,y),image)
for page, subset in enumerate([names],1):
    canvas=Image.new('RGB',(900,284*len(subset)),'#202428');draw=ImageDraw.Draw(canvas)
    for row,name in enumerate(subset):
        y=row*284
        model=json.loads((res/f'assets/tfcfarmingplus/models/item/food/{name}.json').read_text(encoding='utf-8'));texture=model['textures']['layer0'].split(':',1)[1]
        with zipfile.ZipFile(root/'mods/TerraFirmaCraft-NeoForge-1.21.1-4.2.11.jar') as archive: old=Image.open(io.BytesIO(archive.read('assets/tfc/textures/'+texture+'.png'))).convert('RGBA')
        new=Image.open(out/f'exported-candidates/{name}_harvest_v1.png').convert('RGBA')
        square(canvas,old,12,y+12,12);square(canvas,new,456,y+12,12)
        draw.text((218,y+22),zh[names.index(name)]+' '+name,font=font,fill='white')
        draw.text((218,y+60),'当前实际引用 / 原图保留',font=small,fill='#ddd5c4')
        draw.text((662,y+22),'16×16 新候选',font=font,fill='white')
        square(canvas,new,662,y+61,1)
        draw.text((662,y+95),'原生尺寸',font=small,fill='white')
        draw.text((12,y+224),name+'.png',font=small,fill='white')
        draw.text((456,y+224),name+'_harvest_v1.png',font=small,fill='white')
        draw.text((456,y+251),'最终美术与实机未验',font=small,fill='#ddd5c4')
    canvas.save(out/f'AR4X-before-and-candidates-p{page}.png')
canvas=Image.new('RGB',(3*232,300),'#202428');draw=ImageDraw.Draw(canvas)
for i,name in enumerate(names):
    icon=Image.open(out/f'exported-candidates/{name}_harvest_v1.png').convert('RGBA')
    square(canvas,icon,i*232+12,12,12)
    draw.text((i*232+12,218),zh[i]+' '+name,font=font,fill='white')
    square(canvas,icon,i*232+12,251,1)
    draw.text((i*232+42,251),'16×16；实机未验',font=small,fill='white')
canvas.save(out/'AR4X-exported-special-candidates.png')
print(json.dumps([{'Name':r['Name'],'OriginalSize':r['OriginalSize'],'ExportSize':r['ExportSize'],'Alpha':r['AlphaRange']} for r in manifest],ensure_ascii=False))
