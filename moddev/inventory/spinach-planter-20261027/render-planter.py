"""Offline native quad-cell evidence, without a planter base or game simulation."""
from pathlib import Path
import json,copy,shutil,sys,hashlib
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;s=r/'moddev/tfcfarmingplus/src/main/resources'
published='--source' in sys.argv
assets=o/('assets-current' if published else 'preview-assets');new='tfcfarmingplus:block/crop/spinach_planter_mature_v1'
planter=json.loads((s/'data/firmalife/firmalife/plantable/spinach.json').read_bytes());before=planter['textures'][:];before[-1]='tfcfarmingplus:block/crop/spinach_age_4'
after=planter['textures'][:] if published else before[:]
if not published:after[-1]=new
def cell(texture,dx=0,dz=0):
    elements=[]
    for angle in [-45,45]:
        elements.append({'from':[4.5-2.5*2**0.5+dx,5,4.5+dz],'to':[4.5+2.5*2**0.5+dx,11.6656,4.5+dz],
          'rotation':{'origin':[4.5+dx,0,4.5+dz],'axis':'y','angle':angle},'shade':False,
          'faces':{face:{'texture':'#crop','uv':[2,0,14,16]} for face in ['north','south']}})
    return {'textures':{'crop':texture},'elements':elements}
selected=[]
after_label='current' if published else 'candidate'
for label,textures in [('before',before),(after_label,after)]:
    for age,texture in enumerate(textures):
        name=f'ar4ab:preview/{label}_{age}';selected.append(name)
        p=assets/f'ar4ab/models/preview/{label}_{age}.json';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(cell(texture)),encoding='utf-8')
        ns,rel=texture.split(':',1);dest=assets/f'{ns}/textures/{rel}.png';dest.parent.mkdir(parents=True,exist_ok=True)
        source=o/'spinach_planter_mature_v1.png' if texture==new and not published else s/f'assets/{ns}/textures/{rel}.png';shutil.copy2(source,dest)
for label,texture in [('before',before[-1]),(after_label,after[-1])]:
    value=cell(texture);value['elements']=[]
    for dx,dz in [(0,0),(8,0),(8,8),(0,8)]:value['elements']+=cell(texture,dx,dz)['elements']
    name=f'ar4ab:preview/{label}_four_cells';selected.append(name);(assets/f'ar4ab/models/preview/{label}_four_cells.json').write_text(json.dumps(value),encoding='utf-8')
(o/('current-models.txt' if published else 'preview-models.txt')).write_text('\n'.join(selected)+'\n',encoding='utf-8')
(o/('current-source-evidence.json' if published else 'planter-stage-evidence.json')).write_text(json.dumps({'Before':before,'After':after,'Stages':5,'UV':[2,0,14,16],'CellBounds':[2,5,2,7,11.6656,7],'BaseOmitted':True,'NewSpriteSha256':hashlib.sha256((s/'assets/tfcfarmingplus/textures/block/crop/spinach_planter_mature_v1.png').read_bytes()).hexdigest().upper() if published else None,'VisualAccepted':False,'RuntimeVerified':False},indent=2),encoding='utf-8')
print('Prepared 14 native-cell display previews.')
