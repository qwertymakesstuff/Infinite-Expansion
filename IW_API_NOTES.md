# IW_API_NOTES.md — Verified Infinite Warfare (IW7) Scripting Notes

This is the working API reference for the project. **Nothing here is guessed.** Every entry cites where it was verified:

| Tag | Source | Commit |
|-----|--------|--------|
| `[MOD]` | `auroramod/iw7-mod` client source | develop `c0a1c6da`; release `v1.1.0` `1b76f04e` |
| `[TOOL-D]` | IW7 builtin table used by the iw7-mod **develop** compiler (`auroramod/gsc-tool` `0be361a4`) | |
| `[TOOL-R]` | IW7 builtin table used by the iw7-mod **v1.1.0** compiler (`auroramod/gsc-tool` `833822d0`) | |
| `[DUMP]` | Decompiled stock IW7 scripts (`mjkzy/iw7-gsc-dump`) | `1dd48a78` |
| `[DOCS]` | `auroramod/docs` | `236d8155` |
| `[STOCK UI]` | The game's compiled menu scripts (`ui/frontend/cp/*.lua`, `ui/uieditor/*.lua`) in `TheUnknownCod3r/iw7-src`, read as data (§16) | `d1a226db` |
| `[ZT]` | `Joelrau/x64-zt` (zonetool) source, for the character pictures pack (§18) | `3802db4d` |
| `[LISTING]` | aurora's IW7 asset listing (`iw7_asset_listing.zip`, linked from `auroramod/docs`): every stock zone's assets (§18) | |
| `[COMPILED]` | Compiled locally with **both** compilers during Phase 0 | |

If an API is not listed here, verify it the same way before using it. The rule is in section 12.

---

## 1. Runtime environment

- **Project scope: zombies (CP) only** (multiplayer dropped 2026-10-06). Multiplayer facts in this file are kept as reference.
- Mods run under the **iw7-mod** client. Its latest release is **v1.1.0**; `develop` is ahead. `[MOD]`
- Game modes: `GAME_MODE_SP=1`, `GAME_MODE_MP=2`, `GAME_MODE_CP=3`. "CP" is Zombies. `[MOD structs.hpp]`
- Zombies maps: `cp_zmb`, `cp_rave`, `cp_disco`, `cp_town`, `cp_final`. `[DUMP scripts/cp/maps/]`
- Map name in script: `level.script` or `getdvar("mapname")`. `[DUMP]`
- Zombies gametype: `getdvar("ui_gametype") == "zombie"` (also `escape`, `none`). `[DUMP cp/gametypes]`

## 2. Script loading `[MOD gsc/script_loading.cpp]` `[DOCS gsc-load-script.md]`

