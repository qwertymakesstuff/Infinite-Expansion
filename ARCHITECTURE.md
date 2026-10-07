# ARCHITECTURE.md — Infinite Expansion

> **Status: Phase 1 implemented** (entry scripts, bootstrap, logging, compat, first utilities, `tools/check.py`). Sections 4–6 remain the plan for Phases 2–8. This design follows from the verified IW7 facts in `IW_API_NOTES.md` and the AAE v3.9.5 analysis (`PROJECT_ANALYSIS.md` §1). Section 10 maps AAE's components onto this design.

## 1. Constraints that shape the design

| Constraint (verified) | Design consequence |
|-----------------------|--------------------|
| iw7-mod auto-loads only top-level `.gsc` files in `custom_scripts/`, `custom_scripts/<mode>/`, and `custom_scripts/cp_mp/` | One small **entry script** in `custom_scripts/cp/` (zombies only); every module lives in `custom_scripts/ix/…`, which is never auto-loaded |
| Far calls to other custom files compile to `OP_ScriptFarFunctionCall custom_scripts/ix/<area>/<file> <func>` (compiled and disassembled in Phase 0) | Modules call each other by explicit path (`custom_scripts\ix\core\util::fn()`); no `#include` chains |
| `init()` runs before the map's `main()` | Bootstrap waits for the level before wrapping map-owned callbacks |
| 1 MiB custom bytecode budget, fatal if exceeded | Keep modules small; `tools/check.py` reports the total (limit 512 KiB) |
| An unresolved reference in any loaded script is a `script link error` that drops the match (L23) | Every script must pass `tools/check.py` (compile, calls) before a release |
| v1.1.0 compiler mislabels/lacks many method names | Every raw `_meth_` / `_func_` id lives in **one** module (`ix\core\compat`) |
| File I/O only with `fs_game` | Persistence layer with a dvar-only fallback |
| Players cannot join a host whose `fs_game` is set unless the mod ships a `mod.ff` (L30) | Installed into `<game>/iw7-mod/`, without `fs_game`; settings must work from dvars alone |
| Another player's menu choice reaches the host's match only through that player's stats (L29) | Choices made in the frontend apply when the stock code asks for the player's character (`replacefunc` of `zombies_loadout::get_player_character_num`, L36), never mid-match |
| A zombies match links only the stock scripts its map and the gametype reference; 126 are common to all five maps | Stock calls target only those; map-specific code is reached through the pointers maps assign, never by path (§7) |
| Server-side GSC; per-player HUD elements | Per-player state lives on the player entity (`self.ix`) |

## 2. Layout

`mods/infinite_expansion/` holds what a player installs: its `custom_scripts/` and `ui_scripts/` go into `<Infinite Warfare>/iw7-mod/` (README). Copying the whole folder into `<Infinite Warfare>/mods/` also works, for solo play only (L30).

```text
Infinite-Expansion/                          (repository)
├── mods/
│   └── infinite_expansion/                  contents → <Infinite Warfare>/iw7-mod/
│       ├── desc.txt                         Mods-menu description (solo install only)     (Phase 1)
│       ├── ui_scripts/InfiniteExpansion/    client Lua: lobby CHARACTER button + list     (Phase 1.5)
│       └── custom_scripts/
│           ├── cp/ix_main.gsc               ENTRY (zombies only)  — auto-loaded          (Phase 1)
│           └── ix/                          MODULES               — loaded by reference only
│               ├── core/                    ≙ requested /scripts/core/
│               │   ├── bootstrap.gsc        init order, duplicate-init guard, lifecycle   (Phase 1)
│               │   ├── compat.gsc           raw-id wrappers + client feature detection    (Phase 1)
│               │   ├── log.gsc              console logging, levels, ring buffer          (Phase 1)
│               │   ├── util.gsc             player/entity/array/string/timing helpers     (Phase 1: first helpers)
│               │   ├── events.gsc           event bus over real IW7 notifies
│               │   ├── features.gsc         feature registry (register/enable/disable)
│               │   ├── config.gsc           setting registry, get/set/reset, presets
│               │   └── persist.gsc          file I/O (fs_game) with dvar fallback
│               ├── ui/                      ≙ /scripts/ui/
│               │   ├── menu.gsc             menu engine (pages, items, rendering, input)
│               │   ├── menu_tree.gsc        menu definition (data only)
│               │   ├── hud.gsc              info HUD (create-once/update)
│               │   └── player_card.gsc      bottom-right character card              (Phase 1.5)
│               ├── player/                  ≙ /scripts/player/
│               │   ├── player.gsc           health, god mode, third person, utilities
│               │   ├── character.gsc        character selection, specials, per-map cast (Phase 1.5)
│               │   └── movement.gsc         speed, gravity, sprint/slide/mantle options
│               ├── weapons/                 ≙ /scripts/weapons/
│               │   └── weapons.gsc          ammo, fire-rate, recoil, spread, give/take, info
│               ├── zombies/                 ≙ /scripts/zombies/
│               │   ├── zombies.gsc          speed, health, counts, spawn tuning
│               │   └── rounds.gsc           round utilities and round hooks
│               └── debug/                   ≙ /scripts/debug/   (gated)
│                   └── debug.gsc            inspector, trace info, perf/log read-outs
├── Infinite Expansion Setup.cmd             double-click: opens the setup window (Windows)
├── Build Character Pictures.cmd             double-click: builds the picture pack again (the setup builds it once)
├── installer/                               one-click setup: IXSetup.ps1 (WPF window), IXSetup.Core.ps1
│                                            (install logic, tested on Linux), IXSetup.xaml (layout + art), ix.ico;
│                                            picture pack: IXPictures.Core.ps1 (x64-zt runs, build input, install;
│                                            run by the setup after installing, and by IXPictures.ps1, the
│                                            console version; tested with a stand-in for x64-zt)
├── tools/                                   offline verification (Linux)
└── *.md                                     project documentation
```

