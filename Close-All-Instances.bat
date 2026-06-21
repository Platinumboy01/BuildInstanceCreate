@echo off
title Pongz - Close all BlueStacks instances
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0close-all.ps1"
echo.
pause
