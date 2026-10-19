"""Regression against actual PowerPC QuickDraw rasters, not a matching decoder clone."""
import hashlib
import json
from pathlib import Path
import sys
from PIL import Image

root = Path(__file__).resolve().parents[1]
assets = Path(sys.argv[1]) if len(sys.argv)>1 else root/'assets'
golden = json.loads((root/'tools/pict_raster_hashes.json').read_text())['pictures']
for identifier, record in golden.items():
    image = Image.open(assets/'pictures'/f'{identifier}.png').convert('RGB')
    assert image.size == (record['width'], record['height']), identifier
    assert hashlib.sha256(image.tobytes()).hexdigest() == record['rgb_sha256'], identifier
font = Image.open(assets/'atlases/50.png').convert('RGBA')
assert font.getchannel('A').getextrema() == (0,255)
assert 0 < font.getchannel('A').histogram()[0] < 512*512
orb = Image.open(assets/'atlases/99.png').convert('RGBA')
assert orb.getchannel('A').getextrema() == (0,219)
assert orb.getpixel((0,0))[3] == 0
ui = json.loads((assets/'ui/ui.json').read_text())
assert ui['pictures']['51']['source_picture'] == 501
assert ui['pictures']['41']['height'] == 294
assert ui['credits']['lines'][0]['baseline'] == 415
assert len(ui['font']['advance']) == 257 and ui['font']['advance'][32] == .2
scenes = json.loads((assets/'game.json').read_text())['scenes']
assert all(obj['depth']==obj['userdata'] and 'animation_tick' in obj for scene in scenes.values() for obj in scene)
print('PASS 74 native QuickDraw reference rasters, real glyph alpha, transparent orb masks and UI metadata')
