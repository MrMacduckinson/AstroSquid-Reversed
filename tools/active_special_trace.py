#!/usr/bin/env python3
"""Compare coupled world state/clock projections; presentation events stay explicit."""
import argparse
import gzip
from collections import Counter
from itertools import zip_longest
from pathlib import Path
import world_trace


def state_projection(path):
    projected = []
    presentation = Counter()
    for number, row in enumerate(Path(path).read_text().splitlines(), 1):
        fields = row.split('\t')
        tag = fields[0]
        if tag in world_trace.FIELDS:
            if len(fields) != len(world_trace.FIELDS[tag]):
                raise ValueError(f'{path}:{number}: invalid {tag} shape')
            projected.append(row)
        elif tag == 'Q':
            if len(fields) != 9:
                raise ValueError(f'{path}:{number}: invalid clock/state shape')
            for index in (1, 3, 4, 5, 6, 7, 8):
                int(fields[index])
            projected.append(row)
        elif tag == 'V':
            if len(fields) != 3:
                raise ValueError(f'{path}:{number}: invalid HUD observer shape')
            int(fields[1]); int(fields[2])
            presentation['HUD observer outside host presentation boundary'] += 1
        else:
            raise ValueError(f'{path}:{number}: unsupported record {tag}')
    return projected, presentation


def compare_states(original, portable):
    native, excluded = state_projection(original)
    host, host_excluded = state_projection(portable)
    if host_excluded:
        raise ValueError('unexpected host presentation records')
    for index, (a, b) in enumerate(zip_longest(native, host), 1):
        if a != b:
            raise ValueError(f'state row {index} differs: original={a} portable={b}')
    return len(native), excluded


def compare_clocks(original, portable):
    count = 0
    with gzip.open(original, 'rt') as native, Path(portable).open() as host:
        for index, (a, b) in enumerate(zip_longest(native, host)):
            if a is None or b is None:
                raise ValueError(f'clock count differs at {index}')
            n, site, tick = a.strip().split(',')
            h, value = b.strip().split(',')
            int(site, 16)  # Original callsite retained; host has no PPC address.
            if int(n) != index or int(h) != index or int(tick) != int(value):
                raise ValueError(f'clock {index} differs: original={a.strip()} portable={b.strip()}')
            count += 1
    return count


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original'); parser.add_argument('portable')
    parser.add_argument('original_clocks'); parser.add_argument('portable_clocks')
    args = parser.parse_args()
    try:
        states, presentation = compare_states(args.original, args.portable)
        clocks = compare_clocks(args.original_clocks, args.portable_clocks)
    except (ValueError, OSError) as error:
        parser.exit(1, str(error) + '\n')
    print(f'PASS: {states} complete Q/G/E/R/S records and {clocks} clock values identical')
    print(f'Presentation excluded explicitly: {dict(presentation)}; original callsites retained, not mapped to host sites')
