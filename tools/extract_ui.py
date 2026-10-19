"""Recover original menu layout, MacRoman font metrics, labels and briefings."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from macresources import resources, string_list


def export(application, game, output):
    source = Path(str(application) + '/..namedfork/rsrc').read_bytes()
    records = resources(source)
    lists = {r['id']: string_list(r['data']) for r in records if r['type'] == 'STR#'}
    fcod = next(r['data'] for r in records if r['type'] == 'FCOD' and r['id'] == 1001)
    pool = struct.unpack_from('>I', fcod, 16)[0]
    def literal(offset):
        return struct.unpack_from('>d', fcod, pool + offset)[0]
    game_data = json.loads(Path(game).read_text())
    scenes = game_data['scenes']
    picts = {r['id']: r['data'] for r in records if r['type'] == 'PICT'}
    pictures = {}
    for key, texture in game_data['textures'].items():
        if int(key) not in (40, 41, 70) and not 51 <= int(key) <= 78:
            continue
        top,left,bottom,right = struct.unpack_from('>4h', picts[texture['picture']], 2)
        pictures[key] = {'source_picture': texture['picture'],
                         'width': right-left, 'height': bottom+top,
                         'texture_width': texture['width'], 'texture_height': texture['height']}
    for scene_name, objects in scenes.items():
        if scene_name not in ('Data B1', 'Data B2', 'Data B3'):
            continue
        scene_bytes = (Path(application).parent / 'Data' / scene_name).read_bytes()
        for index, obj in enumerate(objects):
            obj['animation_counter'] = struct.unpack_from('>i', scene_bytes, index*308+296)[0]
    labels = {str(i): text for i, text in enumerate(lists[25000], 1) if i >= 165}
    advance = [0.0] + [float(value) / 32 for value in lists[129]]
    advance[32] = .2
    result = {
        'source_sha256': hashlib.sha256(source).hexdigest(),
        'coordinate_system': '640x480 top-left; menu world coordinates plus camera offset',
        'scenes': {key: scenes[key] for key in ('Data B1', 'Data B2', 'Data B3')},
        'labels': labels,
        'pictures': pictures,
        'label_layout': json.loads(Path(__file__).with_name('ui_layout.json').read_text()),
        'briefings': {str(key): lists[key] for key in (400, 401, 402)},
        'key_names': lists[128],
        'font': {'texture': 50, 'encoding': 'mac_roman', 'grid': 16,
                 'code_offset': -1, 'uv_inset': .0015, 'uv_extent': .0595,
                 'advance': advance},
        'level_names': [labels[str(i)] for i in range(233, 264, 2)],
        'credits': {'picture': 41, 'picture_y': literal(0x2d20),
                    'lines': [{'text': labels[str(333+i)], 'center_x': literal(base),
                               'baseline': literal(base+24), 'size': literal(base+32),
                               'brightness': .6 if i<2 else .3}
                              for i,base in enumerate((0x2d40,0x2d68,0x2da8,0x2dd0))]},
        'menu_animation': {'step': .1, 'expand_frames': 31, 'period': 60},
        'ending': [{'text': labels[str(283+i)], 'center_x': literal(base+24),
                    'baseline': literal(base+48), 'size': literal(base+56)}
                   for i,base in enumerate((0x2130,0x2188,0x21e0,0x2238))],
        'camera_adjustments': {'Highscores Menu': [-200, -140],
                               'Register Menu': [180, -120],
                               'Continue Menu': [-190, 120]},
        'pause_heading': {'text': labels['214'], 'x': 220, 'baseline': 220, 'size': 32},
        'end_level_card': {'texture_id': '60 + stage (1..8)', 'picture_xy': [0,40], 'zero_x_means_center': True,
                           'text_list': 402, 'text_center_x': 320, 'text_baseline': 330,
                           'text_size': 12, 'prompt_baseline': 370, 'prompt_size': 10},
        'provenance': {'layout': 'Original Data B1/B2/B3 scene files',
                       'camera': 'MOVEMENUTO 1004b3a4',
                       'font': 'LMDRAWTEXT 1003572c, STR#129',
                       'end_level_card': 'ENDOFLEVEL 1004eda0'},
    }
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('application', type=Path)
    parser.add_argument('--game', default='assets/game.json')
    parser.add_argument('--output', default='assets/ui/ui.json')
    args = parser.parse_args()
    result = export(args.application, args.game, args.output)
    print('Recovered %d menu scene objects, %d labels, %d font metrics' % (
        sum(map(len, result['scenes'].values())), len(result['labels']), len(result['font']['advance'])))
