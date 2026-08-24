[CmdletBinding()]
param(
    [ValidateRange(64, 320)]
    [int]$AudioBitrateKbps = 192
)

$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$inputRoot = Join-Path $projectRoot 'USB'
$outputRoot = Join-Path $projectRoot 'done'

if (-not (Test-Path -LiteralPath $inputRoot -PathType Container)) {
    throw "Input folder not found: $inputRoot"
}

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    throw @'
ffmpeg was not found. Install it, then open a new PowerShell window and run this script again.
Windows installation option: winget install --id Gyan.FFmpeg --exact
'@
}

# Verify the installed FFmpeg can initialize its HEVC encoder before processing
# the entire library. Some builds expose libx265 but reject unsupported tuning.
Write-Host 'Checking HEVC encoder...'
& $ffmpeg.Source -hide_banner -loglevel error -f lavfi `
    -i 'color=c=black:s=640x360:r=25' -frames:v 1 `
    -c:v libx265 -preset ultrafast -pix_fmt yuv420p -f null NUL
if ($LASTEXITCODE -ne 0) {
    throw 'FFmpeg could not initialize the libx265 HEVC encoder. Install a full FFmpeg build with libx265 support.'
}

$files = @(Get-ChildItem -LiteralPath $inputRoot -Filter '*.mp3' -File -Recurse)
if ($files.Count -eq 0) {
    Write-Host "No MP3 files were found in '$inputRoot'."
    exit 0
}

Write-Host "Found $($files.Count) MP3 file(s)."
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
    $destination = Join-Path $destinationDirectory ($file.BaseName + '.mp4')

    Write-Host "Converting: $relativePath"
    & $ffmpeg.Source -hide_banner -loglevel error -y `
        -f lavfi -i 'color=c=black:s=640x360:r=25' `
        -i $file.FullName `
        -map '0:v:0' -map '1:a:0' -shortest `
        -c:v libx265 -preset ultrafast -pix_fmt yuv420p `
        -tag:v hvc1 `
        -c:a aac -profile:a aac_low -b:a "${AudioBitrateKbps}k" -ar 44100 -ac 2 `
        -disposition:a:0 default `
        -movflags '+faststart' $destination

    if ($LASTEXITCODE -eq 0) {
        $converted++
        Write-Host "Saved:      $destination" -ForegroundColor Green
    } else {
        $failed++
        Remove-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
        Write-Warning "Could not convert '$relativePath'."
    }
}

Write-Host "Finished: $converted converted, $failed failed."
if ($failed -gt 0) {
    exit 1
}
