"""Render eight individually authored native16 pixel sources, never resize drafts."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from hashlib import sha256
import json

o=Path(__file__).resolve().parent
palette={'D':'284C24','G':'426C2C','M':'608E37','L':'85AC4A','H':'AEC766','P':'9BB76D','B':'574B2E','K':'827047','T':'AB9461','S':'B7A879'}
blank='................'
drawings={
'celery_age_0_stalks_v1':[blank]*13+[
'......L..M......',
'......GDG.......',
'.......PG.......'],
'celery_age_1_stalks_v1':[blank]*11+[
'........L.......',
'.....LM.GD......',
'.....DGGD.......',
'......GPG.......',
'.......PG.......'],
'celery_age_2_stalks_v1':[blank]*9+[
'........LM......',
'....LM..DGD.....',
'...DGMH.P..LM...',
'....DGP.P.DGD...',
'.....PGPP.GD....',
'......GPPG......',
'.......PG.......'],
'celery_age_3_stalks_v1':[blank]*6+[
'........LM......',
'.......LMGD.....',
'....HLM.DG......',
'...LMGD.P..LM...',
'..DGMLD.P.DGMH..',
'...DGPG.P..DGD..',
'....PGPPG..PG...',
'.....GPPG.PG....',
'......GPPGG.....',
'.......PG.......'],
'celery_age_4_stalks_v1':[blank]*3+[
'.........LM.....',
'....HL..LMGD....',
'...LMGD..DG.....',
'..DGMHD.GP..LM..',
'...DGP.LMP.DGMH.',
'...LMGP.PG..DGD.',
'..DGMHGPLPLMPG..',
'...DGD.GLPDPG...',
'....PG.PLPPG....',
'.....PGPPPG.....',
'......GPPG......',
'......PLG.......',
'.......PG.......'],
'celery_age_5_stalks_v1':[blank]+[
'.........LM.....',
'....HL..LMGD....',
'...LMGD.MDG..L..',
'..DGMHD.GP..LMG.',
'...GDGPLMP.DGMHD',
'..LMGDPGPG..DGD.',
'.DGMHDGPLPLMPG..',
'..DGD.PLP.DGPG..',
'...PG.GLP.PG....',
'....PGPLPPG.....',
'....GPGPPG......',
'.....GPPG.......',
'......PPG.......',
'......PLG.......',
'.......PG.......'],
'celery_stalks_v1':[blank]*3+[
'.........TK.....',
'........KTBB....',
'....KTB..BB.....',
'...BKSB..B..TK..',
'...BBKB..B.BKSB.',
'..KTBKB.BK..BB..',
'..BKSB.BSB..BK..',
'...BB..BSB.BK...',
'....BK.BSBBK....',
'.....BKSSBB.....',
'......BSSB......',
'......BSB.......',
'.......BB.......'],
'celery_young_stalks_v1':[blank]*13+[
'......T..K......',
'......BKB.......',
'.......BB.......'],
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
    assets.append({'Name':name,'EditableSource':str(source),'PixelSize':[16,16],'PNG':str(p),'Preview64':str(preview),'PreviewRule':'exact 4x nearest neighbour; workspace only','SHA256':sha256(p.read_bytes()).hexdigest().upper()})
canvas.save(o/'AR4AE-native16-authored.png')
(o/'native-grid-manifest.json').write_text(json.dumps({'SourceGrid':[16,16],'AlgorithmicShapes':False,'PriorImagegenDraftsAdopted':False,'Assets':assets},ensure_ascii=False,indent=2),encoding='utf-8')
print('Eight native16 grids rendered; all64 previews kept separate.')
