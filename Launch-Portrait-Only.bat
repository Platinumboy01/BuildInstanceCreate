@echo off
title Pongz - Launch PORTRAIT instances only
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-all.ps1" portrait
echo.
pause
