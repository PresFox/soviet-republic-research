param(
    [string]$InputFile = "C:\Program Files (x86)\Steam\steamapps\common\SovietRepublic\ghidra_results\ FUN_1402a1d60.c",
    [string]$OutputFile = "C:\Program Files (x86)\Steam\steamapps\common\SovietRepublic\master_tables\resources.html",
    [string]$CsvOutputFile = "C:\Program Files (x86)\Steam\steamapps\common\SovietRepublic\master_tables\resources.csv"
)

$lines = Get-Content -LiteralPath $InputFile
$baseStackOffset = 0x378
$fieldSizes = @{}

foreach ($line in $lines[0..120]) {
    if ($line -match '^\s*(undefined1|undefined2|undefined4|undefined8|ulonglong|C3D_MESH \*)\s+(local|uStack|pCStack)_([0-9a-f]+)') {
        $size = switch ($matches[1]) {
            'undefined1' { 1 }
            'undefined2' { 2 }
            'undefined4' { 4 }
            default { 8 }
        }
        $fieldSizes[($matches[2] + '_' + $matches[3])] = $size
    }
}

function Get-RecordOffset([string]$field) {
    if ($field -notmatch '^(?:local|uStack|pCStack)_([0-9a-f]+)') { return $null }
    return $baseStackOffset - [Convert]::ToInt32($matches[1], 16)
}

function Convert-HexLittleEndianText([string]$hex) {
    if (($hex.Length % 2) -ne 0) { $hex = '0' + $hex }
    $chars = [System.Collections.Generic.List[char]]::new()
    for ($i = $hex.Length - 2; $i -ge 0; $i -= 2) {
        $b = [Convert]::ToByte($hex.Substring($i, 2), 16)
        if ($b -eq 0) { break }
        if (($b -ge 32) -and ($b -le 126)) { $chars.Add([char]$b) }
    }
    return -join $chars
}

function Set-StateValue([hashtable]$state, [int]$offset, [int]$size, [UInt64]$value) {
    if ($size -eq 8) {
        $state[$offset] = [UInt32]($value -band 0xffffffffL)
        $state[$offset + 4] = [UInt32](($value -shr 32) -band 0xffffffffL)
    } elseif ($size -eq 4) {
        $state[$offset] = [UInt32]($value -band 0xffffffffL)
    } elseif ($size -eq 2) {
        $state[$offset] = [UInt32]($value -band 0xffff)
    } else {
        $state[$offset] = [UInt32]($value -band 0xff)
    }
}

function Format-Value([UInt32]$bits, [int]$offset) {
    if ($offset -eq 0x44) { return [string][BitConverter]::ToInt32([BitConverter]::GetBytes($bits), 0) }
    $integerOffsets = @(0x40, 0xc8, 0x248, 0x2ec, 0x30c)
    if ($integerOffsets -contains $offset) { return [string]$bits }
    if ($bits -eq 0) { return '0' }
    $bytes = [BitConverter]::GetBytes($bits)
    $float = [BitConverter]::ToSingle($bytes, 0)
    $exponent = ($bits -shr 23) -band 0xff
    if (($exponent -gt 0) -and ($exponent -lt 255) -and [float]::IsFinite($float)) {
        return ('{0:G9}' -f $float)
    }
    return [string]$bits
}

$state = @{}
for ($offset = 0; $offset -lt 0x340; $offset += 4) { $state[$offset] = [UInt32]0 }
$records = [System.Collections.Generic.List[object]]::new()
$nameBytes = [byte[]]::new(64)
$assets = [System.Collections.Generic.List[string]]::new()

function Write-NameHex([int]$destination, [string]$hex, [int]$width) {
    if (($hex.Length % 2) -ne 0) { $hex = '0' + $hex }
    $source = [System.Collections.Generic.List[byte]]::new()
    for ($i = $hex.Length - 2; $i -ge 0; $i -= 2) {
        $source.Add([Convert]::ToByte($hex.Substring($i, 2), 16))
    }
    while ($source.Count -lt $width) { $source.Add(0) }
    for ($i = 0; ($i -lt $width) -and (($destination + $i) -lt $nameBytes.Length); $i++) {
        $nameBytes[$destination + $i] = $source[$i]
    }
}

