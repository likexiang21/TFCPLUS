# ============================================================
# 生成 TFC Farming Plus 的手册内容 —— 挂在 **TFC 原版 field_guide** 下
# ------------------------------------------------------------
# 本脚本严格按照 TFC 4.2.10 自己的两个条目来写：
#   assets/tfc/.../entries/the_world/wild_fruits.json  （60 页，讲野生果树/浆果灌木）
#   assets/tfc/.../entries/food/crops.json             （66 页，讲农田作物）
#
# 从它们提取出的「每株一页」模板（TFC 手册内容的标准格式）：
#   [野生植物]  Can be found in regions with:
#                 $(bold)Temperature$(): X - Y        ← 世界生成温度范围
#                 $(bold)Rainfall$(): A - Bmm         ← 世界生成降水范围
#               Conditions required for growth:
#                 $(bold)Temperature$(): X - Y        ← 种植/生长温度范围
#                 $(bold)Hydration$(): A - B %        ← 种植/生长湿度范围
#               <植物名> grows from ..., start flowering ..., bear fruit ...
#               They can be found in ...
#   [农田作物]  $(bold)Temperature$(): ... / $(bold)Hydration$(): ... %
#               $(bold)Category$(): Cereal|Legume|Vegetable|Cover
#               $(bold)$(3)N: 75 $(bold)$(6)P: +20 $(bold)$(d)K: +20$()   ← + 号=补充，无符号=消耗
#               <植物名> is a single block crop. <X> seeds can be planted on farmland ...
#
# ⚠️ TFC 用 $(cfg:climate.<name>.temperature) 从**它自己的配置**动态取值；
#    我们的植物不在 TFC 配置里，所以这里改为把**真实数值写死**，
#    数值仍由脚本从 data/tfcfarmingplus 下的气候与世界生成 JSON 读取，保证不漂移。
# ============================================================
param([string]$OutputRoot = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'cocoa-data-policy.ps1')
$root = Resolve-LegacyGeneratorOutput $OutputRoot
$cocoaPolicy = Read-CocoaPolicy
Add-Type -AssemblyName System.Web.Extensions | Out-Null
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue

$NS   = 'tfcfarmingplus'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:count = 0

function Save-Json([string]$rel, $obj) {
    $path = Join-Path $root $rel
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $ser.Serialize($obj), $utf8)
    $script:count++
}
function Get-JsonV([string]$rel) { return $ser.DeserializeObject([System.IO.File]::ReadAllText((Join-Path $root $rel), $utf8)) }

# ---- 读取真实数值 ----
function GrowthRange([string]$kind, [string]$n) {
    $c = Get-JsonV "data/$NS/tfc/climate_range/$kind/${n}.json"
    return [ordered]@{ minT=[double]$c['min_temperature']; maxT=[double]$c['max_temperature']
                       minH=[int]$c['min_hydration'];      maxH=[int]$c['max_hydration'] }
}
function WildRange([string]$rel) {
    $j = Get-JsonV $rel
    foreach ($p in $j['placement']) {
        if ($p['type'] -eq 'tfc:climate') {
            return [ordered]@{ minT=[double]$p['min_temperature']; maxT=[double]$p['max_temperature']
                               minG=[int]$p['min_groundwater'];     maxG=[int]$p['max_groundwater']
                               minForest=[int]$p['min_forest'];     maxForest=[int]$p['max_forest'] }
        }
    }
    return $null
}
# TFC 的养分写法：正数=消耗（无符号），负数=补充（带 + 号），数值 ×100
function Fmt-Npk([string]$npk, [string]$lang = 'zh_cn') {
    $parts = $npk -split '/'
    $out = @()
    foreach ($p in $parts) {
        $v = [double]$p.Trim()
        if ($v -lt 0) { $out += '+' + [Math]::Round([Math]::Abs($v) * 100) } else { $out += [string][Math]::Round($v * 100) }
    }
    # 照 TFC 原版写法（对照 tfc 手册 food/crops.json）：
    #   中文  $(bold)$(3)氮$(): 100 $(bold)$(6)磷$(): +40 $(bold)$(d)钾$(): +30$()
    #   英文  $(bold)$(3)Nitrogen$(): 100 ...
    # 注意每个标签单独闭合，最后再补一个 $() 收掉整段。
    # ⚠️ 必须按语言分支：早先写死了中文标签，英文页面里会混进「氮/磷/钾」。
    if ($lang -eq 'en_us') {
        return "`$(bold)`$(3)Nitrogen`$(): $($out[0]) `$(bold)`$(6)Phosphorous`$(): $($out[1]) `$(bold)`$(d)Potassium`$(): $($out[2])`$()"
    }
    return "`$(bold)`$(3)氮`$(): $($out[0]) `$(bold)`$(6)磷`$(): $($out[1]) `$(bold)`$(d)钾`$(): $($out[2])`$()"
}
function SoilGuidePages([string]$lang) {
    if ($lang -eq 'zh_cn') {
        return @(
            [ordered]@{type='patchouli:text';title='养分与施肥';text='按住Shift查看种子养分提示：正数为消耗，带+号为回补；实际回补受生长、土壤及其他养分供给影响。$(br2)手持原版肥料右键作物或耕地施肥；潜行可批量施肥，满额时不消耗。堆肥补氮、钾，不补磷；缺磷可用骨粉或木灰。$(br2)$(l:tfc:food/fertilizers)查看原版肥料说明$()。'}
            [ordered]@{type='patchouli:text';title='堆肥循环';text='蔬菜、水果可作高档绿料，谷物可作中档绿料；冬瓜、葫芦、哈密瓜的整瓜也可作高档绿料。$(br2)树叶与B木工的木屑可作低档棕料。使用原版堆肥箱，遵守绿料/棕料比例和等待时间。骨粉可直接施肥，但属于堆肥毒物，不能混入。$(br2)$(l:tfc:food/composter)查看堆肥操作$()。'}
        )
    }
    return @(
        [ordered]@{type='patchouli:text';title='Soil nutrients';text='Hold Shift over seeds: unsigned amounts consume nutrients; + amounts return them. Actual return depends on growth, soil and other nutrient supply.$(br2)Use native fertilizer on crops or farmland. Crouching applies a batch; full relevant bars consume none. Compost supplies nitrogen and potassium, not phosphorus; use bone meal or wood ash for phosphorus.$(br2)$(l:tfc:food/fertilizers)Native fertilizers$().'}
        [ordered]@{type='patchouli:text';title='Composting';text='Vegetables and fruit are high green material; grain is medium green. Project whole winter melons, bottle gourds and cantaloupes also count as high green.$(br2)Leaves and B woodworking sawdust are low brown material. Use the native composter ratio and waiting rules. Bone meal fertilizes soil but poisons compost; keep it out of the composter.$(br2)$(l:tfc:food/composter)Composting instructions$().'}
    )
}
function MaterialGuidePage([string]$lang) {
    $text = if ($lang -eq 'zh_cn') {
        '装有B扩展时，四种麻纤维可接入原生加工：同种纤维12份在TFC织机操作12次得到1块粗麻布；两份纤维在合成格斜放得到2根绳索。$(br2)1个棉铃与原版纺锤合成1份通用线，纺锤按原版规则返还并消耗耐久，耗尽则损坏。$(br2)麻纤维和棉铃可作高档棕料；啤酒花可作低档绿料，酿酒链留待后续。'
    } else {
        'With expansion B, place 12 of the same plant fiber in a TFC loom and work 12 steps for 1 burlap cloth. Two fibers placed diagonally craft 2 ropes.$(br2)One cotton boll and a native spindle craft 1 generic string; the spindle is returned with damage, or breaks when worn out.$(br2)Plant fibers and cotton bolls are high brown compost material. Hops are low green material; the brewing chain remains future work.'
    }
    return [ordered]@{type='patchouli:text';anchor='materials';title=$(if($lang -eq 'zh_cn'){'植物材料用途'}else{'Plant materials'});text=$text}
}
function FoodProcessingGuidePages([string]$lang) {
    if ($lang -eq 'zh_cn') {
        return @(
            [ordered]@{type='patchouli:text';anchor='grain_processing';title='谷物加工';text='装有B扩展时，斯佩尔特小麦、二粒小麦、一粒小麦可用TFC手磨磨粉：每份得1份原生小麦粉，保留食品历史并拒绝腐烂原料。$(br2)小麦粉沿用原生面团及现有搅拌碗配方，不新增面团。高粱归为谷物，不再作为蔬菜入菜。其余项目谷物尚无专属磨粉链，可食用或按原生规则堆肥。'}
            [ordered]@{type='patchouli:text';anchor='beans_oilseeds';title='豆类与油料';text='现有豆类、芝麻、红花、向日葵产物保留原食品数据，可按蔬菜标签用于原生汤、沙拉或三明治。配方仍遵守设备和食品规则。$(br2)油料专属榨油链尚未接入，不会磨成菜籽糊冒充其他油。搅拌碗面团拒绝腐烂原料，并按TFC规则继承投入食品的历史。'}
        )
    }
    elseif ($lang -eq 'en_us') {
        return @(
            [ordered]@{type='patchouli:text';anchor='grain_processing';title='Grain processing';text='With expansion B, quern one spelt, emmer or einkorn into one native wheat flour. Rotten inputs are rejected and food history is carried over.$(br2)Use existing native dough and mixing bowl recipes. Sorghum is grain rather than a vegetable. Other project grains have no dedicated milling chain yet; eat or compost them under native rules.'}
            [ordered]@{type='patchouli:text';anchor='beans_oilseeds';title='Beans and oilseeds';text='Existing beans, sesame, safflower and sunflower harvests retain their food data and vegetable-tag access to native soup, salads and sandwiches. Equipment and food rules still apply.$(br2)Dedicated oil extraction is not connected; these crops do not become canola paste. Project bowl dough rejects rotten ingredients and carries input food history using TFC rules.'}
        )
    }
}
function VegetableBeverageGuidePages([string]$lang) {
    if ($lang -eq 'zh_cn') {
        return @(
            [ordered]@{type='patchouli:text';anchor='vegetables_seasoning';title='蔬菜与调味';text='本项目的叶菜、根茎、水生蔬菜等可按原生规则制作汤、沙拉或三明治，也可作高档绿料。$(br2)装有B扩展时，姜、姜黄可在石臼磨成粉。将新鲜香料粉与尚未调味的新鲜汤放入合成格，给原汤加调味；同一碗汤不能重复调味。$(br2)案板切出的姜片、姜黄片和白菜丝同样可用于原生做菜。'}
            [ordered]@{type='patchouli:text';anchor='tea_coffee_status';title='茶叶与咖啡豆';text='茶树和咖啡树是多年生灌木，在结果期右键采收茶叶或咖啡豆。$(br2)两种收获物目前保留直接食用的既有设定，也可作低档绿料，加入原生堆肥箱并搭配棕料。$(br2)茶叶杀青、炒制、冲泡，以及咖啡烘焙、研磨、冲泡尚未开放；鲜叶或生豆不能直接当成饮品。'}
        )
    }
    elseif ($lang -eq 'en_us') {
        return @(
            [ordered]@{type='patchouli:text';anchor='vegetables_seasoning';title='Vegetables and spices';text='Project leaf, root and aquatic vegetables can enter native soup, salad and sandwich recipes, or high-green compost.$(br2)With B, grind ginger or turmeric in a mortar. Craft fresh spice powder with fresh, unseasoned soup to season the same soup once.$(br2)Board-cut ginger, turmeric and napa cabbage retain native vegetable uses.'}
            [ordered]@{type='patchouli:text';anchor='tea_coffee_status';title='Tea and coffee harvests';text='Tea and coffee are perennial bushes; right-click during fruiting to harvest leaves or beans.$(br2)Their existing edible behavior is retained. Both are now low-green compost material; combine with brown material in the native composter.$(br2)Tea fixing, roasting and brewing, and coffee roasting, grinding and brewing are not available yet. Raw harvests are not drinks.'}
        )
    }
}
function T([double]$v) { return $v.ToString('0.#', [System.Globalization.CultureInfo]::InvariantCulture) }

