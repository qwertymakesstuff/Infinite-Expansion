# CHANGELOG

All notable changes to this project. Format based on *Keep a Changelog*.

## [Unreleased]

### Scope: zombies only (2026-10-06)

Multiplayer support was dropped at the project owner's request.

**Removed**
- The multiplayer entry script `custom_scripts/mp/ix_main.gsc` and the `ix/mp` module.
- The `faux_spawn` watcher; only multiplayer sends that notify.

**Changed**
- `bootstrap::start(modules)` no longer takes a mode, and the init line no longer prints `mode=`.
- `check.py`: the multiplayer/shared separation rule is replaced by a zombies rule. A stock far-call target must be a script that **every** zombies map loads; anything else ends the match with a script link error. The rule uses each map's link closure, computed from the dump. The `modes` check is now `layout`.
- Docs: `ARCHITECTURE.md` §7 is now the zombies scope rules. `TESTING.md` R-S2 is now a co-op check.

**Added**
- `check.py` `source` rejects `//` comments that end in a backslash: both compilers silently drop the next line (C9).

**Findings**
- 126 stock scripts load on every zombies map, including everything the feature plan uses. `scripts\mp\hud_util` loads on none, so `IW_API_NOTES.md` §7 is corrected; map scripts load only on their own map (L25).

### Phase 1 — Foundation (2026-10-06)

**Added**
- The mod folder `mods/infinite_expansion/` (version 0.1.0) with `desc.txt`.
  - Entry scripts `custom_scripts/cp/ix_main.gsc` and `custom_scripts/mp/ix_main.gsc`.
  - `ix/core/bootstrap.gsc`: duplicate-init guard, master switch `ix_enabled`, `level.ix` state, init order (core `setup()`, then each module's `register()`), the lifecycle notifies `ix_ready`, `ix_player_connected`, `ix_player_spawned`, and `ix_shutdown`, plus `ix_version`.
  - `ix/core/log.gsc`: `[IX] LEVEL:` console lines, `ix_debug_log`, and a 32-line ring buffer.
  - `ix/core/compat.gsc`: client feature detection and the nine raw-id wrappers (`god_off`, `local_sound`, `third_person`, `fire_rate_on`/`off`, `recoil_get`/`off`, `spread_reset`, `has_perk`).
  - `ix/core/util.gsc`: the first helpers.
  - One placeholder module per area (player, weapons, zombies, mp, debug, ui).
- `tools/ixcc`: compiles a script the way iw7-mod's in-game loader does, with iw7-mod's 28 extension built-ins registered. `setup_compilers.sh` now builds it for both pins and fetches the pinned stock-script dump.
- `tools/check.py`: compile with both compilers, parity, stub natives and raw ids, far-call targets, mode separation, source rules, and the per-mode memory budget.
- `tools/tests`: 11 tests on a rule-breaking and a clean fixture mod.

**Findings**
- An unresolved script reference is a `script link error` that drops the match (L23).
- Script runtime errors are silent unless `developer_script` is on, and that dvar also compiles `/# #/` blocks (L24). Testers now launch with `+set developer_script 1`.
- Both compilers reject a script function named after a built-in.
- An unknown raw id compiles silently (C6), and iw7-mod's extension ids depend on registration order (C7). `check.py` catches both.
- `scripts\engine\utility::waittill_any` ends its caller on any notify but the first, so the bootstrap uses one watcher thread per notify.
- iw7-mod's own scripts use 711 bytes (CP) and 6,823 bytes (MP) of the 1 MiB custom-script memory.

**Changed**
- Module entry points are `register()` (feature modules) and `setup()` (core). Only entry scripts define `init()`, which iw7-mod runs in every auto-loaded file. `ARCHITECTURE.md` §3 documents the implemented flow.

**Not yet verified in-game**: everything under `mods/`. `TESTING.md` R-S1, R-S2, and R-S5 to R-S9 are the first runtime checks.

### Phase 0 — BO3 reference analysis completed (2026-10-06)

**Added**
- `PROJECT_ANALYSIS.md` §1 rewritten from the real AAE v3.9.5 package: folder structure, method and limits, script structure, init flow, configuration flow (~80 `tfoption_*` keys), the five UI surfaces, shared utilities, assets, multiplayer handling, and dependencies.
- §3 compatibility matrix rebuilt from AAE's actual options (116 rows), each mapped to a verified IW7 mechanism. §4 records the decisions that follow.
- `tools/bo3_reference/` reproduces the analysis workspace from the archive in about 30 s: fastfile decompressor, script carver, LUI string inventory, localized-string extractor, and Dropbox hash checker.
- `ARCHITECTURE.md` §10 maps AAE's components onto this design. Limitations L21 and L22 added; E1 resolved.

**Findings**
- AAE's primary UX is client-side LUI: lobby "Custom Mutations" options, client options, career screen, and HUD widgets. Its GSC menu is a gated dev/cheat menu.
- AAE's configuration is a flat key set, saved by the UI and read by GSC at match start behind a version guard. Infinite Expansion adopts the same model with `ix_*` keys and a GSC-written settings file.

### Phase 0 — Project forensics (2026-10-06)

**Added**
- `PROJECT_ANALYSIS.md`: IW7 modding environment (tools, language, APIs, build, packaging, testing, limitations) and a provisional BO3 feature inventory with a feature compatibility matrix.
- `IW_API_NOTES.md`: verified IW7 / iw7-mod scripting reference, with a source for every entry.
- `KNOWN_LIMITATIONS.md`, `ARCHITECTURE.md` (proposed), `FEATURE_STATUS.md`, `TESTING.md`, `README.md`.
- `tools/setup_compilers.sh`: builds the two gsc-tool versions that iw7-mod embeds (v1.1.0 pin `833822d0`, develop pin `0be361a4`).
- `tools/extract_iw7_builtins.py`: dumps builtin function and method tables for comparison.

**Findings**
- The iw7-mod v1.1.0 compiler resolves `disableinvulnerability` and `playlocalsound` to the wrong natives. This was verified by compiling and disassembling. The mod will use raw ids `_meth_80A1` and `_meth_8242`.
- 503 method and 5 function names compile only on iw7-mod develop. Raw `_meth_` ids work on both.

**Blocked**
- BO3 reference archive (`/AllAroundEnhancement.7z`): not downloadable in the build environment (egress policy). Its file-level analysis is pending.
