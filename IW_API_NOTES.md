# IW_API_NOTES.md — Verified Infinite Warfare (IW7) Scripting Notes

This is the working API reference for the project. **Nothing here is guessed.** Every entry cites where it was verified:

| Tag | Source | Commit |
|-----|--------|--------|
| `[MOD]` | `auroramod/iw7-mod` client source | develop `c0a1c6da`; release `v1.1.0` `1b76f04e` |
| `[TOOL-D]` | IW7 builtin table used by the iw7-mod **develop** compiler (`auroramod/gsc-tool` `0be361a4`) | |
| `[TOOL-R]` | IW7 builtin table used by the iw7-mod **v1.1.0** compiler (`auroramod/gsc-tool` `833822d0`) | |
| `[DUMP]` | Decompiled stock IW7 scripts (`mjkzy/iw7-gsc-dump`) | `1dd48a78` |
| `[DOCS]` | `auroramod/docs` | `236d8155` |
| `[COMPILED]` | Compiled locally with **both** compilers during Phase 0 | |

If an API is not listed here, verify it the same way before using it. The rule is in section 12.

---

## 1. Runtime environment

- Mods run under the **iw7-mod** client. Its latest release is **v1.1.0**; `develop` is ahead. `[MOD]`
- Game modes: `GAME_MODE_SP=1`, `GAME_MODE_MP=2`, `GAME_MODE_CP=3`. "CP" is Zombies. `[MOD structs.hpp]`
- Zombies maps: `cp_zmb`, `cp_rave`, `cp_disco`, `cp_town`, `cp_final`. `[DUMP scripts/cp/maps/]`
- Map name in script: `level.script` or `getdvar("mapname")`. `[DUMP]`
- Zombies gametype: `getdvar("ui_gametype") == "zombie"` (also `escape`, `none`). `[DUMP cp/gametypes]`

## 2. Script loading `[MOD gsc/script_loading.cpp]` `[DOCS gsc-load-script.md]`

| Fact | Detail |
|------|--------|
| Source compiled at runtime | iw7-mod compiles `.gsc` **source** with its embedded gsc-tool when a map loads. A compile error in an auto-loaded entry script is printed to the console and that script is **skipped**. The effect of a compile error in a module that is only referenced is **unverified** (it may abort the load). |
| Search paths | `%LOCALAPPDATA%/…/cdata` (client data), `<game>/iw7-mod/`, then the engine's search paths, which include `<game>/<fs_game>` when a mod is loaded. `[MOD filesystem.cpp]` |
| Auto-loaded folders (in-game) | `custom_scripts/`, `custom_scripts/<mode>/` (`mp`, `cp`, `sp`), and `custom_scripts/cp_mp/` (in MP **and** CP). |
| Auto-loaded folders (frontend) | `custom_scripts/frontend/` only, and **only on develop** (added after v1.1.0). |
| Scanning is non-recursive | `utils::io::list_files` uses `directory_iterator`. Subfolders of the auto-load folders are **not** auto-loaded. They load only when referenced (`#include` or a far call), which is how modules are kept out of auto-execution. |
| Entry points | For each auto-loaded file: `main()` runs at `G_LoadStructs` (**before** stock level scripts; use it for `replacefunc`). `init()` runs at `Scr_LoadLevel`, **before the map's own `main()`**. |
| Ordering consequence | Anything that wraps a callback a map script assigns (for example `level.callbackplayerdamage`, which `cp_town`, `cp_rave`, `cp_disco`, and `cp_final` reassign) must **wait** first, for instance until `level waittill("connected")` or `"prematch_done"`, before wrapping. |
| Custom bytecode budget | `script_memory.size = 0x100000` (**1 MiB**) for **all** custom scripts in one load. Exceeding it is a **fatal** `Com_Error("Out of custom script memory")`. iw7-mod's own bundled scripts count toward it. |
| Includes | `#include path\to\file;` resolves raw `.gsc` files from the search paths first; otherwise the stock compiled script is decompiled. |
| `developer_script` dvar | When enabled, the compiler includes `/# … #/` dev blocks. It defaults to off in release builds. |

## 3. Packaging `[MOD party.cpp, fastfiles.cpp, ui_scripts/Mods]` `[DOCS loading-mods.md]`

- Mods live in `<game>/mods/<name>/`. The in-game **Mods** menu lists the folders, shows `desc.txt` as the description, sets `fs_game` to `mods/<name>`, and runs `vid_restart`.
- From the command line: `iw7-mod.exe +set fs_game "mods/<name>"`.
- Optional `mod.ff`, `mod.sabs`, and `mod.sabl` (custom fastfile and sound banks) are loaded from the mod folder.
- Servers advertise `fs_game`, which **must** start with `mods/` and contain no `.` or `::`.
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

Debug drawing: `line`, `sphere`, `box`, `cylinder`, `orientedbox`, `print3d`, `printtoscreen2d`.
Native file I/O: `openfile`, `closefile`, `fprintln`, `freadln`, `fgetarg`, `fprintfields`.
Also: `adddebugcommand`, `setdebugorigin`, `setdebugangles`, `drawsoundshape`, `perlinnoise2d`, `logstring`, and others.
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
- Both CP and MP set `level.uiparent` and `level.fontheight = 12`, so `scripts\mp\hud_util::createfontstring` works. The project sets fields directly instead.
- `clearalltextafterhudelem` is a **stub**. The classic configstring-overflow workaround is unavailable. Prefer `setvalue` for numbers and a small, fixed set of strings (risk: NEEDS TESTING).

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
  - `replacefunc(old, new)` detours a script function.
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

## 13. Offline toolchain (see `tools/README.md`)

- `tools/setup_compilers.sh` builds both compilers (`gsc-tool-iw7-release` at `833822d0`, `gsc-tool-iw7-develop` at `0be361a4`).
- Compile: `gsc-tool -m comp -g iw7 -s pc <file-or-dir>`.
- Disassemble: `gsc-tool -m disasm -g iw7 -s pc <file.gscbin>`.
- Verified error behaviour:
  - an unknown built-in gives `couldn't determine function call type`;
  - a syntax error gives `expected ';'…`.