# ---------------- 数据 ----------------
$bushes = @(
    [ordered]@{ n='lingonberry'; high=$false;  zh='越橘';         en='Lingonberry';  zhLife='4~6 月生长，7 月开花，8~9 月结果'; enLife='grows from April to June, flowers in July, and bears fruit in August and September'; zhHab='多见于寒冷湿润的林缘与沼泽边'; enHab='It can be found in cold, damp forests' }
    [ordered]@{ n='bearberry'; high=$false;    zh='熊果';         en='Bearberry';    zhLife='5~6 月生长，7 月开花，8~9 月结果'; enLife='grows from May to June, flowers in July, and bears fruit in August and September'; zhHab='极耐寒耐旱，生于开阔的砾石地与针叶林下'; enHab='It can be found in open gravelly ground and under conifers' }
    [ordered]@{ n='crowberry'; high=$false;    zh='岩高兰';       en='Crowberry';    zhLife='5~6 月生长，7 月开花，8 月结果';   enLife='grows from May to June, flowers in July, and bears fruit in August'; zhHab='生于岩石与苔原，耐极寒'; enHab='It can be found on rocks and tundra' }
    [ordered]@{ n='bilberry'; high=$false;     zh='山蓝莓';     en='Bilberry';     zhLife='4~6 月生长，7 月开花，8 月结果';   enLife='grows from April to June, flowers in July, and bears fruit in August'; zhHab='生于针叶林与酸性土壤'; enHab='It can be found in coniferous forests' }
    [ordered]@{ n='blackcurrant'; high=$true; zh='黑加仑';       en='Blackcurrant'; zhLife='4~5 月生长，6 月开花，7~8 月结果'; enLife='grows from April to May, flowers in June, and bears fruit in July and August'; zhHab='喜湿润肥沃的河谷与林缘'; enHab='It can be found in damp, fertile valleys' }
    [ordered]@{ n='redcurrant'; high=$true;   zh='红加仑';       en='Redcurrant';   zhLife='5 月生长，6 月开花，7~8 月结果';   enLife='grows in May, flowers in June, and bears fruit in July and August'; zhHab='喜温凉湿润，多见于林缘'; enHab='It can be found at forest edges' }
    [ordered]@{ n='haskap'; high=$true;       zh='蓝靛果';       en='Haskap';       zhLife='3~4 月生长，5 月开花，6 月结果';   enLife='grows from March to April, flowers in May, and bears fruit in June'; zhHab='极耐寒，是本组最早熟的'; enHab='It is the hardiest and earliest ripening of this group' }
    [ordered]@{ n='goji'; high=$true;         zh='枸杞';         en='Goji Berry';   zhLife='4~5 月生长，6 月开花 7 月结果，8 月二度开花 9 月结果'; enLife='grows from April to May, flowers in June and again in August, and bears fruit in July and September'; zhHab='耐旱，生于干燥向阳的坡地'; enHab='It can be found on dry, sunny slopes' }
    [ordered]@{ n='serviceberry'; high=$true; zh='唐棣';         en='Serviceberry'; zhLife='4 月生长，5 月开花，6 月结果';     enLife='grows in April, flowers in May, and bears fruit in June'; zhHab='生于林缘与灌丛'; enHab='It can be found at forest edges and in thickets' }
    [ordered]@{ n='aronia'; high=$true;       zh='野樱莓'; en='Aronia';       zhLife='5~7 月生长，8 月开花，9~10 月结果'; enLife='grows from May to July, flowers in August, and bears fruit in September and October'; zhHab='生于湿地与沼泽边缘'; enHab='It can be found in wet ground and at the edge of marshes' }
    # 批次 4：茶树 / 咖啡树。两者不是浆果，但同为多年生灌木、年年采收，
    # 所以照灌木的形式写；产物分别是茶叶与咖啡豆。
    [ordered]@{ n='tea'; high=$true; zh='茶树'; en='Tea Bush'; zhLife='3~5 月抽新芽，6~7 月开花，8~10 月采叶'; enLife='sends out new shoots from March to May, flowers in June and July, and is picked for its leaves from August to October'; zhHab='生于温暖湿润的丘陵，耐得住轻霜'; enHab='It can be found on warm, moist hillsides and takes light frost' }
    [ordered]@{ n='coffee'; high=$true; zh='咖啡树'; en='Coffee Bush'; zhLife='3 月返青，4~5 月开花，6~8 月结果'; enLife='leafs out in March, flowers in April and May, and bears fruit from June to August'; zhHab='生于终年无霜的热带高地'; enHab='It can be found in frost free tropical highlands' }
)

# 导语里的灌木数量自动统计（以后加灌木不会失同步）
$script:nHighBush  = @($bushes | Where-Object { [bool]$_['high'] }).Count
$script:nSmallBush = @($bushes | Where-Object { -not [bool]$_['high'] }).Count

