# FEATURE_STATUS.md

**Statuses:** PLANNED · INVESTIGATING · IN PROGRESS · TESTING · COMPLETE · PARTIAL · BLOCKED (· DEFERRED, N/A, NOT PLANNED)

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
| Cast data test (character table vs. stock scripts and the menu) | Tooling | 1.5 | COMPLETE | `tools/tests/test_character_data.py` (6 tests; mutation-checked) |
| Lua UI check (syntax + API names vs. iw7-mod's ui_scripts) | Tooling | 1.5 | COMPLETE | `check.py` `lua`; fixture-tested |

## Installer (Windows)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| One-click setup window (install / update / uninstall) | Installer | 1.5 | TESTING | `Infinite Expansion Setup.cmd` → `installer/IXSetup.ps1` (WPF, Windows PowerShell 5.1); 80s neon art; R-I1, R-I3, R-I5, R-I8 |
| Finds the game through Steam (registry, every library, app manifest) | Installer | 1.5 | TESTING | BROWSE as fallback; R-I2, R-I7 |
| Installs the iw7-mod client when it is missing | Installer | 1.5 | TESTING | Latest GitHub release (SHA-256 digest when listed), iw7-mod's update server as fallback (SHA-1); progress in the window; R-I10, R-I13 |
| PLAY: starts iw7-mod (opens Steam first if needed); desktop shortcut | Installer | 1.5 | TESTING | R-I10, R-I11 |
| Game not installed: Steam's install dialog, then automatic re-detection | Installer | 1.5 | TESTING | `steam://install/292730`; checks again every 4 s; R-I12 |
| Uninstall from Windows Settings → Apps | Installer | 1.5 | TESTING | Per-user entry; a setup copy in `%LOCALAPPDATA%`; R-I6 |
| Removes exactly what it installed; removes the old Mods-menu copy | Installer | 1.5 | TESTING | Record `iw7-mod/infinite-expansion.json`; R-I4, R-I5 |
| Installer tests (logic under PowerShell 7, 5.1 lint, XAML checks, downloads against a local fake server) | Tooling | 1.5 | COMPLETE | `tools/tests/test_installer.py` (29 tests), `tools/tests/ps51_lint.ps1` |
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
| Feature manager | Core | 2 | PLANNED | |
| Configuration manager (flat keys, like AAE's `tfoption_*`) | Core | 2 | PLANNED | `ix_*` dvars; live apply |
| Settings file + schema version (AAE: save data + `tfoption_master_ver`) | Core | 2 | PLANNED | `ix_settings.cfg`; needs the Mods-menu install (L9), which cannot be joined (L30), so dvars stay the main store |
| Live console overrides (`set ix_x v`) | Core | 2 | PLANNED | Replaces AAE `modvar` / `/d` (L3) |
| Event bus | Core | 2 | PLANNED | Real IW7 notifies only |
| Utility library | Core | 2 | IN PROGRESS | `util.gsc` so far: `is_valid_player`, `is_human`, `join` |
| Chat-command router (`say` notify) | Core | 2 | PLANNED | AAE `chatnotify.gsc` equivalent |

## Characters (Phase 1.5)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| CHARACTER button in the zombies main menu (base-game style) | UI | 1.5 | TESTING | `ui_scripts/InfiniteExpansion`; saves `ix_character`, and for specials the stock lobby field `characterSelect`; R-UI1–R-UI5 |
| Choose your character before the match (no switching mid-match) | Player | 1.5 | TESTING | `ix/player/character.gsc`; applied when the player connects. Host: `ix_character`. Every player: specials through `characterSelect`. Toggle `ix_character_select`; R-CH1–R-CH3 |
| A guest's special-character pick in someone else's match | Player | 1.5 | TESTING | Travels in the guest's stats (`characterSelect`); works on the special's own map even without the mod on the host; R-CH3, R-CH8 |
| A guest's regular-character pick in someone else's match | Player | 1.5 | BLOCKED | No verified channel (L29); the guest gets a random character; R-CH4, probe R-CH12 |
| "<player> is playing as <character>" line after the intro | HUD | 1.5 | TESTING | Off by default; `ix_character_announce 1` shows it to everyone, once per player; R-CH10 |
| Per-map cast names | Player | 1.5 | TESTING | Actor names verified from stock VO code; outfit labels made from each map's model names |
| One character per player (no duplicates) | Player | 1.5 | TESTING | Keeps the stock random pool consistent; also stops two players getting the same special, which the stock game allows; R-CH5 |
| Special characters gated by unlocks | Player | 1.5 | TESTING | Soul keys / merit stats, checked for every pick (L27); `ix_character_specials` 0/1/2; R-CH6 |
| Special characters on any map | Player | 1.5 | TESTING (experimental) | Opt-in `ix_character_crossmap 1`; their models may not exist on other maps (L26); R-CH7 |
| Stock HUD portrait follows the chosen character | HUD | 1.5 | TESTING | Stock `setmodelfromcustomization` → `zm_player_character` |
| Player card, bottom right | HUD | 1.5 | TESTING | `ix/ui/player_card.gsc`: name and outfit; `ix_player_card`, `_x`, `_y`; R-CH9 |
| Player card picture | HUD | 1.5 | BLOCKED | L28 |

## UI (Phase 3) / HUD (Phase 8)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| GSC menu engine (pages, toggles, sliders, selects, actions) | UI | 3 | PLANNED | Create-once HUD elements |
| Menu controls (open ADS+Melee, configurable) | UI | 3 | PLANNED | Avoids all CP action slots |
| Settings pages mirroring AAE "Custom Mutations" categories | UI | 3 | PLANNED | Game / Player / Zombie / Weapon / Perk / Power-up / Modes |
| Reset / defaults / presets from menu | UI | 3/11 | PLANNED | |
| Host-only access + per-player access list | UI | 3 | PLANNED | AAE dev menu "verification" |
| LUI front-end (lobby-style options) | UI | – | DEFERRED | Client Lua; optional later |
| HUD: zombie counter (remaining + active) | HUD | 8 | PLANNED | AAE `_zm_counter` |
| HUD: round, timer, coordinates, speed, weapon/ammo, health | HUD | 8 | PLANNED | |
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
| God mode | Player | 4 | PLANNED | `enableinvulnerability` / `_meth_80A1` |
| Player health (AAE 1–5 hits) | Player | 4 | PLANNED | `.maxhealth`; regen interaction NEEDS TESTING |
| Starting points | Player | 4 | PLANNED | `set_player_currency` (CP) |
| Friendly-fire modes / one-team grief | Player | 4 | PLANNED | Damage-callback wrapper |
| Rocket jump | Player | 4 | PLANNED | Callback + `setvelocity` |
| Third person (incl. back-of-head) | Player | 4 | PLANNED | `_meth_845E` |
| Gun (arm) position | Player | 4 | INVESTIGATING | `cg_gun_x/y/z` via `setclientdvar` |
| Teleport / position utilities | Player | 4 | PLANNED | `setorigin`, traces |
| Zombies ignore player | Player | 4 | PLANNED | `self.ignoreme` |
| Player collision (ejection) | Player | 4 | PLANNED | `bg_playerEjection` (global) |
| Move-speed multiplier (AAE: same `g_speed`) | Movement | 5 | PLANNED | `g_speed` / `setmovespeedscale` |
| Gravity | Movement | 5 | PLANNED | `bg_gravity` 1–1000 |
| Jump height | Movement | 5 | INVESTIGATING | L16 |
| No slide / no wallrun / no double jump / no mantle | Movement | 5 | PLANNED | `allow*` |
| Unlimited sprint / omni-movement / air control | Movement | 5 | PLANNED | develop-only dvars (C4), feature-detected |
| Fall damage toggle | Movement | 5 | PLANNED | `jump_enableFallDamage` |
| Legacy mantle | Movement | 5 | PLANNED | `mantle_legacy*` |
| Boost energy tuning | Movement | 5 | INVESTIGATING | `energy_*` semantics |

## Weapons (Phase 6)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Infinite ammo / no reload | Weapons | 6 | PLANNED | `player_sustainAmmo` or per-player refill |
| Fire-rate modifier | Weapons | 6 | PLANNED | `_meth_85C1(pct)`; range NEEDS TESTING |
| Recoil / spread modifiers | Weapons | 6 | PLANNED | `player_recoilscaleon`, `setspreadoverride` |
| Start with max ammo / extra start weapons / random start weapon (AAE) | Weapons | 6 | PLANNED | |
| Give / take / weapon info / testing tools | Weapons | 6/10 | PLANNED | |
| Weapon trade between players (AAE) | Weapons | 6 | PLANNED | Use + trace |
| Weapon roulette / gun game (AAE) | Weapons | 6/7 | PLANNED | |
| Keep kit camo / choose PaP camo (AAE) | Weapons | 6 | INVESTIGATING | `+camoN` suffix; PaP flow |
| Random weapon kit (AAE) | Weapons | 6 | INVESTIGATING | Attachment validity |
| Quick weapon switch | Weapons | 6 | INVESTIGATING | `_meth_84AF` |
| Box filters by source title / ported weapons (AAE) | Weapons | – | BLOCKED | Needs fastfiles (L14) |
| Weapon-asset edits | Weapons | – | BLOCKED | L4 |

## Zombies (Phase 7)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Zombie speed (default/sprint/super) + super-sprint after 40 rule (AAE) | Zombies | 7 | PLANNED | `level.movemodefunc`, `moveratescale` |
| Weaker zombies / zombie health cap round (AAE) | Zombies | 7 | PLANNED | Post-spawn scaling |
| Starting round (AAE) | Zombies | 7 | PLANNED | `level.wave_num`; side effects NEED TESTING |
| Extra points per kill / melee / headshot (AAE) | Zombies | 7 | PLANNED | Agent `on_killed` wrapper |
| Zombie damage multiplier / melee modifier | Zombies | 7 | PLANNED | Agent `on_damaged` wrapper |
| BO4 Max Ammo refills clips (AAE) | Zombies | 7 | PLANNED | Hook `ammo_max` |
| Perk utilities; spawn with perks; perk decay when downed (AAE) | Zombies | 7 | PLANNED | `give_zombies_perk` / `take_zombies_perk` |
| Currency utilities; share points (AAE) | Zombies | 7 | PLANNED | `cp_persistence` |
| Power-up spawning (debug) | Zombies | 7/10 | PLANNED | `drop_loot` |
| Bank / weapon locker (AAE) | Zombies | 7 | PLANNED | File I/O (fs_game) |
| Weapon restore on reconnect/death (AAE) | Zombies | 7 | PLANNED | Per-GUID store |
| Immortal snail / Gambler events (AAE fun) | Zombies | 7 | PLANNED | |
| Max spawned zombies / extra zombies (AAE) | Zombies | 7 | INVESTIGATING | Engine agent cap unknown |
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
| Chat commands (bank, share, save, tp, ammo, help) | QoL | 9 | PLANNED | iw7-mod `say` notify |
| Fast restart | QoL | 9 | PLANNED | `map_restart` / `fast_restart` |
| Timescale | Utilities | 9 | PLANNED | `setslowmotion` / `timescale` |
| Presets (Default/Classic/Enhanced/Testing/Developer/Custom) | Config | 11 | PLANNED | |
| Feature reset (all / per category) | Config | 9/11 | PLANNED | |
| Vision presets | Visuals | 9 | PLANNED | `visionsetnakedforplayer` |
| Night vision | Visuals | 9 | INVESTIGATING | `_meth_821A` |
| Pinging / outlines | Visuals | 9 | INVESTIGATING | `cp_outline`, `_meth_8549` |
| Hitmarkers | Visuals | – | INVESTIGATING | IW7 CP has native damage feedback |
| Overhead map view (AAE keybind) | QoL | 9 | INVESTIGATING | `playerlinkto` camera |
| Client "disable X" visual toggles (AAE) | Visuals | – | DEFERRED | Client Lua / client dvars, per item |
| Grenade projection, player POV camera (AAE) | Visuals | – | BLOCKED | Client rendering |

## Debug / developer (Phase 10)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Developer menu gate (never accidental) | Debug | 10 | PLANNED | `ix_dev 1` + host + confirm (AAE: `elmg_cheats`) |
| UFO / noclip-style fly | Debug | 10 | PLANNED | Script mover |
| Teleport tools (save/load, crosshair, nearest zombie, teleport zombies) | Debug | 10 | PLANNED | |
| Entity tools (spawn/place/rotate/delete models) | Debug | 10 | PLANNED | `spawn`, `setmodel`, `rotateto` |
| Entity inspector / trace info | Debug | 10 | PLANNED | `bullettrace` |
| Player / weapon / map / round info, coordinates | Debug | 10 | PLANNED | |
| Disable AI spawners | Debug | 10 | INVESTIGATING | `debug_pause_spawning` |
| Clone player / fun effects | Debug | 10 | PLANNED | `_meth_8086`, `earthquake`, `hide` |
| Spawn testing | Debug | 10 | INVESTIGATING | `spawnnewagent` semantics |
| Script log viewer | Debug | 10 | PLANNED | Ring buffer of `[IX]` lines |
| Performance information | Debug | 10 | INVESTIGATING | Server-side only |
| 3D debug drawing | Debug | – | BLOCKED | L2 |
| Aimbot (in AAE's dev menu) | Debug | – | NOT PLANNED | MP cheating tool; excluded by design |
