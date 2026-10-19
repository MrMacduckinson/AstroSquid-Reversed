"""Check header parsing, signed sample endianness, and complete extracted PCM."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import unittest
import wave
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from extract_audio import decode_sound

class AudioTests(unittest.TestCase):
    def test_standard(self):
        sound=struct.pack('>HHHIHHHI',1,1,5,128,1,0x8051,0,20)
        header=struct.pack('>IIIII BB',0,3,22050<<16,0,0,0,60)
        self.assertEqual(decode_sound(sound+header+b'\x00\x80\xff'),(b'\x00\x80\xff',1,1,22050,3))
        with self.assertRaises(ValueError): decode_sound(sound+header+b'\x00')
    def test_extended(self):
        sound=struct.pack('>HHHIHHHI',1,1,5,128,1,0x8051,0,20)
        h=bytearray(64);struct.pack_into('>III',h,0,0,1,44100<<16)
        h[20]=255;struct.pack_into('>I',h,22,2);struct.pack_into('>H',h,48,16)
        self.assertEqual(decode_sound(sound+h+b'\x80\x00\x7f\xff')[0],b'\x00\x80\xff\x7f')
    def test_assets(self):
        assets=Path(__file__).resolve().parents[1]/'assets'
        if not (assets/'audio.json').exists(): self.skipTest('Run extract_audio.py with original game first')
        manifest=json.loads((assets/'audio.json').read_text())
        self.assertEqual(len(manifest['sounds']),18);self.assertEqual(len(manifest['music']),3)
        for sound in manifest['sounds'].values():
            with wave.open(str(assets/sound['file'])) as sample:
                self.assertEqual(sample.getnframes(),sound['frames'])
                self.assertEqual(sample.getframerate(),sound['rate'])
                self.assertEqual(hashlib.sha256(sample.readframes(sample.getnframes())).hexdigest(),sound['pcm_sha256'])
        for track in manifest['music'].values():
            self.assertEqual(hashlib.sha256((assets/track['file']).read_bytes()).hexdigest(),track['sha256'])

if __name__=='__main__': unittest.main()
