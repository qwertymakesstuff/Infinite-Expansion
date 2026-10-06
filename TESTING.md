# TESTING.md

## 1. Verification levels

| Level | Where it can run | Covers |
|-------|------------------|--------|
| **Static** | Any Linux machine with `tools/` (including this dev environment): `python3 tools/check.py` | Both compilers (with iw7-mod's extension built-ins), release/develop parity, stub natives and raw ids, far-call targets (and stock scripts loaded on every zombies map), layout, source rules, bytecode budget |
| **Runtime** | **Windows + legally owned Infinite Warfare + iw7-mod only** | Everything else: behaviour, timing, HUD, input, co-op |

Runtime tests **cannot** be executed in the development environment. Every runtime item below stays **not run** until a tester reports a result, and `FEATURE_STATUS.md` will not mark a feature COMPLETE without one.

## 2. Verification log (actually performed in the development environment)

### Phase 0

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

### Phase 1

| # | Check | Result |
|---|-------|--------|
| V16 | `tools/setup_compilers.sh` (now also builds `ixcc` and fetches the stock dump) run from an empty directory | ✅ exit 0 in 504 s from an empty directory: both pins, both `ixcc` binaries, and the stock dump at `1dd48a78`. `check.py` with that toolchain passes, and its compiled and disassembled output is byte-identical to the development toolchain's (`diff -r` clean) |
| V17 | `ixcc` built by the setup script vs. built by hand | ✅ byte-identical `.gscbin` for all 12 mod scripts, both pins |
| V18 | `python3 tools/check.py` on the mod | ✅ PASS, 0 errors, 0 warnings: 24/24 compiled, 12/12 identical between compilers, 31 built-in calls, 30 far references, 10 scripts load per mode, 9 raw ids (all in `compat.gsc`), 0 source issues, 1,481 bytes of custom-script memory per mode (0.14% of 1 MiB) |
| V19 | `python3 -m unittest discover -s tools/tests` | ✅ 11 tests OK. `bad_mod` gives exactly the 23 planted errors and 1 planted warning; comments, strings, iw7-mod extensions (`va`, `tell`, `fileexists`, `logprint`), and a valid stock call are not flagged; `good_mod` passes with 0 warnings; `--budget 100` fails both modes |
| V20 | A script function named after a built-in (`clamp`) | ✅ rejected by both compilers: `function name 'clamp' already defined as builtin` |
| V21 | Unknown raw id `self _meth_85CB()` | ⚠️ compiles on both **without** an error (`KNOWN_LIMITATIONS.md` C6); `check.py` `natives` rejects it |
| V22 | iw7-mod's own bundled scripts compiled with `ixcc` (both pins) | ✅ CP 711 bytes, MP 6,823 bytes of custom-script memory, the same on v1.1.0 and develop (`IW_API_NOTES.md` §2) |
| V23 | Stock zombies map `main()` functions (static read of the dump) | ✅ none of the five waits; the four damage-callback overrides happen there, before any player connects (basis for `ix_ready`) |
| V24 | `check.py` without the stock dump (`--stock /nonexistent`) | ✅ stock far calls become warnings ("not verified"); exit 0 |
| V25 | `check.py` with a missing toolchain | ✅ lists the missing files; exit 2 |

### Scope change: zombies only

| # | Check | Result |
|---|-------|--------|
| V26 | A `//` comment ending in a backslash, followed by `level.swallowed = 1;` | ⚠️ both compilers **silently drop** the next line (missing from the disassembly, no error; `KNOWN_LIMITATIONS.md` C9). `check.py` `source` now rejects such comments |
| V27 | Link closure of each zombies map in the dump (level script + `scripts\cp\gametypes\zombie`, following named and hashed references) | ✅ 126 stock scripts are common to all five maps; every referenced script exists in the dump. `scripts\mp\hud_util` is linked on none, and `cp_town_damage` only on `cp_town` |
| V28 | `python3 -m unittest discover -s tools/tests` after the change | ✅ 11 tests OK; `bad_mod` gives exactly its 24 planted errors and 1 planted warning, including the map-specific and never-loaded stock calls and the backslash comment |
| V29 | `python3 tools/check.py` on the zombies-only mod | ✅ PASS, 0 errors, 0 warnings: 20/20 compiled, 10/10 identical, 23 far references, 10 scripts load, 1,430 bytes of custom-script memory |

### Phase 1.5 (characters)

| # | Check | Result |
|---|-------|--------|
| V30 | Stock character system read from the dump: registration, assignment, release, portrait omnvar, unlock stats, VO prefixes | ✅ recorded in `IW_API_NOTES.md` §15 |
| V31 | `python3 tools/check.py` | ✅ PASS, 0 errors, 0 warnings: 24/24 compiled, 12/12 identical, 158 built-in calls, 49 far references (6 into stock scripts, all loaded on every zombies map), 12 scripts load, 7,453 bytes |
| V32 | `tools/tests/test_character_data.py`: the cast table vs. each map's registration, the lobby ids, and the soul key each map awards | ✅ 5 tests OK. A planted wrong head model and a wrong lobby id are both caught |
| V34 | `luac5.1 -p` on iw7-mod's own 31 ui_scripts | ✅ all parse, so Lua 5.1 syntax checking is meaningful for IW7's Lua |
| V35 | `check.py` `lua` on `ui_scripts/InfiniteExpansion/__init__.lua` | ✅ syntax OK; all 92 API names occur in iw7-mod's ui_scripts at `c0a1c6da`; the scripts it builds on are identical at v1.1.0 |
| V36 | Checker tests with Lua fixtures | ✅ 17 tests OK. `bad_mod` adds a syntax error, three invented names (`Engine.SetPlayerData`, `:SetMagicColor()`, `MakeMagicHappen()`), a folder named like iw7-mod's `MainMenu`, and a folder without `__init__.lua`: all six reported. Comments, strings, real API names and local functions are not flagged |
| V33 | Disassembly spot check | ✅ `OP_ScriptFarMethodThreadCall scripts/cp/zombies/zombies_loadout setmodelfromcustomization 1`; waittill on a variable notify name; built-ins identical on both compilers |

### Phase 1.5 (characters chosen before the match; guests)

| # | Check | Result |
|---|-------|--------|
| V37 | iw7-mod's join code read at v1.1.0 (`1b76f04e`) and develop (`c0a1c6da`): `party.cpp` `check_download_mod` and the `getInfo` handler, `utils/hash.cpp` | ✅ A host with `fs_game` set and no `mod.ff` sends an empty `mod_hash`, and a joining client stops with "Server 'mod_hash' is empty" (L30). Not yet seen in-game: R-S10 |
| V38 | iw7-mod writes coop stats from the frontend with `setCoopPlayerData <path> <value>` and then `uploadstats` (`stats.cpp`: `director_cut`, `unlockstatsEE`) | ✅ The CHARACTER menu writes `zombiePlayerLoadout characterSelect` the same way |
| V39 | `python3 tools/check.py` | ✅ PASS, 0 errors, 0 warnings: 24/24 compiled, 12/12 identical, 125 built-in calls, 43 far references (6 into stock scripts, all loaded on every zombies map), 12 scripts load, 6,204 bytes; `lua`: 94 API names |
| V40 | `tools/tests/test_character_data.py` | ✅ 6 tests OK. The new menu test compares the menu's lobby values with the GSC cast table. A wrong value, a lobby value on a regular character, and a commented-out row are all caught |

## 3. Runtime test environment (for testers)

1. Windows PC with a legally owned Steam copy of *Call of Duty: Infinite Warfare*.
2. iw7-mod installed (`auroramod/docs` → *iw7-install*). Record the client version: **v1.1.0** or a develop build.
3. Install the mod: copy `mods/infinite_expansion/custom_scripts` and `mods/infinite_expansion/ui_scripts` into `<Infinite Warfare>/iw7-mod/`. Every player in a co-op test installs it the same way. The Mods-menu install (`mods/infinite_expansion` in `<Infinite Warfare>/mods/`) works for solo tests only (L30, R-S10).
4. Launch with `+set developer_script 1`. Without it, script runtime errors are not printed at all (`KNOWN_LIMITATIONS.md` L24).
5. Logs: the iw7-mod console (`~`) and `iw7-mod/logs/console.log`, available since iw7-mod v1.0.3. Report every line starting with `[IX]` and any `script compile error`, `script link error`, or `script runtime error` block.
6. **No `[IX]` lines at all?** Check that `<Infinite Warfare>/iw7-mod/custom_scripts/cp/ix_main.gsc` exists. Then try the Mods-menu install, check that the console's `----- FS_Startup -----` list includes `mods/infinite_expansion`, and report which install worked.
7. Mod dvars for testing:
   - `ix_debug_log 1`: extra `[IX] DEBUG:` lines (player connect and spawn). Takes effect immediately.
   - `ix_enabled 0`: turns the whole mod off from the next map load.
   - `ix_version`: set by the mod, shows the loaded version.

## 4. Runtime checklist

Result values are **not run**, **pass**, **fail**, or **n/a**. Fill in the `vX.Y` columns by client version.

### 4.1 Game startup

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-S1 | Load the mod, start a zombies match (`cp_zmb`) | No `script compile error` / `script link error`. Exactly one `[IX] INFO: init 0.1.0 map=cp_zmb modules=player,weapons,zombies,debug,ui`, then `[IX] INFO: client …`, then `[IX] INFO: ready` once you are in | not run | not run |
| R-S2 | Zombies co-op: a second player joins the host's match | One `[IX] INFO: init` on the host only; with `ix_debug_log 1`, one `player connected` line per player | not run | not run |
| R-S3 | Menu opens (ADS + Melee) *(Phase 3)* | Menu visible; weapons/offhands disabled while open | not run | not run |
| R-S4 | Menu closes (Melee at root) *(Phase 3)* | Menu hidden; weapons restored | not run | not run |
| R-S5 | `map_restart` / fast restart | One `init` line per load; with `ix_debug_log 1`, one `player connected` line per player per load | not run | not run |
| R-S6 | Module loading by reference (`custom_scripts/ix/...`) | Modules compile and load in-game (the `modules=` list in R-S1 is complete) | not run | not run |
| R-S7 | `set ix_enabled 0`, then load a map | Only `[IX] INFO: disabled by dvar ix_enabled 0`; no other `[IX]` lines | not run | not run |
| R-S8 | Client feature line from R-S1 | v1.1.0: `omnimovement=0 sprint_unlimited=0 air_control=0`; develop: all `1`. `fs_game=1` when loaded from the Mods menu, `0` for a loose `iw7-mod/custom_scripts` install | not run | not run |
| R-S9 | `set ix_debug_log 1`, spawn; in co-op, also bleed out and respawn at the next round | `[IX] DEBUG: player connected: <name>` once; `[IX] DEBUG: player spawned: <name> (spawn N)` once per spawn, N rising by 1 | not run | not run |
| R-S10 | Co-op join with each install: the host loads the mod (a) into `iw7-mod/`, (b) from the Mods menu; a friend joins | (a) the friend joins. (b) the friend gets "Server 'mod_hash' is empty" (L30). Report both | not run | not run |

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

### 4.5 Characters (Phase 1.5)

Characters are chosen in the CHARACTER menu before a match (§4.6) and kept for the whole match. For testing locked characters, iw7-mod's console command `unlockallEE` unlocks every special character (it sets the soul keys and the Beast merit). Co-op tests need a second PC (or a second account) with the mod installed the same way. `getCoopPlayerData` is expected to mirror iw7-mod's `setCoopPlayerData` and print the value (iw7-mod restores that printing: `Com_DDL_PrintState` in `stats.cpp`); if the command does not exist, report that.

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-CH1 | Host: pick Andre in the menu, start `cp_zmb` | You spawn as Andre; the console shows `[IX] INFO: character: <you> -> Andre (ix_character)` | not run | not run |
| R-CH2 | During a match, type `!char 1` in chat, then `set ix_character sally` in the console | Nothing changes until the next match, and the mod does not reply | not run | not run |
| R-CH3 | Co-op: the guest picks a special they have unlocked (The Hoff), then joins the host's `cp_zmb` | The guest is The Hoff; the host's console shows `(lobby)` | not run | not run |
| R-CH4 | Co-op: the guest picks Poindexter, then joins | The guest gets a random character | not run | not run |
| R-CH5 | Co-op: host and guest both pick The Hoff | The second to connect gets a random character and "Can't play as The Hoff: The Hoff is taken by <name>" | not run | not run |
| R-CH6 | Pick The Hoff without the Spaceland soul key, host `cp_zmb`; repeat after `unlockallEE` | First a random character and "Can't play as The Hoff: The Hoff is locked: earn the soul key on Zombies in Spaceland"; then The Hoff | not run | not run |
| R-CH7 | `set ix_character_crossmap 1`, pick The Hoff, load `cp_town` | **Experimental:** report whether the map loads, what the body and arms look like, and any console error. With the setting off: a random character and "... belongs to Zombies in Spaceland ..." | not run | not run |
| R-CH8 | Co-op: the guest picks an unlocked special, then joins a host **without** this mod on that special's map | The guest is that special (the stock lobby rule) | not run | not run |
| R-CH9 | Player card | Bottom right, not covering the ammo counter; `ix_player_card 0` hides it; `ix_player_card_y 140` moves it up | not run | not run |
| R-CH10 | A match with default settings; then `set ix_character_announce 1` and a new match (co-op if possible); then `set ix_character_select 0` and a new match | First no "is playing as" lines. With the setting on, after the intro, everyone sees one line per player, such as "<guest> is playing as The Hoff". With selection off, the game picks characters as usual | not run | not run |
| R-CH11 | Die or bleed out, then respawn | Same character and knife as before | not run | not run |
| R-CH12 | Probe for L29, in the zombies main menu console: `setCoopPlayerData zombiePlayerLoadout characterSelect 14`, then `getCoopPlayerData zombiePlayerLoadout characterSelect` | Report the printed value (14, another number, or an error). Afterwards pick any character in the CHARACTER menu, which writes the field again | not run | not run |

### 4.6 Zombies main menu (Lua UI)

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-UI1 | Load the mod, open Zombies | A CHARACTER button under the other buttons, styled like them; its description shows on hover and does not overlap the button | not run | not run |
| R-UI2 | Press CHARACTER | A list: Random, Sally, Poindexter, Andre, A.J., then the five specials; hovering shows the outfits per map; Back returns | not run | not run |
| R-UI3 | Pick Andre, then start a solo match | You play as Andre; the console shows `(ix_character)`; after restarting the game the menu still says "Selected: Andre" | not run | not run |
| R-UI4 | Pick a special you have not unlocked, then start a match | A random character, and after the intro "Can't play as ...: ... is locked: ..." | not run | not run |
| R-UI5 | Pick The Hoff, then run `getCoopPlayerData zombiePlayerLoadout characterSelect`; pick Sally and run it again | `1`, then `0`; no console error from `setCoopPlayerData` or `uploadstats` | not run | not run |

### 4.7 Compatibility matrix

The mod claims support **only** for cells marked pass.

| Map / mode | v1.1.0 | develop |
|------------|--------|---------|
| `cp_zmb` (Zombies in Spaceland) | not run | not run |
| `cp_rave` (Rave in the Redwoods) | not run | not run |
| `cp_disco` (Shaolin Shuffle) | not run | not run |
| `cp_town` (Attack of the Radioactive Thing) | not run | not run |
| `cp_final` (The Beast from Beyond) | not run | not run |
| Zombies co-op (host + 1–3 players) | not run | not run |
