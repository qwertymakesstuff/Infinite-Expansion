#!/usr/bin/env python3
"""Static checks for the Infinite Expansion GSC sources.

The game cannot run here, so this verifies everything that can be checked
without it, using the compilers iw7-mod embeds (tools/setup_compilers.sh):

  compile  every script compiles with both iw7-mod compilers (v1.1.0 and develop),
           including iw7-mod's extension built-ins (tools/ixcc)
  parity   both compilers emit the same instructions and call the same natives
  natives  no calls to natives the game exe leaves unimplemented (stubs) and
           no unknown raw ids
  calls    every far call and far function reference names a defined function;
           a stock target must also be loaded on every zombies map, because a far
           call into a script the map did not load is a script link error that
           ends the match (stock scripts come from the decompiled dump)
  layout   script locations (the mod is zombies-only), init()/main() only in the
           entry script, every module reachable from it
  raw ids  _meth_XXXX / _func_XXX ids appear only in ix/core/compat.gsc and never
           in the range iw7-mod assigns to its extension built-ins
  source   no #include (modules call each other by explicit path), no /# #/ dev
           blocks (iw7-mod compiles those only with developer_script 1, so the
           checked code would differ from what runs), and no // comment ending in
           a backslash (both compilers then drop the next line without an error)
  lua      Lua UI scripts (ui_scripts/<Folder>/__init__.lua): luac5.1 syntax, and
           every Engine./LUI./MenuBuilder./... path, method and bare function call
           must appear in iw7-mod's own ui_scripts (pinned in setup_compilers.sh) or
           be defined in the file, so no UI API is invented; folder names must not
           clash with iw7-mod's (its loader would skip ours)
  budget   custom-script memory (bytecode + 1 per loaded script) against a
           512 KiB limit; iw7-mod has 1 MiB and running out is fatal

Usage:
  python3 tools/check.py [--toolchain DIR] [--mod DIR] [--stock DIR] [--iw7mod-ui DIR]
                         [--work DIR] [--budget BYTES]

Both compilers already reject a script function named after a built-in
("already defined as builtin"), and ixcc registers iw7-mod's extension names,
so that rule is covered by the compile check.

Exit status 0 when there are no errors (warnings are allowed), 1 otherwise,
2 when the toolchain is missing.
"""
import argparse
import concurrent.futures
import difflib
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_iw7_builtins import parse_table  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
VARIANTS = ("release", "develop")
VARIANT_LABELS = {"release": "iw7-mod v1.1.0", "develop": "iw7-mod develop"}

# iw7-mod's custom-script memory (gsc/script_loading.cpp): every loaded custom
# script takes bytecode length + 1 bytes; running out is a fatal error.
SCRIPT_MEMORY = 0x100000
DEFAULT_BUDGET = 512 * 1024

# Ids iw7-mod (and tools/ixcc) give to extension built-ins the table lacks.
FIRST_CUSTOM_FUNCTION = 807
FIRST_CUSTOM_METHOD = 0x8000 + 1484

# The mod is zombies-only: iw7-mod auto-loads custom_scripts/cp/ in zombies
# (CP) only. Modules live in custom_scripts/ix/<area>/ and load by reference.
ENTRY_DIR = "custom_scripts/cp"
# A zombies match loads the map's level script and the gametype script; the
# engine links every script they reference, transitively.
ZOMBIES_MAPS = ("cp_zmb", "cp_rave", "cp_disco", "cp_town", "cp_final")
ZOMBIES_ROOTS = ("scripts/cp/gametypes/zombie",)
RAW_ID_FILES = {"custom_scripts/ix/core/compat.gsc"}

RAW_ID = re.compile(r"\b_(meth|func)_([0-9A-Fa-f]+)\b")
PLACEHOLDER = re.compile(r"^_(func|meth)_([0-9A-Fa-f]+)$")
INCLUDE = re.compile(r"^\s*#include\b", re.MULTILINE)
DEV_BLOCK = re.compile(r"/#")
SUB = re.compile(r"^sub:(\S+)")
FAR_REF = re.compile(r"^\s*OP_(ScriptFar\w+|GetFarFunction)\s+(\S+)\s+(\S+)")
BUILTIN_REF = re.compile(
    r"^\s*OP_(CallBuiltin[0-5]?|CallBuiltinMethod[0-5]?|GetBuiltinFunction|GetBuiltinMethod)\s+(\S+)"
)
IXCC_RESULT = re.compile(r"bytecode=(\d+)")

