@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0convert-mp3-to-hevc.ps1" %*
pause
