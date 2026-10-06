# Infinite Expansion

A modular enhancement framework for the **zombies** mode of **Call of Duty: Infinite Warfare** (IW7). It is inspired by *All-Around Enhancement* for Black Ops III: an in-game menu, configurable gameplay, player, weapon, and zombie options, an info HUD, quality-of-life features, and developer tools.

The BO3 mod serves only as a reference. Nothing is copied from it, and every feature is rebuilt on top of what Infinite Warfare and the **iw7-mod** client actually expose.

> **Status: Phase 1.5 (characters) complete — not yet run in-game.**
> The mod skeleton and the character features pass every offline check with both iw7-mod compilers. Nothing has been confirmed in a real match yet: `TESTING.md` §4 lists the first checks a tester can do.

## Requirements

- A legally owned copy of *Call of Duty: Infinite Warfare* (Steam).
- **iw7-mod** client, latest release **v1.1.0** or a newer develop build. Stock IW7 cannot load custom scripts. The one-click setup downloads it for you.

## Installation

### One-click setup (Windows)

1. Download this repository (on GitHub: **Code → Download ZIP**) and extract the whole zip.
2. Double-click **`Infinite Expansion Setup.cmd`**.
3. Click **INSTALL**. When it says ALL SET, the button becomes **PLAY**. Click **UNINSTALL** in the same window to remove the mod again.

What the setup does for you:

