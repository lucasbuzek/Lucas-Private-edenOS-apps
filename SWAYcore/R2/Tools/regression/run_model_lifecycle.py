#!/usr/bin/env python3
"""Compile unchanged Foundation-only production declarations; no model reimplementation.
This proves serialization/validation only. It does not exercise SwayStore, UI or native sharing.
"""
import os,pathlib,subprocess,tempfile
root=pathlib.Path(__file__).resolve().parents[2]
source=(root/'App/SWAY/Models/Move.swift').read_text()
models=source[:source.index('// MARK: - SWAY Music Core')]+'\n'+source[source.index('enum SwayBodyStyle:'):source.index('enum SwayAwardID:')]
with tempfile.TemporaryDirectory(prefix='sway-model-regression-') as tmp:
    tmp=pathlib.Path(tmp);path=tmp/'models.swift';path.write_text(models)
    env=dict(os.environ);env.setdefault('CLANG_MODULE_CACHE_PATH',str(tmp/'module-cache'))
    subprocess.run(['swiftc',str(path),str(root/'Tools/regression/sway_model_lifecycle.swift'),'-o',str(tmp/'regression')],env=env,check=True)
    subprocess.run([str(tmp/'regression')],check=True)
