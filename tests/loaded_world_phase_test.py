"""Check the complete original star/parallax state after the first loaded-world CALC."""
from __future__ import print_function
import hashlib
import json
import os
import sys

with open(os.path.join(os.path.dirname(__file__), 'loaded_world_phase_reference.json')) as f:
    reference = json.load(f)
with open(sys.argv[1], 'rb') as f:
    data = f.read()
assert len(data) == reference['bytes']
assert hashlib.sha256(data).hexdigest() == reference['sha256']
print('PASS96060 original first-CALC star/parallax bytes and loaded-to-active viewport phase')