| Step | How |
|------|-----|
| Finds the game | Through Steam, including libraries on other drives. Not installed yet? **STEAM** opens Steam's own install dialog (you must own the game), and the window notices when the game is there. Installed somewhere else? **BROWSE** to `iw7_ship.exe` |
| Installs the iw7-mod client, if the game folder has none | Downloads `iw7-mod.exe` from the latest release on [iw7-mod's GitHub page](https://github.com/auroramod/iw7-mod/releases), or from iw7-mod's own update server if GitHub fails. It checks the file against the checksum the source lists, puts it in the game folder as iw7-mod's install guide says, and adds an **IW7-Mod (Infinite Warfare)** desktop shortcut. **DOWNLOAD** in the iw7-mod row does only this step |
| Installs the mod | Copies it into `<Infinite Warfare>\iw7-mod\` and records the copied files in `iw7-mod\infinite-expansion.json`. Also removes an old copy in `mods\infinite_expansion` (see below), keeping any file of your own in it |
| Starts the game | **PLAY** starts iw7-mod from the game folder (Steam must be running; PLAY opens Steam if it is not). iw7-mod's first start downloads the rest of its own files, then pick Zombies |

The mod does **not** appear in the game's **Mods** menu. That menu lists only `mods\` folders, and this install loads by itself. To check that it works, see the CHARACTER button in the Zombies menu and the card in the corner of a match (`TESTING.md` §4).

INSTALL also sets your in-game name to your Steam name. iw7-mod calls everyone "Unknown Soldier" otherwise. A name you already chose with `name <new name>` in the console stays.

UNINSTALL removes exactly the recorded mod files; other mods' scripts and the iw7-mod client stay. To remove iw7-mod too, follow [its uninstall guide](https://github.com/auroramod/docs/blob/main/docs/iw7-uninstall.md).

INSTALL also adds **Infinite Expansion** to *Windows Settings → Apps*, so you can uninstall from there after deleting the download; it keeps a copy of the setup in `%LOCALAPPDATA%\InfiniteExpansion` for that, and uninstalling deletes it. Running the setup from a newer download replaces the installed files, and the button then reads UPDATE.

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
[IX] INFO: init 0.1.0 map=cp_zmb modules=player,weapons,zombies,debug,ui
[IX] INFO: client fs_game=0 omnimovement=… sprint_unlimited=… air_control=…
[IX] INFO: ready
```

`fs_game=1` instead means the mod was loaded from the Mods menu.

Only the Mods-menu install lets scripts write files (L9). Nothing uses that yet; a later phase that saves settings to disk will have to handle both installs.

| Dvar | Effect |
|------|--------|
| `ix_enabled 0` | Turns the whole mod off from the next map load |
| `ix_debug_log 1` | Prints extra `[IX] DEBUG:` lines |
| `ix_version` | Set by the mod: the loaded version |

## Choosing your character

In the **Zombies** menu, press **CHARACTER** (under the other buttons) and pick a character before you start or join a match. You keep that character for the whole match. There is no switching mid-match.

| Your pick | In a match you host | When you join someone else's match |
|-----------|---------------------|------------------------------------|
| Sally, Poindexter, Andre or A.J. | You play as them | The game picks a random character. The host's game cannot see this pick (`KNOWN_LIMITATIONS.md` L29) |
| A special character you have unlocked | You play as them on their own map. On other maps only with `ix_character_crossmap 1` | The same. The pick travels with you in the stock lobby setting, so on the character's own map it works even if the host does not have this mod |
| Random | The game picks | The game picks |

No two players can be the same character. If your pick is taken, locked or not allowed on this map, you get a random character and a message says why. If the host sets `ix_character_announce 1`, everyone also sees a line such as "Alex is playing as Andre (Rapper)" for each player after the intro. The card in the bottom-right corner shows your own character.

The rules are enforced by the host's copy of the mod. A host without the mod runs the stock game, which hands out a special character on its own map without checking the unlock.

| Dvar | Default | Effect |
|------|---------|--------|
| `ix_character <name>` | – | Set by the CHARACTER menu: your character in matches you host, read when the match starts |
| `ix_character_select 0` | 1 | Host: turns character selection off |
| `ix_character_specials` | 1 | Host: 0 = no special characters, 1 = the ones each player has unlocked, 2 = all of them |
| `ix_character_crossmap 1` | 0 | Host, **experimental:** special characters on other maps (The Hoff on any map, for example). Set it before the map loads; their models may not exist on other maps (`KNOWN_LIMITATIONS.md` L26) |
| `ix_character_announce 1` | 0 | Host: an "is playing as" line for each player after the intro |
| `ix_player_card 0` | 1 | Host: hides the card; `ix_player_card_x` / `ix_player_card_y` move it |

## Documentation

| File | Contents |
|------|----------|
| `PROJECT_ANALYSIS.md` | Phase 0 forensics: BO3 reference (AAE v3.9.5), IW7 modding environment, feature compatibility matrix |
| `IW_API_NOTES.md` | Verified IW7 / iw7-mod scripting reference, with sources for every API |
| `KNOWN_LIMITATIONS.md` | Engine, client, compiler, and environment limits, with workarounds |
| `ARCHITECTURE.md` | Module layout, init flow (implemented in Phase 1), and planned core interfaces |
| `FEATURE_STATUS.md` | Every planned feature and its status |
| `TESTING.md` | Verification levels, verification log (Phases 0–1), runtime test checklist |
| `CHANGELOG.md` | History |
| `tools/README.md` | Offline toolchain: both iw7-mod compilers, `ixcc`, `check.py` and its tests |
| `installer/` | The Windows setup: `IXSetup.ps1` (window), `IXSetup.Core.ps1` (install logic), `IXSetup.xaml` (layout and artwork) |

## Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Project forensics | **Complete** |
| 1 | Foundation (entry scripts, bootstrap, compat, check tooling) | **Complete** (in-game test pending) |
| 1.5 | Characters: choose who you play as, per-map names, special characters, player card | **Complete** (in-game test pending) |
| 2 | Core systems (features, config, events, utilities) | Next |
| 3 | Main menu | Planned |
| 4 | Player features | Planned |
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
python3 -m unittest discover -s tools/tests     # tests for the checker
```

Every script must compile with **both** compilers and call the same natives under each; `IW_API_NOTES.md` §4 explains why. `tools/README.md` lists every check.

## Acknowledgements

- [auroramod/iw7-mod](https://github.com/auroramod/iw7-mod): the client that makes IW7 modding possible.
- [xensik/gsc-tool](https://github.com/xensik/gsc-tool) and [auroramod/gsc-tool](https://github.com/auroramod/gsc-tool): the IW7 GSC compiler, used offline for verification and not redistributed here.
- [mjkzy/iw7-gsc-dump](https://github.com/mjkzy/iw7-gsc-dump): the stock script reference.
- The authors of *All-Around Enhancement* (BO3), whose design is the inspiration. No code or assets from it are used.

Not affiliated with Activision, Infinity Ward, or the authors of the projects above.
