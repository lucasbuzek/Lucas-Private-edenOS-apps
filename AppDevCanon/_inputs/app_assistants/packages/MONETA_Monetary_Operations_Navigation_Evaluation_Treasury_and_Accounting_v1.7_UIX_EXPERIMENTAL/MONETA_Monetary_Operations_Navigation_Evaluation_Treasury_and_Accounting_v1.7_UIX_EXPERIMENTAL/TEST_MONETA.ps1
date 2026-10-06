$ErrorActionPreference="Stop"
Set-Location $PSScriptRoot
python 96_BRANCH_TESTS/run_boundary_reconciliation.py
Set-Location 90_BRANCHES\B1_WEB
npm test
node --check src/router.mjs
node --check src/server.mjs
Write-Host "MONETA experimental test gate passed."
