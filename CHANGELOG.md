# CHANGELOG

All notable changes to this project. Format based on *Keep a Changelog*.

## [Unreleased]

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
