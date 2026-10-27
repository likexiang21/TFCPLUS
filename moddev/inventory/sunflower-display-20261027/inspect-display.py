"""Read actual source/dependencies and export isolated whole-plant previews."""
from pathlib import Path
import copy, hashlib, io, json, zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
SRC = ROOT/'moddev/tfcfarmingplus/src/main/resources'
sources = [SRC, ROOT/'moddev/tfcagricultureplus/src/main/resources']
archives = [zipfile.ZipFile(p) for p in sorted((ROOT/'mods').glob('*.jar'))]
archives += [zipfile.ZipFile(Path('D:/TFC农业重置/.tooling/game/versions/1.21.1/1.21.1.jar'))]
evidence = {}

def read(key):
    for src in reversed(sources):
        if (src/key).is_file():
            data=(src/key).read_bytes(); origin=str(src/key); break
    else:
        for archive in archives:
            if key in archive.namelist():
                data=archive.read(key); origin=archive.filename+'!/'+key; break
        else: raise FileNotFoundError(key)
    evidence[key]={'Origin':origin,'Sha256':hashlib.sha256(data).hexdigest().upper()}
    return data

def resource(identifier,kind,extension):
    ns,rel=(identifier if ':' in identifier else 'minecraft:'+identifier).split(':',1)
    return f'assets/{ns}/{kind}/{rel}.{extension}'

def model(identifier):
    key=resource(identifier,'models','json'); value=json.loads(read(key))
    parent=value.get('parent')
    result=model(parent) if parent and not parent.startswith('builtin/') else {}
    textures=result.get('textures',{}) | value.get('textures',{})
    result.update(value); result['textures']=textures
    return result

def slot(value,textures):
    seen=set()
    while value.startswith('#'):
        assert value not in seen; seen.add(value); value=textures[value[1:]]
    return value

def flattened(parts):
    elements=[]; textures={}
    for index,(identifier,offset) in enumerate(parts):
        resolved=model(identifier)
        for original in resolved['elements']:
            item=copy.deepcopy(original)
            for end in ['from','to']: item[end][1]+=offset
            if 'rotation' in item: item['rotation']['origin'][1]+=offset
            for face in item['faces'].values():
                key=f'p{index}_{len(textures)}'
                textures[key]=slot(face['texture'],resolved['textures']); face['texture']='#'+key
            elements.append(item)
    return {'ambientocclusion':False,'textures':textures,'elements':elements}

def save(key,data,assets):
    target=assets/key.removeprefix('assets/'); target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(data)

font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',14)
def sheet(cells,name,cols=6):
    w,h=204,300
    canvas=Image.new('RGB',(w*cols,h*((len(cells)+cols-1)//cols)),(37,39,43)); d=ImageDraw.Draw(canvas)
    for i,(label,keys) in enumerate(cells):
        images=[Image.open(io.BytesIO(read(key))).convert('RGBA') for key in keys]
        im=Image.new('RGBA',(max(x.width for x in images),sum(x.height for x in images)))
        y=0
        for x in images: im.paste(x,(0,y)); y+=x.height
        im.thumbnail((176,244),Image.Resampling.NEAREST)
        im=im.resize((im.width*max(1,min(176//im.width,244//im.height)),im.height*max(1,min(176//im.width,244//im.height))),Image.Resampling.NEAREST)
        x,y=i%cols*w,i//cols*h
        canvas.paste(im,(x+(w-im.width)//2,y+244-im.height),im)
        for line,text in enumerate(label.split('\n')): d.text((x+5,y+248+line*16),text,font=font,fill='white')
    canvas.save(OUT/name)

assets=OUT/'assets-before'
states={kind:json.loads(read(f'assets/tfcfarmingplus/blockstates/{kind}/sunflower.json')) for kind in ['crop','wild_crop','dead_crop']}
selected=[]
cells=[]
for age in range(6):
    keys=[f'age={age}'] if age<3 else [f'age={age},part=bottom',f'age={age},part=top']
    parts=[(states['crop']['variants'][key]['model'],16*idx) for idx,key in enumerate(keys)]
    full=flattened(parts); name=f'ar4aa:preview/before_age_{age}'; selected.append(name)
    save(resource(name,'models','json'),json.dumps(full).encode(),assets)
    textures=[resource(model(identifier)['textures']['crop'],'textures','png') for identifier,_ in reversed(parts)]
    cells.append((f'LIVE age {age}',textures))
for kind in ['wild_crop','dead_crop']:
    for label,keys in [('young',['mature=false']),('mature',['mature=true'] if kind=='wild_crop' else ['mature=true,part=bottom','mature=true,part=top'])]:
        parts=[(states[kind]['variants'][key]['model'],16*idx) for idx,key in enumerate(keys)]
        name=f'ar4aa:preview/before_{kind}_{label}'; selected.append(name)
        save(resource(name,'models','json'),json.dumps(flattened(parts)).encode(),assets)
for item in ['food','seeds']:
    texture=model(f'tfcfarmingplus:item/{item}/sunflower')['textures']['layer0']
    cells.append((f'LIVE {item}',[resource(texture,'textures','png')]))
sheet(cells,'AR4AA-live-textures.png',4)
stored=[]
for age in range(6):
    names=[f'sunflower_age_{age}'] if age<3 else [f'sunflower_age_{age}_top',f'sunflower_age_{age}_bottom']
    stored.append((f'STORED age {age}',[f'assets/tfcfarmingplus/textures/block/crop/{x}.png' for x in names]))
for suffix in ['3_top_2','4_top_2','5_top_2','5_top_3']:
    stored.append((f'UNUSED age {suffix}',[f'assets/tfcfarmingplus/textures/block/crop/sunflower_age_{suffix}.png']))
for kind,name in [('wild_crop','sunflower'),('dead_crop','sunflower'),('dead_crop','sunflower_young'),('item/seeds','sunflower')]:
    key=f'assets/tfcfarmingplus/textures/{kind if kind.startswith("item/") else "block/"+kind}/{name}.png'
    stored.append((f'STORED {kind}',[key]))
sheet(stored,'AR4AA-stored-textures.png',5)
for key in list(evidence):
    if key.endswith('.png'): save(key,read(key),assets)
(OUT/'before-models.txt').write_text('\n'.join(selected)+'\n',encoding='utf-8')
(OUT/'before-source-evidence.json').write_text(json.dumps({'Sources':evidence,'States':states,'VisualAccepted':False,'RuntimeVerified':False},indent=2),encoding='utf-8')
for archive in archives: archive.close()
print('Exported actual whole models and texture sheets:',len(evidence))
