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
| `.toolchain/pwsh/pwsh` | PowerShell 7.4.6 release (sha256-checked) | runs the Windows installer's logic in `tests/test_installer.py` |

Requirements: `git`, `curl`, `tar`, `make`, `clang`/`clang++` (C++20), and Python 3.9+ for `check.py` (standard library only). Optional: `luac5.1` (package `lua5.1`) for the Lua syntax check. The script downloads premake 5.0.0-beta2 and 5.0.0-beta8 from the premake GitHub releases, because each pin needs the premake version its own CI used. A run from an empty directory takes about 8 minutes.

## Checking the mod

```bash
python3 tools/check.py                                   # the mod in mods/infinite_expansion
python3 -m unittest discover -s tools/tests -v           # tests: check.py, the setup, the launcher, the menu script, the settings
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

`tools/tests/fixtures/bad_mod` breaks every rule once (each file's first comment says which), and `good_mod` follows them all. `tools/tests/test_check.py` asserts the exact findings for both. `tools/tests/test_installer.py` runs the Windows installer's logic (`installer/IXSetup.Core.ps1`) and its `-NoWindow` mode with PowerShell 7 on fake Steam libraries and game folders. It also tests the iw7-mod download against a local fake of GitHub and iw7-mod's update server, including the window's background-runspace download. It also checks the window's files statically: `ps51_lint.ps1` for Windows PowerShell 5.1 compatibility, ASCII-only scripts, CRLF launchers, and XAML that `XamlReader.Load` accepts and that matches the script's control names. The character pictures pack (`installer/IXPictures*.ps1`) is tested against `fake_zonetool.py`, a stand-in for x64-zt that behaves as its source and the first real run showed (`IW_API_NOTES.md` §18). It prints the ready line and reads console commands until `quit`. It dumps each zone's images with `dumpzone` (the cards where the game's asset listing puts them), finds the menu material only once `techsets_ui_boot` is loaded, and crashes on `dumpasset image`, as the real one did. It checks the build input and writes a JSON "fastfile". `fake_zonetool.json` in the fake game folder makes cards or zones missing, a map crash, or the tool hang. `NewerFiles` checks that a download with the same version number but different files still counts as an update. Updates are tested against a local stand-in for GitHub's release API: `Updates` (lookup, download, checksum, size, safe unpacking, refused releases, old downloads), `SetupUpdateWithoutWindow` (a whole `IXSetup.ps1 -NoWindow -Update` with the setup's GitHub addresses pointed at the stand-in, in which the downloaded version's own setup installs it), `UpdateSettings` (the AUTO-UPDATE switch, argument quoting) and `ReleaseWorkflow` (the script of `.github/workflows/release.yml`, run in a scratch git repository with a stand-in for `gh`). The setup's own picture build is tested the same way: `-NoWindow` installs, and the window's background script run in a second runspace, also stopped mid-run as when the window closes. The launcher (`installer/IXLauncher.cs`) is compiled by PowerShell 7's C# compiler with `/langversion:5`, the C# version of the compiler Windows comes with, and the arguments it passes on are split back by Windows' rules (`GameLauncher`). Its build is tested against `fake_csc.py`, a stand-in for that compiler placed where the setup looks for it (`<WINDIR>\Microsoft.NET\Framework64\v4.0.30319\csc.exe`): it checks the arguments and the source and writes a JSON "program"; `fake_csc.json` next to it makes it refuse the icon or fail. `installer/ix-launcher.ico` must hold bitmap images only and match what `tools/make_launcher_icon.py` makes from `installer/ix.ico` (that check needs Pillow and is skipped without it). `tools/tests/test_menu_script.py` runs the mod's menu script in plain Lua 5.1 (`menu_harness.lua` stands in for IW7's UI and for the stock zombies lobby, as read from the game's compiled UI scripts). It checks the lobby's CHARACTER button in every load order and in both of the lobby's layouts, the lobby field after the stock reset, the CHARACTER menu's text sizes, pictures and locks (Pam Grier's card drawn 2:1), the picture pack (loaded once, the selected map's cards, team cards beside the rows, the fallbacks), the lobby's card of the chosen character (the stand-in lobby has the five stock special pictures with their display / hide sequences, which run again after each step, and the party count model; scenario `lobbycard`: `players=`, a new pick, SELECT SHOW and `restore_focus`, then `players2=`), and the Steam-name rule. `tools/tests/test_character_data.py` checks the character table in `ix/player/character.gsc` against the stock scripts (models, slots, lobby ids, and soul keys), against the lobby values and unlock stats the CHARACTER menu uses, and the picture pack's special characters against the slots that table gives them. `tools/tests/test_settings.py` reads every setting the scripts register (`config::add_*`, `features::add`) and checks it against the menu (`ix/ui/menu_tree.gsc`: every row names a real setting, every setting has a row), the README's settings table (a row with the right default and every word of a word setting) and the init line's count in README and `TESTING.md`. It also wraps each menu row's help as `ix/ui/menu.gsc` does (`help_width()` characters a line), with the range and the guest's "Only the host can change it.", and fails if one needs more than `help_lines()` lines, because the menu drops what does not fit. The small lines of keys at the bottom (`footer_*_text()` in `menu.gsc`) may be at most 44 characters, and `footer_open_text()` needs a line for every way `menu_open` can open the menu. The HUD elements `create_hud()` makes are counted from its code: at most 28, at most 26 of them not archived (`KNOWN_LIMITATIONS.md` L49).

## Launcher icon

```bash
python3 tools/make_launcher_icon.py     # installer/ix.ico -> installer/ix-launcher.ico (needs Pillow)
```

Run it after changing `installer/ix.ico`. The launcher's icon stores the same images, up to 128 px, as 32-bit bitmaps with transparency masks, because the C# compiler that comes with Windows may refuse the PNG images `ix.ico` uses.

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
