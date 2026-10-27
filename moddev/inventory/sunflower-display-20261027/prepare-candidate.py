"""Independent display geometry using preserved project artwork; no game changes."""
exec((__import__('pathlib').Path(__file__).parent/'inspect-display.py').read_text(encoding='utf-8').split('assets=OUT/')[0])
assets=OUT/'assets-candidate'
proposed={}
def put(rel,value): proposed[rel]=value
def planes(y0=0,y1=16,uv=None,texture='crop'):
    uv=uv or [0,0,16,16]
    return [
        {'from':[0,y0,8],'to':[16,y1,8],'shade':False,'faces':{face:{'uv':uv,'texture':'#'+texture} for face in ['north','south']}},
        {'from':[8,y0,0],'to':[8,y1,16],'shade':False,'faces':{face:{'uv':uv,'texture':'#'+texture} for face in ['east','west']}}
    ]
def shape(texture,elements,extra=None):
    return {'ambientocclusion':False,'textures':{'crop':texture,'particle':'#crop'} | (extra or {}),'elements':elements}
def head(x0,y0,x1,y1,uv=None):
    return {'from':[x0,y0,7.9],'to':[x1,y1,7.9],'shade':False,'faces':{f:{'texture':'#head','uv':uv or [0,0,16,16]} for f in ['north','south']}}
for age in range(6):
    parts=[''] if age<3 else ['_bottom','_top']
    for part in parts:
        identifier=f'crop/sunflower_age_{age}{part}'
        tex=f'tfcfarmingplus:block/{identifier}'
        elements=planes()
        extra=None
        if part=='_top':
            elements=planes(0,8,[0,8,16,16])
            texture='sunflower_age_5_top_3' if age==3 else f'sunflower_age_{age}_top_2'
            extra={'head':'tfcfarmingplus:block/crop/'+texture}
            box={3:(6,8,10,12),4:(4.5,8,11.5,15),5:(4,8,12,16)}[age]
            elements.append(head(*box,uv=[4,4,12,12]))
        put('assets/tfcfarmingplus/models/block/'+identifier+'.json',shape(tex,elements,extra))
wild_parent=model('tfc:block/wild_crop/crop')
native_grass=[copy.deepcopy(element) for element in wild_parent['elements'] if all(face['texture']=='#1' for face in element['faces'].values())]
for suffix,texture in [('', 'wild_crop/sunflower'),('_young','crop/sunflower_age_1')]:
    organs=planes() if suffix else [planes()[0],planes(0,8,[0,8,16,16])[1]]
    put('assets/tfcfarmingplus/models/block/wild_crop/sunflower'+suffix+'.json',{'parent':'tfc:block/wild_crop/crop','textures':{'crop':'tfcfarmingplus:block/'+texture},'elements':organs+native_grass})
put('assets/tfcfarmingplus/blockstates/wild_crop/sunflower.json',{'variants':{f'mature={flag}':{'model':'tfcfarmingplus:block/wild_crop/sunflower'+suffix} for flag,suffix in [('false','_young'),('true','')]}})
put('assets/tfcfarmingplus/models/block/dead_crop/sunflower_young.json',shape('tfcfarmingplus:block/dead_crop/sunflower_young',planes()))
put('assets/tfcfarmingplus/models/block/dead_crop/sunflower.json',shape('tfcfarmingplus:block/dead_crop/sunflower',planes(0,16,[0,8,16,16])))
put('assets/tfcfarmingplus/models/block/dead_crop/sunflower_top.json',shape('tfcfarmingplus:block/dead_crop/sunflower',planes(0,8,[0,8,16,16])+[head(3,8,13,13,[0,0,16,8])],{'head':'tfcfarmingplus:block/dead_crop/sunflower'}))
put('assets/tfcfarmingplus/blockstates/dead_crop/sunflower.json',{'variants':{'mature=false':{'model':'tfcfarmingplus:block/dead_crop/sunflower_young'},'mature=true,part=bottom':{'model':'tfcfarmingplus:block/dead_crop/sunflower'},'mature=true,part=top':{'model':'tfcfarmingplus:block/dead_crop/sunflower_top'}}})
planter=json.loads((SRC/'data/firmalife/firmalife/plantable/sunflower.json').read_bytes())
planter['textures']=[f'tfcfarmingplus:block/crop/sunflower_age_{i}' for i in [0,1,2,2]]+['tfcfarmingplus:block/wild_crop/sunflower']*2
put('data/firmalife/firmalife/plantable/sunflower.json',planter)
# Keep planting seed icon unchanged: saved old sunflower icon is generic red seed
# debris; the reviewed edible sunflower seeds must not be repurposed as planting art.
for key,value in proposed.items():
    target=OUT/'candidate-resources'/key;target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
sources.insert(0,OUT/'candidate-resources')
# Source priority is reversed by read(). Candidate must be last.
sources.append(sources.pop(0))
selected=[]
for age in range(6):
    parts=[(f'tfcfarmingplus:block/crop/sunflower_age_{age}',0)] if age<3 else [(f'tfcfarmingplus:block/crop/sunflower_age_{age}_bottom',0),(f'tfcfarmingplus:block/crop/sunflower_age_{age}_top',16)]
    name=f'ar4aa:preview/candidate_age_{age}';selected.append(name)
    save(resource(name,'models','json'),json.dumps(flattened(parts)).encode(),assets)
for form in ['wild_crop','dead_crop']:
    for young in [True,False]:
        label='young' if young else 'mature'
        parts=[(f'tfcfarmingplus:block/{form}/sunflower'+('_young' if young else ''),0)]
        if form=='dead_crop' and not young:parts.append(('tfcfarmingplus:block/dead_crop/sunflower_top',16))
        name=f'ar4aa:preview/candidate_{form}_{label}';selected.append(name)
        save(resource(name,'models','json'),json.dumps(flattened(parts)).encode(),assets)
for age,tex in enumerate(planter['textures']):
    # A single quad planter cell: exact public renderCross bounds and UV window.
    model_value=shape(tex,[])
    for angle in [-45,45]:
        plane={'from':[4.5-2.5*2**0.5,5,4.5],'to':[4.5+2.5*2**0.5,11.6656,4.5],
               'shade':False,'rotation':{'origin':[4.5,0,4.5],'axis':'y','angle':angle},
               'faces':{face:{'texture':'#crop','uv':[2,0,14,16]} for face in ['north','south']}}
        model_value['elements'].append(plane)
    name=f'ar4aa:preview/planter_{age}';selected.append(name)
    save(resource(name,'models','json'),json.dumps(model_value).encode(),assets)
    read(resource(tex,'textures','png'))
for identifier in selected:
    doc=json.loads((assets/resource(identifier,'models','json').removeprefix('assets/')).read_bytes())
    for value in doc['textures'].values():
        read(resource(slot(value,doc['textures']),'textures','png'))
for key in list(evidence):
    if key.endswith('.png'):save(key,read(key),assets)
(OUT/'candidate-models.txt').write_text('\n'.join(selected)+'\n',encoding='utf-8')
(OUT/'candidate-paths.json').write_text(json.dumps(sorted(proposed),indent=2),encoding='utf-8')
(OUT/'candidate-source-evidence.json').write_text(json.dumps(evidence,indent=2),encoding='utf-8')
for archive in archives:archive.close()
print('Candidate JSONs',len(proposed),'whole preview models',len(selected))