# Lua UI scripts: names the mod may use must appear in iw7-mod's own ui_scripts.
LUA_API_ROOTS = ("Engine", "LUI", "MenuBuilder", "FONTS", "CoD", "ACTIONS", "OPTIONS", "DataSources",
                 "SWATCHES", "Lobby", "Rank", "Loot", "MPConfig", "utils", "io")
LUA_DOTTED = re.compile(r"(?<![.\w])(?:" + "|".join(LUA_API_ROOTS) + r")(?:\.[A-Za-z_]\w*)+")
LUA_METHOD = re.compile(r":([A-Za-z_]\w*)\s*\(")
LUA_CALL = re.compile(r"(?<![.:\w])([A-Za-z_]\w*)\s*\(")
LUA_DECLARED = re.compile(r"\bfunction\s+([A-Za-z_]\w*)|\blocal\s+function\s+([A-Za-z_]\w*)|\blocal\s+([A-Za-z_]\w*)")
LUA_KEYWORDS = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in",
                "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}
LUA_STANDARD = {"assert", "error", "getmetatable", "ipairs", "next", "pairs", "pcall", "print", "rawget",
                "rawset", "require", "select", "setmetatable", "tonumber", "tostring", "type", "unpack", "xpcall"}


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, check, where, message):
        self.errors.append(f"ERROR   [{check}] {where}: {message}")

    def warn(self, check, where, message):
        self.warnings.append(f"WARNING [{check}] {where}: {message}")


class Builtins:
    """The develop compiler's builtin tables plus iw7-mod's extension built-ins."""

    def __init__(self, toolchain, extensions_file):
        self.status = {}  # name -> status in the develop table (the disassembler's)
        engine = toolchain / "src" / "gsc-tool-develop" / "src" / "gsc" / "engine"
        develop = {
            "function": parse_table(engine / "iw7_func.cpp"),
            "method": parse_table(engine / "iw7_meth.cpp"),
        }
        for rows in develop.values():
            for _, name, status in rows:
                self.status.setdefault(name, status)

        # Reproduce the ids ixcc gives extension built-ins, so the develop
        # disassembler's placeholders (_func_0338) map back to their names.
        known = {kind: {name for _, name, _ in rows} for kind, rows in develop.items()}
        next_id = {"function": FIRST_CUSTOM_FUNCTION, "method": FIRST_CUSTOM_METHOD}
        prefix = {"function": "_func_", "method": "_meth_"}
        self.extensions = set()
        self.extension_ids = {}
        for kind, name in read_extensions(extensions_file):
            self.extensions.add(name)
            if name not in known[kind]:
                self.extension_ids[f"{prefix[kind]}{next_id[kind]:04X}"] = name
                next_id[kind] += 1


def read_extensions(path):
    entries = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        kind, name = line.split()
        entries.append((kind, name))
    return entries


def strip_code(text):
    """Blank out comments and string contents, keeping line structure."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            end = text.find("\n", i)
            end = n if end == -1 else end
            out.append(" " * (end - i))
            i = end
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            end = n if end == -1 else end + 2
            out.append("".join(ch if ch == "\n" else " " for ch in text[i:end]))
            i = end
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            out.append('"' + " " * (min(j, n) - i - 1) + '"')
            i = j + 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def comment_continuations(text):
    """Line numbers of // comments that end in a backslash."""
    lines = []
    for number, line in enumerate(text.splitlines(), start=1):
        in_string = False
        i = 0
        while i < len(line):
            if line[i] == '"':
                in_string = not in_string
            elif line[i] == "\\" and in_string:
                i += 1
            elif line.startswith("//", i) and not in_string:
                if line.rstrip().endswith("\\"):
                    lines.append(number)
                break
            i += 1
    return lines