Phase 1 also created one placeholder per feature area (`ui/ui.gsc`, `player/player.gsc`, `weapons/weapons.gsc`, `zombies/zombies.gsc`, `debug/debug.gsc`). Each only registers its name, so the init log shows the load order.

`/assets/` from the original brief maps to `mods/infinite_expansion/ui_scripts/` (client Lua; the CHARACTER button in the zombies lobby since Phase 1.5) and an optional `mod.ff` (x64-zt, deferred).

## 3. Initialization flow

Implemented in Phase 1 unless marked *(Phase 2+)*.

```text
iw7-mod loads custom_scripts/cp/ix_main.gsc   (zombies only)
│
├─ main()     [G_LoadStructs — before stock level scripts]
│   └─ (not defined: the mod's replacefunc calls run from init(), before any spawn)
│
└─ init()     [Scr_LoadLevel — before the map's main()]
    └─ ix\core\bootstrap::start(modules())
        ├─ guard: level.ix already exists → log a warning, return      (no double init)
        ├─ master switch: dvar ix_enabled "0" → log, return           (mod fully off)
        ├─ level.ix = { version, map, ready = 0, modules = [] }; dvar ix_version
        ├─ core setup():  log → compat (client feature flags)
        ├─ (Phase 2+) events → features → config: register settings, load file or dvars
        ├─ modules' register(), in entry-script order: player, weapons, zombies, debug, ui
        ├─ log "init <version> map=… modules=…" and "client fs_game=… omnimovement=…"
        ├─ thread wait_until_ready: first "connected" + waittillframeend
        │     → level.ix.ready = 1, notify "ix_ready"
        │     (Phase 2+) wrap map-owned callbacks, apply enabled global features
        ├─ thread watch_players: every "connected"
        │     → self.ix = { spawn_count }, notify "ix_player_connected"
        │     → spawn watcher thread: notify "ix_player_spawned" on every "spawned_player"
        │     (Phase 2+) menu input watcher; re-apply per-player features on spawn
        └─ thread watch_shutdown: "game_ended" → notify "ix_shutdown"
```

**Conventions** (enforced by `tools/check.py` where marked ✓):

- Only entry scripts define `init()` or `main()`, because iw7-mod runs those in every file it auto-loads ✓. Feature modules expose `register()`; core files expose `setup()`.
- `register()` and `setup()` run synchronously and must not wait. Waiting work runs in its own thread.
- Modules take connect, spawn, ready, and shutdown from the `ix_*` notifies above instead of waiting on `connected` / `spawned_player` themselves, so that plumbing lives in one place. The Phase 2 event bus (§4.3) builds on it.

**Shutdown.**
- On `game_ended`, threads end through `level endon("game_ended")`.
- On player `disconnect`, per-player HUD elements are destroyed and threads end with `self endon("disconnect")`.
- Global dvars the mod changes (for example `bg_gravity`) are restored to the values captured at init whenever their feature is disabled, and again on `game_ended`.
  - This is **best effort**: an abrupt map change can end scripts before the restore runs. Dvars are process-wide, so such a value persists until the mod's next load re-applies or resets it.
  - Changed global dvars are therefore listed in the menu's *Active modifiers* view.

## 4. Core systems (interfaces)

### 4.1 Feature manager (`ix\core\features`)

```text
register(id, category, scope, fn_enable, fn_disable, fn_player_apply, requires[])
enable(id) / disable(id) / is_enabled(id) / toggle(id)
```

- **Duplicate-registration guard.** Registering the same `id` twice is logged and ignored.
- **Compatibility gating.** Every entry in `requires` (such as `"dvar:bg_omnimovement"` or `"fs_game"`) must be satisfied, otherwise the feature is shown as *unavailable* and cannot be enabled.
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

| Bus event | Source (verified) |
|-----------|-------------------|
| `player_connect` | `level waittill("connected", p)` (Phase 1: `ix_player_connected`) |
| `player_spawn` | `self waittill("spawned_player")` (Phase 1: `ix_player_spawned`) |
| `player_death` | `self waittill("death")` |
| `player_disconnect` | `self waittill("disconnect")` |
| `player_laststand` | `self waittill("last_stand")` |
| `weapon_change` / `weapon_fired` / `reload` | `self waittill("weapon_change" / "weapon_fired" / "reload")` |
| `round_start` | `level waittill("regular_wave_starting")` and `"event_wave_starting"` |
| `round_end` | `level waittill("spawn_wave_done")` |
| `game_end` | `level waittill("game_ended")` |
| `chat` | `level waittill("say", p, msg)` (iw7-mod ≥ 1.0.3) |

