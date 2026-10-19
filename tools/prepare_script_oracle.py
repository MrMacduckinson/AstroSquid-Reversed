"""Generate original resource tables and public import names for the G5 oracle."""
from pathlib import Path
import argparse
import json
import struct
from macresources import resources

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('application',type=Path)
p.add_argument('export',type=Path)
p.add_argument('output',type=Path)
a=p.parse_args()
a.output.mkdir(parents=True,exist_ok=True)
records=resources(Path(str(a.application)+'/..namedfork/rsrc').read_bytes())
for kind,size,count in [('Attr',30,441),('sprt',14,1001),('Wpns',52,241)]:
    table=bytearray(size*count)
    for r in records:
        if r['type']==kind:
            assert 0<=r['id']<count and len(r['data'])==size
            table[r['id']*size:(r['id']+1)*size]=r['data']
    (a.output/(kind+'.bin')).write_bytes(table)
blocks=[r.split('\t') for r in (a.export/'blocks.tsv').read_text().splitlines()]
base=int(next(r[1] for r in blocks if r[0]=='UnpackedData'),16)
names={}
for row in (a.export/'symbols.tsv').read_text().splitlines()[1:]:
    address,typ,name=row.split('\t',2)
    if name.startswith('.TVect::'):
        names[(int(address,16)-base)//4]=name.split('::',1)[1]
assert len(names)==484 and set(names)==set(range(484))
(a.output/'imports.h').write_text('static const char *import_names[484]={\n'+
    ',\n'.join(json.dumps(names[i]) for i in range(484))+'\n};\n')
print('Prepared 484 original import names and three indexed resource tables')
