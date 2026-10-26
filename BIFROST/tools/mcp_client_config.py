#!/usr/bin/env python3
"""Print a local client configuration fragment; never overwrite client settings."""
import json
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
print(json.dumps({'mcpServers':{'BIFROSTbridge-local':{'command':sys.executable,'args':['-B',str(root/'headless/mcp_bridge.py')]}}},indent=2))
