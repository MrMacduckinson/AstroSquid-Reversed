#!/usr/bin/env python3
"""Validate canonical native/host traces, or report their first differing field."""
import argparse
from itertools import zip_longest
from pathlib import Path

FIELDS = {
    'G': ('type','tick','phase','rng','player','viewport','scroll','inventory','score'),
    'E': ('type','tick','phase','id','render','parent','previous','next','payload'),
    'R': ('type','tick','phase','id','previous','next','payload','userdata'),
    'S': ('type','tick','phase','cue','pan'),
}

def records(path):
    with Path(path).open() as stream:
        for number, line in enumerate(stream, 1):
            values=line.rstrip('\n').split('\t')
            if values[0] not in FIELDS or len(values)!=len(FIELDS[values[0]]):
                raise ValueError(f'{path}:{number}: invalid record shape')
            yield number, dict(zip(FIELDS[values[0]],values))

def validate(path):
    previous_phase=None; links={'E':[], 'R':[]};count=0
    def check_links():
        for kind, entries in links.items():
            for i, record in enumerate(entries):
                previous=entries[i-1]['id'] if i else '0'
                following=entries[i+1]['id'] if i+1<len(entries) else '0'
                if record['previous']!=previous or record['next']!=following:
                    raise ValueError(f'{path}: {kind}{record["id"]} inconsistent canonical list links')
            entries.clear()
    for number, record in records(path):
        count+=1;kind=record['type'];phase=(record['tick'],record['phase'])
        if phase!=previous_phase:
            check_links();previous_phase=phase
        if kind in links:links[kind].append(record)
        lengths={'G':{'rng':8,'viewport':64,'scroll':32,'inventory':20,'score':24},
                 'E':{'payload':180},'R':{'payload':80,'userdata':8},'S':{'pan':16}}[kind]
        for key,length in lengths.items():
            if len(record[key])!=length:raise ValueError(f'{path}:{number}: {key} expected {length} hex digits')
            bytes.fromhex(record[key])
    check_links()
    return count

def compare(original, portable):
    for a,b in zip_longest(records(original), records(portable)):
        if a is None or b is None:raise ValueError('trace length differs')
        for key in dict.fromkeys((*a[1],*b[1])):
            if a[1].get(key)!=b[1].get(key):
                extra=''
                if key in ('payload','viewport','scroll','inventory','score','userdata','pan','rng'):
                    expected=bytes.fromhex(a[1][key]);actual=bytes.fromhex(b[1][key])
                    offset=next(i for i,(x,y) in enumerate(zip(expected,actual)) if x!=y)
                    extra=f' first byte offset {offset}'
                raise ValueError(f'row {a[0]} tick {a[1]["tick"]} phase {a[1]["phase"]} {key}{extra}: '
                                 f'original={a[1].get(key)} portable={b[1].get(key)}')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original');parser.add_argument('portable',nargs='?');args=parser.parse_args()
    try:
        count=validate(args.original)
        if args.portable:validate(args.portable);compare(args.original,args.portable)
    except ValueError as error:parser.exit(1,str(error)+'\n')
    print(f'PASS: {count} canonical records'+(' identical' if args.portable else ' structurally valid'))
