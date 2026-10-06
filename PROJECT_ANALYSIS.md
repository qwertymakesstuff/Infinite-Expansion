# PROJECT_ANALYSIS.md — Phase 0 Forensics

**Project:** Infinite Expansion: an enhancement framework for *Call of Duty: Infinite Warfare*, inspired by *All-Around Enhancement* (BO3)
**Phase:** 0, Project Forensics
**Date:** 2026-10-06

> **Phase 0 status: PARTIAL.**
> The Infinite Warfare half of this analysis is complete. Every claim in it was checked against source code, real script dumps, or a real compiler run.
> The BO3 reference half is **BLOCKED**. The supplied archive (`/AllAroundEnhancement.7z` in Dropbox, 1,485,295,642 bytes) could not be downloaded into the build environment, because the environment's network egress policy denies the Dropbox download host (`*.dl.dropboxusercontent.com`, HTTP 403 on CONNECT). The Dropbox connector can only read files up to 5 MiB, and the archive is a single 1.48 GB 7z.
> Everything in section 1 comes from **secondary public descriptions** returned by web search. Those descriptions are labelled *PROVISIONAL* throughout. They must be re-verified against the real files before Phase 1 relies on them. See section 1.1 for ways to unblock this.

---

## 0. Sources examined

| # | Source | Version / commit | Used for | Access |
|---|--------|------------------|----------|--------|
| S1 | BO3 *All-Around Enhancement* archive (`/AllAroundEnhancement.7z`, Dropbox) | uploaded 2026-10-06 09:40 UTC | BO3 reference implementation | **BLOCKED** (egress policy, see 1.1) |
| S2 | Public descriptions of AAE (Steam Workshop item 2631943123 and community guides), seen **only through web-search result summaries** | n/a | Provisional BO3 feature inventory | Search summaries only; steamcommunity.com and mirrors are blocked by egress policy |
| S3 | `auroramod/iw7-mod`, the IW7 community client that loads custom GSC | `develop` @ `c0a1c6da` (2026-10-05); release tag `v1.1.0` @ `1b76f04e` (2026-09-26) | Script loading, mod loading, client-added GSC/Lua functions, dvars | Cloned and read |
| S4 | `auroramod/gsc-tool`, branch `iw7-more` (the compiler embedded in iw7-mod) | develop pin `0be361a4` (2026-09-24); v1.1.0 pin `833822d0` (2026-01-10) | IW7 builtin function and method tables; real compile checks | Cloned, **both pins built locally**, and test-compiled |
| S5 | `xensik/gsc-tool` (upstream) | `05d212f5` | Comparison of builtin tables | Cloned |
| S6 | `mjkzy/iw7-gsc-dump`, decompiled stock IW7 GSC (MP + CP/zombies) | `1dd48a78` (2026-09-26) | Callbacks, notifies, zombies wave system, stock helper APIs | Cloned and read |
| S7 | `auroramod/docs` (source of docs.auroramod.dev) | `236d8155` | Official folder layout, mod loading, command-line flags | Cloned and read (the docs website itself is blocked) |
| S8 | `SyndiShanX/Synergy-GSC-Menu` (`IW/`), an existing IW7 GSC menu | `33bcc80f` | Which APIs work in practice in IW7 (feasibility only; GPL-3.0, **no code copied**) | Cloned and read |

---

## 1. BO3 REFERENCE: All-Around Enhancement (AAE)

### 1.1 Access status: BLOCKED

| Attempt | Result |
|---------|--------|
| Direct download (Dropbox temporary link, `uc…dl.dropboxusercontent.com`) | `403` at the egress gateway: *"gateway answered 403 to CONNECT (policy denial)"* |
| Dropbox connector `fetch` | `FILE_TOO_LARGE`: the connector limit is 5 MiB and the archive is 1,485,295,642 bytes |
| Public mirrors (steamcommunity.com, catalogue.smods.ru) | Blocked by egress policy |

Any one of these unblocks the BO3 analysis:

