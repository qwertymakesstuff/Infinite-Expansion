# PROJECT_ANALYSIS.md — Phase 0 Forensics

**Project:** Infinite Expansion: an enhancement framework for *Call of Duty: Infinite Warfare*, inspired by *All-Around Enhancement* (BO3)
**Phase:** 0, Project Forensics
**Updated:** 2026-10-06

> **Phase 0 status: COMPLETE.** Both halves now rest on primary material.
> - **BO3 reference** (section 1). The supplied archive (`/AllAroundEnhancement.7z`, AAE **v3.9.5**) was downloaded, hash-verified, and extracted, and its main fastfile was decompressed.
>   - **211 of its 216 compiled scripts were decompiled.**
>   - Its 1,678 English UI strings and 501 LUI (Lua UI) chunks were inventoried.
>   - Section 1.3 explains the method and its limits.
> - **Infinite Warfare** (section 2). Every claim was verified against iw7-mod source, the stock IW7 script dump, or a real compiler run.

---

## 0. Sources examined

| # | Source | Version / commit | Used for | Access |
|---|--------|------------------|----------|--------|
| S1 | BO3 *All-Around Enhancement* package (`/AllAroundEnhancement.7z`, Dropbox) | AAE **v3.9.5** (`workshop.json`) | BO3 reference implementation | ✅ Downloaded (Dropbox `content_hash` verified). Extracted with 7-Zip 23.01. `core_mod.ff` decompressed and scripts decompiled with gsc-tool `t7` (section 1.3) |
| S2 | Public descriptions of AAE (Workshop item 2631943123, community guides), via web-search summaries | n/a | Context only; superseded by S1 | Search summaries |
| S3 | `auroramod/iw7-mod`, the IW7 community client that loads custom GSC | `develop` @ `c0a1c6da` (2026-10-05); release tag `v1.1.0` @ `1b76f04e` (2026-09-26) | Script loading, mod loading, client-added GSC/Lua functions, dvars | Cloned and read |
| S4 | `auroramod/gsc-tool`, branch `iw7-more` (the compiler embedded in iw7-mod) | develop pin `0be361a4` (2026-09-24); v1.1.0 pin `833822d0` (2026-01-10) | IW7 builtin tables; real compile checks; **T7 decompiler for S1** | Cloned; **both pins built locally** |
| S5 | `xensik/gsc-tool` (upstream) | `05d212f5` | Comparison of builtin tables | Cloned |
| S6 | `mjkzy/iw7-gsc-dump`, decompiled stock IW7 GSC (MP + CP/zombies) | `1dd48a78` (2026-09-26) | Callbacks, notifies, zombies wave system, stock helper APIs | Cloned and read |
| S7 | `auroramod/docs` (source of docs.auroramod.dev) | `236d8155` | Official folder layout, mod loading, command-line flags | Cloned and read |
| S8 | `SyndiShanX/Synergy-GSC-Menu` (`IW/`), an existing IW7 GSC menu | `33bcc80f` | Which APIs work in practice in IW7 (feasibility only; GPL-3.0, **no code copied**) | Cloned and read |

---

## 1. BO3 REFERENCE: All-Around Enhancement (AAE) v3.9.5

### 1.1 Package identity

- **`workshop.json`:** title `[ZM] All-around Enhancement v3.9.5`, Workshop ID `2631943123`, folder `all_around_enhancement`, type `mod`. Tags: Animation, Audio, Character, Mod, Skin, Specialist, UI, Weapon, Zombies.
- **Declared incompatibilities** (same file):
  - Clean Ops, ezz BOIII, original BOIII, T7x, CB Servers, BO3Enhanced, and macOS.
  - A host/client version mismatch kicks the client.
  - A separate "Lite" version exists for players whose maps crash.
- **What was supplied is the compiled Steam-Workshop build, not source.** There are no `.gsc`, `.csc`, or `.lua` files on disk. All logic is compiled inside fastfiles, which is why section 1.3 was needed.

### 1.2 Folder structure

| Path | Size | Purpose |
|------|------|---------|
| `core_mod.ff` | 54.1 MB | Main fastfile: compiled GSC/CSC, LUI (Havok Lua), string tables, localized strings, weapons/models/materials |
| `core_mod.xpak` | 177 MB | Streamed image data |
| `{bp,ea,en,es,fr,ge,it,ja,po,ru,sc,tc}_core_mod.ff` | 45 KB – 31 MB | Language packs (the `ja`/`sc`/`tc` packs are ~31 MB each) |
| `snd/<lang>/core_mod.<lang>.sabs/.sabl` | 577 MB | Sound banks (570 MB in `snd/all`) |
| `video/*.mkv` (11) | 738 MB | Loading/outro movies for stock maps and the frontend background |
| `T7Overcharged.ff` | 3.2 MB | **A Windows PE executable with an `.ff` extension** (engine extension, section 1.12), not a fastfile. Not executed or analysed further |
| `T7Overcharged/` | 7.5 MB | `assetlimits.txt` (raised asset-pool sizes, e.g. scriptparsetree 1150→1354, stringtable 220→272); `viewmodel_hide.cfg` (ammo-count-based bullet-joint hiding for ported weapons); `cursors/*.ani`; `discord_game_sdk.dll` |
| `workshop.json` | 2 KB | Workshop metadata |
| `17/`, `18/` `localization.txt` | 5 KB | Stock BO3 Windows dialog strings (Traditional/Simplified Chinese), not mod logic |
| `stats_zm_offline_0.cgp`, `loadouts_zm_offline_0.cgp`, `aae_loadout4` | 68 KB | Player save data (stats, loadouts); `aae_loadout4` is empty |

### 1.3 Method and limits of the analysis

1. **Fastfile.** `core_mod.ff` has a 0x248-byte `TAff0000` header (version 0x251) followed by 492 zlib blocks and 6 stored blocks. Each block has a 16-byte header: compressed size, decompressed size, aligned size, and its own file offset. Seven small unframed regions (360 KB in total) were copied through undecoded. The result is a **114 MB zone**, matching the header's size field.
2. **Scripts.** 216 compiled objects were carved by their T7 magic (`\x80GSC\r\n\0`) and 72-byte header: **162 GSC, 49 CSC, 5 GSH**. They were decompiled with the locally built gsc-tool (`-m decomp -g t7 -s pc64`). **211 succeeded**; the 5 `.gsh` headers were skipped.
3. **Strings.** 1,678 localized key→English pairs were extracted from `en_core_mod.ff`.
4. **LUI.** 501 Havok-Lua chunks were inventoried by source path and string constants. They were **not decompiled**.
5. **Limits:**
   - BO3 stores function and namespace names as 32-bit hashes, so AAE's own functions appear as `_id_XXXXXXXX`. All strings (dvars, notifies, labels, table paths) are intact.
   - Lua control flow was not recovered.
   - Behaviour descriptions below come from decompiled GSC where a script is named, and otherwise from UI strings.
   - No AAE code or text is copied into this project; only behaviour and design are described.