One listener thread exists per source notify (per player where relevant), never one per subscriber.

### 4.4 Utilities (`ix\core\util`, `ix\core\log`, `ix\core\compat`)

- **util:** player iteration and validation (`isdefined`, `isalive`, `isplayer`, not bot), array helpers, string formatting (`va`), clamps, rounding, timing helpers.
- **log:** `ix\core\log::info/warn/error/debug(msg)`, which calls `print("[IX] LEVEL: …")` (iw7-mod console) and keeps the last 32 lines in `level.ix.log` (`log::recent()`). Debug output is gated by dvar `ix_debug_log` (the future setting `debug_log`).
- **compat:** the **only** place raw ids appear, each with its real name in a comment:
  - `god_off()` → `_meth_80A1`
  - `local_sound(a)` → `_meth_8242`
  - `third_person(b)` → `_meth_845E`
  - `fire_rate_on(pct)` → `_meth_85C1`; `fire_rate_off()` → `_meth_85C2`
  - `recoil_get()` → `_meth_85C0`; `recoil_off()` → `_meth_822C`
  - `spread_reset()` → `_meth_8263`; `has_perk(p)` → `_meth_8181`

  It also provides feature detection: `has_dvar(name)` is implemented as `getdvar(name) != ""`. `setup()` stores the results in `level.ix.client` (`has_fs_game`, `has_omnimovement`, `has_sprint_unlimited`, `has_air_control`), and `describe()` formats them for the init log.

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
- **Access:** every player in the match can open the menu, but global options are host-only (setting `menu_global_access`).
- **Top-level tree:** Player, Movement, Weapons, Zombies, HUD, Gameplay, Quality of Life, Visuals, Utilities, Debug (gated), Settings (presets, reset, save/load). The final tree is set after the BO3 menu analysis.

## 6. HUD design (`ix\ui\hud`)

- Each info element (round, zombies left, coordinates, speed, weapon/ammo, active modifiers, health) is a feature with its own toggle.
- Elements are created when enabled and destroyed when disabled; they are **never** recreated per frame.
- A single per-player update thread ticks every 0.1–0.25 s and skips disabled elements. Numbers use `setvalue`; text changes only when the value changes, which minimises unique strings (`KNOWN_LIMITATIONS.md` L12).

## 7. Scope rules (zombies only)

Multiplayer support was dropped on 2026-10-06; the mod targets the zombies mode only.

1. The only entry script is `custom_scripts/cp/ix_main.gsc`. iw7-mod loads `custom_scripts/cp/` in zombies only, so the mod never runs in multiplayer or the campaign. Modules live in `custom_scripts/ix/<area>/`.
2. Every module may use the zombies APIs (`scripts\cp\…`); the `ix/<area>/` folders only organise the code.
3. A far call into a stock script must target a script that **every** zombies map loads. A match loads the map's level script (`scripts\cp\maps\<map>\<map>`) and the gametype script (`scripts\cp\gametypes\zombie`) and links everything they reference; a call into anything else is a `script link error` that ends the match (L23). 126 stock scripts are common to all five maps, including some under `scripts\mp\` (`mp_agent`, the zombie agent scripts).
4. Map-specific behaviour is reached through the pointers each map assigns (`level.callbackplayerdamage`, `level.agent_funcs[…]`, `level.movemodefunc[…]`), never by a far call into `scripts\cp\maps\…`.

`tools/check.py` verifies rules 1 and 3 (`layout`, `calls`). It computes each map's link closure from the decompiled dump, rejects scripts in other locations, and warns about modules the entry script never reaches.

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
| Entry points | `init()` in entry scripts only; `register()` in feature modules; `setup()` in core files | `custom_scripts\ix\ui\ui::register` |

## 9. Adding a feature (extension guide, to be finalized in Phase 2)

1. Pick the module by category, or add a new file under `ix/<area>/`.
2. In that module's `register()`:
   - `config::register_setting(...)` for each option;
   - `features::register(...)` with enable/disable/apply functions;
   - add menu items to `menu_tree`.
3. Implement enable/disable so that disable fully **restores** the previous state.
4. Use only APIs listed in `IW_API_NOTES.md`; raw ids go through `compat`.
5. Run `python3 tools/check.py` until it passes; add rows to `FEATURE_STATUS.md` and `TESTING.md`.

## 10. Mapping from AAE's architecture (BO3) to Infinite Expansion (IW7)

| AAE v3.9.5 (from the decompiled package) | Infinite Expansion | Why it differs |
|------------------------------------------|--------------------|----------------|
| `autoexec` functions + `system::register(name, __init__, __main__, deps)` | One entry script (zombies) → `ix\core\bootstrap` calls each module's `register()` in a fixed order | IW7 has no `system::` manager; iw7-mod runs only `main()`/`init()` of auto-loaded files |
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