function Get-CurrentName {
    $length = 0
    while (($length -lt $nameBytes.Length) -and ($nameBytes[$length] -ne 0)) { $length++ }
    return [Text.Encoding]::ASCII.GetString($nameBytes, 0, $length)
}

function Add-Record {
    $name = Get-CurrentName
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    $copy = @{}
    foreach ($key in $script:state.Keys) { $copy[$key] = $script:state[$key] }
    $records.Add([pscustomobject]@{
        Name = $name
        State = $copy
        Assets = @($script:assets | Select-Object -Unique)
    })
    $script:assets = [System.Collections.Generic.List[string]]::new()
}

foreach ($line in $lines) {
    foreach ($match in [regex]::Matches($line, '"(resources/[^\"]+\.(?:nmf|mtl|dds))"')) {
        if (-not $assets.Contains($match.Groups[1].Value)) { $assets.Add($match.Groups[1].Value) }
    }

    if ($line -match '^\s*(local_378|uStack_370)\s*=\s*0x([0-9a-fA-F]+);') {
        $destination = if ($matches[1] -eq 'local_378') { 0 } else { 8 }
        Write-NameHex $destination $matches[2] 8
    } elseif ($line -match '^\s*(local_378|uStack_370)\s*=\s*CONCAT[0-9]([0-9])\([^,]+,0x([0-9a-fA-F]+)\);') {
        $destination = if ($matches[1] -eq 'local_378') { 0 } else { 8 }
        Write-NameHex $destination $matches[3] ([int]$matches[2].ToString())
    } elseif ($line -match '^\s*(local_378|uStack_370)\._([0-9]+)_1_\s*=\s*''(.)'';') {
        $nameBase = if ($matches[1] -eq 'local_378') { 0 } else { 8 }
        $destination = $nameBase + [int]$matches[2]
        $nameBytes[$destination] = [byte][char]$matches[3]
    } elseif ($line -match '^\s*(local_378|uStack_370)\._([0-9]+)_([0-9])_\s*=\s*0x([0-9a-fA-F]+);') {
        $nameBase = if ($matches[1] -eq 'local_378') { 0 } else { 8 }
        $destination = $nameBase + [int]$matches[2]
        Write-NameHex $destination $matches[4] ([int]$matches[3].ToString())
    } elseif ($line -match '^\s*local_368\s*=\s*(0x[0-9a-fA-F]+|[0-9]+);') {
        $value = if ($matches[1].StartsWith('0x')) { [Convert]::ToUInt16($matches[1].Substring(2), 16) } else { [UInt16]$matches[1] }
        Write-NameHex 16 ('{0:x4}' -f $value) 2
    } elseif ($line -match '^\s*uStack_370\s*=\s*uStack_370\s*&\s*0x([0-9a-fA-F]+);') {
        $mask = [Convert]::ToUInt64($matches[1], 16)
        for ($i = 0; $i -lt 8; $i++) {
            if ((($mask -shr ($i * 8)) -band 0xff) -eq 0) { $nameBytes[8 + $i] = 0 }
        }
    }

    if ($line -match '^\s*((?:local|uStack|pCStack)_[0-9a-f]+)(?:\[0\](?:\._0_4_)?|\._0_[0-9]_)?\s*=\s*(0x[0-9a-fA-F]+|[0-9]+);') {
        $field = $matches[1]
        $raw = $matches[2]
        $offset = Get-RecordOffset $field
        if ($null -ne $offset) {
            $size = if ($fieldSizes.ContainsKey($field)) { $fieldSizes[$field] } else { 4 }
            if ($line -match '\._0_4_' -or $line -match '\[0\]') { $size = [Math]::Min($size, 4) }
            $value = if ($raw.StartsWith('0x')) { [Convert]::ToUInt64($raw.Substring(2), 16) } else { [UInt64]$raw }
            Set-StateValue $state $offset $size $value
        }
    }

    if (($line -match '^\s*FUN_140449350\(puVar1,&local_378\);') -or
        ($line -match '^\s*\*\(longlong \*\)\(param_1 \+ 0xc2b8\) = \*\(longlong \*\)\(param_1 \+ 0xc2b8\) \+ 0x340;')) {
        Add-Record
    }
}