1. Allow `dl.dropboxusercontent.com` (with subdomains) in the cloud environment's network settings. The environment's **Edit → Network access** menu offers either a broader level or *Custom* with that host added. After that, the archive can be downloaded and extracted here.
2. Extract the archive locally and upload only the **script/text files** to Dropbox as individual files under 5 MiB each (`.gsc`, `.csc`, `.gsh`, `.lua`, `.zpkg`, `.gdt`, `.csv`, `.txt`, `.json`, `.cfg`, `.str`). The connector can then read each one.
3. Commit the extracted scripts to a branch of this repository, or to another repository.

### 1.2 Items that require the real files (PENDING)

The following analyses were requested and **cannot be produced honestly without the archive**. They are listed so nothing is silently dropped:

| Requested analysis | Status | What will be checked once accessible |
|--------------------|--------|--------------------------------------|
| Folder structure | PENDING | Full tree; size by type; zone/source layout |
| Script structure | PENDING | Every `.gsc`/`.csc`/`.gsh`; entry points (`autoexec`, `__init__`, `main`, `init`); namespaces |
| Major functions | PENDING | Call graph of the menu, config, and feature modules |
| Menu structure | PENDING | Full option tree, labels, defaults, ranges |
| Feature categories | PROVISIONAL (1.3) | Confirm against the menu definitions in code |
| Shared utilities | PENDING | Common helpers (HUD, input, string, array, player) |
| Initialization flow | PENDING | What runs on level load, player connect, spawn, and round start |
| Configuration flow | PROVISIONAL (1.4) | How "modvars" are parsed, stored, persisted, and applied |
| Asset usage | PENDING | Models, images, sounds, FX, weapons, camos, LUI widgets, and which zones contain them |
| UI implementation | PROVISIONAL (1.5) | GSC HUD menu vs LUI; how HUD styles are swapped |
| Dependencies | PENDING | T7 shared scripts (`zm_utility`, `zm_powerups`, …), other workshop items, BO3 modtools, external tools |
| Multiplayer / co-op handling | PROVISIONAL | Host-only logic, 10-player handling, per-player state |

### 1.3 Provisional feature inventory (secondary sources only)

Each item below was described in web-search summaries of the Workshop page and community guides (S2). How each one is implemented stays unknown until the files are read.

**Gameplay / zombies tuning**
- Zombie speed: default, sprinting, or "super sprinter"; `zm_speed` 0–100
- Zombie health changes; cap zombie health after a chosen round
- Zombie spawn cap raised from 24 up to 64; spawn delay; "spawn additional zombies" (`zombie` 1–60)
- Zombie dodge (from BO1)
- Start round 1–255 (`round`)
- Perk limit 1–50
- Disable gobblegums; enable the Rampage Inducer on most maps
- Weapon Roulette mode (random weapon each round); End-Game Challenge; 30-second break after round 20
- Time-based gameplay (non-stop spawning)
- Friendly-fire options
- BO4-style Max Ammo that also refills clips
- Change player health

**Quality of life**
- BO2-style bank (balance carries across maps) and weapon locker
- Weapon restore on disconnect (weapons, perks, points); optional clear on bleed-out
- Offline bots
- Solo-completable Easter eggs (e.g. Shadows of Evil, Ascension, Shangri-La)
- Easter-egg-count reward system (cheaper bank/share at 15 EEs, Gambler changes at 25, longer bleed-out at 30)
- Developer console support (`~`)
- Marked/"pinged" doors; pinging
- `no_inspect` modvar (disable weapon inspect)

**HUD / visual**
- HUD colour; HUD style selection (AAE, default, BO2)
- Health bars (modern-zombies style); zombie counter; damage numbers on zombies
- Hitmarkers with sounds from several CoD titles
- Night vision
- Camos from other titles (IW Diamond, Cold War Dark Aether, AW X-ray)

**Movement**
- Exo-movement option; option to disable sliding

**Multiplayer**
- Up to 10 players in zombies (gobblegums disabled at that size)

### 1.4 Provisional configuration model (secondary sources)

- Options are **"modvars"** set from the developer console with a short command (described as `/d <name> <value>`), before or during a match. Examples named in the sources: `zm_speed`, `round`, `hitmarker`, `zombie`, `no_inspect`.
- An **"Advanced Features"** master switch gates the GSC mod menu and some commands.
- Some options are applied in real time; others are meant to be set before the match starts.

### 1.5 Provisional menu model (secondary sources)

