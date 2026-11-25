@echo off
setlocal
title VIctory - Memoria Series S - logs en vivo
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\Probar-VIctory.ps1" -Variante Memoria -SerieS %*
set "result=%errorlevel%"
if not defined VICTORY_BATCH_NO_PAUSE pause
exit /b %result%
