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

### One-click Windows setup

| # | Check | Result |
|---|-------|--------|
| V41 | `tools/tests/test_installer.py`, installer logic with PowerShell 7.4.6 (sha256-checked) on fake Steam libraries | ✅ The game is found in a second Steam library (both `libraryfolders.vdf` formats). Install copies every payload file and writes the record. Updating removes a file an older version left. Uninstall removes exactly the recorded files and leaves another mod's script and `iw7-mod/players2` alone. The Mods-menu copy loses only its own files. Record entries that point outside the mod's folders (`..`, absolute paths, `players2/…`) are ignored |
| V42 | `IXSetup.ps1 -NoWindow` under PowerShell 7 | ✅ Installs and uninstalls the fake game folder; a wrong folder exits 1 with a message and creates nothing |
| V43 | Windows PowerShell 5.1 compatibility (`tools/tests/ps51_lint.ps1`): parse errors, PowerShell 7 syntax (`?:`, `??`, `&&`, `?.`), 5.1-missing parameters, three-part `Join-Path`, `$IsWindows`; ASCII-only scripts | ✅ Clean. A sample with each problem is flagged |
| V44 | `IXSetup.xaml`: well formed; no `x:Class` or event attributes (so `XamlReader.Load` accepts it); every control the script uses, resource key and storyboard target exists; only known WPF element types; each element/attribute pair reviewed against WPF | ✅ All checks pass. The window itself has not been opened (E5) |
| V46 | `Install-IXClient` against a local fake of GitHub's release API and iw7-mod's update server (`ClientDownload`, 6 tests) | ✅ The latest release with a matching SHA-256 digest is installed. A wrong digest, or GitHub answering 500, falls back to the update server's SHA-1. When every source fails (bad checksums, an HTML page instead of a program), nothing is left in the game folder. A release without a digest is accepted unverified. An old `iw7-mod.exe` is replaced |
| V47 | The window's background download (`BackgroundDownload`): the exact script text `IXSetup.ps1` builds, run in a second runspace the same way | ✅ Exactly one result object comes back through `EndInvoke`; progress written on the download thread is visible; a failure arrives with its own message |
| V48 | Menu script load order (`tools/tests/test_menu_script.py`, Lua 5.1 with stand-ins for IW7's UI; superseded by V51 when the button moved to the lobby) | ✅ Reproduces the first in-game report: the previous script lost the CHARACTER button when it ran before iw7-mod's own MainMenu script (0 buttons). The fixed script has exactly 1 button in both orders, whether the list is built by name or through `m_types` |
| V49 | Steam name (`SteamName`, `MenuScript`) | ✅ `loginusers.vdf`: the MostRecent account is chosen and VDF escapes are undone. Names keep printable ASCII without `" \ ; % ^`, at most 31 characters; non-ASCII names are not copied. The name file is recorded, and removed when a later install has no name. The menu script replaces only "Unknown Soldier" |
| V45 | Launcher line endings | ✅ `*.cmd text eol=crlf`: `git archive` (GitHub's zip downloads) and checkouts both give CRLF |

### Second in-game report: lobby button, pictures, character applied

| # | Check | Result |
|---|-------|--------|
| V50 | The stock lobby's layout, read from the game's compiled UI scripts (`IW_API_NOTES.md` §16; HavokScript constant tables parsed as data, to the last byte of each file) | ✅ `CPPrivateMatchButtons`: ids, 40-pixel steps, both boss battle layouts; `CPPrivateMatchMenu`: list position, special pictures and sizes, the reset of `characterSelect`; `actions.lua` / `conditions.lua`: what `CharacterSelect`, `SecretCharacterSelection` and `HasBeatenMeph` read and write; the unlock rules of all five specials |
| V51 | Lobby button (`test_menu_script.py`): stock lobby stand-ins built from V50, every load order (types registered before or after the script, or assigned to `m_types`) × built by name or directly × boss battles on or off | ✅ Exactly one CHARACTER button, right after SELECT SHOW in the list order, at 160–190; every element below one step lower, also after the stock list switches layouts again and on a second visit; pressing it opens the CHARACTER menu. The zombies main menu has no button |
| V52 | Lobby field after the stock reset | ✅ A chosen special is written back when it is unlocked (The Hoff 1, Elvira 4, Willard 5 with soul key 5 and the merit), with `ix_character_specials 2` also when locked; not with specials off, a locked special, Willard without the merit, or a regular character. If the game bypassed both registered builders, from the second visit |
| V53 | CHARACTER menu (`test_menu_script.py`) | ✅ Every text element is as tall as its font (name 44, status and description 22). Specials show their own picture (The Hoff 360 × 360, the others 180 × 360); regular characters and Random show colored initials. Locked specials read "(locked)" with the unlock hint and are not saved; unlocked ones save `ix_character` and `characterSelect`; regular characters save `characterSelect 0` |
| V54 | Character data (`test_character_data.py`) | ✅ The GSC and the menu use the same lobby values and unlock stats; Willard needs `soul_key_5` (the key The Beast from Beyond gives) and `mt_dlc4_troll2`; every other special its own map's key |
| V55 | Character applied at the stock pick: `character.gsc` replaces `zombies_loadout::get_player_character_num` with `replacefunc` (iw7-mod v1.1.0 `script_extension.cpp`; the stock callers are `givedefaultloadout`, on every spawn, and `cp_rave`'s intro, both on the player). Superseded the `level.custom_giveloadout` wrapper after the third in-game report | ✅ Compiles with both iw7-mod compilers, `replacefunc` included (`check.py`); the in-game check is R-CH13 |

### Character pictures pack

| # | Check | Result |
|---|-------|--------|
| V56 | x64-zt's behaviour, read from its source (`github.com/Joelrau/x64-zt`, commit `3802db4d`; `IW_API_NOTES.md` §18) | ✅ The console reads standard input and passes commands on only once the game is set up; its ready line; `loadzone` waits for earlier loads; `dumpasset` writes to `dump\assets\`; `-dds` image files; `-buildzone` reads `zone_source\<zone>.csv` and `zonetool\<zone>\` and writes `zone\<zone>.ff`; a `<type>,,<name>` row is a reference (that the game calls the techset type `techset` is not in the source: if not, x64-zt skips the row and the pack carries its own copy); `require,<zone>` loads a zone first; `quit` exits with 0. Not run: x64-zt needs Windows and the game (R-PK1) |
| V57 | Picture plan (`CharacterPictures`) | ✅ 50 cards from each map's `playercash_images` names (main and team card per character, specials on their own map, Willard in `patch_cp_zmb`); one x64-zt run per map, each loading its zones, naming the first zone again to wait for them, dumping its cards and quitting; the language zones found in the game folder (`eng_cp_town`, `fre_cp_town`; not `patch_cp_town`) |
| V58 | Build input from a fake dump (`CharacterPictures`) | ✅ A material per card, patterned on the dumped menu material with the card as its image; `require,ui_boot` and `techset,,2d` before the materials; the pattern's state files copied under each card's name; the largest streamed size taken; missing cards listed. Installing moves the zone into `iw7-mod\zone\` with its list; UNINSTALL removes both; the cleanup removes only what the run added |
| V59 | Download, console and runner with a stand-in for x64-zt (`ZoneToolDownload`, `ZoneToolConsole`, `PicturesScript`, `tools/tests/fake_zonetool.py`) | ✅ The release's "Release zonetool.zip" is found, checked against GitHub's SHA-256 and unpacked to `zonetool.exe` alone; a wrong checksum or a missing asset fails with nothing left behind. Commands go after the ready line, with `\n` line ends, and standard input is still open at `quit`; a run that stops answering ends after the idle time. End to end: five dump runs and a build; a map whose run crashes is named and skipped; the pack and its list are installed; x64-zt's copy and work files are gone. The stand-in only does what V56 describes |
| V60 | CHARACTER menu with a pack (`test_menu_script.py`) | ✅ `loadzone ix_portraits` once per game session, not with `ix_pictures 0` or without the zone file; the main card from the selected map (248 × 360), else a special's own picture, else the team card (256 × 256), else the initials; a 30 × 30 team card left of each row that has one |
| V61 | The setup builds the pictures after installing (`SetupScriptWithoutWindow`, `BackgroundPictures`) | ✅ `-NoWindow`: the first install builds them with the stand-in for x64-zt, a second install does not, UNINSTALL removes them; when every map fails, the mod stays installed and nothing of x64-zt is left (this found empty work folders the clean-up missed; fixed). The window's background script, taken from `IXSetup.ps1` and run in a second runspace the same way: exactly one result, the progress steps, the log; stopped mid-run as when the window closes, x64-zt's process is gone and its files removed. The window itself (WPF) was not opened (E5) |
| V62 | A newer download with the same version number (`NewerFiles`) | ✅ Reproduces the problem: every build so far said 0.1.0, so the setup showed PLAY and kept the old files. Now one changed file (same version) or one missing installed file counts as outdated, and after the update it does not |
| V63 | The first real picture build (2026-10-07): five "ZoneTool ERROR: Fatal error (0xC0000005) at 0x000000016064530D" boxes, one per map | ✅ Explained. The address, symbolized with the release's own `zonetool.pdb`, is in `memmove` at its first read from the source. Image pixels are in the zone's temporary block (`gfx_image::write`), freed once the zone has loaded, and `dumpasset image` after `loadzone` copied them. The stock menu material is in `techsets_ui_boot`, which `loadzone ui_boot` does not load (`[LISTING]`, `skip_extra_zones_stub`), so the build would have failed there too (`IW_API_NOTES.md` §18) |
| V64 | The new dump, against a stand-in that behaves as V63 found (`CharacterPictures`, `PicturesScript`, `SetupScriptWithoutWindow`, `BackgroundPictures`) | ✅ Each map's run sends `dumpzone iw7 <zone> image` for its zones and never `dumpasset image` (the stand-in crashes on it). The pattern material comes after `techsets_ui_boot` is loaded. Each card's `.iw7Image` is renamed into the build input, and a later zone's image replaces an earlier one's (Elvira's patched card). Both pattern zones are `require` rows. Two failed maps in a row stop the rest: the setup started x64-zt twice, not five times. Only the real x64-zt can confirm it (R-PK1) |

### Phase 2 (core systems) and the launcher

| # | Check | Result |
|---|-------|--------|
| V65 | `python3 tools/check.py` with the Phase 2 scripts (`events`, `config`, `persist`, `features`, `chat`) | ✅ PASS, 0 errors, 0 warnings: 34/34 compiled, 17/17 identical between the compilers, 271 built-in calls, 113 far references (10 into stock scripts), 17 scripts load in a zombies match, 13,374 bytes of custom-script memory (1.28% of 1 MiB) |
| V66 | iw7-mod's chat and script functions, read at v1.1.0 and develop (`IW_API_NOTES.md` §19) | ✅ `logprint.cpp` notifies level `"say"` (player, message) and the player `"say"` (message) for every chat line, team chat in zombies included; `executecommand` queues a console command; `tell` sends a quoted chat line to one player. The same in both versions |
| V67 | Single characters of a string in the stock scripts | ✅ Taken with `getsubstr(s, i, i + 1)` (`cp_disco_song_quest.gsc`, `disco_mpq.gsc`, `cp_final_venomx_quest.gsc`); none indexes a string. `util::is_number` and `persist::is_safe` do the same |
| V68 | iw7-mod's `-zombies` / `-cpMode`, read at v1.1.0 and develop | ⚠️ They work on a dedicated server only: the client returns from `dedicated.cpp`'s `post_unpack` before reading them, although iw7-mod's `commandlineargs.md` lists them for the client. The launcher passes no mode flag (§14) |
| V69 | iw7-mod's Steam check (`steam_proxy.cpp`) | ✅ The client loads Steam only when `FindWindowA(0, "Steam")` finds Steam's window, else it shows "Steam must be running to play this game!" and exits. The launcher waits for that window and for `ActiveUser` (§19) |
| V70 | `installer/IXLauncher.cs` compiled by PowerShell 7's C# compiler with `/langversion:5` (`GameLauncher`) | ✅ Compiles; the same flag refuses C# 6 (`?.`), so the source is C# 5 as the compiler of .NET Framework 4 needs. Arguments passed on to iw7-mod split back exactly, by CommandLineToArgvW's rules, for spaces, empty arguments, quotes, backslashes before a quote or at the end, and tabs. The compiled launcher was not run (Windows only: R-L1 to R-L6) |
| V71 | Building, starting and removing the launcher with a stand-in compiler (`GameLauncher`, `SetupScriptWithoutWindow`; `tools/tests/fake_csc.py`) | ✅ `csc.exe` is found under `%WINDIR%\Microsoft.NET\Framework64\v4.0.30319`; it gets `/target:winexe /optimize+ /noconfig /reference:System.dll` and the icon, and the source the package version (0.2.0 → 0.2.0.0). A compiler that refuses the icon: built without it. A failing compiler: its error line, and the launcher already there stays. No compiler (Linux): the install succeeds and says the launcher could not be built. No work folder is left in the temp folder. UNINSTALL deletes it, and a launcher that cannot be deleted (in use) is reported instead of failing the uninstall; PLAY's `Start-IXGame` starts the launcher when it exists, else `iw7-mod.exe`, from the game folder (stand-ins record which ran) |
| V72 | `installer/ix-launcher.ico` (`tools/make_launcher_icon.py`, `SetupFiles`) | ✅ The six sizes of `ix.ico` up to 128 px as 32-bit bitmaps with transparency masks, because the C# 5 compiler may refuse PNG images; Pillow and ImageMagick read it back, pixel for pixel equal to `ix.ico` |
| V73 | `python3 -m unittest discover -s tools/tests` | ✅ 83 tests OK: installer 54 (46 before; the launcher added 8), checker 12, character data 7 (V74 added 1), menu script 10 |
| V74 | The player card's picture: each character's card on each map, as `character::card_material` names it, against aurora's asset listing | ✅ All 50 (25 characters on their maps × main and team card) are materials in the map's `techsets_<map>` zone and images in its zones (Willard's in `patch_cp_zmb`, Elvira's main card in `eng_cp_town`). `test_character_data.py` checks that the names follow the same rule as the setup's picture pack, and catches a changed suffix or a changed Willard name. `check.py` passes (17 scripts, 14,059 bytes) |

### Phase 3 (in-game menu) and the lobby card

| # | Check | Result |
|---|-------|--------|
| V75 | `python3 tools/check.py` with `ix/ui/menu.gsc` and `menu_tree.gsc` | ✅ PASS, 0 errors, 0 warnings: 38/38 compiled, 19/19 identical between the compilers, 398 built-in calls, 156 far references (14 into stock scripts, all loaded on every zombies map, `scripts\engine\utility` included), 21,573 bytes of custom-script memory |
| V76 | The buttons, locks and HUD the menu uses (`IW_API_NOTES.md` §7–8) | ✅ The six polling methods, `disableweapons` / `enableweapons`, the offhand and usability pairs, `allowmelee` and `ishost` are named in both compilers' tables. The stock counters `allow_weapon`, `allow_offhand_weapons`, `allow_melee` and `allow_usability` keep a per-player count; `coop_powers::reset_grenades` polls the frag button with grenades off; `createbar` keeps its own fields on a HUD element. A working IW7 zombies menu polls the same buttons in the same scheme. Not run: the menu needs the game (R-M1–R-M8) |
| V77 | Shaolin Shuffle's card shape and the lobby's special pictures, read from the game's compiled UI scripts as data (`IW_API_NOTES.md` §15–16) | ✅ `mainplayerinfodlc2.lua` puts the main card in a 512 × 256 element; `cpprivatematchmenu.lua` has the five special pictures (The Hoff's 798–1054 × 714–970), shown on `characterSelect == n` with no map check; iw7-mod's `MPMainMenu.lua` refreshes on `gain_focus` / `restore_focus` and adds two `menu_create` handlers to one menu |
| V78 | Lobby card and Pam's card (`test_menu_script.py`, lobby stand-in with the five special pictures) | ✅ A regular character's card of the selected show at 838–1014 × 714–970; after SELECT SHOW and `restore_focus`, the new show's card; choosing a special in the CHARACTER menu shows the stock picture and nothing over it, also when the stock lobby has just reset `characterSelect`; Random shows nothing; initials without the pack; the team card when the pack has no main card. Pam's card 360 × 180 in the CHARACTER menu, the others unchanged |
| V79 | The setup's file list | ✅ Found by the tests: `Sort-Object` sorted `menu_tree.gsc` before `menu.gsc` (language rules); the list is now sorted by character code, the same on every PC |
| V80 | `python3 -m unittest discover -s tools/tests` | ✅ 86 tests OK: installer 54, checker 12, character data 7, menu script 13 |

### 0.3.1 (menu controls, the lobby card in the bottom right, the player card removed)

| # | Check | Result |
|---|-------|--------|
| V81 | `python3 tools/check.py` without `ix/ui/player_card.gsc`, with the new menu input and lobby card | ✅ PASS, 0 errors, 0 warnings: 36/36 compiled, 18/18 identical between the compilers, 392 built-in calls, 145 far references (15 into stock scripts, all loaded on every zombies map, `scripts\engine\utility::is_player_gamepad_enabled` among them), 170 Lua API names, 20,944 bytes of custom-script memory |
| V82 | The calls the movement-key menu uses (`IW_API_NOTES.md` §8) | ✅ `getnormalizedmovement`, `playerlinktodelta`, `islinked`, `getlinkedparent`, `unlink` and `isonground` are named in both compilers' tables. The stock phone booth (`cp_disco/phonebooth.gsc`) links its player to a `tag_origin` model with `playerlinktodelta` and reads `getnormalizedmovement()` while linked, and registers `+goStand` with `notifyonplayercommand`; the stock dodge reads `[0]` as forward / back and `[1]` as right / left. `is_player_gamepad_enabled` reads `usinggamepad()` when `level.console` is false, which `cp_globallogic` sets at init. Not run: the menu needs the game (R-M2, R-M9, R-M10) |
| V83 | The stock lobby's layout and party count, read from `cpprivatematchmenu.lua` and `cplobbymembers.lua` as data, and iw7-mod's own model calls (`IW_API_NOTES.md` §16) | ✅ `CPLobbyMembers` 1405–1841 × 165–991, rows 192 high and 5 apart (at most 4), counted by `alwaysLoaded.activeParty.members.count`; `SocialFeed` at 965–995; `ButtonHelperBar` the bottom 85 pixels. `GetValue`, `GetModel` and `SubscribeToModel` are used the same way in iw7-mod's `MainMenu/CPMainMenuButtons.lua` and `Lobby/GameSetupButtonsBots.lua` (`check.py` `lua`) |
| V84 | Lobby card (`test_menu_script.py`; the stand-in lobby runs the stock display / hide sequences after every step) | ✅ One player: a regular character's card 331 × 480 at 1457–1788 × 475–955, the new show's card after SELECT SHOW; a second player joining: 263 × 381 at 1491–1754 × 574–955; three players: 177 × 256 in the lower middle (837–1014 × 714–970). Pam Grier's card 436 × 218; without the pack The Hoff's square stock picture 256 × 256 and Kevin Smith's 240 × 480; the stock special picture stays hidden (with the hide removed, the test sees it); a special the player has not unlocked and Random: no card. Initials and team cards as before, in the new place |
| V85 | `python3 -m unittest discover -s tools/tests` | ✅ 87 tests OK: installer 54, checker 12, character data 7 (the player card's names test replaced by the picture pack's specials against the cast), menu script 14 |

## 3. Runtime test environment (for testers)

1. Windows PC with a legally owned Steam copy of *Call of Duty: Infinite Warfare*.
2. iw7-mod installed (`auroramod/docs` → *iw7-install*). Record the client version: **v1.1.0** or a develop build.
3. Install the mod with `Infinite Expansion Setup.cmd` (README; §4.8 tests the setup itself), or by hand: copy `mods/infinite_expansion/custom_scripts` and `mods/infinite_expansion/ui_scripts` into `<Infinite Warfare>/iw7-mod/`. Every player in a co-op test installs it the same way. The Mods-menu install (`mods/infinite_expansion` in `<Infinite Warfare>/mods/`) works for solo tests only (L30, R-S10).
4. Launch with `+set developer_script 1`. Without it, script runtime errors are not printed at all (`KNOWN_LIMITATIONS.md` L24).
5. Logs: the iw7-mod console (`~`) and `iw7-mod/logs/console.log`, available since iw7-mod v1.0.3. Report every line starting with `[IX]` and any `script compile error`, `script link error`, or `script runtime error` block.
6. **No `[IX]` lines at all?** Check that `<Infinite Warfare>/iw7-mod/custom_scripts/cp/ix_main.gsc` exists. Then try the Mods-menu install, check that the console's `----- FS_Startup -----` list includes `mods/infinite_expansion`, and report which install worked.
7. Settings for testing (README "Settings and chat commands"): in a match, `!ix list` in chat shows them all; `set ix_<setting> <value>` in the console or `!ix set <setting> <value>` in chat changes one, and it is saved for the next game.
   - `ix_debug_log 1`: extra `[IX] DEBUG:` lines (player connect and spawn). Takes effect immediately.
   - `ix_enabled 0` (a dvar, not a setting): turns the whole mod off from the next map load.
   - `ix_version`: set by the mod, shows the loaded version.

## 4. Runtime checklist

Result values are **not run**, **pass**, **fail**, or **n/a**. Fill in the `vX.Y` columns by client version.

### 4.1 Game startup

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-S1 | Load the mod, start a zombies match (`cp_zmb`) | No `script compile error` / `script link error`. Exactly one `[IX] INFO: init 0.3.1 map=cp_zmb modules=player,weapons,zombies,debug,ui`, then `[IX] INFO: client …`, `[IX] INFO: settings: 8 (0 changed from the default); features: 1; chat: !ix`, then `[IX] INFO: ready` once you are in | not run | not run |
| R-S2 | Zombies co-op: a second player joins the host's match | One `[IX] INFO: init` on the host only; with `ix_debug_log 1`, one `player connected` line per player | not run | not run |
| R-S3 | Menu opens (ADS + Melee) (R-M1) | Menu visible; weapons/offhands disabled while open | not run | not run |
| R-S4 | Menu closes (Melee at root) (R-M1) | Menu hidden; weapons restored | not run | not run |
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

### 4.4 Settings and chat commands (Phase 2)

Chat commands are typed in the match's chat. The replies appear only for the player who typed; everyone sees the command itself, as any chat line.

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-C1 | Type `!ix`, then `!ix list`, `!ix list character`, `!ix get character_specials`, `!ix version` | The command list (with `!ix menu`); all 8 settings with values (a few per line); only the four `character` ones; "Special characters: character_specials = 1 (default 1, a whole number from 0 to 2)" and its help line; "Infinite Expansion 0.3.1". A second player sees none of the replies | not run | not run |
| R-C2 | Console: `set ix_menu_hint 0` | Within about half a second the console shows `[IX] INFO: setting menu_hint = 0 (console)`; `!ix get menu_hint` says 0 | not run | not run |
| R-C3 | Invalid values: console `set ix_character_specials abc`; chat `!ix set character_specials 9999`, `!ix set character_specials maybe`, `!ix on character_specials`, `!ix get nothing` | `abc`: a warning, and `ix_character_specials` is back at its value. 9999 becomes 2. "character_specials: 'maybe' is not a whole number from 0 to 2." "character_specials is not an on/off setting …". "No setting 'nothing' …" | not run | not run |
| R-C4 | Co-op: the guest types `!ix list`, then `!ix set menu_hint 0` | The list works; then "Only the host can change settings." and nothing changes | not run | not run |
| R-C5 | Saving: `!ix set character_announce 1`, quit the game, start it again and a new match | The init line says `1 changed from the default`, and `!ix get character_announce` says 1. Search the files in `iw7-mod\players2` for `ix_character_announce` and report which file holds it | not run | not run |
| R-C6 | `!ix reset character_announce`; then change two settings and `!ix reset all`; restart the game | Each back to its default ("… (default)", "Every setting is back to its default."); after the restart the init line says `0 changed` | not run | not run |
| R-C7 | Open the menu with `!ix menu`, then type `!ix off menu`; ADS + Melee; `!ix on menu`; die or bleed out and respawn, then ADS + Melee | The menu closes at once and does not open while off (`!ix menu` says it cannot open now); after `!ix on menu`, and after the respawn, it opens | not run | not run |
| R-C8 | Odd chat: `!ix set character_specials 1;quit`, `!ix get "x`, `!IX LIST` | The first is refused (not a whole number) and the game keeps running; the second answers "No setting that …"; upper case works like lower case | not run | not run |
| R-C9 | `set ix_debug_log 1`, then a new match; `!ix off debug_log` | `[IX] DEBUG:` lines (player connected / spawned), then none | not run | not run |
| R-C10 | Presets *(Phase 11)* | All values match the preset table | not run | not run |

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
| R-CH9 | *Removed in 0.3.1:* the in-match player card on the right is gone; nothing of it is drawn in a match | — | n/a | n/a |
| R-CH10 | A match with default settings; then `set ix_character_announce 1` and a new match (co-op if possible); then `set ix_character_select 0` and a new match | First no "is playing as" lines. With the setting on, after the intro, everyone sees one line per player, such as "<guest> is playing as The Hoff". With selection off, the game picks characters as usual | not run | not run |
| R-CH11 | Die or bleed out, then respawn | Same character and knife as before | not run | not run |
| R-CH12 | Probe for L29, in the zombies main menu console: `setCoopPlayerData zombiePlayerLoadout characterSelect 14`, then `getCoopPlayerData zombiePlayerLoadout characterSelect` | Report the printed value (14, another number, or an error). Afterwards pick any character in the CHARACTER menu, which writes the field again | not run | not run |
| R-CH13 | The second in-game report: pick Andre, start a Solo Match on any map | Your arms, voice and the stock portrait (bottom left) are Andre's, and nothing extra is drawn on the right. The console and `iw7-mod\logs\console.log` show `[IX] INFO: character: <you> -> Andre (ix_character)` and no "already has a character" warning | not run | not run |

### 4.6 Zombies lobby (Lua UI)

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-UI1 | Open Zombies, then Solo Match; repeat with Custom Game, and on a map with BOSS BATTLE | The main menu has no CHARACTER button. In the lobby, CHARACTER is right under SELECT SHOW, styled like the others; nothing overlaps (TUTORIAL, SURVIVAL DEPOT, CONTRACTS and the description line moved down one step); arrow keys and the mouse reach every button; its description shows when highlighted. A screenshot helps | not run | not run |
| R-UI2 | Press CHARACTER and move through the list | Random, Sally, Poindexter, Andre, A.J., then the five specials. The right side shows a picture: the special characters' own pictures, undistorted (The Hoff square, the others twice as tall as wide), colored initials for the others; then the name in large letters, a status line, and a normal-size description. Back returns to the lobby. A screenshot helps | not run | not run |
| R-UI3 | Pick Andre, then start the match | As R-CH13; after restarting the game the menu still says "Selected: Andre" and opens on Andre | not run | not run |
| R-UI4 | Without the Spaceland soul key, highlight and press The Hoff; then `unlockallEE` and reopen | First "The Hoff (locked)", the status line "Locked: earn the soul key on Zombies in Spaceland.", and pressing it does nothing; afterwards it can be chosen | not run | not run |
| R-UI5 | Pick The Hoff, back out to the main menu, open Solo Match again, run `getCoopPlayerData zombiePlayerLoadout characterSelect`; pick Sally and run it again | `1` (the stock lobby's reset was undone), then `0`; no console error from `setCoopPlayerData` or `uploadstats` | not run | not run |
| R-UI7 | Solo Match: pick Andre in CHARACTER; back in the lobby, change SELECT SHOW; then pick The Hoff (unlocked), then Random. Then Custom Game with one, then two or three friends | Andre's card from the selected show appears big in the bottom right, under your player card (initials without the picture pack), as in the mockup; after SELECT SHOW, the new show's card. The Hoff: his card there (without the pack, the game's own picture of him) and nothing in the lower middle. Random: nothing. With a second player the card is smaller, under both player cards; with three or four it moves to the lower middle. Nothing overlaps the buttons, the player list or the line along the bottom. A screenshot helps | not run | not run |
| R-UI8 | With the picture pack, highlight Pam Grier in CHARACTER | Her Shaolin Shuffle ID card, twice as wide as high, not squeezed | not run | not run |
| R-UI6 | Co-op: the guest opens CHARACTER in the host's lobby | The button is there for the guest too; an unlocked special picked there reaches the match (R-CH3) | not run | not run |

### 4.8 One-click Windows setup

Start from a fresh **Code → Download ZIP** of the repository, extracted, as a player would.

| ID | Test | Expected | Result |
|----|------|----------|--------|
| R-I1 | Double-click `Infinite Expansion Setup.cmd` | The window opens within a few seconds: grid scrolling, hands rising, wheel turning. No error box. If Windows warns, note the exact wording | not run |
| R-I2 | Game detection | The game folder is filled in (also from a Steam library on another drive); IW7-MOD CLIENT is green when `iw7-mod.exe` is there, yellow with GET IT when not | not run |
| R-I3 | INSTALL, then start a zombies match | Status INSTALLED; `<game>\iw7-mod\custom_scripts\cp\ix_main.gsc` and `iw7-mod\infinite-expansion.json` exist; *Settings → Apps* lists Infinite Expansion; the console shows `[IX] INFO: init` | not run |
| R-I4 | With the old `mods\infinite_expansion` copy present | The yellow note shows; INSTALL removes that copy's files and says so | not run |
| R-I5 | UNINSTALL | Status UNINSTALLED; the mod's files and the record are gone; other files in `iw7-mod` stay; the Settings entry is gone | not run |
| R-I15 | With an earlier build installed, run the setup from this download | The button reads UPDATE and the mod row says "newer files are ready" (or the new version); after UPDATE, a match's console shows `[IX] INFO: init 0.3.1` | not run |
| R-I6 | Install, delete the download, then uninstall from *Settings → Apps* | The setup window opens and uninstalls by itself; after closing it, `%LOCALAPPDATA%\InfiniteExpansion` is gone | not run |
| R-I7 | BROWSE: pick another `.exe`, then `iw7_ship.exe` | First "NOT THE GAME FOLDER", then the rows update | not run |
| R-I8 | Window details | Drag by the top bar; minimize and close work; buttons glow on hover; no text cut off, also with the yellow note showing; looks right at 125–150 % display scaling | not run |
| R-I9 | Game in a folder Windows protects (if available) | INSTALL offers to retry as administrator, and that works | not run |
| R-I10 | Move `iw7-mod.exe` out of the game folder, then INSTALL | The status line shows "Downloading iw7-mod.exe from GitHub: x of y MB"; `iw7-mod.exe` is back; then ALL SET and the button reads PLAY. Report the version and whether it says "checksum verified" | not run |
| R-I11 | PLAY, with Steam closed and then open | The setup closes and the launcher starts the game: with Steam closed, after Steam has started and signed in (R-L3). Without the launcher (R-L1 failed): Steam opens and the window says to click PLAY again | not run |
| R-I12 | No game installed (another PC, or a Steam account without the game) | GAME NOT FOUND; STEAM opens Steam's install dialog or the store page; after Steam installs the game, the window finds it within a few seconds | not run |
| R-I13 | DOWNLOAD in the iw7-mod row | Only iw7-mod is downloaded; the status says to click INSTALL next | not run |
| R-I14 | After INSTALL (status names your Steam name), start the game | The Zombies menu shows CHARACTER; your name is your Steam name instead of "Unknown Soldier". After `name Test` in the console and a restart, it stays "Test" | not run |

### 4.11 In-game menu (Phase 3)

| ID | Test | Expected | v1.1.0 | develop |
|----|------|----------|--------|---------|
| R-M1 | After spawning, hold ADS and press Melee; press Melee again; then type `!ix menu` | About 6 s after the first spawn a hint names the controls (W / S, A / D, Use or Jump, Melee). The menu opens on the right of the screen (title "Infinite Expansion", rows Characters, Menu, Settings, Debug, Close; two lines at the bottom: "W / S: move     A / D: change" and "Use or Jump: select     Melee: back"), without the cursor jumping; Melee closes it; the chat command opens it too. A screenshot helps | not run | not run |
| R-M2 | With the menu open: W and S (also held), A and D, Use, Jump, Melee; then ADS, Fire, Tactical, Frag | W/S move the cursor (holding keeps moving) and you stay where you are; A/D change the highlighted value, which has `<` `>` around it; Use and Jump open a page; Melee goes back. ADS/Fire and Tactical/Frag do what W/S and A/D do. You can look around; no walking, shot, aiming, knife, grenade or jump, and Use near a wall buy or door buys nothing. After closing, all of those work again | not run | not run |
| R-M3 | Characters page: change *Special characters* with A and D; switch *Announce characters* with Use, then with A and D | The value steps through 0, 1, 2 and stops at the ends; the help lines show the range; Use and A / D both switch ON / OFF | not run | not run |
| R-M4 | Change a setting in the menu, then `!ix get` it in chat; change it in the console with the menu open | Chat shows the menu's value; the open menu shows the console's value within a moment. After a restart the value is still there (saved) | not run | not run |
| R-M5 | Co-op: the guest opens the menu and tries to change a setting; the host sets *Menu: who changes settings* to everyone, and the guest tries again | First the values are grey, nothing changes, and the help says only the host can change it; then the guest's change works | not run | not run |
| R-M6 | Settings page: *Reset every setting* with Use once, then move away; Use twice | The first Use asks to press Use again; moving away cancels; Use twice resets every setting (*Changed from the default* goes to 0) | not run | not run |
| R-M7 | Open the menu, then get downed by zombies; open it during last stand | It closes when you go down, and your weapon works in last stand as usual; it does not open while down. After being revived, ADS + Melee opens it again | not run | not run |
| R-M8 | Switch *In-game menu* off in the Menu page | The menu closes; ADS + Melee does nothing; `!ix on menu` brings it back | not run | not run |
| R-M9 | With a controller: open the menu, then the left stick up / down / left / right, Jump, Use, Melee | As W/S/A/D, Jump, Use and Melee on the keyboard. The bottom lines read "Stick up / down: move   left / right: change" (the hint after the first spawn names the left stick) | not run | not run |
| R-M10 | Open the menu with zombies nearby and let one reach you; close it. Try ADS + Melee in mid-jump. Open it, then let a zombie down you | While open you stay in place and zombies can still hurt you; Melee closes it and you can walk at once. In the air it does not open (`!ix menu`: "The menu cannot open now."). Going down closes it and frees you. No console error | not run | not run |

### 4.10 The launcher

| ID | Test | Expected | Result |
|----|------|----------|--------|
| R-L1 | INSTALL (or UPDATE / REINSTALL) | The status line says "Added Infinite Expansion.exe to the game folder, and its shortcut to the desktop." `<game>\Infinite Expansion.exe` and the desktop shortcut **Infinite Expansion** have the mod's icon; *Properties → Details* shows Infinite Expansion, version 0.3.1.0. If it says "could not be built", report that line and the `launcher failed:` line of `%TEMP%\InfiniteExpansionSetup.log` | not run |
| R-L2 | Steam open and signed in: double-click the shortcut | The game starts within a few seconds, on its main menu; no other window appears. Report any Windows or antivirus warning about the launcher | not run |
| R-L3 | Steam closed: double-click the shortcut; also once while Steam asks for your password | Steam starts; the game starts by itself a few seconds after Steam has signed in (with the password: after you sign in, within five minutes). No "Steam must be running" box | not run |
| R-L4 | Double-click twice quickly; then once more while the game runs | One game; then "Infinite Warfare is already running." | not run |
| R-L5 | Rename `<game>\iw7-mod\custom_scripts\cp\ix_main.gsc` to `.bak`, double-click; rename it back; then UNINSTALL | It asks whether to start iw7-mod without the mod (No: nothing starts). UNINSTALL deletes the launcher and its shortcut and says "Removed Infinite Expansion.exe." | not run |
| R-L6 | Add ` +set ix_debug_log 1` at the end of the shortcut's *Target*, start a match | `[IX] DEBUG:` lines in the console: the launcher passed the argument on | not run |
| R-L7 | Optional experiment: add ` +cpMode` at the end of the shortcut's *Target* | Report whether the game opens straight into Zombies, opens normally, or misbehaves (`-zombies` does nothing in the client, V68) | not run |

### 4.9 Character pictures (optional)

| ID | Test | Expected | Result |
|----|------|----------|--------|
| R-PK1 | With the game closed, run the setup and click INSTALL (or UPDATE) | After the mod's files, the status says BUILDING CHARACTER PICTURES, "First time only, a few minutes", then downloading x64-zt and "Copying the character cards of …" for each of the five maps; the buttons stay disabled; then ALL SET with "Built N character pictures". No "ZoneTool ERROR" box should appear; if one does, click OK, and send the log below plus the newest `minidumps\zonetool-crash-*.zip` from the game folder. `<game>\iw7-mod\zone\ix_portraits.ff` and `ix_portraits.txt` exist; no `ix-zonetool.exe`, and no `dump`, `zonetool` or `zone_source` folder that was not there before. Send `%TEMP%\InfiniteExpansionPictures.log` either way | not run |
| R-PK2 | Start the game; Solo Match → CHARACTER with SELECT SHOW on Spaceland, then on another map | Each regular character shows their card from that map, not stretched; a small team card beside each row; the specials show their cards. The console has no error about `ix_portraits` or a missing material. A screenshot helps | not run |
| R-PK3 | Play a match, return to the menu, open CHARACTER again; click UPDATE or REINSTALL in the setup | The pictures are still there, with no error from loading the pack a second time. The setup does not build them again | not run |
| R-PK4 | `ix_pictures 0` and restart the game; then UNINSTALL in the setup | Initials and the game's own special pictures again; UNINSTALL removes `ix_portraits.ff` and `ix_portraits.txt` | not run |
| R-PK5 | INSTALL with the game running; then close the setup while it builds the pictures; then run `Build Character Pictures.cmd` | Running game: ALL SET says to close the game and click REINSTALL. Closing mid-build asks first, then leaves no `ix-zonetool.exe` running (Task Manager) and no work folders. The `.cmd` window shows the same steps and ends with "Done." | not run |

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
