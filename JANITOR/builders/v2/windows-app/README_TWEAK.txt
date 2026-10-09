JANITOR Windows app - builder package
=====================================
Two one-click builders, same source:
  Build-JANITOR-WindowsApp-on-Windows.cmd   double-click on a Windows PC
  Build-JANITOR-WindowsApp-on-macOS.command double-click on a Mac (right-click, Open the first time)
Both build src\JANITOR.csproj into output\ . If the .NET SDK is missing they ask before installing it (per user, no admin).

What is in src\
  JANITOR.csproj  - targets .NET Framework 4.5 (runs Windows 7 SP1 to 11), AnyCPU, C# 10 language level.
  Program.cs      - the window (WinForms). It is a thin adapter: it only chooses what to run and asks for confirmation.
  janitor.ps1     - embedded in the exe. ALL real work (scan, quarantine, delete, restore) happens here.
                    This script is the safety contract. Change behaviour here, not in Program.cs.

Easy tweaks
  Version number          JANITOR.csproj  <Version>   (keep it equal to $Version at the top of janitor.ps1)
  Window title / buttons  Program.cs, MainForm constructor
  Quarantine location     janitor.ps1 line starting $QRoot  (and the same default in Program.cs)
  Older or newer .NET     JANITOR.csproj <TargetFramework> (net45 .. net48 are all fine; net6.0-windows or newer drops Windows 7)
  SDK channel             top of either builder script

Rules to keep (the product contract)
  UNKNOWN is not JUNK. Items default to REVIEW, not SAFE, unless a rule proves they are safe.
  Cloud folders (OneDrive, Dropbox, Google Drive, iCloud) are never scanned, hashed or moved.
  Nothing is deleted without a confirmation; quarantine first, with a restore manifest.
  Keep every file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).

Status: source reviewed, NOT yet built or run on Windows. Test on a real PC before sharing widely.
