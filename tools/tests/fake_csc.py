#!/usr/bin/env python3
"""A stand-in for the C# compiler of .NET Framework 4 (csc.exe), for
tools/tests/test_installer.py.

The tests copy it to <fake Windows folder>/Microsoft.NET/Framework64/v4.0.30319/
csc.exe, where installer/IXSetup.Core.ps1 looks for the compiler. It takes the
arguments New-IXLauncher passes:
    /nologo /noconfig /target:winexe /optimize+ /reference:System.dll
    /out:<exe> [/win32icon:<ico>] <source.cs>
checks that the source is the launcher, and writes <exe>: "MZ" and then JSON
describing its input, so a test can check what it was given.

fake_csc.json next to it sets what it does:
    fail     true: print a compiler error and exit 1, writing nothing
    no_icon  true: refuse /win32icon (exit 1), as an older compiler might
Each run is appended to fake_csc.log next to it, one JSON line.
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(sys.argv[0]).resolve().parent


def main(args):
    config_path = HERE / "fake_csc.json"
    config = json.loads(config_path.read_text()) if config_path.is_file() else {}
    options = {}
    sources = []
    for arg in args:
        # Only csc's own options: on Linux a source path starts with "/" too.
        option = re.match(r"/(nologo|noconfig|target|optimize[+-]?|reference|out|win32icon)(?::(.*))?$", arg)
        if option:
            options.setdefault(option.group(1), []).append(option.group(2) or "")
        else:
            sources.append(arg)
    with open(HERE / "fake_csc.log", "a") as log:
        log.write(json.dumps({"options": options, "sources": sources}) + "\n")

    if config.get("fail"):
        print(f"{sources[0]}(70,13): error CS1002: ; expected")
        return 1
    if config.get("no_icon") and "win32icon" in options:
        print("error CS7065: Error building Win32 resources -- The data is invalid.")
        return 1
    if len(sources) != 1 or "out" not in options:
        print("error CS2008: No source files specified")
        return 1
    source = Path(sources[0]).read_text()
    version = re.search(r'AssemblyVersion\("([^"]*)"\)', source)
    icon = options.get("win32icon", [None])[0]
    built = {
        "target": options.get("target", [None])[0],
        "optimize": "optimize+" in options,
        "references": options.get("reference", []),
        "noconfig": "noconfig" in options,
        "icon": icon,
        "icon_is_file": bool(icon) and Path(icon).is_file(),
        "version": version.group(1) if version else None,
        "launcher": "namespace InfiniteExpansion" in source and "static int Main(" in source,
    }
    Path(options["out"][0]).write_bytes(b"MZ" + json.dumps(built).encode())
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
