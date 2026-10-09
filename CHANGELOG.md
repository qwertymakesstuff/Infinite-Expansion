# CHANGELOG

All notable changes to this project. Format based on *Keep a Changelog*.

## [Unreleased]

### 0.4.2: the menu's text appears; ADS + Melee opens it every time (2026-10-09)

**Fixed**
- **The menu's text did not appear** (in-game report). A player sees only so many HUD elements, about 28 per script in Infinite Warfare zombies, and the menu used 33 (34 in 0.4.1). The ones made last, including the help under the list and the keys at the bottom, were simply not drawn. The menu now uses 28, the most important first: eight rows at a time (longer pages scroll), no accent line, and two lines of keys. A test keeps it within that budget.
- **ADS + Melee did not always open the menu.** The menu checked the buttons every 0.05 seconds, so a quick tap of Melee could fall between two checks. Now every Melee press counts, and aiming counts too (toggle ADS works). In the air the menu opens as you land, and when it cannot open (while you are down, on a ride), a line says why.

**Changed**
- **ADS + Melee is the default way to open the menu again**, as asked. Crouch + Melee and chat only are still on the menu's **Menu** page (*Menu: open with*).

**Tests**
- `test_settings.py` checks the menu's HUD element count (9 tests, 108 in all).

### 0.4.1: the menu opens with Crouch + Melee; how to open it at each round's start; its keys in small text (2026-10-09)

**Changed**
- **Opening the menu:** crouch, then press Melee (on a controller: crouch, then the melee button). ADS + Melee also opened the menu whenever you knifed while aiming. The crouch counts once you have been crouched for a moment, so a knife right after a slide does not open it. `!ix menu` in chat still works.
- *Menu: open with* on the menu's **Menu** page (setting `menu_open`) picks the keys for the whole match: *crouch_melee* (default), *ads_melee* (the old way) or *chat* (only `!ix menu`). Changing it tells everyone the new keys.
- **How to open it** now shows in the middle of the screen at the start of each round, until you have opened the menu once in the match. A player who joins mid-round sees it a few seconds after spawning. *Menu: hint* switches it off.
- **The keys at the bottom of the menu** are three lines of small text: moving and changing, selecting and going back, and the keys that open it. A test checks that each line fits the panel.

**Tests**
- `test_settings.py` also checks the footer's lines (8 tests, 107 in all).

### 0.4.0: player options (Phase 4) (2026-10-09)

