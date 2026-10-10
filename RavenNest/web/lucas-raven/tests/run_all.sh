#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
# The glob includes legacy_compat.test.mjs alongside the existing edge suites.
node --test tests/*.test.mjs
(cd ../../workers/raven-cloud-node && node --test tests/*.test.mjs)