| Fact | Detail |
|------|--------|
| Source compiled at runtime | iw7-mod compiles `.gsc` **source** with its embedded gsc-tool when a map loads. A compile error in an auto-loaded entry script is printed to the console (`script compile error`) and that script is **skipped**. |
| Link errors drop the match | An unresolved far-call target (unknown function, or a script that could not be loaded) is reported as `Com_Error(ERR_SCRIPT_DROP, "script link error …")` (`compile_error_stub`, `find_variable_stub` in `gsc/script_error.cpp`). A referenced module that fails to compile therefore most likely ends the load. Not yet observed in-game (R-S6). |
| Runtime errors | `vm_error_internal` prints `script runtime error` **only when `developer_script` is on**; otherwise it is silent. The exception is a call to a missing built-in, which always prints `builtin function "x" doesn't exist` (`script_extension.cpp`). |
| Compile mode | `developer_script` (registered by iw7-mod, default off in release builds) also switches the compiler from `build::prod` to `build::dev`, which compiles `/# … #/` dev blocks (`init_compiler`, `script_loading.cpp`). |
| Extension built-ins | `function::add` / `method::add` **replace** the handler of a name already in the table (`print`, `println`, `assert`, `assertex`, `logprint`, `setslowmotion`) and **append** new names with ids from 807 (functions) and `0x85CC` (methods) in registration order. Scripts must call them by name; their raw ids are not stable. `print` joins its arguments with tabs and writes to the console. |
| Name resolution | An unqualified call resolves to a built-in first, then a function in the same file, then an `#include`. Defining a script function with a built-in's name is a compile error (`function name 'x' already defined as builtin`) in both compilers `[COMPILED]`. |
| Search paths | `<game>/iw7-mod/`, then `%LOCALAPPDATA%/…/cdata` (client data, iw7-mod's own scripts), then the engine's own search paths (`fs_searchpaths`), which should include `<game>/<fs_game>` when a mod is loaded (engine behaviour; R-S1 confirms it). `fs_startup_stub` registers cdata first and `<game>/iw7-mod` second, each with `push_front`, so `<game>/iw7-mod` ends up first. Auto-loading scans them in this order, and a file in an earlier path overrides the same relative file in a later one. The console lists the paths under `----- FS_Startup -----`. `[MOD filesystem.cpp]` (corrected 2026-10-06: an earlier version of this note had cdata first) |
| Auto-loaded folders (in-game) | `custom_scripts/`, `custom_scripts/<mode>/` (`mp`, `cp`, `sp`), and `custom_scripts/cp_mp/` (in MP **and** CP). |
| Auto-loaded folders (frontend) | `custom_scripts/frontend/` only, and **only on develop** (added after v1.1.0). |
| Scanning is non-recursive | `utils::io::list_files` uses `directory_iterator`. Subfolders of the auto-load folders are **not** auto-loaded. They load only when referenced (`#include` or a far call), which is how modules are kept out of auto-execution. |
| Entry points | For each auto-loaded file: `main()` runs at `G_LoadStructs` (**before** stock level scripts; use it for `replacefunc`). `init()` runs at `Scr_LoadLevel`, **before the map's own `main()`**. |
| Ordering consequence | Anything that wraps a callback a map script assigns (for example `level.callbackplayerdamage`, which `cp_town`, `cp_rave`, `cp_disco`, and `cp_final` reassign) must **wait** first, for instance until `level waittill("connected")` or `"prematch_done"`, before wrapping. |
| Custom bytecode budget | `script_memory.size = 0x100000` (**1 MiB**) for **all** custom scripts in one load. Each loaded script takes its bytecode length + 1 (`allocate_buffer`); strings and the stack are allocated elsewhere. Exceeding it is a **fatal** `Com_Error("Out of custom script memory")`. iw7-mod's own bundled scripts count toward it: **711 bytes in CP** (`cp/patches.gsc`, `cp_mp/inspect.gsc`) and **6,823 bytes in MP** (`mp/bots.gsc`, `mp/bots_loadout.gsc`, `mp/ranked.gsc`, `cp_mp/inspect.gsc`), the same at v1.1.0 and develop `[COMPILED]`. |
| Includes | `#include path\to\file;` resolves raw `.gsc` files from the search paths first; otherwise the stock compiled script is decompiled. |
| Stock scripts per zombies map | A match loads the map's level script (`scripts\cp\maps\<map>\<map>`) and the gametype script (`scripts\cp\gametypes\zombie`) and links what they reference, transitively. In the dump, **126** scripts are common to all five maps, among them `cp\utility`, `cp\cp_persistence`, `cp\loot`, `cp\cp_laststand`, `cp\cp_agent_utils`, `cp\cp_outline`, `cp\zombies\zombie_damage`, `cp\zombies\zombies_spawning`, `cp\zombies\zombies_perk_machines`, `cp\zombies\zombies_consumables`, `engine\utility`, and `mp\mp_agent`. `scripts\mp\hud_util` is linked on none. `[DUMP]` (computed by `tools/check.py`) |
| `developer_script` dvar | When enabled, the compiler includes `/# … #/` dev blocks. It defaults to off in release builds. |

## 3. Packaging `[MOD party.cpp, fastfiles.cpp, ui_scripts/Mods]` `[DOCS loading-mods.md]`

- Mods live in `<game>/mods/<name>/`. The in-game **Mods** menu lists the folders, shows `desc.txt` as the description (the whole file, read with `io.readfile` in `ui_scripts/Mods/ModSelectMenu.lua`), sets `fs_game` to `mods/<name>`, and runs `vid_restart`.
- From the command line: `iw7-mod.exe +set fs_game "mods/<name>"`.
- Optional `mod.ff`, `mod.sabs`, and `mod.sabl` (custom fastfile and sound banks) are loaded from the mod folder.
- Servers advertise `fs_game`, which **must** start with `mods/` and contain no `.` or `::`.
- **Joining a host with `fs_game` set.** The server's `getInfo` reply carries `fs_game` and, for each of `mod.ff` / `mod.sabl` / `mod.sabs` in that folder, a hash (`mod_hash`, `sabl_hash`, `sabs_hash`; empty when the file is missing, `utils::hash::get_file_hash`). The joining client (`check_download_mod`) requires `mod_hash`: if it is empty, the join stops with "Server 'mod_hash' is empty". If the client's own `mod.ff` differs, the client downloads it from `sv_wwwBaseUrl`. Otherwise it switches its `fs_game` to the server's and restarts (`vid_restart`). A host without `fs_game` makes a client that has one drop it (`set_mod("")`). The same at v1.1.0 and develop. So a script-only mod in `mods/` cannot be joined; installed into `<game>/iw7-mod/`, it leaves `fs_game` empty (KNOWN_LIMITATIONS.md L30).
- The generic docs show `mods/<name>/scripts/`. For IW7 the loader scans **`custom_scripts/`**; follow the code.

## 4. Compiler compatibility (v1.1.0 vs develop) `[TOOL-R]` `[TOOL-D]` `[COMPILED]`

The two compilers iw7-mod ships resolve built-in names differently.

| Table | Functions named | Methods named | Methods unnamed (`_meth_XXXX`) |
|-------|-----------------|---------------|-------------------------------|
| v1.1.0 (`833822d0`) | 723 + 58 stubs | 848 + 25 stubs | 610 |
| develop (`0be361a4`) | 727 + 58 stubs | 1344 + 50 stubs | 89 |

### 4.1 Mislabeled names in v1.1.0

These were verified by compiling with both compilers and disassembling with the develop table:

| Source written | v1.1.0 actually calls | develop calls | Portable form |
|----------------|-----------------------|---------------|---------------|
| `self disableinvulnerability()` | **`disablegrenadetouchdamage`** (0x80A0) | `disableinvulnerability` (0x80A1) | `self _meth_80A1()` |
| `self playlocalsound(a)` | **`playercommandbot`** (0x8230) | `playlocalsound` (0x8242) | `self _meth_8242(a)` |
| `self getweaponslistall()` | correct (0x8173; the duplicate entry is ignored) | 0x8173 | name is OK |
| `self isreloading()` | correct (0x81B8; the duplicate entry is ignored) | 0x81B8 | name is OK |

### 4.2 Develop-only names

**503 method names and 5 function names** fail to compile by name on v1.1.0 (`couldn't determine function call type`). The raw-id form compiles to the same native on both compilers `[COMPILED]` (for example `self _meth_845E(1)` becomes `setcamerathirdperson` on both). The ones relevant to this project:

| Name (develop) | Raw id | Stock usage `[DUMP]` | Notes |
|----------------|--------|----------------------|-------|
| `setcamerathirdperson(bool)` | `_meth_845E` | yes (`mp/supers/super_reaper.gsc`) | Per-player third person |
| `setfiretimescaleon(pct)` | `_meth_85C1` | yes (`cp_weaponpassives.gsc`, value 65) | Fire time as a % of normal; lower is faster |
| `setfiretimescaleoff()` | `_meth_85C2` | yes | |
| `getfiretimescale()` | `_meth_85C3` | no | |
| `player_getrecoilscale()` | `_meth_85C0` | yes (returns < 0 when unset; treat that as 100) | |
| `player_recoilscaleoff()` | `_meth_822C` | yes | `player_recoilscaleon(int 0–100)` is fine by name |
| `resetspreadoverride()` | `_meth_8263` | no | `setspreadoverride` is fine by name |
| `hasperk(name)` | `_meth_8181` | – | `setperk`/`unsetperk` are fine by name |
| `setnormalhealth(f)` / `getnormalhealth()` | `_meth_8319` / `_meth_814A` | no | |
| `jumpbuttonpressed()` | `_meth_81CE` | – | |
| `sprintbuttonpressed()` | `_meth_8439` | – | |
| `crouchbuttonpressed()` | `_meth_843B` | – | |
| `nightvisionviewon()` / `off()` | `_meth_821A` / `_meth_8219` | no | NEEDS TESTING |
| `enablequickweaponswitch()` | `_meth_84AF` | no | NEEDS TESTING |
| `scriptmoveroutline()` / `scriptmoverclearoutline()` | `_meth_8549` / `_meth_854A` | yes | Outline on script movers |
| `pingplayer()` | `_meth_8229` | no | NEEDS TESTING |
| `isfiring()` | `_meth_819F` | – | |
| `getcommandfromkey(key)` (function) | `_func_082` | – | |

**Rule:** a raw id must be wrapped in a named helper inside the project's compatibility module, with a comment giving the real name. The build check (section 13) compiles every script with both compilers and diffs the disassembly.

### 4.3 Release stubs (`nullptr` natives; calling them is a runtime error)

The tables mark these `// nullptr`: the exe has no function for the id. iw7-mod checks for this and raises `builtin function "x" doesn't exist` (or `builtin method …`), which is printed even without `developer_script` `[MOD script_extension.cpp]`. `tools/check.py` rejects calls to them.

Debug drawing: `line`, `sphere`, `box`, `cylinder`, `orientedbox`, `print3d`, `printtoscreen2d`.
Native file I/O: `openfile`, `closefile`, `fprintln`, `freadln`, `fgetarg`, `fprintfields`.
Also: `adddebugcommand`, `setdebugorigin`, `setdebugangles`, `drawsoundshape`, `perlinnoise2d`, `logstring`, and others.
Methods relevant to planned features: `noclip`, `ufo`, `allowhighjump`, `allowboostjump`, `setdevtext`, `clearalltextafterhudelem`, `openmenu`, `closemenu`, `openpopupmenu`, and `isagent` as a **method** (the function `isagent(ent)` is available).
(`logprint` is a native stub, but iw7-mod re-implements it, so it works.) `[TOOL-D]`

## 5. Callbacks and notifies

### 5.1 Level / player lifecycle `[DUMP cp_globallogic.gsc, mp/playerlogic.gsc]`

| Event | How | Modes |
|-------|-----|-------|
| Player connected | `level waittill("connected", player)` | MP, CP |
| Player spawned | `self waittill("spawned_player")`; `level waittill("player_spawned", player)` | MP, CP |
| Disconnect | `self waittill("disconnect")` | all |
| Death | `self waittill("death")` | all |
| Game end | `level waittill("game_ended")` | all |
| Faux spawn (MP) | `"faux_spawn"` (used by iw7-mod `inspect.gsc`) | MP |
| Last stand (CP) | `self waittill("last_stand")` | CP |
| Chat | `level waittill("say", player, msg)` / `self waittill("say", msg)`, plus `say_team` | all, iw7-mod v1.0.3+ `[MOD logprint.cpp]` |
| LUI → server | `self waittill("luinotifyserver", name, value)` | all |

Ordering and helper traps `[DUMP]`:

- **CP connect → spawn.** `cp_globallogic::defaultplayerconnect` notifies `connected`, runs a `waittillframeend`, then calls `spawnplayer()`, which notifies `spawned_player`. A spawn watcher started on `connected` therefore sees the first spawn.
- **Not every handler of `connected` runs before that spawn.** In the second in-game report (2026-10-06) the character pick ran from a thread woken by a second notify (`ix_player_connected`, sent by a thread `connected` woke) and arrived after `spawnplayer()` had run the loadout: the player card showed the pick, the models were the stock pick's (`KNOWN_LIMITATIONS.md` L36). Wrapping `level.custom_giveloadout` (which `spawnplayer_actual()` calls on every spawn; `zombie.gsc:24` sets it in the gametype's `main()`) did not hold either: in the third in-game report the pick was still not applied. A wrapper installed from `init()` depends on when the gametype's `main()` runs, and `init()` runs before the map's `main()` (§2). What holds is replacing the stock function that makes the decision with `replacefunc` (§11), so the decision is made whenever the stock code asks for it.
- **Map callbacks are set synchronously.** The `main()` of `cp_disco`, `cp_final`, `cp_rave`, `cp_town`, and `cp_zmb` contains no wait, and the four maps that override `level.callbackplayerdamage` do it there (`cp_disco.gsc:54`, `cp_final.gsc:90`, `cp_rave.gsc:52`, `cp_town.gsc:53`). They are set before the first player connects.
- **`scripts\engine\utility::waittill_any(a, b, …)`** puts `endon(b)`, `endon(c)`, … on the **calling** thread, so any notify but the first ends the caller. `waittill_any_return(…)` adds `endon("death")` to the caller unless `"death"` is one of its arguments. Long-lived watchers use one thread per notify instead.

### 5.2 Engine player notifies seen in stock scripts `[DUMP]`

`weapon_change`, `weapon_fired`, `reload`, `reload_start`, `grenade_fire`, `grenade_pullback`, `offhand_fired`, `melee_fired`, `missile_fire`, `sprint_begin`, `sprint_slide_begin`, `sprint_slide_end`, `damage`, `death`, `spawned_player`, `joined_team`, `joined_spectators`, `bulletwhizby`, `begin_firing`, `healed`.

### 5.3 Code callbacks `[DUMP mp/callbacksetup.gsc]`

- `level.callbackplayerdamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, a10, a11)`, 12 args. In CP it is set by the gametype (`zombie_damage::callback_zombieplayerdamage`) and **overridden by `cp_town`, `cp_rave`, `cp_disco`, and `cp_final`**.
- `level.callbackplayerkilled`, `level.callbackplayerconnect`, `level.callbackplayerdisconnect`, `level.callbackplayerlaststand` (CP), `level.callbackfinishweaponchange` (when defined).
- Agents: `codecallback_agentdamaged` calls `self [[ level.agentfunc ]]("on_damaged")`, which reads `level.agent_funcs[agent_type]["on_damaged"]`. The same pattern applies to `"on_killed"`. Maps override these per type (`generic_zombie`, `zombie_brute`, `c6`, `the_hoff`, `slasher`, `skeleton`, `ratking`, `zombie_sasquatch`).
- Wrapping pattern: store the original pointer, install a wrapper that adjusts arguments, and call the original. Do this **after** map scripts have run (section 2, ordering).

