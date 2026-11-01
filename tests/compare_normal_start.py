#!/usr/bin/env python
"""Compare STARTNEWGAME through first gameplay service, with explicit DOMOUSE boundary.

Host enters performMenuAction and emits one upstream Click; native enters
STARTNEWGAME after that Click. Only diagnostic snapshot labels are normalized:
original fixture tick and host simulationTick are not the same clock. All
payloads, actor clocks, ND/NK records and remaining events compare exactly.
"""
import binascii
import io
import math
import struct
import sys


def records(path):
    with io.open(path, encoding='ascii') as stream:
        return [line.rstrip('\n').split('\t') for line in stream]


def compare(native_path, host_path):
    native, host = records(native_path), records(host_path)
    assert len(native) == 6025 and len(host) == 6026, 'unexpected trace length'
    click = host.pop(0)
    assert len(click) == 5 and click[0] == 'S' and click[2:4] == ['normal-start', '436c69636b'], 'expected exactly one upstream Click'
    position = struct.unpack('>d', binascii.unhexlify(click[4]))[0]
    assert not math.isnan(position) and not math.isinf(position)
    assert not any(row[0] == 'S' for row in native + host), 'unexpected additional sound'
    for rows in (native, host):
        assert sum(row[0] in ('G', 'E', 'R') for row in rows) == 20
        for phase in ('normal-ready', 'normal-first-game'):
            stars = [row for row in rows if row[:2] == ['NS', phase]]
            assert len(stars) == 3000 and [int(row[2]) for row in stars] == list(range(3000))
            assert all(len(row) == 4 and len(binascii.unhexlify(row[3])) == 32 for row in stars)
        assert rows[-1] == ['W', 'normal-first-game']
        for row in rows:
            if row[0] in ('G', 'E', 'R', 'S'):
                int(row[1])  # Diagnostic annotation only; entity clocks remain untouched.
                row[1] = '<annotation>'
    for index, (a, b) in enumerate(zip(native, host)):
        assert a == b, 'record %d:\nnative=%r\nhost=%r' % (index, a, b)
    print('PASS 6025 complete STARTNEWGAME/READY/first-game records; one explicit upstream Click; diagnostic ticks only normalized')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit('usage: compare_normal_start.py native.tsv host.tsv')
    compare(*sys.argv[1:])
