#!/usr/bin/env python3
"""Prepare controlled PPC/Intel framebuffer inputs; performs no runtime rendering."""
import json
from pathlib import Path
import shutil
import struct
import sys
from PIL import Image

if len(sys.argv) != 4:
    raise SystemExit("usage: prepare_framebuffer_inputs.py ASSETS ANALYSIS_DIRECTORY OUTPUT_DIRECTORY")
assets, analysis, output = map(Path, sys.argv[1:])
game = json.loads((assets / "game.json").read_text())
output.mkdir(parents=True, exist_ok=True)
sprites = bytearray(1001 * 14)
for key, sprite in game["sprites"].items():
    struct.pack_into(">7h", sprites, int(key) * 14, *(sprite[field] for field in
        ("texture", "x", "y", "width", "height", "next_frame", "delay")))
(output / "sprt.bin").write_bytes(sprites)
for atlas in (0, 1, 2, 5, 7, 10, 12, 18):
    image = Image.open(assets / "atlases" / f"{atlas}.png").convert("RGBA")
    assert image.width == image.height
    (output / f"atlas{atlas}.rgba").write_bytes(struct.pack(">I", image.width) + image.tobytes())
shutil.copyfile(analysis / "AstroSquid.pef", output / "original.pef")
shutil.copyfile(analysis / "AstroSquid.literals.bin", output / "literals.bin")
print("Prepared exact RGBA atlases, sprite definitions and original-code inputs; no renderer launched")