def strip_lua(text):
    """Blank out Lua comments and string contents, keeping line structure."""
    out = []
    i, n = 0, len(text)
    long_bracket = re.compile(r"\[(=*)\[")

    def blank(chunk):
        return "".join(ch if ch == "\n" else " " for ch in chunk)

    while i < n:
        if text.startswith("--", i):
            opener = long_bracket.match(text, i + 2)
            if opener:
                close = text.find("]" + opener.group(1) + "]", opener.end())
                end = n if close == -1 else close + len(opener.group(1)) + 2
            else:
                end = text.find("\n", i)
                end = n if end == -1 else end
            out.append(blank(text[i:end]))
            i = end
        elif text[i] in "\"'":
            quote = text[i]
            j = i + 1
            while j < n and text[j] != quote and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            out.append(quote + blank(text[i + 1:min(j, n)]) + quote)
            i = j + 1
        elif long_bracket.match(text, i):
            opener = long_bracket.match(text, i)
            close = text.find("]" + opener.group(1) + "]", opener.end())
            end = n if close == -1 else close + len(opener.group(1)) + 2
            out.append('""' + blank(text[i + 2:end]))
            i = end
        else:
            out.append(text[i])
            i += 1
    return "".join(out)


def lua_vocabulary(root):
    """Dotted API paths, method names and bare calls used by the Lua files under root."""
    dotted, methods, calls = set(), set(), set()
    for path in sorted(root.rglob("*.lua")):
        code = strip_lua(path.read_text(encoding="utf-8", errors="replace"))
        dotted.update(LUA_DOTTED.findall(code))
        methods.update(LUA_METHOD.findall(code))
        calls.update(LUA_CALL.findall(code))
    return dotted, methods, calls


def location(rel):
    """'entry', 'module', or None for a location the mod does not use."""
    parts = rel.split("/")
    if "/".join(parts[:-1]) == ENTRY_DIR:
        return "entry"
    if len(parts) >= 4 and parts[:2] == ["custom_scripts", "ix"]:
        return "module"
    return None


def parse_asm(path):
    subs, far_refs, builtin_refs = [], [], []
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        match = SUB.match(line)
        if match:
            current = match.group(1)
            subs.append(current)
            continue
        match = FAR_REF.match(line)
        if match:
            far_refs.append((current, match.group(1), match.group(2), match.group(3)))
            continue
        match = BUILTIN_REF.match(line)
        if match:
            builtin_refs.append((current, match.group(1), match.group(2)))
    return subs, far_refs, builtin_refs


def compile_all(tools, extensions_file, mod_root, scripts, work):
    """Compile every script with both ixcc variants. Returns {(variant, rel): (ok, detail)}."""
    jobs = []
    for variant in VARIANTS:
        for rel in scripts:
            out = work / variant / "bin" / (rel[: -len(".gsc")] + ".gscbin")
            jobs.append((variant, rel, [str(tools[f"ixcc-{variant}"]), str(extensions_file), str(mod_root), rel, str(out)]))

    def run(job):
        variant, rel, command = job
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode != 0:
            message = (result.stderr or result.stdout).strip()
            message = message.removeprefix(f"[ERROR] {rel}: ").removeprefix("[ERROR]:compiler:")
            return variant, rel, False, message
        match = IXCC_RESULT.search(result.stdout)
        return variant, rel, True, int(match.group(1)) if match else 0

    results = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
        for variant, rel, ok, detail in pool.map(run, jobs):
            results[(variant, rel)] = (ok, detail)
    return results


def disassemble(tools, work, variant):
    out_dir = work / variant
    bin_dir = out_dir / "bin"
    if not bin_dir.is_dir():
        return None
    result = subprocess.run(
        [str(tools["gsc-tool-iw7-develop"]), "-m", "disasm", "-g", "iw7", "-s", "pc", str(bin_dir)],
        cwd=out_dir,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"disassembler failed for {variant}: {result.stdout}{result.stderr}")
    return out_dir / "disassembled" / "iw7"


