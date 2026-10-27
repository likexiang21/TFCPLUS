"""Read product contracts and compose comparison sheets; do not edit game assets."""
from pathlib import Path
from hashlib import sha256
from collections import Counter
from PIL import Image, ImageDraw, ImageFont
import json, csv, zipfile, re

root = Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)')
out = Path(__file__).resolve().parent
a = root / 'moddev/tfcfarmingplus/src/main/resources'
b = root / 'moddev/tfcagricultureplus/src/main/resources'
names = ['almond', 'hazelnut', 'macadamia', 'pecan', 'walnut', 'agave', 'sunflower', 'rhubarb']
triage = json.loads((root / 'moddev/inventory/remaining-food-icons-20261026/item-icon-triage.json').read_text(encoding='utf-8-sig'))
oldrows = {r['Name']: r for r in triage if r['Family'] == 'food'}
index = {}
archives = []
for jar in sorted((root / 'mods').glob('*.jar')):
    archive = zipfile.ZipFile(jar)
    archives.append(archive)
    for path in archive.namelist():
        if path.startswith(('assets/', 'data/')) and path.endswith(('.png', '.json')):
            index.setdefault(path, (archive, path))
for base in [a, b]:
    for p in base.rglob('*'):
        if p.is_file():
            index[p.relative_to(base).as_posix()] = p

def raw(key):
    v = index[key]
    return v.read_bytes() if isinstance(v, Path) else v[0].read(v[1])

def document(key):
    return json.loads(raw(key).decode('utf-8-sig'))

def pack(key):
    value = index[key]
    origin = str(value) if isinstance(value, Path) else value[0].filename + '!/' + value[1]
    return {'Path': key, 'Origin': origin, 'SHA256': sha256(raw(key)).hexdigest().upper(), 'JSON': document(key)}

def key_for(texture):
    ns, path = texture.split(':')
    return f'assets/{ns}/textures/{path}.png'

languages = document('assets/tfcfarmingplus/lang/zh_cn.json')
rows = []
for name in names:
    model = f'assets/tfcfarmingplus/models/item/food/{name}.json'
    texture = document(model)['textures']['layer0']
    guides = []
    for p in (a / 'assets').rglob('*.json'):
        if 'patchouli_books' not in p.parts:
            continue
        content = p.read_text(encoding='utf-8-sig')
        if not re.search(r'(?<![a-z_])' + name + r'(?![a-z_])', content):
            continue
        data = json.loads(content)
        pages = [page for page in data.get('pages', []) if re.search(r'(?<![a-z_])' + name + r'(?![a-z_])', json.dumps(page, ensure_ascii=False))]
        if pages:
            guides.append({'Path': p.relative_to(root).as_posix(), 'Pages': pages})
    references = []
    for base in [a / 'data', b / 'data']:
        for p in base.rglob('*.json'):
            text = p.read_text(encoding='utf-8-sig')
            if f'tfcfarmingplus:food/{name}' in text or f'tfcfarmingplus:seeds/{name}' in text:
                references.append({'Path': p.relative_to(root).as_posix(), 'SHA256': sha256(p.read_bytes()).hexdigest().upper(), 'JSON': json.loads(text)})
    food = f'data/tfcfarmingplus/tfc/food/{name}.json'
    current_key = key_for(texture)
    stored = f'assets/tfcfarmingplus/textures/item/food/{name}.png'
    rows.append({'Name': name, 'ChineseName': languages[f'item.tfcfarmingplus.food.{name}'], 'ItemID': f'tfcfarmingplus:food/{name}',
                 'CurrentModel': pack(model), 'CurrentTexture': texture,
                 'CurrentTextureSource': str(index[current_key]) if isinstance(index[current_key], Path) else index[current_key][0].filename + '!/' + current_key,
                 'CurrentTextureSHA256': sha256(raw(current_key)).hexdigest().upper(),
                 'StoredTexture': stored, 'StoredTextureSHA256': sha256(raw(stored)).hexdigest().upper(),
                 'FoodData': pack(food), 'DeclaredReferences': references, 'Guides': guides,
                 'PriorTriage': oldrows[name], 'VisualAccepted': False, 'RuntimeVerified': False})

(out / 'product-semantics-evidence.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')

font = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', 16)
small = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', 13)
def image_for(texture):
    from io import BytesIO
    return Image.open(BytesIO(raw(key_for(texture)))).convert('RGBA')

observations = []
def sheet(targets, name):
    canvas = Image.new('RGB', (1056, 304 * len(targets)), '#202428')
    d = ImageDraw.Draw(canvas)
    for i, name_ in enumerate(targets):
        record = oldrows[name_]
        model = document(f'assets/tfcfarmingplus/models/item/food/{name_}.json')
        current = model['textures']['layer0']
        choices = [current, f'tfcfarmingplus:item/food/{name_}']
        for j, texture in enumerate(choices):
            x, y = j * 528, i * 304
            im = image_for(texture)
            for cy in range(16):
                for cx in range(16):
                    d.rectangle((x+12+cx*13, y+12+cy*13, x+24+cx*13, y+24+cy*13), fill=('#30363b' if (cx+cy)%2 else '#282e33'))
            canvas.paste(im.resize((208, 208), Image.Resampling.NEAREST), (x+12, y+12), im.resize((208, 208), Image.Resampling.NEAREST))
            d.text((x+234, y+22), record['ChineseName'], font=font, fill='white')
            d.text((x+234, y+55), name_, font=small, fill='#ddd5c4')
            d.text((x+234, y+88), '当前实际引用' if j == 0 else '已有同名保存图', font=small, fill='white')
            d.text((x+12, y+236), texture, font=small, fill='white')
            d.text((x+12, y+263), '仅离线对照；最终美术与实机未验', font=small, fill='#cdc5b4')
        observations.append({'Name': name_, 'Sheet': name, 'CurrentTexture': current, 'StoredTexture': choices[1], 'VisualAccepted': False, 'RuntimeVerified': False})
    canvas.save(out / name)

sheet(names[:4], 'AR4V-nuts-p1.png')
sheet(names[4:], 'AR4V-nuts-and-products-p2.png')
shared = [r['Name'] for r in triage if r['Family'] == 'food' and any(s in r['Status'] for s in ['共享替代', '共享叶束', '可复用粒形'])]
shared_leaf = [r['Name'] for r in triage if r['Family'] == 'food' and any(s in r['Status'] for s in ['共享替代', '共享叶束'])]
for i in range(0, len(shared_leaf), 4):
    sheet(shared_leaf[i:i+4], f'AR4V-shared-leaf-p{i//4+1}.png')
(out / 'comparison-sheets.json').write_text(json.dumps(observations, ensure_ascii=False, indent=2), encoding='utf-8')
for archive in archives:
    archive.close()
print(json.dumps({'Products': [{'Name': r['Name'], 'Chinese': r['ChineseName'], 'Texture': r['CurrentTexture'], 'Food': r['FoodData']['JSON'], 'DeclaredRefs': len(r['DeclaredReferences'])} for r in rows], 'SharedFood': shared, 'SharedLeaf': shared_leaf, 'Sheets': sorted({r['Sheet'] for r in observations})}, ensure_ascii=False))
