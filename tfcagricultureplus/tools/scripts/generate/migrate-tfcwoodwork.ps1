param([string]$WorkspaceRoot = '')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    $WorkspaceRoot = (Resolve-Path (Join-Path $env:TFC_TOOLS_ROOT '..\..\..')).Path
}
$project = Resolve-Path (Join-Path $WorkspaceRoot 'mod_rebuild\tfcagricultureplus')
$resources = Join-Path $project 'src\main\resources'
$jar = Get-ChildItem (Join-Path $WorkspaceRoot 'mods') -Filter 'tfcwoodwork-*.jar' |
    Sort-Object Name -Descending | Select-Object -First 1
if ($null -eq $jar) { throw 'TFC Woodworking jar was not found in the workspace mods directory.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($jar.FullName)
$utf8 = New-Object System.Text.UTF8Encoding($false)
$tfcWoods = @('acacia','ash','aspen','birch','blackwood','chestnut','douglas_fir','hickory','kapok','mangrove','maple','oak','palm','pine','rosewood','sequoia','spruce','sycamore','white_cedar','willow')
$afcWoods = @('araucaria','baobab','beech','cypress','eucalyptus','fig','ginkgo','hevea','ipe','ironwood','mahoe','mahogany','teak','tualang')

function Read-EntryJson([string]$name) {
    $entry = $zip.GetEntry($name)
    if ($null -eq $entry) { throw "Missing jar entry: $name" }
    $reader = [IO.StreamReader]::new($entry.Open())
    try { return ($reader.ReadToEnd() | ConvertFrom-Json -AsHashtable -Depth 100) }
    finally { $reader.Dispose() }
}

function Normalize-Value($value) {
    if ($value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $value.Keys) {
            $newKey = switch ([string]$key) {
                'inputState' { 'input_state'; break }
                'requiredTool' { 'tool'; break }
                'resultState' { 'result_state'; break }
                'resultItems' { 'result_items'; break }
                'itemStack' { 'item'; break }
                default { [string]$key }
            }
            if ($key -eq 'sound' -and $value[$key] -is [System.Collections.IDictionary]) {
                $sourceSound = $value[$key]
                if ($sourceSound.ContainsKey('sound') -and $sourceSound['sound'] -is [System.Collections.IDictionary]) {
                    $normalizedSound = [ordered]@{}
                    foreach ($soundKey in @('sound', 'volume', 'pitch')) {
                        if ($soundKey -eq 'sound') {
                            $normalizedSound['sound'] = Normalize-Value $sourceSound['sound']['sound_id']
                        } elseif ($sourceSound.ContainsKey($soundKey)) {
                            $normalizedSound[$soundKey] = Normalize-Value $sourceSound[$soundKey]
                        }
                    }
                    $result[$newKey] = $normalizedSound
                    continue
                }
            }
            $normalizedValue = Normalize-Value $value[$key]
            # B's independent InWorldRecipe codec is deliberately strict:
            # BlockStatePredicate.acceptableStates and result_items are lists,
            # while BlockState and SoundInstance are objects. The licensed
            # source contains single-value shorthand in some recipe families.
            if ($newKey -eq 'acceptableStates' -and $normalizedValue -is [System.Collections.IDictionary]) {
                $normalizedValue = @($normalizedValue)
            } elseif ($newKey -eq 'result_items' -and $normalizedValue -is [System.Collections.IDictionary]) {
                $normalizedValue = @($normalizedValue)
            } elseif ($newKey -eq 'result_state' -and $normalizedValue -is [string]) {
                $normalizedValue = [ordered]@{ Name = $normalizedValue }
            } elseif ($newKey -eq 'sound' -and $normalizedValue -is [string]) {
                $normalizedValue = [ordered]@{ sound = $normalizedValue; volume = 1.0; pitch = 1.0 }
            } elseif ($newKey -in @('pools', 'conditions', 'entries', 'functions') -and $normalizedValue -is [System.Collections.IDictionary]) {
                # Vanilla loot codecs use arrays at every loot-pool nesting level.
                $normalizedValue = @($normalizedValue)
            }
            if ($newKey -eq 'result_items' -and $normalizedValue -is [System.Collections.IList]) {
                $items = @()
                foreach ($itemEntry in $normalizedValue) {
                    if ($itemEntry -is [System.Collections.IDictionary] -and $itemEntry.Contains('item') -and $itemEntry['item'] -is [string]) {
                        $itemEntry['item'] = [ordered]@{ id = $itemEntry['item'] }
                    }
                    $items += ,$itemEntry
                }
                $normalizedValue = $items
            }
            $result[$newKey] = $normalizedValue
        }
        return $result
    }
    if ($value -is [System.Collections.IList]) {
        $result = @()
        foreach ($entry in $value) { $result += ,(Normalize-Value $entry) }
        return $result
    }
    if ($value -is [string]) { return $value.Replace('tfcwoodwork:', 'tfcagricultureplus:') }
    return $value
}

