#!/bin/sh
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec /usr/bin/env python3 "$DIR/IRIS_v1.8_LAUNCH.py" "${1:-visual}"
