# FlashTime Portable Packaging Script
# Called by build-portable.bat
param(
    [string]$Root,
    [string]$Exe
)

$ErrorActionPreference = "Stop"

$version = "0.1.0"
# Build Chinese filename via char codes to avoid encoding issues
$exeName = [char]0x95EA + [char]0x65F6 + [char]0x5DE5 + [char]0x5177 + [char]0x7BB1 + ".exe"
$zipName = [char]0x95EA + [char]0x65F6 + [char]0x5DE5 + [char]0x5177 + [char]0x7BB1 + "-portable-v" + $version + ".zip"

$zipPath = Join-Path $Root $zipName
$tmpDir = Join-Path $Root "_portable_tmp"

Write-Host "[3/4] Creating portable package..."

# Clean up
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

# Create structure
New-Item -ItemType Directory -Path $tmpDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmpDir "data") | Out-Null

# Copy exe with Chinese name
Copy-Item $Exe (Join-Path $tmpDir $exeName)

# Zip
Compress-Archive -Path "$tmpDir\*" -DestinationPath $zipPath -Force

# Clean up temp
Remove-Item -Recurse -Force $tmpDir

# Show result
$size = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
Write-Host ""
Write-Host "============================================================"
Write-Host (" Done! " + $size + " MB")
Write-Host (" File: " + $zipName)
Write-Host "============================================================"
