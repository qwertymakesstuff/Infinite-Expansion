"""Extract the IW7 GSC builtin function/method tables from a gsc-tool checkout.

Usage:
    python3 tools/extract_iw7_builtins.py <gsc-tool-source-root> <out-dir>

Writes <out-dir>/iw7_functions.tsv and <out-dir>/iw7_methods.tsv with rows:
    id<TAB>name<TAB>status

status:
    available  the table maps the id to a native address in the release exe
    stub       the table comment is "nullptr": the name compiles, but the
               release exe has no implementation (calling it is a runtime error)
    unnamed    only a placeholder name is known (_func_XXX / _meth_XXXX); call
               it by that raw id

Run it on both iw7-mod compiler pins (see setup_compilers.sh) and diff the
outputs to find names that only one client version can resolve.
"""
import re
import sys
from pathlib import Path

ENTRY = re.compile(r'\{\s*(0x[0-9A-Fa-f]+)\s*,\s*"([^"]+)"\s*\}\s*,?\s*(?://\s*(\S+))?')
TABLES = (("functions", "iw7_func.cpp"), ("methods", "iw7_meth.cpp"))


def parse_table(path):
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = ENTRY.search(line)
        if not match:
            continue
        ident, name, comment = match.group(1), match.group(2), match.group(3) or ""
        if name.startswith(("_func_", "_meth_")):
            status = "unnamed"
        elif comment == "nullptr":
            status = "stub"
        else:
            status = "available"
        rows.append((int(ident, 16), name, status))
    return rows


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    engine_dir = Path(sys.argv[1]) / "src" / "gsc" / "engine"
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    for kind, file_name in TABLES:
        rows = parse_table(engine_dir / file_name)
        with open(out_dir / f"iw7_{kind}.tsv", "w", encoding="utf-8") as out:
            for ident, name, status in rows:
                out.write(f"0x{ident:04X}\t{name}\t{status}\n")
        counts = {}
        for _, _, status in rows:
            counts[status] = counts.get(status, 0) + 1
        print(f"{kind}: {len(rows)} entries {counts}")


if __name__ == "__main__":
    main()
