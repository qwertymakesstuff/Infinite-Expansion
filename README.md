# Infinite Expansion

A modular enhancement framework for **Call of Duty: Infinite Warfare** (IW7), with zombies as the first target. It is inspired by *All-Around Enhancement* for Black Ops III: an in-game menu, configurable gameplay, player, weapon, and zombie options, an info HUD, quality-of-life features, and developer tools.

The BO3 mod serves only as a reference. Nothing is copied from it, and every feature is rebuilt on top of what Infinite Warfare and the **iw7-mod** client actually expose.

> **Status: Phase 0 (project forensics) — no playable build yet.**
> The IW7 research is complete. Analysis of the BO3 reference files is **blocked**, because the archive can't be downloaded into the build environment (see `PROJECT_ANALYSIS.md` §1.1).

## Requirements (for players, once Phase 1 ships)

- A legally owned copy of *Call of Duty: Infinite Warfare* (Steam).
- **iw7-mod** client, latest release **v1.1.0** or a newer develop build. Stock IW7 cannot load custom scripts.

## Planned installation

```text
copy  mods/infinite_expansion   →   <Infinite Warfare>/mods/infinite_expansion
in game: Mods menu → Infinite Expansion   (or launch with +set fs_game "mods/infinite_expansion")
```

Installing as a mod folder enables saving settings to disk. Loose installs into `iw7-mod/custom_scripts` also work, but settings then last only for the session.

## Documentation

| File | Contents |
|------|----------|
| `PROJECT_ANALYSIS.md` | Phase 0 forensics: BO3 reference (provisional), IW7 modding environment, feature compatibility matrix |
| `IW_API_NOTES.md` | Verified IW7 / iw7-mod scripting reference, with sources for every API |
| `KNOWN_LIMITATIONS.md` | Engine, client, compiler, and environment limits, with workarounds |
| `ARCHITECTURE.md` | Proposed module layout, init flow, and core interfaces |
| `FEATURE_STATUS.md` | Every planned feature and its status |
| `TESTING.md` | Verification levels, Phase 0 verification log, runtime test checklist |
| `CHANGELOG.md` | History |
| `tools/README.md` | Offline compiler toolchain (both iw7-mod compiler versions) |

## Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Project forensics | **Partial**: IW7 complete; BO3 files blocked |
| 1 | Foundation (entry scripts, bootstrap, compat, check tooling) | Next |
| 2 | Core systems (features, config, events, utilities) | Planned |
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
tools/setup_compilers.sh   # builds the gsc-tool versions embedded in iw7-mod v1.1.0 and develop
```

Every script must compile with **both** compilers and call the same natives under each; `IW_API_NOTES.md` §4 explains why.

## Acknowledgements

- [auroramod/iw7-mod](https://github.com/auroramod/iw7-mod): the client that makes IW7 modding possible.
- [xensik/gsc-tool](https://github.com/xensik/gsc-tool) and [auroramod/gsc-tool](https://github.com/auroramod/gsc-tool): the IW7 GSC compiler, used offline for verification and not redistributed here.
- [mjkzy/iw7-gsc-dump](https://github.com/mjkzy/iw7-gsc-dump): the stock script reference.
- The authors of *All-Around Enhancement* (BO3), whose design is the inspiration. No code or assets from it are used.

Not affiliated with Activision, Infinity Ward, or the authors of the projects above.
