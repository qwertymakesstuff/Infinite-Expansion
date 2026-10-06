# FEATURE_STATUS.md

**Statuses:** PLANNED · INVESTIGATING · IN PROGRESS · TESTING · COMPLETE · PARTIAL · BLOCKED

Nothing is COMPLETE yet; Phase 0 produced analysis only. A feature becomes COMPLETE only after it is compiled with both iw7-mod compilers **and** confirmed in-game (see `TESTING.md`). Evidence for every API named here is in `IW_API_NOTES.md`.

## Project / analysis

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| IW7 modding research | Analysis | 0 | COMPLETE | `PROJECT_ANALYSIS.md` §2, `IW_API_NOTES.md` |
| BO3 AAE file analysis | Analysis | 0 | BLOCKED | Archive not downloadable here (env egress policy). Provisional inventory from secondary sources only |
| Offline compiler toolchain (both iw7-mod pins) | Tooling | 0 | COMPLETE | Built and exercised in Phase 0; `tools/setup_compilers.sh` |
| Dual-compile parity check | Tooling | 1 | PLANNED | Diff release/develop disassembly |
| Far-call / mode-separation lint | Tooling | 1 | PLANNED | Checks `scripts\…` targets against the dump |

## Core (Phases 1–2)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Entry scripts (CP, MP) | Core | 1 | PLANNED | `custom_scripts/{cp,mp}/ix_main.gsc` |
| Bootstrap + duplicate-init guard | Core | 1 | PLANNED | |
| Compatibility module (raw ids, feature detection) | Core | 1 | PLANNED | Fixes the v1.1.0 mislabels (C1, C2) |
| Logging | Core | 1 | PLANNED | iw7-mod `print`/`logprint` |
| Feature manager | Core | 2 | PLANNED | |
| Configuration manager | Core | 2 | PLANNED | Registry + clamp/validate + `ix_*` dvars |
| Live console overrides (`set ix_x v`) | Core | 2 | PLANNED | Replaces AAE `/d` (L3) |
| File persistence | Core | 2 | PLANNED | Needs a mod-folder install (L9) |
| Event bus | Core | 2 | PLANNED | Real IW7 notifies only |
| Utility library | Core | 2 | PLANNED | |

## UI (Phase 3) / HUD (Phase 8)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| GSC menu engine (pages, toggles, sliders, selects, actions) | UI | 3 | PLANNED | Create-once HUD elements |
| Menu controls (ADS+Melee open, etc.) | UI | 3 | PLANNED | Avoids all CP action slots |
| Reset / defaults from menu | UI | 3 | PLANNED | |
| Host-only access rules | UI | 3 | PLANNED | |
| HUD: round, zombies remaining | HUD | 8 | PLANNED | CP |
| HUD: coordinates, speed, weapon/ammo, health | HUD | 8 | PLANNED | |
| HUD: active modifiers list | HUD | 8 | PLANNED | |
| HUD: FPS | HUD | 8 | BLOCKED | L5: server GSC cannot read client FPS |
| HUD style swap of stock LUI HUD | HUD | – | INVESTIGATING | Needs client Lua; deferred |
| HUD string-overflow behaviour | HUD | 3/8 | INVESTIGATING | L12, NEEDS TESTING |

## Player (Phase 4) / Movement (Phase 5)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| God mode | Player | 4 | PLANNED | `enableinvulnerability` / `_meth_80A1` |
| Health settings | Player | 4 | PLANNED | `.maxhealth`; CP regen interaction NEEDS TESTING |
| Player damage multiplier | Player | 4 | PLANNED | Wrap `level.callbackplayerdamage` after map init |
| Third person | Player | 4 | PLANNED | `_meth_845E` (per player) |
| Teleport / position utilities | Player | 4 | PLANNED | `setorigin`, traces |
| Player collision (ejection) | Player | 4 | PLANNED | `bg_playerEjection` (global) |
| Movement speed (per player) | Movement | 5 | PLANNED | `setmovespeedscale`, safe range 0.5–3.0 (NEEDS TESTING) |
| Gravity | Movement | 5 | PLANNED | `bg_gravity` 1–1000 (global) |
| Jump height | Movement | 5 | INVESTIGATING | No verified dvar (L16) |
| Disable slide / wallrun / double jump / mantle | Movement | 5 | PLANNED | `allow*` methods |
| Unlimited sprint | Movement | 5 | PLANNED | `bg_sprintUnlimited`, develop only (C4) |
| Omni-movement | Movement | 5 | PLANNED | `bg_omnimovement`, develop only (C4) |
| Air control | Movement | 5 | PLANNED | `bg_airControl`, develop only (C4) |
| Fall damage toggle | Movement | 5 | PLANNED | `jump_enableFallDamage` |
| Legacy mantle | Movement | 5 | PLANNED | `mantle_legacy*` |
| Boost energy tuning | Movement | 5 | INVESTIGATING | `energy_*` semantics NEED TESTING |

