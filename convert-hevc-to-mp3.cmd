@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0convert-hevc-to-mp3.ps1" %*
pause
