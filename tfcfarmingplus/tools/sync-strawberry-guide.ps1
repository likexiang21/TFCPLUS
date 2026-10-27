param([switch]$Check, [switch]$DryRun)
# Intentional TFC handbook resource overrides. No game logic is copied.
# Review the source pin and all page changes before upgrading TFC.
$ErrorActionPreference = 'Stop'
if ($Check -and $DryRun) { throw 'Choose either -Check or -DryRun.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$module = Split-Path $PSScriptRoot -Parent
$instance = Split-Path (Split-Path $module -Parent) -Parent
$resourceRoot = Join-Path $module 'src/main/resources'
$policy = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'contracts/strawberry-guide-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$jar = Join-Path $instance ('mods/' + $policy.source_jar)
if ((Get-FileHash -LiteralPath $jar -Algorithm SHA256).Hash -ne $policy.source_sha256) {
    throw 'TFC source fingerprint changed. Review the handbook overrides before regenerating.'
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
function To-JsonText($value) {
    return (($value | ConvertTo-Json -Depth 100).Replace("`r`n", "`n") + "`n")
}
$plans = @()
$zip = [IO.Compression.ZipFile]::OpenRead($jar)
try {
    $sourceLanguages = @($zip.Entries | Where-Object {
        $_.FullName -match '^assets/tfc/patchouli_books/field_guide/[^/]+/entries/the_world/wild_fruits\.json$'
    } | ForEach-Object { $_.FullName.Split('/')[4] } | Sort-Object)
    if (@(Compare-Object @($policy.languages | Sort-Object) $sourceLanguages).Count) {
        throw 'TFC handbook language coverage changed. Review every language.'
    }
    foreach ($lang in $policy.languages) {
        $rel = "assets/tfc/patchouli_books/field_guide/$lang/$($policy.entry)"
        $entry = $zip.GetEntry($rel)
        if (-not $entry) { throw "Missing source entry: $rel" }
        $reader = [IO.StreamReader]::new($entry.Open(), [Text.Encoding]::UTF8)
        try { $book = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        $pages = @($book.pages)
        $target = @(0..($pages.Count - 1) | Where-Object { $pages[$_].anchor -eq $policy.removed_anchor })
        if ($target.Count -ne 1) { throw "Expected one strawberry anchor: $lang" }
        $at = $target[0]
        if (($at % 2) -ne 0 -or $at + 1 -ge $pages.Count -or
            $pages[$at].type -ne 'patchouli:text' -or $pages[$at + 1].type -ne 'tfc:multimultiblock' -or
            (To-JsonText $pages[$at + 1]) -notmatch [regex]::Escape($policy.removed_block)) {
            throw "Unexpected strawberry page pair: $lang"
        }
        $small = @(0..($at - 1) | Where-Object { $pages[$_].anchor -eq 'small_bushes' })
        $tables = @(($at + 2)..($pages.Count - 1) | Where-Object { $pages[$_].type -eq 'tfc:table' })
        if ($small.Count -ne 1 -or $tables.Count -ne 1) { throw "Ambiguous berry calendar: $lang" }
        $tableAt = $tables[0]
        $plantPages = @(($small[0] + 1)..($tableAt - 1) | Where-Object { $pages[$_].anchor })
        $ordinal = [Array]::IndexOf($plantPages, $at)
        $table = $pages[$tableAt]
        $width = [int]$table.columns + 1
        if ($ordinal -lt 0 -or $width -ne 13 -or
            $table.strings.Count -ne ($plantPages.Count + 1) * $width) {
            throw "Unexpected berry calendar layout: $lang"
        }
        $rowStart = ($ordinal + 1) * $width
        $table.strings = @(0..($table.strings.Count - 1) | Where-Object {
            $_ -lt $rowStart -or $_ -ge $rowStart + $width
        } | ForEach-Object { $table.strings[$_] })
        $mappings = $book.extra_recipe_mappings
        foreach ($key in @($policy.removed_block, $policy.fruit)) {
            if (-not $mappings.PSObject.Properties[$key] -or [int]$mappings.$key -ne $at) {
                throw "Unexpected strawberry item mapping: $lang / $key"
            }
            $mappings.PSObject.Properties.Remove($key)
        }
        foreach ($property in @($mappings.PSObject.Properties)) {
            $oldIndex = [int]$property.Value
            if ($oldIndex -eq $at -or $oldIndex -eq $at + 1) { throw "Unreviewed mapping into deleted pages: $lang" }
            if ($oldIndex -gt $at + 1) { $property.Value = $oldIndex - 2 }
        }
        $book.pages = @(0..($pages.Count - 1) | Where-Object { $_ -ne $at -and $_ -ne $at + 1 } | ForEach-Object { $pages[$_] })
        $text = To-JsonText $book
        if ($text -match [regex]::Escape($policy.removed_block) -or
            @($book.pages | Where-Object { $_.anchor -eq $policy.removed_anchor }).Count) {
            throw "Strawberry bush reference survived: $lang"
        }
        $plans += [pscustomobject]@{ Relative = $rel; Path = Join-Path $resourceRoot $rel; Text = $text }
    }
} finally { $zip.Dispose() }
# Prepare and validate every language before writing any output.
$different = @()
foreach ($plan in $plans) {
    $same = $false
    if (Test-Path -LiteralPath $plan.Path) {
        $existing = [IO.File]::ReadAllText($plan.Path, $utf8) | ConvertFrom-Json
        $same = (To-JsonText $existing) -ceq $plan.Text
    }
    if (-not $same) { $different += $plan.Relative }
    if (-not $Check -and -not $DryRun -and -not $same) {
        [void][IO.Directory]::CreateDirectory((Split-Path $plan.Path -Parent))
        [IO.File]::WriteAllText($plan.Path, $plan.Text, $utf8)
    }
}
Write-Output ("[INFO] reviewed languages = {0}; different outputs = {1}" -f $plans.Count, $different.Count)
if ($Check -and $different.Count) {
    $different | ForEach-Object { Write-Output "[FAIL] $_" }
    throw 'Handbook resources differ from the reviewed source transformation.'
}
if ($DryRun) { $different | ForEach-Object { Write-Output "[PLAN] $_" } }
if ($Check) { Write-Output '[OK] only the strawberry page pair, calendar row and item mappings changed from pinned TFC resources' }