## 6. Zombies (CP) internals `[DUMP]`

| Need | Verified API |
|------|--------------|
| Current round | `level.wave_num` (also pushed to the HUD with `player setclientomnvar("zombie_wave_number", n)`) |
| Round start | `level waittill("regular_wave_starting")`; special waves fire `"event_wave_starting"` |
| Round end | `level waittill("spawn_wave_done")`; each player also gets `self notify("next_wave_notify")` |
| Remaining this wave | `level.desired_enemy_deaths_this_wave - level.current_enemy_deaths` |
| Alive now | `level.current_num_spawned_enemies`; `scripts\cp\cp_agent_utils::getaliveagents()`; `getactiveagentsoftype(type)`; `getaliveagentsofteam(team)`; `level.agentarray` |
| Spawn cap | `level.max_static_spawned_enemies` (stock sets 24 at wave start) |
| Zombie health | per-map `calculatezombiehealth(...)` in `zombies_spawning`, `cp_rave_spawning`, `cp_disco_spawning`, `cp_town_spawning`, `cp_final_spawning`; `level.zombie_health_func` (`cp_final`); `self.maxhealth`/`self.health` |
| Zombie speed | `self.movemode` ∈ {`slow_walk`,`walk`,`run`,`sprint`} chosen by `calulatezombiemovemode()` (sic); per-type override hook `level.movemodefunc[agent_type]` (re-evaluated in the agent loop); `self.moveratescale` (stock speed-up uses 1.15) |
| Zombie spawned | `level notify("agent_spawned", ...)` occurs in stock spawning |
| Currency | `scripts\cp\cp_persistence::get_player_currency()`, `set_player_currency(n)`, `give_player_currency(n, …)`, `take_player_currency(n, …)`, `get_player_max_currency()` |
| Power-ups | `scripts\cp\loot::drop_loot(origin, player, contentRef, …)`, 6 params. `origin` is snapped with `getclosestpointonnavmesh`, and `contentRef == "none"` returns 0. Refs found in stock CP scripts (`loot.gsc`, `zombies_consumables.gsc`, `zombies_pillage.gsc`): `instakill_30`, `kill_50`, `ammo_max`, `fire_30`, `infinite_20`, `grenade_30`, `cash_2`, `board_windows` |
| Spawning agents | `scripts\mp\mp_agent::spawnnewagent(...)` (6 params), `spawn_scripted_agent(...)`, `spawn_regular_agent(...)` (argument semantics must be read before use) |
| Restart | console commands `map_restart` / `fast_restart` exist (iw7-mod `party.cpp` executes and patches them); run from GSC with `executecommand(...)`; the function `map_restart(...)` also exists |
| Perks | `scripts\cp\zombies\zombies_perk_machines::give_zombies_perk(perk, a1)` / `give_zombies_perk_immediate` / `take_zombies_perk(perk)`; `scripts\cp\utility::has_zombie_perk(perk)`. Perk refs seen in `[DUMP]`: `perk_machine_{revive,tough,run,flash,more,rat_a_tat,deadeye,change,boom,smack,fwoosh,zap}` (`*_sign`, `_used`, `_deny`, `_remove_perk` are not perks) |
| Outlines | `scripts\cp\cp_outline::enable_outline_for_players / disable_outline_for_players` |
| Weapon naming | `iw7_<name>_zm` (upgraded variants appear as `…_zmr`/`…_zml`); melee e.g. `iw7_knife_zm_*`; attachments with `+` |
| Solo check | `scripts\cp\utility::isplayingsolo()`; `getmaxclients()` |

## 7. HUD elements `[TOOL-R/D]` `[DUMP]`

- Create: `newclienthudelem(player)`, `newhudelem()`, or `newteamhudelem(team)`.
- Methods (all named in both tables): `settext`, `setvalue`, `settimer`, `setshader`, `fadeovertime`, `moveovertime`, `scaleovertime`, `changefontscaleovertime`, `setpulsefx`, `destroy`.
- Fields (all in the token table): `x y alignx aligny horzalign vertalign font fontscale color alpha label sort foreground archived hidewheninmenu hidewhendead showinkillcam glowcolor glowalpha elemtype`.
  - `hidewheninkillcam` is **not** a token. Do not use it.
- Values seen in stock: fonts `default`, `bigfixed`, `objective`; `horzalign`/`vertalign` `fullscreen`, `left`, `center`, `top`, `middle`, `bottom` (`right` is assumed, NEEDS TESTING).
- Both CP and MP set `level.uiparent` and `level.fontheight = 12`, but `scripts\mp\hud_util` (`createfontstring`, …) is **not linked on any zombies map**, so a far call to it risks a script link error (§2). The project sets HUD fields directly.
- `clearalltextafterhudelem` is a **stub**. The classic configstring-overflow workaround is unavailable. Prefer `setvalue` for numbers and a small, fixed set of strings (risk: NEEDS TESTING).
- Scripts may keep their own fields on a HUD element: the stock `scripts\cp\utility::createbar` sets `.frac`, `.shader` and `.hidden` on one.

## 8. Input `[DUMP]` `[TOOL-R/D]`

- `self notifyonplayercommand(notifyName, command)`. The registration persists for the player, so call it once per player.
- IW7 command strings seen in stock: `+attack`, `+attack_akimbo_accessible`, `+speed_throw` (ADS hold), `+toggleads_throw`, `+ads_akimbo_accessible`, `+usereload`, `+activate`, `+melee_zoom`, `+frag`, `+smoke`, `+stance`, `+goStand`, `+breath_sprint`, `+weapnext`, `+togglecrouch`, `+prone`, `+movedown`, `+actionslot 1`…`+actionslot 8`, plus `-` release variants.
  - Accessibility binds use the `_akimbo_accessible` variants. Register **both** forms.
- **CP action-slot usage** (do not bind menu controls here):
  - 1–2: Fate & Fortune cards (`zombies_consumables.gsc`)
  - 3: crafted items and traps
  - 4: quests / kung-fu mode
  - 5–7: crafted-item controls
  - 8: iw7-mod weapon inspect (`custom_scripts/cp_mp/inspect.gsc`)
- Polling (named in both tables): `usebuttonpressed`, `attackbuttonpressed`, `adsbuttonpressed`, `meleebuttonpressed`, `fragbuttonpressed`, `secondaryoffhandbuttonpressed`. `jump`/`sprint`/`crouch` polling is develop-only (section 4.2).
- **A working IW7 zombies menu** (Synergy, S8) polls these every 0.05 s: ADS + Melee opens; Melee goes back; ADS or Fire (one, not both) scrolls; Frag or Tactical changes a value; Use selects; each waits for the button's release. The mod's menu reads the same buttons the same way (`ix\ui\menu`, Phase 3).
- **Buttons are read while weapons are off.** `scripts\cp\powers\coop_powers::reset_grenades()` disables offhand weapons, then waits on `fragbuttonpressed()` until the player lets go `[DUMP]`. The other buttons with weapons, melee and Use off: **NEEDS TESTING** (R-M2).
- **Counted locks** `[DUMP scripts\engine\utility.gsc]`: `allow_weapon(b)`, `allow_offhand_weapons(b)`, `allow_melee(b)` and `allow_usability(b)` keep a per-player count (`self.disabledweapon`, `disabledoffhandweapons`, `disabledmelee`, `disabledusability`) and call `enableweapons()` / `enableoffhandweapons()` / `allowmelee(1)` / `enableusability()` only when it is back at 0; stock zombies scripts use them (the crafted traps). A script that disables through them never re-enables what another part of the game disabled. `scripts\engine\utility` is linked on every zombies map (`check.py` `calls`).

## 9. Player, movement, and physics

