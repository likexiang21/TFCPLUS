from pathlib import Path
from hashlib import sha256
import json,re,shutil

r=Path(r'D:\TFC农业重置\Essential TerraFirmaCraft (TFC)\Essential TerraFirmaCraft (TFC)');o=Path(__file__).resolve().parent;b=r/'moddev/backups/ar4x-special-food-icons-20261026';a=r/'moddev/tfcfarmingplus';res=a/'src/main/resources';names=['rhubarb','sunflower','agave']
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def digest(p):return sha256(p.read_bytes()).hexdigest().upper()
backup=load(b/'backup-manifest.json');assert len(backup)==9159
for row in backup:
    p=Path(r'D:\TFC农业重置\PCL_TFC\mods')/Path(row['path']).name if row['path'].startswith('pcl-mods/') else r/row['path']
    assert digest(p)==digest(b/row['path'])==row['sha256'],row['path']
evidence=load(o/'product-semantics-evidence.json')
for row in evidence:
    for entry in [row['CurrentModel'],row['FoodData']]:assert digest(res/entry['Path'])==entry['SHA256']
    for entry in row['DeclaredReferences']:assert digest(r/entry['Path'])==entry['SHA256']

descriptions={
 'rhubarb':{'zh_cn':'叶柄是食材，叶片不用于食用','en_us':'the stalks are food, while leaves are not harvested as food'},
 'sunflower':{'zh_cn':'收获食用葵花籽，播种种子单独保留','en_us':'harvests edible sunflower seeds, separate from seeds used for planting'},
 'agave':{'zh_cn':'收获中心食材，侧芽用于种植','en_us':'the central heart is food and sidebuds are used for planting'}
}
notes={
 'rhubarb':{'zh_cn':'叶柄可直接食用或用于原生汤、沙拉和三明治；使用未腐烂原料。','en_us':'Eat the stalks or use them in native soup, salads and sandwiches; use unrotten ingredients.'},
 'sunflower':{'zh_cn':'食用籽可直接食用或用于原生餐食；当前没有专属榨油配方。','en_us':'Eat the food seeds or use them in native meals. Dedicated oil extraction is not connected.'},
 'agave':{'zh_cn':'食材是龙舌兰心，侧芽用于播种。当前没有专属烤制或榨汁配方。','en_us':'The harvested food is the agave heart; sidebuds are for planting. No dedicated roasting or juice recipe is connected.'}
}
booktool=a/'tools/gen-patchouli-book.ps1';croptool=a/'tools/gen-crops.ps1'
original_rows={};new_rows=[]
for tool,fields in [(booktool,{'zh_cn':'zhDesc','en_us':'enDesc'}),(croptool,{'zh_cn':'zhNote','en_us':'enNote'})]:
    text=tool.read_text(encoding='utf-8-sig');lines=text.splitlines()
    for name in names:
        found=[i for i,line in enumerate(lines) if re.search(r"n='"+name+r"';",line)];assert len(found)==1
        idx=found[0];line=lines[idx]
        for locale,key in fields.items():
            match=re.search(r"\b"+key+r"='((?:[^']|'')*)'",line);assert match
            if tool==booktool:original_rows[(name,locale)]=match.group(1).replace("''", "'")
            value=descriptions[name][locale] if tool==booktool else notes[name][locale]
            line=line[:match.start(1)]+value.replace("'","''")+line[match.end(1):]
        if tool==booktool:
            line=line.rsplit('}',1)[0].rstrip()+"; zhProductNote='"+notes[name]['zh_cn']+"'; enProductNote='"+notes[name]['en_us']+"' }"
        lines[idx]=line
        new_rows.append({'Path':tool.relative_to(a).as_posix(),'Name':name,'LineSha256':sha256(line.encode('utf-8')).hexdigest().upper()})
    text='\n'.join(lines)+'\n'
    if tool==booktool:
        marker="    $title = if ($lang -eq 'zh_cn') { $c['zh'] } else { $c['en'] }\n    return [ordered]@{ type='patchouli:text'; title=$title; anchor=$c['n']; text=$text }"
        assert text.count(marker)==1
        extra="    # Reviewed food-product notes do not alter crop controls.\n    if ($c['n'] -in @('rhubarb','sunflower','agave')) {\n        $noteField = if ($lang -eq 'zh_cn') { 'zhProductNote' } else { 'enProductNote' }\n        $text += $c[$noteField]\n    }\n"
        text=text.replace(marker,extra+marker)
    tool.write_text(text,encoding='utf-8-sig')

