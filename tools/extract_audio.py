"""Losslessly convert original uncompressed Sound Manager samples to WAV."""
from pathlib import Path
import hashlib
import json
import shutil
import struct
import wave
from macresources import resources, string_list


def decode_sound(data):
    def read(fmt, p):
        if p < 0 or p + struct.calcsize(fmt) > len(data):
            raise ValueError('Truncated sound resource')
        return struct.unpack_from(fmt, data, p)[0]
    def u16(p): return read('>H', p)
    def u32(p): return read('>I', p)
    if u16(0) != 1:
        raise ValueError('Unsupported snd resource format')
    commands = 4 + 6 * u16(2)
    headers = [u32(commands + 2 + 8*i + 4)
               for i in range(u16(commands))
               if u16(commands + 2 + 8*i) == 0x8051]
    if len(headers) != 1:
        raise ValueError('Expected one offset bufferCmd')
    h = headers[0]
    rate = u32(h + 8) / 65536
    encoding = read('B', h + 20)
    if encoding == 0:
        channels, width, frames, start = 1, 1, u32(h + 4), h + 22
    elif encoding == 255:
        channels, width, frames, start = u32(h + 4), u16(h + 48)//8, u32(h + 22), h + 64
        if u16(h + 48) != 16:
            raise ValueError('Expected original 16-bit extended sample header')
    else:
        raise ValueError(f'Unsupported compressed sound encoding {encoding}')
    if not (channels in (1, 2) and width in (1, 2) and frames > 0 and rate > 0):
        raise ValueError('Invalid sound dimensions')
    end = start + channels * width * frames
    # Three original extended resources carry one unused trailing sample.
    if end > len(data) or len(data)-end not in (0, 2):
        raise ValueError(f'Sample length mismatch: {end} != {len(data)}')
    pcm = data[start:end]
    if width == 2:
        swapped = bytearray(pcm)
        swapped[0::2], swapped[1::2] = pcm[1::2], pcm[0::2]
        pcm = bytes(swapped)
    return pcm, channels, width, round(rate), frames


def extract(application, destination):
    application, destination = Path(application), Path(destination)
    destination.mkdir(parents=True, exist_ok=True)
    sounds = destination / 'sounds'
    sounds.mkdir(exist_ok=True)
    records = resources(Path(str(application)+'/..namedfork/rsrc').read_bytes())
    manifest = {'sounds': {}, 'string_cues': {}, 'music': {}}
    names = {r['name'] for r in records if r['type'] == 'snd '}
    for record in records:
        if record['type'] == 'STR#' and record['id'] == 25000:
            manifest['string_cues'] = {str(i): s for i, s in enumerate(string_list(record['data']), 1) if s in names}
        if record['type'] != 'snd ': continue
        name = record['name']
        if not name or Path(name).name != name:
            raise ValueError('Unsafe sound resource name')
        pcm, channels, width, rate, frames = decode_sound(record['data'])
        target = sounds / (name + '.wav')
        with wave.open(str(target), 'wb') as output:
            output.setparams((channels, width, rate, frames, 'NONE', 'not compressed'))
            output.writeframes(pcm)
        manifest['sounds'][name] = dict(resource_id=record['id'], file='sounds/'+target.name,
            channels=channels, sample_bytes=width, rate=rate, frames=frames,
            pcm_sha256=hashlib.sha256(pcm).hexdigest())
    for i in range(1,4):
        name = f'Music{i}.mp3'
        source = application.parent / 'Data' / name
        if not source.is_file(): raise ValueError(f'Missing original music: {name}')
        shutil.copyfile(source, destination / name)
        manifest['music'][str(i)] = dict(file=name, sha256=hashlib.sha256(source.read_bytes()).hexdigest())
    (destination/'audio.json').write_text(json.dumps(manifest, indent=2)+'\n')
    return manifest


if __name__ == '__main__':
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('application'); parser.add_argument('destination')
    args=parser.parse_args()
    result=extract(args.application,args.destination)
    print(f"Extracted {len(result['sounds'])} lossless sounds and {len(result['music'])} original music tracks")