6. **Reproducing it.** `tools/bo3_reference/extract_aae.sh` regenerates this whole workspace from the archive in about 30 s.

### 1.4 Script structure

| Group | Scripts (examples) | Role |
|-------|-------------------|------|
| **Core (server)** | `motherfucker.gsc` (that is its name in the package; 323 functions, ~8.5k lines decompiled), `tfoption.gsc` (110 functions), `_clientdvar.gsc`, `aae_separators.gsc` | Registers client fields and client channels; applies options; score events; general fixes |
| **Core (client)** | `aae_core.csc` (72 functions) | Client-side HUD and visual support |
| **Options UI (LUI)** | `ui/uieditor/menus/pc/tfoptions*.lua` (10 menus), `menus/lobby/common/popups/gamesettingsflyout_aae*.lua`, `menus/pc/aaecareer*.lua`, `ui/t7/utility/aaesavingdatautility.lua`, `lobbyutility.lua` | Lobby options, career screen, save data |
| **HUD (LUI + GSC/CSC)** | Widgets: `aae_zombiecounter`, `aae_damagenumber`, `aae_overhead_healthbar`, `aae_t9_zombie_health_bar`, `aae_countdown`, `aae_lowammo_hint`, `aae_wallbuy_hints`, `aae_3rd_crosshair`, `aae_playercam`, `aae_introscreen`, `aae_za`, several score-widget styles imitating other titles, and `t7hud_zm*` HUD variants | Info HUD and HUD restyling |
| **Gameplay modules** | `banks.gsc`, `timedplay.gsc`, `moreplayers.gsc`, `hot_join_spawn.gsc`, `_zm_counter.gsc`, `_aae_zombie_health_bar.gsc/.csc`, `elmg_hitmarker.gsc`, `elmg_gambler*.gsc`, `elmg_powerups.gsc`, `share_points_powerup.gsc`, `bo3_mc_playerweapontrade.gsc`, `chatnotify.gsc`, `zmsavedata.gsc`, `extra_weapon_load.gsc`, `explosive_zomb.gsc`, `aae_left_ges.gsc`, `aae_phd.gsc`, `_zm_laststand_bar`, `bots/_bot*.gsc` | Individual features (about 54 AAE-specific modules) |
| **Dev/cheat menu** | `gametypes/_clientid.gsc` (180 functions) | GSC HUD menu, enabled only when dvar `elmg_cheats` ≠ 0 |
| **Modified stock scripts** | `_zm_utility`, `_zm_weapons`, `_zm_powerups`, `_zm_bgb*`, `_zm_audio`, `_zm_stats`, `shared/ai/zombie_utility`, other `shared/*` | AAE ships **patched copies** of stock scripts (e.g. `zombie_utility` reads `tfoption_weaker_zombs`) |
| **Map-specific** | ~90 `zm_<map>_*` scripts covering 17 stock maps (castle, factory, genesis, island, moon, prison, stalingrad, temple, theater, tomb, zod, cosmodrome, pentagon, tranzit remakes, …), plus Workshop maps keyed by Workshop ID | Fixes, solo Easter-egg support, VO |
| **Third-party modules** | `sg4y/hitmarker`, `lilrobot/_inspectable_weapons`, `wardog/perk/_wardog_perk_phd`, `sphynx/_zm_subtitles` | Bundled community scripts |

### 1.5 Initialization flow (from decompiled GSC)

```text
BO3 loads core_mod.ff → every script's `autoexec` functions run at script load
 ├─ system::register("<name>", &__init__, &__main__, deps)   ← BO3's dependency-ordered module system
 │    ("motherfucker", "aae_core", "banks", …); system::ignore("…") disables stock systems AAE replaces
 ├─ core __init__: clientfield::register(clientuimodel "hudItems.aae…"); util::registerclientsys("deadshot_keyline",
 │    "levelNotify", "musicCmd", …); resets developer dvars; map-specific registration (incl. Workshop IDs);
 │    hooks the zombie-melee notetrack
 ├─ tfoption::init(): only if  tfoption_tf_enabled == tfoption_master_ver  (version handshake)
 │    ├─ immediately: level/zombie_vars, power-up handler swaps, damage/friendly-fire callbacks, round setup
 │    └─ after flag "all_players_connected": power on, open doors, boxes everywhere, max-AI limits,
 │          damage-number wrapper around level.callbackactordamage, round limit, …
 ├─ per player: callback::on_connect / callback::on_spawned → per-player options
 │    (waits until the player is valid; perks, movement flags)
 └─ dev menu: autoexec checks elmg_cheats → on_spawned → waits "initial_blackscreen_passed" → host gets "Host" verification
```

### 1.6 Configuration flow

```text
Lobby LUI "CUSTOM MUTATIONS" (tfoptions*.lua)          ← player edits options before the match
  │ AAESavingDataUtility: LoadFromSaveData / SetToSaveData — ~80 keys kept in save data
  │ Engine.ExecNow("modvar tfoption_<key> <value>") per key;  "exec AAECustomMutations"
  │ version guard: tfoption_master_ver changed → ResetTFDefault
  ▼
BO3 modvars  tfoption_*  ── read once at match start ──▶  tfoption.gsc applies them
Client options (AAEOPTIONS_*): per-player LUI/CSC preferences (UI colour, hide X, HUD format, …)
Other dvars: zm_speed (zombie run cycle), elmg_cheats (dev menu), aae_boiii_maxplayers (player cap), DontLoadDlls
Server→client bridges: util::setclientsysstate("deadshot_keyline", "dvar,<name><sep><value>")   (sets a client dvar)
                       luinotifyevent(&"aae_score_event", …) + gamedata/tables/common/aae_scoreevents.csv
```

