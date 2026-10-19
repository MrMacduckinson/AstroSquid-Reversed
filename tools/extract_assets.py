"""Export original sprite atlases and typed game data, preserving source hashes."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import shutil
from pathlib import Path
import struct
import subprocess

from macresources import resources, string_list


def export(application, output):
    from PIL import Image
    output.mkdir(parents=True, exist_ok=True)
    app = Path(application)
    items = resources(Path(str(app) + '/..namedfork/rsrc').read_bytes())
    records = {(r['type'], r['id']): r for r in items}
    pict = output / 'pict'
    png = output / 'pictures'
    atlas = output / 'atlases'
    for p in [pict, png, atlas]:
        p.mkdir(exist_ok=True)
    decoder = shutil.which('magick')
    if not decoder:
        raise RuntimeError('ImageMagick magick is required: Apple sips loses indexed PICT masks/font')
    golden = json.loads(Path(__file__).with_name('pict_raster_hashes.json').read_text())['pictures']
    pictures = [r for r in items if r['type'] == 'PICT']
    for r in pictures:
        (pict / f"{r['id']}.pict").write_bytes(bytes(512) + r['data'])

    def convert(r):
        reference = golden.get(str(r['id']))
        verified = reference and hashlib.sha256(r['data']).hexdigest() == reference['pict_sha256']
        source, destination = pict / f"{r['id']}.pict", png / f"{r['id']}.png"
        # Five compressed-color PICTs need sips; all 74 choices match native G5 QuickDraw.
        if verified and reference['decoder'] == 'sips':
            command = ['sips', '-s', 'format', 'png', str(source), '--out', str(destination)]
        else:
            command = [decoder, str(source), str(destination)]
        subprocess.run(command, check=True, capture_output=True)
        if verified:
            image = Image.open(destination).convert('RGB')
            if image.size != (reference['width'], reference['height']) or hashlib.sha256(image.tobytes()).hexdigest() != reference['rgb_sha256']:
                raise ValueError(f"PICT {r['id']}: decoder differs from original G5 QuickDraw pixels")

    with ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(convert, pictures))

    result = {'source_sha256': hashlib.sha256(
        Path(str(app) + '/..namedfork/rsrc').read_bytes()).hexdigest(),
        'sprites': {}, 'textures': {}, 'attributes': {}, 'weapons': {},
        'scripts': {}, 'levels': {}, 'scenes': {}}
    for r in items:
        key = str(r['id'])
        b = r['data']
        if r['type'] == 'sprt':
            tex, x, y, w, h, nxt, delay = struct.unpack('>7h', b)
            result['sprites'][key] = dict(name=r['name'], texture=tex, x=x, y=y,
                                          width=w, height=h, next_frame=nxt, delay=delay)
        elif r['type'] == 'txtr':
            color, mask, w, h = struct.unpack('>4h', b)
            result['textures'][key] = dict(name=r['name'], picture=color, mask=mask,
                                           width=w, height=h)
            if color == 0 and mask == 0:
                image = Image.new('RGBA', (w, h), 'white')
            else:
                original = Image.open(png / f'{color}.png').convert('RGBA')
                image = Image.new('RGBA', (w,h), (0,0,0,255))
                # LM texture loading draws the PICT at its natural size into
                # a fixed-size GWorld; oversized pictures are clipped.
                image.paste(original, (0,0))
                if mask:
                    source_mask = Image.open(png / f'{mask}.png').convert('RGB').getchannel('R')
                    alpha = Image.new('L', (w,h), 0)
                    alpha.paste(source_mask, (0,0))
                    image.putalpha(alpha)
            image.save(atlas / f'{key}.png')
        elif r['type'] == 'Attr':
            fields = ['speed', 'shots_per_second', 'weapon', 'debris_sprite',
                      'debris_amount', 'kill_score', 'script', 'turret_x',
                      'turret_y', 'hit_points', 'animated', 'sprite',
                      'death_effect', 'unused_1', 'unused_2']
            result['attributes'][key] = dict(zip(fields, struct.unpack('>15h', b)))
            result['attributes'][key]['name'] = r['name']
        elif r['type'] == 'Wpns':
            vals = struct.unpack('>26h', b)
            result['weapons'][key] = dict(name=r['name'], rate=vals[0],
                header_field_2=vals[1], bullets=[list(vals[i:i+4]) for i in range(2,26,4)])
        elif r['type'] == 'STR#' and 200 <= r['id'] <= 308:
            result['scripts'][key] = string_list(b)

    for f in sorted((app.parent / 'Data').glob('Data *')):
        if f.name[-1] not in 'AB' or f.name.startswith('Data B'):
            b = f.read_bytes()
            if len(b) % 308:
                raise ValueError(f'{f.name}: partial 308-byte scene record')
            scene = []
            for offset in range(0,len(b),308):
                x,y,w,h = struct.unpack_from('>4d',b,offset)
                kind = struct.unpack_from('>h',b,offset+32)[0]
                animation_tick = struct.unpack_from('>i',b,offset+34)[0]
                userdata = struct.unpack_from('>i',b,offset+296)[0]
                sprite = struct.unpack_from('>h',b,offset+38)[0]
                length = b[offset+40]
                name = b[offset+41:offset+41+length].decode('mac_roman')
                scene.append(dict(x=x,y=y,width=w,height=h,kind=kind,depth=userdata,animation_tick=animation_tick,userdata=userdata,
                                  sprite=sprite,name=name))
            result['scenes'][f.name] = scene
            continue
        b = f.read_bytes()
        size = struct.unpack_from('>H', b)[0]
        background = b[2:2+size].decode('mac_roman')
        payload = b[2+size:]
        if len(payload) % 50:
            raise ValueError(f'{f.name}: partial 50-byte entity record')
        entities = []
        for offset in range(0, len(payload), 50):
            x,y,w,h,kind,ptr,tag,ptr2,ptr3 = struct.unpack_from('>4dhIiII', payload, offset)
            entities.append(dict(x=x,y=y,width=w,height=h,attribute=kind,tag=tag))
        result['levels'][f.name] = dict(background=background, entities=entities,
            source_sha256=hashlib.sha256(b).hexdigest())
    (output / 'game.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    print(f"Exported {len(pictures)} pictures, {len(result['sprites'])} sprites, "
          f"{len(result['textures'])} atlases, {len(result['levels'])} level files")
    return result


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('application', type=Path)
    p.add_argument('output', type=Path)
    a = p.parse_args()
    export(a.application, a.output)
