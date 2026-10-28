"""Compare original executed G5 loader tables with resource bytes and port data."""
import json
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from macresources import resources

native = Path(sys.argv[1])
records = resources((ROOT / "analysis/download-3/AstroSquid.rsrc").read_bytes())
game = json.loads((ROOT / "assets/game.json").read_text())
specs = [("sprt", 14, 1001, "sprites"), ("Attr", 30, 441, "attributes"),
         ("Wpns", 52, 241, "weapons"), ("SPRT", 14, 501, None)]
filenames = {"sprt": "lm-sprt.bin", "Attr": "Attr.bin", "Wpns": "Wpns.bin", "SPRT": "game-SPRT.bin"}
assert len({name.casefold() for name in filenames.values()}) == len(filenames)
fields = {
    "sprt": ["texture", "x", "y", "width", "height", "next_frame", "delay"],
    "Attr": ["speed", "shots_per_second", "weapon", "debris_sprite", "debris_amount",
             "kill_score", "script", "turret_x", "turret_y", "hit_points", "animated",
             "sprite", "death_effect", "unused_1", "unused_2"],
}
for kind, size, count, key in specs:
    expected = bytearray(size * count)
    selected = [r for r in records if r["type"] == kind]
    for record in selected:
        i = record["id"]
        assert 0 <= i < count and len(record["data"]) == size
        expected[i * size:(i + 1) * size] = record["data"]
    assert (native / filenames[kind]).read_bytes() == expected, kind + " native table mismatch"
    if key:
        assert set(game[key]) == {str(r["id"]) for r in selected}
        actual = bytearray(size * count)
        for record in selected:
            i = record["id"]
            entry = game[key][str(i)]
            assert entry["name"] == record["name"]
            if kind == "Wpns":
                assert len(entry["bullets"]) == 6 and all(len(b) == 4 for b in entry["bullets"])
                values = [entry["rate"], entry["header_field_2"]] + [v for b in entry["bullets"] for v in b]
            else:
                values = [entry[f] for f in fields[kind]]
            actual[i * size:(i + 1) * size] = struct.pack(">" + "h" * (size // 2), *values)
        assert actual == expected, kind + " port table mismatch"
    print(f"PASS {kind}: {len(selected)} records, {len(expected)} complete indexed bytes including zero holes")
