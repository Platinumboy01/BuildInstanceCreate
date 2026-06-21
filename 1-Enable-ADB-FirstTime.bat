@echo off
title Pongz - STEP 1: Enable ADB (run once on a new PC)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enable-adb.ps1"
echo.
pause
