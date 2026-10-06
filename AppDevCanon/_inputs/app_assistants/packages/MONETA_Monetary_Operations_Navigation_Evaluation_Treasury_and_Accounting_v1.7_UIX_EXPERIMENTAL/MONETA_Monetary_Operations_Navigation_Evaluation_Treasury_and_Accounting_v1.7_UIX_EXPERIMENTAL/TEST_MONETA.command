#!/bin/sh
set -e
cd "$(dirname "$0")"
python3 96_BRANCH_TESTS/run_boundary_reconciliation.py
cd 90_BRANCHES/B1_WEB
npm test
node --check src/router.mjs
node --check src/server.mjs
echo "MONETA experimental test gate passed."
