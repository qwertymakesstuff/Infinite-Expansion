# tools/ — offline verification

The game cannot run here, so the build pipeline verifies everything that can be checked **without** the game. iw7-mod compiles scripts at runtime with an embedded copy of gsc-tool, and these tools run that same compiler offline.

## Setup (Linux x86_64)

```bash
tools/setup_compilers.sh            # builds into .toolchain/ (git-ignored)
```

| Output | Built from | Purpose |
|--------|-----------|---------|
| `.toolchain/bin/gsc-tool-iw7-release` | auroramod/gsc-tool `833822d0` | the compiler in iw7-mod **v1.1.0** (latest release) |
| `.toolchain/bin/gsc-tool-iw7-develop` | auroramod/gsc-tool `0be361a4` | the compiler in iw7-mod **develop** (`c0a1c6da`); also the disassembler |
| `.toolchain/bin/ixcc-release`, `ixcc-develop` | `tools/ixcc/ixcc.cpp` linked against each pin | compile **exactly as iw7-mod's in-game loader does** (see below) |
| `.toolchain/src/iw7-gsc-dump/decompiled/` | mjkzy/iw7-gsc-dump `1dd48a78` | decompiled stock scripts; reference for far-call checks, never shipped |
| `.toolchain/src/iw7-mod-ui/data/cdata/ui_scripts/` | auroramod/iw7-mod develop `c0a1c6da` (sparse) | iw7-mod's own Lua UI scripts; reference for the `lua` check |

Requirements: `git`, `curl`, `tar`, `make`, `clang`/`clang++` (C++20), and Python 3.9+ for `check.py` (standard library only). Optional: `luac5.1` (package `lua5.1`) for the Lua syntax check. The script downloads premake 5.0.0-beta2 and 5.0.0-beta8 from the premake GitHub releases, because each pin needs the premake version its own CI used. A run from an empty directory takes about 8 minutes.

## Checking the mod

```bash
python3 tools/check.py                                   # the mod in mods/infinite_expansion
python3 -m unittest discover -s tools/tests -v           # tests for check.py itself
```

`check.py` exits 0 when there are no errors. Warnings do not fail the check. It runs these checks:

| Check | What it verifies |
|-------|------------------|
| `compile` | Every script compiles with **both** iw7-mod compilers, including iw7-mod's extension built-ins |
| `parity` | Both compilers emit identical code (disassembled with the develop table). This catches the v1.1.0 mislabels (`KNOWN_LIMITATIONS.md` C1, C2) |
| `natives` | No call to a native the game exe leaves unimplemented (`nullptr` stubs; iw7-mod raises a script error for these), and no unknown raw id |
| `calls` | Every far call and far function reference names a function that exists: in the mod, or in the stock dump for `scripts\…` paths. A stock target must also be a script that **every** zombies map loads (each map's link closure is computed from the dump), because a far call into anything else ends the match with a script link error |
| `layout` | Zombies-only layout (`ARCHITECTURE.md` §7): the entry script in `custom_scripts/cp/`, modules in `custom_scripts/ix/<area>/`, `init()` only in the entry script, every module reachable from it |
| `raw ids` | `_meth_XXXX` / `_func_XXX` only in `ix/core/compat.gsc`, and never in iw7-mod's extension id range (those ids depend on registration order) |
| `source` | No `#include`, no `/# #/` dev blocks (iw7-mod compiles dev blocks only with `developer_script 1`, so the checked code would differ from what runs), and no `//` comment ending in a backslash (both compilers silently drop the next line) |
| `lua` | Lua UI scripts: `luac5.1` syntax; every `Engine.`/`LUI.`/`MenuBuilder.`… path, method and bare function call must occur in iw7-mod's own ui_scripts or be defined in the file; folders need `__init__.lua` and must not be named like iw7-mod's (its copy would win) |
| `budget` | Custom-script memory (bytecode + 1 byte per loaded script) against a 512 KiB limit; iw7-mod's hard limit is 1 MiB, fatal if exceeded |

Options: `--mod DIR`, `--toolchain DIR`, `--stock DIR`, `--budget BYTES`, and `--work DIR` (keeps the `.gscbin` and `.gscasm` output).

Both compilers already reject a script function named after a built-in (`function name 'clamp' already defined as builtin`), so that rule needs no separate check.

`tools/tests/fixtures/bad_mod` breaks every rule once (each file's first comment says which), and `good_mod` follows them all. `tools/tests/test_check.py` asserts the exact findings for both. `tools/tests/test_character_data.py` checks the character table in `ix/player/character.gsc` against the stock scripts: models, slots, lobby ids, and soul keys.

## ixcc

Stock gsc-tool rejects calls to iw7-mod's extension built-ins (`va`, `fileexists`, `tell`, `replacefunc`, …) because its tables do not contain them. iw7-mod adds those names at runtime with `func_add` / `meth_add`. ixcc does the same, then compiles one file:

```bash
.toolchain/bin/ixcc-develop tools/ixcc/iw7mod_extensions.txt <script-root> <relative/script.gsc> <out.gscbin> [stock-root]
```

- It uses the same context as iw7-mod: IW7 server instance, production build, and extension ids from 807 / `0x8000 + 1484`, matching `script_extension.cpp`.
- For scripts without extension calls, the output is byte-identical to gsc-tool's.
- `tools/ixcc/iw7mod_extensions.txt` lists the 28 names. It is identical at iw7-mod v1.1.0 and develop, and the file header explains how to regenerate it.
- ixcc links gsc-tool, so `ixcc.cpp` is GPL-3.0-or-later. It is a build-time tool and is not part of the mod.

## Lower-level commands

```bash
# compile with stock gsc-tool (writes compiled/iw7/<name>.gscbin; -w = include root)
.toolchain/bin/gsc-tool-iw7-release -m comp -g iw7 -s pc -w <mod-root> <file.gsc>

# disassemble a file or a whole directory (paths are kept) to see which natives it calls
.toolchain/bin/gsc-tool-iw7-develop -m disasm -g iw7 -s pc <file.gscbin | dir>

# dump builtin tables (id, name, status) from a gsc-tool source checkout
python3 tools/extract_iw7_builtins.py .toolchain/src/gsc-tool-release out/release
python3 tools/extract_iw7_builtins.py .toolchain/src/gsc-tool-develop out/develop
```

Compiler messages seen so far:

- `couldn't determine function call type`: unknown built-in, or a name only the other compiler knows.
- `expected ';', got …` (develop) / `syntax error, unexpected …` (v1.1.0): a syntax error.
- `function name 'x' already defined as builtin`: a script function reuses a built-in name.
- An unknown raw id such as `_meth_85CB` compiles **silently**. The `natives` check catches it.
- A `//` comment that ends in `\` joins the next line into the comment, so that line disappears without an error. The `source` check catches it.

## BO3 reference workspace

`tools/bo3_reference/extract_aae.sh <AllAroundEnhancement.7z> <out-dir>` regenerates the decompiled AAE reference used in `PROJECT_ANALYSIS.md` §1 (see `tools/bo3_reference/README.md`).
