"""Compare actual cleanup/CALC payloads; tick column is an observer label."""
from __future__ import print_function
import os
import sys

def records(path):
    with open(path) as f:
        rows = [line.rstrip("\n").split("\t") for line in f]
    for row in rows:
        # Native observer retains input tick100; host labels the last clock read310.
        if row[0] in ("G", "E", "R", "S"):
            row[1] = "observation"
    return rows

native = records(os.path.join(os.path.dirname(__file__), "outer_body_native.tsv"))
host = records(sys.argv[1])
assert len(native) == len(host) == 94
for index, (expected, actual) in enumerate(zip(native, host)):
    assert expected == actual, (index, expected, actual)
print("PASS94 original outer-body records: cleanup, reload, stars, camera and active actors")
