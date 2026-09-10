$root = "d:\Webus Labs\POS BIllingwala\pos_billingwala_v2\lib\features"
$imp = "import 'package:pos_billingwala_v2/core/widgtes/widgtes.dart';"
$pattern = 'TextFormField|FilledButton|ElevatedButton|OutlinedButton|DropdownButtonFormField|showModalBottomSheet|\bCard\('
$changed = @()

Get-ChildItem -Path $root -Recurse -Filter *.dart |
  Where-Object { $_.FullName -match '\\presentation\\' } |
  ForEach-Object {
    $text = Get-Content -Raw -LiteralPath $_.FullName
    if ($text -match 'core/widgtes/widgtes\.dart') { return }
    if ($text -notmatch $pattern) { return }
    $lines = Get-Content -LiteralPath $_.FullName
    $insertAt = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -like 'import *') { $insertAt = $i + 1 }
    }
    $new = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($i -eq $insertAt) { $new += $imp }
      $new += $lines[$i]
    }
    if ($insertAt -ge $lines.Count) { $new += $imp }
    Set-Content -LiteralPath $_.FullName -Value $new -Encoding utf8
    $changed += $_.FullName.Replace($root + '\', '')
  }

Write-Host "imports added: $($changed.Count)"
$changed | ForEach-Object { Write-Host $_ }
