#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
node --test tests/*.test.mjs
(cd ../../workers/raven-cloud-node && node --test tests/*.test.mjs)
