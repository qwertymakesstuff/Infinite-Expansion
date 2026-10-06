# ARCHITECTURE.md — Infinite Expansion

> **Status: PROPOSED (Phase 0, final).** This design follows from the verified IW7 facts in `IW_API_NOTES.md` and the AAE v3.9.5 analysis (`PROJECT_ANALYSIS.md` §1). Section 10 maps AAE's components onto this design. Implementation starts in Phase 1.

## 1. Constraints that shape the design

| Constraint (verified) | Design consequence |
|-----------------------|--------------------|
| iw7-mod auto-loads only top-level `.gsc` files in `custom_scripts/`, `custom_scripts/<mode>/`, and `custom_scripts/cp_mp/` | One small **entry script per mode**; every module lives in `custom_scripts/ix/…`, which is never auto-loaded |
| Far calls to other custom files compile to `OP_ScriptFarFunctionCall custom_scripts/ix/<area>/<file> <func>` (compiled and disassembled in Phase 0) | Modules call each other by explicit path (`custom_scripts\ix\core\util::fn()`); no `#include` chains |
| `init()` runs before the map's `main()` | Bootstrap waits for the level before wrapping map-owned callbacks |
| 1 MiB custom bytecode budget, fatal if exceeded | Keep modules small; the build check reports total size (target ≤ 512 KiB) |
| v1.1.0 compiler mislabels/lacks many method names | Every raw `_meth_` / `_func_` id lives in **one** module (`ix\core\compat`) |
| File I/O only with `fs_game` | Persistence layer with a dvar-only fallback |
| CP and MP have different stock script sets | Shared modules never reference `scripts\cp\…` or `scripts\mp\…`; mode modules are referenced only by their own entry script |
| Server-side GSC; per-player HUD elements | Per-player state lives on the player entity (`self.ix`) |

## 2. Layout

The repository mirrors the game folder, so installing is a straight copy of `mods/` into the Infinite Warfare directory.

```text
Infinite-Expansion/                          (repository)
├── mods/
│   └── infinite_expansion/                  → <Infinite Warfare>/mods/infinite_expansion/
│       ├── desc.txt                         Mods-menu description
│       └── custom_scripts/
│           ├── cp/ix_main.gsc               ENTRY (zombies)       — auto-loaded
│           ├── mp/ix_main.gsc               ENTRY (multiplayer)   — auto-loaded
│           └── ix/                          MODULES               — loaded by reference only
│               ├── core/                    ≙ requested /scripts/core/
│               │   ├── bootstrap.gsc        init order, duplicate-init guard, shutdown
│               │   ├── compat.gsc           raw-id wrappers + client feature detection
│               │   ├── log.gsc              print/logprint wrappers, levels
│               │   ├── util.gsc             player/entity/array/string/timing helpers
│               │   ├── events.gsc           event bus over real IW7 notifies
│               │   ├── features.gsc         feature registry (register/enable/disable)
│               │   ├── config.gsc           setting registry, get/set/reset, presets
│               │   └── persist.gsc          file I/O (fs_game) with dvar fallback
│               ├── ui/                      ≙ /scripts/ui/
│               │   ├── menu.gsc             menu engine (pages, items, rendering, input)
│               │   ├── menu_tree.gsc        menu definition (data only)
│               │   └── hud.gsc              info HUD (create-once/update)
│               ├── player/                  ≙ /scripts/player/   (shared MP/CP)
│               │   ├── player.gsc           health, god mode, third person, utilities
│               │   └── movement.gsc         speed, gravity, sprint/slide/mantle options
│               ├── weapons/                 ≙ /scripts/weapons/  (shared)
│               │   └── weapons.gsc          ammo, fire-rate, recoil, spread, give/take, info
│               ├── zombies/                 ≙ /scripts/zombies/  (CP ONLY)
│               │   ├── zombies.gsc          speed, health, counts, spawn tuning
│               │   └── rounds.gsc           round utilities and round hooks
│               ├── mp/                      MP-only helpers
│               └── debug/                   ≙ /scripts/debug/   (gated)
│                   └── debug.gsc            inspector, trace info, perf/log read-outs
├── tools/                                   offline verification (Linux)
└── *.md                                     project documentation
```

