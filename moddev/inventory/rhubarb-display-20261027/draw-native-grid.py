"""Render individually authored 16x16 rhubarb grids in the project pixel format."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
from hashlib import sha256
import json
o=Path(__file__).resolve().parent
palette={'D':'284925','G':'416B32','M':'628C42','L':'8BAC59','H':'ADC67A','R':'893849','P':'BB5260','B':'594A32','K':'84704C','T':'AB9567','S':'BDA97C'}
blank='................'
drawings={
'rhubarb_age_0_petioles_v1':[blank]*13+[
'.......L.M......',
'.......GDG......',
'........R.......'],
'rhubarb_age_1_petioles_v1':[blank]*12+[
'......LM..L.....',
'.....DGM.DGM....',
'......GD.RP.....',
'.......RR.......'],
'rhubarb_age_2_petioles_v1':[blank]*10+[
'......HL........',
'.....LMHD.LM....',
'....DGMHGDMHG...',
'.....DGD.GMGD...',
'......RP.RP.....',
'.......RR.......'],
'rhubarb_age_3_petioles_v1':[blank]*7+[
'......HL........',
'.....LMHD.LM....',
'....DGMHLDGMHD..',
'....GMHLGDMHGD..',
'.....DGD.GMGD...',
'......R...P.....',
'......P...R.....',
'.......R..P.....',
'.......P.R......'],
'rhubarb_age_4_petioles_v1':[blank]*5+[
'......HL........',
'.....LMHD.LM....',
'....DGMHLDGMHG..',
'...DGMHLGDMHGD..',
'....GMLD.GMGD...',
'.....R....P.....',
'.....P....R.....',
'......R...P.....',
'......P..R......',
'.......R.P......',
'.......R.R......'],
'rhubarb_age_5_petioles_v1':[blank]*3+[
'.....HL.........',
'....LMHD..LM....',
'...DGMHLDLMHG...',
'...GMHLGDGMHLD..',
'..DGMHGDLMHMGD..',
'...DGD.GMLGD....',
'....R...DGMGD...',
'....P....DGD....',
'.....R....P.....',
'.....P....R.....',
'......R...P.....',
'......P..R......',
'.......R.R......'],
'rhubarb_petioles_v1':[blank]*5+[
'......TK........',
'.....KTBB.TK....',
'....BKSKBBKSKB..',
'...BKSTKBBKSKB..',
'....BBKB.BKBB...',
'.....B....K.....',
'.....K....B.....',
'......B...K.....',
'......K..B......',
'.......B.K......',
'.......B.B......'],
'rhubarb_young_petioles_v1':[blank]*13+[
'.......T.K......',
'.......BKB......',
'........B.......'],
}
for folder in ['pixel-source-16','native-grid-png','preview-64']:(o/folder).mkdir(exist_ok=True)
canvas=Image.new('RGB',(1320,520),(37,39,43));d=ImageDraw.Draw(canvas);font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',14);assets=[]
for i,(name,pixels) in enumerate(drawings.items()):
    assert len(pixels)==16 and all(len(row)==16 for row in pixels),(name,[len(row) for row in pixels])
    assert all(ch=='.' or ch in palette for row in pixels for ch in row)
    source=o/'pixel-source-16'/f'{name}.txt';source.write_text('\n'.join(f'{key}={value}' for key,value in palette.items())+'\n\n'+'\n'.join(pixels)+'\n',encoding='utf-8')
    im=Image.new('RGBA',(16,16))
    for y,row in enumerate(pixels):
        for x,ch in enumerate(row):
            if ch!='.':im.putpixel((x,y),tuple(bytes.fromhex(palette[ch]))+(255,))
    p=o/'native-grid-png'/f'{name}.png';im.save(p);preview=o/'preview-64'/p.name;im.resize((64,64),Image.Resampling.NEAREST).save(preview)
    x=i%6*220;y=i//6*260;zoom=im.resize((192,192),Image.Resampling.NEAREST);canvas.paste(zoom,(x+12,y+12),zoom);d.text((x+8,y+225),f'Native16 age{i}' if i<6 else ['Dead mature','Dead young'][i-6],font=font,fill='white')
    assets.append({'Name':name,'EditableSource':str(source),'PixelSize':[16,16],'PNG':str(p),'Preview64':str(preview),'PreviewRule':'exact4x nearest; workspace only','SHA256':sha256(p.read_bytes()).hexdigest().upper()})
canvas.save(o/'AR4AG-native16-authored.png')
(o/'native-grid-manifest.json').write_text(json.dumps({'SourceGrid':[16,16],'AlgorithmicShapes':False,'ImagegenUsed':False,'Assets':assets},ensure_ascii=False,indent=2),encoding='utf-8')
print('Eight native16 rhubarb grids rendered.')