**Added**
- **Player page** in the in-game menu (ADS + Melee, then *Player*). Each option is also a setting for chat and the console, applies to the whole match, and belongs to the host:
  - **God mode**: off, host (only the host takes no damage) or everyone.
  - **Damage taken**: 10 to 500 percent of the damage players take; 100 is the game's own.
  - **Third person**: off, host or everyone.
  - **Zombies ignore players**: off, host or everyone.
  - **Rocket jump** and **Rocket jump: power**: your own explosions that would hurt you (launchers, grenades) throw you up and away instead. The ones the game already makes harmless to you, such as the wonder weapons, still do nothing.
  - **Friendly fire**: off (the game's own: players cannot hurt each other), on (they can, and can down each other) or reflect (whoever shoots a teammate takes the damage).
  - **Starting points**: 0 to 999,999 (the game gives 500), for players who spawn for the first time after the change. Director's Cut keeps its own 25,000.
  - **Players push apart**: on, as in the game; off lets players stand inside each other.
  - **Position** page: *Save position*, *Go to saved position* and *Teleport to crosshair*. Host only, unless *Menu: who changes settings* is *everyone*; the menu closes first; refused while down. A teleport can put you where the game does not expect a player.
- Version 0.4.0: the first release that reaches 0.3.2 installs by itself, through the desktop shortcut.

**Fixed**
- The help under the menu's list has four lines instead of three. Longer help was cut off without a sign: a guest never saw the end of "Only the host can change it." on three Characters rows.

**Not in this version**
- *Gun position* is not a setting, because it differs per player: iw7-mod's `cg_gun_x`, `cg_gun_y` and `cg_gun_z` move the weapon in each player's own console.
- The one-team grief mode is deferred.

**Tests**
- New `tools/tests/test_settings.py` (7 tests, 106 in all). It checks that every setting has a valid default, a menu row and a README row, and that the init line counts them. It also checks that every row's help fits the menu's lines, including the guest's note.

### Roadmap: Phases 14–21 added (2026-10-09)

- Eight new phases for the fun features, planned after Phases 4–13 and not started: emotes (14), fun toys (15), a zombies randomizer (16), favorites and presets (17), FUN menu polish (18), secrets and easter eggs (19), co-op social features (20) and their tests (21). Their full scope and ground rules are in the new `ROADMAP.md`; `README.md` and `FEATURE_STATUS.md` list them.

### 0.3.2: automatic updates from GitHub (2026-10-08)

**Added**
- **Automatic updates.** New versions install themselves; no more downloading zips after this one.
  - Each time the **Infinite Expansion** shortcut starts the game, it asks GitHub whether a newer version has been released (five seconds at most; offline, the game just starts). If so, the setup window opens, downloads it, installs it, and starts the game.
  - The setup window asks too when it opens: the mod row says "v… is out" and the green button reads UPDATE.
  - Downloads come only from this project's own Releases page and are checked against the SHA-256 GitHub lists for them. Then the new version's own setup installs it, so each version installs itself the way it was written to. Old downloads are deleted; UNINSTALL removes them all.
  - **AUTO-UPDATE: ON / OFF** at the bottom of the setup window switches the launcher's check off; `--ix-no-update` on the shortcut skips it once.
  - `IXSetup.ps1 -NoWindow -Update` updates without any window.
- **Releases.** A new GitHub workflow publishes a release by itself whenever a push changes the version number: `Infinite-Expansion-<version>.zip` (the same layout as the downloads so far) with that version's notes from this changelog.
- Version 0.3.2.

**Changed**
- The setup copy in `%LOCALAPPDATA%\InfiniteExpansion\Setup` is now updated file by file instead of being deleted and copied again, so an update can replace the copy it was started from.
- The README no longer mentions the removed in-match card when it says how to check the install.

**Tests**
- 12 new installer tests (99 in all): release lookup, download, checksum, size and unpacking against a local stand-in for GitHub, including a release from elsewhere, a tampered checksum and a zip with a path outside its folder; a whole `-NoWindow -Update` in which the new version's setup installs itself; the auto-update switch; the launcher's version checks and the arguments it hands to the setup; and the release workflow's script, run against a stand-in for `gh`.

### 0.3.1: easier menu controls; the lobby card in the bottom right; the in-match card removed (2026-10-08)

**Changed**
- **Menu controls.** W / S (or the left stick) move up and down, A / D change the highlighted value, Use or Jump selects, Melee goes back. ADS / Fire and Tactical / Frag still work too.
  - While the menu is open you stand still and can look around: the movement keys steer the menu. The menu holds you the way the game's own phone booth on Shaolin Shuffle holds its player. It opens only while you stand on the ground; if the game itself takes you somewhere while it is open (a ride, a trap), it closes.
  - The two lines at the bottom name these keys (the stick with a controller), larger and brighter. `<` `>` around the highlighted value show that A / D change it. The panel is a little wider. The hint after the first spawn names the keys too.
- **Lobby card** moved to the bottom right, under the players' cards, as big as fits there (as in the mockup). It now shows special characters too: their own card from the picture pack, else the game's own picture of them, which no longer also appears in the lower middle. With three or four players it goes to the lower middle. A special the player cannot have shows no card, because the game picks for them.

**Removed**
- The player card on the right of the screen in a match, with its settings `player_card`, `player_card_picture`, `player_card_x` and `player_card_y` and the menu's HUD page. Values saved for them stay in the game config but are no longer read.

- Version 0.3.1.

**Tests**
- Menu script tests (14): the lobby card for one, two and three players, special characters in place of the stock picture (also when the stock lobby shows it again), a locked special. The character data test checks the picture pack's specials against the cast instead of the player card's names. 87 tests OK; `check.py` passes (18 scripts).

### Phase 3: the in-game menu; the lobby's character card; Pam Grier's card (2026-10-08)

**Added**
- **In-game menu.** Hold ADS and press Melee in a match (or type `!ix menu`). ADS / Fire move, Use opens a page or switches a setting, Frag / Tactical change a value, Melee goes back and closes it. Pages: Characters, HUD, Menu, Settings (changed count, *Reset every setting*, version), Debug.
  - Every row is a setting with its own label, value, range and help, the same ones the chat commands and the console use; a change made anywhere shows in an open menu.
  - While it is open, your weapon, grenades, melee and Use are off, so the buttons only steer the menu. It uses the game's own counters for that, so closing it never undoes what the game turned off itself (last stand, traps). It closes when you go down and at the end of the match.
  - Everyone can open it; only the host changes settings, unless `menu_access` is `everyone`.
  - New settings: `menu` (the menu itself), `menu_access`, `menu_hint` (a line after the first spawn naming the controls).
  - Modules can add chat commands (`chat::add_command`); the menu adds `!ix menu`.
- **Lobby card.** The character picked in CHARACTER now shows in the lobby, where the game itself shows a chosen special character's picture: the game's own picture for a special character, the selected show's card (picture pack) or initials for a regular one. It follows a new pick and a new SELECT SHOW.
- Version 0.3.0.

**Fixed**
- Pam Grier's card in the CHARACTER menu was squeezed: her only card is Shaolin Shuffle's New York ID card, which that map's HUD draws twice as wide as high. It is now drawn that way. The other cards are unchanged.
- The setup sorted its file list by the PC's language rules; it now sorts by character code, the same everywhere.

**Tests**
- 3 new menu-script tests (13): the lobby card in every case above, and Pam's card shape; the lobby stand-in now has the stock lobby's five special pictures. `check.py` passes with the menu on both compilers (19 scripts).

### The player card shows the character's picture (2026-10-07)

**Added**
- The card in the bottom-right corner now shows the character's picture at its left: their square card from the current map, the one the game's HUD shows for teammates. These pictures are part of every map, so every player sees them, without the picture pack.
  - A special character from another map (`character_crossmap`) has no picture there, and the card stays as before.
  - The new setting `player_card_picture` (on by default) turns the picture off: `!ix off player_card_picture`.
- Version 0.2.1.

**Tests**
- Each of the 50 card names (every character on their maps, main and team card) is a material that the map loads, per the game's asset listing. A new test checks that the player card and the setup's picture pack use the same names.

### Phase 2: settings, chat commands, saving; the launcher (2026-10-07)

**Added**
- **Settings.** Every option of the mod is now a setting with a type, a default and a valid range (`ix\core\config`). Eight so far: `debug_log`, the four character settings, `player_card` and its two margins.
  - Change one in chat (`!ix set character_announce 1`) or in the console (`set ix_character_announce 1`, applied within half a second). A value that means nothing is refused, and numbers are kept within their range.
  - Changes are **saved** by themselves, as archived dvars in the host's own config (`seta`, the way the CHARACTER menu saves your pick), so they also work in the install friends can join. `ix_settings_version` records the layout, for later migrations.
- **Chat commands** (`ix\core\chat`): `!ix`, `!ix list [word]`, `!ix get`, `!ix set`, `!ix on` / `off`, `!ix reset <setting>` / `all`, `!ix version`. Everyone can look; only the host can change settings. Replies go only to the player who typed.
- **Event bus** (`ix\core\events`): modules subscribe to 12 events (connect, spawn, death, disconnect, last stand, weapon change, fire, reload, round start and end, game end, chat), each from a real IW7 notify, with one listener per source.
- **Feature manager** (`ix\core\features`): on/off features with requirements and global or per-player hooks. The player card is the first: `!ix off player_card` hides it at once.
- More utilities: `parse_bool`, `is_number`, `array_contains`, `starts_with`.
- The init log has a third line: `settings: 8 (0 changed from the default); features: 1; chat: !ix`.
- **Launcher.** INSTALL, UPDATE and REINSTALL now build `Infinite Expansion.exe` in the game folder, with an **Infinite Expansion** shortcut on the desktop. It checks that iw7-mod and the mod are there, starts Steam if needed and waits until you are signed in (iw7-mod refuses to start without Steam), then starts iw7-mod from the game folder. Arguments given to it go on to iw7-mod.
  - It is compiled on your PC by the C# compiler that comes with Windows, from `installer\IXLauncher.cs`, so the download carries no program file. If it cannot be built, the install still succeeds and PLAY works as before.
  - The game opens on its main menu: iw7-mod's `-zombies` switch only works on dedicated servers (its own docs say otherwise).
  - PLAY now starts the launcher. UNINSTALL removes it and its shortcut.
- Version 0.2.0.

**Changed**
- The character and player-card dvars (`ix_character_select`, `ix_character_specials`, `ix_character_crossmap`, `ix_character_announce`, `ix_player_card`, `_x`, `_y`) are now settings. The dvar names are the same, so earlier values still apply.
- The setup no longer adds an "IW7-Mod (Infinite Warfare)" desktop shortcut when it downloads iw7-mod; the Infinite Expansion shortcut replaces it.

**Tests**
- 8 new installer tests (54): the launcher's source compiles with C# 5 rules and passes arguments on intact; building it against a stand-in for Windows' C# compiler (arguments, version, icon refused, compiler failing or missing, nothing left in the temp folder); PLAY prefers it; UNINSTALL removes it, and finishes when it is in use; its icon is bitmap-only and matches `ix.ico`.
- `check.py` passes with the five new core scripts on both compilers (17 scripts, 13,374 bytes).

### Character pictures: x64-zt no longer crashes on every map (2026-10-07)

**Fixed**
- Building the character pictures crashed x64-zt once per map ("ZoneTool ERROR: Fatal error (0xC0000005)"), so no pictures were built.
  - x64-zt's own symbols place the crash in a memory copy reading freed memory. The game frees an image's pixels as soon as its map has loaded, and the build asked for the cards after that.
  - The build now has x64-zt copy each map's images *while* the map loads (`dumpzone`), which is how x64-zt normally dumps. It then builds the pack from those copies (x64-zt's own `.iw7Image` files), renamed per card.