`/assets/` from the original brief maps to `mods/infinite_expansion/ui_scripts/` (client Lua, later) and an optional `mod.ff` (x64-zt, deferred). Neither is used in the script phases.

## 3. Initialization flow

```text
iw7-mod loads custom_scripts/<mode>/ix_main.gsc
│
├─ main()     [G_LoadStructs — before stock level scripts]
│   └─ (reserved for replacefunc hooks; nothing in Phase 1)
│
└─ init()     [Scr_LoadLevel — before the map's main()]
    └─ ix\core\bootstrap::start(mode)
        ├─ guard: if level.ix already exists → log + return     (no double init)
        ├─ level.ix = spawnstruct(); mode, map, client features (compat::detect)
        ├─ core:     log → util → events → features → config
        ├─ config:   register all settings → load (file if fs_game, else dvars)
        ├─ modules:  each module's register() adds features + settings + menu items
        │             (CP entry also registers ix\zombies\*; MP entry registers ix\mp\*)
        ├─ events:   start listeners (connected, spawned_player, waves, game_ended)
        ├─ wait for level ready (first "connected" / prematch) ─┐
        │                                                       ├─ wrap map-owned callbacks
        │                                                       └─ apply enabled global features
        └─ per player (events: player_connect → player_spawn)
            ├─ self.ix = spawnstruct()  (state, HUD handles, menu state)
            ├─ menu input watcher (one thread, guarded)
            └─ apply enabled per-player features (re-applied every spawn)
```

**Shutdown.**
- On `game_ended`, threads end through `level endon("game_ended")`.
- On player `disconnect`, per-player HUD elements are destroyed and threads end with `self endon("disconnect")`.
- Global dvars the mod changes (for example `bg_gravity`) are restored to the values captured at init whenever their feature is disabled, and again on `game_ended`.
  - This is **best effort**: an abrupt map change can end scripts before the restore runs. Dvars are process-wide, so such a value persists until the mod's next load re-applies or resets it.
  - Changed global dvars are therefore listed in the menu's *Active modifiers* view.

## 4. Core systems (interfaces)

### 4.1 Feature manager (`ix\core\features`)

```text
register(id, category, modes[], scope, fn_enable, fn_disable, fn_player_apply, requires[])
enable(id) / disable(id) / is_enabled(id) / toggle(id)
```

- **Duplicate-registration guard.** Registering the same `id` twice is logged and ignored.
- **Compatibility gating.** `modes` must include the current mode. Any entry in `requires` (such as `"dvar:bg_omnimovement"` or `"fs_game"`) must be satisfied, otherwise the feature is shown as *unavailable* and cannot be enabled.
- **Scope.** `global` features have enable/disable functions. `player` features have a per-player apply function that runs on enable and on every spawn.

### 4.2 Configuration manager (`ix\core\config`)

```text
register_setting(id, type, default, min, max, step, options[], label, help, scope, on_change)
get(id) / set(id, value) / reset(id) / reset_all() / apply_preset(name)
```

- **Types:** `bool`, `int`, `float`, `enum`.
- **Validation.** Values are clamped to `[min, max]`; enum values are validated against `options`.
- **Source of truth at runtime:** `level.ix.settings[id]`.
- **Live console overrides.** Every setting is mirrored to dvar `ix_<id>`. A watcher thread polls these dvars about every 0.5 s and applies changes, so `set ix_<id> <value>` in the console works live. This replaces AAE's `/d name value`.
- **Persistence (`ix\core\persist`).** With `fs_game`, settings are stored in `ix_settings.cfg` inside the mod folder, as human-editable `id = value` lines with `//` comments. Without `fs_game`, the dvars are the only store (session-only), and the menu says so.
- **Schema version.** A `settings_version` key works like AAE's `tfoption_master_ver` guard: when it changes, known keys are migrated and unknown or invalid ones fall back to defaults.
- **Presets.** Default, Classic, Enhanced, Testing, Developer, and Custom are defined as data (`id → value` maps).

### 4.3 Event bus (`ix\core\events`)

```text
subscribe(event, fn)        dispatches level thread [[fn]](args…)
```

Only real IW7 sources are used:

