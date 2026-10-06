"""Summarise Havok Lua (LUI) chunks found in a decompressed BO3 zone.

Usage: python -I t7_lua_strings.py <zone> <out-dir>
For each '\\x1bLua' chunk (sliced up to the next chunk) this writes the
printable strings to <out-dir>/<index>.txt and prints a one-line summary:
the first path-like string (usually the source/menu name) and string count.
Nothing is executed; this is a pure byte scan.
"""
import re
import sys
from pathlib import Path

MAGIC = b"\x1bLua"
PRINTABLE = re.compile(rb"[\x20-\x7e]{3,}")


def main():
    data = Path(sys.argv[1]).read_bytes()
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    starts = [m.start() for m in re.finditer(re.escape(MAGIC), data)]
    for index, start in enumerate(starts):
        end = starts[index + 1] if index + 1 < len(starts) else min(len(data), start + 2_000_000)
        chunk = data[start:min(end, start + 2_000_000)]
        strings = [m.group().decode("latin-1") for m in PRINTABLE.finditer(chunk)]
        (out_dir / f"{index:03d}.txt").write_text("\n".join(strings), encoding="utf-8")
        name = next((s for s in strings if "/" in s and (s.endswith(".lua") or s.startswith("ui/"))), "")
        print(f"{index:03d} {len(chunk):8d} strings={len(strings):5d} {name}")


if __name__ == "__main__":
    main()