The ~80 option keys (`tfoption_<key>`):
`tf_enabled starting_points max_ammo higher_health no_perk_lim more_powerups extra_cash weaker_zombs roamer_enabled roamer_time zcounter_enabled starting_round perkaholic exo_movement perk_powerup melee_bonus headshot_bonus max_zombies no_delay start_rk5 hitmarkers no_round_delay bo4_max_ammo better_nuke better_nuke_points spawn_with_quick_res roundlimit roundtime bo4_carpenter timed_gameplay move_speed open_all_doors every_box random_weapon start_bowie start_power bgb roundrevive trade spectator_spawn perk_lose safeArea_horizontal camo_pap og_camo boxshare loadoutsave ff iw4 t5 t7 bgb_cost bgb_loadout bgb_use spfreemus fixed_cost elmg bank c4nuke nt_death se damagestats crazy_zombie hud limit duck nohotjoin snail roulette gambler no_dog status pregum solorevive flamer gungame perkplus rj shock juke dpap vclut noslide bigger_mule loadoutsave2 bot eereward`

### 1.7 Menu and UI structure

AAE has **five** user-facing control surfaces.

**(a) Lobby options, "CUSTOM MUTATIONS"** (LUI, pre-match, host). There is a master switch ("Enable … / Reset to Default"), safe-area sliders, and these pages:

