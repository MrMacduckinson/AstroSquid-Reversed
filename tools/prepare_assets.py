"""Extract every original game asset required by the native build."""
from pathlib import Path
import argparse
from extract_assets import export as export_graphics
from extract_audio import extract as export_audio
from extract_ui import export as export_ui

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('application',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    export_graphics(args.application,args.output)
    export_audio(args.application,args.output)
    export_ui(args.application,args.output/'game.json',args.output/'ui'/'ui.json')
