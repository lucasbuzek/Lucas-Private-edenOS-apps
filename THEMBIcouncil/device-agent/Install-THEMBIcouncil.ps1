# THEMBIcouncil owner-initiated Windows endpoint setup.
# Downloads pinned source; does not request admin rights, pair, or run remotely.
$ErrorActionPreference = "Stop"
$dest = Join-Path $env:LOCALAPPDATA "THEMBIcouncil"
$source = "https://raw.githubusercontent.com/lucasbuzek/Lucas-Private-edenOS-apps/5cc421746f8f5e6a258a840c3eee1d79aaaf1ebe/THEMBIcouncil/device-agent/thembicouncil_agent.py"
if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
$target = Join-Path $dest "thembicouncil_agent.py"
if (Test-Path $target) { throw "A connector file already exists. Review it before replacing." }
Invoke-WebRequest -Uri $source -OutFile $target -MaximumRedirection 2 -UseBasicParsing
$body = Get-Content $target -Raw -Encoding UTF8
if (($body.Length -lt 5000) -or (!$body.Contains("THEMBIcouncil device endpoint"))) {
  Remove-Item $target -Force
  throw "The downloaded file did not match the expected Council connector."
}
$python = Get-Command py -ErrorAction SilentlyContinue
if (!$python) { Write-Warning "Python launcher missing. Install Python 3.10+ from python.org/downloads."; exit 1 }
& py -3 -m py_compile $target
if ($LASTEXITCODE -ne 0) { throw "Python compilation failed." }
Write-Host ""
Write-Host "THEMBIcouncil connector saved: $target"
Write-Host "Pair only after your own Council gives a one-time pairing code:"
Write-Host ('py -3 "' + $target + '" pair --label "Thembi Windows" --root "$HOME\Documents"')
Write-Host "After pairing, use:"
Write-Host ('py -3 "' + $target + '" run')
Write-Host "Each device action requires YES from the local operator. No hidden background agent was installed."