| Need | API | Scope |
|------|-----|-------|
| Speed (per player) | `setmovespeedscale(f)` (stock uses it, e.g. `1`) | per player |
| Speed (global) | dvar `g_speed` (default 190; iw7-mod made it script-settable and replicated) `[MOD gameplay.cpp]` | global |
| Gravity | dvar `bg_gravity` (default 800, range **1–1000**, replicated) `[MOD]` | global |
| Fall damage | dvar `jump_enableFallDamage` (bool) `[MOD]` | global |
| Mantle | `mantle_legacy`, `mantle_legacyMaxAngle` (0–90, IW6 60), `mantle_legacyReach` (16–128, IW6 54.9) `[MOD]` | global |
| Bounces | `bg_bounces`, `bg_bounceMinFallSpeed` (0–1000) `[MOD]` | global |
| Player ejection (collision) | `bg_playerEjection` (bool) `[MOD]` | global |
| Omni-movement / unlimited sprint / air control | `bg_omnimovement`, `bg_sprintUnlimited`, `bg_airControl` (0–100). **develop only**: feature-detect with `getdvar(n) != ""` `[MOD develop]` | global |
| Ability toggles | `allowjump`, `allowsprint`, `allowslide`, `allowwallrun`, `allowdoublejump`, `allowmantle`, `allowprone`, `allowcrouch`, `allowstand`, `allowads`, `allowfire`, `allowmelee` | per player |
| Boost energy | `energy_setmax`, `energy_getmax`, `energy_setrestorerate` | per player |
| Velocity / position | `getvelocity`, `setvelocity`, `isonground`, `isonladder`, `ismantling`, `iswallrunning`, `setorigin`, `setplayerangles`, `getplayerangles`, `getstance`, `setstance` | per player |
| Control | `freezecontrols(b)`, `playerlinkto(ent)`, `unlink()`, `disableweapons()`, `enableweapons()` | per player |
| Third person | `_meth_845E` (`setcamerathirdperson`); or client dvar `cg_thirdPerson` (CHEAT, client-only, not on dedicated) plus `cg_thirdPersonAngle` / `cg_thirdPersonRange` `[MOD thirdperson.cpp]` | per player / host |
| FOV (client prefs) | `cg_fov` (1–160), `cg_fovScale` (0.1–2), `cg_fovMin` (saved client dvars) `[MOD fov.cpp]` | client |
| Timescale | `setslowmotion(...)` (iw7-mod) or dvar `timescale` (0.001–1000, CHEAT, replicated) `[MOD timescale.cpp]` | global |
| Viewmodel offset | `cg_gun_x/y/z` (client) `[MOD]` | client |

## 10. Weapons and damage

- **Inventory** (named in both tables): `giveweapon`, `takeweapon`, `takeallweapons`, `switchtoweapon`, `switchtoweaponimmediate`, `getcurrentweapon`, `getcurrentprimaryweapon`, `getweaponslistall`, `getweaponslistprimaries`, `getweaponslistoffhands`, `hasweapon`, `getcurrentoffhand`.
- **Ammo:** `setweaponammoclip`, `setweaponammostock`, `getweaponammoclip`, `getweaponammostock`, `givemaxammo`, `givestartammo`. Info functions: `weaponclipsize`, `weaponmaxammo`, `weaponstartammo`, `weaponclass`, `weapontype`, `weaponfiretime`, `weaponinventorytype`, `getweaponbasename`, `getweaponattachments`, `weaponaltweaponname`.
- **Infinite clip (global):** dvar `player_sustainAmmo` (bool, replicated) `[MOD gameplay.cpp]`.
- **Fire rate:** `_meth_85C1(pct)` / `_meth_85C2()` (section 4.2).
  - Recoil: `player_recoilscaleon(0–100)` and `_meth_822C()`.
  - Spread: `setspreadoverride(n)` and `_meth_8263()`.
  - Kick: `setviewkickscale(f)`.
- **Health:**
  - Invulnerability: `enableinvulnerability()` and **`_meth_80A1()`** (disable).
  - Damage and death: `dodamage(...)`, `suicide()`.
  - Fields: `self.health` / `self.maxhealth`.
  - Perks: `setperk` / `unsetperk` / `_meth_8181` (hasperk).
- **Damage modification:** via callback wrappers (section 5.3).
- `iw7-mod`'s `setWeaponFieldFloat/Int/Bool` console commands exist **only in `_DEBUG` builds**, so they are not available to players. `[MOD weapon.cpp]`
- Weapon inspect: `startweaponinspection()` / `isinspectingweapon()` (iw7-mod). Bound by iw7-mod to `+actionslot 8` in MP and CP.

## 11. Dvars, files, misc

- **Dvar access:** `getdvar`, `getdvarint`, `getdvarfloat`, `getdvarvector`, `setdvar`, `setdvarifuninitialized`, `setclientdvar(s)` (methods).
  - GSC sets use source `DVAR_SOURCE_SCRIPT`, which iw7-mod's cheat/replicated/read-only checks **do not block** (only `EXTERNAL`, the console, is checked). Read-only/write-protected flags are still enforced. `[MOD dvar_cheats.cpp]`
  - IW7 hashes dvar names, so a typo silently creates or reads a different dvar. Use only names that are verified (stock usage list, iw7-mod registrations) or created by this mod (`ix_*`).
  - Detecting a dvar that may not exist: compare `getdvar(name) == ""`. Stock scripts use this idiom 22 times for usually-unset dvars, e.g. `common/fx.gsc` (`createfx`) and `cp_disco_interactions.gsc` (`scr_nunchucks`).
  - Unverified names are UNKNOWN: `jump_height`, `cg_drawfps`, `player_sprintSpeedScale`.
  - Stock dvars useful here: `scr_team_fftype`, `scr_player_maxhealth`, `scr_player_healthregentime`, `g_gametype`, `ui_gametype`, `mapname`, `cg_draw2d`, `cg_drawcrosshair`.
- **File I/O (iw7-mod `io.cpp`):** `fileexists(p)`, `readfile(p)`, `writefile(p, data[, append])`, `filesize`, `createdirectory`, `directoryexists`, `directoryisempty`, `listfiles`, `copyfolder`, `removefile`.
  - Paths are **relative to `fs_game`**, and the call **throws** `"fs_game is not properly defined"` when no mod is loaded.
  - `..` is rejected. The `-allow_root_io` launch flag switches the base to `fs_basepath`.
- **Script control (iw7-mod):**
  - `replacefunc(old, new)` detours a script function. From then on, for the rest of the level load, every call of `old` runs `new` with the same `self` and arguments: iw7-mod checks each code position the VM is about to execute and jumps to `new` at `old`'s start (`vm_execute_stub`, `gsc/script_extension.cpp`, v1.1.0). The table is cleared when scripts are freed. `old` itself can no longer be called, not even from `new`, so a replacement must do the original's work itself. iw7-mod's own `custom_scripts/cp/patches.gsc` calls it in `main()`. The mod replaces `zombies_loadout::get_player_character_num` while the level loads (`ix/player/character.gsc` `register()`), long before the first spawn.
  - `getfunction("path/to/script", "name")` returns a pointer and throws if the function is not loaded.
  - `executecommand("cmd")` runs a console command.
- **Strings and output (iw7-mod):** `print`/`println` (console), `logprint`, `va("…%s…", …)`, `typeof`/`type`, `toupper`, `strstartswith`.
- **Chat (iw7-mod):** `say(msg)` (to all), `player tell(msg)`.
- **Entities and markers** (named in both tables): `spawn("script_model", origin)`, `setmodel`, `moveto`, `rotateto`, `delete`, `hide`, `show`, `linkto`, `playerlinkto`, `dropitem`. HUD waypoints: `setwaypoint`, `settargetent` (for overhead markers and health bars; NEEDS TESTING). `cloneplayer` is develop-only (`_meth_8086`).
- **More verified dvars:**
  - `debug_pause_spawning` (stock CP scripts read it; release behaviour NEEDS TESTING).
  - `cg_unlimited_cards` (iw7-mod v1.0.4+, unlimited Fate & Fortune cards) `[DOCS iw7-changelog]`.
  - `cg_draw2d` (stock).
- **Stock helpers:**
  - `iprintln` / `iprintlnbold` (function and method), `map_restart`, `exitlevel`, `setslowmotion`.
  - Vision: `visionsetnaked`, `visionsetnakedforplayer` (method).
  - Traces: `bullettrace`, `bullettracepassed`, `sighttracepassed`, `physicstrace`, `playerphysicstrace`.
  - Arrays and structs: `getentarray`, `spawnstruct`.
  - Random: `randomint`, `randomfloat`, `randomintrange`, `randomfloatrange`.
  - Strings: `strtok`, `issubstr`, `getsubstr`, `tolower`.
  - Time: `gettime`.
- **LUI bridge:**
  - Client Lua calls `Engine.NotifyServer(name, intValue)`; GSC receives `self waittill("luinotifyserver", name, value)`.
  - GSC calls `setclientomnvar(name, v)`; Lua reads `Game.GetOmnvar(name)`, for **predefined omnvars only**.
  - Lua UI scripts load from `ui_scripts/<Folder>/__init__.lua` (also inside the active mod folder). The Lua `io` table provides `fileexists`, `directoryexists`, `listfiles`, `readfile`, and `zoneexists`, with **no write**. `[MOD ui_scripting.cpp]`

## 12. Verification rule for new APIs

Before using any built-in, field, notify, dvar, or stock function:

1. **Built-ins:** the name must be in the **v1.1.0** table as `available` and map to the same id as develop. Otherwise use the raw id through the compatibility module.
2. **Stock script functions and far calls** must exist in `[DUMP]` with that exact path and name.
3. **Stock fields** must be spelled exactly as in `[DUMP]`, including `_id_XXXX` hashes.
4. **Dvars** must come from stock usage, an iw7-mod registration, or this mod's own `ix_*` namespace.
5. **Runtime behaviour** that cannot be checked statically is marked **NEEDS TESTING** in `FEATURE_STATUS.md` until a tester confirms it.

Rules 1 and 2 are enforced by `tools/check.py` (`compile`, `parity`, `natives`, `calls`).

## 13. Offline toolchain (see `tools/README.md`)

