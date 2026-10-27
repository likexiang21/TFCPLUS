from pathlib import Path
from PIL import Image
import json,shutil,zipfile
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;s=r/'moddev/tfcfarmingplus/src/main/resources'
candidate=o/'candidate-v2-resources'
manifest=json.loads((o/'native-grid-manifest.json').read_text(encoding='utf-8'));pngs=[]
for row in manifest['Assets']:
 name=row['Name'];folder='crop' if '_age_' in name else 'dead_crop';key=f'assets/tfcfarmingplus/textures/block/{folder}/{name}.png';pngs.append(key);target=candidate/key;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(row['PNG'],target)
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
