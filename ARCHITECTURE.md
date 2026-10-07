# ARCHITECTURE.md — Infinite Expansion

> **Status: Phases 1–3 implemented** (Phase 1: entry scripts, bootstrap, logging, compat, `tools/check.py`; Phase 2: event bus, settings, saving, feature manager, chat commands, utilities — confirmed in a real match; Phase 3: the in-game menu — compiled and checked, in-game test pending). Sections 4 and 5 describe what exists; presets (§4.2) and the info HUD (§6) remain plans for later phases. This design follows from the verified IW7 facts in `IW_API_NOTES.md` and the AAE v3.9.5 analysis (`PROJECT_ANALYSIS.md` §1). Section 10 maps AAE's components onto this design.

## 1. Constraints that shape the design

| Constraint (verified) | Design consequence |
|-----------------------|--------------------|
| iw7-mod auto-loads only top-level `.gsc` files in `custom_scripts/`, `custom_scripts/<mode>/`, and `custom_scripts/cp_mp/` | One small **entry script** in `custom_scripts/cp/` (zombies only); every module lives in `custom_scripts/ix/…`, which is never auto-loaded |
| Far calls to other custom files compile to `OP_ScriptFarFunctionCall custom_scripts/ix/<area>/<file> <func>` (compiled and disassembled in Phase 0) | Modules call each other by explicit path (`custom_scripts\ix\core\util::fn()`); no `#include` chains |
| `init()` runs before the map's `main()` | Bootstrap waits for the level before wrapping map-owned callbacks |
| 1 MiB custom bytecode budget, fatal if exceeded | Keep modules small; `tools/check.py` reports the total (limit 512 KiB) |
| An unresolved reference in any loaded script is a `script link error` that drops the match (L23) | Every script must pass `tools/check.py` (compile, calls) before a release |
| v1.1.0 compiler mislabels/lacks many method names | Every raw `_meth_` / `_func_` id lives in **one** module (`ix\core\compat`) |
| File I/O only with `fs_game` | Settings are saved as archived dvars (`seta`, through iw7-mod's `executecommand`), which needs no file access |
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
│               │   ├── util.gsc             player/array/string/number helpers            (Phases 1–2)
│               │   ├── events.gsc           event bus over real IW7 notifies               (Phase 2)
│               │   ├── config.gsc           settings: types, ranges, get/set/reset, console (Phase 2)
│               │   ├── persist.gsc          saving settings (seta) + layout version        (Phase 2)
│               │   ├── features.gsc         on/off features, requirements, hooks           (Phase 2)
│               │   └── chat.gsc             !ix chat commands                              (Phase 2)
│               ├── ui/                      ≙ /scripts/ui/
│               │   ├── menu.gsc             menu engine (pages, items, rendering, input)   (Phase 3)
│               │   ├── menu_tree.gsc        menu pages (data only)                       (Phase 3)
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
│                                            launcher: IXLauncher.cs + ix-launcher.ico, compiled on the player's PC
│                                            into <game>\Infinite Expansion.exe (tested with a stand-in compiler);
│                                            picture pack: IXPictures.Core.ps1 (x64-zt runs, build input, install;
│                                            run by the setup after installing, and by IXPictures.ps1, the
│                                            console version; tested with a stand-in for x64-zt)
├── tools/                                   offline verification (Linux)
└── *.md                                     project documentation
```

Phase 1 also created one placeholder per feature area (`ui/ui.gsc`, `player/player.gsc`, `weapons/weapons.gsc`, `zombies/zombies.gsc`, `debug/debug.gsc`). Each only registers its name, so the init log shows the load order.

`/assets/` from the original brief maps to `mods/infinite_expansion/ui_scripts/` (client Lua; the CHARACTER button in the zombies lobby since Phase 1.5) and an optional `mod.ff` (x64-zt, deferred).

## 3. Initialization flow

Implemented in Phases 1 and 2 unless marked *(later)*.

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
        ├─ core setup():  log → compat (client feature flags) → events → config
        │     → persist (saved-settings layout check) → features → chat; setting debug_log
        ├─ modules' register(), in entry-script order: player, weapons, zombies, debug, ui
        │     (each adds its settings and features; a setting takes its saved ix_<id> value)
        ├─ config::start(): console watcher thread (ix_<id> dvars, every 0.5 s)
        ├─ log "init <version> map=… modules=…", "client fs_game=… omnimovement=…",
        │     "settings: N (M changed from the default); features: K; chat: !ix"
        ├─ thread wait_until_ready: first "connected" + waittillframeend
        │     → level.ix.ready = 1, notify "ix_ready"
        │     → features: global features that are on start (on_enable)
        │     (later) wrap map-owned callbacks
        ├─ thread watch_players: every "connected"
        │     → self.ix = { spawn_count }, notify "ix_player_connected"
        │     → spawn watcher thread: notify "ix_player_spawned" on every "spawned_player"
        │     → features: on_player( 1 ) for each feature that is on, on every spawn
        │     (later) menu input watcher
        └─ thread watch_shutdown: "game_ended" → notify "ix_shutdown"
```

**Conventions** (enforced by `tools/check.py` where marked ✓):

- Only entry scripts define `init()` or `main()`, because iw7-mod runs those in every file it auto-loads ✓. Feature modules expose `register()`; core files expose `setup()`.
- `register()` and `setup()` run synchronously and must not wait. Waiting work runs in its own thread.
- Modules take connect, spawn, ready, and shutdown from the `ix_*` notifies above, or better from the event bus (§4.3) built on them, instead of waiting on `connected` / `spawned_player` themselves, so that plumbing lives in one place.
- Modules read options with `config::get(id)`, never with `getdvar`, so that every option has one type, one range and one default.

**Shutdown.**
- On `game_ended`, threads end through `level endon("game_ended")`.
- On player `disconnect`, per-player HUD elements are destroyed and threads end with `self endon("disconnect")`.
- Global dvars the mod changes (for example `bg_gravity`) are restored to the values captured at init whenever their feature is disabled, and again on `game_ended`.
  - This is **best effort**: an abrupt map change can end scripts before the restore runs. Dvars are process-wide, so such a value persists until the mod's next load re-applies or resets it.
  - Changed global dvars are therefore listed in the menu's *Active modifiers* view.

## 4. Core systems (interfaces)

Implemented in Phase 2. Modules call them by path, for example `custom_scripts\ix\core\config::get( "player_card_x" )`; below, `config::` stands for that path.

### 4.1 Feature manager (`ix\core\features`)

A feature is something that can be switched on and off while playing. It is backed by an on/off setting with the same id, so the console, the chat commands and later the menu switch it the same way.

```text
feature = features::add(id, category, label, help, default_on)   in a module's register()
feature.on_enable  = ::fn        global; runs once when switched on (after ix_ready)
feature.on_disable = ::fn        global; must undo everything on_enable did
feature.on_player  = ::fn        self = player, argument 1/0: on every player when
                                 switched, and on each spawn while on
feature.requires[feature.requires.size] = "dvar:<name>" | "fs_game"
features::is_enabled(id) / enable(id, source) / disable(id, source) / toggle(id, source)
```

- **Duplicate-registration guard.** Adding the same `id` twice is logged and ignored (the first stays).
- **Requirements.** `"dvar:<name>"` needs a dvar the client has (`compat::has_dvar`); `"fs_game"` needs the mod loaded from the Mods menu. A feature with a missing requirement stays off, switching it on is refused and logged, and `is_enabled` is 0.
- **Timing.** Nothing is applied before `ix_ready`, because the stock maps set their callbacks up first. A switch before then only changes the setting.
- `player_card` (`ui\player_card.gsc`) is the first feature: `on_player(0)` hides the card at once.

### 4.2 Configuration manager (`ix\core\config`)

```text
config::add_bool(id, default, label, help, on_change)
config::add_int(id, default, min, max, label, help, on_change)
config::add_float(id, default, min, max, label, help, on_change)
config::add_enum(id, default, "word1 word2 …", label, help, on_change)
config::get(id) / set(id, value, source) / reset_default(id, source) / reset_all(source)
config::find(id) / exists(id) / changed_count() / to_text(setting, value) / describe_range(setting)
```

- **Types:** `bool` (1/0; also true/false, on/off, yes/no), `int`, `float`, `enum` (lower-case words).
- **Validation.** A value that means nothing for the type is refused (`set` returns 0); numbers are clamped to `[min, max]`.
- **Source of truth at runtime:** `level.ix.config.settings[id]` (`.value`, `.text`, `.default_value`, `.type`, range, `.label`, `.help`); `level.ix.config.order` keeps registration order.
- **Live console overrides.** Every setting is mirrored to dvar `ix_<id>`. A watcher thread polls these dvars every 0.5 s and applies changes, so `set ix_<id> <value>` in the console works live; an invalid value is logged and the dvar put back, and a cleared dvar means the default. This replaces AAE's `/d name value`.
- **Change notification.** Each change logs `setting <id> = <value> (<source>)`, notifies `level "ix_setting_changed", id`, and runs `level thread [[on_change]](value, old_value, id)`. The value found at registration does not count as a change.
- **Persistence (`ix\core\persist`).** Every change is saved as an archived dvar: `executecommand("seta ix_<id> <value>")`, the way the CHARACTER menu saves `ix_character`. iw7-mod keeps archived dvars in the host's config, so the next game starts with them, and registration reads them back. This needs neither `fs_game` nor file access, so it works in the install friends can join (L9, L30). Only values made of letters, digits, `_`, `.` and `-` (at most 64) are ever written, so no value can add a console command.
- **Layout version.** `ix_settings_version` (now 1) records which layout of settings was saved; `persist::migrate(from)` converts old values once when a later version renames or changes a setting. An invalid saved value is replaced by the default at registration, and saved again.
- **Presets** *(later)*: Default, Classic, Enhanced, Testing, Developer and Custom as data (`id → value` maps), applied with `set`.

### 4.3 Event bus (`ix\core\events`)

```text
events::subscribe(event, fn)   level events:  level thread [[fn]](arg)
                               player events: level thread [[fn]](player, arg)
```

Only real IW7 sources are used:

| Bus event | Source (verified) | Argument |
|-----------|-------------------|----------|
| `player_connect` | level `ix_player_connected` (bootstrap, from `connected`) | — |
| `player_spawn` | level `ix_player_spawned` (bootstrap, from `spawned_player`) | — |
| `player_death` | player `death` | — |
| `player_disconnect` | player `disconnect` | — |
| `player_laststand` | player `last_stand` (`scripts\cp\cp_laststand`) | weapon |
| `weapon_change` / `weapon_fired` / `reload` | player `weapon_change` / `weapon_fired` / `reload` | weapon (`weapon_change`) |
| `round_start` | level `regular_wave_starting` and `event_wave_starting` | `level.wave_num` |
| `round_end` | level `spawn_wave_done` | `level.wave_num` |
| `game_end` | level `game_ended` | — |
| `chat` | level `say`, player, message (iw7-mod `logprint.cpp`; in zombies team chat arrives as `say` too) | message |

One listener thread exists per source notify (per player for player events), started by the first subscriber, never one per subscriber. A `player_disconnect` handler gets the player as it leaves.

### 4.4 Utilities (`ix\core\util`, `ix\core\log`, `ix\core\compat`)

- **util:** `is_valid_player`, `is_human`, `dvar_string`, `join(items, separator)`, `parse_bool(text)`, `is_number(text, allow_fraction)`, `array_contains(items, value)`, `starts_with(text, prefix)`. Single characters are taken with `getsubstr(text, i, i + 1)`, as the stock scripts do.
- **log:** `ix\core\log::info/warn/error/debug(msg)`, which calls `print("[IX] LEVEL: …")` (iw7-mod console) and keeps the last 32 lines in `level.ix.log` (`log::recent()`). Debug output is gated by the setting `debug_log` (dvar `ix_debug_log`).
- **compat:** the **only** place raw ids appear, each with its real name in a comment:
  - `god_off()` → `_meth_80A1`
  - `local_sound(a)` → `_meth_8242`
  - `third_person(b)` → `_meth_845E`
  - `fire_rate_on(pct)` → `_meth_85C1`; `fire_rate_off()` → `_meth_85C2`
  - `recoil_get()` → `_meth_85C0`; `recoil_off()` → `_meth_822C`
  - `spread_reset()` → `_meth_8263`; `has_perk(p)` → `_meth_8181`

  It also provides feature detection: `has_dvar(name)` is implemented as `getdvar(name) != ""`. `setup()` stores the results in `level.ix.client` (`has_fs_game`, `has_omnimovement`, `has_sprint_unlimited`, `has_air_control`), and `describe()` formats them for the init log.

### 4.5 Chat commands (`ix\core\chat`)

Typed in the game's chat; replies go only to the player who typed, with iw7-mod's `tell()`.

| Command | Who | Does |
|---------|-----|------|
| `!ix` | everyone | the list of commands |
| `!ix list [word]` | everyone | settings and their values, optionally only ids containing `word` |
| `!ix get <setting>` | everyone | value, default, valid values, help |
| `!ix set <setting> <value>` | host | changes a setting (through `config::set`, so the range applies) |
| `!ix on <setting>` / `!ix off <setting>` | host | switches an on/off setting |
| `!ix reset <setting>` / `!ix reset all` | host | back to the default |
| `!ix version` | everyone | the mod's version |

Settings apply to the whole match, so only the host (`player ishost()`) may change them. A reply quotes typed text only when it is a plain word, because `tell()` sends the text inside a quoted server command.

Modules add commands with `chat::add_command(name, fn, usage)`: `!ix <name> ...` runs `player thread [[fn]](words)`, and `!ix` lists them. The menu adds `!ix menu`.

## 5. Menu design (`ix\ui\menu`) — implemented in Phase 3

- **Type:** a server-side **GSC HUD menu**, matching AAE's own approach and proven feasible in IW7 by an existing menu (S8).
- **Model:** pages hold rows (`menu_tree.gsc`, data only, built on the first opening when every module has registered):

  ```text
  add_page( id, title, parent )                    a page, linked from its parent
  add_setting( page, setting, step )               a setting row; Frag / Tactical change numbers by step
  add_action( page, label, help, fn, confirm, host_only )   confirm: Use twice
  add_info( page, label, help, fn )                a read-out: fn returns a number or a short word
  ```

  A setting row takes its label, help, range and value from the setting registry (§4.2), so the menu never hardcodes them; a row for a missing setting is skipped and a page without rows is left out.
- **Rendering:** a fixed set of HUD elements per player, **created once** on first open: panel, accent edge, title, breadcrumb, 10 rows (label and value), cursor bar, three help lines (the row's help and range, word-wrapped), and a two-line footer with the controls. Opening, closing, and scrolling only change text, values, alpha, and positions; numbers are shown with `setvalue`, so they never become new strings (L12). The panel is right of the screen's centre (`horzalign "center"`, x 96–320, y 96–342).
- **State indication:** on/off settings show ON (green) / OFF (pink); numbers and words show their value, with the range in the help lines; a feature whose requirements are missing shows N/A in grey; values the player may not change are grey.
- **Controls** (AAE-style; avoids every CP action slot), polled every 0.05 s with `adsbuttonpressed`, `attackbuttonpressed`, `usebuttonpressed`, `meleebuttonpressed`, `fragbuttonpressed` and `secondaryoffhandbuttonpressed` (all in both compilers), the way a working IW7 zombies menu reads them (IW_API_NOTES §8):

  | Action | Input |
  |--------|-------|
  | Open | ADS + Melee (both released before the menu reacts), or `!ix menu` in chat |
  | Up / down | ADS / Fire; held: repeats after 0.35 s, then every 0.1 s |
  | Open a page, switch, step a word, run an action | Use |
  | Change a value | Frag (more / next / on) / Tactical (less / previous / off) |
  | Back / close | Melee |

  While it is open, weapons, grenades, melee and Use are off through the stock counters `scripts\engine\utility::allow_weapon`, `allow_offhand_weapons`, `allow_melee` and `allow_usability`, once each way, so closing never undoes what the game itself turned off. It closes on last stand, death, the match's end, and when the `menu` feature is switched off; it cannot open while down, in the afterlife arcade or before `ix_ready`.
- **Access:** every player can open the menu; settings and host-only actions change only for the host, unless the setting `menu_access` is `everyone`.
- **Tree (Phase 3):** Characters, HUD, Menu, Settings (changed count, *Reset every setting* with confirmation, version), Debug, Close. Later phases add Player, Movement, Weapons, Zombies, Quality of Life, Visuals, Utilities and presets.

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
| Level state | `level.ix.*` | `level.ix.config.settings` |
| Player state | `self.ix.*` | `self.ix.menu` |
| Dvars | `ix_<setting_id>` | `ix_movement_speed` |
| Notifies | `ix_<event>` | `ix_menu_closed` |
| Files | `snake_case.gsc`; one responsibility per file | `menu_tree.gsc` |
| Functions | `snake_case`; module-qualified calls | `custom_scripts\ix\core\config::get("x")` |
| Entry points | `init()` in entry scripts only; `register()` in feature modules; `setup()` in core files | `custom_scripts\ix\ui\ui::register` |

## 9. Adding a feature (extension guide)

1. Pick the module by category, or add a new file under `ix/<area>/` and its `register` to the entry script's module list.
2. In that module's `register()`:
   - `config::add_bool/add_int/add_float/add_enum(...)` for each option; read them with `config::get(id)`;
   - `features::add(...)` for each part that can be switched on and off, with `on_enable`/`on_disable` (global) or `on_player` (per player) and any `requires`;
   - `events::subscribe(...)` for what it reacts to;
   - rows for its settings in `ix/ui/menu_tree.gsc` (`add_setting`, with a step for numbers), on an existing page or a new `add_page`;
   - a chat command, if useful: `chat::add_command(name, fn, usage)` (the menu adds `!ix menu`).
3. Implement `on_disable` / `on_player(0)` so that switching off fully **restores** the previous state.
4. Use only APIs listed in `IW_API_NOTES.md`; raw ids go through `compat`.
5. Run `python3 tools/check.py` until it passes; add rows to `FEATURE_STATUS.md` and `TESTING.md`.

```text
register()
{
    feature = custom_scripts\ix\core\features::add( "player_card", "hud", "Player card", "The card in the bottom-right corner naming your character.", 1 );
    feature.on_player = ::apply_player_card;
    custom_scripts\ix\core\config::add_int( "player_card_x", 16, 0, 600, "Player card: right margin", "Distance from the right edge of a 640 x 480 screen.", undefined );
    custom_scripts\ix\core\events::subscribe( "player_spawn", ::on_spawn );
}
```

## 10. Mapping from AAE's architecture (BO3) to Infinite Expansion (IW7)

| AAE v3.9.5 (from the decompiled package) | Infinite Expansion | Why it differs |
|------------------------------------------|--------------------|----------------|
| `autoexec` functions + `system::register(name, __init__, __main__, deps)` | One entry script (zombies) → `ix\core\bootstrap` calls each module's `register()` in a fixed order | IW7 has no `system::` manager; iw7-mod runs only `main()`/`init()` of auto-loaded files |
| `tfoption.gsc` reads ~80 `tfoption_*` modvars **once** at match start | `ix\core\config`: flat `ix_*` keys, applied at start **and live** | Same flat-key model; live apply because the menu is in-game |
| LUI save data + `exec AAECustomMutations` + `tfoption_master_ver` reset | `ix\core\persist`: archived dvars (`seta ix_<id>`, via iw7-mod's `executecommand`) + `ix_settings_version` | GSC file I/O needs `fs_game`, which the joinable install has none of (L30); the host's config needs nothing |
| LUI "Custom Mutations" lobby menus (`tfoptions*.lua`) | GSC HUD menu, Settings pages | A LUI front-end would be client code every player needs (L22) |
| `_clientid.gsc` dev menu (`elmg_cheats`, host verification, Stance+Reload) | Debug pages gated by `ix_dev` + host + confirmation | Same idea; never reachable by accident |
| `callback::on_connect/on_spawned`, `zm::register_*_callback`, `level._custom_powerups[..].grab_powerup`, `level.round_wait_func` | `ix\core\events` over IW7 notifies; wrappers around `level.callbackplayerdamage` / `level.agent_funcs[..]`; `level.movemodefunc`; `replacefunc` | Use the hooks IW7 actually has |
| Patched **copies** of stock scripts (e.g. `zombie_utility`) | `replacefunc` detours of single functions | No redistribution of modified stock code; smaller surface |
| `chatnotify.gsc` (`chat` notify, `/bal`, `/dep`, …) | `ix\core\chat`: `!ix` commands on iw7-mod's `say` notify, replies with `tell()` | Equivalent mechanism |
| Client sys-state "set client dvar" bridge; `luinotifyevent` score popups | `setclientdvar(s)`; GSC HUD text | Native in IW7 |
| 48 custom CSV tables, 1,678 localized strings | Inline GSC data; plain `settext` labels | New tables/strings need a fastfile (L21) |
| ~800 ported assets, sound banks, movies | Not ported (optional future asset phase, x64-zt) | Script-only scope |