$crops = @(
    [ordered]@{ n='spinach';        zh='菠菜';     en='Spinach';        npk='0.7 / -0.2 / -0.2'; zhDesc='最耐寒的叶菜之一，霜降前都还能长'; enDesc='one of the hardiest greens, still growing until the first hard frost' }
    [ordered]@{ n='lettuce';        zh='生菜';     en='Lettuce';        npk='0.6 / -0.2 / -0.2'; zhDesc='含水量很高，同时补充水分与蔬菜营养'; enDesc='very watery, topping up both hunger and thirst' }
    [ordered]@{ n='celery';         zh='芹菜';     en='Celery';         npk='0.7 / 0.3 / 0.4';   zhDesc='耗水较多，茎秆清脆多汁'; enDesc='thirsty, with crisp and juicy stalks' }
    [ordered]@{ n='kale';           zh='羽衣甘蓝'; en='Kale';           npk='0.7 / 0.2 / 0.3';   zhDesc='能扛 -20 °C，是寒带农场最可靠的蔬菜'; enDesc='survives -20 °C, the most reliable vegetable of the far north' }
    [ordered]@{ n='napa_cabbage';   zh='白菜';   en='Napa Cabbage';   npk='0.7 / 0.2 / 0.4';   zhDesc='与卷心菜同级的当家菜'; enDesc='a staple on par with TFC cabbage' }
    [ordered]@{ n='mustard_greens'; zh='芥菜';     en='Mustard Greens'; npk='0.3 / 0.25 / 0.35'; zhDesc='带辛辣味，略耐热'; enDesc='peppery and a little more heat-tolerant' }
    [ordered]@{ n='broccoli';       zh='西兰花';   en='Broccoli';       npk='0.8 / 0.3 / 0.4';   zhDesc='产量与营养俱佳的温带蔬菜'; enDesc='a temperate vegetable with good yield and nutrition' }
    [ordered]@{ n='cauliflower';    zh='花菜';   en='Cauliflower';    npk='0.8 / 0.3 / 0.4';   zhDesc='与西兰花同源，更喜凉爽湿润'; enDesc="broccoli's close relative, preferring cooler and damper weather" }
    [ordered]@{ n='brussels_sprouts'; zh='芽甘蓝'; en='Brussels Sprouts'; npk='0.8 / 0.3 / 0.4'; zhDesc='茎上结满小球，耐寒，冬前采收最甜'; enDesc='little cabbages along a tall stem' }
    [ordered]@{ n='swiss_chard'; zh='牛皮菜'; en='Swiss Chard'; npk='0.6 / 0.2 / 0.4'; zhDesc='叶柄肥厚、叶片宽大；成熟后破坏整株收获，之后需要重新播种'; enDesc='thick stalks and broad leaves; break the mature plant to harvest, then sow seeds again' }
    [ordered]@{ n='celtuce'; zh='莴笋'; en='Celtuce'; npk='0.6 / -0.2 / -0.2'; zhDesc='茎秆脆嫩，可炒可腌'; enDesc='a crisp stem vegetable' }
    [ordered]@{ n='garland_chrysanthemum'; zh='茼蒿'; en='Garland Chrysanthemum'; npk='0.6 / -0.2 / -0.2'; zhDesc='气味独特的速生叶菜，涮锅首选'; enDesc='a fast, aromatic green' }
    [ordered]@{ n='perilla'; zh='紫苏'; en='Perilla'; npk='0.6 / -0.2 / -0.2'; zhDesc='喜温，叶片带特殊香气'; enDesc='heat-loving, with aromatic leaves' }
    [ordered]@{ n='arugula'; zh='芝麻菜'; en='Arugula'; npk='0.5 / -0.2 / -0.2'; zhDesc='带辛辣芝麻香，生长极快'; enDesc='peppery and nutty' }
    [ordered]@{ n='turnip'; zh='芜菁'; en='Turnip'; npk='0.3 / 0.3 / 0.4'; zhDesc='耐寒的根菜，地窖里能放很久'; enDesc='a hardy root vegetable' }
    [ordered]@{ n='parsnip'; zh='防风'; en='Parsnip'; npk='0.4 / 0.25 / 0.5'; zhDesc='霜打之后更甜的白色根菜'; enDesc='a white root, sweet after frost' }
    [ordered]@{ n='sunchoke'; zh='洋姜'; en='Sunchoke'; npk='0.3 / 0.2 / 0.6'; zhDesc='地下块茎，产量极高且极耐寒'; enDesc='a prolific, hardy tuber' }
    [ordered]@{ n='shallot'; zh='红葱'; en='Shallot'; npk='0.35 / 0.3 / 0.45'; zhDesc='香味细腻的小葱头，耐储存'; enDesc='a fine-flavoured small onion' }
    [ordered]@{ n='celeriac'; zh='根芹'; en='Celeriac'; npk='0.6 / 0.3 / 0.5'; zhDesc='芹菜的地下版本，球茎可炖可泥'; enDesc='the underground cousin of celery' }
    [ordered]@{ n='salsify'; zh='鸦葱'; en='Salsify'; npk='0.4 / 0.3 / 0.5'; zhDesc='细长白根，煮熟有牡蛎般的鲜味'; enDesc='a long white root, faintly oyster-like' }
    [ordered]@{ n='ginger'; zh='生姜'; en='Ginger'; npk='0.5 / 0.3 / 0.6'; zhDesc='喜温的辛香根茎，晒干后能存很久'; enDesc='a warm-climate pungent rhizome, keeps well dried' }
    [ordered]@{ n='turmeric'; zh='姜黄'; en='Turmeric'; npk='0.5 / 0.25 / 0.6'; zhDesc='比生姜更怕冷，根茎切开是明亮的橙黄'; enDesc='less cold-hardy than ginger, with a bright orange rhizome' }
    [ordered]@{ n='yacon'; zh='雪莲果'; en='Yacon'; npk='0.35 / 0.3 / 0.5'; zhDesc='块根清甜多汁，可当水果吃'; enDesc='a sweet, juicy tuber' }
    [ordered]@{ n='chicory_root'; zh='菊苣'; en='Chicory Root'; npk='0.4 / 0.2 / 0.5'; zhDesc='根可烘焙代咖啡，叶可作沙拉'; enDesc='the root roasts as a coffee substitute' }
    # ── 批次 3：谷物（12 种）──
    #    ⚠️ TFC 的谷物本身不给营养（需磨粉→面团→面包），我们没有那条加工链，因此直接给 grain 营养。
    [ordered]@{ n='millet'; zh='黍'; en='Millet'; npk='0.7 / -0.2 / -0.2'; zhDesc='耐旱耐贫瘠，最早熟的谷物之一，古时北方的主粮'; enDesc='drought hardy and quick to ripen' }
    [ordered]@{ n='foxtail_millet'; zh='谷子'; en='Foxtail Millet'; npk='0.7 / -0.2 / -0.2'; zhDesc='脱壳就是小米，熬粥最香，也最耐储存'; enDesc='hulled it becomes millet; it keeps very well' }
    [ordered]@{ n='buckwheat'; zh='荞麦'; en='Buckwheat'; npk='0.6 / 0.2 / 0.3'; zhDesc='生长期短，贫地也能收，磨粉可做面食'; enDesc='short seasoned and tolerant of poor soil' }
    [ordered]@{ n='fonio'; zh='福尼奥米'; en='Fonio'; npk='0.6 / -0.2 / -0.2'; zhDesc='西非的古老谷物，极耐旱，六十天就能收'; enDesc='an ancient West African grain, extremely drought tolerant' }
    [ordered]@{ n='spelt'; zh='斯佩耳特麦'; en='Spelt'; npk='0.7 / 0.1 / 0.3'; zhDesc='古老的小麦近亲，壳硬难脱，但麦香浓郁'; enDesc='an old wheat relative with a tough husk and rich flavour' }
    [ordered]@{ n='emmer'; zh='二粒麦'; en='Emmer'; npk='0.7 / 0.1 / 0.3'; zhDesc='新月沃地最早的栽培小麦之一'; enDesc='one of the first wheats ever farmed' }
    [ordered]@{ n='einkorn'; zh='单粒麦'; en='Einkorn'; npk='0.6 / 0.1 / 0.3'; zhDesc='最古老的小麦，穗小粒少，却极耐瘠薄'; enDesc='the oldest wheat of all; small ears, but very hardy' }
    [ordered]@{ n='pearl_millet'; zh='珍珠粟'; en='Pearl Millet'; npk='0.7 / -0.2 / -0.2'; zhDesc='萨赫勒地区的耐热主粮，穗大粒圆'; enDesc='a heat loving staple of the Sahel' }
    [ordered]@{ n='amaranth'; zh='苋米'; en='Amaranth'; npk='0.6 / 0.2 / 0.3'; zhDesc='籽粒极小的伪谷物，穗子像火把一样红'; enDesc='a tiny seeded pseudo cereal with torch red plumes' }
    [ordered]@{ n='quinoa'; zh='藜麦'; en='Quinoa'; npk='0.6 / 0.2 / 0.3'; zhDesc='高原谷物，耐霜耐旱，籽粒营养很全面'; enDesc='a highland grain that shrugs off frost and drought' }
    [ordered]@{ n='finger_millet'; zh='穇子'; en='Finger Millet'; npk='0.6 / -0.2 / -0.2'; zhDesc='穗像手指一样张开，耐储存，可酿酒'; enDesc='its seed head spreads like fingers; stores very well' }
    [ordered]@{ n='jobs_tears'; zh='薏苡'; en="Job's Tears"; npk='0.7 / 0.2 / 0.4'; zhDesc='籽粒外包一层硬壳，可煮粥，也可串珠子'; enDesc='hard shelled grain, eaten in soups or strung as beads' }
    # ── 批次 3：豆类（6 种）──
    #    TFC 手册里豆类的类别词是「豆类 / Legume」（不是蔬菜）。
    #    NPK 的氮为负：豆科固氮，种一季反而补充土壤里的氮。
    [ordered]@{ n='chickpea'; zh='鹰嘴豆'; en='Chickpea'; npk='-0.6 / 0.2 / 0.3'; zhDesc='中东与南亚的当家豆，耐旱，鹰嘴状的小豆粒'; enDesc='a drought tolerant staple of the Middle East and South Asia' }
    [ordered]@{ n='faba_bean'; zh='蚕豆'; en='Faba Bean'; npk='-0.7 / 0.15 / 0.25'; zhDesc='豆粒肥大，最耐寒的豆类之一，秋播也能越冬'; enDesc='big flat beans and one of the hardiest legumes' }
    [ordered]@{ n='lupin'; zh='羽扇豆'; en='Lupin'; npk='-0.5 / 0.15 / 0.2'; zhDesc='蛋白含量数一数二，花穗像烛台一样立着'; enDesc='very high in protein, with candle like flower spikes' }
    [ordered]@{ n='adzuki'; zh='红小豆'; en='Adzuki Bean'; npk='-0.6 / 0.2 / 0.3'; zhDesc='东亚的红皮小豆，煮豆沙最香'; enDesc='the small red bean of East Asia, the classic filling for sweet pastes' }
    [ordered]@{ n='bambara_nut'; zh='班巴拉豆'; en='Bambara Nut'; npk='-0.6 / 0.15 / 0.25'; zhDesc='非洲的地下结荚豆，耐旱又顶饱'; enDesc='an African legume that pods underground; drought hardy and filling' }
    [ordered]@{ n='fenugreek'; zh='胡卢巴'; en='Fenugreek'; npk='-0.7 / 0.2 / 0.3'; zhDesc='籽与嫩叶都能吃，带一股焦糖似的香气'; enDesc='both the seeds and the greens are eaten, with a maple like aroma' }

    # ── 批次 3：油料 / 纤维（4 种）──
    #    类别照 TFC：油菜是「覆盖作物」、黄麻是「杂项」。
    #    ⚠️ 亚麻/苎麻的产物是纤维（tfc:jute_fiber），没有可食用的籽 —— 见 docs §5.19。
    #    zhProd/enProd：页面上的**产物名**。产物不是自己的食物物品时必须写，
    #    否则正文会写成「收割亚麻得到亚麻」，与掉落表不符。
    [ordered]@{ n='flax'; zh='亚麻'; en='Flax'; npk='0.6 / 0.2 / 0.3'; zhProd='纤维（与 TFC 的黄麻纤维是同一种物品）'; enProd="fibre (the same item as TFC's jute fibre)"; zhDesc='茎皮纤维坚韧，可织亚麻布'; enDesc='its bast fibre is woven into linen' }
    [ordered]@{ n='sesame'; zh='芝麻'; en='Sesame'; npk='0.6 / 0.2 / 0.3'; zhDesc='籽粒极小，香气浓，怕冷'; enDesc='tiny aromatic seeds; it hates the cold' }
    [ordered]@{ n='safflower'; zh='红花'; en='Safflower'; npk='0.6 / 0.2 / 0.3'; zhDesc='花可作红色染料，籽可榨油，耐旱'; enDesc='a red dye from the flowers, oil from the seed' }
    [ordered]@{ n='ramie'; zh='苎麻'; en='Ramie'; npk='0.5 / 0.2 / 0.4'; zhProd='纤维（与 TFC 的黄麻纤维是同一种物品）'; enProd="fibre (the same item as TFC's jute fibre)"; zhDesc='茎皮纤维坚韧，可织夏布'; enDesc='a tough bast fibre, woven into summer cloth' }

    # ── 批次 4：多年生可采摘蔬菜（7 种）+ 棉花 ──
    #    前 7 种不会在成熟时被整株割掉：采摘只取走果实，植株退回未成熟状态继续长，
    #    因此沿用 TFC 手册的类别词「可采摘蔬菜 / Pickable Vegetable」。
    #    NPK 与 MyCrops.java 的 pickable(...) 一一对应。
    #    ⚠️ 棉花是一年生，成熟即连秆收割，既不属于可采摘蔬菜、
    #       也不是蔬菜，照 TFC 把黄麻归「杂项」的先例写进杂项（见 §miscNames）。
    [ordered]@{ n='chili'; zh='辣椒'; en='Chili'; npk='0.3 / 0.4 / 0.5'; zhDesc='果实由绿转红，晒得越足越辣'; enDesc='the pods turn from green to red, and the more sun they get the hotter they are' }
    [ordered]@{ n='eggplant'; zh='茄子'; en='Eggplant'; npk='0.35 / 0.4 / 0.5'; zhDesc='喜温的茄科植物，果实沉甸甸地垂着'; enDesc='a heat loving nightshade with heavy hanging fruit' }
    [ordered]@{ n='okra'; zh='秋葵'; en='Okra'; npk='0.4 / 0.35 / 0.5'; zhDesc='嫩荚带黏液，天越热长得越快'; enDesc='its pods are mucilaginous, and it grows faster the hotter it gets' }
    [ordered]@{ n='cotton'; zh='棉花'; en='Cotton'; npk='0.6 / 0.3 / -0.3'; zhProd='棉铃'; enProd='cotton bolls'; zhDesc='蒴果裂开后露出白色的棉絮'; enDesc='the bolls split open to show white lint' }
    [ordered]@{ n='asparagus'; zh='芦笋'; en='Asparagus'; npk='0.6 / 0.3 / 0.4'; zhDesc='春天从根里抽出嫩茎，割了还会再发'; enDesc='sends up tender spears in spring, and keeps sending more' }
    [ordered]@{ n='chive'; zh='韭菜'; en='Chive'; npk='0.6 / -0.2 / -0.2'; zhDesc='气味辛香，割下叶子后很快又长齐'; enDesc='pungent leaves that soon grow back after cutting' }
    [ordered]@{ n='rhubarb'; zh='大黄'; en='Rhubarb'; npk='0.5 / 0.2 / 0.3'; zhDesc='叶柄是食材，叶片不用于食用'; enDesc='the stalks are food, while leaves are not harvested as food'; zhProductNote='叶柄可直接食用或用于原生汤、沙拉和三明治；使用未腐烂原料。'; enProductNote='Eat the stalks or use them in native soup, salads and sandwiches; use unrotten ingredients.' }
    [ordered]@{ n='artichoke'; zh='洋蓟'; en='Artichoke'; npk='0.7 / 0.3 / 0.5'; zhDesc='趁花苞还没开就采下，是地中海的名菜'; enDesc='picked before the bud opens, a Mediterranean classic' },
    # ── 批次 5：水田作物（10 种）· Java 侧用 MyFloodedCropBlock（含水方块）──
    [ordered]@{ n='taro'; flooded=$true; zh='芋头'; en='Taro'; npk='0.45 / 0.35 / 0.6'; zhDesc='水田里的淀粉块茎，煮熟后绵软'; enDesc='a starchy tuber grown in paddies' }
    [ordered]@{ n='water_chestnut'; flooded=$true; zh='荸荠'; en='Water Chestnut'; npk='0.4 / 0.3 / 0.6'; zhDesc='球茎脆甜，生吃炒菜都行'; enDesc='a crisp, sweet corm' }
    [ordered]@{ n='water_caltrop'; flooded=$true; zh='菱角'; en='Water Caltrop'; npk='0.35 / 0.3 / 0.55'; zhDesc='两角尖尖的坚果，煮粉了最好吃'; enDesc='a two horned nut, best boiled soft' }
    [ordered]@{ n='wild_rice_stem'; flooded=$true; zh='茭白'; en='Wild Rice Stem'; npk='0.5 / 0.3 / 0.5'; zhDesc='被菌感染后膨大的嫩茎，鲜嫩多汁'; enDesc='the swollen shoot, tender and juicy' }
    [ordered]@{ n='lotus'; flooded=$true; zh='莲藕'; en='Lotus'; npk='0.45 / 0.35 / 0.6'; zhDesc='淤泥里的藕节，切开满是孔洞'; enDesc='a rhizome riddled with air channels' }
    [ordered]@{ n='water_dropwort'; flooded=$true; zh='水芹'; en='Water Dropwort'; npk='0.5 / 0.3 / 0.4'; zhDesc='水边丛生的香芹，越冷越嫩'; enDesc='a fragrant celery relative that prefers the cold' }
    [ordered]@{ n='water_spinach'; flooded=$true; zh='空心菜'; en='Water Spinach'; npk='0.8 / -0.2 / -0.2'; zhDesc='茎中空的速生叶菜，割了又发'; enDesc='a fast hollow stemmed green' }
    [ordered]@{ n='arrowhead'; flooded=$true; zh='慈菇'; en='Arrowhead'; npk='0.45 / 0.35 / 0.55'; zhDesc='带尖芽的球茎，微苦回甘'; enDesc='a beaked tuber with a bitter edge' }
    [ordered]@{ n='gorgon_nut'; flooded=$true; zh='芡实'; en='Gorgon Nut'; npk='0.4 / 0.3 / 0.55'; zhDesc='满身尖刺的睡莲籽，晒干能放很久'; enDesc='the spiny seed of a water lily, keeps very well' }
    # ── 批次 6：瓜类（蔓延型·产物挂在结果方块上）──
    [ordered]@{ n='winter_melon'; zh='冬瓜'; en='Winter Melon'; spread=$true; npk='0.5 / 0.35 / 0.55'; zhDesc='表皮挂霜的大瓜，能存到冬天'; enDesc='a big frosted gourd that keeps into winter' }
    # ── 批次 7：攀爬作物（6 种）──
    [ordered]@{ n='hops';             zh='啤酒花'; en='Hops';             climb=$true; npk='0.9 / 0.2 / -0.3'; zhDesc='雌花酿啤酒，苦香扑鼻'; enDesc='the cones that bitter a beer' }
    [ordered]@{ n='loofah';          zh='丝瓜';   en='Loofah';          climb=$true; npk='0.45 / 0.3 / 0.5'; zhDesc='嫩时做汤，老了只剩一团纤维'; enDesc='tender in soup, nothing but fibre when old' }
    [ordered]@{ n='bitter_melon';    zh='苦瓜';   en='Bitter Melon';    climb=$true; npk='0.4 / 0.35 / 0.5'; zhDesc='苦味来自瓜肉，越熟越苦'; enDesc='the bitterness is in the flesh, stronger as it ripens' }
    [ordered]@{ n='snake_gourd';     zh='蛇瓜';   en='Snake Gourd';     climb=$true; npk='0.4 / 0.35 / 0.5'; zhDesc='能垂到两米长的细长瓜'; enDesc='a gourd that hangs two meters long' }
    [ordered]@{ n='yam';             zh='山药';   en='Yam';             climb=$true; npk='0.5 / 0.3 / 0.6'; zhDesc='地下长条块茎，削皮手会痒'; enDesc='a long underground tuber' }
    [ordered]@{ n='malabar_spinach'; zh='木耳菜'; en='Malabar Spinach'; climb=$true; npk='0.7 / -0.2 / -0.2'; zhDesc='叶片肥厚发黏，越热越旺'; enDesc='thick, mucilaginous leaves that love the heat' }
    [ordered]@{ n='chayote'; zh='佛手瓜'; en='Chayote'; climb=$true; npk='0.4 / 0.35 / 0.5'; zhDesc='需支架才能长高，成熟后连株收获'; enDesc='needs support to grow tall and is removed at harvest' }
    [ordered]@{ n='bottle_gourd'; zh='瓠瓜'; en='Bottle Gourd'; spread=$true; npk='0.4 / 0.3 / 0.5'; zhDesc='嫩时做菜，老了当水瓢'; enDesc='eaten young, dried into a ladle when old' }
    [ordered]@{ n='cantaloupe'; zh='哈密瓜'; en='Cantaloupe'; spread=$true; npk='0.4 / 0.35 / 0.55'; zhDesc='网纹瓜皮，切开满是甜汁'; enDesc='netted skin, sweet juicy flesh' }
    [ordered]@{ n='water_shield'; flooded=$true; zh='莼菜'; en='Water Shield'; npk='0.4 / 0.2 / 0.3'; zhDesc='裹着透明胶质的嫩叶，最娇气'; enDesc='tender leaves in a clear jelly' }
    # ── 批次 12：莲座类（第 7 种作物形状）──
    #    ⚠️ 顺序必须紧跟在 gen-crops 表的末尾，否则 202 行的顺序自检会失败、跳转映射整体偏移。
    [ordered]@{ n='cardoon';  rosette=$true; zh='刺菜蓟'; en='Cardoon';  npk='0.6 / 0.3 / 0.5'; zhDesc='叶丛贴地轮生，中心抽出肥嫩的花苞——朝鲜蓟的近亲'; enDesc='a ground-hugging rosette whose heart sends up a tender bud' }
    [ordered]@{ n='agave';    rosette=$true; zh='龙舌兰'; en='Agave';    npk='0.3 / 0.2 / 0.5'; zhDesc='收获中心食材，侧芽用于种植'; enDesc='the central heart is food and sidebuds are used for planting'; zhProductNote='食材是龙舌兰心，侧芽用于播种。当前没有专属烤制或榨汁配方。'; enProductNote='The harvested food is the agave heart; sidebuds are for planting. No dedicated roasting or juice recipe is connected.' }
    [ordered]@{ n='purslane'; rosette=$true; zh='马齿苋'; en='Purslane'; npk='0.4 / 0.2 / 0.3'; zhDesc='肉质叶片贴地铺开，越热长得越旺，酸脆多汁'; enDesc='fleshy leaves spread flat on the ground; thrives in heat' }
    # ── 补齐物种缺口（2026-09-26）：豆科攀爬 4 + 木豆 + 向日葵 + 大麻 + 高粱 + 剑麻 ──
    [ordered]@{ n='pea';          zh='豌豆';   en='Pea';          climb=$true; npk='-0.7 / 0.3 / 0.3';  zhDesc='豆科攀爬作物，根瘤固氮，卷须攀架而上'; enDesc='a climbing legume that fixes nitrogen and twines up a trellis' }
    [ordered]@{ n='cowpea';       zh='豇豆';   en='Cowpea';       climb=$true; npk='-0.8 / 0.4 / 0.3';  zhDesc='耐热耐旱的攀爬豆，长荚垂挂'; enDesc='a heat-loving climbing bean with long hanging pods' }
    [ordered]@{ n='common_bean';  zh='菜豆';   en='Common Bean';  climb=$true; npk='-0.8 / 0.4 / 0.4';  zhDesc='最常见的攀爬豆类，荚嫩豆香'; enDesc='the everyday climbing bean' }
    [ordered]@{ n='winged_bean';  zh='四棱豆'; en='Winged Bean';  climb=$true; npk='-1.0 / 0.3 / 0.4';  zhDesc='荚有四条棱翅，热带藤本，全株可食'; enDesc='pods with four winged edges; a tropical vine, every part edible' }
    [ordered]@{ n='pigeon_pea';   zh='木豆';   en='Pigeon Pea';   npk='-0.9 / 0.4 / 0.4'; zhDesc='半木质的耐旱豆类，可连年生长'; enDesc='a semi-woody drought-hardy legume' }
    [ordered]@{ n='sunflower';    zh='向日葵'; en='Sunflower';    npk='0.8 / -0.3 / -0.4'; zhDesc='收获食用葵花籽，播种种子单独保留'; enDesc='harvests edible sunflower seeds, separate from seeds used for planting'; zhProductNote='食用籽可直接食用或用于原生餐食；当前没有专属榨油配方。'; enProductNote='Eat the food seeds or use them in native meals. Dedicated oil extraction is not connected.' }
    [ordered]@{ n='hemp';         zh='大麻';   en='Hemp';         npk='0.7 / -0.3 / -0.3'; zhProd='大麻纤维'; enProd='Hemp Fibre'; zhDesc='茎皮纤维最韧，可搓绳织布'; enDesc='the toughest bast fibre; rope and cloth' }
    [ordered]@{ n='sorghum';      zh='高粱';   en='Sorghum';      npk='1.0 / -0.3 / -0.3'; zhDesc='耐旱高秆谷物，穗大粒密'; enDesc='a drought-hardy tall grain with a dense head' }
    [ordered]@{ n='sisal';        zh='剑麻';   en='Sisal';        rosette=$true; npk='0.4 / -0.4 / -0.4'; zhProd='剑麻纤维'; enProd='Sisal Fibre'; zhDesc='极耐旱的硬叶莲座，叶纤维可制绳索'; enDesc='a drought-proof hard-leaved rosette; its fibre makes rope' }
    [ordered]@{ n='strawberry';   zh='草莓';   en='Strawberry';   npk='0.5 / 0.3 / 0.4'; zhDesc='由种子栽培，成熟收获原版草莓'; enDesc='grown from seeds and harvested for TFC strawberries' }
)