class StockScripts:
    """The decompiled stock scripts: what each defines and references, and
    which of them a zombies match loads."""

    NAMED_REF = re.compile(r"\b(scripts(?:\\[a-z0-9_]+)+)::", re.IGNORECASE)
    HASHED_REF = re.compile(r"\b_id_([0-9a-f]+)::", re.IGNORECASE)  # _id_0D60:: is 3424.gsc
    DEFINITION = re.compile(r"^([A-Za-z_][A-Za-z_0-9]*)\s*\(", re.MULTILINE)

    def __init__(self, root):
        self.root = root
        self.parsed = {}

    def parse(self, path):
        """(defined function names, referenced script paths), or None if there is no such script."""
        if path not in self.parsed:
            source = self.root / (path + ".gsc")
            if not source.is_file():
                self.parsed[path] = None
            else:
                text = source.read_text(encoding="utf-8", errors="replace")
                defined = {name.lower() for name in self.DEFINITION.findall(text)}
                referenced = {ref.replace("\\", "/").lower() for ref in self.NAMED_REF.findall(text)}
                referenced |= {str(int(ident, 16)) for ident in self.HASHED_REF.findall(text)}
                self.parsed[path] = (defined, referenced)
        return self.parsed[path]

    def linked(self, roots):
        seen, pending = set(), list(roots)
        while pending:
            path = pending.pop()
            if path in seen:
                continue
            seen.add(path)
            parsed = self.parse(path)
            if parsed:
                pending.extend(parsed[1] - seen)
        return seen

    def linked_per_map(self):
        return {name: self.linked([f"scripts/cp/maps/{name}/{name}", *ZOMBIES_ROOTS]) for name in ZOMBIES_MAPS}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--toolchain", type=Path, default=REPO / ".toolchain")
    parser.add_argument("--mod", type=Path, default=REPO / "mods" / "infinite_expansion")
    parser.add_argument("--stock", type=Path, help="decompiled stock scripts (default: <toolchain>/src/iw7-gsc-dump/decompiled)")
    parser.add_argument("--iw7mod-ui", type=Path, help="iw7-mod's ui_scripts (default: <toolchain>/src/iw7-mod-ui/data/cdata/ui_scripts)")
    parser.add_argument("--work", type=Path, help="keep compiled and disassembled output here (default: temporary)")
    parser.add_argument("--budget", type=int, default=DEFAULT_BUDGET, help=f"bytecode limit per mode (default {DEFAULT_BUDGET})")
    args = parser.parse_args()

    toolchain = args.toolchain.resolve()
    mod_root = args.mod.resolve()
    stock_root = (args.stock or toolchain / "src" / "iw7-gsc-dump" / "decompiled").resolve()
    ui_root = (args.iw7mod_ui or toolchain / "src" / "iw7-mod-ui" / "data" / "cdata" / "ui_scripts").resolve()
    extensions_file = REPO / "tools" / "ixcc" / "iw7mod_extensions.txt"

    tools = {name: toolchain / "bin" / name for name in ("ixcc-release", "ixcc-develop", "gsc-tool-iw7-develop")}
    tables = [toolchain / "src" / "gsc-tool-develop" / "src" / "gsc" / "engine" / name for name in ("iw7_func.cpp", "iw7_meth.cpp")]
    missing = [str(path) for path in [*tools.values(), *tables] if not path.is_file()]
    if missing:
        print("missing toolchain files (run tools/setup_compilers.sh):\n  " + "\n  ".join(missing))
        return 2

    builtins = Builtins(toolchain, extensions_file)
    report = Report()
    scripts_root = mod_root / "custom_scripts"
    scripts = sorted(path.relative_to(mod_root).as_posix() for path in scripts_root.rglob("*.gsc"))
    stock = StockScripts(stock_root) if stock_root.is_dir() else None
    per_map = stock.linked_per_map() if stock else {}
    everywhere = set.intersection(*per_map.values()) if per_map else set()

    print("Infinite Expansion static check")
    print(f"  mod:        {display(mod_root)} ({len(scripts)} scripts)")
    print("  compilers:  " + ", ".join(f"ixcc-{v} ({VARIANT_LABELS[v]})" for v in VARIANTS))
    print(f"  stock dump: {display(stock_root) if stock else 'not found; stock far calls are not verified'}")
    print()

    # Mod folder: fs_game must start with "mods/" and contain no "." (iw7-mod party.cpp).
    if "." in mod_root.name:
        report.error("layout", display(mod_root), "mod folder name must not contain '.' (fs_game rule)")
    if not (mod_root / "desc.txt").is_file():
        report.warn("layout", display(mod_root), "no desc.txt; the Mods menu shows a default description")

    with tempfile.TemporaryDirectory(prefix="ix_check_") as temp:
        work = (args.work or Path(temp)).resolve()
        work.mkdir(parents=True, exist_ok=True)

        # compile
        results = compile_all(tools, extensions_file, mod_root, scripts, work)
        compiled = 0
        for (variant, rel), (ok, detail) in sorted(results.items()):
            if ok:
                compiled += 1
            else:
                report.error("compile", rel, f"{VARIANT_LABELS[variant]} compiler: {detail}")
        print(f"[compile]  {compiled}/{len(results)} compiled")

        asm_dirs = {variant: disassemble(tools, work, variant) for variant in VARIANTS}
        asm = {}
        for variant in VARIANTS:
            for rel in scripts:
                if results[(variant, rel)][0]:
                    asm[(variant, rel)] = asm_dirs[variant] / (rel[: -len(".gsc")] + ".gscasm")

        # parity
        identical = 0
        both = [rel for rel in scripts if all((variant, rel) in asm for variant in VARIANTS)]
        for rel in both:
            release_text = asm[("release", rel)].read_text(encoding="utf-8").splitlines()
            develop_text = asm[("develop", rel)].read_text(encoding="utf-8").splitlines()
            if release_text == develop_text:
                identical += 1
                continue
            diff = [
                f"{line[0]} {line[1:].strip()}"
                for line in difflib.unified_diff(release_text, develop_text, n=0, lineterm="")
                if line[:1] in "+-" and line[:3] not in ("+++", "---")
            ]
            report.error("parity", rel, "v1.1.0 (-) and develop (+) compile it differently:\n          " + "\n          ".join(diff[:12]))
        print(f"[parity]   {identical}/{len(both)} identical")

        # parse the develop disassembly for the remaining checks
        parsed = {rel: parse_asm(asm[("develop", rel)]) for rel in scripts if ("develop", rel) in asm}
        defined = {rel: {name.lower() for name in subs} for rel, (subs, _, _) in parsed.items()}

        # natives
        native_calls = 0
        for rel, (_, _, builtin_refs) in parsed.items():
            for func, op, name in builtin_refs:
                native_calls += 1
                where = f"{rel} ({func})"
                if PLACEHOLDER.match(name):
                    if name in builtins.extension_ids:
                        continue
                    if builtins.status.get(name) == "unnamed":
                        continue
                    report.error("natives", where, f"{op} {name}: id is not in the IW7 table or iw7-mod's extensions")
                elif builtins.status.get(name) == "stub" and name not in builtins.extensions:
                    report.error("natives", where, f"{name} has no implementation in the game exe (stub)")
        print(f"[natives]  {native_calls} built-in calls checked")

        # calls
        far_count = stock_count = 0
        unverified_stock = set()
        for rel, (_, far_refs, _) in parsed.items():
            for func, op, path, target in far_refs:
                far_count += 1
                where = f"{rel} ({func})"
                if path.startswith("custom_scripts/"):
                    target_rel = path + ".gsc"
                    if target_rel not in scripts:
                        report.error("calls", where, f"{path}::{target}: no such script in the mod")
                    elif target_rel in defined and target.lower() not in defined[target_rel]:
                        report.error("calls", where, f"{path}::{target}: function not defined there")
                elif path.startswith("scripts/"):
                    stock_count += 1
                    if stock is None:
                        unverified_stock.add(f"{path}::{target}")
                        continue
                    parsed_stock = stock.parse(path)
                    if parsed_stock is None:
                        report.error("calls", where, f"{path}::{target}: no such stock script in the dump")
                    elif target.lower() not in parsed_stock[0]:
                        report.error("calls", where, f"{path}::{target}: function not defined in the stock script")
                    elif path not in everywhere:
                        maps = [name for name in ZOMBIES_MAPS if path in per_map[name]]
                        loaded = "only on " + ", ".join(maps) if maps else "on no zombies map"
                        report.error("calls", where, f"{path}::{target}: that script is loaded {loaded}; where it is missing, this far call is a script link error that ends the match")
                else:
                    report.error("calls", where, f"{op} {path}::{target}: unexpected script path")
        for name in sorted(unverified_stock):
            report.warn("calls", name, "stock target not verified (no stock dump)")
        stock_note = f"; {len(everywhere)} stock scripts load on every zombies map" if stock else ""
        print(f"[calls]    {far_count} far references checked ({stock_count} into stock scripts{stock_note})")

        # layout
        locations = {rel: location(rel) for rel in scripts}
        for rel, kind in locations.items():
            if kind is None:
                report.error("layout", rel, f"unsupported location: the entry script goes in {ENTRY_DIR}/ (iw7-mod loads it in zombies only), modules in custom_scripts/ix/<area>/")
        entries = [rel for rel, kind in locations.items() if kind == "entry"]
        if not entries:
            report.error("layout", ENTRY_DIR, "no entry script; iw7-mod would load nothing")
        for rel in entries:
            if rel in defined and not defined[rel] & {"init", "main"}:
                report.error("layout", rel, "entry script defines neither init() nor main(); iw7-mod would run nothing")
        for rel, names in defined.items():
            if locations[rel] == "module" and names & {"init", "main"}:
                report.error("layout", rel, "only the entry script defines init() or main() (iw7-mod runs them in every file it auto-loads); use register() or setup()")
        loaded, pending = set(), list(entries)
        while pending:
            rel = pending.pop()
            if rel in loaded:
                continue
            loaded.add(rel)
            for _, _, path, _ in parsed.get(rel, ([], [], []))[1]:
                if path.startswith("custom_scripts/") and path + ".gsc" in scripts:
                    pending.append(path + ".gsc")
        for rel in scripts:
            if locations[rel] == "module" and rel not in loaded:
                report.warn("layout", rel, "not reachable from the entry script; it never loads")
        print(f"[layout]   {plural(len(entries), 'entry script')}; {plural(len(loaded), 'script')} load in a zombies match")

        # raw ids, include
        raw_total = 0
        for rel in scripts:
            code = strip_code((mod_root / rel).read_text(encoding="utf-8"))
            for match in RAW_ID.finditer(code):
                line = code.count("\n", 0, match.start()) + 1
                ident = int(match.group(2), 16)
                first_custom = FIRST_CUSTOM_METHOD if match.group(1) == "meth" else FIRST_CUSTOM_FUNCTION
                if ident >= first_custom:
                    report.error("raw ids", f"{rel}:{line}", f"{match.group(0)} is in the range iw7-mod gives its extension built-ins, which depends on registration order; call it by name")
                elif rel in RAW_ID_FILES:
                    raw_total += 1
                else:
                    report.error("raw ids", f"{rel}:{line}", f"{match.group(0)} outside ix/core/compat.gsc; add a named wrapper there")
        print(f"[raw ids]  {raw_total} in " + ", ".join(sorted(RAW_ID_FILES)))
        source_issues = 0
        for rel in scripts:
            text = (mod_root / rel).read_text(encoding="utf-8")
            for line in comment_continuations(text):
                source_issues += 1
                report.error("source", f"{rel}:{line}", "// comment ends in a backslash; the compilers silently drop the next line")
            code = strip_code(text)
            for pattern, message in (
                (INCLUDE, "#include is not used in this mod; call other files by explicit path"),
                (DEV_BLOCK, "/# #/ dev blocks compile only with developer_script 1; gate debug code with a dvar instead"),
            ):
                for match in pattern.finditer(code):
                    source_issues += 1
                    line = code.count("\n", 0, match.start()) + 1
                    report.error("source", f"{rel}:{line}", message)
        print(f"[source]   {source_issues} #include / dev-block / comment issues")

        # lua
        check_lua(mod_root, ui_root, report)

        # budget
        sizes = {}
        for rel in scripts:
            values = [results[(variant, rel)][1] for variant in VARIANTS if results[(variant, rel)][0]]
            if values:
                sizes[rel] = max(values) + 1
        total = sum(sizes.get(rel, 0) for rel in loaded)
        print(f"[budget]   {total:,} bytes of custom-script memory ({100 * total / SCRIPT_MEMORY:.2f}% of 1 MiB; limit {args.budget:,})")
        if total > args.budget:
            report.error("budget", "zombies", f"{total:,} bytes exceeds the limit of {args.budget:,}")

    print()
    for line in report.errors + report.warnings:
        print(line)
    if report.errors or report.warnings:
        print()
    verdict = "FAIL" if report.errors else "PASS"
    print(f"RESULT: {verdict} ({plural(len(report.errors), 'error')}, {plural(len(report.warnings), 'warning')})")
    return 1 if report.errors else 0


