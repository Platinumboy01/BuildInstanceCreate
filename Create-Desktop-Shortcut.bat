@echo off
title Pongz - Create Desktop shortcut
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-shortcut.ps1"
echo.
pause
