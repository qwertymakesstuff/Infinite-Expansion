# CHANGELOG

All notable changes to this project. Format based on *Keep a Changelog*.

## [Unreleased]

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
