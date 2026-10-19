"""Check the entire extracted resource graph before building a renderer."""
import json
import math
from pathlib import Path
import sys
from PIL import Image


def check(root):
    data = json.loads((root / 'game.json').read_text())
    for key, texture in data['textures'].items():
        with Image.open(root / 'atlases' / (key + '.png')) as image:
            assert image.size == (texture['width'], texture['height']), key
            assert image.mode == 'RGBA', key
    for key, sprite in data['sprites'].items():
        assert str(sprite['texture']) in data['textures'], key
        assert sprite['width'] > 0 and sprite['height'] > 0, key
        assert sprite['next_frame'] >= -1, key
        if sprite['next_frame'] > 0:
            assert str(sprite['next_frame']) in data['sprites'], key
    for key, attr in data['attributes'].items():
        assert str(attr['sprite']) in data['sprites'], key
        if attr['script']:
            assert str(attr['script']) in data['scripts'], key
    count = 0
    for name, level in data['levels'].items():
        assert level['background'] in data['scenes'], name
        for entity in level['entities']:
            assert str(entity['attribute']) in data['attributes'], (name,entity)
            assert all(math.isfinite(entity[k]) for k in ('x','y','width','height')), name
            assert entity['width'] > 0 and entity['height'] > 0, name
            count += 1
    for name, scene in data['scenes'].items():
        for entity in scene:
            assert str(entity['sprite']) in data['sprites'], (name,entity)
    assert len(data['textures']) == 54
    assert len(data['sprites']) == 295
    assert len(data['levels']) == 17
    assert len(data['levels']['Data 1A']['entities']) == 319
    player = data['levels']['Data 1A']['entities'][0]
    assert (player['x'],player['y'],player['attribute']) == (-91.5,-311.0,11)
    print(f'PASS: {count} level entities, all scene/sprite/script links, and all 54 RGBA atlas dimensions')


if __name__ == '__main__':
    check(Path(sys.argv[1] if len(sys.argv)>1 else 'assets'))
