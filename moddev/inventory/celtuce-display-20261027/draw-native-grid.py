"""Eight individually authored native16 grids in the project pixel-source format."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from hashlib import sha256
import json

o=Path(__file__).resolve().parent
palette={'D':'305126','G':'4B702D','M':'6B923F','L':'91B75B','H':'B4CD79','P':'A4B971','B':'584A2F','K':'847049','T':'AF9666','S':'BEAA7C'}
blank='................'
drawings={
'celtuce_age_0_stem_v1':[blank]*13+[
'.......L.M......',
'.......GPG......',
'........G.......'],
'celtuce_age_1_stem_v1':[blank]*12+[
'.......HL.......',
'.....LMGML......',
'......DGPG......',
'.......PG.......'],
'celtuce_age_2_stem_v1':[blank]*10+[
'.......HL.......',
'......LMGD......',
'....LMGPGLM.....',
'...DGMHPLGD.....',
'....DGGPGD......',
'.......PG.......'],
'celtuce_age_3_stem_v1':[blank]*6+[
'.......HM.......',
'......LMGD......',
'...LM.GPL.......',
'..DGMHPGLM......',
'...GMDPGLGD.....',
'....DGPGDG......',
'.....GPGL.......',
'......PGL.......',
'......GPG.......',
'.......PG.......'],
'celtuce_age_4_stem_v1':[blank]*3+[
'........HL......',
'.......LMGD.....',
'...HL..GPGL.....',
'..LMGD.PGLML....',
'..GMLDGPGDGM....',
'...DMGPGLDGD....',
'....DGPGGPG.....',
'...LMGPGL.......',
'..DGMDPGDGM.....',
'...DG.GPGLD.....',
'......GPG.......',
'.......PG.......',
'.......PG.......'],
'celtuce_age_5_stem_v1':[blank]+[
'........HL......',
'.......LMGD.....',
'...HML.GPGL.....',
'..LMGHDGPG.ML...',
'..DGMHDPLGLMGD..',
'...DGMGPGDGMHD..',
'....DGPLG.DGD...',
'...LMGPGL.GD....',
'..DGMHPGLML.....',
'...GMDPLGDGD....',
'....DGPGLDGM....',
'.....GPGL.DG....',
'......GPG.......',
'.......PG.......',
'.......PG.......'],
'celtuce_stem_v1':[blank]*4+[
'........TK......',
'.......KTBB.....',
'...TK..BSBB.....',
'..BKSB.BSBKT....',
'...KBBBSBBKB....',
'....BBBSB.B.....',
'...KTBBSB.......',
'..BKBBBSBKB.....',
'...BB.BSBBB.....',
'......BSB.......',
'.......BB.......',
'.......BB.......'],
'celtuce_young_stem_v1':[blank]*13+[
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
canvas.save(o/'AR4AF-native16-authored.png')
(o/'native-grid-manifest.json').write_text(json.dumps({'SourceGrid':[16,16],'AlgorithmicShapes':False,'ImagegenUsed':False,'Assets':assets},ensure_ascii=False,indent=2),encoding='utf-8')
print('Eight native16 celtuce grids rendered.')
