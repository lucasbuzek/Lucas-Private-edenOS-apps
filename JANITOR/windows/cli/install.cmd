@echo off
rem JANITOR Windows CLI installer. Per-user only: no admin rights, no registry, no PATH changes.
rem Copies janitor.cmd + janitor.ps1 to %LOCALAPPDATA%\JANITOR\bin. Remove by deleting that folder.
set "DEST=%LOCALAPPDATA%\JANITOR\bin"
if not exist "%~dp0janitor.ps1" ( echo janitor.ps1 not found next to install.cmd. Nothing was changed. & exit /b 1 )
if not exist "%DEST%" mkdir "%DEST%"
copy /y "%~dp0janitor.ps1" "%DEST%\" >nul && copy /y "%~dp0janitor.cmd" "%DEST%\" >nul
if errorlevel 1 ( echo Copy failed. Nothing else was changed. & exit /b 1 )
echo Installed to %DEST%
echo Run:  "%DEST%\janitor.cmd" help
echo To type just "janitor", add that folder to your user PATH yourself (System - Advanced system settings - Environment Variables).