function Convert-JsonForWood($json, [string]$sourceWood, [string]$targetWood, [string]$targetNamespace) {
    $text = $json | ConvertTo-Json -Depth 100 -Compress
    if ($targetNamespace -eq 'afc') {
        $text = $text.Replace('tfc:wood/', 'afc:wood/')
    }
    if ($sourceWood -ne $targetWood) {
        $text = $text.Replace('/' + $sourceWood, '/' + $targetWood)
    }
    return ($text | ConvertFrom-Json -AsHashtable -Depth 100)
}

function Write-Json($value, [string]$relative) {
    $path = Join-Path $resources $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    [IO.File]::WriteAllText($path, (($value | ConvertTo-Json -Depth 100) + "`n"), $utf8)
}

function Migrate-Entry([string]$sourceEntry, [string]$targetRelative, [string]$sourceWood, [string]$targetWood, [string]$targetNamespace) {
    $normalized = Normalize-Value (Read-EntryJson $sourceEntry)
    $normalized = Convert-JsonForWood $normalized $sourceWood $targetWood $targetNamespace
    Write-Json $normalized $targetRelative
}

# Replace the old B wood recipes with the licensed source content converted to B's protocol.
$oldInWorld = Get-ChildItem (Join-Path $resources 'data\tfcagricultureplus\recipe\in_world') -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(axe_|saw_|timber_)' }
foreach ($file in $oldInWorld) { Remove-Item -LiteralPath $file.FullName -Force }

$inWorldEntries = @($zip.Entries | Where-Object { $_.FullName -like 'data/tfcwoodwork/recipe/in_world/*.json' })
foreach ($entry in $inWorldEntries) {
    $relative = $entry.FullName.Substring('data/tfcwoodwork/recipe/in_world/'.Length)
    $sourceWood = [IO.Path]::GetFileNameWithoutExtension($relative)
    Migrate-Entry $entry.FullName ("data\tfcagricultureplus\recipe\in_world\woodwork\tfc\" + $relative.Replace('/','\')) $sourceWood $sourceWood 'tfc'
    foreach ($targetWood in $afcWoods) {
        Migrate-Entry $entry.FullName ("data\tfcagricultureplus\recipe\in_world\woodwork\afc\" + $relative.Replace('/','\').Replace($sourceWood, $targetWood)) $sourceWood $targetWood 'afc'
    }
}

$craftEntries = @($zip.Entries | Where-Object { $_.FullName -like 'data/tfcwoodwork/recipe/crafting/*.json' })
foreach ($entry in $craftEntries) {
    $relative = $entry.FullName.Substring('data/tfcwoodwork/recipe/crafting/'.Length)
    $sourceWood = [IO.Path]::GetFileNameWithoutExtension($relative)
    if ($tfcWoods -contains $sourceWood) {
        Migrate-Entry $entry.FullName ("data\tfcagricultureplus\recipe\crafting\woodwork\tfc\" + $relative.Replace('/','\')) $sourceWood $sourceWood 'tfc'
        foreach ($targetWood in $afcWoods) {
            Migrate-Entry $entry.FullName ("data\tfcagricultureplus\recipe\crafting\woodwork\afc\" + $relative.Replace('/','\').Replace($sourceWood, $targetWood)) $sourceWood $targetWood 'afc'
        }
    } else {
        Migrate-Entry $entry.FullName ("data\tfcagricultureplus\recipe\crafting\woodwork\" + $relative.Replace('/','\')) '' '' 'tfc'
    }
}

# Migrate food/fuel/item-size data and debarked block drops into B's namespace.
foreach ($entry in @($zip.Entries | Where-Object { $_.FullName -like 'data/tfcwoodwork/tfc/*.json' })) {
    $relative = $entry.FullName.Substring('data/tfcwoodwork/tfc/'.Length)
    Migrate-Entry $entry.FullName ("data\tfcagricultureplus\tfc\" + $relative.Replace('/','\')) '' '' 'tfc'
}
foreach ($entry in @($zip.Entries | Where-Object { $_.FullName -like 'data/tfcwoodwork/loot_table/blocks/*.json' })) {
    $relative = $entry.FullName.Substring('data/tfcwoodwork/loot_table/blocks/'.Length)
    Migrate-Entry $entry.FullName ("data\tfcagricultureplus\loot_table\blocks\" + $relative.Replace('/','\')) '' '' 'tfc'
}
foreach ($entry in @($zip.Entries | Where-Object { $_.FullName -like 'data/tfcwoodwork/tags/*.json' })) {
    $relative = $entry.FullName.Substring('data/tfcwoodwork/tags/'.Length)
    Migrate-Entry $entry.FullName ("data\tfcagricultureplus\tags\" + $relative.Replace('/','\')) '' '' 'tfc'
}

# Copy the source's explicit disabling conditions so vanilla TFC wood recipes do not run in parallel.
foreach ($entry in @($zip.Entries | Where-Object { $_.FullName -like 'data/tfc/recipe/crafting/*.json' })) {
    $relative = $entry.FullName.Substring('data/tfc/recipe/crafting/'.Length)
    Migrate-Entry $entry.FullName ("data\tfc\recipe\crafting\" + $relative.Replace('/','\')) '' '' 'tfc'
}

$zip.Dispose()
Write-Host ("Migrated {0} in-world recipes, {1} crafting recipes, and licensed woodwork data into tfcagricultureplus." -f $inWorldEntries.Count, $craftEntries.Count)
