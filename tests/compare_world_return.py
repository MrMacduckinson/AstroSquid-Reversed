#!/usr/bin/env python3
"""Compare complete recorded world returns with explicit native/host UI mapping."""
import sys
from pathlib import Path
from compare_menu_return import selected

PHASES = {'panel-ready', 'panel-submit', 'panel-cleanup', 'gameover-tail'}


def canonical(rows, panel_ids=()):
    panel_ids = set(panel_ids)
    lists = {}
    for row in rows:
        f = row.split('\t')
        if f[0] == 'R' and f[2] in PHASES:
            lists.setdefault(f[2], []).append(f)
    for phase, nodes in lists.items():
        for i, node in enumerate(nodes):
            assert node[4] == (nodes[i-1][3] if i else '0'), (phase, 'previous link', node[3])
            assert node[5] == (nodes[i+1][3] if i+1 < len(nodes) else '0'), (phase, 'next link', node[3])
    indexes = {phase: {node[3]: node for node in nodes} for phase, nodes in lists.items()}
    def render_id(value):
        # Native's shared allocator counts the three UI births; host's world allocator does not.
        return str(int(value) - sum(int(p) < int(value) for p in panel_ids))
    output = []
    for row in rows:
        fields = row.split('\t')
        if fields[0] == 'R' and fields[2] in PHASES:
            if fields[3] in panel_ids:
                continue  # UI state is compared separately through U/F records.
            for direction in (4, 5):
                visited = set()
                while fields[direction] in panel_ids:
                    assert fields[direction] not in visited, 'UI list cycle'
                    visited.add(fields[direction])
                    fields[direction] = indexes[fields[2]][fields[direction]][direction]
                fields[direction] = render_id(fields[direction])
            fields[3] = render_id(fields[3])
        if fields[0] == 'E' and fields[2] in PHASES:
            assert fields[4] not in panel_ids, 'entity references UI sprite'
            fields[4] = render_id(fields[4])
        if fields[0] in {'G', 'E', 'R', 'S'}:
            fields[1] = 'T'  # Diagnostic annotation, not a game-state clock.
        output.append('\t'.join(fields))
    return output


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