def check_lua(mod_root, ui_root, report):
    ui_dir = mod_root / "ui_scripts"
    files = sorted(ui_dir.rglob("*.lua")) if ui_dir.is_dir() else []
    if not files:
        print("[lua]      no ui_scripts")
        return

    luac = shutil.which("luac5.1")
    have_reference = ui_root.is_dir()
    reference = lua_vocabulary(ui_root) if have_reference else (set(), set(), set())
    reference_folders = {path.name.lower() for path in ui_root.iterdir() if path.is_dir()} if have_reference else set()
    if not luac:
        report.warn("lua", display(ui_dir), "luac5.1 not found (package lua5.1); Lua syntax not checked")
    if not have_reference:
        report.warn("lua", display(ui_dir), "iw7-mod ui_scripts not found (run tools/setup_compilers.sh); Lua API names not checked")

    for folder in sorted(path for path in ui_dir.iterdir() if path.is_dir()):
        where = folder.relative_to(mod_root).as_posix()
        if not (folder / "__init__.lua").is_file():
            report.error("lua", where, "no __init__.lua; iw7-mod loads only ui_scripts/<Folder>/__init__.lua")
        if folder.name.lower() in reference_folders:
            report.error("lua", where, "iw7-mod has a ui_scripts folder with this name and its copy wins; rename the folder")

    names_checked = 0
    for path in files:
        rel = path.relative_to(mod_root).as_posix()
        if path.parent.parent != ui_dir:
            report.error("lua", rel, "Lua files belong in ui_scripts/<Folder>/")
        if luac:
            result = subprocess.run([luac, "-p", str(path)], capture_output=True, text=True)
            if result.returncode != 0:
                message = (result.stderr or result.stdout).strip()
                located = re.search(r":(\d+): (.*)$", message)
                if located:
                    report.error("lua", f"{rel}:{located.group(1)}", "syntax: " + located.group(2))
                else:
                    report.error("lua", rel, "syntax: " + message)
                continue
        if not have_reference:
            continue

        code = strip_lua(path.read_text(encoding="utf-8"))
        declared = {name for match in LUA_DECLARED.findall(code) for name in match if name}
        ref_dotted, ref_methods, ref_calls = reference

        def line_of(match):
            return code.count("\n", 0, match.start()) + 1

        for match in LUA_DOTTED.finditer(code):
            names_checked += 1
            if match.group(0) not in ref_dotted:
                report.error("lua", f"{rel}:{line_of(match)}", f"{match.group(0)} is not used by any iw7-mod ui_script; unverified API")
        for match in LUA_METHOD.finditer(code):
            names_checked += 1
            if match.group(1) not in ref_methods:
                report.error("lua", f"{rel}:{line_of(match)}", f":{match.group(1)}() is not used by any iw7-mod ui_script; unverified API")
        for match in LUA_CALL.finditer(code):
            name = match.group(1)
            if name in LUA_KEYWORDS or name in LUA_STANDARD or name in declared:
                continue
            names_checked += 1
            if name not in ref_calls:
                report.error("lua", f"{rel}:{line_of(match)}", f"{name}() is not used by any iw7-mod ui_script; unverified API")

    syntax_note = "syntax checked" if luac else "syntax not checked"
    print(f"[lua]      {plural(len(files), 'script')}: {syntax_note}, {names_checked} API names checked against iw7-mod's ui_scripts")


def plural(count, noun):
    return f"{count} {noun}" + ("" if count == 1 else "s")


def display(path):
    try:
        return path.relative_to(REPO).as_posix()
    except ValueError:
        return str(path)


if __name__ == "__main__":
    sys.exit(main())
