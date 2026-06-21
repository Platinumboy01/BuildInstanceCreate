@echo off
title Pongz - Show Home screen on boot (not Store)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0set-home-on-boot.ps1"
echo.
pause