- A **GSC mod menu**, opened with **ADS + Melee**. The sources call it a GSC menu; that it is drawn with HUD elements rather than LUI is an inference to confirm in code.
- **Shoot/ADS** scroll, **Use (F)** selects, **Melee** goes back or closes. Controller users rebind to the D-pad.
- It requires "Advanced Features = On".

---

## 2. INFINITE WARFARE (IW7)

### 2.1 Available modding tools

| Tool | What it provides | Notes |
|------|------------------|-------|
| **iw7-mod** (S3) | Community client. Loads custom **GSC from source** (compiled at runtime by an embedded gsc-tool), Lua UI scripts (`ui_scripts/`), mods (`mods/<name>`, selected via `fs_game`), extra GSC built-ins, extra dvars, console | **Required** at runtime. Latest release is **v1.1.0**; `develop` is ahead (see 2.7) |
| **gsc-tool** `iw7-more` (S4) | IW7 GSC compiler/decompiler. The same code iw7-mod embeds | Built locally at **both** iw7-mod pins and used for offline compile checks |
| **IW7 GSC dump** (S6) | Decompiled stock scripts: the only reference for stock function names, notifies, and level fields | Many identifiers appear only as hashes (`_id_XXXX`) |
| **x64-zt** (per S7 docs) | Read/write IW7 fastfiles (`mod.ff`) for custom assets | Needs Windows and game files; outside the script-only phases |
| iw7-mod console | `~` console, `set <dvar> <value>`, `exec` | Usable to configure the mod through dvars |

**There are no official Infinite Warfare mod tools**, so no Radiant or official linker exists. Everything goes through iw7-mod.

### 2.2 Scripting language

- **GSC** (IW-engine dialect): threads (`thread`, `childthread`), `wait`, `waittill`/`notify`/`endon`, function pointers `::f` / `[[ f ]]()`, `#include`, far calls `path\to\script::func()`, structs (`spawnstruct()`), arrays, `foreach`, `switch`.
- **IW7 peculiarities, all verified:**
  - Built-in function and method names are **resolved by the compiler from a table**. A name missing from the table is a compile error (`couldn't determine function call type`), so invented APIs are caught at compile time.
  - Unknown built-ins can be called by raw id (`_func_XXX`, `_meth_XXXX`). The compiler accepts this, and it is how develop-only names are called portably (section 2.7).
  - Many stock **field and function names are hashed** in the game data. The dump shows them as `_id_XXXX`. Writing a guessed "real" name for a hashed field creates a *different* variable, so reads silently return `undefined`. Stock fields must be referenced exactly as the dump spells them.
  - New, mod-defined field names (`self.ix_menu`) compile as strings and work. iw7-mod's own scripts rely on this.
- **Lua (Havok Lua / LUI)** for UI: `ui_scripts/<Folder>/__init__.lua`, loaded by iw7-mod on the client.

### 2.3 Available APIs (summary; full detail in `IW_API_NOTES.md`)

