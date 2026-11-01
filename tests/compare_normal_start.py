#!/usr/bin/env python
"""Compare STARTNEWGAME through first gameplay service, with explicit DOMOUSE boundary.

Host enters performMenuAction and emits one upstream Click; native enters
STARTNEWGAME after that Click. Only diagnostic snapshot labels are normalized:
original fixture tick and host simulationTick are not the same clock. All
payloads, actor clocks, ND/NK records and remaining events compare exactly.
"""
import binascii
import gzip
import math
import struct
import sys


def records(path):
    stream = gzip.open(path, 'rb') if path.endswith('.gz') else open(path, 'rb')
    with stream:
        return [line.decode('ascii').rstrip('\n').split('\t') for line in stream]


def compare(native_path, host_path, frames=1):
    frames = int(frames)
    assert 1 <= frames <= 256
    native, host = records(native_path), records(host_path)
    assert len(host) == len(native) + 1, 'unexpected trace length'
    if frames == 1:
        assert len(native) == 6025
    phases = ['normal-ready'] + (['normal-first-game'] if frames == 1 else ['normal-game%d' % i for i in range(1, frames + 1)])
    click = host.pop(0)
    assert len(click) == 5 and click[0] == 'S' and click[2:4] == ['normal-start', '436c69636b'], 'expected exactly one upstream Click'
    position = struct.unpack('>d', binascii.unhexlify(click[4]))[0]
    assert not math.isnan(position) and not math.isinf(position)
    for rows in (native, host):
        assert [row[2] for row in rows if row[0] == 'G'] == phases
        assert sum(row[0] == 'NK' for row in rows) == frames
        grouped = {}
        for row in rows:
            if row[0] == 'NS': grouped.setdefault(row[1], []).append(row)
        assert set(grouped) == set(phases)
        for phase in phases:
            stars = grouped[phase]
            assert len(stars) == 3000 and [int(row[2]) for row in stars] == list(range(3000))
            assert all(len(row) == 4 and len(binascii.unhexlify(row[3])) == 32 for row in stars)
        assert rows[-1] == ['W', 'normal-first-game']
        for row in rows:
            if row[0] in ('G', 'E', 'R', 'S'):
                int(row[1])  # Diagnostic annotation only; entity clocks remain untouched.
                row[1] = '<annotation>'
    for index, (a, b) in enumerate(zip(native, host)):
        assert a == b, 'record %d:\nnative=%r\nhost=%r' % (index, a, b)
    print('PASS %d complete STARTNEWGAME/READY/%d-game-frame records; one explicit upstream Click; diagnostic ticks only normalized' % (len(native), frames))


if __name__ == '__main__':
    if len(sys.argv) not in (3, 4):
        sys.exit('usage: compare_normal_start.py native.tsv[.gz] host.tsv[.gz] [frames]')
    compare(*sys.argv[1:])
