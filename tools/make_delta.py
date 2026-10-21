"""Recreate only the delta from two locally owned, known scripts. Python 3.8+."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import struct

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('translated', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    manifest = json.loads((Path(__file__).resolve().parents[1]/'manifest.json').read_text(encoding='utf-8'))
    a, b = args.original.read_bytes(), args.translated.read_bytes()
    sha = lambda data: hashlib.sha256(data).hexdigest()
    if sha(a) != manifest['baseScriptSha256'] or sha(b) != manifest['patchedScriptSha256']:
        raise SystemExit('Input hashes do not match this release.')
    original, translated = a.splitlines(keepends=True), b.splitlines(keepends=True)
    if len(original) != len(translated): raise SystemExit('Line counts differ.')
    operations=[]; offset=0
    for old, new in zip(original, translated):
        if old != new:
            left=0
            while left<min(len(old),len(new)) and old[left]==new[left]: left+=1
            right=0
            while right<min(len(old),len(new))-left and old[-right-1]==new[-right-1]: right+=1
            operations.append((offset+left,len(old)-left-right,new[left:len(new)-right]))
        offset+=len(old)
    raw=bytearray(b'UMICN001'+struct.pack('<II',len(b),len(operations)))
    rebuilt=bytearray(); cursor=0
    for offset, remove, data in operations:
        raw.extend(struct.pack('<III',offset,remove,len(data))); raw.extend(data)
        rebuilt.extend(a[cursor:offset]); rebuilt.extend(data); cursor=offset+remove
    rebuilt.extend(a[cursor:])
    if rebuilt != b: raise SystemExit('Reconstruction failed.')
    result=gzip.compress(bytes(raw),compresslevel=9,mtime=0)
    # Gzip encoders may differ between Python/zlib versions; uncompressed data and
    # reconstructed script are deterministic, but compressed bytes can differ.
    with args.output.open('xb') as f: f.write(result)
    print(json.dumps({'operations':len(operations),'sha256':sha(result),'bytes':len(result)}))

if __name__ == '__main__': main()
