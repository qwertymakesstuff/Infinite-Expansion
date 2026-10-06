# CHANGELOG

All notable changes to this project. Format based on *Keep a Changelog*.

## [Unreleased]

### Character pictures from the HUD's cards (2026-10-06)

**Added**
- **`Build Character Pictures.cmd`** (optional, experimental). It copies the character cards the HUD shows in a match out of the player's own game files into a small picture pack, `iw7-mod/zone/ix_portraits.ff`. Nothing of the game's art ships with the mod.
  - It downloads [x64-zt](https://github.com/Joelrau/x64-zt) and runs it in the game folder once per map, so a map that is missing or fails costs only its own cards. It then builds the pack and deletes x64-zt and its work files.
  - Each card becomes its own material (`ix_card_*` for the main card, `ix_icon_*` for the team card). The materials refer to the game's own menu shaders instead of copying them.
  - Log: `%TEMP%\InfiniteExpansionPictures.log`. UNINSTALL removes the pack.
- With the pack, the CHARACTER menu shows each character's main card from the map selected in the lobby. The team card (the small picture the HUD shows for teammates) appears beside each row, and in the big picture when a main card is missing. Without the pack, nothing changes. `ix_pictures 0` turns the pictures off.
- Tests: the cards to copy and the x64-zt runs; x64-zt's build input from a fake dump; the console exchange and the whole script against a stand-in for x64-zt (`tools/tests/fake_zonetool.py`); the menu with a pack.

**Source**
- x64-zt's behaviour comes from its source (`IW_API_NOTES.md` §18). It has not been run on a real install yet (`TESTING.md` R-PK1–R-PK4, `KNOWN_LIMITATIONS.md` L37).

### Third in-game report: the pick still did not apply (2026-10-06)

**Fixed**
- Choosing a character in the menu still did not change the character in the match.
  - The second attempt wrapped the gametype's loadout function from the mod's start-up. Whether that wrapper is in place in time depends on the order in which the game runs its scripts, and in-game it was not.
  - The mod now replaces the stock function that decides a player's character (`zombies_loadout::get_player_character_num`) with its own, using iw7-mod's `replacefunc`. The stock code calls it on the player at every spawn, so the pick is made exactly when the game asks. Without a pick it hands out a random free character, as the stock function did.
  - With `ix_character_select 0` the stock function is left alone.

### Second in-game report: the pick is applied, CHARACTER moves to the lobby (2026-10-06)

**Fixed**
- The chosen character was not applied. The card in the corner named the pick, but the player was someone else.
  - The game picks a character inside its loadout function, on the first spawn. The mod's pick ran from a second notify after "connected" and arrived after that spawn.
  - The mod now wraps that function (`level.custom_giveloadout`) and makes the pick right before the stock code reads it. A pick that would come too late is not applied halfway, and the console says so.
  - Every outcome is logged as `[IX] INFO: character: …` in the console and in `iw7-mod/logs/console.log`.
- CHARACTER menu text: the name is now large (44) and the description normal (22). IW7 sizes text by the height of its element, and the description's element was 100 tall.

**Changed**
- The CHARACTER button moved from the zombies main menu into the lobby that Solo Match and Custom Game open, right under SELECT SHOW. The buttons under it move down one step, in both of the lobby's layouts (with and without BOSS BATTLE).
- The stock lobby clears the special-character field `characterSelect` every time it opens. The mod puts back a special character chosen in the CHARACTER menu while it is still unlocked.
- Willard Wyler needs The Beast from Beyond's soul key and its merit, as in the stock lobby. The stock lobby also requires Director's Cut; the mod does not (L27).

**Added**
- A picture of the highlighted character: the game's own pictures of the five special characters, and colored initials for the four regular characters and Random, which have no picture in the game's menus (L28).
- Locked special characters are marked "(locked)", say how to unlock them, and cannot be chosen. `ix_character_specials 2` allows them, `0` turns specials off.
- Tests: the lobby list in every load order and both layouts, the lobby field after the stock reset, and the CHARACTER menu's text sizes, pictures and locks.

**Source**
- The lobby's layout, element names and rules come from the game's compiled menu scripts in a public dump, read as data and never run (`IW_API_NOTES.md` §16).

### Fixes from the first in-game report (2026-10-06)

**Fixed**
- The CHARACTER button was missing in the zombies menu when the mod was installed into `<game>\iw7-mod\` (the setup's install).
  - iw7-mod runs scripts from that folder before its own, and its own MainMenu script then replaced the button list, wrapper included (L33).
  - The menu script now hooks `MenuBuilder.BuildRegisteredType` and adds the button when the list is built, in either load order and only once.
- Docs: iw7-mod's search order is `<game>/iw7-mod`, then its client data, then the engine's paths; v1.1.0's Lua `io` table can write files, develop's cannot.

**Added**
- Your Steam name instead of "Unknown Soldier" (L34).
  - The setup reads it from Steam's `loginusers.vdf` (the logged-in or most recent account) and writes it next to the menu script.
  - The menu script sets iw7-mod's `name` setting from it, only while that is still "Unknown Soldier".
  - Names with characters the game cannot show are skipped, and the status line says so.
- `tools/tests/test_menu_script.py` and `menu_harness.lua`: the menu script in plain Lua 5.1, in both load orders. Steam-name tests in `test_installer.py`.
- `check.py` `lua`: `io.*` names are checked against iw7-mod's own scripts too.

**Notes**
- The mod does not appear in the game's Mods menu. It loads from the iw7-mod folder by itself (README).

### Setup installs iw7-mod and starts the game (2026-10-06)

**Added**
- INSTALL now also sets up the iw7-mod client when the game folder has none.
  - It downloads `iw7-mod.exe` from the latest GitHub release, or from iw7-mod's own update server if that fails, and checks it against the listed checksum (SHA-256 / SHA-1).
  - It places the file in the game folder, as iw7-mod's install guide says, and adds an **IW7-Mod (Infinite Warfare)** desktop shortcut.
  - The download runs in the background with progress in the window. DOWNLOAD in the iw7-mod row does only this step.
- The green button walks through INSTALL → UPDATE → **PLAY**. PLAY starts iw7-mod from the game folder and opens Steam first if it is not running. REINSTALL copies the mod again.
- No game yet: **STEAM** opens Steam's install dialog for Infinite Warfare (`steam://install/292730`; the store page if Steam is missing). The window checks again every 4 seconds and notices when the game is there.
- A write check before downloading, so a protected game folder gets the offer to retry as administrator.
- `-NoWindow` installs also download iw7-mod when it is missing.
- Tests: the download against a local fake of GitHub and the update server, and the window's background download in a second runspace.

**Not verified**
- The real GitHub API and update server cannot be reached from the development environment (E6); R-I10–R-I13 check them on a player's PC.

### One-click Windows setup (2026-10-06)

**Added**
- `Infinite Expansion Setup.cmd` opens a setup window (`installer/`) with INSTALL / UPDATE and UNINSTALL buttons.
  - It finds Infinite Warfare through Steam (registry, every library in `libraryfolders.vdf`, the game's app manifest), or the player picks `iw7_ship.exe` with BROWSE.
  - It shows whether the iw7-mod client is there and which version of the mod is installed.
  - Installing copies the mod into `<game>\iw7-mod\`, records the copied files, removes files an older version left, removes the old Mods-menu copy's files, and adds an entry to *Windows Settings → Apps*. Uninstalling removes exactly the recorded files.
  - Artwork, all original vector drawings: a synthwave sunset with a striped sun, a neon ferris wheel, a scrolling pink grid, toxic fog and zombie hands rising from the ground; plus an app icon (`installer/ix.ico`, source `ix-icon.svg`).
  - Errors go to `%TEMP%\InfiniteExpansionSetup.log`. A protected game folder gets an offer to retry as administrator. `-NoWindow` installs or uninstalls from a script.
- `tools/tests/test_installer.py` and `ps51_lint.ps1`: the install logic runs with PowerShell 7 on fake Steam libraries, and the window's files are checked for Windows PowerShell 5.1 and `XamlReader` compatibility. `setup_compilers.sh` fetches PowerShell 7.4.6 for them.
- `.gitattributes`: `.cmd` files keep CRLF line endings, also in GitHub's zip downloads.

**Not verified**
- The window has not been opened yet: WPF needs Windows, and the .NET SDK that could compile-check the XAML cannot be downloaded here (E5). `TESTING.md` §4.8 lists what to check.

### Phase 1.5 — Characters chosen before the match; guests (2026-10-06)

**Changed**
- Characters are chosen only before a match, in the CHARACTER menu. The choice is applied when the player connects and kept for the whole match.
- The menu also writes a special-character pick into the stock lobby field `zombiePlayerLoadout.characterSelect` (`setCoopPlayerData`, then `uploadstats`, like iw7-mod's own Director's Cut setting).
  - Each player's stats reach the host's match, so a guest's special pick follows them into other players' matches.
  - On the special's own map it works even when the host does not have the mod.
- Every special pick is checked against the unlock stats, including picks from the stock lobby (L27). A refused pick gets a random character, as in the stock game, and a message says why.
- No two players can get the same special any more; the stock game allowed it.
- Installation: copy the mod into `<game>/iw7-mod/` (README). A host who loaded the mod from the Mods menu cannot be joined (L30).

**Added**
- Optional, off by default: after the intro, everyone sees "<player> is playing as <character>" for each player (`ix_character_announce 1`).
- `test_character_data.py`: the menu's lobby values must match the cast table.

**Removed**
- The `!char` chat commands, and applying `ix_character` changes mid-match. The knife swap that went with switching is gone too.

**Blocked**
- A guest's pick of a regular character (Sally, Poindexter, Andre, A.J.) cannot reach the host, because no stats field is known to hold it (L29). The guest gets a random character. R-CH12 is a console probe that could unblock it.

**Findings**
- iw7-mod v1.1.0 and develop do not let players join a host whose `fs_game` is set when it has no `mod.ff`: "Server 'mod_hash' is empty" (`party.cpp`, L30).

### Phase 1.5 — CHARACTER button in the zombies menu (2026-10-06)

**Added**
- `ui_scripts/InfiniteExpansion/__init__.lua`: a base-game style CHARACTER button under the zombies main menu's buttons.
  - It opens a list (Random, the four regular characters, the five specials). Hovering shows each character's outfit on every map.
  - Picking one saves the archived dvar `ix_character`, which the GSC applies to the host at match start (L29). `random` lets the game pick.
  - It is built only from widgets and calls that iw7-mod's own ui_scripts use.
- `check.py` `lua`: `luac5.1` syntax, plus API names checked against iw7-mod's ui_scripts (pinned and fetched by `setup_compilers.sh`), plus folder rules. Lua fixtures in `tools/tests`.

### Phase 1.5 — Characters (2026-10-06)

**Added**
- `ix/player/character.gsc`: choose who you play as.
  - In chat, `!char` lists the map's cast and `!char <number or name>` switches. The host can also set the `ix_character` dvar.
  - The switch is immediate: body, arms, voice and knife change, and the stock HUD portrait follows. A downed player switches on the next spawn.
  - Characters are unique per match, and the stock random pool stays consistent.
  - Each map has its own cast list. The actor names come from the stock VO code; the outfit labels come from each map's model names.
  - Special characters (The Hoff, Willard Wyler, Kevin Smith, Pam Grier, Elvira) are available to players who have unlocked them through soul keys or, for Willard, the Beast merit (`ix_character_specials`).
  - Experimental and opt-in: special characters on maps other than their own (`ix_character_crossmap 1`, L26). A special picked in the stock lobby is then honoured on any map.
- `ix/ui/player_card.gsc`: a bottom-right card with the character's name and outfit (`ix_player_card`, `_x`, `_y`). There is no picture yet (L28).
- `ix/core/util.gsc`: `dvar_int` and `dvar_string` for settings with defaults.
- `tools/tests/test_character_data.py`: checks the character table against the stock scripts.

**Findings**
- The stock character system, the HUD portrait omnvar and the unlock stats (`IW_API_NOTES.md` §15).
- Each special character's models are referenced only by its own map, so they are probably missing elsewhere (L26).

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
