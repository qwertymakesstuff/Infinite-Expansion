#!/usr/bin/env bash
# Rebuilds the BO3 reference workspace (see PROJECT_ANALYSIS.md §1.3) from the
# All-Around Enhancement Workshop package.  Nothing from the package is run;
# fastfiles are only decompressed and scanned, scripts are only decompiled.
#
# Usage: tools/bo3_reference/extract_aae.sh <AllAroundEnhancement.7z> <out-dir> [gsc-tool]
#   gsc-tool defaults to .toolchain/bin/gsc-tool-iw7-develop (tools/setup_compilers.sh);
#   any gsc-tool build works, the T7 decompiler is part of every build.
# Needs: 7z (p7zip/7zip; the archive uses BCJ2), python3.
#
# Output (<out-dir>):
#   package/                  extracted Workshop files
#   core_mod.zone             decompressed main fastfile (~114 MB)
#   compiled/                 carved compiled GSC/CSC objects, by script name
#   decompiled/t7/scripts/    decompiled GSC/CSC (function names are hashes)
#   scripts.txt, decompile.log, lua.txt, lua_strings/, localize_en.tsv
set -euo pipefail

ARCHIVE="$1"
OUT="$2"
GSC_TOOL="${3:-.toolchain/bin/gsc-tool-iw7-develop}"
HERE="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
GSC_TOOL="$(cd "$(dirname "$GSC_TOOL")" && pwd)/$(basename "$GSC_TOOL")"

echo "==> extracting package"
7z x -y -bd -o"$OUT/package" "$ARCHIVE" > /dev/null

echo "==> decompressing fastfiles"
python3 -I "$HERE/t7ff_decompress.py" "$OUT/package/core_mod.ff" "$OUT/core_mod.zone"
python3 -I "$HERE/t7ff_decompress.py" "$OUT/package/en_core_mod.ff" "$OUT/en_core_mod.zone"

echo "==> carving compiled scripts"
python3 -I "$HERE/t7_carve_gsc.py" "$OUT/core_mod.zone" "$OUT/compiled" > "$OUT/scripts.txt"
tail -n 1 "$OUT/scripts.txt"

echo "==> decompiling (gsc-tool -g t7)"
(cd "$OUT" && "$GSC_TOOL" -m decomp -g t7 -s pc64 "$OUT/compiled" > "$OUT/decompile.log" 2>&1) || true
echo "    $(grep -c '^decompiled' "$OUT/decompile.log") scripts decompiled"

echo "==> inventorying LUI chunks and localized strings"
python3 -I "$HERE/t7_lua_strings.py" "$OUT/core_mod.zone" "$OUT/lua_strings" > "$OUT/lua.txt"
python3 -I "$HERE/t7_localize.py" "$OUT/en_core_mod.zone" "$OUT/localize_en.tsv"
echo "Done: $OUT"
