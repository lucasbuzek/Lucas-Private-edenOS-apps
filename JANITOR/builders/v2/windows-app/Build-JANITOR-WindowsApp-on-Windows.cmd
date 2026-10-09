@echo off
setlocal
rem JANITOR Windows app - ONE-CLICK BUILDER for Windows. Produces JANITOR.exe (.NET Framework 4.5, AnyCPU).
rem Needs the .NET SDK. If missing, offers a per-user install (no admin rights) and asks first.
rem Tweak: SDK_CHANNEL below, or the project in .\src (JANITOR.csproj, Program.cs; janitor.ps1 is embedded and does the real work).
rem Build PC: SDK 8.0 needs Windows 10 or newer. On Windows 7/8.1 set SDK_CHANNEL=6.0.

set "SDK_CHANNEL=8.0"

cd /d "%~dp0"
if not exist "src\JANITOR.csproj" ( echo src\JANITOR.csproj not found next to this script. & goto :end )
set "DOTNET="
where dotnet >nul 2>nul && set "DOTNET=dotnet"
if not defined DOTNET if exist "%LOCALAPPDATA%\JANITOR-dotnet\dotnet.exe" set "DOTNET=%LOCALAPPDATA%\JANITOR-dotnet\dotnet.exe"
if defined DOTNET goto :build

echo The .NET SDK was not found.
echo I can install it for your user only (about 200 MB, into %LOCALAPPDATA%\JANITOR-dotnet, no admin rights).
echo It is downloaded from https://dot.net/v1/dotnet-install.ps1 (Microsoft).
choice /c YN /m "Install it now"
if errorlevel 2 ( echo Cancelled. Nothing was changed. Install the .NET SDK yourself, then run this again. & goto :end )
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('https://dot.net/v1/dotnet-install.ps1', $env:TEMP + '\dotnet-install.ps1'); & ($env:TEMP + '\dotnet-install.ps1') -Channel %SDK_CHANNEL% -InstallDir ($env:LOCALAPPDATA + '\JANITOR-dotnet')"
if errorlevel 1 ( echo SDK install failed. Nothing else was changed. & goto :end )
set "DOTNET=%LOCALAPPDATA%\JANITOR-dotnet\dotnet.exe"

:build
echo Building JANITOR Windows app...
if exist output rmdir /s /q output
mkdir output\app
"%DOTNET%" build "src\JANITOR.csproj" -c Release -o "output\app" > output\build.log 2>&1
if errorlevel 1 ( type output\build.log & echo. & echo BUILD FAILED - full log: %~dp0output\build.log & goto :end )
if not exist "output\app\JANITOR.exe" ( echo JANITOR.exe was not produced - see output\build.log & goto :end )
echo STATE: BUILT. Not tested on this PC until you run it. > output\BUILD_RECORD.txt
echo.
echo DONE: %~dp0output\app\JANITOR.exe
echo Double-click JANITOR.exe to run. Windows SmartScreen may warn because the app is not signed.

:end
echo.
pause
endlocal
