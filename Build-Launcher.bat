@echo off
title Pongz - Build the GUI launcher
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-launcher.ps1"
echo.
pause