$knownLabels = @{
    0x40 = 'localizationId'
    0x44 = 'productionChainDepth'
    0x50 = 'workerPriceMultiplier'
    0x58 = 'calculatedPriceA'
    0x5c = 'calculatedPriceB'
    0x60 = 'priceBoundA'
    0x64 = 'priceBoundB'
    0x68 = 'productionCostAdjustmentA'
    0x6c = 'productionCostAdjustmentB'
    0x70 = 'specialPriceCopyA'
    0x74 = 'specialPriceCopyB'
    0x88 = 'priceMultiplierA_low'
    0x8c = 'priceMultiplierA_high'
    0xa4 = 'priceMultiplierA_base'
    0xa8 = 'priceMultiplierB_low'
    0xac = 'priceMultiplierB_high'
    0xc4 = 'priceMultiplierB_base'
    0xc8 = 'unknown_0xC8'
    0x248 = 'unknown_0x248'
    0x2ec = 'isWasteResource'
    0x30c = 'recyclingMaterialFamily'
    0x310 = 'unknown_0x310'
}

$offsets = [System.Collections.Generic.SortedSet[int]]::new()
foreach ($record in $records) {
    foreach ($offset in $record.State.Keys) {
        if (($offset -ge 0x40) -and ($offset -lt 0x318) -and ($record.State[$offset] -ne 0)) {
            [void]$offsets.Add([int]$offset)
        }
    }
}

$headers = @('internalName') + @($offsets | ForEach-Object {
    if ($knownLabels.ContainsKey($_)) { $knownLabels[$_] } else { 'unknown_0x{0:X3}' -f $_ }
}) + @('meshAndMaterialAssets')

$csvRows = foreach ($record in $records) {
    $properties = [ordered]@{ internalName = $record.Name }
    foreach ($offset in $offsets) {
        $header = if ($knownLabels.ContainsKey($offset)) { $knownLabels[$offset] } else { 'unknown_0x{0:X3}' -f $offset }
        $properties[$header] = if ($record.State.ContainsKey($offset)) {
            Format-Value $record.State[$offset] $offset
        } else {
            '0'
        }
    }
    $properties.meshAndMaterialAssets = $record.Assets -join '; '
    [pscustomobject]$properties
}

$rows = foreach ($record in $records) {
    $cells = [System.Collections.Generic.List[string]]::new()
    $cells.Add([System.Net.WebUtility]::HtmlEncode($record.Name))
    foreach ($offset in $offsets) {
        $value = if ($record.State.ContainsKey($offset)) { Format-Value $record.State[$offset] $offset } else { '0' }
        $cells.Add([System.Net.WebUtility]::HtmlEncode($value))
    }
    $assetText = ($record.Assets -join "`n")
    $cells.Add([System.Net.WebUtility]::HtmlEncode($assetText).Replace("`n", '<br>'))
    '<tr>' + (($cells | ForEach-Object { '<td>' + $_ + '</td>' }) -join '') + '</tr>'
}

