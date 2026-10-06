"""Carve compiled BO3 (T7) GSC/CSC objects out of a decompressed zone stream.

Usage: python -I t7_carve_gsc.py <zone> <out-dir>

For each '\\x80GSC\\r\\n\\x00' magic the 72-byte header is read; the object's
name is the C string at header.name.  Bytes from the magic up to the next
magic (capped) are written to <out-dir>/<name>; gsc-tool only reads what the
header's offsets reference, so trailing bytes are harmless.
Names are sanitised so nothing can be written outside <out-dir>.
"""
import re
import struct
import sys
from pathlib import Path, PurePosixPath

MAGIC = b"\x80GSC\r\n\x00"
HEADER = struct.Struct("<QIIIIIIIIIIII HHHHHH BBB")
CAP = 4 * 1024 * 1024


def safe_relpath(name):
    parts = [p for p in PurePosixPath(name.replace("\\", "/")).parts if p not in ("", ".", "..", "/")]
    parts = [re.sub(r"[^A-Za-z0-9_.\-]", "_", p) for p in parts]
    return Path(*parts) if parts else Path("unnamed.gsc")


def main():
    zone_path, out_dir = sys.argv[1], Path(sys.argv[2])
    data = Path(zone_path).read_bytes()
    starts = [m.start() for m in re.finditer(re.escape(MAGIC), data)]
    seen = {}
    rows = []
    for index, start in enumerate(starts):
        end = starts[index + 1] if index + 1 < len(starts) else len(data)
        end = min(end, start + CAP)
        fields = HEADER.unpack_from(data, start)
        (_magic, crc, inc_off, anim_off, cseg_off, strfix_off, devstrfix_off, exp_off, imp_off,
         fix_off, prof_off, cseg_size, name_off, strfix_n, exp_n, imp_n, fix_n, prof_n, devstr_n,
         inc_n, anim_n, flags) = fields
        name_end = data.find(b"\x00", start + name_off, start + name_off + 512)
        name = data[start + name_off:name_end].decode("latin-1") if name_end > 0 else f"unnamed_{index}.gsc"
        rel = safe_relpath(name)
        if str(rel) in seen:
            seen[str(rel)] += 1
            rel = rel.with_name(f"{rel.stem}__dup{seen[str(rel)]}{rel.suffix}")
        else:
            seen[str(rel)] = 0
        target = out_dir / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data[start:end])
        rows.append((name, end - start, exp_n, imp_n, inc_n, cseg_size))
    for name, size, exp_n, imp_n, inc_n, cseg_size in sorted(rows):
        print(f"{size:9d}  exports={exp_n:4d} imports={imp_n:4d} includes={inc_n:3d} cseg={cseg_size:7d}  {name}")
    print(f"carved {len(rows)} objects")


if __name__ == "__main__":
    main()
