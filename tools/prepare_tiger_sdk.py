#!/usr/bin/env python
"""Make an isolated i386 link-stub copy of a prebound Tiger SDK for newer ld64.
Keep all exported symbols/addresses. Strip obsolete prebinding commands and
correct the __LINKEDIT file range; never alter the source SDK or installed OS.
"""
from __future__ import print_function
import os
import shutil
import struct
import sys

def normalize(data):
    if data[:4] == b'\xca\xfe\xba\xbe':
        count = struct.unpack_from('>I', data, 4)[0]
        selected = None
        for i in range(count):
            cpu, subtype, offset, size, align = struct.unpack_from('>IIIII', data, 8+20*i)
            if cpu == 7: selected = data[offset:offset+size]; break
        if selected is None: return None
        data = selected
    if data[:4] != b'\xce\xfa\xed\xfe': return None
    header = list(struct.unpack_from('<7I', data))
    if header[1] != 7 or header[3] not in (6,9): return None
    commands = []; offset = 28; symbol_start = None
    for i in range(header[4]):
        kind, size = struct.unpack_from('<II', data, offset)
        assert size >= 8 and offset+size <= 28+header[5]
        command = bytearray(data[offset:offset+size]); offset += size
        if kind == 2:
            symoff, nsyms, stroff, strsize = struct.unpack_from('<4I', command, 8)
            assert symoff+nsyms*12 <= len(data) and stroff+strsize <= len(data)
            symbol_start = min(symoff,stroff)
        if kind not in (0x17,0x1a): commands.append(command)
    if symbol_start is not None:
        for command in commands:
            if struct.unpack_from('<I',command)[0] == 1 and bytes(command[8:24]).rstrip(b'\0') == b'__LINKEDIT':
                oldstart = struct.unpack_from('<I',command,32)[0]
                start = min(oldstart,symbol_start)
                struct.pack_into('<II',command,32,start,len(data)-start)
                struct.pack_into('<I',command,28,(len(data)-start+4095)&~4095)
    oldsize = header[5]; header[4] = len(commands); header[5] = sum(len(c) for c in commands)
    header[6] &= ~(0x10|0x800|0x1000)
    merged = b''.join(bytes(c) for c in commands)
    return struct.pack('<7I',*header)+merged+b'\0'*(oldsize-len(merged))+data[28+oldsize:]

if __name__ == '__main__':
    source, target = map(os.path.abspath,sys.argv[1:])
    assert source != target and not os.path.exists(target)
    shutil.copytree(source,target,symlinks=True)
    changed=0
    for folder, dirs, files in os.walk(target):
        for name in files:
            path=os.path.join(folder,name)
            if os.path.islink(path): continue
            with open(path,'rb') as f: data=f.read()
            output=normalize(data)
            if output is not None:
                with open(path,'wb') as f:f.write(output)
                changed+=1
    print('Prepared isolated i386 SDK link stubs:',changed)