| Area | Verified availability |
|------|----------------------|
| Player connect/spawn | `level waittill("connected", p)`; `self waittill("spawned_player")`; `level waittill("player_spawned", p)` (MP **and** CP) |
| Damage/kill callbacks | `level.callbackplayerdamage` (12 args), `level.callbackplayerkilled`; agents (zombies) use `level.agent_funcs[type]["on_damaged"/"on_killed"]` |
| Zombies rounds (CP) | `level.wave_num`; notifies `regular_wave_starting`, `event_wave_starting`, `spawn_wave_done`; player notify `next_wave_notify` |
| Zombie counts (CP) | `level.current_num_spawned_enemies`, `level.desired_enemy_deaths_this_wave`, `level.current_enemy_deaths`; `scripts\cp\cp_agent_utils::getaliveagents()` |
| Zombie speed (CP) | `self.movemode` (`slow_walk`/`walk`/`run`/`sprint`); hook `level.movemodefunc[agent_type]`; `self.moveratescale` |
| Currency (CP) | `scripts\cp\cp_persistence::get_player_currency / set_player_currency / give_player_currency / take_player_currency` |
| Power-ups (CP) | `scripts\cp\loot::drop_loot(...)` (power-up refs such as `instakill_30`, `ammo_max`, `kill_50`, `cash_2`) |
| Perks (CP) | `scripts\cp\zombies\zombies_perk_machines::give_zombies_perk / take_zombies_perk` (`perk_machine_*`) |
| HUD | `newclienthudelem`, `newhudelem`, `settext`, `setvalue`, `setshader`, `fadeovertime`, `moveovertime`, `destroy`; fields `x y alignx aligny horzalign vertalign font fontscale color alpha label sort foreground archived hidewheninmenu hidewhendead glowcolor glowalpha` |
| Input | `notifyonplayercommand`, `usebuttonpressed`, `attackbuttonpressed`, `adsbuttonpressed`, `meleebuttonpressed`, `fragbuttonpressed`, `secondaryoffhandbuttonpressed` |
| Movement | `setmovespeedscale`, `allowjump/sprint/slide/wallrun/doublejump/mantle/ads/fire/melee`, `setvelocity/getvelocity`, `setorigin`, `setplayerangles`, `freezecontrols`; iw7-mod dvars `bg_gravity`, `g_speed`, `jump_enableFallDamage`, `mantle_legacy*`, `bg_bounces` |
| Weapons | `giveweapon`, `takeweapon`, `switchtoweapon`, `getcurrentweapon`, `setweaponammoclip/stock`, `givemaxammo`, `weaponclipsize`, `getweaponbasename`, `player_recoilscaleon`, `setspreadoverride`, fire-rate scale (`_meth_85C1`/`_meth_85C2`), iw7-mod dvar `player_sustainAmmo` |
| Health | `enableinvulnerability`, `disableinvulnerability` (**use `_meth_80A1`**, see 2.7), `dodamage`, `.health`/`.maxhealth` |
| Dvars | `getdvar*`, `setdvar`, `setdvarifuninitialized`, `setclientdvar(s)`; script-source sets bypass the console cheat/replicated checks |
| File I/O (iw7-mod) | `fileexists`, `readfile`, `writefile(path, data, append)`, `createdirectory`, `listfiles`, `removefile`. Paths are relative to **`fs_game`**, and calls throw if no mod is loaded |
| Misc (iw7-mod) | `replacefunc`, `getfunction`, `executecommand`, `print`/`println`, `logprint`, `va`, `typeof`, `toupper`, `strstartswith`, `say`, `tell`; notifies `say`/`say_team` |
| LUI ↔ GSC | LUI `Engine.NotifyServer(name, int)` → GSC `self waittill("luinotifyserver", name, value)`; GSC `setclientomnvar` → LUI `Game.GetOmnvar` (predefined omnvars only) |

### 2.4 Build pipeline

1. **Runtime build.** iw7-mod compiles each `.gsc` **from source** when a map loads. There is no offline build step for players.
   - A compile error in an **auto-loaded entry script** is printed to the iw7-mod console, and that script is skipped (`load_custom_script` catches the error).
   - What happens when a **module that is only referenced** fails to compile is unverified; it may abort the level load. This is another reason every script is compile-checked offline.
2. **Offline verification** (this project). Compile every script with gsc-tool built at **both** pins iw7-mod uses:
   - `833822d0` → users on **v1.1.0 (release)**
   - `0be361a4` → users on **develop**

   Then disassemble both outputs and diff the native call names. This was done for test scripts during Phase 0 (section 2.7). Build procedure:
   `premake5 gmake2` with premake 5.0.0-beta2 for `833822d0`, or `premake5 gmake` with 5.0.0-beta8 for `0be361a4`, then `make -C build config=release_amd64 xsk-tool`, with clang 18. `tools/setup_compilers.sh` automates this; details are in `tools/README.md`.
3. **Packaging check.** Total custom bytecode must stay **under 1 MiB** per map load (`script_memory.size = 0x100000`). Going over is a **fatal** `Com_Error` ("Out of custom script memory"), and the budget is shared with iw7-mod's own bundled custom scripts and any other mod.

### 2.5 Packaging

Two supported layouts (from S3 code and S7 docs):

