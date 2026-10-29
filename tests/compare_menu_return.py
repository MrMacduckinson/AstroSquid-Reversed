#!/usr/bin/env python3
"""Compare native/host continuous-world menu-return traces, not whole-game parity."""
import sys
from collections import Counter
from pathlib import Path


def selected(path):
    lines = Path(path).read_text().splitlines()
    counts = Counter(line.split('\t', 1)[0] for line in lines)
    for tag, expected in [('MENU', 1), ('MS', 3000), ('MU', 52),
                          ('RETURN-FLUSH', 1), ('RETURN', 1)]:
        if counts[tag] != expected:
            raise AssertionError(f'{path}: {tag}: {counts[tag]}, expected {expected}')
    if lines[-4:-1] != ['RETURN-FLUSH', 'A\tstop', 'A\tplay1'] or not lines[-1].startswith('RETURN\t'):
        raise AssertionError(f'{path}: missing completed return protocol')
    tags = {'MENU', 'MS', 'MU', 'RETURN-FLUSH', 'RETURN', 'A'}
    return [line for line in lines if line.split('\t', 1)[0] in tags]


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit('usage: compare_menu_return.py native.tsv host.tsv')
    native, host = map(selected, sys.argv[1:])
    if len(native) != len(host):
        raise AssertionError(f'record counts differ: {len(native)} / {len(host)}')
    for index, (a, b) in enumerate(zip(native, host)):
        if a != b:
            raise AssertionError(f'record {index}:\nnative: {a}\nhost:   {b}')
    print(f'PASS {len(native)} selected menu-state and return-protocol records')
