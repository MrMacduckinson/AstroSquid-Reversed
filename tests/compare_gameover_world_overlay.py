#!/usr/bin/env python3
"""Full retained-world comparison with explicit shared-list/UI mapping."""
import gzip
import sys
import io
from world_ui_mapping import canonical


def read(path):
    return (gzip.open(path, 'rb').read().decode('ascii') if str(path).endswith('.gz')
            else io.open(path, encoding='ascii').read()).splitlines()


def compare(native_path, host_path):
    native, host = read(native_path), read(host_path)
    ids = lambda phase: {r.split('\t')[3] for r in native
                         if r.startswith('R\t') and r.split('\t')[2] == phase}
    panel_ids = ids('panel-ready') - ids('warm9')
    assert len(panel_ids) == 3
    for rows in (native, host):
        assert rows[-1] == 'W\tcleanup-complete'
        sprites = [int(r.split('\t')[4]) for r in rows if r.startswith('P\toverlay\t0\t')]
        assert sprites in ([900, 900, 900, 900, 900, 901, 901],
                           [900, 902, 902, 902, 900, 901, 901])
        assert sum(r.startswith('OC\t') for r in rows) == 7
        assert sum(r.startswith('P\toverlay\t') for r in rows) == 21
        for phase, count in [('panel-ready', 3), ('panel-submit', 3), ('panel-cleanup', 1)]:
            assert sum(r.startswith('P\t' + phase + '\t') for r in rows) == count
        assert sum(r.startswith('U\t') for r in rows) == 3
        assert sum(r.startswith('F\t') for r in rows) == 1
        assert sum(r.startswith('H\t') for r in rows) == 10
    # Native's three UI nodes share the world render list; host stores UI apart.
    # P records retain their full geometry/type/deadline/counter at each boundary.
    # Only the existing diagnostic tick and shared allocator/list mapping differ.
    a, b = canonical(native, panel_ids), canonical(host)
    assert len(a) == len(b), (len(a), len(b))
    for i, (x, y) in enumerate(zip(a, b)):
        assert x == y, 'record %d:\nnative %s\nhost %s' % (i, x, y)
    print('PASS %d complete world/HUD/overlay records' % len(a))


if __name__ == '__main__':
    assert len(sys.argv) == 3
    compare(*sys.argv[1:])