- The stock menu picture that every card is patterned on was never loaded either: IW7 keeps materials in a separate `techsets_ui_boot` zone, which x64-zt's `loadzone ui_boot` skips. The build now loads both.
- After two maps fail in a row, the build skips the rest instead of showing an error box for each.

**Tests**
- The stand-in for x64-zt now behaves the way the real one did on a real PC: it crashes on `dumpasset image`, needs `techsets_ui_boot` for the material, and dumps each zone's images with `dumpzone`. Elvira's card comes from the patched language zone.

### The setup builds the character pictures by itself (2026-10-06)

**Changed**
- The character pictures no longer need a separate step. The first INSTALL (or UPDATE) builds them right after copying the mod, while the window shows which map it is on. Later updates keep them, so they are built once.
  - The game must be closed, because x64-zt cannot run next to it. If it is running, ALL SET says to close it and click REINSTALL.
  - A failed build never fails the install: the menu shows initials, the status line says why, and REINSTALL tries again.
  - Closing the window during the build asks first, then stops x64-zt and removes its files.
  - `-NoPictures` installs without them. `Build Character Pictures.cmd` stays, for building them again after a game update.
- `-NoWindow` installs build them too.
- Version 0.1.1. The console's `[IX] INFO: init 0.1.1` line shows that this build's files are the ones loaded.

