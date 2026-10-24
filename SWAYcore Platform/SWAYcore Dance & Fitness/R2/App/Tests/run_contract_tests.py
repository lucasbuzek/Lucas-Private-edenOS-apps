#!/usr/bin/env python3
import importlib.util, inspect, pathlib, sys
p=pathlib.Path(__file__).with_name('test_full_feature_alpha_package.py')
spec=importlib.util.spec_from_file_location('alpha_contract',p); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
tests=sorted((n,f) for n,f in vars(m).items() if n.startswith('test_') and callable(f) and not inspect.signature(f).parameters)
failed=[]
for n,f in tests:
    try: f(); print('PASS',n)
    except Exception as e: failed.append((n,e)); print('FAIL',n,repr(e))
print(f'CONTRACT_TESTS {len(tests)-len(failed)}/{len(tests)} PASS')
sys.exit(bool(failed))