guide_contracts=[];page_diff=[]
for locale in ['zh_cn','en_us']:
    path=res/f'assets/tfc/patchouli_books/field_guide/{locale}/entries/farming_plus/crops.json';before=load(path);after=load(path)
    for name in names:
        pages=[p for p in after['pages'] if p.get('anchor')==name];assert len(pages)==1
        page=pages[0];old=page['text']
        if name!='agave':
            assert old.count(original_rows[(name,locale)])==1
            page['text']=old.replace(original_rows[(name,locale)],descriptions[name][locale])
        page['text']+=notes[name][locale]
        guide_contracts.append({'Path':path.relative_to(res).as_posix(),'Name':name,'Locale':locale,'Text':page['text']})
        page_diff.append({'Locale':locale,'Name':name,'BeforeCharacters':len(old),'AfterCharacters':len(page['text']),'PageCount':len(after['pages'])})
    assert before.keys()==after.keys() and len(before['pages'])==len(after['pages'])
    diffs=[i for i,(old,new) in enumerate(zip(before['pages'],after['pages'])) if old!=new]
    assert len(diffs)==3 and {after['pages'][i]['anchor'] for i in diffs}==set(names)
    for i in diffs:assert {k:v for k,v in before['pages'][i].items() if k!='text'}=={k:v for k,v in after['pages'][i].items() if k!='text'}
    save(path,after)
save(o/'guide-page-diff.json',page_diff)

contract_path=a/'tools/reviewed-item-icon-routes.json';c=load(contract_path);assert c['Version']==8 and len(c['Routes'])==40
art=load(o/'imagegen-asset-manifest.json')
for row in art:
    dest=Path(row['AdoptedSourcePath']);assert not dest.exists();shutil.copy2(r/row['Export'],dest)
    model=Path(row['ModelPath']);data=load(model);texture='tfcfarmingplus:item/food/'+dest.stem;data['textures']['layer0']=texture;save(model,data)
    c['Routes'].append({'Path':model.relative_to(res).as_posix(),'Texture':texture,'Name':row['Name'],'Family':'food'})
    for p in [res/f'assets/tfcfarmingplus/textures/item/food/{row["Name"]}.png',dest]:c['ProtectedTextureSha256'][p.relative_to(res).as_posix()]=digest(p)
    p=res/f'data/tfcfarmingplus/tfc/food/{row["Name"]}.json';c['FoodDataSha256'][p.relative_to(res).as_posix()]=digest(p)
    row['Adopted']=True
c['Version']=9;c['GuidePages']=guide_contracts;c['ReviewedTemplateRows']=new_rows
c['AR4XArtReview']=[{'Name':n,'Origin':'built-in image_gen 16x16 export','VisualAccepted':False,'RuntimeVerified':False} for n in names]
assert len(c['Routes'])==43 and len(c['ProtectedTextureSha256'])==72 and len(c['FoodDataSha256'])==40
save(contract_path,c);save(o/'imagegen-asset-manifest.json',art)

audit=a/'tools/audit-item-icon-routes.ps1';text=audit.read_text(encoding='utf-8-sig');marker='$native=$contract.NativeTexture';assert text.count(marker)==1
extra='''# Exact reviewed product prose and generator rows, independent of other book pages.
$guideCount=0
if($contract.GuidePages){
    foreach($guide in $contract.GuidePages){
        $path=Join-Path $resources $guide.Path
        Check (-not(Test-Path -LiteralPath (Join-Path $other $guide.Path))) "B shadows reviewed food guide: $($guide.Path)"
        if(-not(Test-Path -LiteralPath $path)){$errors.Add("Missing reviewed food guide: $($guide.Path)");continue}
        try {
            $book=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json
            $pages=@($book.pages|Where-Object {$_.anchor -ceq $guide.Name})
            Check ($pages.Count -eq 1) "Reviewed food guide anchor count: $($guide.Locale)/$($guide.Name)"
            if($pages.Count -eq 1){Check ($pages[0].text -ceq $guide.Text) "Reviewed food guide text changed: $($guide.Locale)/$($guide.Name)"}
            $guideCount++
        } catch {$errors.Add("Invalid reviewed food guide: $($guide.Path): $_")}
    }
}
$templateCount=0
if($contract.ReviewedTemplateRows){
    foreach($row in $contract.ReviewedTemplateRows){
        $path=Join-Path $instance ('moddev/tfcfarmingplus/'+$row.Path)
        if(-not(Test-Path -LiteralPath $path)){$errors.Add("Missing reviewed generator: $($row.Path)");continue}
        $pattern=[regex]::Escape("n='$($row.Name)';")
        $lines=@([IO.File]::ReadAllLines($path,[Text.Encoding]::UTF8)|Where-Object {$_ -match $pattern})
        Check ($lines.Count -eq 1) "Reviewed generator row count: $($row.Path)/$($row.Name)"
        if($lines.Count -eq 1){
            $hasher=[Security.Cryptography.SHA256]::Create()
            try {$hash=[BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($lines[0]))).Replace('-','')} finally {$hasher.Dispose()}
            Check ($hash -eq $row.LineSha256) "Reviewed generator row changed: $($row.Path)/$($row.Name)"
        }
        $templateCount++
    }
}
'''
text=text.replace(marker,extra+marker)
text=text.replace("ItemPNGsSizeChecked=$iconSizeCount;Findings", "ItemPNGsSizeChecked=$iconSizeCount;GuidePages=$guideCount;TemplateRows=$templateCount;Findings")
audit.write_text(text,encoding='utf-8-sig')
print(json.dumps({'Models':43,'PNGs':72,'FoodData':40,'GuidePages':6,'TemplateRows':6,'PageDiff':page_diff},ensure_ascii=False))
