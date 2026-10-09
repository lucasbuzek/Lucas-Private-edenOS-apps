@echo off
rem Builds the JANITOR Windows app (JANITOR.exe, .NET Framework 4.5, AnyCPU: Windows 7 SP1 .. 11).
rem Run on any PC (or Mac/Linux with the dotnet SDK). Needs the .NET SDK 6 or newer: https://dotnet.microsoft.com/download
rem Not run yet. The CLI (..\cli) is the supported Windows edition for now.
where dotnet >nul 2>nul
if errorlevel 1 ( echo .NET SDK not found. Install it first, then run again. Nothing was changed. & exit /b 1 )
cd /d "%~dp0"
dotnet build JANITOR.csproj -c Release -o "%~dp0out"
if errorlevel 1 ( echo Build failed. & exit /b 1 )
echo Built: %~dp0out\JANITOR.exe