| Page | Options |
|------|---------|
| Game | Starting round; zombie counter; hitmarkers (+ sound style: IW/MW2019, Cold War, BO3/BO4); score events; timed gameplay; start with all doors open; box at all locations; start with power; weapon trade; spectator respawn; disable locker & bank; no round delay; round revive |
| Player | Starting points; move-speed multiplier; player health (1/2/4/5 hits); EXO movement; friendly fire (reflect / shared / knock-back / can't kill); player health bar; damage analysis; no HUD |
| Zombie | Extra points per kill / melee / headshot; max spawned zombies (default 24); weaker zombies; zombie speed (default / sprint / super sprint); no spawn delay; horrific (double-speed) zombies |
| Weapon | Start with max ammo / RK5 / Bowie; random starting weapon; keep weapon-kit camo when PaP'd; choose PaP camo; box share (melee to share); weapon restore; disable C4 ending |
| Mystery Box filters | Enable/disable weapons by source title (WaW, MW2, BO1, MW3, BO2, Ghosts, AW, IW, MWR, WW2, BO4, MW2019, CW, AAE); add BO3 weapons; multiple wonder weapons |
| Perk | Perk limit; bigger Mule Kick (4 weapons); spawn with Perkaholic / Quick Revive; time-based perk decay when downed |
| Power-up | Drop frequency (6 levels); improved Nuke and its points; BO4 Carpenter; perk-bottle drop; BO4 Max Ammo |
| GobbleGum | Disable machines; random gums; fixed cost; base cost; per-round limit; disable Shopping Free music; unlimited Newtonian Negation |
| Roamer | Intermission between rounds (start the next round with ADS + Melee); max roamer time |
| Advanced (TFP/TFT) | Party size; finish on round N + end-game challenge; one-team grief; rocket jump; no slide; solo revive; disable perk enhancements / purifier / blood; BO4 repack; clear loadout after bleed-out; Ripper upgrade toggle; dual-wield PaP wonder weapons; enemy HP bar; zombie juke; disable super sprinters after round 40; random weapon kit; weapon limit; pre-patch gum machines; zombie-count algorithm; special-enemy modifiers; zombie health cap round; damage numbers; crosshair dot; highlighted craftables; weapon roulette; immortal snail; duck float; Rampage Inducer instead of Gambler; low-cost wall buys; hide custom/AAE weapons; disable omni-movement/strafe-jump |

**(b) Client options, "AAE Options"** (LUI, per player). Covers:
- UI colour (40+ presets), HUD format (BO3 vanilla / centered perks), HUD scale, flat UI, BO6-style team colours
- First-person arm (gun) position, back-of-head view, player POV camera
- In-game timer, movement-speed statistics, system time display, grenade projection (line/timer), potato graphics / forced high LOD
- A long list of "disable X" toggles: hints, wall-buy hints, flashes, letterboxing, intro, solo loading movies, low-ammo sound, reload prompt, names through walls, last-zombie outlines, zone announcer, HP bars, stamina bar, grenade countdown, perk indicators, character dialogue, team subtitles, auto-leaning, ADS zoom, extra recoil, muzzle smoke, AATs, left-hand gestures

**(c) Keybinds** (configurable in LUI): flashlight, drop points (shares 1000 at a time), third person, overhead map view, pay half a door's cost, set the Mule Kick weapon, change reticle, weapon inspect/redraw, emote wheel.

**(d) Chat commands** (`chatnotify.gsc`, `self waittill("chat", msg)`): `/` prefix with `bal`, `dep`, `transfer` (bank), `save`, `tp`, `ammo`, `ee`, `ct`, `cin`, `?` (help), single-letter shortcuts, and map names.

**(e) GSC dev/cheat menu** (`gametypes/_clientid.gsc`, enabled by `elmg_cheats`; host-verified; opened with **Stance + Reload**). An "EnCoRe"-style framework (internal version 14.2) with themeable colours, shaders, width, animations, and sounds. Pages:
- Client mods: god, unlimited ammo/stock, refill, UFO, forge tool, score, print origin / zombie count, zombies ignore you, …
- Fun: invisible, flashing, earthquake, drop vending machine, clone + animations
- Perks: give / remove all / keep on death
- GobbleGums; power-ups
- Weapons: normal / upgraded
- Weapon mods: PaP / unpack / drop / hide / shoot power-ups
- Bullets: weapon / FX projectiles
- Teleport: save/load position, teleport zombies, sky / ground / crosshair / nearest zombie
- Aimbot
- Entity: spawn / place / physics-drop / rotate / delete models
- Visions
- Lobby: box mods, super speed / gravity / timescale, disable spawners, friendly fire, grab craftables, unlock wearables, revive all, no fall damage, open doors
- Clients: per-player pages

### 1.8 Shared utilities and inter-module communication

- **BO3 registries.** AAE hooks the engine through BO3 registries rather than its own event bus:
  - `callback::on_connect` / `on_spawned`
  - `zm::register_zombie_damage_override_callback`, `register_player_friendly_fire_callback`, `register_vehicle_damage_callback`
  - `zm_spawner::add_custom_zombie_spawn_logic`
  - `level._custom_powerups[<name>].grab_powerup` swaps, `level.round_wait_func`, `level.func_get_zombie_spawn_delay`
  - `zombie_utility::set_zombie_var`, `level.zombie_vars[…]`
- **Callback wrapping.** The original handler is stored and a wrapper installed, e.g. for `level.callbackactordamage` (damage numbers).
- **Server→client.** Client fields / UI models (`hudItems.aae*`), named client sys-states (including a generic "set client dvar" bridge), and `luinotifyevent` for LUI popups.
- **Data tables.** CSV string tables under `gamedata/tables/common/` (48 tables: score events, box chances, music player, custom-map categories, …).
- **The dev menu's own framework.** Per-player menu state arrays and helpers for adding pages and options.

### 1.9 UI implementation

- **The main AAE UX is LUI** (client Lua, built with BO3's UI editor): lobby options, client options, career, and the HUD widgets. The **GSC HUD menu is only the gated dev/cheat menu.**
- **HUD restyles.** AAE replaces or extends stock HUD widgets (`t7hud_zm*` variants, score widgets imitating other titles) and adds 3D/overhead widgets.
- 200 of the 501 Lua chunks are a Chinese input-method dictionary for chat.

### 1.10 Asset usage

| Asset class | Evidence | Scale |
|-------------|----------|-------|
| Ported weapons/models/attachments | Distinct asset names with a game prefix in the zone | ~800 names: T7 360, T6 130, S2 95, T5 46, T9 33, IW8 31, T8 24, T4 21, S1 16, H2 13, H1 8, S4 8, IW6 8, IW5 4, IW4 2 |
| Sounds | Sound banks; ~227 `mus_*` and ~624 `zmb_*` alias names | 577 MB |
| Images | `core_mod.xpak` | 177 MB |
| Movies | `video/*.mkv` | 11 files, 738 MB |
| String tables | `gamedata/tables/common/*.csv` | 48 |
| Localized text | 12 language packs; 1,678 English strings | |

### 1.11 Multiplayer and co-op handling

- **Host authority.** Lobby options are host settings, the dev menu is host-verified, and some options are gated by a host/eligibility check.
- **Player count.** `moreplayers.gsc` raises `com_maxclients` from `aae_boiii_maxplayers` (needs the BOIII client) and adjusts the zombie AI/actor limits. GobbleGums are disabled above 5 players.
- **Joining and reconnecting.** Hot-join spawning, spectator respawn, weapon restore for players who reconnect or die, and a version-mismatch kick.
- **Bots.** Scripted bot AI on top of `addtestclient()` (`bots/_bot*.gsc`).

### 1.12 Dependencies

- **BO3 stock script library:** `scripts\shared\*`, `scripts\zm\*`, and the `system::` / `callback::` / `clientfield::` frameworks.
- **T7Overcharged:** a native engine extension shipped as a renamed PE file. It provides asset-pool limit overrides, a viewmodel bullet-hide config, cursors, and Discord SDK integration. A `DontLoadDlls` dvar gates part of the core module's start-up; that this is the extension loader is likely but not confirmed. **In IW7 this layer is iw7-mod itself**, which provides the console, Discord RPC, file I/O, extra dvars, and script hooks.
- **The BOIII client**, for the >4-player feature.
- **Workshop custom maps**, recognised by numeric Workshop IDs, with per-map compatibility categories.

---

## 2. INFINITE WARFARE (IW7)

### 2.1 Available modding tools

| Tool | What it provides | Notes |
|------|------------------|-------|
| **iw7-mod** (S3) | Community client. Loads custom **GSC from source** (compiled at runtime by an embedded gsc-tool), Lua UI scripts (`ui_scripts/`), mods (`mods/<name>`, selected via `fs_game`), extra GSC built-ins, extra dvars, console | **Required** at runtime. Latest release is **v1.1.0**; `develop` is ahead (see 2.7) |
| **gsc-tool** `iw7-more` (S4) | IW7 GSC compiler/decompiler. The same code iw7-mod embeds | Built locally at **both** iw7-mod pins and used for offline compile checks |
| **IW7 GSC dump** (S6) | Decompiled stock scripts: the only reference for stock function names, notifies, and level fields | Many identifiers appear only as hashes (`_id_XXXX`) |
| **x64-zt** (per S7 docs) | Read/write IW7 fastfiles (`mod.ff`) for custom assets | Needs Windows and game files; outside the script-only phases. Since Phase 1.5 the optional picture pack runs it on the player's PC (`IW_API_NOTES.md` §18) |
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
     - *Phase 1 update:* iw7-mod reports any unresolved script reference as `script link error` with `ERR_SCRIPT_DROP` (`gsc/script_error.cpp`), so the load most likely ends. See `KNOWN_LIMITATIONS.md` L23; the in-game check is R-S6.
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
│   ├── mp/ix_main.gsc               ← multiplayer entry point (auto-loaded; dropped 2026-10-06)
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
10. **Asset additions need x64-zt and Windows.** Camos, sounds, and models are out of scope for script phases. The one exception so far is the optional character pictures pack, which the player's own PC builds from their own game files (`KNOWN_LIMITATIONS.md` L28, L37).

---

## 3. FEATURE COMPATIBILITY MATRIX

The *BO3 Implementation* column comes from S1 (decompiled GSC where a script is named, otherwise the UI strings). Every IW mechanism was verified in S3/S4/S6. A raw `_meth_XXXX` id means the name is callable on iw7-mod v1.1.0 only in that form (section 2.7).

**Legend**
- Difficulty: E = Easy, M = Medium, H = Hard.
- Classification:
  - **DP**: Directly Portable (same mechanism exists)
  - **RI**: Reimplementable
  - **PP**: Partially Possible
  - **NCP**: Not Currently Possible
  - **UNK**: Unknown / Needs Testing
  - **N/A**: Not applicable to IW7
- Statuses follow `FEATURE_STATUS.md`. "IW" below means Infinite Warfare zombies (CP) unless stated.

### 3.1 Framework: menus, configuration, persistence

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Lobby options ("Custom Mutations") | LUI menus `tfoptions*.lua`; writes `modvar tfoption_*`; read once by `tfoption.gsc` | **In-game GSC HUD menu** ("Settings" pages) writing `ix_*` dvars, plus a settings file. Lobby LUI is a later optional client add-on (`ui_scripts/`) | M | RI | TESTING (Phase 3: the GSC menu `ix\ui\menu`) |
| Option persistence | LUI save data (`AAESavingDataUtility`), `exec AAECustomMutations` | Archived dvars: `executecommand("seta ix_<k> <v>")` into the host's config (`ix\core\persist`). Planned as `ix_settings.cfg` via GSC file I/O, which needs `fs_game` and so the install nobody can join (L9, L30) | M | RI | TESTING (Phase 2) |
| Option-schema versioning | `tfoption_master_ver` vs `tfoption_tf_enabled`; reset on mismatch | `ix_settings_version` dvar with a migration hook; an invalid saved value falls back to the default | E | RI | TESTING (Phase 2) |
| Console overrides | `modvar tfoption_<k> <v>`; plain dvars `zm_speed`, `elmg_cheats` | `set ix_<k> <v>` (iw7-mod console); watcher thread applies live; also `!ix set <k> <v>` in chat | E | RI | TESTING (Phase 2) |
| Presets | Client "Preset" list (`AAE_PRESENT_LIST`) | Data-defined presets (Default/Classic/Enhanced/Testing/Developer/Custom) | E | RI | PLANNED (Phase 11) |
| Module system / init order | `autoexec` + `system::register(name, __init__, __main__, deps)` | No BO3 system manager in IW7. `ix\core\bootstrap` calls each module's `register()` in a fixed order from one entry script per mode | M | RI | PLANNED (Phase 1) |
| Engine hooks | `callback::on_connect/on_spawned`, `zm::register_*_callback`, `level._custom_powerups[..].grab_powerup`, `level.round_wait_func` | Event bus `ix\core\events` over `connected` / `spawned_player`, round, last-stand, weapon and chat notifies (TESTING, Phase 2); wrap `level.callbackplayerdamage`, `level.agent_funcs[type]["on_damaged"/"on_killed"]`, `level.movemodefunc[type]` and `replacefunc` for the rest when a feature needs them | M | RI | PARTIAL (Phase 2: events; wrappers with their features) |
| Server→client dvar bridge | Client sys-state `"deadshot_keyline"` carrying `dvar,<name>,<value>` | Native `setclientdvar(s)` (both compilers); client acceptance of cheat-flagged dvars UNK | E | RI / UNK | PLANNED |
| LUI notifications (score popups) | `luinotifyevent(&"aae_score_event", …)` + CSV table | GSC HUD text; LUI only through predefined omnvars, or later client Lua | M | PP | PLANNED (HUD) |
| String tables | `gamedata/tables/common/*.csv` | `tablelookup` works on stock tables; **new** tables need a fastfile, so data is inlined in GSC | E | PP | Design note |
| Dev/cheat menu gate | dvar `elmg_cheats`, host verification | `ix_dev` dvar + host-only + in-menu confirm | E | RI | PLANNED (Phase 10) |
| Developer console | BO3 lacks one (T7Overcharged adds tooling) | Provided by iw7-mod (`~`) | – | DP | N/A (exists) |
| Engine extension (T7Overcharged DLL) | Native DLL, asset limits, Discord SDK | iw7-mod is the equivalent layer; a mod cannot ship DLLs | – | N/A | N/A |

### 3.2 Game options

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Starting round | Sets `level.start_round`/`round_number`, recomputes zombie speed/health, `zm::set_round_number` | Set `level.wave_num` before the first wave; health scales per spawn from `wave_num`; push omnvar `zombie_wave_number` | M | RI / UNK | PLANNED (side effects NEED TESTING) |
| Zombie counter | `_zm_counter.gsc` + LUI widget | GSC HUD: `desired_enemy_deaths_this_wave − current_enemy_deaths`, `current_num_spawned_enemies` | E | RI | PLANNED (Phase 8) |
| Hitmarkers (+ sound styles) | `elmg_hitmarker.gsc`, custom sounds | IW7 CP already has damage feedback (`scripts\cp\cp_damage::updatedamagefeedback`); other titles' sounds need assets | E | PP | INVESTIGATING (likely native) |
| Score events | LUI popups via `luinotifyevent` + CSV | GSC HUD popup near crosshair from kill events | M | PP | PLANNED |
| Timed gameplay | `level.round_wait_func` override, no round delay, HUD timer | Wave-loop internals are hashed (`_id_E81B`, `_id_13BCB`); needs `replacefunc` research | H | PP | INVESTIGATING |
| Start with all doors open | Thread after `all_players_connected` | `scripts\cp\zombies\zombie_doors` (door logic to be traced) | M | UNK | INVESTIGATING |
| Mystery box at all locations | Thread enabling every box | IW7 "magic wheel" (`interaction_magicwheel.gsc`) | H | UNK | INVESTIGATING |
| Start with power | Thread turning power on | `level.power_on` exists (read by the wave loop); switch logic to be traced (`zombie_power.gsc`) | M | UNK | INVESTIGATING |
| Weapon trade | `bo3_mc_playerweapontrade.gsc` (hold Use while looking at a player) | Use-button polling + `bullettrace` + `takeweapon`/`giveweapon` | M | RI | PLANNED |
| Spectator respawn | Respawn dead spectators after 5 min | IW7 CP has its own death flow (afterlife arcade on `cp_zmb`) | M | UNK | INVESTIGATING |
| No round delay | `zombie_between_round_time = 0` | Between-wave wait is internal to the wave loop (hashed helper `_id_7D00`) | M | PP | INVESTIGATING |
| Round revive | Revive and heal everyone at round end | On `spawn_wave_done`: revive through `cp_laststand` (to be traced), restore health | M | PP | INVESTIGATING |
| Disable locker & bank | Toggle | Applies once bank/locker exist | E | RI | PLANNED |

### 3.3 Player options

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Move-speed multiplier | `setdvar("g_speed", 190 × pct)` | **Same dvar** `g_speed` (iw7-mod, replicated); the stock per-player `setmovespeedscale` multiplies with it | E | DP | TESTING (Phase 5: *Move speed*) |
| Starting points | `level.player_starting_points` | `level.starting_currency`, which `cp_persistence::get_starting_currency()` reads at each player's first spawn (Director's Cut and the boss-fight-only mode use their own amounts) | E | RI | TESTING (Phase 4) |
| Player health (1–5 hits) | `zombie_var player_base_health` | *Damage taken* (10–500 percent of each hit) in the damage-callback wrapper; `self.maxhealth` stays the game's (the tough perk and regen set it) | E | RI | TESTING (Phase 4) |
| EXO movement | `callback::on_connect` handler | IW7 is natively boost/wall-run, but zombies switches double jump, wall run and mantle off at each spawn (`zombies_loadout.gsc`); re-applied `allowdoublejump(1)`, `allowwallrun(1)`, `allowmantle(1)`; `bg_omnimovement` (develop) | E | RI | TESTING (Phase 5: *Wall run*, *Double jump*, *Mantle*; L50) |
| No slide | `on_connect` handler | `self allowslide(0)`, re-applied (the loadout switches it on at spawn) | E | DP | TESTING (Phase 5: *Slide*) |
| Friendly fire (reflect/shared/knock-back/can't kill), one-team grief | `zm::register_player_friendly_fire_callback` | Wrap `level.callbackplayerdamage` (on `ix_ready`, after every `main()`); on: the stock `finishplayerdamagewrapper`; reflect: `dodamage` on the shooter; grief: `setmovespeedscale` + a slow-down effect | M | RI | TESTING (Phase 4: off / on / reflect); grief DEFERRED |
| Rocket jump | Friendly-fire callback + push | Damage-callback wrapper + `setvelocity` on the player's own splash damage that `zombie_damage::get_explosive_damage_on_player` would apply | M | RI | TESTING (Phase 4) |
| Player health bar (self/ally overhead) | LUI widgets | Self bar: GSC hudelem (`setshader` width). Ally bars: `setwaypoint` + `settargetent` (both compilers), NEEDS TESTING | M | PP | PLANNED |
| Damage analysis / damage numbers | Wrapper on `level.callbackactordamage` + LUI | Wrap agent `on_damaged`; short-lived hudelems (budget risk L12) | M | PP | PLANNED |
| No HUD | Option | `setclientdvar("cg_draw2d", 0)` (stock dvar); acceptance UNK | E | UNK | INVESTIGATING |

### 3.4 Zombie options

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Zombie speed (default/sprint/super sprint) | dvar `zm_speed` → `set_zombie_run_cycle_override_value("super_sprint")` | `level.movemodefunc[agent_type]` → `"sprint"`; "super" = sprint + `self.moveratescale > 1` (stock uses 1.15) | M | RI | PLANNED (Phase 7) |
| Disable super sprinters after round 40 | AAE makes all zombies super sprint from round 40 | Rule inside the same move-mode hook | E | RI | PLANNED |
| Horrific zombies (double speed for all actions) | Thread | `moveratescale` / `generalspeedratescale` (fields seen in `zombie_agent.gsc`), NEEDS TESTING | M | PP / UNK | INVESTIGATING |
| Weaker zombies / health-cap round | Patched stock `zombie_utility` health math | Scale or clamp `.maxhealth`/`.health` right after spawn | M | RI | PLANNED |
| Max spawned zombies (24 → N) | `level.zombie_ai_limit`, `zombie_actor_limit`, `zombie_max_ai` | `level.max_static_spawned_enemies` (stock 24); engine agent cap unknown | H | PP / UNK | INVESTIGATING |
| Extra points per kill / melee / headshot | `zombie_vars` score bonuses | Agent `on_killed` wrapper + `give_player_currency` | M | RI | PLANNED |
| No spawn delay | Spawn-delay function | Spawn pacing internal to `zombies_spawning` (hashed `_id_8454`) | H | PP | INVESTIGATING |
| Round size algorithm | Custom formula | `level.desired_enemy_deaths_this_wave` computed by hashed `_id_8455` | H | PP | INVESTIGATING |
| Special-enemy modifiers | Round composition change | IW7 event waves per map | H | UNK | INVESTIGATING |
| Zombie juke (BO1) | Custom spawn logic enabling BO3's built-in AI behaviour attributes `can_juke` / `spark_behavior` (stock animations) | IW7's zombie ASM has no juke behaviour or animations | H | NCP | BLOCKED — IW LIMITATION |
| Zombies ignore a player (dev menu) | `self.ignoreme = 1` | **Same field** `self.ignoreme` (49 stock uses); the stock count `.enabledignoreme` left alone | E | DP | TESTING (Phase 4: off / host / everyone) |

### 3.5 Weapon and Mystery Box options

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Start with max ammo / extra start weapons / random start weapon | Spawn handlers | Max ammo: the stock `loot::give_max_ammo_to_player` after each spawn; weapons: `giveweapon` with names from the mystery box's own lists (`interaction_magicwheel.gsc`: per map, camos, Pack-a-Punch levels) | E | RI | Max ammo TESTING (Phase 6); start weapons DEFERRED |
| Weapon restore (disconnect/death) + clear after bleed-out | Host saves weapons/perks/points | Per-GUID store (`getguid`) in `level`; file I/O across sessions | M | RI | PLANNED |
| Weapon roulette / gun game | Random weapon each round / kill progression | On `regular_wave_starting` / kill events: `takeweapon` + `giveweapon`, names from the box's lists | M | RI | DEFERRED |
| Keep kit camo / choose PaP camo | PaP hooks | IW7 PaP is `interaction_weapon_upgrade.gsc`; camo is a weapon-name suffix (`+camoN`) | M | PP | INVESTIGATING |
| Random weapon kit (attachments/camo) | Random attachment build | Needs valid per-weapon attachment lists (`getweaponattachments`, tables) | H | PP | INVESTIGATING |
| Box share / weapon limit / multiple wonder weapons | Box hooks | IW7 magic-wheel logic (to be traced) | H | PP | INVESTIGATING |
| Box filters by source title | AAE's ported weapons (~800 assets) | Ported weapons need fastfiles (x64-zt) | – | NCP | BLOCKED — IW LIMITATION (script-only) |
| Disable C4 buyable ending | AAE-specific ending | Not in IW7 | – | N/A | N/A |

### 3.6 Perk, power-up, and GobbleGum options

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Spawn with Perkaholic / Quick Revive | Spawn handlers | `scripts\cp\zombies\zombies_perk_machines::give_zombies_perk(...)` per perk | E | RI | PLANNED |
| Perk limit | `tfoption_no_perk_lim` | No perk cap found in IW7 CP scripts | – | N/A / UNK | INVESTIGATING |
| Bigger Mule Kick (4 weapons) | `level.additionalprimaryweapon_limit = 4` | Mule Munchies (`perk_machine_more`) via `give_more_perk`; needs `replacefunc` | M | PP | INVESTIGATING |
| Time-based perk decay when downed | Thread on down | `last_stand` notify + `take_zombies_perk` over time | M | RI | PLANNED |
| Solo unlimited Quick Revive | Option | Up 'N Atoms (`perk_machine_revive`) solo logic to be traced | M | UNK | INVESTIGATING |
| Power-up frequency | `zombie_powerup_drop_increment` / `_max_per_round` | `scripts\cp\loot` drop logic (`check_to_increase_powerup_drop_rates`, `update_power_up_drop_time`) via `replacefunc` | M | PP | INVESTIGATING |
| BO4 Max Ammo (refill clips) | Swaps `grab_powerup` for `full_ammo` | Hook `ammo_max` in `scripts\cp\loot::process_loot_content`, then `setweaponammoclip(w, weaponclipsize(w))` | M | RI | PLANNED |
| Improved Nuke / BO4 Carpenter | `grab_powerup` swaps | Hook `kill_50` / `board_windows` processing | M | PP | INVESTIGATING |
| Perk-bottle power-up | `free_perk` drop function | No equivalent IW7 drop ref confirmed | M | UNK | INVESTIGATING |
| GobbleGum options (disable/random/cost/limit) | `_zm_bgb*` patches | IW7 analogue is **Fate & Fortune cards** (deck + meter, no machines). Only "disable" and "unlimited" map (iw7-mod has `cg_unlimited_cards`) | M | PP | INVESTIGATING |

### 3.7 Modes and fun options

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Roamer (intermission; ADS+Melee starts the next round) | Thread between rounds | Requires holding the wave loop (hashed internals) | H | PP | INVESTIGATING |
| End-game challenge / finish on round N | Round-limit thread + endless round | `spawn_wave_done` counting + `exitlevel`/end flow (to be traced) | H | PP | INVESTIGATING |
| Immortal snail | Scripted chaser | `spawn("script_model")` + `moveto` toward a player; damage on touch | M | RI | PLANNED |
| Duck float (Quacknarok) | BO3 cosmetic asset | No duck model in IW7; any stock model is a substitute | M | PP | DEFERRED |
| Rampage Inducer (instead of Gambler) | Spawn pacing | Spawn pacing internals (see 3.4) | H | PP | INVESTIGATING |
| Gambler (random event) | `elmg_gambler*.gsc` | Scripted random events using verified APIs | M | RI | PLANNED |

### 3.8 Client options and HUD

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| UI colour / HUD format / scale / flat UI | LUI on the stock HUD | Our GSC HUD is themeable; restyling the **stock** IW7 LUI HUD needs client Lua | H | PP | DEFERRED |
| Gun (arm) position | Client option | iw7-mod client dvars `cg_gun_x/y/z` via `setclientdvar` (acceptance UNK); a per-player choice | E | RI / UNK | DEFERRED (per-player options, L46) |
| Back-of-head / third person | Keybind + LUI crosshair | `_meth_845E` (`setcamerathirdperson`, per player); 3rd-person crosshair (LUI) NCP | E | RI | TESTING (Phase 4: a setting, off / host / everyone) |
| In-game timer / movement-speed stats / system time | LUI | GSC HUD (`settimer`, `getvelocity`, `gettime`); system time UNK | E | RI | PLANNED |
| Low-ammo hint / grenade countdown | LUI | GSC: `getweaponammoclip` vs `weaponclipsize` + hudelem | E | RI | PLANNED |
| "Disable X" visual toggles (hints, flashes, letterbox, subtitles, …) | LUI / client dvars | Mostly stock-LUI behaviour; only toggles backed by real client dvars are possible | – | PP | DEFERRED (per item) |
| Potato graphics / force high LOD | Client dvars | Client graphics dvars are the player's own settings | – | N/A | N/A |
| Grenade projection (line + timer) | LUI/CSC | Needs client-side rendering | – | NCP | BLOCKED — IW LIMITATION |
| Player POV camera | LUI widget | Client render feature | – | NCP | BLOCKED — IW LIMITATION |

### 3.9 Keybinds and chat commands

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Custom keybinds (flashlight, drop points, third person, map view, split door cost, …) | LUI key-binding UI | GSC cannot create new binds. Use `notifyonplayercommand` on **existing** commands, or chat commands players can bind (`bind <key> "say /cmd"`) | M | PP | PLANNED (as chat commands) |
| Drop/share points | Keybind | Chat command `/share` + `give_player_currency` / `take_player_currency` | E | RI | PLANNED |
| Overhead map view | Keybind | Link the player to a high script origin camera (`playerlinkto`) | M | PP / UNK | INVESTIGATING |
| Chat commands (`/bal /dep /transfer /save /tp /ammo /ee /?`) | `self waittill("chat", msg)` | iw7-mod `say` notify (`level waittill("say", player, msg)`, v1.0.3+). The router and the `!ix` settings commands exist (`ix\core\chat`, Phase 2); these gameplay commands come with their features | E | RI | PLANNED (router: TESTING) |
| Weapon inspect / redraw | Third-party script | Already provided by iw7-mod (`startweaponinspection`, actionslot 8) | – | DP | N/A (exists) |

### 3.10 Dev/cheat menu (`elmg_cheats`)

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| God mode / unlimited ammo / refill | Menu toggles | God mode: the damage-callback wrapper drops the damage (no zombies script uses `enableinvulnerability`); ammo: what the Infinite Ammo and Max Ammo power-ups do, as a loop; refill: Max Ammo for everyone | E | RI | God mode TESTING (Phase 4); ammo and refill TESTING (Phase 6) |
| UFO / noclip | Menu toggle | Link to a script mover, fly with button polling | M | RI | PLANNED (Phase 10) |
| Teleport menu (save/load, crosshair, sky/ground, nearest zombie, teleport zombies) | Menu actions | `setorigin`, `bullettrace`, `playerphysicstrace`, `getaliveagents` | E | RI | Save / load / crosshair TESTING (Phase 4); the rest PLANNED (Phase 10) |
| Score / perks / power-ups / weapons / visions | Menu actions | Currency API; `give_zombies_perk`; `drop_loot`; `giveweapon`; `visionsetnakedforplayer` | E | RI | PLANNED |
| Entity / forge tools | Spawn/place/rotate/delete models | `spawn("script_model")`, `setmodel`, `rotateto`, `delete` | M | RI | PLANNED (Phase 10) |
| Lobby: super speed / gravity / timescale / no fall damage | dvars | `g_speed`, `bg_gravity`, `setslowmotion`/`timescale`; falls dropped in the damage callback (`MOD_FALLING`) | E | RI | Speed, gravity, fall damage TESTING (Phase 5); timescale PLANNED (Phase 10) |
| Disable AI spawners | dvar | Stock dvar `debug_pause_spawning` (read by stock scripts), NEEDS TESTING | E | UNK | INVESTIGATING |
| Clone player / fun effects | Menu actions | `_meth_8086` (`cloneplayer`); `earthquake`; `hide`/`show` | M | PP | PLANNED (Phase 10) |
| Aimbot | Menu | Excluded by design (an MP cheating tool; not part of AAE's gameplay feature set) | – | – | NOT PLANNED |
| Host verification levels | Per-player status | Host-only menu; per-player access list | E | RI | PLANNED (Phase 3) |

### 3.11 Systems, content, and multiplayer

| BO3 Feature | BO3 Implementation | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|---|
| Bank / weapon locker (persistent) | `banks.gsc` + LUI save data | GSC file I/O keyed by `getguid()` (mod-folder install) | M | RI | PLANNED |
| Career / stats screen | `aaecareer.lua` + saved stats | File I/O stats; GSC "Stats" page (LUI screen deferred) | M | PP | PLANNED (later) |
| Easter-egg-count rewards | Saved EE counter + reward hooks | File I/O counter; per-reward hooks | H | PP | DEFERRED |
| Solo Easter eggs / map fixes | ~90 map scripts for 17 BO3 maps | IW7 has 5 CP maps; per-map `replacefunc` work | H | PP | DEFERRED |
| Offline bots | Scripted bot AI on `addtestclient()` | `addtestclient` exists; no IW7 CP bot AI, so a full AI would be needed | H | NCP / UNK | INVESTIGATING |
| >4 players (up to 10) | `com_maxclients` via BOIII + AI-limit changes | IW7 CP is a 4-player mode; client cap unverified | H | NCP / UNK | BLOCKED — IW LIMITATION (pending test) |
| Hot-join spawning | `hot_join_spawn.gsc` | IW7 CP join-in-progress behaviour to be observed | M | UNK | INVESTIGATING |
| Version-mismatch kick | Version compare | Clients don't run our scripts (host-authoritative); not needed | – | N/A | N/A |
| Ported weapons, camos, sounds, HUD art, movies | ~800 assets, 577 MB audio, 177 MB images | x64-zt fastfile work on Windows | H | NCP (script-only) | DEFERRED (asset pipeline) |
| Discord invites / lobby ID / map download | LUI + SDK | iw7-mod has Discord RPC; the rest is client UI | – | N/A | N/A |

### 3.12 Not in AAE but requested in the brief

| Feature | IW Equivalent | Diff. | Class | Status |
|---|---|---|---|---|
| Gravity | `bg_gravity` (1–1000, global) | E | RI | TESTING (Phase 5) |
| Jump height | No verified dvar; lower gravity jumps higher, double jump adds height | – | PP | PARTIAL (Phase 5, L16) |
| Unlimited sprint / air control / omni-movement | `bg_sprintUnlimited`, `bg_airControl`, `bg_omnimovement` (develop only) | E | PP | TESTING (Phase 5, feature-detected: N/A on v1.1.0) |
| Fire-rate / rapid fire | `_meth_85C1(pct)` / `_meth_85C2()` (stock: the Berserk passive's 65) | M | RI | TESTING (Phase 6) |
| Recoil / spread | `player_recoilscaleon`, `_meth_822C`; `setspreadoverride`, `_meth_8263` (no stock use) | E | RI / UNK | Recoil TESTING (Phase 6); spread INVESTIGATING |
| Damage multipliers | Damage-callback wrappers | M | RI | PLANNED |
| Coordinates / speed / weapon HUD | `self.origin`, `getvelocity`, `getcurrentweapon` | E | RI | PLANNED |
| FPS display | Not readable from server GSC | – | NCP | BLOCKED — IW LIMITATION |
| 3D debug drawing | `line` / `print3d` are release stubs | – | NCP | BLOCKED — IW LIMITATION |
| Entity inspector / trace info | `bullettrace` + entity fields | M | RI | PLANNED |
| Fast restart | `map_restart` / `executecommand("fast_restart")` | E | RI / UNK | PLANNED |

---

## 4. Decisions for Phase 1 and beyond

1. **Target both iw7-mod v1.1.0 and develop.** Use only names the release compiler resolves correctly. Put every develop-only or mislabeled built-in behind `_meth_`/`_func_` ids in one `ix\core\compat` module. Enforce this with the dual-compile parity check.
2. **Configuration model = AAE's model, adapted.**
   - AAE uses a flat set of option keys (`tfoption_*`), saved by the UI, read by GSC at match start, and reset on a version change.
   - Infinite Expansion uses the same flat model with `ix_*` dvars and an `ix_settings.cfg` file written from GSC.
   - A settings-version key handles migration.
   - Options are also applied **live**, not just at match start.
3. **The primary UI is a GSC HUD menu.** AAE's main UX is LUI, but IW7 LUI menus would be client-side code that every player needs, and LUI↔GSC traffic is limited to integer notifies and predefined omnvars. The GSC menu works for every client of the host.
   - It covers AAE's lobby options (3.2–3.7) as in-game pages plus the dev tools (3.10).
   - A LUI front-end stays an optional later phase.
   - *Update 0.3.1, after the first in-game try:* the button-only controls (ADS / Fire to scroll) were hard to find. The menu now steers with the movement keys or left stick while it holds the player in place, as the stock phone booth does (`IW_API_NOTES.md` §8); the AAE-style buttons still work.
4. **Hooks over file overrides.** AAE ships patched copies of stock scripts. Infinite Expansion uses iw7-mod's `replacefunc` and callback wrapping instead, which avoids redistributing modified stock code and survives game-script differences between maps.
5. **Zombies (CP) is the primary target**, MP is secondary (host only), and SP is out of scope.
   - *Update 2026-10-06: the project owner dropped MP. The mod is zombies-only.*
6. **Use one entry script per mode** (`custom_scripts/cp/ix_main.gsc`, `custom_scripts/mp/ix_main.gsc`) with modules under `custom_scripts/ix/`. CP-only modules (which reference `scripts\cp\…`) are never referenced from the MP entry.
   - *Update 2026-10-06: with MP dropped, only the zombies entry script exists, and every module may use zombies APIs (`ARCHITECTURE.md` §7).*
7. **Asset-dependent AAE features are deferred to an optional asset phase** (x64-zt on Windows): ported weapons, camos, sounds, and HUD art.
