#!/usr/bin/env python3
"""Compare controlled G5/Intel offscreen frames; no GUI/OpenGL/audio is started."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image, ImageChops, ImageStat

if len(sys.argv) != 3:
    raise SystemExit("usage: compare_framebuffers.py FRAME_DIRECTORY OUTPUT_JSON")
root, output = map(Path, sys.argv[1:])
rows = []
for smooth in range(2):
    for trial in range(6):
        raw = [(root / f"{prefix}-{smooth}-{trial}.rgba").read_bytes()
               for prefix in ("original", "port")]
        assert all(len(data) == 640 * 380 * 4 for data in raw)
        original, port = [Image.frombytes("RGBA", (640, 380), data).convert("RGB")
                          for data in raw]
        difference = ImageChops.difference(original, port)
        bands = difference.split()
        maximum = ImageChops.lighter(ImageChops.lighter(bands[0], bands[1]), bands[2])
        histogram = maximum.histogram()
        neighbor_errors = []
        a, b = original.load(), port.load()
        for y in range(380):
            for x in range(640):
                if maximum.getpixel((x, y)) <= 16:
                    continue
                neighbor_errors.append(min(max(abs(a[xx, yy][c] - b[x, y][c]) for c in range(3))
                    for xx in range(max(0, x - 1), min(640, x + 2))
                    for yy in range(max(0, y - 1), min(380, y + 2))))
        mean = ImageStat.Stat(difference).mean
        rows.append(dict(smooth=smooth, trial=trial, stage=(1, 4, 7)[trial % 3],
            camera=(0, 0) if trial < 3 else (-37.25, -13.5),
            changed_pixels=sum(histogram[1:]), pixels_over_2=sum(histogram[3:]),
            pixels_over_16=sum(histogram[17:]), max_rgb=max(v[1] for v in difference.getextrema()),
            mean_rgb=mean, over16_neighbor_max=max(neighbor_errors, default=0),
            original_sha256=hashlib.sha256(raw[0]).hexdigest(),
            port_sha256=hashlib.sha256(raw[1]).hexdigest()))
        if smooth == 1 and trial == 3:
            for name, image in (("original", original), ("port", port), ("difference", difference)):
                image.transpose(Image.Transpose.FLIP_TOP_BOTTOM).save(root / f"{name}-controlled.png")
report = dict(
    scope="12 controlled full-playfield composites; original RENDERGAMEWINDOW/LMDRAWSPRITE on G5 vs duplicated equivalent sprite/star math on Intel; not linked production renderer or live campaign/HUD/menu frame",
    method_limits=["Intel primitives are duplicated and source-cross-checked, not linked production calls; production app runtime selftests are separate.","GL_DITHER disabled on both contexts; production default dither state is outside this comparison."],
    original_gpu="ATI Radeon 9600 OpenGL1.5 ATI-1.4.18, PowerPC Tiger",
    port_gpu="AMD Radeon Pro560 OpenGL2.1 ATI-1.68.20, Intel HighSierra",
    tolerance="Mean error below 1/255 per RGB channel and at least 99% pixels within 2/255; high-contrast raster-edge differences reported separately",
    passed=all(max(row["mean_rgb"]) < 1 and row["pixels_over_2"] <= 640 * 380 * .01 for row in rows),
    frames=rows)
output.write_text(json.dumps(report, indent=2) + "\n")
print(("PASS" if report["passed"] else "FAIL") + ": 12 controlled original/port playfield composites under stated cross-GPU RGB tolerance")
raise SystemExit(0 if report["passed"] else 1)
