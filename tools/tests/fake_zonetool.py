#!/usr/bin/env python3
"""A stand-in for x64-zt's zonetool.exe, for tools/tests/test_installer.py.

It behaves the way installer/IXPictures.Core.ps1 relies on x64-zt behaving
(IW_API_NOTES.md section 18): it runs in the game folder, prints its ready line,
then reads console commands from standard input until "quit"; with -buildzone it
builds from zone_source/ and zonetool/ and exits. The "fastfile" it writes is
JSON describing what it was given, so the tests can check the build input.

Like the real one on a real install:
  - a zone's images are the character cards the game's asset listing puts there
    (ZONE_IMAGES), plus a few others; "dumpzone iw7 <zone> image" writes them to
    dump/<zone>/images/<name>.iw7Image;
  - the menu material is only found once techsets_ui_boot is loaded (IW7 keeps
    materials in techsets_<zone>, and x64-zt's loadzone does not load it);
  - "dumpasset image" crashes, as it did on every map on a player's PC: an
    image's pixels are freed once its zone has loaded.

fake_zonetool.json in the game folder sets what it does:
    missing        images the "game" does not have
    missing_zones  zones that are not installed ("could not be found")
    crash_on       zones whose dumpzone makes it exit with code 3
    hang           true: print the ready line, then never answer again
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


def cards(main, team, main_slots, team_slots):
    return [main.format(n) for n in main_slots] + [team.format(n) for n in team_slots]


# Where the game's asset listing (aurora's iw7_asset_listing) puts each card.
ZONE_IMAGES = {
    "cp_zmb": cards("zm_pc_score_main_plyr_{0}", "zm_pc_score_team_plyr_{0}", range(1, 6), range(1, 6)),
    "patch_cp_zmb": ["zm_main_plyr_6_dlc4", "zm_team_plyr_6_dlc4"],
    "cp_rave": cards("zm_main_plyr_{0}_dlc1", "zm_team_plyr_{0}_dlc1", range(1, 6), range(1, 6)),
    "cp_disco": cards("zm_main_plyr_{0}_dlc2", "zm_team_plyr_{0}_dlc2", range(1, 6), range(1, 6)),
    "cp_town": cards("zm_main_plyr_{0}_dlc3", "zm_team_plyr_{0}_dlc3", range(1, 5), range(1, 6)),
    "eng_cp_town": ["zm_main_plyr_5_dlc3"],
    "eng_patch_cp_town": ["zm_main_plyr_5_dlc3"],
    "cp_final": cards("zm_main_plyr_{0}_dlc4", "zm_team_plyr_{0}_dlc4", range(1, 5), range(1, 5)),
    "ui_boot": ["zm_character_select_hoff"],
    "techsets_ui_boot": [],
}


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


def zone_exists(zone, config):
    return zone in ZONE_IMAGES and zone not in config.get("missing_zones", [])


def dump_material(name):
    material = {
        "name": name,
        "techniqueSet->name": "2d",
        "gameFlags": 0,
        "sortKey": 41,
        "textureTable": [{"image": name, "semantic": 2}],
        "constantTable": [],
    }
    write(f"dump/assets/materials/{name}.json", json.dumps(material, indent=4).encode())
    for kind, ext in STATE_KINDS:
        write(f"dump/assets/techsets/{kind}/2d/{name}{ext}", name.encode())


def dump_zone(zone, config):
    say(f'Dumping zone "{zone}"...')
    images = ZONE_IMAGES[zone] + [f"{zone}_world_{n}" for n in range(3)]
    for name in images:
        if name not in config.get("missing", []):
            write(f"dump/{zone}/images/{name}.iw7Image", f"IW7IMAGE {zone} {name}".encode())
    write(f"dump/{zone}/{zone}.csv", "".join(f"image,{name}\n" for name in images).encode())
    say(f'Zone "{zone}" dumped.')


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
            if not zone_exists(zone, config):
                say(f'Zone "{zone}" could not be found!')
            elif zone in loaded:
                say(f'zone "{zone}" is already loaded...')
            else:
                say(f'Loading zone "{zone}"...')
                loaded.add(zone)
        elif words[:2] == ["dumpasset", "material"]:
            if "techsets_ui_boot" in loaded:
                dump_material(words[2])
                say("Dumped to dump/assets")
            else:
                say("Asset not found")
        elif words[:2] == ["dumpasset", "image"]:
            log("dumpasset image: crash")
            return 5
        elif words[0] == "dumpzone" and words[1:2] == ["iw7"] and words[3:] == ["image"]:
            zone = words[2]
            if zone in config.get("crash_on", []):
                return 3
            if not zone_exists(zone, config):
                say(f'Zone "{zone}" could not be found!')
            elif zone in loaded:
                say(f'zone "{zone}" is already loaded...')
            else:
                dump_zone(zone, config)
                loaded.add(zone)


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
        for path in [f"{source}/images/{name}.iw7Image"] + [f"{source}/techsets/{k}/2d/{name}{e}" for k, e in STATE_KINDS]:
            if not os.path.isfile(path):
                say(f"missing {path}")
                return 2
        materials.append({"name": name, "image": open(f"{source}/images/{name}.iw7Image", "rb").read().decode()})
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
