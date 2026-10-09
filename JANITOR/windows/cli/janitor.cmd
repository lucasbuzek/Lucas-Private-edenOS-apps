@echo off
rem JANITOR Windows launcher - runs janitor.ps1 next to this file. Nothing is installed.
rem Works with the Windows PowerShell that ships with Windows 8 and later; Windows 7 SP1 needs WMF 5.1 (janitor.ps1 explains).
where powershell.exe >nul 2>nul
if errorlevel 1 (
  echo JANITOR needs Windows PowerShell, which was not found on this PC. Nothing was changed.
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0janitor.ps1" %*
