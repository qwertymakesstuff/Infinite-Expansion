# tools/ — offline verification

The game cannot run here, so the build pipeline verifies everything that can be checked **without** the game. iw7-mod compiles scripts at runtime with an embedded copy of gsc-tool, and these tools run that same compiler offline.

## Setup (Linux x86_64)

```bash
tools/setup_compilers.sh            # builds into .toolchain/ (git-ignored)
```

It produces two compilers, one per iw7-mod version players may be running:

| Binary | gsc-tool commit | Matches |
|--------|-----------------|---------|
| `.toolchain/bin/gsc-tool-iw7-release` | `833822d0` | iw7-mod **v1.1.0** (latest release) |
| `.toolchain/bin/gsc-tool-iw7-develop` | `0be361a4` | iw7-mod **develop** (`c0a1c6da`, 2026-10-05) |

Requirements: `git`, `curl`, `tar`, `make`, `clang`/`clang++` (C++20). The script downloads premake 5.0.0-beta2 and 5.0.0-beta8 from the premake GitHub releases, because each pin needs the premake version its own CI used.

## Usage

```bash
# compile (writes compiled/iw7/<name>.gscbin; -w = include root)
.toolchain/bin/gsc-tool-iw7-release -m comp -g iw7 -s pc -w <mod-root> <file.gsc>

# disassemble a compiled file to see which natives it really calls
.toolchain/bin/gsc-tool-iw7-develop -m disasm -g iw7 -s pc <file.gscbin>

# dump builtin tables (id, name, status) from a gsc-tool source checkout
python3 tools/extract_iw7_builtins.py .toolchain/src/gsc-tool-release out/release
python3 tools/extract_iw7_builtins.py .toolchain/src/gsc-tool-develop out/develop
```

Errors observed in Phase 0:

- An unknown built-in gives `couldn't determine function call type`.
- A syntax error gives `expected ';', got …`.

## BO3 reference workspace

`tools/bo3_reference/extract_aae.sh <AllAroundEnhancement.7z> <out-dir>` regenerates the decompiled AAE reference used in `PROJECT_ANALYSIS.md` §1 (see `tools/bo3_reference/README.md`).

## Planned (Phase 1)

- `check.sh` will:
  - compile every script with **both** compilers and fail on any error;
  - disassemble both outputs and fail if they call different natives (release/develop parity);
  - verify that every `scripts\…::func` far call exists in the stock IW7 dump;
  - enforce the mode-separation rules (`ARCHITECTURE.md` §7);
  - report total bytecode against the 1 MiB custom-script budget.
