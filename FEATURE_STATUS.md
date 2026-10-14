# FEATURE_STATUS.md

**Statuses:** PLANNED · INVESTIGATING · IN PROGRESS · TESTING · COMPLETE · PARTIAL · BLOCKED (· DEFERRED, N/A, NOT PLANNED, REMOVED)

- A feature becomes **COMPLETE** only after it compiles with both iw7-mod compilers **and** is confirmed in-game (`TESTING.md`).
- **TESTING** means the code is written and passes static checks (`tools/check.py`), but no in-game run has been reported yet.
- Tooling runs offline, so a tooling row is **COMPLETE** once it works and is tested here.
- Evidence for every API named here is in `IW_API_NOTES.md`. The BO3 origin of each AAE feature is in `PROJECT_ANALYSIS.md` §1 and §3.

## Project / analysis / tooling

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| IW7 modding research | Analysis | 0 | COMPLETE | `PROJECT_ANALYSIS.md` §2, `IW_API_NOTES.md` |
| BO3 AAE file analysis | Analysis | 0 | COMPLETE | AAE v3.9.5 decompressed; 211/216 scripts decompiled; `PROJECT_ANALYSIS.md` §1 |
| BO3 reference pipeline | Tooling | 0 | COMPLETE | `tools/bo3_reference/extract_aae.sh` (reproduces §1.3 in ~30 s) |
| Offline compiler toolchain (both iw7-mod pins) | Tooling | 0 | COMPLETE | `tools/setup_compilers.sh` |
| Extension-aware compiler (`tools/ixcc`) | Tooling | 1 | COMPLETE | Compiles iw7-mod extension calls; byte-identical to gsc-tool otherwise |
| Dual-compile parity check | Tooling | 1 | COMPLETE | `tools/check.py` `parity`; catches C1/C2 (fixture-tested) |
| Stub-native / unknown raw-id check | Tooling | 1 | COMPLETE | `natives`, `raw ids` (fixture-tested) |
| Far-call / layout lint, bytecode budget | Tooling | 1 | COMPLETE | `calls`, `layout`, `source`, `budget` (fixture-tested) |
| Stock scripts loaded on every zombies map (link-error guard) | Tooling | 1 | COMPLETE | `calls`: per-map link closure from the dump; 126 scripts common to all five maps |
| Checker test suite | Tooling | 1 | COMPLETE | `tools/tests/test_check.py` (12 tests; `bad_mod` / `good_mod` fixtures) |
| Cast data test (character table vs. stock scripts, the menu, and the picture pack's card names) | Tooling | 1.5 | COMPLETE | `tools/tests/test_character_data.py` (7 tests; mutation-checked) |
| Lua UI check (syntax + API names vs. iw7-mod's ui_scripts) | Tooling | 1.5 | COMPLETE | `check.py` `lua`; fixture-tested |
| Settings test (every setting in the menu and README, valid defaults, help that fits the menu, the init line's count) | Tooling | 4 | COMPLETE | `tools/tests/test_settings.py` (9 tests, 36 settings; checked to fail on a missing row, a wrong count, help that does not fit, a footer line that is too long and a menu over its HUD element budget) |
| Polish review of every script (Phase 12) | Code quality | 12 | TESTING | Idle option loops sleep in `config::wait_for_change()`; the info HUD moves its elements instead of making them anew; `chat::tell_lines`, `util::is_playing`; `agents::stock_max_zombies()`. Findings and what was left as is: `TESTING.md` V146; in game: `PLAYTEST_CHECKLIST.md` PL1–PL3 |

## Installer (Windows)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| One-click setup window (install / update / uninstall) | Installer | 1.5 | TESTING | `Infinite Expansion Setup.cmd` → `installer/IXSetup.ps1` (WPF, Windows PowerShell 5.1); 80s neon art; R-I1, R-I3, R-I5, R-I8 |
| Finds the game through Steam (registry, every library, app manifest) | Installer | 1.5 | TESTING | BROWSE as fallback; R-I2, R-I7 |
| Installs the iw7-mod client when it is missing | Installer | 1.5 | TESTING | Latest GitHub release (SHA-256 digest when listed), iw7-mod's update server as fallback (SHA-1); progress in the window; R-I10, R-I13 |
| PLAY: starts the game through the launcher (without it: iw7-mod, opening Steam first if needed) | Installer | 1.5 | TESTING | R-I11 |
| Launcher `Infinite Expansion.exe` in the game folder, with a desktop shortcut: waits for Steam, starts iw7-mod from the game folder, passes arguments on | Installer | 2 | TESTING | Compiled on the player's PC from `installer/IXLauncher.cs` by the C# compiler of .NET Framework 4, so the download has no program file; built again by every install, removed by UNINSTALL; a failed build leaves the install working. Opens on the main menu: `-zombies` works on dedicated servers only (V68); R-L1–R-L7 |
| Automatic updates from GitHub releases: the launcher asks on each start, the setup window when it opens; download checked (project's own release, size, SHA-256, safe unzip), then the new version's setup installs it; AUTO-UPDATE switch | Installer | 0.3.2 | TESTING | `IXSetup.Core.ps1` (`Get-IXLatestRelease`, `Save-IXUpdate`), `IXSetup.ps1 -Update`, `IXLauncher.cs`; releases by `.github/workflows/release.yml` on each version change; the first update to 0.3.2 is by hand (L44); 0.4.0 is the first release a 0.3.2 install fetches by itself (its download checked here against the real GitHub, V99); R-U1–R-U7 |
| Release workflow: a GitHub release with `Infinite-Expansion-<version>.zip` and the CHANGELOG section for each new version | Tooling | 0.3.2 | COMPLETE | Its script runs in the tests against a stand-in for `gh` (`ReleaseWorkflow`); real runs published v0.3.2 (V91) and v0.4.0 (V99), each zip identical to a local `git archive` of its commit |
| Game not installed: Steam's install dialog, then automatic re-detection | Installer | 1.5 | TESTING | `steam://install/292730`; checks again every 4 s; R-I12 |
| Uninstall from Windows Settings → Apps | Installer | 1.5 | TESTING | Per-user entry; a setup copy in `%LOCALAPPDATA%`; R-I6 |
| Removes exactly what it installed; removes the old Mods-menu copy | Installer | 1.5 | TESTING | Record `iw7-mod/infinite-expansion.json`; R-I4, R-I5 |
| Offers UPDATE when the download's files differ from the installed ones, even with the same version number | Installer | 1.5 | TESTING | Compares each file's SHA-256; every build up to 0.1.0 kept that number; R-I15 |
| Builds the character pictures pack once, by itself, after installing (downloads x64-zt, one run per map, cleans up after itself) | Installer | 1.5 | TESTING (experimental) | In the background with progress in the window; skipped while the game runs (REINSTALL then builds it); closing the window stops it cleanly; `-NoPictures` skips it. `installer/IXPictures.Core.ps1`; `Build Character Pictures.cmd` rebuilds by hand; UNINSTALL removes the pack; R-PK1, R-PK3–R-PK5 |
| Installer tests (logic under PowerShell 7, 5.1 lint, XAML checks, downloads against a local fake server, the picture pack against a stand-in for x64-zt, the launcher against a stand-in C# compiler) | Tooling | 1.5 | COMPLETE | `tools/tests/test_installer.py` (66 tests; updates against a local stand-in for GitHub), `tools/tests/ps51_lint.ps1`, `tools/tests/fake_zonetool.py`, `tools/tests/fake_csc.py` |
| Launcher source compiled with C# 5 rules; its icon as classic bitmaps | Tooling | 2 | COMPLETE | `GameLauncher`, `SetupFiles`; `tools/make_launcher_icon.py` makes `installer/ix-launcher.ico` from `ix.ico` |
| Signed installer (no Windows warning) | Installer | – | NOT PLANNED | Needs a paid certificate (L31) |

## Core (Phases 1–2)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Entry script (zombies) | Core | 1 | TESTING | `custom_scripts/cp/ix_main.gsc`; R-S1, R-S2, R-S6 |
| Install that friends can join (`<game>/iw7-mod/`) | Core | 1.5 | TESTING | The Mods-menu install cannot be joined without a `mod.ff` (L30); R-S10 |
| Multiplayer support | Core | – | NOT PLANNED | Dropped 2026-10-06 by the project owner; the mod loads in zombies only |
| Bootstrap + duplicate-init guard + module order | Core | 1 | TESTING | Replaces BO3's `system::register` ordering (AAE §1.5); R-S1, R-S5 |
| Master switch (`ix_enabled 0`) | Core | 1 | TESTING | Whole mod off at the next map load; R-S7 |
| Lifecycle notifies (`ix_ready`, `ix_player_connected`, `ix_player_spawned`, `ix_shutdown`) | Core | 1 | TESTING | One connect/spawn watcher per player; R-S9 |
| Compatibility module (raw ids, feature detection) | Core | 1 | TESTING | Fixes the v1.1.0 mislabels (C1, C2); wrappers are exercised by Phases 4 and 6; R-S8 |
| Logging (`[IX]` console lines, `ix_debug_log`, ring buffer) | Core | 1 | TESTING | R-S1, R-S9 |
| Feature manager (on/off features, requirements, global and per-player hooks) | Core | 2 | TESTING | `ix/core/features.gsc`; in use: `menu` (the player card was the first, removed in 0.3.1); R-C7 |
| Configuration manager (bool/int/float/enum settings with defaults and ranges, like AAE's `tfoption_*`) | Core | 2 | TESTING | `ix/core/config.gsc`; 8 settings so far; invalid values refused, numbers clamped; R-C1, R-C3, R-C6 |
| Saved settings + layout version (AAE: save data + `tfoption_master_ver`) | Core | 2 | TESTING | `ix/core/persist.gsc`: archived dvars (`seta ix_<id>`) in the host's config, so it works in the install friends can join; `ix_settings_version` with a migration hook (L38); R-C5 |
| Live console overrides (`set ix_x v`) | Core | 2 | TESTING | Watcher every 0.5 s; replaces AAE `modvar` / `/d` (L3); R-C2 |
| Event bus | Core | 2 | TESTING | `ix/core/events.gsc`: 12 events from real IW7 notifies, one listener per source; R-C9, R-Z1 |
| Utility library | Core | 2 | TESTING | `util.gsc`: player checks, `join`, `parse_bool`, `is_number`, `array_contains`, `starts_with` |
| Chat commands (`!ix …` on iw7-mod's `say` notify) | Core | 2 | TESTING | `ix/core/chat.gsc`: list, get, set, on/off, reset, version; changes host-only; replies with `tell()`; R-C1, R-C4, R-C8 |

## Characters (Phase 1.5)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| CHARACTER button in the zombies lobby, under SELECT SHOW (base-game style) | UI | 1.5 | TESTING | `ui_scripts/InfiniteExpansion`; in the lobby of Solo Match and Custom Game (moved there from the main menu after the second in-game report); saves `ix_character`, and for specials the stock lobby field `characterSelect`. Layout from the stock lobby (L35); R-UI1–R-UI6 |
| Picture of the highlighted character in the CHARACTER menu (Pam Grier's card drawn 2:1, as the game's HUD draws it) | UI | 1.5 | TESTING | The game's own pictures of the five specials; colored initials for the regular characters, or their HUD cards with the picture pack (L28); R-UI2 |
| Character pictures pack: the HUD's cards in the CHARACTER menu, a team card beside each row | UI | 1.5 | TESTING (experimental) | Built by the setup after the first INSTALL (or by hand with `Build Character Pictures.cmd`): x64-zt copies the cards from the player's own game files into `iw7-mod/zone/ix_portraits.ff`; the menu loads it with `loadzone` and picks the selected map's cards. `ix_pictures 0` turns it off (L28, L37); R-PK1–R-PK5 |
| Locked special characters shown and refused in the menu | UI | 1.5 | TESTING | Reads the same zombies stats as the stock lobby (L27); setting `character_specials`; R-UI4 |
| A chosen special survives the stock lobby's reset | UI | 1.5 | TESTING | The stock lobby clears `characterSelect` when it opens; the menu script writes the choice back; R-UI5 |
| Steam name instead of "Unknown Soldier" | Player | 1.5 | TESTING | The setup copies the Steam name; the menu script sets iw7-mod's `name` while it is the default (L34); R-I14 |
| Choose your character before the match (no switching mid-match) | Player | 1.5 | TESTING | `ix/player/character.gsc`; applied when the stock code asks for the player's character, by replacing `zombies_loadout::get_player_character_num` (iw7-mod `replacefunc`). Second and third in-game reports: the pick did not apply (connect notify too late, then the loadout wrapper), now replaced at the source (L36). Host: `ix_character`. Every player: specials through `characterSelect`. Setting `character_select` (from the next map); every outcome logged; R-CH1–R-CH3, R-CH13 |
| A guest's special-character pick in someone else's match | Player | 1.5 | TESTING | Travels in the guest's stats (`characterSelect`); works on the special's own map even without the mod on the host; R-CH3, R-CH8 |
| A guest's regular-character pick in someone else's match | Player | 1.5 | BLOCKED | No verified channel (L29); the guest gets a random character; R-CH4, probe R-CH12 |
| "<player> is playing as <character>" line after the intro | HUD | 1.5 | TESTING | Off by default; the setting `character_announce` shows it to everyone, once per player; R-CH10 |
| Per-map cast names | Player | 1.5 | TESTING | Actor names verified from stock VO code; outfit labels made from each map's model names |
| One character per player (no duplicates) | Player | 1.5 | TESTING | Keeps the stock random pool consistent; also stops two players getting the same special, which the stock game allows; R-CH5 |
| Special characters gated by unlocks | Player | 1.5 | TESTING | The stock lobby's stats: soul keys, and for Willard also the merit (L27); checked in the menu and for every pick in the match; setting `character_specials` 0/1/2; R-CH6 |
| Special characters on any map | Player | 1.5 | TESTING (experimental) | Opt-in setting `character_crossmap`; their models may not exist on other maps (L26); R-CH7 |
| Stock HUD portrait follows the chosen character | HUD | 1.5 | TESTING | Stock `setmodelfromcustomization` → `zm_player_character` |
| Player card, bottom right (in a match) | HUD | 1.5 | REMOVED | Removed in 0.3.1 at the project owner's request, with the settings `player_card`, `player_card_picture`, `player_card_x` and `player_card_y` and the menu's HUD page; the lobby card replaces it (R-CH9) |

## UI (Phase 3) / HUD (Phase 8)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| GSC menu engine (pages, on/off settings, numbers, words, actions, read-outs) | UI | 3 | TESTING | `ix/ui/menu.gsc`: create-once HUD elements, numbers with `setvalue`, help and range under the list (four lines, enough for every row: `test_settings.py`), 28 HUD elements, the most a player sees (L49; the text did not appear with 33 in 0.4.0), 8 rows with scrolling, live refresh when a setting changes anywhere; the feature `menu`; R-M1–R-M8 |
| Menu controls (open: crouch, then Melee, or `!ix menu`; W / S / A / D or the left stick, Use or Jump, Melee; ADS / Fire and Tactical / Frag too) | UI | 3 | TESTING | The movement keys are read with `getnormalizedmovement` while the player is held in place, as the stock phone booth holds its player; the buttons are polled like a working IW7 zombies menu; Jump is a `+goStand` notify. Weapon, grenades, melee and Use are off while open, through the stock counters. The footer names the keys or the stick, and `<` `>` mark a value A / D change (L41); R-M1, R-M2, R-M9, R-M10 |
| How the menu opens (`menu_open`: ads_melee, crouch_melee, chat) | UI | 0.4.1 | TESTING | ADS + Melee by default again (0.4.2, as the player asked), on every Melee press (`+melee_zoom` notify; polling alone missed quick taps) while ADS is held or the player aims (`playerads`, so toggle ADS works); in the air on landing; a line says why when it cannot open. *crouch_melee*: after 0.3 s crouched without sliding. R-M11, R-M12 |
| How to open it, at the start of each round | UI | 0.4.1 | TESTING | `iprintlnbold` 3 s after `round_start`, until the player has opened the menu; late joiners 6 s after spawning; `menu_hint`. R-M13 |
| The menu's keys in small text at its bottom | UI | 0.4.1 | TESTING | Two lines at fontscale 0.7, keyboard or controller words, with the keys that open it; their width is tested. Not visible in 0.4.0 (too many HUD elements, L49); fixed in 0.4.2. R-M1, R-M14 |
| Menu pages (data) | UI | 3 | TESTING | `ix/ui/menu_tree.gsc`: Characters, Player (with Position), Movement, Weapons, Zombies, HUD, Game, Menu, Settings, Debug (with Information and Drop a power-up); the first page scrolls |
| Reset / defaults from menu | UI | 3/9 | TESTING | *Reset every setting* (confirm with a second Use, host only); *Reset this page* at the end of every page of options (Phase 9); presets: the Presets page (Phase 11); R-M6, R-Q1, R-C10 |
| Host-only changes | UI | 3 | TESTING | Everyone can look; only the host changes, unless `menu_access` is `everyone`; R-M5 |
| Per-player access list | UI | – | NOT PLANNED | `menu_access` covers host-only versus everyone |
| Lobby card of the chosen character | UI | 3 | TESTING | The CHARACTER pick's card, big, in the stock lobby's bottom right under the player list (the lower middle with three or four players): the pack's card (Pam Grier's 2:1), else a special's stock picture, else the team card or initials; the stock special pictures stay hidden; follows a new pick, SELECT SHOW and players joining or leaving (L42, L43); R-UI7 |
| LUI front-end (lobby-style options) | UI | – | DEFERRED | Client Lua; optional later |
| HUD: zombie counter (remaining + active) | HUD | 8 | TESTING | `ix/ui/hud.gsc`, *HUD: zombies*: left this round (`desired_enemy_deaths_this_wave − current_enemy_deaths`) and alive now (live `axis` agents; the stock counter leaves brutes out and drifts on Spaceland). R-H1, R-H4 |
| HUD: round, speed, health | HUD | 8 | TESTING | *HUD: round*, *HUD: health*, *HUD: speed*; *HUD: side* (left / right) and *HUD: height*; archived elements only, two a row, `setvalue` numbers; hidden while the menu is open, while not playing and over the game's menus (L49). R-H1–R-H3 |
| HUD: timer, coordinates, weapon/ammo | HUD | 8/10 | PARTIAL | Coordinates on the Debug page's *Information*; the game shows ammo itself. A match timer: `settimerup` is named in both tables but no zombies script uses it: INVESTIGATING |
| HUD: active modifiers list | HUD | 8 | PLANNED | Also lists changed global dvars (L20) |
| HUD: low-ammo hint | HUD | 8 | PLANNED | |
| HUD: player health bar (self) | HUD | 8 | PLANNED | hudelem bar |
| HUD: ally overhead bars / zombie health bars | HUD | 8 | INVESTIGATING | `setwaypoint` + `settargetent`, NEEDS TESTING |
| HUD: damage numbers / score-event popups | HUD | 8 | INVESTIGATING | hudelem budget (L12) |
| HUD: FPS | HUD | – | BLOCKED | L5 |
| Restyle stock IW7 HUD (colour/format/scale) | HUD | – | DEFERRED | Client Lua |
| HUD string-overflow behaviour | HUD | 3/8 | INVESTIGATING | L12, NEEDS TESTING |

## Player (Phase 4) / Movement (Phase 5)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| God mode (off / host / everyone) | Player | 4 | TESTING | `ix/player/damage.gsc`: the mod's damage callback, put in front of the map's own on `ix_ready`, drops the damage (`IW_API_NOTES.md` §5.3; no stock zombies script uses `enableinvulnerability`, so the mod does not either). L47; R-P2 |
| Damage taken (AAE's player health: 1–5 hits) | Player | 4 | TESTING | `damage_taken` 10–500 percent of every hit, in the same callback; `.maxhealth` stays the game's (the tough perk and health regen set it). R-P3 |
| Starting points | Player | 4 | TESTING | `ix/player/options.gsc`: `level.starting_currency`, which the stock `cp_persistence::get_starting_currency()` reads at each player's first spawn; Director's Cut, the boss-fight-only mode and a player back from spectating keep the game's amounts (L48). R-P9 |
| Friendly fire (off / on / reflect) | Player | 4 | TESTING | Same callback: *on* applies a teammate's hit with the stock `finishplayerdamagewrapper` (last stand included); *reflect* gives it to the shooter with `dodamage`. R-P4 |
| One-team grief (shots slow teammates) | Player | – | DEFERRED | Needs a slow-down effect that zombies maps load; not looked into yet |
| Rocket jump (and its power) | Player | 4 | TESTING | Same callback: your own splash damage throws you with `setvelocity`, as the stock `fling_zombie` throws zombies, instead of hurting you. R-P5 |
| Third person (off / host / everyone) | Player | 4 | TESTING | `compat::third_person` (`_meth_845E`, `setcamerathirdperson`), applied on every spawn. R-P6 |
| Gun (arm) position | Player | – | DEFERRED | iw7-mod's `cg_gun_x/y/z` are dvars of each player's own game; whether `setclientdvar` from the host's scripts reaches them is unknown, and the offset is each player's own choice, which the match-wide settings cannot hold yet (L46). README names the console commands |
| Teleport / position utilities | Player | 4 | TESTING | `ix/player/position.gsc`: save / go to a position, teleport to the crosshair (`bullettrace`, `playerphysicstrace`, `setorigin`); menu actions, host only; refused while down, dead or moved by the game (L45). R-P10 |
| Zombies ignore players (off / host / everyone) | Player | 4 | TESTING | `.ignoreme` kept set, the game's own count (`allow_player_ignore_me`) left alone and restored when off. R-P7 |
| Player collision (ejection) | Player | 4 | TESTING | `player_ejection` sets iw7-mod's `bg_playerEjection` (global, L20; the game's 1 back at the match's end). R-P8 |
| Player page in the menu | UI | 4 | TESTING | *Player* with the nine options and a *Position* page. R-P1 |
| Move speed (AAE: the same `g_speed`) | Movement | 5 | TESTING | `ix/player/movement.gsc`: `move_speed` 50–300 percent of iw7-mod's `g_speed` (190, global, replicated); the stock per-player `setmovespeedscale` multiplies with it. The game's 190 comes back at the match's end (L20). R-MV1 |
| Gravity | Movement | 5 | TESTING | `gravity` 10–125 percent of `bg_gravity` (800; iw7-mod allows 1–1000). R-MV2 |
| Jump height | Movement | 5 | PARTIAL | No jump-height dvar exists (L16); lower *Gravity* jumps higher, and *Double jump* adds a boosted second jump |
| Wall run / double jump / mantle (AAE: "EXO movement") | Movement | 5 | TESTING | The game's own multiplayer movement, which zombies switches off at every spawn (`zombies_loadout.gsc`); re-applied four times a second while the player plays freely (not down, not in the afterlife arcade, not on a ride). L50; R-MV3–R-MV5 |
| Slide off (AAE: "No slide") | Movement | 5 | TESTING | Raw `allowslide(0)` re-applied; ON never undoes a map's own counted lock (`allow_slide`). R-MV6 |
| Unlimited boost (boost energy) | Movement | 5 | TESTING | Energy slot 0 (the double jump's; the game gives 400, refilling at 1000 a second) refilled to its maximum four times a second. R-MV4 |
| Unlimited sprint / omni-movement / air control | Movement | 5 | TESTING | iw7-mod develop builds only (C4): features needing `bg_sprintUnlimited` / `bg_omnimovement` / `bg_airControl` (set to 10, the game's 1); N/A on v1.1.0. R-MV9 |
| Fall damage toggle | Movement | 5 | TESTING | Falls arrive as `MOD_FALLING` in the mod's damage callback (`damage.gsc`), dropped while `fall_damage` is OFF; no global dvar needed. R-MV8 |
| Legacy mantle | Movement | 5 | TESTING | iw7-mod's `mantle_legacy` (older games' reach and angle); matters with *Mantle* ON. R-MV5 |
| Bunny hop | Movement | 5 | TESTING | iw7-mod's `bg_bounces`: landing at speed keeps the speed. R-MV7 |
| Movement page in the menu | UI | 5 | TESTING | *Movement* with 13 rows (scrolls past eight). R-M14 |

## Weapons (Phase 6)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Unlimited ammo (off / reserve / clip) | Weapons | 6 | TESTING | `ix/weapons/ammo.gsc`: *reserve* does what the Max Ammo power-up does (`givemaxammo` on each primary) every half second; *clip* what the Infinite Ammo power-up does (the current primary's clip, both hands, every 0.05 s; Venom-X left alone, as by the power-up). No global `player_sustainAmmo`. L51; R-W1, R-W7 |
| Unlimited grenades | Weapons | 6 | TESTING | Grenades are powers with charges; one used is topped up with the stock `recharge_power`, as Max Ammo does. The game's own Infinite Grenades flag is left alone. R-W2 |
| Fire-rate modifier | Weapons | 6 | TESTING | `ix/weapons/handling.gsc`: `fire_rate` 50–300 percent, the time between shots set with `setfiretimescaleon` (`compat::fire_rate_on`) four times a second; the Berserk passive's 65 is kept when it is faster. R-W3 |
| Recoil / spread modifiers | Weapons | 6 | PARTIAL | *No recoil*: `player_recoilscaleon(0)` four times a second; off hands back to the stock `stancerecoilupdate`. Spread: no zombies script uses `setspreadoverride`, so its values are unknown: INVESTIGATING. R-W4 |
| Start with max ammo / extra start weapons / random start weapon (AAE) | Weapons | 6 | PARTIAL | *Start with max ammo* (Max Ammo a second after each spawn). Extra or random start weapons need the mystery box's weapon lists (per map, with camos and Pack-a-Punch levels in `interaction_magicwheel.gsc`): DEFERRED. R-W5 |
| Give / take / weapon info / testing tools | Weapons | 6/10 | PARTIAL | *Refill ammo* (Phase 6); *Give a weapon* (0.10.1): every box and wall weapon of the map's own weapon table, by class, and the map's wonder weapons, given as the box gives them (`ix/weapons/give.gsc`; L57; R-W8). Take / weapon info: not built |
| Weapon trade between players (AAE) | Weapons | – | DEFERRED | Use + trace; not started |
| Weapon roulette / gun game (AAE) | Weapons | – | DEFERRED | Needs the mystery box's weapon lists, as random start weapons do |
| Keep kit camo / choose PaP camo (AAE) | Weapons | 6 | INVESTIGATING | `+camoN` suffix; PaP flow |
| Random weapon kit (AAE) | Weapons | 6 | INVESTIGATING | Attachment validity |
| Quick weapon switch | Weapons | 6 | INVESTIGATING | `_meth_84AF` |
| Box filters by source title / ported weapons (AAE) | Weapons | – | BLOCKED | Needs fastfiles (L14) |
| Weapon-asset edits | Weapons | – | BLOCKED | L4 |

## Zombies (Phase 7)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Zombie speed (default / walk / run / sprint) | Zombies | 7 | TESTING | `ix/zombies/agents.gsc`: the mod's hook in front of the stock `level.movemodefunc` of regular zombies and cops (clowns and skeletons keep their own). The game has no faster mode than sprint, so AAE's "super sprint" has no equivalent. L54; R-Z1 |
| Weaker / tougher zombies (AAE: weaker zombies, health cap round) | Zombies | 7 | TESTING | *Zombie health* 10–1000 percent, set on each regular zombie when the game announces its spawn (`"agent_spawned"`) and on those out when it changes; bosses and brutes keep theirs. 0.10.0–0.10.1 used the stock multiplier `level._id_8CB3`, which did nothing in game (L58). *In effect now* shows one zombie's health next to the game's. A cap round: not built. L54, L58; R-Z2 |
| Starting round (AAE) | Zombies | 7 | TESTING | `ix/zombies/rounds.gsc`: `level.wave_num` and `last_event_wave` before the first round, as the stock boss-fight-only modes do; from the next match; it counts toward the highest round (L53); R-Z6 |
| Points multiplier | Zombies | 7 | TESTING | `ix/zombies/points.gsc`: `level.cash_scalar` (kills, hits, the Nuke, windows) times the option; Double Money still doubles. R-Z4 |
| Power-ups per round | Zombies | 7 | TESTING | `level.powerup_drop_max_per_round` (the game's 5; 0: none from kills). R-Z5 |
| Start with every perk | Zombies | 7 | TESTING | `ix/zombies/perks.gsc`: the stock permanent-perks reward (`give_permanent_perks`) at each spawn. R-Z7 |
| Extra points per kill / melee / headshot (AAE) | Zombies | 7 | PLANNED | Agent `on_killed` wrapper |
| Zombie damage multiplier / melee modifier | Zombies | 7 | PLANNED | Agent `on_damaged` wrapper |
| BO4 Max Ammo refills clips (AAE) | Zombies | 7 | PLANNED | Hook `ammo_max` |
| Perk utilities; spawn with perks; perk decay when downed (AAE) | Zombies | 7 | PARTIAL | Spawn with perks: *Start with perks* (above). Perk decay and per-perk tools: `give_zombies_perk` / `take_zombies_perk`, not built |
| Currency utilities; share points (AAE) | Zombies | 7 | PLANNED | `cp_persistence` |
| Power-up spawning (debug) | Zombies | 10 | TESTING | Debug → *Drop a power-up* (locked): seven power-ups with the stock `drop_loot`, as the Fate & Fortune cards drop them. R-D6 |
| Bank / weapon locker (AAE) | Zombies | 7 | PLANNED | File I/O (fs_game) |
| Weapon restore on reconnect/death (AAE) | Zombies | 7 | PLANNED | Per-GUID store |
| Immortal snail / Gambler events (AAE fun) | Zombies | 7 | PLANNED | |
| Max spawned zombies / extra zombies (AAE) | Zombies | 7 | TESTING | *Max zombies alive* 1–64 (`level.max_static_spawned_enemies`, the game's 24) while a round runs; the engine's agent pool may cap it (L54); R-Z3 |
| Horrific (double-speed) zombies (AAE) | Zombies | 7 | INVESTIGATING | `generalspeedratescale` |
| Round size algorithm / no spawn delay / no round delay (AAE) | Zombies | 7 | INVESTIGATING | Hashed wave-loop internals |
| Timed gameplay / Roamer / end-game challenge (AAE) | Zombies | 7 | INVESTIGATING | Same |
| Open all doors / power on / box everywhere (AAE) | Zombies | 7 | INVESTIGATING | Door/power/magic-wheel logic to trace |
| Round revive / spectator respawn (AAE) | Zombies | 7 | INVESTIGATING | `cp_laststand`, afterlife |
| Power-up frequency / improved Nuke / BO4 Carpenter (AAE) | Zombies | 7 | INVESTIGATING | `scripts\cp\loot` |
| Bigger Mule Munchies (AAE "bigger Mule Kick") | Zombies | 7 | INVESTIGATING | `give_more_perk` |
| Fate & Fortune cards disable/unlimited (≈ AAE gum options) | Zombies | 7 | INVESTIGATING | `zombies_consumables`, `cg_unlimited_cards` |
| Perk limit (AAE) | Zombies | – | INVESTIGATING | No IW7 perk cap found |
| Zombie juke (AAE) | Zombies | – | BLOCKED | L13 |
| >4 players (AAE 10-player) | Zombies | – | BLOCKED | L15 (pending test) |
| Offline bots (AAE) | Zombies | – | INVESTIGATING | L19 |
| Solo Easter eggs / EE rewards / career stats (AAE) | Zombies | – | DEFERRED | Large per-map effort |

## Quality of life / visuals / utilities (Phases 9, 11)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Chat commands (save, tp, ammo, help) | QoL | 9 | TESTING | `ix/qol/qol.gsc`: `!ix refill`, `!ix save`, `!ix load`, `!ix tp` (the menu's actions, same rules); `!ix` lists everything, a few lines a frame. Bank and share: not built. R-Q5 |
| Restart | QoL | 9 | TESTING | Game → *Restart the match* (host, Use twice): iw7-mod's console `map_restart`. L55; R-Q4 |
| Timescale | Utilities | 9 | TESTING | Game → *Game speed* 25–200 percent with iw7-mod's `setslowmotion( s, s, 0 )`; the game's speed back at 100 and at the match's end. L55; R-Q2 |
| Presets (Default/Classic/Enhanced/Testing/Developer/Custom) | Config | 11 | TESTING | `ix/core/presets.gsc`: built-in presets as data (`id=value` words), applied through `config::set` to every governed setting (the menu's own settings, the HUD's position and the characters are kept); *Custom* saved as archived dvars (L38, L59); *In use* read-out; Presets page and `!ix preset`. R-C10 |
| Feature reset (all / per category) | Config | 9 | TESTING | *Reset every setting* and *Reset this page* (every page of options). R-Q1 |
| Vision presets | Visuals | – | DEFERRED | `visionsetnakedforplayer` works, but the stock scripts set their own vision at many moments (last stand, afterlife arcade, revives, Rave mode, Dischord glasses, the final boss), and only three names exist on all five maps |
| Night vision | Visuals | 9 | INVESTIGATING | `_meth_821A` |
| Outlines | Visuals | 9 | TESTING | Game → *Zombie outlines*: every enemy outlined in orange through walls for every player, as the stock outline effects do (`cp_outline::enable_outline_for_player`). Pinging: not built. R-Q3 |
| Hitmarkers | Visuals | – | INVESTIGATING | IW7 CP has native damage feedback |
| Overhead map view (AAE keybind) | QoL | 9 | INVESTIGATING | `playerlinkto` camera |
| Client "disable X" visual toggles (AAE) | Visuals | – | DEFERRED | Client Lua / client dvars, per item |
| Grenade projection, player POV camera (AAE) | Visuals | – | BLOCKED | Client rendering |

## Debug / developer (Phase 10)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Developer menu gate (never accidental) | Debug | 10 | TESTING | *Developer tools* (`dev_tools`, off): until ON the Debug page's tools read "Locked"; each is host only and asks for a second Use. R-D1 |
| UFO / noclip-style fly | Debug | – | BLOCKED | iw7-mod's `ufo` / `noclip` are client commands needing `sv_cheats`; the script methods are null in v1.1.0 (L56). A fly mode built from a script mover: not looked into |
| Teleport tools (save/load, crosshair, nearest zombie, teleport zombies) | Debug | 10 | PLANNED | |
| Entity tools (spawn/place/rotate/delete models) | Debug | 10 | PLANNED | `spawn`, `setmodel`, `rotateto` |
| Entity inspector / trace info | Debug | 10 | TESTING | *What am I looking at?*: `bullettrace` and the entity's fields (kind, agent type, model, health, distance). R-D7 |
| Player / map / round info, coordinates | Debug | 10 | TESTING | Debug → *Information*: map, players, round, zombies alive and left, position X / Y / Z. Weapon info: not built. R-D7 |
| Pause zombie spawning | Debug | 10 | TESTING | *Pause / resume spawning* (locked): `level.zombies_paused`, set again while paused (`debug_pause_spawning` is never read by the game). L52; R-D2 |
| Kill all zombies / end the round / give points | Debug | 10 | TESTING | Locked tools: as the Nuke kills (bosses and brutes spared), the round's kill count set to its goal, `give_player_currency`. R-D3–R-D5 |
| Clone player / fun effects | Debug | 10 | PLANNED | `_meth_8086`, `earthquake`, `hide` |
| Spawn testing | Debug | 10 | INVESTIGATING | `spawnnewagent` semantics |
| Script log viewer | Debug | 10 | TESTING | `!ix log [n]`: the last 8 (up to 32) `[IX]` lines from the ring buffer, to the player who asked. R-D8 |
| Performance information | Debug | 10 | INVESTIGATING | Server-side only |
| 3D debug drawing | Debug | – | BLOCKED | L2 |
| Aimbot (in AAE's dev menu) | Debug | – | NOT PLANNED | MP cheating tool; excluded by design |

## Guided Mode (Phase 13, 0.13.0)

The scope is in `ROADMAP.md`. Every guide step is taken from the stock scripts (file and line in `tools/guided/research/<map>.md`) and checked against them by `tools/tests/test_guides.py`; walkthrough-only details are marked there, and places no source confirms are left out of the texts.

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Guided Mode toggle before a map (OFF by default, remembered, never switched on by an update) and in the in-game menu | Guided | 13 | TESTING | The lobby's GUIDED MODE button writes `seta ix_guided_mode` (ui_scripts); the setting `guided_mode` (default 0) on the menu's Guided Mode page. R-G1 |
| One verified guide per map, as data apart from the code | Guided | 13 | TESTING | `ix/guided/guides/<map>.gsc`: Spaceland 17 steps (by hand), Rave in the Redwoods 18, Shaolin Shuffle 34, Attack of the Radioactive Thing 44, The Beast from Beyond 22, generated by `tools/guided/make_guide.py` from specs and research. R-G2 |
| Contextual objectives and hints; automatic progress from the game's own signals, else Next / Previous / Mark complete / Full guide | Guided | 13 | TESTING | `ix/guided/tracker.gsc`: flags, notifies, counted notifies and guide checks that read the world (C10 fields avoided); later steps close earlier ones; steps done in any order (`step.parallel`) close by their own signal or with a step that needs them (`step.needs`); the game's undo notifies roll the guide back (`step.reset`). Two Shaolin Shuffle steps have nothing to read (L60). R-G2, R-G3 |
| Locations and directions; markers only for targets the game can locate | Guided | 13 | TESTING | The objective's item outlined for that player, through walls (0.13.1, `guided_outline`): the target when it is a script model or an agent, else the script model on its spot. A waypoint (as the stock revive icon) where there is none. The distance in meters. Targets are structs, entities, interactions or the guide's own locator, all names the stock scripts use; elsewhere the hint gives the place. R-G4 |
| Hint levels: Minimal, Standard (default), Detailed, Full Walkthrough | Guided | 13 | TESTING | `guided_hints`; *Reveal more* raises it for one step; full shows the next step and lets *Next step* look ahead. R-G3 |
| Guided Mode HUD panel (hide, minimize, position, size, opacity) | Guided | 13 | TESTING | `ix/guided/panel.gsc`, about 11 archived elements and the marker, hidden with the menu open (L62); `guided_panel`, `guided_side`, `guided_height`, `guided_text`, `guided_opacity`, `guided_marker`. R-G4 |
| Objective complete / New objective notifications | Guided | 13 | TESTING | `iprintlnbold` with the game's own challenge sounds (`zmb_challenge_complete`, `zmb_challenge_start`, cp_challenge.gsc); steps done ahead in any order are announced too. R-G2 |
| Co-op: the game's progress for all; hand marks shared or personal | Guided | 13 | TESTING | The quest runs on the host, so what the game reports is the same for everyone; `guided_coop`. R-G5 |
| "GUIDED MODE UNAVAILABLE" on maps without a verified guide | Guided | 13 | TESTING | Never another map's guide; every stock zombies map has one now |
| `!ix guide [next / prev / more / done]` | Guided | 13 | TESTING | The current objective and hint in chat. R-G6 |
| Guide generator and guide data test | Tooling | 13 | COMPLETE | `tools/guided/make_guide.py`, `tools/tests/test_guides.py` (`TESTING.md` V151) |

## Emotes (Phase 14, 0.14.0)

The scope is in `ROADMAP.md`. AAE's emotes were studied first (`IW_API_NOTES.md` §23); every emote is a gesture its map loads, checked against the stock scripts by `tools/tests/test_emotes.py`.

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Emotes as a feature of their own (on by default; off ends one playing) | Fun | 14 | TESTING | `ix/fun/emotes.gsc`, feature `emotes`, its own module (`fun`). R-E1 |
| Each map's emotes: every character's Pack-a-Punch, entrance and card gestures, and the map's hand gestures | Fun | 14 | TESTING | `ix/fun/emote_data.gsc`: Spaceland 19, Rave 15, Shaolin Shuffle 15, Radioactive Thing 17, Beast 3. Off-hand gestures fired as the game fires them, hand gestures as `gesture_activate` plays them; card sounds as the game's. R-E2 |
| Categories: Celebration, Poses, Greetings, Taunts, Funny | Fun | 14 | TESTING | A category without emotes on the map is left out of *Browse emotes*. R-E2 |
| Categories Dance, Reactions, Miscellaneous | Fun | 14 | BLOCKED — IW LIMITATION | No such animation a script can play (L64) |
| Emote menu: wheel, browse, favorites, random, settings, preview | Fun | 14 | TESTING | `ix/ui/menu_tree.gsc` `emote_pages()`. R-E1 |
| Radial emote wheel | Fun | 14 | TESTING | A menu page drawn as a ring (`page.wheel`, menu.gsc `draw_wheel`): seven slots and *Back* at the bottom, picked by the stick's direction, with the menu's own elements (no new HUD elements, L49). R-E1 |
| Preview | Fun | 14 | TESTING | The closest stable alternative to a preview screen: the emote played with the camera behind the player (a script cannot show a separate model of the player). R-E3 |
| Favorites (seven, the wheel's) saved across games | Fun | 14 | TESTING | Host: `ix_emote_favorites` in the config; per character across maps; a guest's for the match (L65). R-E4 |
| Emote safety (death, down, revive, weapon change, rounds, teleports, menus, interrupts) | Fun | 14 | TESTING | Starts only on the ground with nothing else going on and no zombie within 3 m; ends on damage, down, death, a new emote, Emotes off; never holds the player, aiming, melee (and grenades for a hand gesture) back through the stock counters; the camera back as Third person has it; at most 8 seconds. R-E5 |
| `!ix emote [name / random / list]` | Fun | 14 | TESTING | R-E6 |
| Emotes from the menu wait for the player to be on the ground again (fix of "Land first", first in-game report) | Fun | 14 | TESTING | `emotes.gsc` `play()`, as `menu.gsc` `open_after_landing`. R-E10 |
| A key for the emote wheel (B) | Fun | 14 | TESTING | Raw keys: BLOCKED (L70). `!ix wheel` toggles the menu at the wheel; `bind b "say !ix wheel"`. R-E10 |
| Visible to other players | Fun | 14 | NEEDS TESTING | L66, R-E3 |

### Custom emotes (after Phase 14, in progress: step 1 of 4)

Your own full-body animations, played on a copy of your character (`IW_API_NOTES.md` §24). The plan's four steps are in `ROADMAP.md`.

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Stand-in body: player hidden and held, a copy with their body and attachments plays the animation, camera behind, everything back on every way out | Fun | 14+ | TESTING | `ix/fun/emote_custom.gsc`; `tools/tests/test_custom_emotes.py`. R-E8 |
| Custom category on the emote pages, favorites, `!ix emote u1` | Fun | 14+ | TESTING | Appended to the map's emotes; ids `u1`…; R-E8 |
| Setting to switch them off | Fun | 14+ | TESTING | `emote_custom` (on), from the next map; at the next game start the pack is not loaded. R-E9 |
| Step 1: proof pack from a game animation (`Build Custom Emotes.cmd`) | Tooling | 14+ | NEEDS TESTING | `installer/IXEmotes.Core.ps1`: x64-zt lists `cp_zmb` / `patch_cp_zmb`, dumps `IW7_cp_zom_hoff_dj_desk_01`, renames it `ix_emote_proof`, builds and re-lists `ix_emotes`; logs the bone names. L69, R-E7 |
| Menu script loads the pack and hands the list to the GSC | UI | 14+ | TESTING | `ui_scripts/InfiniteExpansion/__init__.lua` `loadEmotes()`; `tools/tests/test_menu_script.py` |
| Seen by other players; a guest without the pack | Fun | 14+ | NEEDS TESTING | L67, R-E7 |
| Step 2: converter (SEAnim, Cast, then glTF/GLB) through one intermediate, `.xab` reader and writer proven by byte-for-byte round trips | Tooling | 14+ | PLANNED | `ROADMAP.md` |
| Step 3: *Build Custom Emotes* in the setup, a manifest, host-side checks | Tooling | 14+ | PLANNED | `ROADMAP.md` |
| Step 4: docs, tests, version, release | — | 14+ | PLANNED | |

## Fun features (Phases 15–21, not started)

The full scope is in `ROADMAP.md`. Nothing here is started; each feature is verified against the game first, and dropped or marked BLOCKED if the game cannot support it.

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Fun player and movement effects (super jump, gravity, speed, spin, poses, landings, third person, size) | Fun | 15 | PLANNED | Shares mechanisms with Phases 4–5; global dvars restored (L17, L20) |
| Fun zombie effects (speed, health, size, freeze, launch, random) | Fun | 15 | PLANNED | Only what the game exposes; each tested alone |
| Fun weapon effects (rapid or slow fire, infinite ammo, magazine, damage, recoil, one-shot) | Fun | 15 | PLANNED | Separate from the Phase 6 weapon system |
| Visual effects and miscellaneous toys | Fun | 15 | PLANNED | |
| Zombies randomizer, with RESET RANDOMIZER | Fun | 16 | PLANNED | Only supported systems |
| Favorites and presets of fun features | Fun | 17 | PLANNED | Persist only if reliable (L38), else per session; related to Phase 11 |
| FUN menu section and polish | Fun | 18 | PLANNED | Menu root title to settle ("ALL-SPECTRUM" in the request) |
| Secret feature manager and easter eggs | Fun | 19 | PLANNED | Hidden from the normal menus; reversible |
| Co-op social and show-off features | Fun | 20 | PLANNED | No pretend synchronization; local where it cannot sync |
| Fun feature test checklist | Testing | 21 | PLANNED | Goes into `TESTING.md` with the features |

