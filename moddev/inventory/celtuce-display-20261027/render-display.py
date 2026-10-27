"""Resolve actual models and native planter coordinates, no gameplay simulation."""
exec((__import__('pathlib').Path(__file__).parent/'prepare-before.py').read_text(encoding='utf-8').split('assets=OUT/')[0])
import sys
published='--source' in sys.argv
if not published:sources.append(OUT/'candidate-v2-resources')
assets=OUT/('assets-current' if published else 'assets-candidate');label='current' if published else 'candidate';selected=[]
names=[f'tfcfarmingplus:block/crop/celtuce_age_{i}' for i in range(6)]+['tfcfarmingplus:block/wild_crop/celtuce','tfcfarmingplus:block/wild_crop/celtuce_young','tfcfarmingplus:block/dead_crop/celtuce','tfcfarmingplus:block/dead_crop/celtuce_young']
for i,name in enumerate(names):
 identifier=f'ar4af:{label}/m{i:02}';selected.append(identifier);value=flattened([(name,0)]);save(resource(identifier,'models','json'),json.dumps(value).encode(),assets)
 for texture in value['textures'].values():read(resource(texture,'textures','png'))
plantable='data/firmalife/firmalife/plantable/celtuce.json';data=json.loads(((SRC if published else OUT/'candidate-v2-resources')/plantable).read_bytes())
for stage,texture in enumerate(data['textures']):
 identifier=f'ar4af:{label}/planter{stage}';selected.append(identifier);elements=[]
 for angle in [-45,45]:elements.append({'from':[4.5-2.5*2**0.5,5,4.5],'to':[4.5+2.5*2**0.5,11.6656,4.5],'shade':False,'rotation':{'origin':[4.5,0,4.5],'axis':'y','angle':angle},'faces':{f:{'texture':'#crop','uv':[2,0,14,16]} for f in ['north','south']}})
 save(resource(identifier,'models','json'),json.dumps({'textures':{'crop':texture},'elements':elements}).encode(),assets);read(resource(texture,'textures','png'))
for key in list(evidence):
 if key.endswith('.png'):save(key,read(key),assets)
(OUT/f'{label}-models.txt').write_text('\n'.join(selected)+'\n',encoding='utf-8');(OUT/f'{label}-preview-sources.json').write_text(json.dumps({'Sources':evidence,'Planter':data,'PlanterBaseOmitted':True,'VisualAccepted':False,'RuntimeVerified':False},indent=2),encoding='utf-8')
for archive in archives:archive.close()
print('Resolved',len(selected),'display models from',label)
