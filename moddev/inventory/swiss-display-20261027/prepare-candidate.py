from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
from hashlib import sha256
import json,shutil,zipfile
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;s=r/'moddev/tfcfarmingplus/src/main/resources'
rawroot=Path('C:/Users/asus/.codex/generated_images/01a10f79-2f78-7943-a187-88601096d4bf')
ids=['7c6dc07e-fa8a-4912-8623-c637883056c0','0f1f98e8-37d6-4cc6-8b79-dd5af2c1f85e','5c76f5a9-372e-453a-8b0f-c913ed8324f2','18c3c2df-2091-4921-8d61-9640de67ff09','266eb496-046a-4830-8f92-6adee0aab970','f3f0856f-c480-4525-818c-c739d8cfb0d8','e126b54b-778f-4e31-aef6-1374a84176fa','32a50599-53bf-4f0a-adc9-093427a8360d']
boxes=[(5,2),(6,3),(8,5),(10,7),(11,9),(12,11),(12,10),(6,3)]
pngs=[f'assets/tfcfarmingplus/textures/block/crop/swiss_chard_age_{i}_leafy_v1.png' for i in range(6)]+['assets/tfcfarmingplus/textures/block/dead_crop/swiss_chard_leafy_v1.png','assets/tfcfarmingplus/textures/block/dead_crop/swiss_chard_young_leafy_v1.png']
candidate=o/'candidate-resources';exports=[];font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',15);page=Image.new('RGB',(1320,520),(38,39,43));draw=ImageDraw.Draw(page)
for i,(id,box,key) in enumerate(zip(ids,boxes,pngs)):
 raw=rawroot/f'exec-{id}.png';shutil.copy2(raw,o/'imagegen-source'/raw.name);im=Image.open(raw).convert('RGBA');bbox=im.getchannel('A').point(lambda a:255 if a>=26 else 0).getbbox();part=im.crop(bbox);part.thumbnail(box,Image.Resampling.NEAREST);sprite=Image.new('RGBA',(16,16));sprite.paste(part,((16-part.width)//2,16-part.height));p=candidate/key;p.parent.mkdir(parents=True,exist_ok=True);sprite.save(p)
 x=i%6*220;y=i//6*260;enlarged=sprite.resize((192,192),Image.Resampling.NEAREST);page.paste(enlarged,(x+12,y+15),enlarged);draw.text((x+10,y+225),f'age{i}' if i<6 else ['dead mature','dead young'][i-6],font=font,fill='white')
 exports.append({'Name':p.stem,'Raw':str(raw),'RawSize':im.size,'VisibleBounds':bbox,'ContentSize':part.size,'RelativePath':key,'ExportSize':[16,16],'SHA256':sha256(p.read_bytes()).hexdigest().upper()})
page.save(o/'AR4AD-final-candidates.png');(o/'imagegen-final-exports.json').write_text(json.dumps(exports,ensure_ascii=False,indent=2),encoding='utf-8')
def texture(key):return key.removeprefix('assets/tfcfarmingplus/textures/').removesuffix('.png')
routes={};proposed={}
def centered():
 return [{'from':[0,0,8],'to':[16,16,8],'shade':False,'faces':{f:{'texture':'#crop','uv':[0,0,16,16]} for f in ['north','south']}},{'from':[8,0,0],'to':[8,16,16],'shade':False,'faces':{f:{'texture':'#crop','uv':[0,0,16,16]} for f in ['east','west']}}]
with zipfile.ZipFile(next((r/'mods').glob('TerraFirmaCraft-*.jar'))) as archive:
 wild_native=json.loads(archive.read('assets/tfc/models/block/wild_crop/crop.json'))
 native_grass=[el for el in wild_native['elements'] if all(f['texture']=='#1' for f in el['faces'].values())]
def put(rel,value):proposed[rel]=value;p=candidate/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(value,separators=(',',':'))+'\n',encoding='utf-8')
for i in range(6):
 model=f'tfcfarmingplus:block/crop/swiss_chard_age_{i}';routes[model]='tfcfarmingplus:'+texture(pngs[i]);put(f'assets/tfcfarmingplus/models/block/crop/swiss_chard_age_{i}.json',{'parent':'minecraft:block/crop','textures':{'crop':routes[model]},'elements':centered()})
for suffix,index in [('',6),('_young',7)]:
 model='tfcfarmingplus:block/dead_crop/swiss_chard'+suffix;routes[model]='tfcfarmingplus:'+texture(pngs[index]);put('assets/tfcfarmingplus/models/block/dead_crop/swiss_chard'+suffix+'.json',{'parent':'minecraft:block/crop','textures':{'crop':routes[model]},'elements':centered()})
for suffix,index in [('',5),('_young',1)]:
 model='tfcfarmingplus:block/wild_crop/swiss_chard'+suffix;routes[model]='tfcfarmingplus:'+texture(pngs[index]);put('assets/tfcfarmingplus/models/block/wild_crop/swiss_chard'+suffix+'.json',{'parent':'tfc:block/wild_crop/crop','textures':{'crop':routes[model]},'elements':centered()+native_grass})
put('assets/tfcfarmingplus/blockstates/wild_crop/swiss_chard.json',{'variants':{'mature=true':{'model':'tfcfarmingplus:block/wild_crop/swiss_chard'},'mature=false':{'model':'tfcfarmingplus:block/wild_crop/swiss_chard_young'}}})
planter=json.loads((s/'data/firmalife/firmalife/plantable/swiss_chard.json').read_bytes());planter['textures']=[routes[f'tfcfarmingplus:block/crop/swiss_chard_age_{i}'] for i in range(6)];put('data/firmalife/firmalife/plantable/swiss_chard.json',planter)
(o/'candidate-paths.json').write_text(json.dumps(sorted(proposed)+pngs,indent=2),encoding='utf-8');(o/'candidate-texture-routes.json').write_text(json.dumps(routes,indent=2),encoding='utf-8')
print('Prepared',len(proposed),'candidate JSONs and',len(pngs),'new sprites.')
