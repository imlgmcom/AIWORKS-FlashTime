# FlashTime - Set version to current date (YY.M.D)
# Called by build-portable.bat before building.
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ver = Get-Date -Format "yy.M.d"

$files = @("src-tauri\tauri.conf.json", "package.json")
$utf8 = New-Object System.Text.UTF8Encoding($false)

foreach ($f in $files) {
    $path = Join-Path $root $f
    if (-not (Test-Path $path)) { continue }
    $text = [IO.File]::ReadAllText($path)
    $new = [regex]::Replace($text, '"version"\s*:\s*"[^"]*"', ('"version": "' + $ver + '"'))
    [IO.File]::WriteAllText($path, $new, $utf8)
}

Write-Output $ver