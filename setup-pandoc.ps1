[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$version = '3.11'
$expectedSha256 = '2AB72BAF2399450E148DDF7A2A8689806C42E1BBA71862B57E220FD9B8456D3D'
$projectRoot = $PSScriptRoot
$toolsDir = Join-Path $projectRoot '.tools'
$archiveName = "pandoc-$version-windows-x86_64.zip"
$archivePath = Join-Path $toolsDir $archiveName
$pandocPath = Join-Path $toolsDir "pandoc-$version\pandoc.exe"
$downloadUrl = "https://github.com/jgm/pandoc/releases/download/$version/$archiveName"

if (Test-Path -LiteralPath $pandocPath) {
    Write-Host "Pandoc $version is already installed locally."
    & $pandocPath --version | Select-Object -First 1
    exit 0
}

New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null

if (Test-Path -LiteralPath $archivePath) {
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash
    if ($actualHash -ne $expectedSha256) {
        Remove-Item -LiteralPath $archivePath -Force
    }
}

if (-not (Test-Path -LiteralPath $archivePath)) {
    Write-Host "Downloading official Pandoc $version portable archive..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath
}

$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash
if ($actualHash -ne $expectedSha256) {
    throw "Pandoc archive checksum mismatch. Expected $expectedSha256, got $actualHash."
}

Expand-Archive -LiteralPath $archivePath -DestinationPath $toolsDir -Force
if (-not (Test-Path -LiteralPath $pandocPath)) {
    throw "Pandoc executable was not found after extraction: $pandocPath"
}

Write-Host "Pandoc installed locally and checksum verified."
& $pandocPath --version | Select-Object -First 1

