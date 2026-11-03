#!/usr/bin/env python3
"""Static compatibility checks, not a claim of execution on Lion."""
import pathlib
import plistlib
import re
import subprocess
import sys
app = pathlib.Path(sys.argv[1])
exe = app / 'Contents/MacOS/AstroSquid'
def output(*args):
    return subprocess.check_output(args, text=True)
assert output('lipo', '-archs', str(exe)).strip() == 'x86_64'
assert plistlib.loads((app / 'Contents/Info.plist').read_bytes())['LSMinimumSystemVersion'] == '10.7'
assert re.search(r'LC_VERSION_MIN_MACOSX\s+cmdsize\s+\d+\s+version\s+10\.7', output('otool', '-l', str(exe)))
symbols = output('nm', '-u', str(exe))
for symbol in ['AVAudioEngine', 'AVAudioPlayerNode', 'AVAudioPCMBuffer', 'AVAudioFile', 'AVAudioTime']:
    assert symbol not in symbols, symbol
all_symbols = output('nm', str(exe))
for symbol in ['__arclite_NSArray_objectAtIndexedSubscript', '__arclite_NSDictionary_objectForKeyedSubscript']:
    assert symbol in all_symbols, symbol
print('PASS x86_64 / 10.7 Mach-O and plist, no AVAudioEngine imports, libarclite subscripting present')
