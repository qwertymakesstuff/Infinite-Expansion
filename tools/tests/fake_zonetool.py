#!/usr/bin/env python3
"""A stand-in for x64-zt's zonetool.exe, for tools/tests/test_installer.py.

It behaves the way installer/IXPictures.Core.ps1 relies on x64-zt behaving
(IW_API_NOTES.md section 18): it runs in the game folder, prints its ready line,
then reads console commands from standard input until "quit"; with -buildzone it
builds from zone_source/ and zonetool/ and exits. The "fastfile" it writes is
JSON describing what it was given, so the tests can check the build input.

fake_zonetool.json in the game folder sets what it does:
    missing   images the "game" does not have ("Asset not found")
    streamed  images dumped the streamed way (streamed_images/<name>_stream<n>.dds)
    crash_on  zones whose loadzone makes it exit with code 3
    hang      true: print the ready line, then never answer again
Every command it receives is appended to fake_zonetool.log, as Python repr,
after a "pid <n>" line, so a test can tell whether it was ended.
"""
import json
import os
import select
import sys
import time

CONFIG = "fake_zonetool.json"
LOG = "fake_zonetool.log"
STATE_KINDS = (("state", ".statebits"), ("state", ".statebitsmap"))


def say(text):
    sys.stdout.write(text + "\n")
    sys.stdout.flush()


def log(text):
    with open(LOG, "a", encoding="utf-8") as handle:
        handle.write(text + "\n")


def write(path, data):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(data)


def dump_material(name):
    material = {
        "name": name,
        "techniqueSet->name": "2d",
        "gameFlags": 0,
        "sortKey": 41,
        "textureTable": [{"image": name + "_img", "semantic": 2}],
        "constantTable": [],
    }
    write(f"dump/assets/materials/{name}.json", json.dumps(material, indent=4).encode())
    for kind, ext in STATE_KINDS:
        write(f"dump/assets/techsets/{kind}/2d/{name}{ext}", name.encode())


def dump_image(name, config):
    if name in config.get("missing", []):
        say("Asset not found")
        return
    if name in config.get("streamed", []):
        write(f"dump/assets/streamed_images/{name}_stream0.dds", b"small")
        write(f"dump/assets/streamed_images/{name}_stream1.dds", b"the largest stream " + name.encode())
        return
    write(f"dump/assets/images/{name}.dds", b"DDS " + name.encode())


def stdin_closed():
    """True if standard input has already reached its end (it should stay open)."""
    readable, _, _ = select.select([sys.stdin], [], [], 0.3)
    return bool(readable) and os.read(sys.stdin.fileno(), 1) == b""


def console(config):
    say("ZoneTool is initializing...")
    say("ZoneTool initialization complete!")
    if config.get("hang"):
        time.sleep(600)
        return 0
    loaded = set()
    while True:
        line = sys.stdin.readline()
        if line == "":
            log("EOF before quit")
            return 4
        log(repr(line))
        words = line.split()
        if not words:
            continue
        if words[0] == "quit":
            if stdin_closed():
                log("stdin closed before quit")
            return 0
        if words[0] == "loadzone":
            zone = words[1]
            if zone in config.get("crash_on", []):
                say(f'Loading zone "{zone}"...')
                return 3
            say(f'zone "{zone}" is already loaded...' if zone in loaded else f'Loading zone "{zone}"...')
            loaded.add(zone)
        elif words[0] == "dumpasset" and words[1] == "material":
            dump_material(words[2])
            say("Dumped to dump/assets")
        elif words[0] == "dumpasset" and words[1] == "image":
            dump_image(words[2], config)


def build(zone):
    rows = [line for line in open(f"zone_source/{zone}.csv", encoding="utf-8").read().splitlines() if line]
    source = f"zonetool/{zone}"
    materials = []
    for row in rows:
        if not row.startswith("material,"):
            continue
        name = row.split(",", 1)[1]
        material = json.load(open(f"{source}/materials/{name}.json", encoding="utf-8"))
        if [t["image"] for t in material["textureTable"]] != [name]:
            say(f"material {name} does not use the image {name}")
            return 2
        for path in [f"{source}/images/{name}.dds"] + [f"{source}/techsets/{k}/2d/{name}{e}" for k, e in STATE_KINDS]:
            if not os.path.isfile(path):
                say(f"missing {path}")
                return 2
        materials.append({"name": name, "image": open(f"{source}/images/{name}.dds", "rb").read().decode()})
    target = f"zone/{zone}.ff" if os.path.isdir("zone") else f"{zone}.ff"
    write(target, json.dumps({"rows": rows, "materials": materials}).encode())
    say(f'Building fastfile "{zone}"')
    return 0


def main():
    config = json.load(open(CONFIG, encoding="utf-8")) if os.path.isfile(CONFIG) else {}
    args = sys.argv[1:]
    log(f"pid {os.getpid()}")
    log("args " + " ".join(args))
    if "-buildzone" in args:
        return build(args[args.index("-buildzone") + 1])
    return console(config)


if __name__ == "__main__":
    sys.exit(main())