```text
A) As a mod (recommended — enables file I/O persistence)
<Infinite Warfare>/mods/infinite_expansion/
├── desc.txt                         ← shown in the in-game Mods menu
├── custom_scripts/
│   ├── cp/ix_main.gsc               ← zombies entry point (auto-loaded)
│   ├── mp/ix_main.gsc               ← multiplayer entry point (auto-loaded)
│   └── ix/...                       ← modules (NOT auto-loaded; loaded by reference)
└── (optional) ui_scripts/<Name>/__init__.lua, mod.ff
Load: in-game "Mods" menu → sets fs_game=mods/infinite_expansion → vid_restart
  or: iw7-mod.exe +set fs_game "mods/infinite_expansion"

B) Loose scripts (no fs_game ⇒ GSC file I/O unavailable)
<Infinite Warfare>/iw7-mod/custom_scripts/...   (same inner layout)
```

Loader facts that drive the layout:

- **Which folders auto-load.** Auto-loaded folders are scanned **non-recursively**: `custom_scripts/`, `custom_scripts/<mode>/` (`mp`, `cp`, `sp`), and `custom_scripts/cp_mp/` (for both MP and CP). In the frontend, only `custom_scripts/frontend/` loads, and only on develop.
- **Entry points.** Each auto-loaded script may define `main()` and `init()`.
  - `main()` runs at `G_LoadStructs`, before stock level scripts (used for `replacefunc`).
  - `init()` runs at `Scr_LoadLevel`, **before the map's own `main()`**. Anything that must wrap callbacks set by map scripts has to wait first.
- **Docs vs. code.** The generic docs show `mods/<name>/scripts/`, but the IW7 loader only scans `custom_scripts/`. This project follows the code.

### 2.6 Testing process

| Level | Where | What |
|-------|-------|------|
| Static: compile | Here (Linux) | Both compilers; no unknown built-ins; no syntax errors |
| Static: release/develop parity | Here | Disassemble both outputs and diff the native call names |
| Static: far-call targets | Here | Every `scripts\…::func` reference must exist in the stock dump |
| Static: bytecode budget | Here | Sum of compiled sizes, well under 1 MiB |
| **Runtime** | **Windows + legally owned IW7 + iw7-mod only** | Load each map/mode and run `TESTING.md`. **Cannot be done in this environment.** Every runtime claim stays *NEEDS TESTING* until a user confirms it |

### 2.7 Known limitations (summary; full list in `KNOWN_LIMITATIONS.md`)

1. **The release v1.1.0 compiler has mislabeled method ids (verified by compiling and disassembling).**
   - `self disableinvulnerability()` compiles to native **`disablegrenadetouchdamage`**.
   - `self playlocalsound(x)` compiles to native **`playercommandbot`**.
   - Fix: call `_meth_80A1` and `_meth_8242`, which compile identically and correctly on both.
2. **503 method names and 5 function names are known only to the develop compiler.** On v1.1.0 they fail to compile by name; examples are `hasperk`, `setnormalhealth`, `jumpbuttonpressed`, `setcamerathirdperson`, `setfiretimescaleon`, `player_recoilscaleoff`, and `resetspreadoverride`. Fix: use `_meth_XXXX` ids, centralized in one compatibility module.
3. **Develop-only dvars.** `bg_omnimovement`, `bg_sprintUnlimited`, and `bg_airControl` exist only on develop. Feature-detect at runtime: an empty `getdvar(name)` means the dvar is unavailable.
4. **Debug drawing built-ins are release stubs.** `line`, `sphere`, `box`, `cylinder`, `print3d`, `printtoscreen2d`, and the native file functions are `nullptr` in the release exe. Calling them is a runtime script error.
5. **No custom console commands from GSC.** `adddebugcommand` is a stub, so configuration uses `set ix_<name> <value>` dvars instead of a custom command.
6. **Rapid-fire via weapon-field editing is unavailable.** iw7-mod's `setWeaponField*` commands exist only in `_DEBUG` builds. The native fire-time scale is used instead.
7. **Client-only data is not visible to server GSC.** This includes FPS, key binds, and client dvar values. Only server-side state can be displayed.
8. **The `clearalltextafterhudelem` overflow workaround is a stub.** The HUD must minimise unique `settext` strings; whether IW7 overflows here NEEDS TESTING.
9. **Scripts run only on the host.** In MP, the menu works only for the host's game (Synergy notes the same).
10. **Asset additions need x64-zt and Windows.** Camos, sounds, and models are out of scope for script phases.

