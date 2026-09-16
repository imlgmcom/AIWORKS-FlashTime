param(
    [Parameter(Mandatory=$true)]
    [string]$Root
)

$ErrorActionPreference = "Stop"

# 输出文件名
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$zipName = "闪时-$timestamp.zip"
$zipPath = Join-Path $Root ".bak\$zipName"

# 确保备份目录存在
$bakDir = Join-Path $Root ".bak"
if (-not (Test-Path $bakDir)) {
    New-Item -ItemType Directory -Path $bakDir -Force | Out-Null
}

# 排除的目录名（匹配任意层级）
$excludeNames = @("node_modules", ".temp", ".bak", "dist", "gen", "target", ".vscode")

Write-Host "[1/3] Scanning files..."

# 收集要备份的文件 —— 按目录名精确排除
$allFiles = Get-ChildItem -Path $Root -Recurse -File | Where-Object {
    $skip = $false
    $parts = $_.FullName.Substring($Root.Length + 1) -split '\\'
    foreach ($part in $parts) {
        if ($excludeNames -contains $part) {
            $skip = $true
            break
        }
    }
    -not $skip
}

$fileCount = $allFiles.Count
Write-Host "[2/3] Compressing $fileCount files..."

# 如果已存在同名 zip，先删除
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# 用 .NET ZipFile 直接从源文件打包（无需暂存复制，解决中文乱码）
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $allFiles) {
        $relativePath = $file.FullName.Substring($Root.Length + 1).Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relativePath) | Out-Null
    }
} finally {
    $zip.Dispose()
}

Write-Host "[3/3] Done!"

# 显示大小
$size = (Get-Item $zipPath).Length
$sizeMB = [math]::Round($size / 1MB, 2)

Write-Host ""
Write-Host "============================================"
Write-Host "  Backup: $zipPath"
Write-Host "  Size:   $sizeMB MB"
Write-Host "  Files:  $fileCount"
Write-Host "============================================"
