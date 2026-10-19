"""The coupled comparator must reject one changed state word or clock tick."""
import gzip
from pathlib import Path
import sys
import tempfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from active_special_trace import compare_states, compare_clocks

with tempfile.TemporaryDirectory(prefix='astrosquid-trace-test-') as directory:
    root = Path(directory)
    native = root / 'native.tsv'; host = root / 'host.tsv'
    row = 'Q\t100\treturn\t1\t100\t100\t1\t0\t0\n'
    native.write_text(row + 'V\t100\t1\n'); host.write_text(row)
    assert compare_states(native, host)[0] == 1
    host.write_text(row.replace('return\t1', 'return\t2'))
    try:
        compare_states(native, host)
    except ValueError:
        pass
    else:
        raise AssertionError('changed clock/state word was accepted')
    clocks = root / 'native.csv.gz'; portable = root / 'host.csv'
    with gzip.open(clocks, 'wt') as stream:
        stream.write('0,100343f0,100\n')
    portable.write_text('0,100\n'); assert compare_clocks(clocks, portable) == 1
    portable.write_text('0,101\n')
    try:
        compare_clocks(clocks, portable)
    except ValueError:
        pass
    else:
        raise AssertionError('changed clock value was accepted')
print('PASS coupled trace comparator rejects changed state and clock; presentation boundary explicit')