---

## 3. FEATURE COMPATIBILITY MATRIX (PROVISIONAL)

The *BO3 Implementation* column is from secondary descriptions (S2) and will be re-verified against the archive.
Difficulty: E = Easy, M = Medium, H = Hard.
Classification:
- **DP**: Directly Portable
- **RI**: Reimplementable
- **PP**: Partially Possible
- **NCP**: Not Currently Possible
- **UNK**: Unknown / Needs Testing

Every IW mechanism named here was checked in S3/S4/S6. A mechanism written as a raw `_meth_XXXX` id is callable on iw7-mod v1.1.0 only in that form (section 2.7).

### 3.1 Framework / menu / config

| BO3 Feature | BO3 Implementation (provisional) | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| GSC mod menu (ADS+Melee open; Shoot/ADS scroll; Use select; Melee back) | GSC HUD menu | GSC HUD menu: `newclienthudelem` + polled `adsbuttonpressed/meleebuttonpressed/attackbuttonpressed/usebuttonpressed` (all present in both compilers). Proven feasible in IW7 CP by S8 | M | RI | PLANNED (Phase 3) |
| "Advanced Features" master switch | Modvar gate | `ix_enabled` / `ix_dev` dvars read by the feature manager | E | RI | PLANNED |
| Modvars set via console (`/d name value`) | Custom command + dvars | `set ix_<name> <value>` in the iw7-mod console (GSC cannot add console commands); a watcher thread applies changes live | E | RI | PLANNED (Phase 2) |
| Developer console | BO3 lacks a console | Provided by iw7-mod (`~`) | – | DP | N/A (already exists) |
| Settings persistence | Unknown (PENDING) | `writefile`/`readfile` to `ix_settings.cfg` under `fs_game`; fallback is dvars only (session) | M | RI | PLANNED (Phase 2/11) |
| Multiplayer / co-op | Unknown (PENDING) | Per-player state on the player entity; host-only menu in MP | M | RI | PLANNED |

### 3.2 Zombies (IW7 "cp" mode)

| BO3 Feature | BO3 Implementation (provisional) | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Zombie speed (default / sprint / super sprint; `zm_speed`) | Modifies zombie move speed | `level.movemodefunc[agent_type]` returns `"sprint"`; "super" adds `self.moveratescale > 1` (stock uses 1.15) | M | RI | PLANNED (super-sprint values UNK) |
| Zombie health / cap after round | Health calc override | Scale `.maxhealth/.health` after spawn (`agent_spawned` notify), or `replacefunc` each map's `calculatezombiehealth` | M | RI | PLANNED |
| Zombie spawn cap 24→64 | Spawn limit | `level.max_static_spawned_enemies` (stock 24) is a script var; the engine agent cap is unknown | H | PP / UNK | INVESTIGATING |
| Extra zombies (`zombie 1–60`) | Spawns more | Raise `level.desired_enemy_deaths_this_wave`; or stock `scripts\mp\mp_agent::spawnnewagent(...)` (argument semantics to be read before use) | M | PP | PLANNED |
| Start round 1–255 (`round`) | Sets round | Set `level.wave_num` before the wave loop advances; push omnvar `zombie_wave_number` | M | RI / UNK | PLANNED (side effects need testing) |
| Zombie dodge (BO1) | Custom anim/AI | Needs new ASM states and animations | H | NCP | BLOCKED — IW LIMITATION |
| Perk limit 1–50 | Perk cap var | No perk-cap logic found in IW7 `zombies_perk_machines` / `perks/` (grep found none) | – | UNK | INVESTIGATING (may be N/A) |
| Disable gobblegums | Disable feature | IW7 analogue is Fate & Fortune cards (`zombies_consumables.gsc`); disabling needs `replacefunc` research | M | PP | INVESTIGATING |
| Rampage Inducer | Faster early rounds | Combine move-mode override and spawn pacing for rounds < N | M | PP | PLANNED |
| Weapon Roulette + End-Game Challenge | Random weapon per round | On `regular_wave_starting`: `takeweapon` + `giveweapon(random)` from a curated `iw7_*_zm` list | M | RI | PLANNED |
| 30 s break after round 20 | Wave timing | The wait between waves is internal to the wave loop (`_id_E81B`); would need `replacefunc` of hashed functions | H | PP | INVESTIGATING |
| Time-based (non-stop) spawning | Spawner change | Same wave-loop internals | H | PP | INVESTIGATING |
| Friendly fire options | Damage callback | `scr_team_fftype` dvar (stock) and/or a damage-callback wrapper | E | RI | PLANNED |
| BO4 Max Ammo refills clips | Power-up override | Hook the `ammo_max` power-up (`scripts\cp\loot`), then `setweaponammoclip(w, weaponclipsize(w))` | M | RI | PLANNED |
| Bank / weapon locker across maps | Persistent storage | GSC file I/O under `fs_game` (`writefile`) | M | RI | PLANNED (requires mod-folder install) |
| Weapon restore on disconnect | Stores loadout | Per-GUID store in `level` (same match) or file (cross-session) | M | RI | PLANNED |
| Offline bots | Bots in zombies | `addtestclient`/`addbot` exist, but no IW7 CP bot AI was found | H | NCP / UNK | INVESTIGATING |
| Solo Easter eggs | Script edits per map | Per-map `replacefunc` of quest steps (5 maps; many hashed names) | H | PP | DEFERRED |
| EE-count rewards | Persistent stats | File I/O counters + perk/cost hooks | H | PP | DEFERRED |
| 10-player zombies | Engine/lobby change | IW7 CP is a 4-player mode; the engine client cap is unverified | H | NCP / UNK | BLOCKED — IW LIMITATION (pending test) |
| Pinging / marked doors | Ping system | `scripts\cp\cp_outline::enable_outline_for_players`, `scriptmoveroutline` (`_meth_8549`), waypoint hudelems | M | PP | PLANNED |
| (new) Zombies ignore a player | – | `self.ignoreme = 1` (token; 49 uses in stock MP/CP scripts) | E | RI | PLANNED |

