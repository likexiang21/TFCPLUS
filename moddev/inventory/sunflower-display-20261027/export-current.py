"""Re-resolve published source; no candidate-resource models are used."""
exec((__import__('pathlib').Path(__file__).parent/'inspect-display.py').read_text(encoding='utf-8').split('assets=OUT/')[0])
assets=OUT/'assets-current';selected=[]
for age in range(6):
    parts=[(f'tfcfarmingplus:block/crop/sunflower_age_{age}',0)] if age<3 else [(f'tfcfarmingplus:block/crop/sunflower_age_{age}_bottom',0),(f'tfcfarmingplus:block/crop/sunflower_age_{age}_top',16)]
    name=f'ar4aa:preview/current_age_{age}';selected.append(name)
    save(resource(name,'models','json'),json.dumps(flattened(parts)).encode(),assets)
for form in ['wild_crop','dead_crop']:
    for young in [True,False]:
        label='young' if young else 'mature';parts=[(f'tfcfarmingplus:block/{form}/sunflower'+('_young' if young else ''),0)]
        if form=='dead_crop' and not young:parts.append(('tfcfarmingplus:block/dead_crop/sunflower_top',16))
        name=f'ar4aa:preview/current_{form}_{label}';selected.append(name)
        save(resource(name,'models','json'),json.dumps(flattened(parts)).encode(),assets)
planter=json.loads((SRC/'data/firmalife/firmalife/plantable/sunflower.json').read_bytes())
for age,texture in enumerate(planter['textures']):
    # Geometry below is evidence only: native quad cell bounds, exact UV and diagonals.
    value={'textures':{'crop':texture},'elements':[]}
    for angle in [-45,45]:
        value['elements'].append({'from':[4.5-2.5*2**0.5,5,4.5],'to':[4.5+2.5*2**0.5,11.6656,4.5],
             'shade':False,'rotation':{'origin':[4.5,0,4.5],'axis':'y','angle':angle},
             'faces':{f:{'texture':'#crop','uv':[2,0,14,16]} for f in ['north','south']}})
    name=f'ar4aa:preview/current_planter_{age}';selected.append(name)
    save(resource(name,'models','json'),json.dumps(value).encode(),assets)
for name in selected:
    value=json.loads((assets/resource(name,'models','json').removeprefix('assets/')).read_bytes())
    for texture in value['textures'].values(): read(resource(slot(texture,value['textures']),'textures','png'))
for key in list(evidence):
    if key.endswith('.png'):save(key,read(key),assets)
(OUT/'current-models.txt').write_text('\n'.join(selected)+'\n',encoding='utf-8')
(OUT/'current-preview-sources.json').write_text(json.dumps({'Sources':evidence,'PlanterData':planter,'PlanterCellOnly':True,'VisualAccepted':False,'RuntimeVerified':False},indent=2),encoding='utf-8')
for archive in archives:archive.close()
print('Current-source 3D evidence prepared:',len(selected),'models.')
