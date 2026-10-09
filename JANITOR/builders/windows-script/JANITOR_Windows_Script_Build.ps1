$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $MyInvocation.MyCommand.Path
$Out=Join-Path $Root 'output'; Remove-Item $Out -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $Out|Out-Null
$Core=@'
$ErrorActionPreference='Continue'
function Menu { Clear-Host; 'JANITOR — Windows Script'; '1 Quick Scan'; '2 Running Processes'; '3 Services'; '0 Exit' }
while($true){ Menu; switch(Read-Host 'Choose'){
'1'{Get-PSDrive C|Format-Table Name,Used,Free; Read-Host 'Enter'}
'2'{Get-Process|Sort-Object CPU -Descending|Select-Object -First 60 Id,ProcessName,CPU,WorkingSet|Format-Table; $p=Read-Host 'PID to stop or Enter'; if($p -match '^\d+$' -and (Read-Host 'Stop? y/N') -match '^[Yy]$'){Stop-Process -Id $p}}
'3'{Get-Service|Sort-Object Status,DisplayName|Format-Table Status,Name,DisplayName; $n=Read-Host 'Service name or Enter'; if($n){$a=Read-Host 'S start / T stop / R restart / E enable / D disable'; switch($a.ToUpper()){'S'{Start-Service $n}'T'{Stop-Service $n}'R'{Restart-Service $n}'E'{Set-Service $n -StartupType Automatic}'D'{Set-Service $n -StartupType Disabled}}}; Read-Host 'Enter'}
'0'{exit}}}
'@
Set-Content (Join-Path $Out 'JANITOR.ps1') $Core -Encoding UTF8
Set-Content (Join-Path $Out 'JANITOR.cmd') '@echo off`r`npowershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0JANITOR.ps1"' -Encoding ASCII
Compress-Archive "$Out\JANITOR.ps1","$Out\JANITOR.cmd" (Join-Path $Out 'JANITOR-Windows-Script.zip') -Force
Write-Host "BUILT: $Out"