### 3.3 Player / movement

| BO3 Feature | BO3 Implementation (provisional) | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Exo movement | BO3 exo port | Native in IW7 (boost jump, wallrun, slide): `allowdoublejump`, `allowwallrun`, `allowslide`; omni-movement via `bg_omnimovement` (develop only) | E | RI | PLANNED |
| Disable sliding | Allow-slide toggle | `self allowslide(0)` | E | DP | PLANNED |
| Change player health | maxhealth edit | `self.maxhealth` / `self.health`; CP regen interaction UNK | E | RI / UNK | PLANNED |
| (new) Movement speed | – | `setmovespeedscale(f)` per player, or `g_speed` dvar (global) | E | RI | PLANNED |
| (new) Gravity | – | `bg_gravity` dvar (iw7-mod, range 1–1000, replicated, global) | E | RI | PLANNED |
| (new) Jump height | – | No verified dvar (`jump_height` not seen in stock scripts) | – | UNK | INVESTIGATING |
| (new) Unlimited sprint / air control | – | `bg_sprintUnlimited`, `bg_airControl` (develop only, feature-detect) | E | PP | PLANNED |
| (new) Fall damage toggle | – | `jump_enableFallDamage` dvar (iw7-mod) | E | RI | PLANNED |
| (new) Third person | – | `setcamerathirdperson` (`_meth_845E`, per player, used by stock), or `cg_thirdPerson` (client, host only) | E | RI | PLANNED |
| (new) God mode | – | `enableinvulnerability` / `_meth_80A1` (disable) | E | RI | PLANNED |
| (new) Teleport / noclip-style fly | – | `setorigin`, `playerlinkto` a mover | M | RI | PLANNED |

### 3.4 Weapons

