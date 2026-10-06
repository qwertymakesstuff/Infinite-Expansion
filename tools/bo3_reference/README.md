# tools/bo3_reference: rebuild the BO3 reference workspace

These tools regenerate the material behind `PROJECT_ANALYSIS.md` §1 from the user-supplied *All-Around Enhancement* package (AAE v3.9.5). No AAE content is stored in this repository; run the pipeline locally whenever later phases need to consult the BO3 reference.

```bash
tools/setup_compilers.sh                                   # once: builds gsc-tool (includes the T7 decompiler)
tools/bo3_reference/extract_aae.sh AllAroundEnhancement.7z /path/to/aae_ref
```

The pipeline takes about 30 s. Every run so far has produced the same results: 216 compiled objects carved, 211 decompiled, 1,678 English strings, and 501 LUI chunks.

## Steps

| Step | Script | Notes |
|------|--------|-------|
| Verify the download | `dropbox_content_hash.py` | Prints the Dropbox `content_hash` (SHA-256 over per-4 MiB SHA-256s) to compare with the API value |
| Extract | `7z x` | The archive uses BCJ2, so a real 7-Zip is required (py7zr cannot decode it) |
| Decompress fastfiles | `t7ff_decompress.py` | BO3 PC `TAff0000` v0x251. A 0x248-byte header is followed by zlib blocks with 16-byte self-locating headers; stored blocks are copied through, and unframed regions are passed through and reported |
| Carve scripts | `t7_carve_gsc.py` | Finds `\x80GSC\r\n\0`, reads the 72-byte T7 header, and names each object from its embedded name. Output paths are sanitised |
| Decompile | `gsc-tool -m decomp -g t7 -s pc64` | Function names are hashes (`_id_XXXXXXXX`) because BO3 stores them hashed |
| LUI inventory | `t7_lua_strings.py` | Havok Lua bytecode is **not** decompiled; only the source path and string constants are recorded |
| Localized strings | `t7_localize.py` | Heuristic: each entry's text sits right before its KEY |

Treat the package as untrusted input. The pipeline only reads and decompresses it; it never executes anything from it. `T7Overcharged.ff` is a Windows PE binary and is left untouched.
