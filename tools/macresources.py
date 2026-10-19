"""Read a classic Macintosh resource fork without changing its original bytes."""
from pathlib import Path
import struct


def resources(blob):
    if len(blob) < 16:
        raise ValueError("Resource fork header is missing")
    data, mapping, data_size, map_size = struct.unpack_from(">4I", blob)
    if data + data_size > len(blob) or mapping + map_size > len(blob):
        raise ValueError("Resource fork regions exceed file length")
    types = mapping + struct.unpack_from(">H", blob, mapping + 24)[0]
    names = mapping + struct.unpack_from(">H", blob, mapping + 26)[0]
    count = struct.unpack_from(">H", blob, types)[0] + 1
    result = []
    for i in range(count):
        at = types + 2 + i * 8
        kind = blob[at:at + 4].decode("mac_roman")
        last, refs = struct.unpack_from(">HH", blob, at + 4)
        for j in range(last + 1):
            ref = types + refs + j * 12
            number, name_offset = struct.unpack_from(">hh", blob, ref)
            offset = data + int.from_bytes(blob[ref + 5:ref + 8], "big")
            length = struct.unpack_from(">I", blob, offset)[0]
            end = offset + 4 + length
            if end > data + data_size:
                raise ValueError("Resource extends beyond data region")
            name = None
            if name_offset != -1:
                p = names + name_offset
                name = blob[p + 1:p + 1 + blob[p]].decode("mac_roman")
            result.append(dict(type=kind, id=number, name=name,
                               offset=offset + 4, data=blob[offset + 4:end]))
    return result


def string_list(data):
    count = struct.unpack_from(">H", data)[0]
    pos = 2
    values = []
    for _ in range(count):
        size = data[pos]
        pos += 1
        values.append(data[pos:pos + size].decode("mac_roman"))
        pos += size
    return values


def inspect(path, output):
    import json
    import hashlib
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    path = Path(path)
    blob = Path(str(path) + "/..namedfork/rsrc").read_bytes()
    (output / "AstroSquid.rsrc").write_bytes(blob)
    (output / "AstroSquid.stub.pef").write_bytes(path.read_bytes())
    inventory = []
    for resource in resources(blob):
        item = {k: v for k, v in resource.items() if k != "data"}
        b = resource["data"]
        item.update(size=len(b), sha256=hashlib.sha256(b).hexdigest())
        if resource["type"] == "FCOD":
            pef_offset = b.find(b"Joy!peff")
            if pef_offset not in (0, 64):
                raise ValueError("FCOD is not the expected PEF container")
            item["pef_offset"] = pef_offset
            (output / "AstroSquid.pef").write_bytes(b[pef_offset:])
            (output / "AstroSquid.FCOD").write_bytes(b)
            if pef_offset == 64:
                literal_offset = struct.unpack_from('>I', b, 16)[0]
                if not 64 < literal_offset < len(b):
                    raise ValueError('Invalid FutureBASIC literal pool offset')
                (output / 'AstroSquid.literals.bin').write_bytes(b[literal_offset:])
                pef = bytearray(b[64:])
                code_start = struct.unpack_from('>I', pef, 60)[0]
                next_start = struct.unpack_from('>I', pef, 88)[0]
                # FB's FCOD reader retains the import glue in the inter-section
                # gap. A standard PEF importer otherwise maps data over it.
                for field in (48, 52, 56):
                    struct.pack_into('>I', pef, field, next_start-code_start)
                (output / 'AstroSquid.analysis-expanded.pef').write_bytes(pef)
                item['literal_offset_in_FCOD'] = literal_offset
                item['global_bytes'] = struct.unpack_from('>I', b, 8)[0]
        if resource["type"] == "STR#":
            item["strings"] = string_list(b)
        if resource["type"] in ("Attr", "Wpns", "sprt", "txtr", "TMPL"):
            item["hex"] = b.hex()
        inventory.append(item)
    (output / "resources.json").write_text(
        json.dumps(inventory, indent=2, ensure_ascii=False) + "\n")
    return inventory


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("application")
    p.add_argument("output")
    a = p.parse_args()
    items = inspect(a.application, a.output)
    print(f"Extracted {len(items)} resources; original application unchanged")
