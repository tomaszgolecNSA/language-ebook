[CmdletBinding()]
param(
    [string]$Source = 'THE IMMERSION GAP.md',
    [string]$Output = 'dist\the-immersion-gap.epub'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = $PSScriptRoot

function Resolve-ProjectPath([string]$PathValue) {
    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
    }
    return Join-Path $projectRoot $PathValue
}

$sourcePath = Resolve-ProjectPath $Source
$outputPath = Resolve-ProjectPath $Output
$coverPath = Join-Path $projectRoot 'frontpage.png'
$metadataPath = Join-Path $projectRoot 'ebook.yaml'
$cssPath = Join-Path $projectRoot 'kindle.css'
$frontmatterPath = Join-Path $projectRoot 'ebook-frontmatter.md'
$prepareScript = Join-Path $projectRoot 'scripts\prepare_manuscript.py'
$validateScript = Join-Path $projectRoot 'scripts\validate_epub.py'
$buildDir = Join-Path $projectRoot '.build'
$preparedPath = Join-Path $buildDir 'manuscript.md'

$requiredFiles = @(
    $sourcePath,
    $coverPath,
    $metadataPath,
    $cssPath,
    $frontmatterPath,
    $prepareScript,
    $validateScript
)
foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Required file not found: $file"
    }
}

$pandocCandidates = @(
    @(
        (Join-Path $projectRoot '.tools\pandoc-3.11\pandoc.exe'),
        (Get-Command pandoc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
)

if (-not $pandocCandidates) {
    throw "Pandoc is not installed. Run .\setup-pandoc.ps1 once, then build again."
}
$pandoc = $pandocCandidates | Select-Object -First 1

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCommand) {
    throw 'Python 3 is required for manuscript preparation and EPUB validation.'
}
$python = $pythonCommand.Source

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputPath) | Out-Null

Write-Host 'Preparing manuscript...'
& $python $prepareScript --source $sourcePath --output $preparedPath
if ($LASTEXITCODE -ne 0) {
    throw "Manuscript preparation failed with exit code $LASTEXITCODE."
}

Write-Host 'Building EPUB 3...'
$pandocArgs = @(
    '--from=markdown+smart',
    '--to=epub3',
    '--standalone',
    "--metadata-file=$metadataPath",
    "--epub-cover-image=$coverPath",
    "--css=$cssPath",
    '--toc',
    '--toc-depth=1',
    '--split-level=1',
    "--resource-path=$projectRoot",
    "--output=$outputPath",
    $frontmatterPath,
    $preparedPath
)
& $pandoc @pandocArgs
if ($LASTEXITCODE -ne 0) {
    throw "Pandoc failed with exit code $LASTEXITCODE."
}

Write-Host 'Validating EPUB structure...'
& $python $validateScript $outputPath
if ($LASTEXITCODE -ne 0) {
    throw "EPUB validation failed with exit code $LASTEXITCODE."
}

$result = Get-Item -LiteralPath $outputPath
Write-Host ''
Write-Host 'Kindle test file is ready:'
Write-Host "  $($result.FullName)"
Write-Host "  $([Math]::Round($result.Length / 1MB, 2)) MB"
