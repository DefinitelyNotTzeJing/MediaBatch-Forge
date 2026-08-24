# Bulk Media Format Converter

A simple Windows utility for converting large collections of media files with
[FFmpeg](https://ffmpeg.org/). It searches through every subfolder in the configured
source directory, converts supported files, and recreates the same folder structure
inside the output directory.

## Features

- Converts files in bulk, including files inside nested subfolders.
- Preserves the original directory structure.
- Supports filenames containing spaces and Unicode characters.
- Uses one configuration file for both source and output locations.
- Provides double-clickable Windows command files.
- Reports successful and failed conversions when finished.

## Included converters

### HEVC video to MP3

`convert-hevc-to-mp3.cmd` extracts the first audio track from supported video files
and saves it as a 192 kbps MP3.

Supported input extensions include:

- `.hevc` and `.h265`
- `.mp4`, `.m4v`, and `.mov`
- `.mkv` and `.avi`
- `.ts`, `.mts`, and `.m2ts`

A video must contain an audio stream to produce an MP3.

### MP3 to HEVC video

`convert-mp3-to-hevc.cmd` turns each MP3 into an MP4 containing:

- A black 640x360 HEVC/H.265 video at 25 FPS.
- AAC-LC stereo audio at 44.1 kHz and 192 kbps.

HEVC is a video codec and cannot store audio by itself, so this converter creates
an `.mp4` container that holds both the HEVC video and converted audio.

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or newer
- FFmpeg with `libx265` support

Install FFmpeg with Windows Package Manager:

```powershell
winget install --id Gyan.FFmpeg --exact
```

After installation, close and reopen PowerShell or File Explorer so Windows can
refresh the system `PATH`.

Verify the installation:

```powershell
ffmpeg -version
```

## Configuration

Edit `paths.json` to choose where files are read from and saved:

```json
{
  "inputFolder": "Source",
  "outputFolder": "Output"
}
```

Relative paths are resolved from the project directory. Absolute Windows paths are
also supported:

```json
{
  "inputFolder": "D:\\My Music",
  "outputFolder": "E:\\Converted Media"
}
```

In JSON, each backslash in an absolute Windows path must be written twice.

## Usage

1. Install FFmpeg and reopen File Explorer.
2. Put the files to convert inside the configured input folder (`Source` by default).
3. Double-click the command file for the required conversion:
   - `convert-hevc-to-mp3.cmd`
   - `convert-mp3-to-hevc.cmd`
4. Wait for the summary showing how many files succeeded or failed.
5. Find the converted files in the configured output folder (`Output` by default).

Existing output files with matching names are overwritten. The source files are
never modified or deleted.

## Optional bitrate setting

The default audio bitrate is 192 kbps. To use a different bitrate, run a converter
from PowerShell and provide a supported value.

HEVC video to MP3 example:

```powershell
.\convert-hevc-to-mp3.ps1 -BitrateKbps 256
```

MP3 to HEVC video example:

```powershell
.\convert-mp3-to-hevc.ps1 -AudioBitrateKbps 256
```

## Troubleshooting

### `ffmpeg was not found`

Install FFmpeg using the command above, then reopen the terminal or File Explorer.

### No supported files were found

Check `inputFolder` in `paths.json` and confirm that the files use an extension
supported by the selected converter. Subfolders are searched automatically.

### A converted HEVC video will not play

The player must support HEVC/H.265 video. Windows may require an HEVC extension, or
you can use a player with built-in HEVC support such as VLC.

### Conversion is slow

HEVC encoding is computationally intensive. Converting thousands of MP3 files into
HEVC videos can take a long time and require substantial storage space.

## Repository folders

The media contents of `Source` and `Output` are excluded from Git by default. Empty
`.gitkeep` files preserve the required folder structure without uploading source or
generated media.
