#!/usr/bin/env python3
"""Select a reachable physical iPhone/iPad using devicectl JSON, not table widths."""
import json
import sys

result = json.load(open(sys.argv[1]))
assert result.get('info', {}).get('outcome') == 'success', 'device enumeration unsuccessful'
candidates = []
for device in result['result']['devices']:
    properties = device.get('properties', {})
    hardware = properties.get('hardware', device.get('hardwareProperties', {}))
    connection = properties.get('connection', device.get('connectionProperties', {}))
    state = connection.get('state', connection.get('tunnelState'))
    kind = hardware.get('deviceType')
    if kind in ('iPhone', 'iPad') and hardware.get('reality') == 'physical' and state in ('connected', 'available'):
        candidates.append((kind != 'iPhone', device['identifier']))
if candidates:
    print(sorted(candidates)[0][1])
