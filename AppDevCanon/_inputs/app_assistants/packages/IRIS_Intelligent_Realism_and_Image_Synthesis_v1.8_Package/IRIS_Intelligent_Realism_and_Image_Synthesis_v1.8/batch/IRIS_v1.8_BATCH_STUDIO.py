#!/usr/bin/env python3
import runpy,sys
from pathlib import Path
p=Path(__file__).resolve().parent.parent/'IRIS_v1.8_LAUNCH.py'
sys.argv=[str(p),'batch',*sys.argv[1:]]
runpy.run_path(str(p),run_name='__main__')
