"""Extract localized-string pairs (KEY -> text) from a decompressed BO3 language zone.

Usage: python3 -I t7_localize.py <lang_core_mod.zone> <out.tsv>

In the zones examined, each localize entry stores its text immediately before
its KEY (upper-case, underscore-separated).  This is a heuristic byte scan:
it is good enough to read menu labels and option descriptions, not a parser.
"""
import re
import sys
from pathlib import Path

PRINTABLE = re.compile(rb"[\x20-\x7e\x09\x0a]{1,}")
KEY = re.compile(r"[A-Z][A-Z0-9_]*_[A-Za-z0-9_]+")


def main():
    data = Path(sys.argv[1]).read_bytes()
    strings = [m.group().decode("latin-1") for m in PRINTABLE.finditer(data)]
    pairs = 0
    with open(sys.argv[2], "w", encoding="utf-8") as out:
        for index in range(1, len(strings)):
            if KEY.fullmatch(strings[index]):
                text = strings[index - 1].replace("\t", " ").replace("\n", "\\n")
                out.write(f"{strings[index]}\t{text}\n")
                pairs += 1
    print(f"{pairs} localized pairs")


if __name__ == "__main__":
    main()
