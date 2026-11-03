#!/usr/bin/env python3
"""Resource fidelity and copy-only linker metadata transformation."""
import importlib.util
import json
from pathlib import Path
import plistlib
import struct
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('sdk', root/'tools/prepare_tiger_sdk.py')
sdk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sdk)
with tempfile.TemporaryDirectory() as folder:
    target = Path(folder)
    (target/'ui').mkdir()
    subprocess.run(['python3', str(root/'tools/tiger_assets.py'), str(root/'assets'), folder], check=True)
    def decode(value):
        if isinstance(value, dict):
            if value == {'__AstroSquidNull__': True}: return None
            return {k: decode(v) for k,v in value.items()}
        if isinstance(value, list): return [decode(v) for v in value]
        return value
    for name in ['game', 'audio', 'ui/ui']:
        assert decode(plistlib.loads((target/(name+'.plist')).read_bytes())) == json.loads((root/'assets'/(name+'.json')).read_bytes())
# Minimal prebound dylib stub: metadata may change, original symbol/string bytes must not.
segment = struct.pack('<II16s8I', 1,56,b'__LINKEDIT',0,4096,180,12,7,1,0,0)
symtab = struct.pack('<6I',2,24,160,1,172,20)
obsolete = struct.pack('<3I',0x1a,12,123)
header = struct.pack('<7I',0xfeedface,7,3,9,3,92,0x10|0x800|0x1000)
original = header+segment+symtab+obsolete+bytes(range(72))
result = sdk.normalize(original)
assert result[120:] == original[120:]
assert struct.unpack_from('<II',result,16) == (2,80)
assert struct.unpack_from('<II',result,60) == (160,32)
assert struct.unpack_from('<I',result,24)[0] == 0
assert sdk.normalize(b'not a dylib') is None
print('PASS all resource values, nulls and CRs preserved; stub symbol bytes unchanged')
