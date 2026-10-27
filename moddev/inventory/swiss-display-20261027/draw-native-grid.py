"""Eight explicitly authored 16-row native pixel sources; no procedural shapes."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
from hashlib import sha256
import json,shutil
o=Path(__file__).resolve().parent
palette={'D':'234822','G':'386630','M':'56803A','L':'7AA249','H':'A1BB62','R':'9D3040','S':'683F35','B':'51482E','K':'82734B','T':'AA9867','P':'BCAB7A'}
blank='................'
drawings={
'swiss_chard_age_0_leafy_v2':[blank]*13+['.....L....M.....','....MG...DGL....','.....D....D.....'],
'swiss_chard_age_1_leafy_v2':[blank]*12+['....LM....ML....','...MGD....DGM...','....GD....DG....','.....D....D.....'],
'swiss_chard_age_2_leafy_v2':[blank]*10+['....LM..........','...MGD....DGM...','..GMHDL..LDMHG..','...GMR....RMG...','....GD....DG....','.....D....D.....'],
'swiss_chard_age_3_leafy_v2':[blank]*8+['....HL..........','...LMG.....MH...','..GMHRD..DRHMG..','..DGRGD..DGRGD..','...DMRD..DRMD...','....GR....RG....','...GDG....GDG...','.....D....D.....'],
'swiss_chard_age_4_leafy_v2':[blank]*6+['.....L..........','....HMG..LMG....','...GMHR..RDMH...','..DGLRG..GRLGD..','..GMRGD..DGRMG..','..DGMRD..DRMGD..','...DMRD..DRMD...','....GR....RG....','...GDG....GDG...','.....D....D.....'],
'swiss_chard_age_5_leafy_v2':[blank]*4+['..........L.....','....HMG..LMG....','...GMHR..RDMH...','..DGLRG..GRLGD..','..GLMRD..DRMLG..','..GMRGD..DGRMG..','..DGMRD..DRMGD..','...GMRD..DRMG...','...DMRD..DRMD...','....GR....RG....','...GDG....GDG...','.....D....D.....'],
'swiss_chard_leafy_v2':[blank]*6+['.....T..........','....KTB.........','...BPKB....TK...','..BKSKB..BKPKB..','..KBSKB..BKSKB..','...BKS....SKB...','....BS....SB....','...KB.....BBK...','....B.....B.....','.....B....B.....'],
'swiss_chard_young_leafy_v2':[blank]*13+['....T.....K.....','...KPB....BK....','.....B....B.....']}
(o/'pixel-source-16').mkdir(exist_ok=True);(o/'preview-64').mkdir(exist_ok=True);(o/'native-grid-png').mkdir(exist_ok=True)
page=Image.new('RGB',(1320,520),(38,39,43));d=ImageDraw.Draw(page);font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',14);rows=[]
for index,(name,pixels) in enumerate(drawings.items()):
 assert len(pixels)==16 and all(len(row)==16 for row in pixels),(name,[len(row) for row in pixels])
 assert all(ch=='.' or ch in palette for row in pixels for ch in row)
 # This is the existing editable pixel-source format: palette plus 16 literal rows.
 source=o/'pixel-source-16'/f'{name}.txt';source.write_text('\n'.join(f'{key}={value}' for key,value in palette.items())+'\n\n'+'\n'.join(pixels)+'\n',encoding='utf-8')
 im=Image.new('RGBA',(16,16))
 for y,row in enumerate(pixels):
  for x,ch in enumerate(row):
   if ch!='.':im.putpixel((x,y),tuple(bytes.fromhex(palette[ch]))+(255,))
 target=o/'native-grid-png'/f'{name}.png';im.save(target);im.resize((64,64),Image.Resampling.NEAREST).save(o/'preview-64'/target.name)
 x=index%6*220;y=index//6*260;large=im.resize((192,192),Image.Resampling.NEAREST);page.paste(large,(x+12,y+12),large);d.text((x+8,y+225),f'Native16: age{index}' if index<6 else ['Native16: dead','Native16: dead young'][index-6],font=font,fill='white')
 rows.append({'Name':name,'EditableSource':str(source),'PixelSize':[16,16],'PNG':str(target),'Preview64':str(o/'preview-64'/target.name),'PreviewRule':'exact 4x nearest neighbour; workspace only','SHA256':sha256(target.read_bytes()).hexdigest().upper()})
page.save(o/'AR4AD-native16-authored.png');(o/'native-grid-manifest.json').write_text(json.dumps({'SourceGrid':[16,16],'AlgorithmicShapes':False,'PriorImagegenDraftsAdopted':False,'Assets':rows},ensure_ascii=False,indent=2),encoding='utf-8')
print('Eight native 16x16 pixel sources exported; 64x64 previews separate.')
