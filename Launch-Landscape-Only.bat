@echo off
title Pongz - Launch LANDSCAPE instances only
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-all.ps1" landscape
echo.
pause
