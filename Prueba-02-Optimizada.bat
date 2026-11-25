@echo off
setlocal
title VIctory - Memoria - logs en vivo
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\Probar-VIctory.ps1" -Variante Memoria %*
set "result=%errorlevel%"
if not defined VICTORY_BATCH_NO_PAUSE pause
exit /b %result%
