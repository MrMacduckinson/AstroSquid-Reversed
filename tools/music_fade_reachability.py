#!/usr/bin/env python3
"""Bounded static entry-reference audit; does not prove dynamic unreachability."""
import hashlib
import json
from pathlib import Path


def branch_target(word, address):
    opcode = word >> 26
    if opcode == 18:
        displacement, sign, modulus = word & 0x03FFFFFC, 0x02000000, 0x04000000
    elif opcode == 16:
        displacement, sign, modulus = word & 0xFFFC, 0x8000, 0x10000
    else:
        return None
    if displacement & sign:
        displacement -= modulus
    return (displacement if word & 2 else address + displacement) & 0xFFFFFFFF


def audit(root):
    targets = {0x10033254: "FADETRACKOUT", 0x10033374: "FADETRACKIN",
               0x10033030: "MWDOMUSICFADING"}
    blobs = {p.name: p.read_bytes() for p in sorted(root.glob("*.bin"))}
    code = blobs["Code.bin"]
    entries = {name: {"address": f"{address:08x}", "direct_branches": [],
                      "literal_references": []} for address, name in targets.items()}
    for offset in range(0, len(code) - 3, 4):
        address = 0x10000000 + offset
        target = branch_target(int.from_bytes(code[offset:offset + 4], "big"), address)
        if target in targets:
            entries[targets[target]]["direct_branches"].append(f"{address:08x}")
    for address, name in targets.items():
        needle = address.to_bytes(4, "big")
        for filename, data in blobs.items():
            start = 0
            while True:
                offset = data.find(needle, start)
                if offset < 0:
                    break
                entries[name]["literal_references"].append({"file": filename, "offset": offset})
                start = offset + 1
    return {"entries": entries,
            "inputs": {name: {"size": len(data), "sha256": hashlib.sha256(data).hexdigest()}
                       for name, data in blobs.items()},
            "limits": ["Static scan of aligned PPC b/bc entry targets and all byte-aligned address literals only",
                       "Computed pointers, relocations, interior entry points and external callers not resolved",
                       "No runtime observation or proof of whole-program unreachability"]}


if __name__ == "__main__":
    assert branch_target(0x48000005, 0x1000) == 0x1004
    assert branch_target(0x4BFFFFFD, 0x1000) == 0x0FFC
    assert branch_target(0x48000006, 0x1000) == 4
    assert branch_target(0x4182FFFC, 0x1000) == 0x0FFC
    assert branch_target(0x60000000, 0x1000) is None
    root = Path(__file__).resolve().parents[1] / "analysis/decompilation-typed-fixed"
    print(json.dumps(audit(root), indent=2))