**Fixed**
- A newer download showed PLAY instead of UPDATE, because every build so far kept the version number 0.1.0. Clicking PLAY then kept the older mod files, so a fix in a newer download might never have reached the game (unless REINSTALL was used). The setup now compares the installed files with the download's and offers UPDATE when any differs.
- When every map failed, the build's clean-up left empty `dump`/`zonetool` folders in the game folder. It now removes the folders it created, and only those.
- x64-zt could keep running after the build stopped early; it is now ended.

**Tests**
- A download with the same version number but a changed or missing file counts as newer.
- The first `-NoWindow` install builds the pictures and a second does not; a failed build leaves the mod installed. The window's background build script runs in a second runspace, and when stopped mid-run, x64-zt's process is gone and its files removed.

### Character pictures from the HUD's cards (2026-10-06)

**Added**
- **`Build Character Pictures.cmd`** (optional, experimental). It copies the character cards the HUD shows in a match out of the player's own game files into a small picture pack, `iw7-mod/zone/ix_portraits.ff`. Nothing of the game's art ships with the mod.
  - It downloads [x64-zt](https://github.com/Joelrau/x64-zt) and runs it in the game folder once per map, so a map that is missing or fails costs only its own cards. It then builds the pack and deletes x64-zt and its work files.
  - Each card becomes its own material (`ix_card_*` for the main card, `ix_icon_*` for the team card). The materials refer to the game's own menu shaders instead of copying them.
  - Log: `%TEMP%\InfiniteExpansionPictures.log`. UNINSTALL removes the pack.
- With the pack, the CHARACTER menu shows each character's main card from the map selected in the lobby. The team card (the small picture the HUD shows for teammates) appears beside each row, and in the big picture when a main card is missing. Without the pack, nothing changes. `ix_pictures 0` turns the pictures off.
- Tests: the cards to copy and the x64-zt runs; x64-zt's build input from a fake dump; the console exchange and the whole script against a stand-in for x64-zt (`tools/tests/fake_zonetool.py`); the menu with a pack.

**Source**
- x64-zt's behaviour comes from its source (`IW_API_NOTES.md` §18). It has not been run on a real install yet (`TESTING.md` R-PK1–R-PK4, `KNOWN_LIMITATIONS.md` L37).

### Third in-game report: the pick still did not apply (2026-10-06)

**Fixed**
- Choosing a character in the menu still did not change the character in the match.
  - The second attempt wrapped the gametype's loadout function from the mod's start-up. Whether that wrapper is in place in time depends on the order in which the game runs its scripts, and in-game it was not.
  - The mod now replaces the stock function that decides a player's character (`zombies_loadout::get_player_character_num`) with its own, using iw7-mod's `replacefunc`. The stock code calls it on the player at every spawn, so the pick is made exactly when the game asks. Without a pick it hands out a random free character, as the stock function did.
  - With `ix_character_select 0` the stock function is left alone.

### Second in-game report: the pick is applied, CHARACTER moves to the lobby (2026-10-06)

**Fixed**
- The chosen character was not applied. The card in the corner named the pick, but the player was someone else.
  - The game picks a character inside its loadout function, on the first spawn. The mod's pick ran from a second notify after "connected" and arrived after that spawn.
  - The mod now wraps that function (`level.custom_giveloadout`) and makes the pick right before the stock code reads it. A pick that would come too late is not applied halfway, and the console says so.
  - Every outcome is logged as `[IX] INFO: character: …` in the console and in `iw7-mod/logs/console.log`.
- CHARACTER menu text: the name is now large (44) and the description normal (22). IW7 sizes text by the height of its element, and the description's element was 100 tall.

**Changed**
- The CHARACTER button moved from the zombies main menu into the lobby that Solo Match and Custom Game open, right under SELECT SHOW. The buttons under it move down one step, in both of the lobby's layouts (with and without BOSS BATTLE).
- The stock lobby clears the special-character field `characterSelect` every time it opens. The mod puts back a special character chosen in the CHARACTER menu while it is still unlocked.
- Willard Wyler needs The Beast from Beyond's soul key and its merit, as in the stock lobby. The stock lobby also requires Director's Cut; the mod does not (L27).

**Added**
- A picture of the highlighted character: the game's own pictures of the five special characters, and colored initials for the four regular characters and Random, which have no picture in the game's menus (L28).
- Locked special characters are marked "(locked)", say how to unlock them, and cannot be chosen. `ix_character_specials 2` allows them, `0` turns specials off.
- Tests: the lobby list in every load order and both layouts, the lobby field after the stock reset, and the CHARACTER menu's text sizes, pictures and locks.

**Source**
- The lobby's layout, element names and rules come from the game's compiled menu scripts in a public dump, read as data and never run (`IW_API_NOTES.md` §16).

### Fixes from the first in-game report (2026-10-06)

**Fixed**
- The CHARACTER button was missing in the zombies menu when the mod was installed into `<game>\iw7-mod\` (the setup's install).
  - iw7-mod runs scripts from that folder before its own, and its own MainMenu script then replaced the button list, wrapper included (L33).
  - The menu script now hooks `MenuBuilder.BuildRegisteredType` and adds the button when the list is built, in either load order and only once.
- Docs: iw7-mod's search order is `<game>/iw7-mod`, then its client data, then the engine's paths; v1.1.0's Lua `io` table can write files, develop's cannot.

**Added**
- Your Steam name instead of "Unknown Soldier" (L34).
  - The setup reads it from Steam's `loginusers.vdf` (the logged-in or most recent account) and writes it next to the menu script.
  - The menu script sets iw7-mod's `name` setting from it, only while that is still "Unknown Soldier".
  - Names with characters the game cannot show are skipped, and the status line says so.
- `tools/tests/test_menu_script.py` and `menu_harness.lua`: the menu script in plain Lua 5.1, in both load orders. Steam-name tests in `test_installer.py`.
- `check.py` `lua`: `io.*` names are checked against iw7-mod's own scripts too.

**Notes**
- The mod does not appear in the game's Mods menu. It loads from the iw7-mod folder by itself (README).

### Setup installs iw7-mod and starts the game (2026-10-06)

**Added**
- INSTALL now also sets up the iw7-mod client when the game folder has none.
  - It downloads `iw7-mod.exe` from the latest GitHub release, or from iw7-mod's own update server if that fails, and checks it against the listed checksum (SHA-256 / SHA-1).
  - It places the file in the game folder, as iw7-mod's install guide says, and adds an **IW7-Mod (Infinite Warfare)** desktop shortcut.
  - The download runs in the background with progress in the window. DOWNLOAD in the iw7-mod row does only this step.
- The green button walks through INSTALL → UPDATE → **PLAY**. PLAY starts iw7-mod from the game folder and opens Steam first if it is not running. REINSTALL copies the mod again.
- No game yet: **STEAM** opens Steam's install dialog for Infinite Warfare (`steam://install/292730`; the store page if Steam is missing). The window checks again every 4 seconds and notices when the game is there.
- A write check before downloading, so a protected game folder gets the offer to retry as administrator.
- `-NoWindow` installs also download iw7-mod when it is missing.
- Tests: the download against a local fake of GitHub and the update server, and the window's background download in a second runspace.

**Not verified**
- The real GitHub API and update server cannot be reached from the development environment (E6); R-I10–R-I13 check them on a player's PC.

### One-click Windows setup (2026-10-06)

**Added**
- `Infinite Expansion Setup.cmd` opens a setup window (`installer/`) with INSTALL / UPDATE and UNINSTALL buttons.
  - It finds Infinite Warfare through Steam (registry, every library in `libraryfolders.vdf`, the game's app manifest), or the player picks `iw7_ship.exe` with BROWSE.
  - It shows whether the iw7-mod client is there and which version of the mod is installed.
  - Installing copies the mod into `<game>\iw7-mod\`, records the copied files, removes files an older version left, removes the old Mods-menu copy's files, and adds an entry to *Windows Settings → Apps*. Uninstalling removes exactly the recorded files.
  - Artwork, all original vector drawings: a synthwave sunset with a striped sun, a neon ferris wheel, a scrolling pink grid, toxic fog and zombie hands rising from the ground; plus an app icon (`installer/ix.ico`, source `ix-icon.svg`).
  - Errors go to `%TEMP%\InfiniteExpansionSetup.log`. A protected game folder gets an offer to retry as administrator. `-NoWindow` installs or uninstalls from a script.
- `tools/tests/test_installer.py` and `ps51_lint.ps1`: the install logic runs with PowerShell 7 on fake Steam libraries, and the window's files are checked for Windows PowerShell 5.1 and `XamlReader` compatibility. `setup_compilers.sh` fetches PowerShell 7.4.6 for them.
- `.gitattributes`: `.cmd` files keep CRLF line endings, also in GitHub's zip downloads.

**Not verified**
- The window has not been opened yet: WPF needs Windows, and the .NET SDK that could compile-check the XAML cannot be downloaded here (E5). `TESTING.md` §4.8 lists what to check.

### Phase 1.5 — Characters chosen before the match; guests (2026-10-06)

**Changed**
- Characters are chosen only before a match, in the CHARACTER menu. The choice is applied when the player connects and kept for the whole match.
- The menu also writes a special-character pick into the stock lobby field `zombiePlayerLoadout.characterSelect` (`setCoopPlayerData`, then `uploadstats`, like iw7-mod's own Director's Cut setting).
  - Each player's stats reach the host's match, so a guest's special pick follows them into other players' matches.
  - On the special's own map it works even when the host does not have the mod.
- Every special pick is checked against the unlock stats, including picks from the stock lobby (L27). A refused pick gets a random character, as in the stock game, and a message says why.
- No two players can get the same special any more; the stock game allowed it.
- Installation: copy the mod into `<game>/iw7-mod/` (README). A host who loaded the mod from the Mods menu cannot be joined (L30).

**Added**
- Optional, off by default: after the intro, everyone sees "<player> is playing as <character>" for each player (`ix_character_announce 1`).
- `test_character_data.py`: the menu's lobby values must match the cast table.

**Removed**
- The `!char` chat commands, and applying `ix_character` changes mid-match. The knife swap that went with switching is gone too.

**Blocked**
- A guest's pick of a regular character (Sally, Poindexter, Andre, A.J.) cannot reach the host, because no stats field is known to hold it (L29). The guest gets a random character. R-CH12 is a console probe that could unblock it.

**Findings**
- iw7-mod v1.1.0 and develop do not let players join a host whose `fs_game` is set when it has no `mod.ff`: "Server 'mod_hash' is empty" (`party.cpp`, L30).

### Phase 1.5 — CHARACTER button in the zombies menu (2026-10-06)

**Added**
- `ui_scripts/InfiniteExpansion/__init__.lua`: a base-game style CHARACTER button under the zombies main menu's buttons.
  - It opens a list (Random, the four regular characters, the five specials). Hovering shows each character's outfit on every map.
  - Picking one saves the archived dvar `ix_character`, which the GSC applies to the host at match start (L29). `random` lets the game pick.
  - It is built only from widgets and calls that iw7-mod's own ui_scripts use.
- `check.py` `lua`: `luac5.1` syntax, plus API names checked against iw7-mod's ui_scripts (pinned and fetched by `setup_compilers.sh`), plus folder rules. Lua fixtures in `tools/tests`.

### Phase 1.5 — Characters (2026-10-06)

**Added**
- `ix/player/character.gsc`: choose who you play as.
  - In chat, `!char` lists the map's cast and `!char <number or name>` switches. The host can also set the `ix_character` dvar.
  - The switch is immediate: body, arms, voice and knife change, and the stock HUD portrait follows. A downed player switches on the next spawn.
  - Characters are unique per match, and the stock random pool stays consistent.
  - Each map has its own cast list. The actor names come from the stock VO code; the outfit labels come from each map's model names.
  - Special characters (The Hoff, Willard Wyler, Kevin Smith, Pam Grier, Elvira) are available to players who have unlocked them through soul keys or, for Willard, the Beast merit (`ix_character_specials`).
  - Experimental and opt-in: special characters on maps other than their own (`ix_character_crossmap 1`, L26). A special picked in the stock lobby is then honoured on any map.
- `ix/ui/player_card.gsc`: a bottom-right card with the character's name and outfit (`ix_player_card`, `_x`, `_y`). There is no picture yet (L28).
- `ix/core/util.gsc`: `dvar_int` and `dvar_string` for settings with defaults.
- `tools/tests/test_character_data.py`: checks the character table against the stock scripts.

**Findings**
- The stock character system, the HUD portrait omnvar and the unlock stats (`IW_API_NOTES.md` §15).
- Each special character's models are referenced only by its own map, so they are probably missing elsewhere (L26).

### Scope: zombies only (2026-10-06)

Multiplayer support was dropped at the project owner's request.

**Removed**
- The multiplayer entry script `custom_scripts/mp/ix_main.gsc` and the `ix/mp` module.
- The `faux_spawn` watcher; only multiplayer sends that notify.

**Changed**
- `bootstrap::start(modules)` no longer takes a mode, and the init line no longer prints `mode=`.
- `check.py`: the multiplayer/shared separation rule is replaced by a zombies rule. A stock far-call target must be a script that **every** zombies map loads; anything else ends the match with a script link error. The rule uses each map's link closure, computed from the dump. The `modes` check is now `layout`.
- Docs: `ARCHITECTURE.md` §7 is now the zombies scope rules. `TESTING.md` R-S2 is now a co-op check.

**Added**
- `check.py` `source` rejects `//` comments that end in a backslash: both compilers silently drop the next line (C9).

**Findings**
- 126 stock scripts load on every zombies map, including everything the feature plan uses. `scripts\mp\hud_util` loads on none, so `IW_API_NOTES.md` §7 is corrected; map scripts load only on their own map (L25).

### Phase 1 — Foundation (2026-10-06)

**Added**
- The mod folder `mods/infinite_expansion/` (version 0.1.0) with `desc.txt`.
  - Entry scripts `custom_scripts/cp/ix_main.gsc` and `custom_scripts/mp/ix_main.gsc`.
  - `ix/core/bootstrap.gsc`: duplicate-init guard, master switch `ix_enabled`, `level.ix` state, init order (core `setup()`, then each module's `register()`), the lifecycle notifies `ix_ready`, `ix_player_connected`, `ix_player_spawned`, and `ix_shutdown`, plus `ix_version`.
  - `ix/core/log.gsc`: `[IX] LEVEL:` console lines, `ix_debug_log`, and a 32-line ring buffer.
  - `ix/core/compat.gsc`: client feature detection and the nine raw-id wrappers (`god_off`, `local_sound`, `third_person`, `fire_rate_on`/`off`, `recoil_get`/`off`, `spread_reset`, `has_perk`).
  - `ix/core/util.gsc`: the first helpers.
  - One placeholder module per area (player, weapons, zombies, mp, debug, ui).
- `tools/ixcc`: compiles a script the way iw7-mod's in-game loader does, with iw7-mod's 28 extension built-ins registered. `setup_compilers.sh` now builds it for both pins and fetches the pinned stock-script dump.
- `tools/check.py`: compile with both compilers, parity, stub natives and raw ids, far-call targets, mode separation, source rules, and the per-mode memory budget.
- `tools/tests`: 11 tests on a rule-breaking and a clean fixture mod.

**Findings**
- An unresolved script reference is a `script link error` that drops the match (L23).
- Script runtime errors are silent unless `developer_script` is on, and that dvar also compiles `/# #/` blocks (L24). Testers now launch with `+set developer_script 1`.
- Both compilers reject a script function named after a built-in.
- An unknown raw id compiles silently (C6), and iw7-mod's extension ids depend on registration order (C7). `check.py` catches both.
- `scripts\engine\utility::waittill_any` ends its caller on any notify but the first, so the bootstrap uses one watcher thread per notify.
- iw7-mod's own scripts use 711 bytes (CP) and 6,823 bytes (MP) of the 1 MiB custom-script memory.

**Changed**
- Module entry points are `register()` (feature modules) and `setup()` (core). Only entry scripts define `init()`, which iw7-mod runs in every auto-loaded file. `ARCHITECTURE.md` §3 documents the implemented flow.

**Not yet verified in-game**: everything under `mods/`. `TESTING.md` R-S1, R-S2, and R-S5 to R-S9 are the first runtime checks.

### Phase 0 — BO3 reference analysis completed (2026-10-06)

**Added**
- `PROJECT_ANALYSIS.md` §1 rewritten from the real AAE v3.9.5 package: folder structure, method and limits, script structure, init flow, configuration flow (~80 `tfoption_*` keys), the five UI surfaces, shared utilities, assets, multiplayer handling, and dependencies.
- §3 compatibility matrix rebuilt from AAE's actual options (116 rows), each mapped to a verified IW7 mechanism. §4 records the decisions that follow.
- `tools/bo3_reference/` reproduces the analysis workspace from the archive in about 30 s: fastfile decompressor, script carver, LUI string inventory, localized-string extractor, and Dropbox hash checker.
- `ARCHITECTURE.md` §10 maps AAE's components onto this design. Limitations L21 and L22 added; E1 resolved.

**Findings**
- AAE's primary UX is client-side LUI: lobby "Custom Mutations" options, client options, career screen, and HUD widgets. Its GSC menu is a gated dev/cheat menu.
- AAE's configuration is a flat key set, saved by the UI and read by GSC at match start behind a version guard. Infinite Expansion adopts the same model with `ix_*` keys and a GSC-written settings file.

### Phase 0 — Project forensics (2026-10-06)

**Added**
- `PROJECT_ANALYSIS.md`: IW7 modding environment (tools, language, APIs, build, packaging, testing, limitations) and a provisional BO3 feature inventory with a feature compatibility matrix.
- `IW_API_NOTES.md`: verified IW7 / iw7-mod scripting reference, with a source for every entry.
- `KNOWN_LIMITATIONS.md`, `ARCHITECTURE.md` (proposed), `FEATURE_STATUS.md`, `TESTING.md`, `README.md`.
- `tools/setup_compilers.sh`: builds the two gsc-tool versions that iw7-mod embeds (v1.1.0 pin `833822d0`, develop pin `0be361a4`).
- `tools/extract_iw7_builtins.py`: dumps builtin function and method tables for comparison.

**Findings**
- The iw7-mod v1.1.0 compiler resolves `disableinvulnerability` and `playlocalsound` to the wrong natives. This was verified by compiling and disassembling. The mod will use raw ids `_meth_80A1` and `_meth_8242`.
- 503 method and 5 function names compile only on iw7-mod develop. Raw `_meth_` ids work on both.

**Blocked**
- BO3 reference archive (`/AllAroundEnhancement.7z`): not downloadable in the build environment (egress policy). Its file-level analysis is pending.