- `tools/setup_compilers.sh` builds both compilers (`gsc-tool-iw7-release` at `833822d0`, `gsc-tool-iw7-develop` at `0be361a4`), `ixcc` on top of each (it compiles with iw7-mod's extension built-ins registered), and fetches the stock dump.
- `python3 tools/check.py` runs every static check on the mod. `python3 -m unittest discover -s tools/tests` tests the checker.
- Disassemble: `gsc-tool -m disasm -g iw7 -s pc <file.gscbin | dir>`. Ids that neither table names print as `_func_%04X` / `_meth_%04X`.
- Table ranges (develop): functions `0x001`–`0x326`, methods `0x8000`–`0x85CA`. `0x85CB` is unused, and iw7-mod's extension methods start at `0x85CC`.
- Verified error behaviour:
  - an unknown built-in gives `couldn't determine function call type`;
  - a syntax error gives `expected ';'…` (develop) or `syntax error, unexpected …` (v1.1.0);
  - a function named after a built-in gives `function name 'x' already defined as builtin`;
  - an unknown raw id (`_meth_85CB`) compiles **without** an error;
  - a `//` comment that ends in a backslash swallows the next line, silently, on both compilers.

## 14. Launching, logs, and quitting (for unattended test runs) `[MOD]` `[DOCS]`

Read from the source; none of it has been run yet. Line numbers are the same at v1.1.0 and develop unless noted.

- **No launcher.** The client starts the game directly (`main.cpp`). `-dedicated` is the only environment switch. `-zombies` / `-cpMode` select zombies **only on a dedicated server** (`dedicated.cpp:433-443`). The console commands `cpMode`, `mpMode`, and `spMode` set the desired mode (`command.cpp:460-478`).
- **Command line.** It is parsed Quake3-style: split at each `+`, with text before the first `+` dropped (`command.cpp:71-110`). `+set <dvar> <value>` is applied at startup, or when the dvar is registered (`command.cpp:112-143`). `-flags` can appear anywhere, but `map` / `devmap` ignore the command unless it has exactly 2 arguments (`party.cpp:1099-1102`, `1133-1136`), so every `-flag` goes **before** the first `+`.
- **`+map` / `+devmap cp_zmb`.** These choose the mode from the `cp_` prefix while online data is still syncing (`party.cpp:827-858`). `devmap` sets `sv_cheats 1` and exists on the client only. Whether a normal client started this way ends up in zombies **NEEDS TESTING**; the fallbacks are `+cpMode` before `+devmap`, or `-dedicated -zombies +map cp_zmb`.
- **Unattended start.** `-nointro` skips the intro video (`intro.cpp:17-29`). `-noupdate` skips the updater, which can otherwise relaunch the exe (`iw7-update.md`). Steam must be running, or the client shows a message box and exits (`steam_proxy.cpp:187-211`).
- **Console log.** `g_consoleLog` defaults to `iw7-mod/logs/console.log`. Each line is appended and the file closed again, so it is effectively flushed; the file is never truncated. It is registered on the first frame, so the earliest startup lines are missing. **`-noconsole` disables it entirely** (`console.cpp:131-132`, `197-218`).
- **Quitting from GSC.** `executecommand("quit")` queues `quit` for the next frame (`script_extension.cpp:422-426`, `command.cpp:450-453`). GSC cannot set the exit code.
- **Writing a result file.** `writefile(path, data[, append])` writes under `<game>/<fs_game>/`, rejects `..`, and throws when `fs_game` is empty (`io.cpp:24-95`).

## 15. Zombies characters `[DUMP]` `[MOD stats.cpp]`

- **Registration.** Each map's `scripts\cp\maps\<map>\<map>_player_character_setup::init_player_characters()` runs synchronously from the map's `main()`. It fills `level.player_character_info[slot]` with a struct holding `body_model`, `view_model`, `head_model`, `hair_model`, `vo_prefix`, `vo_suffix`, gestures, `photo_index`, `fate_card_weapon`, `intro_music`, `intro_gesture`, `melee_weapon`, `starting_weapon` and `post_setup_func`. Slots registered `"yes"` go into `level.available_player_characters`.
  - Slots 1–4 (`"yes"`) are the regular characters on every map. The slot-to-actor mapping is the same everywhere: `p1_` Sally, `p2_` Poindexter ("pdex"), `p3_` Andre, `p4_` A.J. (VO switch in `cp_disco_vo.gsc` and `cp_town_vo.gsc`; `cp_final` model names `sally` / `dexter` / `andre` / `aj`).
  - Special characters (`"no"`): `cp_zmb` 5 The Hoff and 6 Willard Wyler; `cp_rave` 5 Kevin Smith; `cp_disco` 5 Pam Grier; `cp_town` 5 Elvira; `cp_final` none. Each special's models are referenced only by its own map's script.
- **Assignment.** `zombies_loadout::get_player_character_num()` returns `self.player_character_num` if it is set. Otherwise it uses the lobby's `getrankedplayerdata("cp", "zombiePlayerLoadout", "characterSelect")` on the special's own map (`cp_zmb`: 1 The Hoff, 5 Willard; `cp_rave` 2; `cp_disco` 3; `cp_town` 4; reset to 0 after use), or a random free slot.
- **Applying.** `spawnplayer()` runs `level.custom_giveloadout` (`givedefaultloadout`) on **every** spawn. That function calls `detachall`, then `setmodelfromcustomization(num)`, which sets the fields, models and photo and runs `post_setup_func`. After the first spawn, the knife comes from `self.default_starting_melee_weapon`.
- **Release.** On disconnect, `release_character_number()` returns every slot except 5 and 6 to the pool.
- **Lobby field.** `characterSelect` is part of each player's own coop stats, and the server reads it per player with `getrankedplayerdata`. The stock code honours it only on the special's own map and only for the values above. It checks neither the unlock nor whether another player already has that special. It clears the field with `setplayerdata` after use. The frontend can write the field with the console command `setCoopPlayerData zombiePlayerLoadout characterSelect <n>`, then `uploadstats`. iw7-mod writes coop stats that way itself (`stats.cpp`: `setCoopPlayerData haveSoulKeys soul_key_1 1`, `setCoopPlayerData dc <n>`). The field's type and range are not known (no DDL offline). iw7-mod re-enables `Com_DDL_PrintState`, which its source labels "GetPlayerData print", so a console getter can show stored values (R-CH12).
- **HUD portrait.** `setplayerinside()` writes `photo_index` into omnvar `zm_player_character` (3 bits per entity number 0–3); `zm_player_status` holds healthy, damaged, laststand or afterlife. The client UI draws the picture, and its image names are not visible to scripts.
- **The HUD draws Shaolin Shuffle's main cards twice as wide as high** `[STOCK UI]`: `MainPlayerInfoDLC2` (`ui/ingame/cp/mainplayerinfodlc2.lua`) puts `zm_main_plyr_N_dlc2` in a 512 × 256 element (scale −0.42), while the other maps' main cards are tall (256 × 371) and team cards square (`cpplayerinfo.lua`, 128 × 128). Pam Grier's only card is one of these New York ID cards.
- **HUD cards as materials** `[LISTING]` `[TOOL-R/D]` `[DUMP]`. Every card the portrait uses is also a *material* of the same name in the map's `techsets_<map>` zone, which loads with each match on that map, for every player; the images are in the map's own zones. `cp_zmb`: `zm_pc_score_main_plyr_N` and `zm_pc_score_team_plyr_N` for slots 1–5, Willard `zm_main_plyr_6_dlc4` / `zm_team_plyr_6_dlc4` (images in `patch_cp_zmb`); the other maps `zm_main_plyr_N_dlcK` / `zm_team_plyr_N_dlcK` with K = 1 `cp_rave`, 2 `cp_disco`, 3 `cp_town` (Elvira's main image in `eng_cp_town`), 4 `cp_final` (slots 1–4). All 50 names checked in the listing (`TESTING.md` V74). GSC can draw them with `setshader` on a HUD element; `precacheshader` is function `0x187` in both compilers' tables. Stock zombies scripts call `setshader` without precaching (`progress_bar_fill` in `scripts\cp\utility.gsc`, `waypoint_blitz_goal` in `escape.gsc`), while multiplayer gametypes precache during load (`mugger.gsc`); the mod precaches while the level loads, in a thread of its own. Whether the card draws correctly is **NEEDS TESTING** (R-CH9).
- **Unlocks** `[STOCK UI]`. The stock lobby's rules, read from its compiled UI script (§16): it sets `characterSelect` only when `ui_mapname` is the special's map and the player has its soul key (The Hoff `soul_key_1` → 1, Kevin Smith `soul_key_2` → 2, Pam Grier `soul_key_3` → 3, Elvira `soul_key_4` → 4), and for Willard Wyler (5, `cp_zmb`) when Director's Cut is on, `meritState mt_dlc4_troll2` ≥ 1 (`CONDITIONS.HasBeatenMeph`) and `soul_key_5` are all true. It reads them with `Engine.GetPlayerDataEx(controller, CoD.StatsGroup.Coop, "haveSoulKeys", "soul_key_N")`. Where the stats come from:
  - Each map's final Easter-egg boss sets `setplayerdata("cp", "haveSoulKeys", "soul_key_N", 1)`, with N = 1 `cp_zmb`, 2 `cp_rave`, 3 `cp_disco`, 4 `cp_town`, 5 `cp_final` (`cp_zmb_ufo.gsc:1062`, `cp_rave_super_slasher_fight.gsc`, `rat_king_fight.gsc`, `cp_town_crab_boss_bomb.gsc`, `cp_final_rhino_boss.gsc`; `directors_cut::get_num_of_newbs_in_game`).
  - iw7-mod's `unlockallEE` sets the soul keys ("secret characters") and `meritState mt_dlc4_troll2` ("secret character 5 on cp_zmb", `Conditions.HasBeatenMeph`).
  - The lobby UI confirms which key unlocks which character (`KNOWN_LIMITATIONS.md` L27). Director's Cut itself also needs `soul_key_5` (`directors_cut.gsc:485`).
- **The stock lobby clears the field** `[STOCK UI]`. Each time `CPPrivateMatchMenu` is built, its post-load function calls `ACTIONS.CharacterSelect(menu, controller, 0)`, which is `Engine.SetPlayerDataEx(controller, CoD.StatsGroup.Coop, "zombiePlayerLoadout", "characterSelect", 0)` (`ui/uieditor/actions.lua`). A special character is picked again in the lobby each time: the stock game does it with a hidden button combination (`LUI.UIButtonCombination`), this mod with the CHARACTER button, which also writes the saved pick back when the lobby opens.
- **Player state.** `self.inlaststand`, `self.in_afterlife_arcade` (`cp_zmb`), and `self.sessionstate`.
- **HUD space.** `horzalign` / `vertalign` `"fullscreen"` uses a 640 × 480 virtual screen (stock full-screen overlays use `setshader("black", 640, 480)` at 0, 0). Stock zombies scripts use the materials `"black"` and `"white"`, the fonts `"default"` and `"objective"`, and `fontscale` 1.
- **Chat.** iw7-mod sends `level notify("say", player, text)` and `player notify("say", text)`, plus `"say_team"`, with the leading control character removed (`logprint.cpp`).

## 16. Lua UI scripts (menus) `[MOD ui_scripting.cpp, data/cdata/ui_scripts]`

- **Loading.**
  - When the Lua VM starts (frontend and in-game), iw7-mod lists `ui_scripts/` across the search paths in their order: `<game>/iw7-mod/`, then the client data folder (iw7-mod's own scripts), then the engine's paths, which include a Mods-menu folder.
  - It runs `ui_scripts/<Folder>/__init__.lua` for each folder. A folder name already found in an earlier path is **skipped**, so a mod folder named like one of iw7-mod's never loads (`list_files(..., true)` in `load_scripts`).
  - Scripts test `Engine.InFrontend()` themselves.
  - **Load order depends on the install.** Scripts in `<game>/iw7-mod/` run **before** iw7-mod's own; scripts in a Mods-menu folder run after them. iw7-mod's `MainMenu/CPMainMenuButtons.lua` replaces the zombies button list by assigning `MenuBuilder.m_types["CPMainMenuButtons"]`. A wrapper installed earlier is therefore lost (KNOWN_LIMITATIONS.md L33). The mod hooks `MenuBuilder.BuildRegisteredType` and wraps the list again when menus are built, which works in either order (`tools/tests/test_menu_script.py`).
- **Wrapping a menu.** Save `MenuBuilder.m_types["X"]`, assign a function that calls it and adds elements, and return the result (iw7-mod: `CPMainMenu`, `HeadquartersCustomizationButtons`, `ModeButton`). `MenuBuilder.registerType(name, fn)` adds a new menu or widget type.
- **Zombies main menu** (no CHARACTER button since the second in-game report; the button is in the lobby). iw7-mod rebuilds its button list as `CPMainMenuButtons` (`MainMenu/CPMainMenuButtons.lua`, identical at v1.1.0 and develop). Each button is `MenuBuilder.BuildRegisteredType("MenuButton", {controllerIndex})` with `.Text:setText(...)` and `.buttonDescription`, placed with `SetAnchorsAndPosition(0, 1, 0, 1, 0, 340*_1080p, top, bottom)` at 40-pixel steps. Mods sits at 240–270, Contracts at 280–340, and the description line at 336–394.
- **Zombies lobby** `[STOCK UI]`. Solo Match and Custom Game open `CPPrivateMatchMenu` (iw7-mod's `CPMainMenuButtons.lua`). Its button list is the registered type `CPPrivateMatchButtons`, built with `MenuBuilder.BuildRegisteredType` and placed at x 131–631, y 200–600. The list is a `LUI.UIVerticalNavigator` of `"MenuButton"` elements, each 340 wide and 30 tall at 40-pixel steps, stored in fields named after their ids:
  - `StartMatch` 0–30, `Loadout` 40–70, `Barracks` 80–110, `ChooseMap` ("SELECT SHOW", opens `CPMaps`) 120–150.
  - `BossBattle` 160–190 exists only when `CONDITIONS.IsBossBattleOn`. `Tips`, `Armory`, a 5-pixel `ForSpacing` image, the `ContractsButton` widget (`ContractsButtonCP`) and the `ButtonDescription` text (`ButtonDescriptionText`, 504 wide) follow.
  - The list builds its layout with two animation sequences, `bossBattleOff` (`Tips` 160, `Armory` 200, `ForSpacing` 240, `ContractsButton` 240–300, `ButtonDescription` 310–375) and `bossBattleOn` (`BossBattle` 160, `Tips` 200, `Armory` 240, `ContractsButton` 280–340, `ButtonDescription` 350–415). Each step calls the element's own `SetAnchorsAndPosition`.
  - The menu also shows the special characters' pictures (`Hoff` 256 × 256; `Smith`, `Pam`, `Elvira`, `Willard` 128 × 256) when `characterSelect` names one, and clears `characterSelect` when it is built (§15).
- **Stock UI scripts as a source** `[STOCK UI]`. The game's own menu scripts are compiled HavokScript (`\x1bLuaQ`, 4-byte numbers). A public dump of the game's files has them under `ui/` (`github.com/TheUnknownCod3r/iw7-src`, commit `d1a226db`). Their constant tables (strings and numbers, function by function) give element ids, positions, sequence names and the stats and actions the lobby uses, which is how `[STOCK UI]` facts were found. The files were parsed as data and never run. Instruction-level details, such as the jump targets that make Willard's rule a chain of "and", come from the same parse. A UI fact from this source still needs an in-game check (`TESTING.md` R-UI1).
- **Text size.** A text element's height is its font size: top to bottom is the size, and longer text wraps downwards below the element (`ModSelectMenu.lua`: a 30-pixel title, a 20-pixel description). A text element 100 tall draws 100-pixel letters.
- **Moving stock elements.** `element:getLocalRect()` returns left, top, right, bottom; `SetTop` / `SetBottom` move an edge (`MPMainMenuButtons.lua` moves buttons up this way). An element whose position a stock sequence sets again keeps an offset if its own `SetAnchorsAndPosition` field is replaced by a function that adds the offset and calls the original. `LUI.UIElement.addElementBefore(new, existing)` inserts into `existing`'s parent (`LobbyMissionButtons.lua`).
- **The lobby's special pictures** `[STOCK UI]`. `CPPrivateMatchMenu` has an image element per special character, stored in fields named after their ids: `Hoff` (`zm_character_select_hoff`, 798–1054 × 714–970), `Smith` (872–1000 × 661.5–917.5), `Willard` (886–1014 × 689–945), and `Elvira` and `Pam`, whose positions reuse earlier constants. Sequences `displayHoff` / `hideHoff` (and so on) set their alpha; they run on `CONDITIONS.SecretCharacterSelection("<n>")`, which is `characterSelect == n` in the player's coop stats, with no map check (`conditions.lua`). The mod's lobby card shows the chosen special through these elements and draws a regular character's card in the same place.
- **Returning to a menu.** iw7-mod's `MPMainMenu.lua` refreshes on `gain_focus` and `restore_focus`, and adds two `menu_create` handlers to the same menu, so `addEventHandler` adds a handler rather than replacing one (`registerEventHandler` is the call that replaces).
- **Pictures.** `LUI.UIImage.new()`, then `:setImage(RegisterMaterial(name), 0)`. The material must be loaded in the frontend. `white` is in `code_post_gfx` (always loaded), and the special characters' pictures are in `ui` / `ui_boot` (`KNOWN_LIMITATIONS.md` L28).
- **The HUD's character cards** `[STOCK UI]`. The in-match player info (`ui/ingame/cp/mainplayerinfo*.lua`, `cpplayerinfo.lua`) gets its picture from `ZombiesUtils.GetZombiesPlayerPhoto` (`ui/utils/cp/zombiesutils.lua`), which reads the photo index from the `playerCharacter` omnvar data and looks it up in `CSV.zombiePlayerImage` = `cp/zombies/<ui_mapname>_playercash_images.csv`. Each row is: photo index, team card, its `b`/`c`/`d` status variants, a tag (`valley`, `nerd`, `rapper`, `jock`, `hoff`, `willard`), a big image, and a name string. The main card's name is the team card's with `team` replaced by `main`. The images are only in the maps' own fastfiles (L28). iw7-mod's `loadzone <zone>` console command (`fastfiles.cpp`, v1.1.0 and develop) loads a zone asynchronously and permanently.
- **Zombies stats in the frontend.** `Engine.GetPlayerDataEx(controller, CoD.StatsGroup.Coop, ...)` reads them (iw7-mod's `Stats/__init__.lua` uses that group for zombies). A soul key reads as a boolean.
- **List menus.** `Mods/ModSelectMenu.lua` builds a list menu: `CPMenuTitle`, a `LUI.UIDataSourceGrid` whose rows are the registered `"ModSelectButton"` type fed by `LUI.DataSourceFromList` items (`buttonLabel`, `buttonOnClickFunction`, `buttonOnHoverFunction`), plus `ButtonHelperBar` and `LUI.UIBindButton` for back.
- **Talking to the game.**
  - `Engine.Exec("set …" / "seta …")` sets dvars (`seta` also saves them in the config).
  - `Engine.GetDvarString/Int/Bool` reads them.
  - `Engine.NotifyServer(name, int)` (in-game; `EndGame/__init__.lua`) arrives in GSC as `player waittill("luinotifyserver", name, value)` (stock: `end_game`, `splash_shown`, `arcade_off`, `reset_weapon_player_data`).
  - Player stats: `Engine.Exec("setCoopPlayerData <path> <value>")` and `Engine.Exec("uploadstats")` (console commands iw7-mod itself runs, `stats.cpp`). iw7-mod's Lua reads and writes multiplayer stats with `Engine.GetPlayerDataEx` / `Engine.SetPlayerDataEx(controller, CoD.StatsGroup.Ranked, …)` and saves them with `Engine.ExecNow("uploadstats", controller)` (`MissionTeams`, `MainMenu/MPMainMenu.lua`). No stats group for coop data appears in its scripts.
  - In-game reads: `Game.GetOmnvar(name)` (`EndGame`). The server sets omnvars with `setclientomnvar`; stock zombies scripts use that to ask the client UI for something, then wait for `luinotifyserver`.
  - Events from C++: iw7-mod dispatches `mod_download_*` events to `Engine.GetLuiRoot()`, where `registerEventHandler` receives them (`Mods/ModDownload.lua`).
- **Not available.** No timer or other in-game trigger appears in iw7-mod's ui_scripts, so in-game Lua has no verified way to act on its own after the map loads. File access differs by version: v1.1.0's `io` table has `fileexists`, `readfile`, `writefile`, `movefile`, `filesize`, `createdirectory`, `directoryexists`, `directoryisempty`, `listfiles`, `removefile` and `zoneexists`; develop keeps only `fileexists`, `directoryexists`, `listfiles`, `readfile` and `zoneexists` (`setup_functions` in `ui_scripting.cpp`). Only read access is safe to rely on. Relative paths start at the game folder. Adding localized strings is commented out in iw7-mod, so labels are plain text, as iw7-mod's own "Server Browser" button does. The in-game pause menu's type name appears in no script.
- **Checking.** `tools/check.py` `lua` runs `luac5.1 -p` (it parses all 31 of iw7-mod's own scripts) and allows only API names that iw7-mod's ui_scripts at `c0a1c6da` use.

## 17. Windows setup facts `[MOD main.cpp, filesystem.cpp]` `[STEAM]`

`[STEAM]` marks Steam's own file formats and registry keys, which are general knowledge, not read from a source in this repository; R-I2 confirms them.

- **Game folder.** The game's executable is `iw7_ship.exe`, and the iw7-mod client must sit next to it: `iw7-mod.exe` exits with "Please copy the iw7-mod.exe into your Call of Duty: Infinite Warfare installation folder" otherwise (`main.cpp`). The installer accepts a folder only when it contains `iw7_ship.exe`.
- **iw7-mod's folder.** iw7-mod registers `<current dir>/iw7-mod` as a search path (`filesystem.cpp`), with the game folder as the current directory. It also moves the `players2` folder (player configs and stats) into `iw7-mod/players2`, so the installer must never touch that folder. The recorded-file check enforces this.
- **`fs_game` is not saved.** iw7-mod clears the `fs_game` dvar's flags (`filesystem.cpp`, "fs_game flags"), so a mod loaded from the Mods menu is gone after restarting the game.
- **Steam `[STEAM]`.** The install folder is in `HKCU\Software\Valve\Steam\SteamPath`, or `InstallPath` under `HKLM\SOFTWARE\(WOW6432Node\)Valve\Steam`. `steamapps\libraryfolders.vdf` lists the other libraries: `"path" "D:\\SteamLibrary"` in the current format, `"1" "D:\\SteamLibrary"` in the old one. `steamapps\appmanifest_292730.acf` (Infinite Warfare's app id 292730) names the folder under `steamapps\common` in `"installdir"`.
- **Apps & features.** A per-user entry is a registry key under `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\<name>` with `DisplayName`, `UninstallString` and related values; it needs no administrator rights.
- **iw7-mod's install guide** (`auroramod/docs`, `iw7-install.md`): you must own the game on Steam. Download `iw7-mod.exe` from the latest GitHub release, move it into the game folder, launch it once so its updater downloads the client's files, then play. The uninstall guide lists the `iw7-mod` and `data` folders in the game folder and `%localappdata%/auroramod`.
- **iw7-mod's updater** (`updater.cpp`) runs at every start unless `-noupdate` is given.
  - It reads `https://iw7-mod.auroramod.dev/files.json` (`files-dev.json` for develop builds). That file is a JSON array of `[name, size, sha1]` entries, with SHA-1 in upper-case hex, and includes `iw7-mod.exe` itself.
  - It downloads each file from `data/<name>` (`data-dev/` for develop) and checks the SHA-1.
  - It replaces its own exe by renaming the old one to `.old`, then restarts itself (`-update-only`: exits instead). Data files go below `%LOCALAPPDATA%`.
  - CI (`.github/workflows/build.yml`) uploads every push to `main` and `develop` to that server. GitHub releases are made by hand.
- **Steam `[STEAM]`.** `steam://install/292730` opens Steam's install dialog for the game; `steam://open/main` starts Steam. iw7-mod exits with a message when Steam is not running (`steam_proxy.cpp`).
- **Player name.** iw7-mod registers the `name` dvar with the default "Unknown Soldier" and the saved flag, and reports it as the local player's name (`get_login_username`, `live_get_local_client_name` in `patches.cpp`, the same in v1.1.0 and develop). Its Steam stand-in answers `GetPersonaName` with "1337" (`steam/interfaces/friends.cpp`), so the Steam name is never used. `name <new name>` in the console changes it, and it is saved. Steam keeps each account's display name in `<Steam>\config\loginusers.vdf` (`"PersonaName"`, with `"MostRecent" "1"` on the last account) `[STEAM]`, and the logged-in account's 32-bit id in `HKCU\Software\Valve\Steam\ActiveProcess\ActiveUser` (SteamID64 = 76561197960265728 + id) `[STEAM]`.

## 18. Character pictures pack: x64-zt `[ZT]` `[LISTING]`

The setup (and `installer/IXPictures.ps1`) builds `iw7-mod/zone/ix_portraits.ff` with x64-zt (README "Character pictures"). `[ZT]` facts come from x64-zt's source. `[LISTING]` facts come from aurora's IW7 asset listing (`iw7_asset_listing.zip`, linked from `auroramod/docs` "zonetool-basics"), which lists every zone's assets. The first real run (2026-10-07) is under "What went wrong".

- **The tool.**
  - One `zonetool.exe` serves several games and picks the game by the executable in the current folder: `iw7_ship.exe` means IW7 (`main.cpp`). It must run in the game folder, and its README lists IW7 as supported, "no custom maps".
  - It loads the game binary, answers Steam's API itself, and sets the game up without renderer, sound or menus. It then loads `code_pre_gfx`, `code_post_gfx` and `common`, and runs the game's command buffer every 5 ms (`component/iw7/zonetool.cpp`).
  - Releases: the tag `latest`, asset "Release zonetool.zip" (GitHub names it `Release.zonetool.zip`) holding `zonetool.exe` and its symbols, `zonetool.pdb` (`.github/workflows/build.yml`). `zonetool.exe` itself is based at `0x160000000`; the game is mapped at `0x140000000`.
  - A crash shows "ZoneTool ERROR: Fatal error (<code>) at <address>" and saves `minidumps\zonetool-crash-<time>.zip` (`crash.dmp`, `info.txt`) in the game folder (`component/exception.cpp`). The address is the raw one; `llvm-symbolizer --obj=zonetool.exe <address>`, with the release's `zonetool.pdb` beside it, names the function.
- **IW7's zones** `[LISTING]` `[ZT]`.
  - A zone's materials, techsets and shaders are in a companion zone, `techsets_<zone>`. For example, `material,zm_character_select_hoff` is in `techsets_ui_boot`, its image in `ui_boot`. The game also loads `patch_<zone>` and the language zone (`eng_<zone>`) with a zone.
  - x64-zt's and iw7-mod's `loadzone` set `DB_ZONE_CUSTOM`, which skips those companion zones ("Don't load extra zones with loadzone", `fastfiles.cpp`). Each one must be named.
  - `techsets_ui_boot` holds no techsets of its own. The `2d` techset is in `code_post_gfx`, which is always loaded.
  - Where the 50 character cards are: `cp_zmb` (Spaceland's ten), `patch_cp_zmb` (Willard's two), `cp_rave`, `cp_disco`, `cp_final` (their own), `cp_town` (all but Elvira's main card), `eng_cp_town` and `eng_patch_cp_town` (Elvira's main card). Each map zone has 4,300 to 5,400 images.
- **Console** (`component/iw7/console.cpp`).
  - A thread reads standard input with `std::getline` and passes each non-empty line to the game's command buffer.
  - At the end of the input, `getline` fails without clearing the line, and the loop sends the last command again, endlessly. **The input must stay open** until x64-zt exits.
  - "ZoneTool initialization complete!" is printed once the setup is done, before the commands are registered and before the buffer runs, so commands typed after that line are not lost.
  - Messages are `printf` on standard output; `-unbuffered-io` turns off its buffering (`main.cpp`).
- **Commands** (`zonetool/iw7/zonetool.cpp`).
  - `loadzone <zone>` loads with `DB_ZONE_GAME | DB_ZONE_CUSTOM`, synchronously. It first waits for loads in progress (`wait_for_database`), then says `zone "<zone>" is already loaded...` for a loaded zone. That makes a repeated `loadzone` a wait for everything before it. A missing file gets `Zone "<zone>" could not be found!`, without waiting.
  - `dumpzone <game> <zone> <types>` (for example `dumpzone iw7 cp_zmb image`) loads a zone that is not loaded yet and dumps its assets of those types *while it loads*, to `dump\<zone>\`. It returns when the load has finished (`dump_zone`).
  - `dumpasset <type> <name>` dumps a loaded asset to `dump\assets\`, or prints "Asset not found".
  - `quit` is `std::quick_exit(EXIT_SUCCESS)`. On the command line, `-buildzone <zone>` builds, then exits.
- **What is safe to dump after a load.**
  - An image's pixels are in the zone's temporary block (`XFILE_BLOCK_TEMP`; `gfx_image::write` puts them there), which the game frees once the zone has loaded. A material's data is in the permanent block (`XFILE_BLOCK_VIRTUAL`).
  - So `dumpasset material` works after `loadzone`, and an image must be dumped with `dumpzone` while its zone loads.
  - **What went wrong** on the first real run, 2026-10-07: `dumpasset image` after `loadzone` crashed x64-zt on every map, "Fatal error (0xC0000005) at 0x000000016064530D". With the release's symbols, that address is in `memmove` (`memcpy.asm`), at its first read from the source (`vmovdqu (%rdx)`): the copy read the freed pixels.
- **Dumped files.**
  - A material gives `materials\<name>.json` (with `"techniqueSet->name"` and `textureTable[].image`). It also gives its per-material techset files, `techsets\<kind>\<techset>\<material>.<ext>` (`material.cpp`, `techset.cpp`).
  - `dumpzone … image` gives `images\<name>.iw7Image` per image, x64-zt's own format (`gfx_image::dump`): the image header, its name, then its pixels when the zone holds them, or its place in the game's `imagefile<n>.pak` when the game streams it. (`-dds` would also write a DDS of every image, reading the game's pak files for each one.)
- **Building** (`zonetool.cpp` `parse_csv_file`, `material.cpp`, `gfximage.cpp`).
  - `zone_source\<zone>.csv` holds rows of these kinds:
    - `//` comments.
    - `require,<zone>`: loads a zone first and waits for it.
    - `<type>,<name>`: an asset parsed from `zonetool\<zone>\` (searched first), then `zonetool\`.
    - `<type>,,<name>`: a reference to an asset of that name, resolved when the game loads the zone.
  - A material comes from `materials\<name>.json`. Its images come from `images\<name>.iw7Image` first, then `.dds` or `.tga`. The zone gets an image under the name the material asks for (`this->name()` in `gfx_image::write`), whatever name is inside the file, so a renamed copy of a dumped image works.
  - The material's techset is looked up among the loaded zones and added to the new zone, unless the zone already has it or a reference to it. Missing per-material techset files fall back to any file of that kind in the techset's folder (`get_parse_path`).
  - The zone is written to `zone\<zone>.ff` when the current folder has `zone\`, otherwise to the current folder (`zone_buffer::save`).
- **Asset type names** come from the game's own table (`g_assetNames`, read at run time), which is not in the source. `material` and `techset` appear in x64-zt's README and the docs' zone source example (H1), and the IW7 asset listing names `image`, `material` and `techset` the same way. If `techset` were wrong, x64-zt would skip that row and copy the techset into the pack.
- **How the mod uses it.**
  - The setup runs the build once, after the first install, in a second runspace while its window shows the progress. `Build Character Pictures.cmd` runs the same function (`Invoke-IXPictureBuild`) in a console.
  - `IXPictures.Core.ps1` runs x64-zt once per map. The first run loads `ui_boot` and `techsets_ui_boot`, waits for them and dumps the pattern material. Each run then sends `dumpzone iw7 <zone> image` for each zone holding the map's cards, and quits.
  - Two failed maps in a row stop the remaining runs, so that one crash does not mean five error boxes. When the build stops early (an error, or the window closing), x64-zt's process is ended and its files removed.
  - Each card becomes a material patterned on the stock menu material `zm_character_select_hoff`, with the card's `.iw7Image` renamed to match.
  - The build input has `require,ui_boot`, `require,techsets_ui_boot` and a `techset,,<name>` reference, so the pack never replaces the game's shaders.
  - The menu loads the pack with iw7-mod's `loadzone` (§16).

## 19. Settings, chat commands and the launcher (Phase 2) `[MOD]` `[DUMP]` `[TOOL-R/D]`

Read at v1.1.0 and develop; the code below is the same in both.

- **Chat reaches scripts as `say`.** `g_say_stub` (`logprint.cpp`) runs for every chat line: it removes the line's leading control character, notifies `level "say", player, text` and `player "say", text`, logs it, and then calls the game's own chat, so everyone still sees the line. Team chat is reported as `say_team`, except in zombies, where it is `say` too. `ix\core\events` listens to the level notify (event `chat`).
- **`player tell(text)`** sends `T "<text>"` to that client only, as a server command the game may drop when that client's command buffer is full (`SV_CMD_CAN_IGNORE`, `script_extension.cpp`). The text sits inside quotes, so a `"` in it would end the line early: `ix\core\chat` quotes typed text only when it is a plain word. It throws for an entity that is not a player.
- **`executecommand(cmd)`** queues a console command (`command::execute(cmd, false)`, `script_extension.cpp`); it runs on a later frame, not before the call returns. `seta <dvar> <value>` through it saves the dvar in the config, as `Engine.Exec("seta …")` does from Lua (§16). `ix\core\persist` saves every setting this way; values are restricted to `[A-Za-z0-9_.-]`, at most 64 characters, so no value can add a second command.
- **`ishost()`** is method `0x81A3` in both compilers' tables; the stock `scripts\cp\gametypes\zombie.gsc` calls it on players (it keeps the host out of the inactivity kick). The chat commands let only the host change settings.
- **Single characters of a string.** The stock scripts take one with `getsubstr(s, i, i + 1)` (`cp_disco_song_quest.gsc`, `disco_mpq.gsc`, `cp_final_venomx_quest.gsc`) and never index a string (`s[i]`), so the mod does the same.
- **A dvar set on the command line before a script registers it.** `+set <dvar> <value>` is applied at startup or when the dvar is registered (`command.cpp:112-143`, §14). A setting reads its `ix_<id>` dvar when it is registered, so `+set ix_debug_log 1` on the launcher's command line works.
- **`-zombies` / `-cpMode` do nothing in the client.** Both are read only in `dedicated.cpp`'s `post_unpack`, after it has returned for a client (`if (!game::environment::is_dedi()) { … return; }`), although `auroramod/docs` `commandlineargs.md` lists them as IW7-Mod flags without that condition. The console command `cpMode` sets the desired game mode in the client too (`command.cpp`); whether `+cpMode` at startup opens Zombies is **NEEDS TESTING** (R-L7).
- **What iw7-mod needs from Steam.** `steam_proxy.cpp` loads the Steam client in `post_load` only when `FindWindowA(0, "Steam")` finds a window titled "Steam"; without it `start_mod` reports `nosteam` and the client shows "Steam must be running to play this game!" and exits (unless `-nosteam`, a dedicated server, or Wine). Ownership is then checked with the signed-in account. The launcher waits for that window and for `HKCU\Software\Valve\Steam\ActiveProcess\ActiveUser` ≠ 0 (§17 `[STEAM]`).
- **The C# compiler the launcher is built with.** Windows 10 and 11 include .NET Framework 4.8, whose `csc.exe` (C# 5) lives in `%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\` (`Framework\` on 32-bit Windows). Not verifiable here: **NEEDS TESTING** (R-L1). The launcher's source is compiled here with C# 5 rules (`TESTING.md` V70), and its icon uses bitmap images, because older compilers may refuse PNG images in `/win32icon` (V72).
