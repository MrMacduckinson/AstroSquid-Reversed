#!/usr/bin/env python3
"""Compare complete recorded world returns with explicit native/host UI mapping."""
import sys
from pathlib import Path
from compare_menu_return import selected

from world_ui_mapping import PHASES, canonical


def compare(native_path, host_path):
    assert selected(native_path) == selected(host_path), 'menu return differs'
    native, host = [Path(p).read_text().splitlines() for p in (native_path, host_path)]
    ids = lambda phase: {r.split('\t')[3] for r in native
                         if r.startswith('R\t') and r.split('\t')[2] == phase}
    panel_ids = ids('panel-ready') - ids('warm9')
    assert len(panel_ids) == 3, 'expected three native panel nodes'
    for rows in (native, host):
        assert sum(r.startswith('U\t') for r in rows) == 3
        assert sum(r.startswith('F\t') for r in rows) == 1
        qualified = any(r.startswith('Q\t') for r in rows)
        assert ('F\tinactive' in rows) == (not qualified), 'field activation differs from score insertion'
        required = PHASES if qualified else PHASES - {'panel-submit'}
        for phase in required:
            assert any(r.startswith('G\t') and r.split('\t')[2] == phase for r in rows)
    a, b = canonical(native, panel_ids), canonical(host)
    assert len(a) == len(b), f'record counts differ: {len(a)} / {len(b)}'
    for i, (x, y) in enumerate(zip(a, b)):
        assert x == y, f'record {i}:\nnative: {x}\nhost: {y}'
    print(f'PASS {len(a)} canonical records across recorded world, panel and menu return')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit('usage: compare_world_return.py native.tsv host.tsv')
    compare(*sys.argv[1:])