$headerHtml = ($headers | ForEach-Object { '<th>' + [System.Net.WebUtility]::HtmlEncode($_) + '</th>' }) -join ''
$generated = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss K')
$html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Soviet Republic Resource Master Table</title>
<style>
:root { color-scheme: dark; font-family: Segoe UI, Arial, sans-serif; }
body { margin: 0; background: #11151a; color: #e7edf3; }
header { padding: 18px 22px; border-bottom: 1px solid #35404b; background: #192129; position: sticky; left: 0; }
h1 { margin: 0 0 6px; font-size: 21px; }
p { margin: 3px 0; color: #aebbc7; }
.controls { display: flex; gap: 8px; margin-top: 12px; flex-wrap: wrap; }
input, select, button { background: #111820; color: #e7edf3; border: 1px solid #465463; border-radius: 4px; padding: 6px 9px; }
input { min-width: 260px; }
button { cursor: pointer; }
.table-wrap { overflow: auto; height: calc(100vh - 150px); }
table { border-collapse: separate; border-spacing: 0; font: 12px Consolas, monospace; white-space: nowrap; }
th, td { padding: 6px 8px; border-right: 1px solid #303943; border-bottom: 1px solid #303943; text-align: right; }
th { position: sticky; top: 0; z-index: 2; background: #24303a; color: #dbe9f5; cursor: pointer; }
th:first-child, td:first-child { position: sticky; left: 0; text-align: left; z-index: 1; background: #1b242c; font-weight: 600; }
th:first-child { z-index: 3; background: #24303a; }
td:last-child { text-align: left; color: #b6d7a8; }
tr:hover td { background-color: #27323c; }
tr:hover td:first-child { background-color: #303d48; }
</style>
</head>
<body>
<header>
<h1>Hardcoded resource definitions</h1>
<p>Decoded from FUN_1402A1D60. Unknown columns retain their record offsets.</p>
<p>$($records.Count) records · generated $generated</p>
<div class="controls">
  <input id="search" type="search" placeholder="Filter resources or asset paths">
  <select id="groupColumn"><option value="">Group/sort by column…</option></select>
  <button id="groupButton" type="button">Group ascending</button>
  <button id="resetButton" type="button">Reset</button>
</div>
</header>
<div class="table-wrap"><table id="resources"><thead><tr>$headerHtml</tr></thead><tbody>$($rows -join "`n")</tbody></table></div>
<script>
document.querySelectorAll('th').forEach((th, column) => th.addEventListener('click', () => {
  const body = th.closest('table').tBodies[0];
  const direction = th.dataset.direction === 'asc' ? -1 : 1;
  th.dataset.direction = direction === 1 ? 'asc' : 'desc';
  [...body.rows].sort((a, b) => {
    const av = a.cells[column].innerText.trim(), bv = b.cells[column].innerText.trim();
    const an = Number(av), bn = Number(bv);
    return direction * ((!Number.isNaN(an) && !Number.isNaN(bn)) ? an - bn : av.localeCompare(bv));
  }).forEach(row => body.appendChild(row));
}));
const table = document.getElementById('resources');
const originalRows = [...table.tBodies[0].rows];
const groupColumn = document.getElementById('groupColumn');
[...table.tHead.rows[0].cells].forEach((cell, index) => {
  const option = document.createElement('option');
  option.value = index; option.textContent = cell.innerText;
  groupColumn.appendChild(option);
});
document.getElementById('search').addEventListener('input', event => {
  const query = event.target.value.trim().toLowerCase();
  [...table.tBodies[0].rows].forEach(row => {
    row.hidden = query && !row.innerText.toLowerCase().includes(query);
  });
});
document.getElementById('groupButton').addEventListener('click', () => {
  if (groupColumn.value === '') return;
  const column = Number(groupColumn.value), body = table.tBodies[0];
  [...body.rows].sort((a, b) => {
    const av = a.cells[column].innerText.trim(), bv = b.cells[column].innerText.trim();
    const an = Number(av), bn = Number(bv);
    return (!Number.isNaN(an) && !Number.isNaN(bn)) ? an - bn : av.localeCompare(bv);
  }).forEach(row => body.appendChild(row));
});
document.getElementById('resetButton').addEventListener('click', () => {
  document.getElementById('search').value = '';
  groupColumn.value = '';
  originalRows.forEach(row => { row.hidden = false; table.tBodies[0].appendChild(row); });
});
</script>
</body>
</html>
"@

$directory = Split-Path -Parent $OutputFile
New-Item -ItemType Directory -Force -Path $directory | Out-Null
Set-Content -LiteralPath $OutputFile -Value $html -Encoding utf8
$csvDirectory = Split-Path -Parent $CsvOutputFile
New-Item -ItemType Directory -Force -Path $csvDirectory | Out-Null
$csvRows | Export-Csv -LiteralPath $CsvOutputFile -NoTypeInformation -Encoding utf8
Write-Output "Wrote $($records.Count) records and $($offsets.Count) numeric fields to $OutputFile and $CsvOutputFile"
