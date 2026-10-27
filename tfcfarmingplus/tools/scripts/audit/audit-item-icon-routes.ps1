param([string]$SourceInstance='', [string]$ReportDirectory='')
# Review routing and preservation only; visual and runtime acceptance remain separate.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$live=Split-Path (Split-Path (Split-Path $env:TFC_TOOLS_ROOT -Parent) -Parent) -Parent
$instance=if($SourceInstance){(Resolve-Path -LiteralPath $SourceInstance).Path}else{$live}
$resources=Join-Path $instance 'mod_rebuild/tfcfarmingplus/src/main/resources'
$other=Join-Path $instance 'mod_rebuild/tfcagricultureplus/src/main/resources'
$contract=Get-Content -LiteralPath (Join-Path $env:TFC_TOOLS_ROOT 'contracts/reviewed-item-icon-routes.json') -Raw -Encoding UTF8|ConvertFrom-Json
$errors=New-Object 'System.Collections.Generic.List[string]'
$rows=New-Object 'System.Collections.Generic.List[object]'
function Check([bool]$ok,[string]$message){if(-not $ok){$errors.Add($message)}}
function Check-IconSize([string]$path,[string]$label){
    $bytes=[IO.File]::ReadAllBytes($path)
    if($bytes.Length -lt 24){$errors.Add("Invalid item PNG header: $label");return}
    $signature=[BitConverter]::ToString($bytes,0,8)
    $chunk=[Text.Encoding]::ASCII.GetString($bytes,12,4)
    if($signature -cne '89-50-4E-47-0D-0A-1A-0A' -or $chunk -cne 'IHDR'){$errors.Add("Invalid item PNG header: $label");return}
    $width=([long]$bytes[16]*16777216)+([long]$bytes[17]*65536)+([long]$bytes[18]*256)+$bytes[19]
    $height=([long]$bytes[20]*16777216)+([long]$bytes[21]*65536)+([long]$bytes[22]*256)+$bytes[23]
    Check ($width -eq 16 -and $height -eq 16) "Item texture must be 16x16, found ${width}x${height}: $label"
}
foreach($route in $contract.Routes){
    $path=Join-Path $resources $route.Path
    Check (-not(Test-Path -LiteralPath (Join-Path $other $route.Path))) "B shadows reviewed icon: $($route.Path)"
    if(-not(Test-Path -LiteralPath $path)){$errors.Add("Missing icon: $($route.Path)");continue}
    try {
        $j=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json
        Check ($j.parent -in @('item/generated','minecraft:item/generated')) "Unexpected icon parent: $($route.Path)"
        Check (($j.PSObject.Properties.Name|Sort-Object) -join '|' -ceq 'parent|textures') "Unreviewed model fields/geometry: $($route.Path)"
        Check (@($j.textures.PSObject.Properties).Count -eq 1) "Unexpected icon layers: $($route.Path)"
        Check ($j.textures.layer0 -ceq $route.Texture) "Wrong icon texture: $($route.Path)"
        $rows.Add([pscustomobject]@{Name=$route.Name;Family=$route.Family;Model=$route.Path;Texture=$j.textures.layer0;VisualAccepted=$false;RuntimeVerified=$false})
    } catch {$errors.Add("Invalid icon JSON: $($route.Path): $_")}
}
foreach($table in @($contract.ProtectedTextureSha256,$contract.FoodDataSha256)){
    foreach($entry in $table.PSObject.Properties){
        $path=Join-Path $resources $entry.Name
        Check (-not(Test-Path -LiteralPath (Join-Path $other $entry.Name))) "B shadows protected input: $($entry.Name)"
        if(-not(Test-Path -LiteralPath $path)){$errors.Add("Missing protected input: $($entry.Name)");continue}
        Check ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $entry.Value) "Protected art/food data changed: $($entry.Name)"
    }
}
# Item icons have a 16x16 requirement; do not apply it to GUI or animated block atlases.
$iconSizeCount=0
foreach($family in @('food','seeds')){
    $directory=Join-Path $resources "assets/tfcfarmingplus/textures/item/$family"
    if(Test-Path -LiteralPath $directory){
        foreach($sprite in @(Get-ChildItem -LiteralPath $directory -Recurse -File -Filter '*.png')){
            Check-IconSize $sprite.FullName $sprite.FullName
            $iconSizeCount++
        }
    }
}
# Exact reviewed product prose and generator rows, independent of other book pages.
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
        $path=Join-Path $instance ('mod_rebuild/tfcfarmingplus/'+$row.Path)
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
$native=$contract.NativeTexture
foreach($candidate in @((Join-Path $resources $native.Path),(Join-Path $other $native.Path))){
    Check (-not(Test-Path -LiteralPath $candidate)) "Source overrides reviewed native seed atlas: $candidate"
}
$archive=[IO.Compression.ZipFile]::OpenRead((Join-Path $live ('mods/'+$native.Jar)))
try {
    $entry=$archive.GetEntry($native.Path)
    Check ($null -ne $entry) 'Native seed atlas missing from installed dependency'
    if($entry){
        $stream=$entry.Open();$hasher=[Security.Cryptography.SHA256]::Create()
        try {$hash=[BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-','')} finally {$stream.Dispose();$hasher.Dispose()}
        Check ($hash -eq $native.Sha256) 'Installed native seed atlas changed; re-review actual pixels'
    }
} finally {$archive.Dispose()}
$result=[ordered]@{Models=$rows.Count;ProtectedPNGs=@($contract.ProtectedTextureSha256.PSObject.Properties).Count;ProtectedFoodData=@($contract.FoodDataSha256.PSObject.Properties).Count;ItemTextureSize='16x16';ItemPNGsSizeChecked=$iconSizeCount;GuidePages=$guideCount;TemplateRows=$templateCount;Findings=@($errors);VisualAccepted=$false;RuntimeVerified=$false}
if($ReportDirectory){
    [void][IO.Directory]::CreateDirectory($ReportDirectory)
    $utf8=[Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText((Join-Path $ReportDirectory 'item-icon-contracts.json'),($result|ConvertTo-Json -Depth 8),$utf8)
    $rows|Export-Csv -LiteralPath (Join-Path $ReportDirectory 'item-icon-contracts.csv') -NoTypeInformation -Encoding UTF8
}
Write-Host "Reviewed item icons: $($rows.Count), protected PNGs: $($result.ProtectedPNGs), food data: $($result.ProtectedFoodData), findings: $($errors.Count)"
foreach($message in $errors){Write-Host "  - $message"}
if($errors.Count){exit 1};exit 0
