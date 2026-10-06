# Infinite Expansion

A modular enhancement framework for the **zombies** mode of **Call of Duty: Infinite Warfare** (IW7). It is inspired by *All-Around Enhancement* for Black Ops III: an in-game menu, configurable gameplay, player, weapon, and zombie options, an info HUD, quality-of-life features, and developer tools.

The BO3 mod serves only as a reference. Nothing is copied from it, and every feature is rebuilt on top of what Infinite Warfare and the **iw7-mod** client actually expose.

> **Status: Phase 1 (foundation) complete — loads, but has no gameplay options yet.**
> The mod skeleton (entry scripts, bootstrap, logging, compatibility layer) passes every offline check with both iw7-mod compilers. It has **not been run in-game yet**: see `TESTING.md` §4 for the first checks a tester can do.

## Requirements

- A legally owned copy of *Call of Duty: Infinite Warfare* (Steam).
- **iw7-mod** client, latest release **v1.1.0** or a newer develop build. Stock IW7 cannot load custom scripts.

## Installation

```text
copy  mods/infinite_expansion   →   <Infinite Warfare>/mods/infinite_expansion
in game: Mods menu → infinite_expansion   (or launch with +set fs_game "mods/infinite_expansion")
```

Start a zombies match and open the console (`~`). It should show:

```text
[IX] INFO: init 0.1.0 map=cp_zmb modules=player,weapons,zombies,debug,ui
[IX] INFO: client fs_game=1 omnimovement=… sprint_unlimited=… air_control=…
[IX] INFO: ready
```

Installing as a mod folder will let later phases save settings to disk. Copying `custom_scripts` into `iw7-mod/custom_scripts` also loads the mod, but settings will then last only for the session.

| Dvar | Effect |
|------|--------|
| `ix_enabled 0` | Turns the whole mod off from the next map load |
| `ix_debug_log 1` | Prints extra `[IX] DEBUG:` lines |
| `ix_version` | Set by the mod: the loaded version |

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

## Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Project forensics | **Complete** |
| 1 | Foundation (entry scripts, bootstrap, compat, check tooling) | **Complete** (in-game test pending) |
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
