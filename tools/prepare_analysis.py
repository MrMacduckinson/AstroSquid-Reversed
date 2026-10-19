"""Prepare isolated, traceable Ghidra views of FutureBASIC's FCOD container."""
import argparse
import json
from pathlib import Path
import re
import struct

from macresources import inspect


def prepare(app, output):
    inspect(app, output)
    original = (output / 'AstroSquid.pef').read_bytes()
    view = bytearray((output / 'AstroSquid.analysis-expanded.pef').read_bytes())
    code_start = struct.unpack_from('>I', view, 60)[0]
    code_length = struct.unpack_from('>I', view, 56)[0]
    code = original[code_start:code_start+code_length]
    previous = 0x60
    rows = []
    for marker in re.finditer(rb'\x4e\x75\x80[\x01-\x7f]([_A-Za-z][ -~]{2,80})',code):
        size = code[marker.start()+3]
        name = code[marker.start()+4:marker.start()+4+size].decode('ascii').rstrip('.')
        rows.append((0x10000000+previous+4,name,0x10000000+marker.start()))
        previous = (marker.start()+4+size+3) & ~3
    # Names are candidate entry associations; PrepareAstro.java renames only
    # entries that Ghidra actually recognized, leaving unmatched entries alone.
    (output / 'function-names.tsv').write_text(''.join(f'{a:08x}\t{n}\t{end:08x}\n' for a,n,end in rows))
    changes = []
    for offset in range(code_start,code_start+code_length,4):
        value = struct.unpack_from('>I',view,offset)[0]
        if value & 0xfc6007ff == 0xfc200000:
            canonical = value & ~0x200000
            struct.pack_into('>I',view,offset,canonical)
            changes.append(dict(file_offset=offset,address=hex(0x10000000+offset-code_start),
                                original=hex(value),analysis=hex(canonical)))
    (output / 'compare-normalizations.json').write_text(json.dumps(changes,indent=2)+'\n')
    (output / 'AstroSquid.analysis-normalized.pef').write_bytes(view)
    print(f'Analysis copy: {len(rows)} name markers, {len(changes)} reserved-bit compare normalizations')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('application',type=Path)
    p.add_argument('output',type=Path)
    a = p.parse_args()
    prepare(a.application,a.output)