# ⚠️ 自检：手册表的顺序必须与 gen-crops 导出的清单一致。
#   手册页面顺序由本表决定，而跳转映射由 anchor 反推 —— 两者顺序若不同，
#   页面与跳转会对不上（§5.29 实测：水田作物插在表尾而 polish-book 插在中部，跳转整体偏移）。
$manifestPath = Join-Path $PSScriptRoot 'crops-manifest.json'
if (Test-Path $manifestPath) {
    $mf = [System.IO.File]::ReadAllText($manifestPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    $mfNames  = @($mf.crops | ForEach-Object { $_.name })
    $tblNames = @($crops | ForEach-Object { $_.n })
    if ($mfNames.Count -ne $tblNames.Count) {
        throw "手册作物表数量与 gen-crops 清单不一致：手册 $($tblNames.Count) vs 清单 $($mfNames.Count)"
    }
    for ($i = 0; $i -lt $mfNames.Count; $i++) {
        if ($mfNames[$i] -ne $tblNames[$i]) {
            throw "手册作物表顺序与 gen-crops 清单不一致：第 $i 项 手册='$($tblNames[$i])' 清单='$($mfNames[$i])'"
        }
    }
    Write-Host "[自检] 手册作物表与 gen-crops 清单顺序一致（$($mfNames.Count) 种）"
} else {
    Write-Host "[自检] 未找到 crops-manifest.json，跳过顺序核对"
}

# 作物分两类（与 gen-tags.ps1 的 $grainNames 保持一致）：
#   谷类 → c:foods/grain，手册里类别写「谷类」
#   其余 → c:foods/vegetable，手册里类别写「蔬菜类」（TFC 原版用词就是「蔬菜类」）
$script:grainNames = @('millet','foxtail_millet','buckwheat','fonio','spelt','emmer','einkorn','pearl_millet','amaranth','quinoa','finger_millet','jobs_tears')
# 豆类（照 TFC 手册的类别词「豆类 / Legume」）
$script:legumeNames = @('chickpea','faba_bean','lupin','adzuki','bambara_nut','fenugreek')
# 类别词照 TFC 手册的 crops.json：油菜归「覆盖作物」、黄麻归「杂项」
# 棉花与亚麻/苎麻同属纤维作物，照 TFC 把黄麻归「杂项」的先例，一并写杂项。
$script:coverNames = @('sesame','safflower')
$script:miscNames  = @('flax','ramie','cotton')
# 可采摘蔬菜：成熟后只取果实、植株退回未成熟状态继续生长（TFC 手册的「可采摘蔬菜 / Pickable Vegetable」）
# ⚠️ 棉花是**一年生**，成熟即连秆收割，不在这一类里。
$script:pickableNames = @('chili','eggplant','okra','asparagus','chive','rhubarb','artichoke')
# 蔓延型瓜类：TFC 手册的类别词是「蔓延性蔬菜 / Spreading Vegetable」
$script:spreadNames = @('cantaloupe','winter_melon','bottle_gourd')
# 攀爬型（佛手瓜）：需要木棍，正文要说明这一点
$script:climbNames = @($mf.crops | Where-Object { $_.climb } | ForEach-Object { $_.name })
$script:rosetteNames = @($mf.crops | Where-Object { $_.rosette } | ForEach-Object { $_.name })
$script:doubleNames = @($mf.crops | Where-Object { $_.double } | ForEach-Object { $_.name })
$script:nSpread = $script:spreadNames.Count

# 条目导语里的分类计数（自动统计，以后加作物时不会失同步）
$script:nPick   = $script:pickableNames.Count
$script:nGrain  = $script:grainNames.Count
$script:nLegume = $script:legumeNames.Count
$script:nOther  = $script:coverNames.Count + $script:miscNames.Count
$script:nVeg    = @($crops | Where-Object {
    $script:grainNames  -notcontains $_.n -and $script:legumeNames -notcontains $_.n -and
    $script:coverNames  -notcontains $_.n -and $script:miscNames   -notcontains $_.n -and
    $script:spreadNames -notcontains $_.n
}).Count

# ---------------- 页面构造 ----------------
function BushIntroGuidance([bool]$high, [string]$lang) {
    if ($lang -eq 'zh_cn') {
        return '$(br2)在合适土壤与气候下种植，生长按TFC配置计时；结果期右键采收，采后遵守开花冷却。锋利工具可回收主丛，蔓生幼株有概率；枝段掉木棍。南半球换季。自然株需在新生成区块寻找。'
    }
    return '$(br2)Plant on suitable soil and climate. Growth uses TFC settings; right-click when fruiting, then wait for bloom cooldown. Sharp tools recover main bushes (young spreading bushes may fail); canes drop sticks. Seasons shift in the south. Look for wild bushes in newly generated chunks.'
}
function BushPage($b, [string]$lang) {
    $g = GrowthRange 'plant' "$($b['n'])_bush"
    $w = WildRange "data/$NS/worldgen/placed_feature/plant/$($b['n'])_bush_patch.json"
    if ($lang -eq 'zh_cn') {
        $text = "可在下列区域找到：`$(br)`$(bold)`$(l:tfc:core_mechanics/climate#temperature)温度`$(): $(T $w['minT'])°C - $(T $w['maxT'])°C`$(br)`$(bold)`地下水`$(): $($w['minG']) - $($w['maxG'])mm`$(br)`$(bold)森林覆盖率`$(): $($w['minForest']) - $($w['maxForest'])`$(br2)" +
                "栽培需`$(bold)湿度`$(): $($g['minH']) - $($g['maxH']) %。`$(br2)" +
                $(if ([bool]$b['high']) { "形态：`$(thing)蔓生`$() —— 长成后会向四周与上方长出枝叶。`$(br2)" } else { "形态：`$(thing)矮丛`$() —— 低矮一丛，最高一格。`$(br2)" }) +
                "$($b['zh'])在 $($b['zhLife'])；$($b['zhHab'])。"
    } else {
        $text = "Can be found in regions with: `$(br)`$(bold)`$(l:tfc:core_mechanics/climate#temperature)Temperature`$(): $(T $w['minT'])°C - $(T $w['maxT'])°C`$(br)`$(bold)`Groundwater`$(): $($w['minG']) - $($w['maxG'])mm`$(br)`$(bold)Forest coverage`$(): $($w['minForest']) - $($w['maxForest'])`$(br2)" +
                "As a crop it needs `$(bold)hydration`$() $($g['minH']) - $($g['maxH']) %.`$(br2)" +
                $(if ([bool]$b['high']) { "Form: `$(thing)spreading`$() — it puts out side branches and shoots once grown.`$(br2)" } else { "Form: `$(thing)small`$() — a low lying bush, never taller than one block.`$(br2)" }) +
                "$($b['en']) $($b['enLife']). $($b['enHab'])."
    }
    $title = if ($lang -eq 'zh_cn') { $b['zh'] } else { $b['en'] }
    return [ordered]@{ type='patchouli:text'; title=$title; anchor=$b['n']; text=$text }
}
# Rosette instructions come from the reviewed live contract, not the single-block fallback.
function RosetteHarvestText($c, [string]$lang) {
    $text = if ($lang -eq 'zh_cn') { '种子（侧芽）播在$(l:tfc:food/farmland)农田$()上。莲座分六龄生长，完全成熟并显现中心结果态后，破坏整株采收并返还1至2份侧芽；空手右键不采摘。枯死时在原地返还1份对应侧芽，应及时拾取；之后破坏共享死株不再掉落。$(br2)' } else { 'Sow seeds (sidebuds) on $(l:tfc:food/farmland)farmland$(). This rosette has six leaf stages. Once fully grown with a ripe centre, break the whole plant to harvest and receive one to two sidebuds; an empty-hand right-click does not harvest. When it dies, one species sidebud drops immediately: collect it promptly. Breaking the shared dead plant gives nothing further.$(br2)' }
    if ($c['n'] -eq 'sisal') { $text += $(if ($lang -eq 'zh_cn') { '收获剑麻纤维；不是食物。' } else { 'Harvests Sisal Fibre, a material rather than food.' }) }
    return $text
}
function CropPage($c, [string]$lang) {
    $g = GrowthRange 'crop' $c['n']
    $w = WildRange "data/$NS/worldgen/placed_feature/plant/wild_crop/$($c['n'])_patch.json"
    # 类别用词照 TFC 原版手册（food/crops.json）：谷类 / 豆类 / 蔬菜类 / 覆盖作物 / 杂项。
    # 清单与我们 gen-tags.ps1 的 $grainNames 一致（同一批产物进 c:foods/grain）。
    # 页面上的产物名：产物不是自己的食物物品时（纤维 / 棉铃）用表里 zhProd/enProd 指定的写法，
    # 否则正文会写成「收割亚麻得到亚麻」，与掉落表对不上。
    $cprod   = if ($c['zhProd']) { $c['zhProd'] } else { $c['zh'] }
    $cprodEn = if ($c['enProd']) { $c['enProd'] } else { $c['en'] }
    # 水田作物：必须种在积水的耕地上（手册正文与图示都要照 TFC 水稻页那样标出水位）
    $isRosette = $script:rosetteNames -contains $c['n']
    $isFlooded = [bool]$c['flooded']
    $isSpread  = $script:spreadNames -contains $c['n']
    $isClimb   = $script:climbNames -contains $c['n']
    $isGrain  = $script:grainNames  -contains $c['n']
    $isLegume = $script:legumeNames -contains $c['n']
    $isPickable = $script:pickableNames -contains $c['n']
    $cat   = if ($c['n'] -eq 'sisal') { '杂项' } elseif ($isLegume) { '豆类' } elseif ($isGrain) { '谷类' }
             elseif ($script:coverNames -contains $c['n']) { '覆盖作物' }
             elseif ($script:miscNames  -contains $c['n']) { '杂项' }
             elseif ($isPickable) { '可采摘蔬菜' }
             elseif ($script:spreadNames -contains $c['n']) { '蔓延性蔬菜' }
             else { '蔬菜类' }
    $catEn = if ($c['n'] -eq 'sisal') { 'Misc' } elseif ($isLegume) { 'Legume' } elseif ($isGrain) { 'Cereal' }
             elseif ($script:coverNames -contains $c['n']) { 'Cover' }
             elseif ($script:miscNames  -contains $c['n']) { 'Misc' }
             elseif ($isPickable) { 'Pickable Vegetable' }
             elseif ($script:spreadNames -contains $c['n']) { 'Spreading Vegetable' }
             else { 'Vegetable' }
    if ($lang -eq 'zh_cn') {
        $text = "`$(bold)`$(l:tfc:core_mechanics/climate#temperature)温度`$(): $(T $g['minT'])°C - $(T $g['maxT'])°C`$(br)`$(bold)`$(l:tfc:food/hydration)湿度`$(): $($g['minH']) - $($g['maxH']) %`$(br)`$(bold)类别`$(): $($cat)`$(br2)" +
                (Fmt-Npk $c['npk'] $lang) + "`$(br2)" +
                $(if ($isRosette) {
                    RosetteHarvestText $c $lang
                } elseif ($isClimb) {
                    "$($c['zh'])是`$(thing)攀爬性作物`$()。$($c['zhDesc'])。`$(br2)$($c['zh'])种子可以种植在`$(l:tfc:food/farmland)农田`$()上，用`$(thing)木棍`$()右键幼苗可以让它攀爬；长高后成熟，破坏植株采收。`$(br2)"
                } elseif ($isSpread) {
                    "$($c['zh'])是`$(thing)蔓延性作物`$()。$($c['zhDesc'])。`$(br2)种子播在`$(l:tfc:food/farmland)农田`$()上，四周预留结果空地。藤成熟后在旁边结整瓜；破坏整瓜收回原瓜，放到案板上用小刀一瓜切四片，继承新鲜度。藤只返种，腐烂瓜不能加工。`$(br2)"
                } elseif ($isFlooded) {
                    "$($c['zh'])是单格作物。$($c['zhDesc'])。`$(br2)先开垦`$(l:tfc:food/farmland)农田`$()，再在上方备好一格深淡水水源，最后对水下农田播种。完全成熟后破坏收获食材和种子。`$(br2)"
                } elseif ($isPickable) {
                    "$($c['zh'])是`$(thing)可采摘蔬菜`$()。$($c['zhDesc'])。`$(br2)种子播在`$(l:tfc:food/farmland)农田`$()上，生长后期空手右键采摘可保留植株；左键破坏会拔除植株。`$(br2)"
                } else {
                    "$($c['zh'])是单格作物。$($c['zhDesc'])。`$(br2)$($c['zh'])种子可以种植在`$(l:tfc:food/farmland)农田`$()上，成熟后收割可以得到`$(thing)$($cprod)`$()和`$(thing)$($c['zh'])种子`$()。`$(br2)"
                })
    } else {
        $text = "`$(bold)`$(l:tfc:core_mechanics/climate#temperature)Temperature`$(): $(T $g['minT'])°C - $(T $g['maxT'])°C`$(br)`$(bold)`$(l:tfc:food/hydration)Hydration`$(): $($g['minH']) - $($g['maxH']) %`$(br)`$(bold)Category`$(): $($catEn)`$(br2)" +
                (Fmt-Npk $c['npk'] $lang) + "`$(br2)" +
                $(if ($isRosette) {
                    RosetteHarvestText $c $lang
                } elseif ($isClimb) {
                    "$($c['en']) is a `$(thing)climbing crop`$(): $($c['enDesc']).`$(br2)Sow the seeds on `$(l:tfc:food/farmland)farmland`$() and use a `$(thing)stick`$() on the seedling to let it climb. Once tall and ripe, break the plant to harvest.`$(br2)"
                } elseif ($isSpread) {
                    "$($c['en']) is a `$(thing)spreading crop`$(): $($c['enDesc']).`$(br2)Sow on `$(l:tfc:food/farmland)farmland`$() with space beside the vine for fruit. Break a whole fruit to collect it, then use a knife on the cutting board for four slices with inherited freshness. Breaking the vine returns only seeds. Rotten fruit cannot be processed.`$(br2)"
                } elseif ($isFlooded) {
                    "$($c['en']) is a single block crop: $($c['enDesc']).`$(br2)Prepare `$(l:tfc:food/farmland)farmland`$(), cover it with a one-block-deep fresh water source, then sow on the submerged farmland. Once fully grown, break the crop to harvest food and seeds.`$(br2)"
                } elseif ($isPickable) {
                    "$($c['en']) is a `$(thing)pickable vegetable`$(): $($c['enDesc']).`$(br2)Its seeds are sown on `$(l:tfc:food/farmland)farmland`$(); late in growth, right-click with an empty hand to harvest and regrow; breaking removes it.`$(br2)"
                } else {
                    "$($c['en']) is a single block crop: $($c['enDesc']).`$(br2)$($c['en']) seeds can be planted on `$(l:tfc:food/farmland)farmland`$(), and once ripe the harvest gives `$(thing)$($cprodEn)`$() and `$(thing)$($c['en']) Seeds`$().`$(br2)"
                })
    }
    if ($isClimb -or $script:doubleNames -contains $c['n']) {
        $paragraphs = $text -split '\$\(br2\)'
        $prefix = $paragraphs[0..2] -join '$(br2)'
        if ($lang -eq 'zh_cn') {
            $form = if ($isClimb) { '是攀爬作物。' } else { '是双格作物。' }
            $prefix = $prefix.Replace('是单格作物。', $form)
            $control = if ($isClimb) { '种子播在$(l:tfc:food/farmland)农田$()上，上方留空，用木棍右键下半株搭架才能继续长高。完全成熟后破坏任意半株收获并返种、返棍，各结算一次；空手右键不采摘。' } else { '种子播在$(l:tfc:food/farmland)农田$()上，上方留空供植株长高。完全成熟后破坏任意半株收获并返种，只结算一次。' }
        } else {
            $form = if ($isClimb) { 'is a climbing crop' } else { 'is a two-block crop' }
            $prefix = $prefix.Replace('is a single block crop', $form)
            $control = if ($isClimb) { 'Sow on $(l:tfc:food/farmland)farmland$() with space above. To grow tall, right-click the lower plant with a wooden stick. Once fully grown, break either half to harvest and return seeds and the stick once. Empty-hand right-click does not harvest.' } else { 'Sow on $(l:tfc:food/farmland)farmland$() with space above for the upper plant. Once fully grown, break either half to harvest and return seeds once.' }
        }
        $text = $prefix + '$(br2)' + $control + '$(br2)'
    }
    # Reviewed food-product notes do not alter crop controls.
    if ($c['n'] -in @('rhubarb','sunflower','agave')) {
        $noteField = if ($lang -eq 'zh_cn') { 'zhProductNote' } else { 'enProductNote' }
        $text += $c[$noteField]
    }
    $title = if ($lang -eq 'zh_cn') { $c['zh'] } else { $c['en'] }
    return [ordered]@{ type='patchouli:text'; title=$title; anchor=$c['n']; text=$text }
}
function WildPage($c, [string]$lang) {
    $g = GrowthRange 'crop' $c['n']
    $w = WildRange "data/$NS/worldgen/placed_feature/plant/wild_crop/$($c['n'])_patch.json"
    if ($lang -eq 'zh_cn') {
        # 采集规则、掉落数量、怎么种 —— 这些在条目总结页已经讲过一遍了，
        # 每种作物再重复一遍只会让页面难读，所以这里只留「这一种」特有的信息。
        $text = "可在下列区域找到：`$(br)`$(bold)`$(l:tfc:core_mechanics/climate#temperature)温度`$(): $(T $w['minT'])°C - $(T $w['maxT'])°C`$(br)`$(bold)`$(l:tfc:core_mechanics/climate#rainfall)降水`$(): $($w['minG']) - $($w['maxG'])mm`$(br2)" +
                "采到的种子播在`$(l:tfc:farming_plus/crops)农田`$()上即可栽培；栽培条件为温度 $(T $g['minT'])°C - $(T $g['maxT'])°C、湿度 $($g['minH']) - $($g['maxH']) %。"
    } else {
        # 采集规则、掉落数量、怎么种 —— 这些在条目总结页已经讲过一遍了，
        # 每种作物再重复一遍只会让页面难读，所以这里只留「这一种」特有的信息。
        $text = "Can be found in regions with: `$(br)`$(bold)`$(l:tfc:core_mechanics/climate#temperature)Temperature`$(): $(T $w['minT'])°C - $(T $w['maxT'])°C`$(br)`$(bold)`$(l:tfc:core_mechanics/climate#rainfall)Rainfall`$(): $($w['minG']) - $($w['maxG'])mm`$(br2)" +
                "Seeds collected here can be sown on `$(l:tfc:farming_plus/crops)farmland`$(); as a crop it needs temperature $(T $g['minT'])°C - $(T $g['maxT'])°C and hydration $($g['minH']) - $($g['maxH']) %."
    }
    if ([bool]$c['flooded']) {
        if ($lang -eq 'zh_cn') {
            $text = $text.Replace('采到的种子播在$(l:tfc:farming_plus/crops)农田$()上即可栽培', '生于一格深的淡水水源中，根部需要适合野生作物的土壤；采种后按$(l:tfc:farming_plus/crops)先开垦、灌水、后播种$()的顺序栽培')
        } else {
            $text = $text.Replace('Seeds collected here can be sown on $(l:tfc:farming_plus/crops)farmland$()', 'Found in one-block-deep fresh water over suitable wild-crop soil. Follow the $(l:tfc:farming_plus/crops)prepare farmland, flood, then sow$() order')
        }
    }
    $title = "$(if ($lang -eq 'zh_cn') { '野生' } else { 'Wild ' })$(if ($lang -eq 'zh_cn') { $c['zh'] } else { $c['en'] })"
    return [ordered]@{ type='patchouli:text'; title=$title; anchor=$c['n']; text=$text }
}

# ---------------- 物候数据 + 三种页面构造 ----------------
# 12 个月的状态表，直接对应 MyBushes.java 里的 Lifecycle[] 数组（1 月起）
$lifecycles = [ordered]@{
    lingonberry  = @('DORMANT','DORMANT','DORMANT','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FRUITING','FRUITING','DORMANT','DORMANT','DORMANT')
    bearberry    = @('DORMANT','DORMANT','DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','FRUITING','FRUITING','DORMANT','DORMANT','DORMANT')
    crowberry    = @('DORMANT','DORMANT','DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','FRUITING','DORMANT','DORMANT','DORMANT','DORMANT')
    bilberry     = @('DORMANT','DORMANT','DORMANT','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FRUITING','DORMANT','DORMANT','DORMANT','DORMANT')
    blackcurrant = @('DORMANT','DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','FRUITING','FRUITING','DORMANT','DORMANT','DORMANT','DORMANT')
    redcurrant   = @('DORMANT','DORMANT','DORMANT','DORMANT','HEALTHY','FLOWERING','FRUITING','FRUITING','DORMANT','DORMANT','DORMANT','DORMANT')
    haskap       = @('DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','FRUITING','DORMANT','DORMANT','DORMANT','DORMANT','DORMANT','DORMANT')
    goji         = @('DORMANT','DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','FRUITING','FLOWERING','FRUITING','DORMANT','DORMANT','DORMANT')
    serviceberry = @('DORMANT','DORMANT','DORMANT','HEALTHY','FLOWERING','FRUITING','DORMANT','DORMANT','DORMANT','DORMANT','DORMANT','DORMANT')
    aronia       = @('DORMANT','DORMANT','DORMANT','DORMANT','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FRUITING','FRUITING','DORMANT','DORMANT')
    # 批次 4（与 MyBushes.java 的 TEA / COFFEE 数组逐月一致）
    tea          = @('DORMANT','DORMANT','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','FRUITING','HEALTHY','DORMANT')
    coffee       = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','FRUITING','HEALTHY','HEALTHY','DORMANT','DORMANT')
}
# 14 种温带果树的物候 —— **必须与 MyFruitTrees.java 的 TREES 表逐月一致**
# （那边是运行时真正生效的数据，这里只用于手册的日历表与文字描述）。
$treeLifecycles = [ordered]@{
    pear        = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT','DORMANT','DORMANT')
    apricot     = @('DORMANT','HEALTHY','FLOWERING','HEALTHY','HEALTHY','FRUITING','HEALTHY','DORMANT','DORMANT','DORMANT','DORMANT','DORMANT')
    quince      = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    persimmon   = @('DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    pomegranate = @('DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    loquat      = @('HEALTHY','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING')
    sorb        = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    mulberry    = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY','DORMANT','DORMANT','DORMANT','DORMANT')
    jujube      = @('DORMANT','DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    hawthorn    = @('DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    medlar      = @('DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','DORMANT')
    pawpaw      = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    crabapple   = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    cornelian_cherry = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    # ---------------- 热带果树 14 种（与 MyFruitTrees.java 的同名条目逐月一致） ----------------
    mango       = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','FRUITING','HEALTHY','HEALTHY','HEALTHY')
    papaya      = @('HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY')
    guava       = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','FRUITING','HEALTHY','HEALTHY','FLOWERING','FRUITING','FRUITING')
    lychee      = @('DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT','DORMANT','DORMANT','DORMANT')
    longan      = @('DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT','DORMANT','DORMANT')
    avocado     = @('HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','FRUITING','HEALTHY','HEALTHY','HEALTHY','HEALTHY')
    starfruit   = @('HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY')
    tamarind    = @('DORMANT','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','FRUITING','HEALTHY','DORMANT')
    sapodilla   = @('HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','FRUITING','HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING')
    cherimoya   = @('DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT','DORMANT','DORMANT')
    rambutan    = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FRUITING','FRUITING')
    durian      = @('HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING')
    jackfruit   = @('HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','FRUITING','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY')
    breadfruit  = @('HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','FRUITING','HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING')
    # ---------------- 坚果 5 种（与 MyFruitTrees.java 的同名条目逐月一致） ----------------
    # 坚果同样走果树机制（TFC 没有树干/树冠果实方块），物候集中在夏末到秋季成熟。
    # 榛子是先花后叶（冬末葇荑花序），杏仁是早春最先开花，两者在表里都体现出来了。
    walnut      = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    hazelnut    = @('FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','HEALTHY','DORMANT','DORMANT','DORMANT','DORMANT')
    almond      = @('DORMANT','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT','DORMANT','DORMANT','DORMANT')
    pecan       = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','FRUITING','HEALTHY','DORMANT')
    macadamia   = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING','HEALTHY','HEALTHY','FLOWERING','FLOWERING','FRUITING','FRUITING')
    # 批次 10：老茎结果 6 种 —— ⚠️ 必须与 MyFruitTrees.java 完全一致，**不含 FRUITING**
    #   （它们的果实在树干上，树叶只开花不结果）
    jabuticaba  = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY')
    soursop     = @('HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY')
    mangosteen  = @('HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY')
    cupuacu     = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY')
    bael        = @('DORMANT','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','HEALTHY','FLOWERING','HEALTHY','DORMANT')
    canistel    = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY')
    black_pepper = @('HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','HEALTHY','HEALTHY')
    waxberry      = @('DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT','DORMANT','DORMANT')
    lime          = @('HEALTHY','FLOWERING','FLOWERING','HEALTHY','FRUITING','FRUITING','FRUITING','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY')
    grapefruit    = @('DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    kiwi          = @('DORMANT','DORMANT','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT')
    wax_apple     = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','FRUITING','FRUITING','HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY')
    wampee        = @('HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY','HEALTHY','HEALTHY','HEALTHY')
    amla          = @('HEALTHY','HEALTHY','FLOWERING','FLOWERING','HEALTHY','HEALTHY','HEALTHY','HEALTHY','HEALTHY','FRUITING','FRUITING','HEALTHY')
    sea_buckthorn  = @('DORMANT','DORMANT','DORMANT','HEALTHY','FLOWERING','FLOWERING','HEALTHY','FRUITING','FRUITING','HEALTHY','DORMANT','DORMANT')
}
# 果树表：名称读 gen-fruit-trees.ps1 导出的 manifest，避免两处维护树名。
$treeManifest = Join-Path $PSScriptRoot 'fruit-trees-manifest.json'
if (-not (Test-Path $treeManifest)) { throw "缺少 $treeManifest —— 请先运行 gen-fruit-trees.ps1" }
$trees = @(([System.IO.File]::ReadAllText($treeManifest, [System.Text.Encoding]::UTF8) | ConvertFrom-Json).trees |
    Where-Object { $_.name -ne $cocoaPolicy.legacy_tree })
$script:nTree = $trees.Count
# 树苗长成枝干的天数 —— 与 MyFruitTrees.java 的 DAYS_TO_GROW 一致
$script:treeGrowDays = 8
# TFC 日历表用的四种状态配色（照抄 the_world/wild_fruits.json 的 legend）
$lifecycleColor = [ordered]@{ DORMANT='0xa8986a'; HEALTHY='0x6ab553'; FLOWERING='0xcca0db'; FRUITING='0xa217ff' }

# 多块展示页 —— 结构照 TFC：
#   矮丛灌木 the_world/wild_fruits.json：pattern [[X],[0]]，四种 lifecycle 各一帧
#   蔓生灌木（本模组的新形态）：上格再叠一格配套藤蔓，pattern [[X],[Y],[0]]
#   作物     food/crops.json          ：pattern [[X],[Y],[0]]，X=作物各 age，Y=农田
# 0 是多块原点标记，不参与映射。
function BushMultiBlock($b, [string]$lang) {
    $blocks = @()
    $high = [bool]$b['high']
    foreach ($lc in @('dormant','healthy','flowering','fruiting')) {
        if ($high) {
            # 照 TFC wild_fruits.json 的黑莓页（pattern 的第一个元素是**最上面一层**）：
            #     [X ]   ← 最上层只有 stage 0 的小丛
            #     [YZ]   ← stage 1 的主丛，右边紧挨着藤蔓
            #     [AZ]   ← stage 2 的成熟主丛，右边同样挨着藤蔓
            #     [0 ]   ← 原点标记（不参与映射）
            # 关键点：藤蔓是**和主丛水平并排**的，不是单独占一层 ——
            # 藤蔓的模型是侧向的（*_bush_side_*），单独放一层会与主丛叠在一起糊成一团。
            $blocks += [ordered]@{
                pattern = @(, @('X',' ')) + @(, @('Y','Z')) + @(, @('A','Z')) + @(, @('0',' '))
                mapping = [ordered]@{
                    X = "$NS`:plant/$($b['n'])_bush[lifecycle=$lc,stage=0]"
                    Y = "$NS`:plant/$($b['n'])_bush[lifecycle=$lc,stage=1]"
                    A = "$NS`:plant/$($b['n'])_bush[lifecycle=$lc,stage=2]"
                    Z = "$NS`:plant/$($b['n'])_bush_cane[lifecycle=$lc,facing=east,stage=1]"
                }
            }
        } else {
            $blocks += [ordered]@{
                pattern = @(, @('X')) + @(, @('0'))
                mapping = [ordered]@{ X = "$NS`:plant/$($b['n'])_bush[lifecycle=$lc,stage=2]" }
            }
        }
    }
    $text = if ($lang -eq 'zh_cn') { "一丛典型的$($b['zh'])灌木。" }
            else                   { "A typical $($b['en']) bush." }
    return [ordered]@{ type='tfc:multimultiblock'; text=$text; multiblocks=$blocks }
}
# 作物形态：**从实际生成的 blockstate 反推**，而不是在手册表里再抄一份 age/double。
#   单格阶段 → 变体键 "age=N"
#   双格阶段 → 变体键 "age=N,part=bottom"
# 抄副本迟早会与 gen-crops.ps1 失同步（本函数的前身就把阶段数写死成 6，8 阶段谷物少显示两段）。
function CropShape([string]$n) {
    $j = Get-JsonV "assets/$NS/blockstates/crop/$n.json"
    $maxAge = 0; $dblFrom = -1
    # 蔓延型作物用 multipart（age + 四方向），没有 variants —— 从 multipart 里取 age。
    if ($null -ne $j.multipart) {
        foreach ($part in @($j.multipart)) {
            $a = $part['when']['age']
            if ($null -ne $a) { $a = [int]$a; if ($a -gt $maxAge) { $maxAge = $a } }
        }
        return [ordered]@{ maxAge = $maxAge; dbl = $false; singleAge = -1 }
    }
    foreach ($k in $j.variants.Keys) {
        if ($k -match '^age=(\d+)(?:,fruiting=(?:false|true))?$') {
            $a = [int]$Matches[1]; if ($a -gt $maxAge) { $maxAge = $a }
        } elseif ($k -match '^age=(\d+),part=bottom$') {
            $a = [int]$Matches[1]
            if ($a -gt $maxAge) { $maxAge = $a }
            if ($dblFrom -lt 0 -or $a -lt $dblFrom) { $dblFrom = $a }
        }
    }
    return [ordered]@{ maxAge = $maxAge; dbl = ($dblFrom -ge 0); singleAge = $dblFrom }
}
function CropMultiBlock($c, [string]$lang) {
    $blocks = @()
    # ⚠️ 阶段数必须**从表里读**：蔬菜类 age=5（6 阶段），谷物类 age=7（8 阶段）。
    #    早期写死 `-le 5`，8 阶段谷物的最后两阶段在手册里根本看不到。
    $shape  = CropShape $c['n']
    $maxAge = [int]$shape['maxAge']
    $rosette = $script:rosetteNames -contains $c['n']
    $flooded = [bool]$c['flooded']
    $dbl    = [bool]$shape['dbl']
    $single = if ($dbl) { [int]$shape['singleAge'] } else { $maxAge + 1 }
    for ($i = 0; $i -le $maxAge; $i++) {
        if ($flooded) {
            # 水田作物：水是**作物方块自己的状态属性**，与农田同格 —— 不是上面另放一个水方块。
            # 原样照 TFC 的水稻页写法：X = "tfc:crop/rice[age=0,fluid=water]"，
            # 农田也用冲积土 tfc:farmland/fluvisol（水稻田的标准基质）。
            $blocks += [ordered]@{
                pattern = @(, @('X')) + @(, @('Y')) + @(, @('0'))
                mapping = [ordered]@{
                    X = "$NS`:crop/$($c['n'])[age=$i,fluid=water]"
                    Y = 'tfc:farmland/fluvisol'
                }
            }
        } elseif ($dbl -and $i -ge $single) {
            # 双格阶段：上格 + 下格 + 农田。
            # pattern 的第一个元素是**最上面**一层，所以 top 在前、bottom 在后。
            $blocks += [ordered]@{
                pattern = @(, @('X')) + @(, @('Z')) + @(, @('Y')) + @(, @('0'))
                mapping = [ordered]@{
                    X = "$NS`:crop/$($c['n'])[age=$i,part=top]"
                    Z = "$NS`:crop/$($c['n'])[age=$i,part=bottom]"
                    Y = 'tfc:farmland/entisol'
                }
            }
        } else {
            $cropState = if ($rosette) { "${NS}:crop/$($c['n'])[age=$i,fruiting=false]" } else { "${NS}:crop/$($c['n'])[age=$i]" }
            $blocks += [ordered]@{
                pattern = @(, @('X')) + @(, @('Y')) + @(, @('0'))
                mapping = [ordered]@{ X = $cropState; Y = 'tfc:farmland/entisol' }
            }
        }
    }
    if ($rosette) {
        $blocks += [ordered]@{ pattern = @(, @('X')) + @(, @('Y')) + @(, @('0')); mapping = [ordered]@{ X="${NS}:crop/$($c['n'])[age=5,fruiting=true]"; Y='tfc:farmland/entisol' } }
    }
    $stages = $maxAge + 1
    if ($lang -eq 'zh_cn') {
        $text = "$($c['zh'])在农田上的 $stages 个生长阶段。" +
                $(if ($flooded) { "注意：为了生长，作物方块必须`$(thing)含水`$()。" } else { "" }) +
                $(if ($dbl) { "后几个阶段会向上长高，占上下两格。" } else { "" })
    } else {
        $text = "The $stages growth stages of $($c['en']) on farmland." +
                $(if ($flooded) { " Note: in order to grow, the crop block must be `$(thing)waterlogged`$()." } else { "" }) +
                $(if ($dbl) { " The later stages grow a second block tall." } else { "" })
    }
    if ($rosette) {
        $text = if ($lang -eq 'zh_cn') { "$($c['zh'])的六个叶片生长阶段与完全成熟后的中心结果态；最后一帧才可收获产物。" } else { "The six leaf stages of $($c['en']) and its fully mature fruiting centre; only the final frame yields the harvest." }
    }
    return [ordered]@{ type='tfc:multimultiblock'; text=$text; multiblocks=$blocks }
}
# 物候日历表 —— 结构照 TFC 的 tfc:table（strings 为扁平数组：表头 13 项 + 每行「名字 + 12 格」）
# 物候日历表 —— 结构照 TFC 的 tfc:table（strings 为扁平数组：表头 13 项 + 每行「名字 + 12 格」）
# ⚠️ 照 TFC 的 the_world/wild_fruits.json：矮丛与蔓生**各有一张表**
#    （TFC 那边叫「小型浆果灌木」与「大型浆果灌木」）。
#    一张表塞 10 行会把图例和下方说明挤出页面 —— TFC 的表最多 7 行。
function Select-Bushes([string]$kind) {
    if ($kind -eq 'high') { return @($bushes | Where-Object { $_['high'] }) }
    return @($bushes | Where-Object { -not $_['high'] })
}
function BushCalendar([string]$lang, [string]$kind) {
    $zh   = $lang -eq 'zh_cn'
    $high = $kind -eq 'high'
    $strings = @()
    # 表头左上角那一格：TFC 用的是空文本 {"text":""}。
    # ⚠️ 不能写成 {fill:0x000000} —— PowerShell 会把 0x000000 当成十六进制**数字** 0，
    #    序列化后变成 {"fill":0}，游戏里渲染成一个纯黑方块。
    #    （数据行的 fill 是字符串 '0xa8986a' 这种，带引号，所以没问题。）
    $strings += [ordered]@{ text = '' }
    $months = if ($zh) { @('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec') }
              else     { @('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec') }
    foreach ($m in $months) { $strings += [ordered]@{ text = $m } }
    foreach ($b in (Select-Bushes $kind)) {
        $strings += [ordered]@{ text = $(if ($zh) { $b['zh'] } else { $b['en'] }) }
        foreach ($lc in $lifecycles[$b['n']]) { $strings += [ordered]@{ fill = $lifecycleColor[$lc] } }
    }
    $title   = if ($high) { if ($zh) { '蔓生灌木物候日历' } else { 'Spreading Bush Calendar' } }
               else        { if ($zh) { '矮丛灌木物候日历' } else { 'Small Bush Calendar' } }
    $caption = if ($high) { if ($zh) { "$($script:nHighBush) 种蔓生灌木在一年中的状态变化。" } else { "The fruiting calendar of the $($script:nHighBush) spreading bushes." } }
               else        { if ($zh) { "$($script:nSmallBush) 种矮丛灌木在一年中的状态变化。" } else { "The fruiting calendar of the $($script:nSmallBush) small bushes." } }
    return [ordered]@{
        type            = 'tfc:table'
        strings         = $strings
        title           = $title
        text            = $caption
        legend          = @(
            [ordered]@{ text = $(if ($zh) { '休眠' } else { 'Dormant' });   color = '0xa8986a' }
            [ordered]@{ text = $(if ($zh) { '健康' } else { 'Healthy' });   color = '0x6ab553' }
            [ordered]@{ text = $(if ($zh) { '开花' } else { 'Flowering' }); color = '0xcca0db' }
            [ordered]@{ text = $(if ($zh) { '结果' } else { 'Fruiting' });  color = '0xa217ff' }
        )
        columns         = 12
        first_column_width = 45
        column_width    = 15
        row_height      = 10
        left_buffer     = 8
        top_buffer      = 14
        draw_background = $true
    }
}
# 从 12 个月的物候数组推出「几月生长、几月开花、几月结果」——
# 照 TFC 手册的写法（如「樱桃树在一月至三月生长，四月至五月开花，六月结果」）。
# 12 个月是按状态分组的，取每组的首尾月份即可（跨越 12→1 的连续段按两段处理，与 TFC 一致）。
function LifecycleText($lc, [string]$lang, [string]$name) {
    $zh = $lang -eq 'zh_cn'
    $mon = if ($zh) { @('一月','二月','三月','四月','五月','六月','七月','八月','九月','十月','十一月','十二月') }
           else     { @('January','February','March','April','May','June','July','August','September','October','November','December') }
    $parts = @()
    foreach ($st in @('HEALTHY','FLOWERING','FRUITING')) {
        $idx = @()
        for ($i = 0; $i -lt 12; $i++) { if ($lc[$i] -eq $st) { $idx += $i } }
        if ($idx.Count -eq 0) { continue }
        $range = if ($idx.Count -eq 1) { $mon[$idx[0]] }
                 else { $mon[$idx[0]] + $(if ($zh) { '至' } else { ' to ' }) + $mon[$idx[-1]] }
        if ($zh) {
            $verb = if ($st -eq 'HEALTHY') { '生长' } elseif ($st -eq 'FLOWERING') { '开花' } else { '结果' }
            $parts += "$range$verb"
        } else {
            $verb = if ($st -eq 'HEALTHY') { 'grows' } elseif ($st -eq 'FLOWERING') { 'flowers' } else { 'bears fruit' }
            $parts += "$verb in $range"
        }
    }
    if ($parts.Count -eq 0) { return '' }
    if ($zh) { return "$name 在" + ($parts -join '，') + '。' }
    $j = ($parts -join ', ')
    return "$name " + $j.Substring(0, 1).ToUpper() + $j.Substring(1) + '.'
}
# Reviewed leaf-fruit/nut groups; trunk calendars are handled separately below.
$script:temperateTreeNames = @('pear','apricot','quince','persimmon','pomegranate','loquat','sorb','mulberry','jujube','hawthorn','medlar','pawpaw','crabapple','cornelian_cherry')
$script:tropicalTreeNames = @('mango','papaya','guava','lychee','longan','avocado','starfruit','tamarind','sapodilla','cherimoya','rambutan','durian','jackfruit','breadfruit')
$script:nutTreeNames = @('walnut','hazelnut','almond','pecan','macadamia')
$script:remainingTreeNames = @('waxberry','lime','grapefruit','kiwi','wax_apple','wampee','amla','sea_buckthorn')
$script:reviewedTreeNames = @($script:temperateTreeNames) + @($script:tropicalTreeNames) + @($script:nutTreeNames) + @($script:remainingTreeNames)
function ReviewedTreeGuidance($lc, [string]$lang) {
    $flower = @(); $fruit = @()
    for ($i=0; $i -lt 12; $i++) {
        if ($lc[$i] -eq 'FLOWERING') { $flower += [string]($i+1) }
        if ($lc[$i] -eq 'FRUITING') { $fruit += [string]($i+1) }
    }
    if ($lang -eq 'zh_cn') { return '树苗等待时长以物品提示为准，受配置调整；须在活动月份满足温湿度才会转枝，枝叶还需继续生长。结果期右键树叶采果，采后遵守TFC开花冷却。$(br2)北半球开花月：' + ($flower -join '、') + '；结果月：' + ($fruit -join '、') + '。南半球由TFC换季。' }
    return 'Check the sapling tooltip for its configured wait. Conversion to a branch also needs an active month and suitable climate; branch growth takes additional time. Right-click fruiting leaves to pick; TFC bloom cooldown still applies.$(br2)Northern flowering months: ' + ($flower -join ', ') + '; fruiting months: ' + ($fruit -join ', ') + '. TFC shifts seasons in the south.'
}
function BranchTreeGuidance([string]$name, [string]$lang) {
    $source = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../src/main/java/com/example/tfcfarmingplus/common/MyBranchFruits.java') -Raw -Encoding UTF8
    $match = [regex]::Match($source, ('(?s)"'+[regex]::Escape($name)+'", new Lifecycle\[\]\{([^}]+)\}'))
    $months = @([regex]::Matches($match.Groups[1].Value, 'Lifecycle\.([A-Z]+)') | ForEach-Object {$_.Groups[1].Value})
    if ($months.Count -ne 12) {throw "Missing branch calendar: $name"}
    $flower=@();$fruit=@();foreach ($i in 0..11) {if ($months[$i] -eq 'FLOWERING') {$flower += [string]($i+1)};if ($months[$i] -eq 'FRUITING') {$fruit += [string]($i+1)}}
    if ($lang -eq 'zh_cn') {return '树苗等待以物品提示为准，转枝须在活动月份满足气候。果实只长在上下相连且六邻无果树叶的成熟枝干。$(br2)根部温湿度合适且在结果期时，按浆果生长配置推进两阶段；余量保留。成熟后右键采收，采后重新计时；破坏成熟枝也掉一份产物。$(br2)北半球枝干开花月：'+($flower -join '、')+'；结果月：'+($fruit -join '、')+'。南半球由TFC换季。'}
    return 'Check the sapling tooltip; an active month and suitable climate are also required. Fruit grows on mature branches connected up/down with no adjacent fruit-tree leaves.$(br2)Root climate and fruiting months gate two stages using the berry growth setting; fractional time is retained. Right-click ripe fruit; harvest restarts the timer. Breaking a ripe branch also drops one product.$(br2)Northern trunk flowering months: '+($flower -join ', ')+'; fruiting months: '+($fruit -join ', ')+'. TFC shifts seasons in the south.'
}
function TreePage($t, [string]$lang) {
    $lc = $treeLifecycles[$t.name]
    if ($lang -eq 'zh_cn') {
        $life = LifecycleText $lc $lang "$($t.zh)树"
        $text = "生长所需条件：`$(br)`$(bold)`$(l:tfc:core_mechanics/climate#temperature)温度`$(): $(T $t.minT)°C - $(T $t.maxT)°C`$(br2)" +
                "把树苗种在合适的土壤上，$($script:treeGrowDays) 天后长成`$(thing)枝干`$()，随后在枝干周围长出树叶。" +
                "果实挂在`$(bold)结果期`$()的树叶上，直接采摘即可。`$(br2)" + $life
    } else {
        $life = LifecycleText $lc $lang "$($t.en) trees"
        $text = "Conditions required for growth: `$(br)`$(bold)`$(l:tfc:core_mechanics/climate#temperature)Temperature`$(): $(T $t.minT)°C - $(T $t.maxT)°C`$(br2)" +
                "Plant the sapling on suitable soil; after $($script:treeGrowDays) days it grows into a " +
                "`$(thing)branch`$(), and leaves then grow around the branches. " +
                "Fruit hangs on the leaves during the `$(bold)fruiting`$() season and is picked directly.`$(br2)" + $life
    }
    if ($t.name -in $script:reviewedTreeNames) { $text = ($text -split [regex]::Escape('$(br2)'), 2)[0] + '$(br2)' + (ReviewedTreeGuidance $lc $lang) }
    if ($t.name -in $script:nutTreeNames) { $text += '$(br2)' + $(if ($lang -eq 'zh_cn') { '坚果提供蛋白质，可直接食用，也可作汤、沙拉和三明治配料。加工须用未腐烂原料，遵守原版工具和容器规则。' } else { 'These protein foods can be eaten or used in soup, salad and sandwiches. Use fresh ingredients and native tools/containers.' }) }
    if ($t.name -in @('jabuticaba','soursop','mangosteen','bael','canistel','black_pepper')) { $text = ($text -split [regex]::Escape('$(br2)'),2)[0] + '$(br2)' + (BranchTreeGuidance $t.name $lang) }
    if ($t.name -eq 'black_pepper') { $text += '$(br2)' + $(if ($lang -eq 'zh_cn') { '未腐烂胡椒放入石臼，手持石杵右键三次得到一份胡椒粉，消耗三点耐久并继承食品新鲜度。胡椒粉与未调味的未腐烂汤放入合成格即可调味；也可放入煎锅调味槽，按现有配方烹饪。' } else { 'Put fresh pepper in a mortar; right-click with a pestle three times for one powder, costing three durability and retaining food freshness. Combine fresh powder and fresh unseasoned soup in a crafting grid to season it, or use the pan spice slot with its existing recipe.' }) }
    $title = if ($lang -eq 'zh_cn') { "$($t.zh)树" } else { "$($t.en) Tree" }
    if ($t.name -eq $cocoaPolicy.tree) { $text = $cocoaPolicy.guide_text.$lang }
    return [ordered]@{ type='patchouli:text'; title=$title; anchor=$t.name; text=$text }
}
# 果树的多块展示 —— 结构**逐格照抄** TFC wild_fruits.json 的樱桃树页：
# 6 个元素，**第一个元素是最上面一层**，每层 5 行 × 5 字符；
# "0"/"1" 是竖直枝干，"2" 是向西的分枝，"3" 是向东的分枝带 up，L 是树叶。
# TFC 的果树条目**没有**日历表（14 种树放一张表会撑出页面），所以这里也不做。
function TreeMultiBlock($t, [string]$lang) {
    $blocks = @()
    foreach ($lc in @('dormant','healthy','flowering','fruiting')) {
        $blocks += [ordered]@{
            pattern = @(, @('     ','  L  ','     ','     ','     ')) +
                      @(, @('  L  ',' L1L ','  L  ','     ','     ')) +
                      @(, @('  L  ',' L1L ','  L  ','     ','     ')) +
                      @(, @('  L  ',' L3L ',' L2L ','  L  ','     ')) +
                      @(, @('     ','     ','  0  ','     ','     ')) +
                      @(, @('     ','     ','  1  ','     ','     '))
            mapping = [ordered]@{
                '0' = "$NS`:plant/$($t.name)_branch[down=true,up=true]"
                '1' = "$NS`:plant/$($t.name)_branch[down=true,up=true]"
                '2' = "$NS`:plant/$($t.name)_branch[down=true,west=true]"
                '3' = "$NS`:plant/$($t.name)_branch[east=true,up=true]"
                'L' = "$NS`:plant/$($t.name)_leaves[lifecycle=$lc]"
            }
        }
    }
    $text = if ($lang -eq 'zh_cn') { "一棵典型的$($t.zh)树。" } else { "A typical $($t.en) tree." }
    $page = [ordered]@{ type='tfc:multimultiblock'; text=$text; multiblocks=$blocks }
    if ($t.name -eq $cocoaPolicy.tree) {
        $page.text = $cocoaPolicy.diagram_text.$lang
        Set-CupuacuDiagram $page
    }
    return $page
}
# ---------------- 生成条目 ----------------
foreach ($lang in @('en_us','zh_cn')) {
    $zh = $lang -eq 'zh_cn'
    $base = "assets/tfc/patchouli_books/field_guide/$lang/entries/farming_plus"

    # ① 简介
    if ($zh) {
        $pages = @(
            [ordered]@{ type='patchouli:text'; title='TFC农业+'; text=(
                "本选项卡收录 `$(thing)TFC农业+`$() 为 TerraFirmaCraft 增加的植物：`$(br2)" +
                "`$(li)$($bushes.Count) 种多年生 `$(l:tfc:farming_plus/bushes)灌木`$() —— 浆果灌木、茶树与咖啡树" +
                "`$(li)$($crops.Count) 种可耕种的 `$(l:tfc:farming_plus/crops)作物`$()" +
                "`$(li)$($crops.Count) 种提供种子的 `$(l:tfc:farming_plus/wild_crops)野生作物`$()" +
                "`$(li)$($script:nTree) 种 `$(l:tfc:farming_plus/fruit_trees)果树`$() —— 树苗长成枝干，按物种从结果期树叶或成熟枝干采收"
) }
        )
    } else {
        $pages = @(
            [ordered]@{ type='patchouli:text'; title='TFC Farming Plus'; text=(
                "This tab collects the plants that `$(thing)TFC Farming Plus`$() adds to TerraFirmaCraft:`$(br2)" +
                "`$(li)$($bushes.Count) perennial `$(l:tfc:farming_plus/bushes)bushes`$() — berry bushes, tea and coffee" +
                "`$(li)$($crops.Count) farmable `$(l:tfc:farming_plus/crops)crops`$()" +
                "`$(li)$($crops.Count) matching `$(l:tfc:farming_plus/wild_crops)wild plants`$() that provide the seeds" +
                "`$(li)$($script:nTree) `$(l:tfc:farming_plus/fruit_trees)fruit trees`$() — the sapling grows into branches, and harvest fruiting leaves or ripe branches, depending on the species"
) }
        )
    }
    $pages += (SoilGuidePages $lang)
    $pages += (MaterialGuidePage $lang)
    $pages += (FoodProcessingGuidePages $lang)
    $pages += (VegetableBeverageGuidePages $lang)
    Save-Json "$base/intro.json" ([ordered]@{ name=$(if($zh){'关于 TFC农业+'}else{'About TFC Farming Plus'}); category='tfc:farming_plus'; icon="$NS`:seeds/spinach"; pages=$pages })

    # ② 矮丛浆果灌木（照 TFC the_world/wild_fruits 的「小型浆果灌木」一节）
    $pages = @()
    if ($zh) {
        $pages += [ordered]@{ type='patchouli:text'; text=("本模组新增 $($script:nSmallBush) 种矮丛浆果灌木，最高只有一格。") }
    } else {
        $pages += [ordered]@{ type='patchouli:text'; text=("This mod adds $($script:nSmallBush) small berry bushes, never taller than one block.") }
    }
    # ⚠️ tfc:table 是**双页类型**，会横跨整个跨页显示。要让它正确铺开，必须：
    #    ① 落在**偶数索引**（跨页的左半），② 紧跟一个空页占住右半。
    #    对照 TFC 的 the_world/wild_fruits.json：[26]table 左 + [27]empty 右 + [28]下一节。
    #    少了这两个空页，表格会落在右半页而被裁掉。
    $pages += [ordered]@{ type='patchouli:empty' }
    $pages[0].text += (BushIntroGuidance $false $lang)
    $pages += (BushCalendar $lang 'small')
    $pages += [ordered]@{ type='patchouli:empty' }
    foreach ($b in (Select-Bushes 'small')) { $pages += (BushPage $b $lang); $pages += (BushMultiBlock $b $lang) }
    Save-Json "$base/bushes.json" ([ordered]@{ name=$(if($zh){'矮丛灌木'}else{'Small Bushes'}); category='tfc:farming_plus'; icon="$NS`:food/lingonberry"; pages=$pages })

    # ②b 蔓生浆果灌木（照 TFC 的「大型浆果灌木」一节）——
    #     与矮丛分开成两个条目，是因为两者外形与采摘方式都不同，
    #     而且一张日历表放 10 行会把图例和说明挤出页面（TFC 的表最多 7 行）。
    $pages = @()
    if ($zh) {
        $pages += [ordered]@{ type='patchouli:text'; text=("本模组新增 $($script:nHighBush) 种蔓生灌木：浆果灌木，以及茶树与咖啡树。长成后会向四周与上方伸出枝叶。") }
    } else {
        $pages += [ordered]@{ type='patchouli:text'; text=("This mod adds $($script:nHighBush) spreading bushes: berry bushes, plus tea and coffee. They put out side branches and shoots once grown.") }
    }
    # ⚠️ tfc:table 是**双页类型**，会横跨整个跨页显示。要让它正确铺开，必须：
    #    ① 落在**偶数索引**（跨页的左半），② 紧跟一个空页占住右半。
    #    对照 TFC 的 the_world/wild_fruits.json：[26]table 左 + [27]empty 右 + [28]下一节。
    #    少了这两个空页，表格会落在右半页而被裁掉。
    $pages += [ordered]@{ type='patchouli:empty' }
    $pages[0].text += (BushIntroGuidance $true $lang)
    $pages += (BushCalendar $lang 'high')
    $pages += [ordered]@{ type='patchouli:empty' }
    foreach ($b in (Select-Bushes 'high')) { $pages += (BushPage $b $lang); $pages += (BushMultiBlock $b $lang) }
    Save-Json "$base/bushes_high.json" ([ordered]@{ name=$(if($zh){'蔓生灌木'}else{'Spreading Bushes'}); category='tfc:farming_plus'; icon="$NS`:food/goji"; pages=$pages })

    # ②c 温带果树（照 TFC the_world/wild_fruits 的「果树」一节）——
    #     TFC 的果树条目结构是：总述页 → 每棵树「文字页 + multimultiblock」。
    #     这里同样**不做日历表**：TFC 也没做，14 种树挤一张表会把图例挤出页面。
    $pages = @()
    if ($zh) {
        $pages += [ordered]@{ type='patchouli:text'; anchor='fruit_trees'; title='果树';
            text="`$(thing)果树`$()会从一棵小树苗长成高大的果树。果树的`$(thing)枝干`$()是它们最重要的部分，只要气候合适就会持续生长，并在枝干周围长出`$(thing)树叶`$()。树叶会在合适的季节开花结果。`$(br2)本模组新增 $($script:nTree) 种温带果树，果实挂在`$(bold)结果期`$()的树叶上，直接采摘即可获得。" }
    } else {
        $pages += [ordered]@{ type='patchouli:text'; anchor='fruit_trees'; title='Fruit Trees';
            text="`$(thing)Fruit trees`$() grow from a sapling into a tall tree. The `$(thing)branches`$() are their most important part: they keep growing as long as the climate suits them, putting out `$(thing)leaves`$() around themselves. The leaves flower and fruit in the right season.`$(br2)This mod adds $($script:nTree) temperate fruit trees; fruit hangs on the leaves during the `$(bold)fruiting`$() season and is picked directly." }
    }
    # ⚠️ 跨页对齐（第二次踩同一个坑）：
    #    tfc:multimultiblock 必须和它的**文字页**落在同一个跨页里，且顺序是「左文字、右多块」——
    #    也就是文字页落在**偶数**索引、多块落在**奇数**索引。
    #    对照 TFC 的 the_world/wild_fruits.json：[8]patchouli:text(cherry) + [9]tfc:multimultiblock(cherry)。
    #    最初总述页只占 1 页，于是每棵树变成「奇=文字、偶=多块」，
    #    多块被推到下一个跨页的左半，和**下一棵树**的文字页拼在一起 ——
    #    表现为「标题写枇杷树、图注却写一棵典型的石榴树」。
    #    补一个空页把后续索引整体 +1 即可对齐（这与灌木日历表那两个空页是同一类修正）。
    $pages += [ordered]@{ type='patchouli:empty' }
    foreach ($t in $trees) { $pages += (TreePage $t $lang); $pages += (TreeMultiBlock $t $lang) }
    Save-Json "$base/fruit_trees.json" ([ordered]@{ name=$(if($zh){'果树'}else{'Fruit Trees'}); category='tfc:farming_plus'; icon="$NS`:plant/pear_sapling"; pages=$pages })

    # ③ 叶菜作物（照 food/crops）
    $pages = @()
    if ($zh) {
        $pages += [ordered]@{ type='patchouli:text'; text=("本模组新增 $($crops.Count) 种作物：蔬菜类 $($script:nVeg) 种（其中 $($script:nPick) 种可反复采摘）、蔓延性蔬菜 $($script:nSpread) 种、谷类 $($script:nGrain) 种、豆类 $($script:nLegume) 种、油料与纤维 $($script:nOther) 种。") }
    } else {
        $pages += [ordered]@{ type='patchouli:text'; text=("This mod adds $($crops.Count) crops: $($script:nVeg) vegetables ($($script:nPick) of them pickable), $($script:nSpread) spreading vegetables, $($script:nGrain) cereals, $($script:nLegume) legumes, and $($script:nOther) oil or fibre crops.") }
    }
    $pages += [ordered]@{ type='patchouli:empty' }
    foreach ($c in $crops) { $pages += (CropPage $c $lang); $pages += (CropMultiBlock $c $lang) }
    Save-Json "$base/crops.json" ([ordered]@{ name=$(if($zh){'作物'}else{'Crops'}); category='tfc:farming_plus'; icon="$NS`:food/kale"; pages=$pages })

    # ④ 野生作物
    $pages = @()
    if ($zh) {
        $pages += [ordered]@{ type='patchouli:text'; text=("本模组新增 $($crops.Count) 种野生作物。") }
    } else {
        $pages += [ordered]@{ type='patchouli:text'; text=("This mod adds $($crops.Count) wild crops.") }
    }
    foreach ($c in $crops) { $pages += (WildPage $c $lang) }
    Save-Json "$base/wild_crops.json" ([ordered]@{ name=$(if($zh){'野生作物'}else{'Wild Crops'}); category='tfc:farming_plus'; icon="$NS`:wild_crop/spinach"; pages=$pages })
}

# 条目数由**实际写入的文件数**反推（每个条目每种语言 1 个文件，共 2 种语言）。
# ⚠️ 以前这里硬编码 "4 个条目"、名单也只列 4 个，而实际早就是 6 个
#    （intro / bushes / bushes_high / fruit_trees / crops / wild_crops）——
#    日志因此长期误导读者。改成反推后，以后再加条目不会再失同步。
$entryCount = [int]($script:count / 2)
if ($script:count % 2 -ne 0) {
    Write-Host "  ⚠ 文件数 $($script:count) 不是偶数，条目数反推可能不准（预期 = 条目数 × 2 语言）"
}
Write-Host "已生成手册内容: $entryCount 个条目 × 2 语言，写入 $script:count 个文件"
Write-Host "  选项卡: tfc:farming_plus"
Write-Host "  条目: intro / bushes($($bushes.Count) 株) / bushes_high / fruit_trees($($trees.Count) 种) / crops($($crops.Count) 株) / wild_crops($($crops.Count) 株)"
# ---------------- 自检：Patchouli 的闭合格式标记 ----------------
# Patchouli 的格式闭合必须写成「反引号 + 美元符 + 括号」。若漏掉美元符，
# PowerShell 会吃掉反引号（反引号加左括号不是转义序列），闭合标记退化成裸括号，
# 游戏里会渲染成数字 0。这类错误 JSON 合法、资源能加载，静态校验完全查不出来。
#
# 注意：本段代码**不能**出现那个错误写法本身（否则自检会把自己报出来），
# 所以检测串用 [char]0x60 拼出来。
$selfText = [System.IO.File]::ReadAllText($PSCommandPath)
$needle   = [string]([char]0x60) + '()'
$badClose = ([regex]::Matches($selfText, [regex]::Escape($needle))).Count
if ($badClose -gt 0) {
    Write-Host "  [自检失败] 脚本里还有 $badClose 处缺美元符的闭合写法，生成的正文会显示成数字 0"
    exit 1
} else {
    Write-Host "  [自检通过] Patchouli 闭合格式标记写法正确"
}
