@echo off
title Pongz - Open game in ALL running instances
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0open-game.ps1"
echo.
pause
