[CmdletBinding()]
param(
    [ValidateRange(32, 320)]
    [int]$BitrateKbps = 192
)

$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$configPath = Join-Path $projectRoot 'paths.json'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Configuration file not found: $configPath"
}

$paths = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if (-not $paths.inputFolder -or -not $paths.outputFolder) {
    throw 'paths.json must define both inputFolder and outputFolder.'
}

$inputRoot = if ([System.IO.Path]::IsPathRooted($paths.inputFolder)) {
    $paths.inputFolder
} else {
    Join-Path $projectRoot $paths.inputFolder
}
$outputRoot = if ([System.IO.Path]::IsPathRooted($paths.outputFolder)) {
    $paths.outputFolder
} else {
    Join-Path $projectRoot $paths.outputFolder
}
$supportedExtensions = @('.hevc', '.h265', '.mp4', '.m4v', '.mov', '.mkv', '.avi', '.ts', '.mts', '.m2ts')

if (-not (Test-Path -LiteralPath $inputRoot -PathType Container)) {
    throw "Input folder not found: $inputRoot"
}

if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $outputRoot | Out-Null
}

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    throw @'
ffmpeg was not found. Install it, then open a new PowerShell window and run this script again.
Windows installation option: winget install --id Gyan.FFmpeg --exact
'@
}

$files = Get-ChildItem -LiteralPath $inputRoot -File -Recurse | Where-Object {
    $supportedExtensions -contains $_.Extension.ToLowerInvariant()
}

if (-not $files) {
    Write-Host "No supported video files were found in '$inputRoot'."
    exit 0
}

$converted = 0
$failed = 0

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($inputRoot.Length).TrimStart('\', '/')
    $relativeDirectory = Split-Path $relativePath -Parent
    $destinationDirectory = if ($relativeDirectory) {
        Join-Path $outputRoot $relativeDirectory
    } else {
        $outputRoot
    }

    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    $destination = Join-Path $destinationDirectory ($file.BaseName + '.mp3')

    Write-Host "Converting: $relativePath"
    & $ffmpeg.Source -hide_banner -loglevel error -y -i $file.FullName `
        -map '0:a:0' -vn -codec:a libmp3lame -b:a "${BitrateKbps}k" $destination

    if ($LASTEXITCODE -eq 0) {
        $converted++
        Write-Host "Saved:      $destination" -ForegroundColor Green
    } else {
        $failed++
        Remove-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
        Write-Warning "Could not convert '$relativePath'. It may not contain an audio stream."
    }
}

Write-Host "Finished: $converted converted, $failed failed."
if ($failed -gt 0) {
    exit 1
}