| Bus event | Source (verified) | Modes |
|-----------|-------------------|-------|
| `player_connect` | `level waittill("connected", p)` | MP, CP |
| `player_spawn` | `self waittill("spawned_player")` | MP, CP |
| `player_death` | `self waittill("death")` | MP, CP |
| `player_disconnect` | `self waittill("disconnect")` | all |
| `player_laststand` | `self waittill("last_stand")` | CP |
| `weapon_change` / `weapon_fired` / `reload` | `self waittill("weapon_change" / "weapon_fired" / "reload")` | MP, CP |
| `round_start` | `level waittill("regular_wave_starting")` and `"event_wave_starting"` | CP |
| `round_end` | `level waittill("spawn_wave_done")` | CP |
| `game_end` | `level waittill("game_ended")` | all |
| `chat` | `level waittill("say", p, msg)` (iw7-mod ≥ 1.0.3) | all |

One listener thread exists per source notify (per player where relevant), never one per subscriber.

### 4.4 Utilities (`ix\core\util`, `ix\core\log`, `ix\core\compat`)

- **util:** player iteration and validation (`isdefined`, `isalive`, `isplayer`, not bot), array helpers, string formatting (`va`), clamps, rounding, timing helpers.
- **log:** `ix\core\log::info/warn/error/debug(msg)`, which calls `print("[IX] …")` (iw7-mod console). Debug output is gated by setting `debug_log`.
- **compat:** the **only** place raw ids appear, each with its real name in a comment:
  - `god_off()` → `_meth_80A1`
  - `local_sound(a)` → `_meth_8242`
  - `third_person(b)` → `_meth_845E`
  - `fire_rate_on(pct)` → `_meth_85C1`; `fire_rate_off()` → `_meth_85C2`
  - `recoil_get()` → `_meth_85C0`; `recoil_off()` → `_meth_822C`
  - `spread_reset()` → `_meth_8263`; `has_perk(p)` → `_meth_8181`

  It also provides feature detection: `has_dvar(name)` is implemented as `getdvar(name) != ""`.

## 5. Menu design (`ix\ui\menu`)

- **Type:** a server-side **GSC HUD menu**, matching AAE's own approach and proven feasible in IW7 by an existing menu (S8).
- **Model:** pages hold items. Item kinds are `page` (submenu), `toggle` (bool setting), `slider` (int/float setting), `select` (enum setting), and `action` (function). Item labels and help text come from the setting registry, so the menu never hardcodes values.
- **Rendering:** a fixed set of HUD elements per player, **created once** on first open: background, title, a page breadcrumb, N visible rows (default 10), cursor bar, value column, help line, and footer. Opening, closing, and scrolling only change text, values, alpha, and positions. Elements are destroyed on disconnect.
- **State indication:** toggles show ON/OFF in colour; sliders show their value with min/max; unavailable features are greyed and labelled.
- **Controls** (AAE-style; avoids every CP action slot):

  | Action | Input |
  |--------|-------|
  | Open | ADS + Melee |
  | Scroll | ADS (up) / Fire (down) |
  | Select / toggle | Use |
  | Back / close | Melee |
  | Value change on sliders/selects | Frag (+) / Tactical (−) |

  Weapons and offhands are disabled while the menu is open. Controls are polled with `adsbuttonpressed`, `attackbuttonpressed`, `usebuttonpressed`, `meleebuttonpressed`, `fragbuttonpressed`, and `secondaryoffhandbuttonpressed`, all present in both compilers.
- **Access:** in MP, host only. In CP, every player can open the menu, but global options are host-only (setting `menu_global_access`).
- **Top-level tree:** Player, Movement, Weapons, Zombies (CP), HUD, Gameplay, Quality of Life, Visuals, Utilities, Debug (gated), Settings (presets, reset, save/load). The final tree is set after the BO3 menu analysis.

## 6. HUD design (`ix\ui\hud`)

- Each info element (round, zombies left, coordinates, speed, weapon/ammo, active modifiers, health) is a feature with its own toggle.
- Elements are created when enabled and destroyed when disabled; they are **never** recreated per frame.
- A single per-player update thread ticks every 0.1–0.25 s and skips disabled elements. Numbers use `setvalue`; text changes only when the value changes, which minimises unique strings (`KNOWN_LIMITATIONS.md` L12).

## 7. Mode separation rules

