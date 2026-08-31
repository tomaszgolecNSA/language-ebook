@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-kindle.ps1" %*
exit /b %ERRORLEVEL%

