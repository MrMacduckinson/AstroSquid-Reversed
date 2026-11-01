#!/usr/bin/env python
"""Stream complete normal-start traces; exclude one upstream DOMOUSE Click only.

Only G/E/R/S diagnostic tick annotations differ in meaning between harnesses.
All state, star, sound, actor-clock and NK/ND payloads compare exactly.
"""
import binascii
import gzip
import itertools
import math
import struct
import sys


def records(path):
    stream = gzip.open(path, 'rb') if path.endswith('.gz') else open(path, 'rb')
    try:
        for line in stream:
            yield line.decode('ascii').rstrip('\n').split('\t')
    finally:
        stream.close()


def compare(native_path, host_path, frames=1, terminal='limit'):
    frames = int(frames)
    assert 1 <= frames <= 1024 and terminal in ('limit', 'gameover')
    native, host = records(native_path), records(host_path)
    click = next(host)
    assert len(click) == 5 and click[0] == 'S' and click[2:4] == ['normal-start', '436c69636b'], 'expected one upstream Click'
    position = struct.unpack('>d', binascii.unhexlify(click[4]))[0]
    assert not math.isnan(position) and not math.isinf(position)
    pairs = getattr(itertools, 'izip_longest', None) or itertools.zip_longest
    phase = None
    stars = states = clocks = games = delays = reasons = endings = count = 0
    ended = False
    for count, (a, b) in enumerate(pairs(native, host), 1):
        assert a is not None and b is not None, 'trace length mismatch'
        assert not ended, 'records after terminal'
        if a[0] in ('G', 'E', 'R', 'S'):
            int(a[1]); int(b[1])
            a[1] = b[1] = '<annotation>'
        assert a == b, 'record %d:\nnative=%r\nhost=%r' % (count, a, b)
        tag = a[0]
        if tag == 'G':
            assert phase is None or stars == 3000, 'incomplete star state'
            if states == 0:
                assert a[2] == 'normal-ready'
            elif a[2] == 'normal-gameover':
                assert terminal == 'gameover' and games < frames
            else:
                games += 1
                assert games <= frames
                assert a[2] == ('normal-first-game' if frames == 1 else 'normal-game%d' % games)
            phase = a[2]; stars = 0; states += 1
        elif tag == 'NS':
            assert len(a) == 4 and a[1] == phase and int(a[2]) == stars
            assert len(binascii.unhexlify(a[3])) == 32
            stars += 1
            assert stars <= 3000
        elif tag == 'NK':
            assert stars == 3000 and phase != 'normal-ready'
            clocks += 1
            assert clocks == states - 1
        elif tag == 'ND':
            assert phase == 'normal-ready' and a[1] == '60'
            delays += 1
        elif tag == 'NT':
            assert a == ['NT', terminal]
            reasons += 1
            if terminal == 'gameover':
                assert phase == 'normal-gameover'
                ended = True
        elif tag == 'W':
            assert terminal == 'limit' and a == ['W', 'normal-first-game']
            endings += 1; ended = True
    assert ended and stars == 3000 and delays == 1 and clocks == states - 1
    if terminal == 'gameover':
        assert reasons == 1 and endings == 0 and clocks == games + 1
    else:
        assert games == frames and clocks == frames and endings == 1
        assert reasons == (1 if frames > 256 else 0)
    print('PASS %d complete records, %d service states, terminal %s; explicit upstream Click; diagnostic ticks only normalized' % (count, clocks, terminal))


if __name__ == '__main__':
    if len(sys.argv) not in (3, 4, 5):
        sys.exit('usage: compare_normal_start.py native.tsv[.gz] host.tsv[.gz] [budget] [limit|gameover]')
    compare(*sys.argv[1:])
