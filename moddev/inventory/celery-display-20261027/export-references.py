from pathlib import Path
from hashlib import sha256
from PIL import Image, ImageDraw, ImageFont
import json, zipfile

o=Path(__file__).resolve().parent
r=o.parents[2]
s=r/'moddev/tfcfarmingplus/src/main/resources'
font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',14)
cells=[];manifest=[];dumps=[]
with zipfile.ZipFile(next((r/'mods').glob('TerraFirmaCraft-*.jar'))) as jar:
    for species in ['onion','carrot','soybean']:
        for age in range(6):
            key=f'assets/tfc/textures/block/crop/{species}_{age}.png'
            if key not in jar.namelist():
                continue
            data=jar.read(key);p=o/'native-reference'/f'{species}_{age}.png';p.parent.mkdir(exist_ok=True);p.write_bytes(data)
            cells.append((f'TFC {species} {age}',p))
            manifest.append({'Resource':key,'Origin':jar.filename,'SHA256':sha256(data).hexdigest().upper()})
            im=Image.open(p).convert('RGBA');colors=sorted(set(im.getdata())-{(0,0,0,0)});colors=[c for c in colors if c[3]]
            symbols={c:chr(65+i) for i,c in enumerate(colors)}
            dumps.append(key+'\n'+str({symbols[c]:c for c in colors})+'\n'+'\n'.join(''.join(symbols.get(im.getpixel((x,y)),'.') for x in range(16)) for y in range(16)))
    for key in ['assets/tfc/models/block/wild_crop/crop.json','assets/tfc/textures/block/crop/wild_crop_grass.png']:
        data=jar.read(key);manifest.append({'Resource':key,'Origin':jar.filename,'SHA256':sha256(data).hexdigest().upper()})
for folder,names in [('crop',[f'celery_age_{i}' for i in range(6)]),('wild_crop',['celery']),('dead_crop',['celery','celery_young']),('item/food',['celery','celery_stalks_v1']),('item/seeds',['celery'])]:
    for name in names:
        path=s/f'assets/tfcfarmingplus/textures/{"block/" if not folder.startswith("item/") else ""}{folder}/{name}.png'
        cells.append(('Saved '+folder+'/'+name,path))
canvas=Image.new('RGB',(1200,((len(cells)+5)//6)*235),(36,38,42));draw=ImageDraw.Draw(canvas)
for i,(label,p) in enumerate(cells):
    im=Image.open(p).convert('RGBA').resize((176,176),Image.Resampling.NEAREST);x=i%6*200;y=i//6*235
    canvas.paste(im,(x+10,y+8),im);draw.text((x+6,y+190),label[:24],font=font,fill='white');draw.text((x+6,y+209),label[24:],font=font,fill='white')
canvas.save(o/'AR4AE-original-reference-and-saved.png')
(o/'native-reference-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(o/'native-pixel-dumps.txt').write_text('\n\n'.join(dumps),encoding='utf-8')
print('Exported native references and all twelve saved celery sprites.')