| BO3 Feature | BO3 Implementation (provisional) | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| (new) Infinite ammo | – | `player_sustainAmmo` dvar (iw7-mod, global), or a per-player `setweaponammoclip`/`givemaxammo` loop | E | RI | PLANNED |
| (new) Rapid fire / fire-rate | – | `setfiretimescaleon(pct)` / `off` (`_meth_85C1` / `_meth_85C2`); stock uses 65 | M | RI / UNK | PLANNED (range UNK) |
| (new) Recoil modifier | – | `player_recoilscaleon(0–100)`; off is `_meth_822C`; read is `_meth_85C0` | E | RI | PLANNED |
| (new) Spread modifier | – | `setspreadoverride`; reset is `_meth_8263` | E | RI | PLANNED |
| (new) Damage multiplier | – | Wrap `level.callbackplayerdamage` (players) and `level.agent_funcs[type]["on_damaged"]` (zombies) | M | RI | PLANNED |
| (new) Give / take / info utilities | – | `giveweapon`, `takeweapon`, `getcurrentweapon`, `getweaponbasename`, `getweaponattachments`, `weaponclipsize` | E | RI | PLANNED |
| (new) Quick weapon switch | – | `enablequickweaponswitch` (`_meth_84AF`), no stock usage | E | UNK | INVESTIGATING |
| Camos from other titles | New assets | Needs fastfile assets (x64-zt) | H | NCP (script-only) | DEFERRED (asset pipeline) |
| `no_inspect` | Modvar | IW7 inspect is added by iw7-mod's own `custom_scripts/cp_mp/inspect.gsc` and cannot be cleanly disabled from another script | E | NCP | N/A |

### 3.5 HUD / visuals / debug

| BO3 Feature | BO3 Implementation (provisional) | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Zombie counter | HUD element | `setvalue(level.desired_enemy_deaths_this_wave - level.current_enemy_deaths)` | E | RI | PLANNED |
| Health bars / damage numbers | HUD | Crosshair-target readout (`bullettrace`), or short-lived hudelems (budget risk) | M | PP | PLANNED |
| Hitmarker sounds | Custom sounds | Stock IW7 sounds only via `playlocalsound` (`_meth_8242`); new sounds need assets | M | PP | PLANNED |
| HUD colour / HUD style swap | LUI / HUD assets | Own GSC HUD fully themeable; restyling the **stock** LUI HUD needs client Lua (`ui_scripts`) | H | PP | DEFERRED |
| Night vision | Vision toggle | `nightvisionviewon/off` (`_meth_821A` / `_meth_8219`), no stock usage; or `visionsetnakedforplayer` | E | UNK | INVESTIGATING |
| (new) FPS display | – | Server GSC cannot read client FPS; a client dvar toggle is UNK | – | NCP (GSC) | BLOCKED — IW LIMITATION |
| (new) Coordinates / speed / weapon HUD | – | `self.origin`, `getvelocity`, `getcurrentweapon`, `getweaponammoclip` + `setvalue` | E | RI | PLANNED |
| (new) Debug lines / 3D text | – | `line` / `print3d` are release stubs | – | NCP | BLOCKED — IW LIMITATION |
| (new) Entity inspector / trace info | – | `bullettrace` (returns entity/position/normal), entity fields, `getentitynumber` | M | RI | PLANNED |
| (new) Fast restart | – | `map_restart` function / `executecommand("fast_restart")` | E | RI / UNK | PLANNED |
| (new) Timescale | – | `setslowmotion` (iw7-mod) / `timescale` dvar | E | RI | PLANNED |

---

## 4. Decisions proposed for Phase 1 (pending the BO3 files)

1. **Target both iw7-mod v1.1.0 and develop.** Use only names the release compiler resolves correctly. Put every develop-only or mislabeled built-in behind `_meth_`/`_func_` ids in one `ix\core\compat` module. Enforce this with the dual-compile parity check.
2. **Primary install is the mod-folder layout** (`mods/infinite_expansion`), which gives file-based persistence. Loose `iw7-mod/custom_scripts` installs still work, with dvar-only settings.
3. **Primary menu is a GSC HUD menu** (server-side), which matches AAE's own GSC menu and works for every client on the host. A LUI menu is a later, optional client-side upgrade.
4. **Zombies (CP) is the primary target**, MP second (host only), and SP out of scope.
5. **Use one entry script per mode** (`custom_scripts/cp/ix_main.gsc`, `custom_scripts/mp/ix_main.gsc`), with modules under `custom_scripts/ix/`. CP-only modules (which reference `scripts\cp\…`) must never be referenced from the MP entry. Doing so would make MP try to load CP scripts.
6. **The BO3 file analysis must be completed** (section 1.2) before the menu tree and option list are finalized in Phase 3.
