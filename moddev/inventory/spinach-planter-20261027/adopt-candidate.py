from pathlib import Path
from hashlib import sha256
import json,shutil
r=Path(__file__).resolve().parents[3];o=Path(__file__).resolve().parent;a=r/'moddev/tfcfarmingplus';s=a/'src/main/resources';t=a/'tools';bak=r/'moddev/backups/ar4ab-spinach-planter-20261027'
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for row in load(bak/'backup-manifest.json'):
    if row['path'].startswith(('moddev/tfcfarmingplus/src/','moddev/tfcfarmingplus/tools/','moddev/tfcagricultureplus/src/','moddev/tfcagricultureplus/tools/')):assert digest(r/row['path'])==row['sha256'],row['path']
sprite='assets/tfcfarmingplus/textures/block/crop/spinach_planter_mature_v1.png'
shutil.copy2(o/'spinach_planter_mature_v1.png',s/sprite)
p=s/'data/firmalife/firmalife/plantable/spinach.json';v=load(p);assert v['textures'][-1]==v['textures'][-2];v['textures'][-1]='tfcfarmingplus:block/crop/spinach_planter_mature_v1';save(p,v)
p=t/'spinach-display-contract.json';c=load(p);c['ProtectedTextureSha256'][sprite]=digest(s/sprite);c['PlanterTextures']=v['textures'];c['PlanterMature']={'Texture':v['textures'][-1],'StageIndex':5,'VisibleColumns':[2,13],'PixelSize':[16,16],'Revision':'AR4-AB; dedicated mature foliage, native TFC artwork referenced; original crop art unchanged'};save(p,c)
p=t/'audit-reviewed-crop-display.ps1';text=p.read_text(encoding='utf-8-sig');anchor='if($planter){$copy=$planter|Select-Object * -ExcludeProperty textures;Check (Same-Value $copy $contract.PlanterFieldsExceptTextures) "${Species} planter gameplay fields changed"}'
assert text.count(anchor)==1
extra='''
foreach($texture in @($planter.textures)){
    Check ($textures.ContainsKey([string]$texture)) "${Species} planter atlas is not protected: $texture"
}
if($contract.PlanterMature){
    $mature=$contract.PlanterMature
    Check ($planter.textures[$mature.StageIndex] -ceq $mature.Texture) "${Species} mature planter atlas changed"
    Check ($planter.textures[$mature.StageIndex-1] -cne $mature.Texture) "${Species} mature planter repeats its prior stage"
    $relative='assets/'+(([string]$mature.Texture) -replace ':','/textures/')+'.png'
    $path=Join-Path $resources $relative
    if(Test-Path -LiteralPath $path){
        $bitmap=[Drawing.Bitmap]::new($path)
        try{
            $grounded=$false
            for($y=0;$y -lt $bitmap.Height;$y++){for($x=0;$x -lt $bitmap.Width;$x++){
                if($bitmap.GetPixel($x,$y).A -ge 26){
                    Check ($x -ge $mature.VisibleColumns[0] -and $x -le $mature.VisibleColumns[1]) "${Species} mature planter loses visible pixels to native UV crop"
                    if($y -eq 15){$grounded=$true}
                }
            }}
            Check $grounded "${Species} mature planter sprite is not grounded"
        }finally{$bitmap.Dispose()}
    }
}
'''
text=text.replace(anchor,anchor+'\n'+extra);p.write_text(text,encoding='utf-8-sig')
p=t/'gen-crops.ps1';text=p.read_text(encoding='utf-8-sig');anchor="    if($Species -eq 'sunflower'){";assert text.count(anchor)==1
text=text.replace(anchor,"    if($Species -eq 'spinach'){\n        & (Join-Path $PSScriptRoot 'audit-spinach-display.ps1')\n        if($LASTEXITCODE -ne 0){throw 'Spinach display preflight failed; no files copied.'}\n    }\n"+anchor);p.write_text(text,encoding='utf-8-sig')
p=r/'DEVELOPMENT_RULES.md';text=p.read_text(encoding='utf-8-sig');anchor='- 农业食品、种子物品的正式图标使用'
assert text.count(anchor)==1
text=text.replace(anchor,'- 绘制新贴图前，必须实际查看对应 Minecraft/TFC 原版贴图和模型显示；农业植物以已安装 TFC 同类资源为主要风格参考。记录参考资源与来源，用于学习植株结构、配色和生长阶段表现；新图须查看最终游戏尺寸及实际模型裁切效果，保留原图和原稿，不能只看生成大图就接入。\n'+anchor);p.write_text(text,encoding='utf-8')
save(o/'adoption-manifest.json',{'NewPNG':sprite,'ModifiedResource':'data/firmalife/firmalife/plantable/spinach.json','ModifiedTools':['spinach-display-contract.json','audit-reviewed-crop-display.ps1','gen-crops.ps1'],'ProtectedPNGs':14,'GameplayUnchanged':True,'VisualAccepted':False,'RuntimeVerified':False})
print('Adopted mature planter PNG, one planter route, protection and original-artwork development rule.')
