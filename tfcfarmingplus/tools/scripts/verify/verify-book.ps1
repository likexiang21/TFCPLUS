# Check additive entries and explicitly reviewed TFC handbook overrides.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$module = Split-Path $env:TFC_TOOLS_ROOT -Parent
$instance = Split-Path (Split-Path $module -Parent) -Parent
$root = (Resolve-Path -LiteralPath (Join-Path $module 'src/main/resources')).Path
$ourDir = Join-Path $root 'assets/tfc/patchouli_books/field_guide'
if (-not (Test-Path -LiteralPath $ourDir)) { throw 'Missing field guide resources.' }
$errors = New-Object 'System.Collections.Generic.List[string]'
$knownPaths = New-Object 'System.Collections.Generic.HashSet[string]'
$knownItems = New-Object 'System.Collections.Generic.HashSet[string]'
$categories = New-Object 'System.Collections.Generic.HashSet[string]'
$tfcPaths = New-Object 'System.Collections.Generic.HashSet[string]'
$policy = Get-Content -LiteralPath (Join-Path $env:TFC_TOOLS_ROOT 'contracts/strawberry-guide-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$allowed = @($policy.languages | ForEach-Object { "assets/tfc/patchouli_books/field_guide/$_/$($policy.entry)" })
function Register-Resource([string]$path) {
    [void]$knownPaths.Add($path)
    if ($path -match '^assets/([^/]+)/models/item/(.+)\.json$') {
        [void]$knownItems.Add("$($Matches[1]):$($Matches[2])")
    }
    if ($path -match '^assets/([^/]+)/patchouli_books/field_guide/en_us/categories/(.+)\.json$') {
        [void]$categories.Add("$($Matches[1]):$($Matches[2])")
    }
}
foreach ($prefix in @('TerraFirmaCraft-NeoForge-', 'Patchouli-')) {
    $jars = @(Get-ChildItem -LiteralPath (Join-Path $instance 'mods') -File | Where-Object {
        $_.Name.StartsWith($prefix) -and $_.Extension -eq '.jar'
    })
    if ($jars.Count -ne 1) { throw "Expected exactly one dependency JAR: $prefix" }
    $zip = [IO.Compression.ZipFile]::OpenRead($jars[0].FullName)
    try {
        foreach ($entry in $zip.Entries) {
            [void]$tfcPaths.Add($entry.FullName)
            Register-Resource $entry.FullName
        }
    } finally { $zip.Dispose() }
}
foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File) {
    Register-Resource ($file.FullName.Substring($root.Length + 1).Replace('\', '/'))
}
$ours = @(Get-ChildItem -LiteralPath $ourDir -Recurse -File -Filter '*.json')
$intentional = 0
foreach ($file in $ours) {
    $rel = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
    if ($tfcPaths.Contains($rel)) {
        if ($rel -in $allowed) { $intentional++ }
        else { $errors.Add("Unreviewed handbook override: $rel") }
    }
}
try { & (Join-Path $env:TFC_TOOLS_ROOT 'sync-strawberry-guide.ps1') -Check }
catch { $errors.Add($_.Exception.Message) }
if ($intentional -ne $allowed.Count) { $errors.Add('Reviewed override coverage does not match the policy.') }
$enDir = Join-Path $ourDir 'en_us'
$enFiles = @{}
foreach ($file in Get-ChildItem -LiteralPath $enDir -Recurse -File -Filter '*.json') {
    $enFiles[$file.FullName.Substring($enDir.Length + 1).Replace('\', '/')] = $true
}
$entries = 0
$pageCount = 0
foreach ($langDir in Get-ChildItem -LiteralPath $ourDir -Directory) {
    foreach ($file in Get-ChildItem -LiteralPath $langDir.FullName -Recurse -File -Filter '*.json') {
        $rel = $file.FullName.Substring($langDir.FullName.Length + 1).Replace('\', '/')
        $label = "$($langDir.Name)/$rel"
        if (-not $enFiles.ContainsKey($rel)) { $errors.Add("Not discoverable from en_us: $label") }
        try { $book = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }
        catch { $errors.Add("Invalid JSON: $label"); continue }
        if (-not $rel.StartsWith('entries/')) { continue }
        $entries++
        if (-not $categories.Contains([string]$book.category)) { $errors.Add("Unknown category: $label / $($book.category)") }
        foreach ($required in @('read_by_default', 'sortnum')) {
            if (-not $book.PSObject.Properties[$required]) { $errors.Add("Missing $required : $label") }
        }
        if ($book.icon -and -not $knownItems.Contains([string]$book.icon)) {
            $parts = ([string]$book.icon).Split(':', 2)
            if ($parts.Count -ne 2 -or -not $knownPaths.Contains("assets/$($parts[0])/$($parts[1])")) {
                $errors.Add("Unknown icon: $label / $($book.icon)")
            }
        }
        foreach ($mapping in @($book.extra_recipe_mappings.PSObject.Properties)) {
            if (-not $mapping) { continue }
            if ([int]$mapping.Value -lt 0 -or [int]$mapping.Value -ge $book.pages.Count) {
                $errors.Add("Out-of-range item jump: $label / $($mapping.Name)")
            }
            if (-not $knownItems.Contains($mapping.Name)) { $errors.Add("Unknown mapped item: $label / $($mapping.Name)") }
        }
        for ($i = 0; $i -lt $book.pages.Count; $i++) {
            $page = $book.pages[$i]
            $pageCount++
            if ($page.item -and -not $knownItems.Contains([string]$page.item)) {
                $errors.Add("Unknown page item: $label / $($page.item)")
            }
            if ($page.type -eq 'tfc:multimultiblock' -and ($i % 2) -ne 1) {
                $errors.Add("Multiblock should occupy the right page: $label / $i")
            }
            if ($page.type -eq 'tfc:table' -and (($i % 2) -ne 0 -or
                $i + 1 -ge $book.pages.Count -or $book.pages[$i + 1].type -ne 'patchouli:empty')) {
                $errors.Add("Table spread needs an even index and empty right page: $label / $i")
            }
        }
    }
}
foreach ($lang in @('en_us', 'zh_cn')) {
    $cropPath = Join-Path $ourDir "$lang/$($policy.crop_entry)"
    if (-not (Test-Path -LiteralPath $cropPath)) { $errors.Add("Missing strawberry crop guide: $lang"); continue }
    $crop = Get-Content -LiteralPath $cropPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $crop.extra_recipe_mappings.PSObject.Properties['tfc:food/strawberry'] -or
        [int]$crop.extra_recipe_mappings.'tfc:food/strawberry' -ne 0 -or
        -not $crop.extra_recipe_mappings.PSObject.Properties['tfcfarmingplus:seeds/strawberry']) {
        $errors.Add("Strawberry crop/fruit jump is missing: $lang")
    }
}
Write-Output ("[INFO] intentional overrides = {0}; entries = {1}; pages = {2}" -f $intentional, $entries, $pageCount)
if ($errors.Count) {
    $errors | ForEach-Object { Write-Output "[FAIL] $_" }
    exit 1
}
Write-Output '[OK] handbook JSON, discovery, categories, items, jump indices and spreads checked'
