# TESTING.md

## 1. Verification levels

| Level | Where it can run | Covers |
|-------|------------------|--------|
| **Static** | Any Linux machine with `tools/` (including this dev environment) | Both compilers, release/develop native-call parity, far-call targets, mode separation, bytecode budget |
| **Runtime** | **Windows + legally owned Infinite Warfare + iw7-mod only** | Everything else: behaviour, timing, HUD, input, multiplayer |

Runtime tests **cannot** be executed in the development environment. Every runtime item below stays **not run** until a tester reports a result, and `FEATURE_STATUS.md` will not mark a feature COMPLETE without one.

## 2. Phase 0 verification log (actually performed)

| # | Check | Result |
|---|-------|--------|
| V1 | Built gsc-tool `0be361a4` (iw7-mod develop pin) with clang 18 | ✅ binary `0.0.0.50-iw7-more` |
| V2 | Built gsc-tool `833822d0` (iw7-mod v1.1.0 pin) with clang 18 + premake beta2 | ✅ binary `0.0.0.1` |
| V3 | Compiled a sample IW7 script (connect/spawn threads, HUD element, `notifyonplayercommand`, far call into `scripts\cp\cp_persistence`, `setdvar`) | ✅ compiles |
| V4 | Unknown built-in (`self setclientthirdperson(1)`) | ✅ rejected at compile time: `couldn't determine function call type` |
| V5 | Syntax error (missing `;`) | ✅ rejected: `expected ';', got 'level'` |
| V6 | Same script compiled with both compilers, disassembled with the develop table | ⚠️ v1.1.0 emits `disablegrenadetouchdamage` for `disableinvulnerability` and `playercommandbot` for `playlocalsound` (see `KNOWN_LIMITATIONS.md` C1/C2) |
| V7 | Raw id `self _meth_845E(1)` | ✅ compiles on both and disassembles to `setcamerathirdperson` on both |
| V8 | Module far call `custom_scripts\ix\core\util::add_one()` and `#include custom_scripts\ix\core\util;` | ✅ both compile to `OP_ScriptFarFunctionCall custom_scripts/ix/core/util add_one` on both compilers. Runtime loading of that path is **not run** (R-S6) |
| V9 | Builtin table diff (v1.1.0 vs develop) | 503 methods and 5 functions resolvable only on develop; 3 duplicate names in v1.1.0 |
| V10 | `tools/setup_compilers.sh` run from an empty directory | ✅ exit 0. Both binaries built; each produces **byte-identical** `.gscbin` output to the hand-built compilers of V1/V2. The version string reads `0.0.0.1` for both, because it comes from git metadata a shallow fetch lacks; this is cosmetic |
| V11 | BO3 archive integrity | ✅ Dropbox `content_hash` recomputed locally (`7fe78384…eaef7`) matches the API value |
| V12 | BO3 extraction (7-Zip 23.01; the archive uses LZMA2 + LZMA + BCJ2) | ✅ 69 files, 1,651,921,753 bytes, "Everything is Ok" |
| V13 | `core_mod.ff` decompression | ✅ 492 zlib + 6 stored blocks → 113,981,208-byte zone (header size field ≈ 114 MB); 360,220 bytes in 7 unframed regions passed through |
| V14 | Script carve + T7 decompile | ✅ 216 objects carved (162 GSC / 49 CSC / 5 GSH); 211 decompiled by gsc-tool `-g t7` |
| V15 | `tools/bo3_reference/extract_aae.sh` run from an empty directory | ✅ ~31 s; decompiled output byte-identical to the analysis run (`diff -rq` clean) |

## 3. Runtime test environment (for testers)

1. Windows PC with a legally owned Steam copy of *Call of Duty: Infinite Warfare*.
2. iw7-mod installed (`auroramod/docs` → *iw7-install*). Record the client version: **v1.1.0** or a develop build.
3. Install the mod folder (from Phase 1 on): copy `mods/infinite_expansion` into `<Infinite Warfare>/mods/`, then load it from the in-game **Mods** menu.
4. Logs: the iw7-mod console (`~`) and `iw7-mod/logs/console.log`, available since iw7-mod v1.0.3. Report every line starting with `[IX]` and any `script compile error` block.

## 4. Runtime checklist

Result values are **not run**, **pass**, **fail**, or **n/a**. Fill in the `vX.Y` columns by client version.

### 4.1 Game startup

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-S1 | Load the mod, start a zombies match (`cp_zmb`) | No `script compile error` in the console; `[IX] init` logged once | not run | not run |
| R-S2 | Start an MP private match | Same as R-S1 for MP | not run | not run |
| R-S3 | Menu opens (ADS + Melee) | Menu visible; weapons/offhands disabled while open | not run | not run |
| R-S4 | Menu closes (Melee at root) | Menu hidden; weapons restored | not run | not run |
| R-S5 | `map_restart` / fast restart | Init runs once per load; no duplicate HUD/threads | not run | not run |
| R-S6 | Module loading by reference (`custom_scripts/ix/...`) | Modules compile and load in-game | not run | not run |

### 4.2 Player

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-P1 | Spawn | Per-player features applied | not run | not run |
| R-P2 | Death → respawn / last stand → revive | Features re-applied; no duplicate threads | not run | not run |
| R-P3 | Weapon switching | Weapon features follow the new weapon | not run | not run |
| R-P4 | Movement options on/off | Effect visible; **off fully restores** stock behaviour | not run | not run |
| R-P5 | God mode on → off | Damage blocked, then taken again (checks the `_meth_80A1` fix) | not run | not run |

### 4.3 Zombies

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-Z1 | Round transitions | Round start/end events fire once per wave | not run | not run |
| R-Z2 | Zombie spawning with modifiers | Speed/health modifiers applied to newly spawned zombies | not run | not run |
| R-Z3 | Zombie death | Counters update correctly | not run | not run |
| R-Z4 | Player death / bleed-out | No script errors; menu and HUD recover | not run | not run |
| R-Z5 | Restart | State reset; no leaked HUD elements | not run | not run |

### 4.4 Configuration

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-C1 | Change a setting in the menu | Applied live; `ix_<id>` dvar updated | not run | not run |
| R-C2 | `set ix_<id> <value>` in the console | Applied within ~0.5 s; menu reflects it | not run | not run |
| R-C3 | Reset one / reset all | Defaults restored | not run | not run |
| R-C4 | Presets | All values match the preset table | not run | not run |
| R-C5 | Persistence (mod-folder install) | `ix_settings.cfg` written; values restored next load | not run | not run |
| R-C6 | Persistence without fs_game (loose install) | No script error; menu reports session-only | not run | not run |

### 4.5 Compatibility matrix

The mod claims support **only** for cells marked pass.

| Map / mode | v1.1.0 | develop |
|------------|--------|---------|
| `cp_zmb` (Zombies in Spaceland) | not run | not run |
| `cp_rave` (Rave in the Redwoods) | not run | not run |
| `cp_disco` (Shaolin Shuffle) | not run | not run |
| `cp_town` (Attack of the Radioactive Thing) | not run | not run |
| `cp_final` (The Beast from Beyond) | not run | not run |
| MP private match / combat training (host) | not run | not run |
| Dedicated server (MP/CP) | not run | not run |
