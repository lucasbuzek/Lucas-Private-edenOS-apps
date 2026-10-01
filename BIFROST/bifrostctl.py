#!/usr/bin/env python3
import json
from bifrost.remote_provider import RemoteProvider

if __name__ == "__main__":
    print(json.dumps(RemoteProvider().status(), indent=2))
