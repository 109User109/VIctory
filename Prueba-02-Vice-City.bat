@echo off
setlocal
title VIctory - Vice City - logs en vivo
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\Probar-VIctory.ps1" -Variante Memoria -DesdeGuardado -ConfirmarEn 43,105 %*
set "result=%errorlevel%"
if not defined VICTORY_BATCH_NO_PAUSE pause
exit /b %result%
