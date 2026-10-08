# Infinite Expansion

A modular enhancement framework for the **zombies** mode of **Call of Duty: Infinite Warfare** (IW7). It is inspired by *All-Around Enhancement* for Black Ops III: an in-game menu, configurable gameplay, player, weapon, and zombie options, an info HUD, quality-of-life features, and developer tools.

The BO3 mod serves only as a reference. Nothing is copied from it, and every feature is rebuilt on top of what Infinite Warfare and the **iw7-mod** client actually expose.

> **Status: Phase 3 (in-game menu) complete — not yet run in-game.**
> The in-game menu (ADS + Melee) shows and changes every setting. It sits on the settings, chat commands, saving and launcher of Phase 2 (confirmed working in a real match) and the character features of Phase 1.5. Everything passes every offline check with both iw7-mod compilers; `TESTING.md` §4 lists the checks a tester can do.

## Requirements

- A legally owned copy of *Call of Duty: Infinite Warfare* (Steam).
- **iw7-mod** client, latest release **v1.1.0** or a newer develop build. Stock IW7 cannot load custom scripts. The one-click setup downloads it for you.

## Installation

### One-click setup (Windows)

1. Download this repository (on GitHub: **Code → Download ZIP**) and extract the whole zip.
2. Double-click **`Infinite Expansion Setup.cmd`**.
3. Click **INSTALL**. When it says ALL SET, the button becomes **PLAY**. Click **UNINSTALL** in the same window to remove the mod again.
4. From then on, start the game with **Infinite Expansion** on your desktop, or `Infinite Expansion.exe` in the game folder ([the launcher](#the-launcher)).

What the setup does for you:

| Step | How |
|------|-----|
| Finds the game | Through Steam, including libraries on other drives. Not installed yet? **STEAM** opens Steam's own install dialog (you must own the game), and the window notices when the game is there. Installed somewhere else? **BROWSE** to `iw7_ship.exe` |
| Installs the iw7-mod client, if the game folder has none | Downloads `iw7-mod.exe` from the latest release on [iw7-mod's GitHub page](https://github.com/auroramod/iw7-mod/releases), or from iw7-mod's own update server if GitHub fails. It checks the file against the checksum the source lists and puts it in the game folder, as iw7-mod's install guide says. **DOWNLOAD** in the iw7-mod row does only this step |
| Installs the mod | Copies it into `<Infinite Warfare>\iw7-mod\` and records the copied files in `iw7-mod\infinite-expansion.json`. Also removes an old copy in `mods\infinite_expansion` (see below), keeping any file of your own in it |
| Adds the launcher | Builds `Infinite Expansion.exe` in the game folder and an **Infinite Expansion** shortcut on the desktop. See [The launcher](#the-launcher) |
| Builds the character pictures, the first time | Right after installing, while the window shows its progress (a few minutes, once): the cards the HUD shows in a match, copied from your own game files for the CHARACTER menu. See [Character pictures](#character-pictures-automatic-experimental) |
| Starts the game | **PLAY** starts the game through the launcher, which waits for Steam. iw7-mod's first start downloads the rest of its own files; then pick Zombies in the main menu |

The mod does **not** appear in the game's **Mods** menu. That menu lists only `mods\` folders, and this install loads by itself. To check that it works, look for the CHARACTER button in the lobby after **Solo Match** or **Custom Game**, and the card in the corner of a match (`TESTING.md` §4).

INSTALL also sets your in-game name to your Steam name. iw7-mod calls everyone "Unknown Soldier" otherwise. A name you already chose with `name <new name>` in the console stays.

UNINSTALL removes exactly the recorded mod files; other mods' scripts and the iw7-mod client stay. To remove iw7-mod too, follow [its uninstall guide](https://github.com/auroramod/docs/blob/main/docs/iw7-uninstall.md).

INSTALL also adds **Infinite Expansion** to *Windows Settings → Apps*, so you can uninstall from there after deleting the download; it keeps a copy of the setup in `%LOCALAPPDATA%\InfiniteExpansion` for that, and uninstalling deletes it. Running the setup from a newer download replaces the installed files: the button then reads UPDATE. It compares the files themselves, so this works even when the version number did not change.

### The launcher

`Infinite Expansion.exe`, in the game folder next to `iw7_ship.exe`, starts the modded game in one double-click; the desktop shortcut **Infinite Expansion** points at it. It:

1. checks that `iw7-mod.exe` is there, and that the mod is installed (if not, it asks whether to start iw7-mod anyway);
2. does nothing if the game is already running;
3. starts Steam if it is not running, and waits until you are signed in (up to five minutes; Steam shows its own window meanwhile). iw7-mod refuses to start without Steam ("Steam must be running to play this game!");
4. starts `iw7-mod.exe` from the game folder. The game opens on its main menu: pick **Zombies**. iw7-mod has a `-zombies` switch, but it only works on dedicated servers.

The setup builds the launcher on your PC with the C# compiler that comes with Windows (.NET Framework 4), from `installer\IXLauncher.cs`, which you can read. So the download contains no program file, and Windows has no downloaded program to warn about. Every INSTALL, UPDATE and REINSTALL builds it again; UNINSTALL deletes it and its shortcut. If it cannot be built, the status line says why, and PLAY and `iw7-mod.exe` start the game as before.

Arguments given to the launcher go on to iw7-mod: a shortcut target such as `"...\Infinite Expansion.exe" +set ix_debug_log 1` works.

### Windows warnings and logs

Windows asks before running a file from the internet, and the setup is not code-signed, so it may show "Windows protected your PC". Choose *More info → Run anyway*. The setup is plain PowerShell (`installer\IXSetup.ps1`) that you can read first. If something goes wrong, details go to `%TEMP%\InfiniteExpansionSetup.log`. For a protected game folder, the setup offers to retry as administrator.

### By hand

Copy the two folders inside `mods/infinite_expansion` into the `iw7-mod` folder of your game. Every player who wants the CHARACTER menu installs it the same way:

```text
copy  mods/infinite_expansion/custom_scripts   →   <Infinite Warfare>/iw7-mod/custom_scripts
copy  mods/infinite_expansion/ui_scripts       →   <Infinite Warfare>/iw7-mod/ui_scripts
```

The mod then runs in every zombies match you host, and friends can join you. The setup's UNINSTALL also removes a copy made this way.

**Solo only:** you can instead copy `mods/infinite_expansion` to `<Infinite Warfare>/mods/` and load it from the **Mods** menu (or launch with `+set fs_game "mods/infinite_expansion"`). Nobody can join a game started that way. iw7-mod asks joining players to download the host's `mod.ff`, and this mod has none, so they get "Server 'mod_hash' is empty" (`KNOWN_LIMITATIONS.md` L30).

Start a zombies match and open the console (`~`). It should show:

```text
[IX] INFO: init 0.3.1 map=cp_zmb modules=player,weapons,zombies,debug,ui
[IX] INFO: client fs_game=0 omnimovement=… sprint_unlimited=… air_control=…
[IX] INFO: settings: 8 (0 changed from the default); features: 1; chat: !ix
[IX] INFO: ready
```

`fs_game=1` instead means the mod was loaded from the Mods menu.

## The in-game menu

In a match, **hold ADS (aim) and press Melee** to open the menu, or type `!ix menu` in chat. A line after your first spawn reminds you.

| Keyboard | Controller | In the menu |
|----------|------------|-------------|
| **W / S** | Left stick up / down | Move up / down (hold to keep moving) |
| **A / D** | Left stick left / right | Change the highlighted value: less / more |
| **Use** or **Jump** | Use or Jump | Open a page, switch a setting on or off, run an action |
| **Melee** | Melee | Back; on the first page, close |

The two lines at the bottom of the menu say the same, and `<` `>` around a value mean A / D change it. ADS / Fire also move up and down, and Tactical / Frag also change a value.

While the menu is open you stand still: the movement keys steer the menu instead of you, and your weapon, grenades, melee and Use are off. You can still look around, and zombies can still hit you. Closing the menu gives everything back at once. It opens only while you stand on the ground, and it closes by itself if you go down.

Its pages: **Characters**, **Menu** (its own settings), **Settings** (how many differ from the default, *Reset every setting*, the version) and **Debug**. Later phases add theirs. Each row shows a setting's current value, and the lines under the list say what it does and which values it takes. Everyone can open the menu; only the host can change settings (they apply to the whole match), unless the host sets *Menu: who changes settings* to *everyone*.

## Settings and chat commands

Every option of the mod is a **setting** with a type, a default and a valid range. Change one in any of three ways:

- **The in-game menu** (above).
- **Chat** (press the chat key in a match): `!ix set character_announce 1`. Only the host can change settings; everyone can look.
- **Console** (`~`): `set ix_character_announce 1`. It applies within half a second.

Changes are **saved** by themselves: the mod stores them in your game config (as `seta ix_<setting> <value>`, the way the CHARACTER menu saves your pick), so the next game starts with them. This works in the normal install, which friends can join; nothing is written anywhere else. Settings belong to the host: in someone else's match, theirs apply. A value outside a setting's range is refused (`!ix` says what is valid), and numbers are kept within their range.

| Chat command | Does |
|--------------|------|
| `!ix` | Lists the commands |
| `!ix list` / `!ix list character` | Every setting with its value / only those whose name contains "character" |
| `!ix get <setting>` | Its value, default, valid values and what it does |
| `!ix set <setting> <value>` | Host: changes it |
| `!ix on <setting>` / `!ix off <setting>` | Host: switches an on/off setting |
| `!ix reset <setting>` / `!ix reset all` | Host: back to the default |
| `!ix version` | The mod's version |
| `!ix menu` | Opens the in-game menu |

| Setting | Default | Range | Effect |
|---------|---------|-------|--------|
| `debug_log` | 0 | 0/1 | Extra `[IX] DEBUG:` lines in the console and `iw7-mod\logs\console.log` |
| `character_select` | 1 | 0/1 | Character selection (from the next map) |
| `character_specials` | 1 | 0–2 | 0 = no special characters, 1 = the ones each player has unlocked, 2 = all |
| `character_crossmap` | 0 | 0/1 | **Experimental:** special characters on other maps (from the next map) |
| `character_announce` | 0 | 0/1 | An "is playing as" line for each player after the intro |
| `menu` | 1 | 0/1 | The in-game menu; switching it off closes it for everyone |
| `menu_access` | host | host, everyone | Who may change settings in the menu |
| `menu_hint` | 1 | 0/1 | The line after your first spawn saying how to open the menu |

These dvars are not settings, because they are not the host's to set:

| Dvar | Effect |
|------|--------|
| `ix_enabled 0` | Turns the whole mod off from the next map load |
| `ix_version` | Set by the mod: the loaded version |
| `ix_character` | Your pick in the CHARACTER menu ([Choosing your character](#choosing-your-character)) |
| `ix_pictures 0` | Your CHARACTER menu shows initials instead of the [character pictures](#character-pictures-automatic-experimental) |

## Choosing your character

In the **Zombies** menu, choose **Solo Match** or **Custom Game**. In the lobby, press **CHARACTER** (under SELECT SHOW) and pick a character before you start the match. The menu shows a picture of the highlighted character, and locked special characters say how to unlock them. You keep that character for the whole match. There is no switching mid-match.

Back in the lobby, a big card of the character you picked shows in the **bottom right**, under the players' cards. A regular character shows their card from the selected show (from the [picture pack](#character-pictures-automatic-experimental); without it, their initials); a special character their own card (without the pack, the game's own picture of them, which then no longer appears in the lower middle); Random shows nothing. With a second player in the lobby the card gets smaller to fit; with three or four there is no room left under the player list, so it moves to the lower middle, where the game shows special characters.

To see what happened to your pick, open the console (`~`) in the match, or read `iw7-mod\logs\console.log` afterwards. The mod writes one line per player, for example `[IX] INFO: character: Alex -> Andre (ix_character)`, or the reason it gave you a random character.

| Your pick | In a match you host | When you join someone else's match |
|-----------|---------------------|------------------------------------|
| Sally, Poindexter, Andre or A.J. | You play as them | The game picks a random character. The host's game cannot see this pick (`KNOWN_LIMITATIONS.md` L29) |
| A special character you have unlocked | You play as them on their own map. On other maps only with the setting `character_crossmap` on | The same. The pick travels with you in the stock lobby setting, so on the character's own map it works even if the host does not have this mod |
| Random | The game picks | The game picks |

No two players can be the same character. If your pick is taken, locked or not allowed on this map, you get a random character and a message says why. If the host switches on `character_announce` (`!ix on character_announce`), everyone also sees a line such as "Alex is playing as Andre (Rapper)" for each player after the intro.

The rules are enforced by the host's copy of the mod. A host without the mod runs the stock game, which hands out a special character on its own map without checking the unlock.

The CHARACTER menu stores your pick in the dvar `ix_character`, applied on your first spawn in matches you host. The host's [settings](#settings-and-chat-commands) `character_select`, `character_specials`, `character_crossmap` and `character_announce` control the rest. `character_crossmap` is **experimental** (The Hoff on any map, for example): their models may not exist on other maps (`KNOWN_LIMITATIONS.md` L26), and like `character_select` it takes effect from the next map.

### Character pictures (automatic, experimental)

The game's menus only have pictures of the special characters, so the CHARACTER menu used to show big initials for Sally, Poindexter, Andre and A.J. The cards the HUD shows in a match exist only inside each map's own files, which the menus cannot reach while you are in the lobby (`KNOWN_LIMITATIONS.md` L28). So the setup copies those cards out of *your own* game files into a small picture pack. Nothing of the game's art ships with this mod.

It happens **once, by itself**, the first time you click INSTALL (or UPDATE): after copying the mod, the window says BUILDING CHARACTER PICTURES and shows which map it is on. It takes a few minutes, and the game must be closed. After that the CHARACTER menu shows each character's card from the map selected in the lobby. The team card (the small picture the HUD shows for teammates) appears beside each name. Later updates keep the pack, so it is never built again.

Pam Grier's only card is Shaolin Shuffle's, a New York ID card twice as wide as it is high; the menu draws it in that shape, as the game's HUD does.

What it does:

- **Downloads the tool.** It fetches [x64-zt](https://github.com/Joelrau/x64-zt), the community fastfile tool, from its latest GitHub release and checks the checksum GitHub lists.
- **Copies the cards.** It runs x64-zt in the game folder once per map, then builds `iw7-mod\zone\ix_portraits.ff` and a list of what it holds (`ix_portraits.txt`).
- **Cleans up.** It deletes x64-zt and its work files afterwards. Your own files in `dump\`, `zonetool\` or `zone_source\` stay.
- **Skips missing maps.** A map you do not have (DLC) is skipped, and those characters keep their initials.
- **Logs.** Details go to `%TEMP%\InfiniteExpansionPictures.log`.

If it cannot finish, the mod is still installed and the menu shows initials. The status line says why, and **REINSTALL** tries again; so does the game running during INSTALL. Closing the window during the build stops it cleanly. If a "ZoneTool ERROR" box appears, click OK: that map is skipped, and after two in a row the rest are too. Please send the log and the newest `minidumps\zonetool-crash-*.zip` from the game folder.

To build the pictures again (after a game update, for example), double-click **`Build Character Pictures.cmd`** with the game closed. `ix_pictures 0` hides them without deleting them, and UNINSTALL removes them. To install without them, start the setup with `-NoPictures` (`"Infinite Expansion Setup.cmd" -NoPictures` in a command prompt).

This is the newest and least tested part of the mod: `TESTING.md` R-PK1 to R-PK5 list what to check.

## Documentation

| File | Contents |
|------|----------|
| `PROJECT_ANALYSIS.md` | Phase 0 forensics: BO3 reference (AAE v3.9.5), IW7 modding environment, feature compatibility matrix |
| `IW_API_NOTES.md` | Verified IW7 / iw7-mod scripting reference, with sources for every API |
| `KNOWN_LIMITATIONS.md` | Engine, client, compiler, and environment limits, with workarounds |
| `ARCHITECTURE.md` | Module layout, init flow, the core systems (settings, events, features, chat commands), and how to add a feature |
| `FEATURE_STATUS.md` | Every planned feature and its status |
| `TESTING.md` | Verification levels, verification log, runtime test checklist |
| `CHANGELOG.md` | History |
| `tools/README.md` | Offline toolchain: both iw7-mod compilers, `ixcc`, `check.py` and its tests |
| `installer/` | The Windows setup: `IXSetup.ps1` (window), `IXSetup.Core.ps1` (install logic), `IXSetup.xaml` (layout and artwork); the launcher's source, `IXLauncher.cs`; the picture pack: `IXPictures.ps1` and `IXPictures.Core.ps1` |

## Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Project forensics | **Complete** |
| 1 | Foundation (entry scripts, bootstrap, compat, check tooling) | **Complete** (in-game test pending) |
| 1.5 | Characters: choose who you play as, per-map names, special characters | **Complete** (in-game test pending) |
| 2 | Core systems (settings, saving, chat commands, events, features, utilities) and the launcher | **Complete** (in-game test pending) |
| 3 | In-game menu (ADS + Melee, W / S / A / D), the lobby's character card | **Complete** (in-game test pending) |
| 4 | Player features | Next |
| 5 | Movement | Planned |
| 6 | Weapons | Planned |
| 7 | Zombies | Planned |
| 8 | HUD | Planned |
| 9 | Quality of life | Planned |
| 10 | Debug / developer mode | Planned |
| 11 | Configuration presets | Planned |
| 12 | Polish | Planned |
| 13 | Testing | Planned |

## Development

```bash
tools/setup_compilers.sh                        # once: both iw7-mod compilers, ixcc, stock script reference
python3 tools/check.py                          # every static check; must PASS before a commit
python3 -m unittest discover -s tools/tests     # tests: the checker, the setup, the launcher, the menu script
```

Every script must compile with **both** compilers and call the same natives under each; `IW_API_NOTES.md` §4 explains why. `tools/README.md` lists every check.

## Acknowledgements

- [auroramod/iw7-mod](https://github.com/auroramod/iw7-mod): the client that makes IW7 modding possible.
- [xensik/gsc-tool](https://github.com/xensik/gsc-tool) and [auroramod/gsc-tool](https://github.com/auroramod/gsc-tool): the IW7 GSC compiler, used offline for verification and not redistributed here.
- [mjkzy/iw7-gsc-dump](https://github.com/mjkzy/iw7-gsc-dump): the stock script reference.
- The authors of *All-Around Enhancement* (BO3), whose design is the inspiration. No code or assets from it are used.

Not affiliated with Activision, Infinity Ward, or the authors of the projects above.
