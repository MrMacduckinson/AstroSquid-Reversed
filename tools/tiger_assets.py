#!/usr/bin/env python
"""Convert the fixed bundled resource tables to Tiger-readable XML plists."""
from __future__ import print_function
import json
import os
import plistlib
import sys
def encode(value):
    if value is None: return {'__AstroSquidNull__': True}
    if isinstance(value, dict):
        assert '__AstroSquidNull__' not in value
        return {key: encode(item) for key,item in value.items()}
    if isinstance(value, list): return [encode(item) for item in value]
    return value

for name in ['game', 'audio', 'ui/ui']:
    with open(os.path.join(sys.argv[1], name+'.json')) as source:
        data = encode(json.load(source))
    target = os.path.join(sys.argv[2], name+'.plist')
    if hasattr(plistlib, 'dump'):
        with open(target, 'wb') as dest:
            plistlib.dump(data, dest, fmt=plistlib.FMT_XML)
    else:
        plistlib.writePlist(data, target)
    with open(target, 'rb') as source: xml = source.read()
    with open(target, 'wb') as dest: dest.write(xml.replace(b'\r', b'&#13;'))
print('Converted game/audio/UI tables to XML property lists')