1. `ix\core\*`, `ix\ui\*`, `ix\player\*`, `ix\weapons\*`, and `ix\debug\*` must not reference `scripts\cp\…` or `scripts\mp\…`. They may use `scripts\engine\utility` and `scripts\common\…`, which exist in every mode.
2. `ix\zombies\*` is referenced **only** from `custom_scripts/cp/ix_main.gsc`.
3. `ix\mp\*` is referenced **only** from `custom_scripts/mp/ix_main.gsc`.
4. Mode modules plug into shared code through function pointers stored in `level.ix` (for example `level.ix.fn_get_round`), never through direct calls.

The build check verifies these rules by scanning far-call paths.

## 8. Naming conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Mod prefix | `ix` (checked: no collision with any IW7 token, stock field, or stock dvar) | |
| Level state | `level.ix.*` | `level.ix.settings` |
| Player state | `self.ix.*` | `self.ix.menu` |
| Dvars | `ix_<setting_id>` | `ix_movement_speed` |
| Notifies | `ix_<event>` | `ix_menu_closed` |
| Files | `snake_case.gsc`; one responsibility per file | `menu_tree.gsc` |
| Functions | `snake_case`; module-qualified calls | `custom_scripts\ix\core\config::get("x")` |

## 9. Adding a feature (extension guide, to be finalized in Phase 2)

1. Pick the module by category, or add a new file under `ix/<area>/`.
2. In that module's `register()`:
   - `config::register_setting(...)` for each option;
   - `features::register(...)` with enable/disable/apply functions;
   - add menu items to `menu_tree`.
3. Implement enable/disable so that disable fully **restores** the previous state.
4. Use only APIs listed in `IW_API_NOTES.md`; raw ids go through `compat`.
5. Run `tools/` checks; add rows to `FEATURE_STATUS.md` and `TESTING.md`.

## 10. Mapping from AAE's architecture (BO3) to Infinite Expansion (IW7)

| AAE v3.9.5 (from the decompiled package) | Infinite Expansion | Why it differs |
|------------------------------------------|--------------------|----------------|
| `autoexec` functions + `system::register(name, __init__, __main__, deps)` | One entry script per mode → `ix\core\bootstrap` calls each module's `register()` in a fixed order | IW7 has no `system::` manager; iw7-mod runs only `main()`/`init()` of auto-loaded files |
| `tfoption.gsc` reads ~80 `tfoption_*` modvars **once** at match start | `ix\core\config`: flat `ix_*` keys, applied at start **and live** | Same flat-key model; live apply because the menu is in-game |
| LUI save data + `exec AAECustomMutations` + `tfoption_master_ver` reset | `ix\core\persist`: `ix_settings.cfg` via GSC file I/O + `settings_version` | GSC can write files in IW7 (with `fs_game`); BO3 GSC could not |
| LUI "Custom Mutations" lobby menus (`tfoptions*.lua`) | GSC HUD menu, Settings pages | A LUI front-end would be client code every player needs (L22) |
| `_clientid.gsc` dev menu (`elmg_cheats`, host verification, Stance+Reload) | Debug pages gated by `ix_dev` + host + confirmation | Same idea; never reachable by accident |
| `callback::on_connect/on_spawned`, `zm::register_*_callback`, `level._custom_powerups[..].grab_powerup`, `level.round_wait_func` | `ix\core\events` over IW7 notifies; wrappers around `level.callbackplayerdamage` / `level.agent_funcs[..]`; `level.movemodefunc`; `replacefunc` | Use the hooks IW7 actually has |
| Patched **copies** of stock scripts (e.g. `zombie_utility`) | `replacefunc` detours of single functions | No redistribution of modified stock code; smaller surface |
| `chatnotify.gsc` (`chat` notify, `/bal`, `/dep`, …) | Chat-command router on iw7-mod's `say` notify | Equivalent mechanism |
| Client sys-state "set client dvar" bridge; `luinotifyevent` score popups | `setclientdvar(s)`; GSC HUD text | Native in IW7 |
| 48 custom CSV tables, 1,678 localized strings | Inline GSC data; plain `settext` labels | New tables/strings need a fastfile (L21) |
| ~800 ported assets, sound banks, movies | Not ported (optional future asset phase, x64-zt) | Script-only scope |