## Weapons (Phase 6)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Infinite ammo | Weapons | 6 | PLANNED | `player_sustainAmmo` (global) or per-player refill |
| No reload (always-full clip) | Weapons | 6 | PLANNED | Per-player clip refill |
| Fire-rate modifier / rapid fire | Weapons | 6 | PLANNED | `_meth_85C1(pct)`; valid range NEEDS TESTING |
| Recoil modifier | Weapons | 6 | PLANNED | `player_recoilscaleon(0–100)` / `_meth_822C` |
| Spread modifier | Weapons | 6 | PLANNED | `setspreadoverride` / `_meth_8263` |
| Damage multiplier (vs zombies) | Weapons | 6 | PLANNED | Agent `on_damaged` wrapper (CP) |
| Give / take / weapon info | Weapons | 6 | PLANNED | |
| Weapon testing tools (give by full name incl. `+attachments`, refill, cycle list) | Weapons | 6/10 | PLANNED | Debug-gated |
| Quick weapon switch | Weapons | 6 | INVESTIGATING | `_meth_84AF`, no stock usage |
| Weapon-asset edits | Weapons | – | BLOCKED | L4: debug builds only |
| New camos | Weapons | – | BLOCKED | L14: needs x64-zt assets (deferred) |

## Zombies (Phase 7)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Zombie count info | Zombies | 7 | PLANNED | Wave counters |
| Round utilities (set / skip round) | Zombies | 7 | PLANNED | `level.wave_num`; side effects NEED TESTING |
| Zombie speed (default/sprint/super) | Zombies | 7 | PLANNED | `level.movemodefunc[type]`, `moveratescale` |
| Zombie health modifier / cap | Zombies | 7 | PLANNED | Post-spawn scaling |
| Spawn cap / extra zombies | Zombies | 7 | INVESTIGATING | Engine agent cap unknown |
| Kill all / freeze / teleport zombies (debug) | Zombies | 7 | PLANNED | Debug-gated |
| Zombie targeting: zombies ignore a player | Zombies | 7 | PLANNED | `self.ignoreme` (token; 49 stock uses) |
| Melee damage modifier | Zombies | 7 | PLANNED | Agent `on_damaged` wrapper, `MOD_MELEE` |
| Power-up spawning (debug) | Zombies | 7 | PLANNED | `scripts\cp\loot::drop_loot` |
| Perk utilities | Zombies | 7 | PLANNED | `give_zombies_perk` / `take_zombies_perk` |
| Currency utilities | Zombies | 7 | PLANNED | `cp_persistence` currency functions |
| Max Ammo refills clips (AAE) | Zombies | 7 | PLANNED | Hook the `ammo_max` power-up |
| Weapon roulette (AAE) | Zombies | 7 | PLANNED | On `regular_wave_starting` |
| Friendly fire options (AAE) | Zombies | 7 | PLANNED | `scr_team_fftype` / callback |
| Bank / weapon locker (AAE) | Zombies | 7 | PLANNED | File I/O (fs_game) |
| Weapon restore on reconnect (AAE) | Zombies | 7 | PLANNED | Per-GUID store |
| Non-stop spawns / round break timing (AAE) | Zombies | 7 | INVESTIGATING | Wave-loop internals are hashed |
| Disable Fate & Fortune cards (≈ gobblegums) | Zombies | 7 | INVESTIGATING | `zombies_consumables.gsc` |
| Perk limit (AAE) | Zombies | 7 | INVESTIGATING | No IW7 perk-cap logic found |
| Zombie dodge (AAE) | Zombies | – | BLOCKED | L13: needs animations/ASM |
| 10-player zombies (AAE) | Zombies | – | BLOCKED | L15: 4-player mode (pending test) |
| Offline bots (AAE) | Zombies | – | INVESTIGATING | L19: no CP bot AI found |
| Solo Easter eggs / EE rewards (AAE) | Zombies | – | INVESTIGATING | Large per-map effort; deferred |

## Gameplay / QoL / Visuals / Utilities (Phases 9, 11)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Fast restart | QoL | 9 | PLANNED | `map_restart` / `executecommand("fast_restart")`, NEEDS TESTING |
| Timescale | Utilities | 9 | PLANNED | `setslowmotion` / `timescale` |
| Presets (Default/Classic/Enhanced/Testing/Developer/Custom) | Config | 11 | PLANNED | |
| Feature reset (all / per category) | Config | 9/11 | PLANNED | |
| Night vision | Visuals | 9 | INVESTIGATING | `_meth_821A`, no stock usage |
| Vision presets | Visuals | 9 | PLANNED | `visionsetnakedforplayer` |
| Pinging / outlines | Visuals | 9 | INVESTIGATING | `cp_outline`, `_meth_8549` |
| Hitmarker sounds | Visuals | 9 | PARTIAL | Stock sounds only (`_meth_8242`) |
| Damage numbers / health bars | Visuals | 9 | INVESTIGATING | HUD budget risk |

## Debug / developer (Phase 10)

| Feature | Category | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Developer menu gate (never accidental) | Debug | 10 | PLANNED | Requires `ix_dev 1` **and** a menu confirm |
| Entity inspector / trace info | Debug | 10 | PLANNED | `bullettrace`, entity fields |
| Player / weapon / map / round info | Debug | 10 | PLANNED | |
| Coordinates | Debug | 10 | PLANNED | |
| Spawn testing | Debug | 10 | INVESTIGATING | |
| Script log viewer | Debug | 10 | PLANNED | Ring buffer of recent `ix` log lines |
| Performance information | Debug | 10 | INVESTIGATING | Server-side only (`gettime()` frame deltas, entity/agent counts); client FPS is L5 |
| 3D debug drawing | Debug | – | BLOCKED | L2: `line`/`print3d` are stubs |
