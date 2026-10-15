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

For the custom emotes (installer/IXEmotes.Core.ps1), as x64-zt's source has it
(IW_API_NOTES.md section 24):
  - "dumpcsv <zone>" loads the zone and lists its assets, "<type>,<name>", in
    dump/<zone>/<zone>.csv, with the game's own type names; a zone's
    animations are ZONE_XANIMS;
  - "dumpasset <type> <name>" of a loaded animation writes
    dump/assets/xanim/<name>.xab in x64-zt's format (make_xab: made-up
    numbers, no game data); an unknown type name crashes it (type_to_int
    gives -1);
  - a build row "<type>,<name>" of that type reads zonetool/<zone>/xanim/<name>.xab;
    the zone it builds can be listed with dumpcsv again.

fake_zonetool.json in the game folder sets what it does:
    missing        images the "game" does not have
    missing_zones  zones that are not installed ("could not be found")
    crash_on       zones whose dumpzone makes it exit with code 3
    xanim_type     the game's name for animations (default "xanim")
    xanim_zones    {zone: [animation, ...]} in place of ZONE_XANIMS
    xanim_frames   [frames, framerate, flags] of every dumped animation
    fixtures       the folder of emote_fixtures.py: dumped animations are then
                   laid out with real data streams (emote_fixtures
                   sample_animation: the zone's first animation "short", the
                   others with 16-bit frame indices), and "dumpasset xmodel"
                   of a listed body model writes dump/assets/xmodel/<name>.xmb
                   (emote_fixtures.make_rig); numbers made up, no game data
    xmodel_zones   {zone: [model, ...]} in place of ZONE_XMODELS
    corrupt_xanims animations dumped with one bone too many in their counts,
                   so they do not read back
    crash_on_csv   zones whose dumpcsv makes it exit with code 7
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


# Where the custom emotes' proof looks for its animation; made up for the test.
ZONE_XANIMS = {"cp_zmb": ["IW7_cp_zom_hoff_dj_desk_01", "iw7_cp_zom_hoff_dj_idle_01"], "patch_cp_zmb": []}
# A zone's body models (listed as "xmodel,<name>"; only with "fixtures").
ZONE_XMODELS = {"cp_zmb": ["body_zmb_hero_jock"], "patch_cp_zmb": []}


# Made-up bone names for the stand-in's animations (not read from any game file).
FAKE_BONES = ["bone_a", "bone_b", "bone_c"]


def make_xab(name, frames=151, framerate=30.0, flags=0, bones=None):
    """An animation file laid out as x64-zt's xanim_parts::dump writes one:
    XAnimParts (0x88 bytes) as an array of one, the name as a string, the bone
    names as strings (a repeated one as a reference back, DUMP_TYPE_OFFSET),
    then the rest (here a made-up raw block). The numbers are not a real
    animation."""
    import struct
    bones = FAKE_BONES if bones is None else bones
    parts = bytearray(0x88)
    if bones:
        struct.pack_into("<Q", parts, 8, 0x1234)
    struct.pack_into("<f", parts, 100, framerate)
    struct.pack_into("<H", parts, 116, frames)
    parts[118] = flags
    parts[128] = len(bones)
    data = bytes([8, 1]) + struct.pack("<I", 1) + bytes(parts)
    data += bytes([6, 1]) + name.encode() + b"\0"
    entries = [None, name]
    for bone in bones:
        if bone in entries:
            data += bytes([9]) + struct.pack("<II", entries.index(bone), 0)
        else:
            entries.append(bone)
            data += bytes([6, 1]) + bone.encode() + b"\0"
    rest = b"made-up animation data"
    return data + bytes([10, 1]) + struct.pack("<I", len(rest)) + rest


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
    if zone == "ix_emotes":
        return os.path.isfile("zone/ix_emotes.ff") or os.path.isfile("ix_emotes.ff")
    return zone in ZONE_IMAGES and zone not in config.get("missing_zones", [])


def zone_xanims(zone, config):
    return config.get("xanim_zones", ZONE_XANIMS).get(zone, [])


def zone_xmodels(zone, config):
    if not config.get("fixtures"):
        return []
    return config.get("xmodel_zones", ZONE_XMODELS).get(zone, [])


def fixtures(config):
    sys.path.insert(0, config["fixtures"])
    import emote_fixtures
    return emote_fixtures


def dump_csv(zone, config):
    """dumpcsv: the zone's assets as "<type>,<name>" lines."""
    kind = config.get("xanim_type", "xanim")
    if zone == "ix_emotes":
        path = "zone/ix_emotes.ff" if os.path.isfile("zone/ix_emotes.ff") else "ix_emotes.ff"
        rows = [f"{kind},{x['name']}" for x in json.load(open(path, encoding="utf-8")).get("xanims", [])]
    else:
        rows = [f"image,{name}" for name in ZONE_IMAGES[zone]] + [f"{kind},{name}" for name in zone_xanims(zone, config)]
        rows += [f"xmodel,{name}" for name in zone_xmodels(zone, config)]
    write(f"dump/{zone}/{zone}.csv", "".join(row + "\n" for row in rows).encode())
    say(f'Csv "{zone}" dumped...')


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
        elif words[0] == "dumpcsv":
            zone = words[1]
            if zone in config.get("crash_on_csv", []):
                return 7
            if not zone_exists(zone, config):
                say(f'Zone "{zone}" could not be found!')
            elif zone in loaded:
                say(f'zone "{zone}" is already loaded...')
            else:
                dump_csv(zone, config)
                loaded.add(zone)
        elif words[:2] == ["dumpasset", "xmodel"] and config.get("fixtures"):
            names = {n.lower(): n for zone in loaded for n in zone_xmodels(zone, config)}
            name = names.get(words[2].lower())
            if name is None:
                say("Asset not found")
            else:
                write(f"dump/assets/xmodel/{name}.xmb", fixtures(config).make_rig(name)[0])
                say("Dumped to dump/assets")
        elif words[0] == "dumpasset" and words[1] not in ("material", "image"):
            if words[1] != config.get("xanim_type", "xanim"):
                log("dumpasset with an unknown type: crash")
                return 6
            names = {n.lower(): (n, i) for zone in loaded for i, n in enumerate(zone_xanims(zone, config))}
            name, index = names.get(words[2].lower(), (None, 0))
            if name is None:
                say("Asset not found")
            elif config.get("fixtures"):
                variant = ("short", "long_inline", "long_indices")[min(index, 2)]
                data = bytearray(fixtures(config).sample_animation(name, variant))
                if name in config.get("corrupt_xanims", []):
                    data[6 + 121] += 1
                write(f"dump/assets/xanim/{name}.xab", bytes(data))
                say("Dumped to dump/assets")
            else:
                frames, framerate, flags = config.get("xanim_frames", [151, 30.0, 0])
                write(f"dump/assets/xanim/{name}.xab", make_xab(name, frames, framerate, flags))
                say("Dumped to dump/assets")
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
    config = json.load(open(CONFIG, encoding="utf-8")) if os.path.isfile(CONFIG) else {}
    kind = config.get("xanim_type", "xanim")
    materials = []
    xanims = []
    for row in rows:
        if row.startswith(kind + ","):
            name = row.split(",", 1)[1]
            path = f"{source}/xanim/{name}.xab"
            if not os.path.isfile(path):
                say(f"missing {path}")
                return 2
            data = open(path, "rb").read()
            if data[:6] != bytes([8, 1, 1, 0, 0, 0]) or data[142:144] != bytes([6, 1]):
                say(f"{path} is not an animation")
                return 2
            inner = data[144:data.index(0, 144)].decode()
            xanims.append({"name": name, "inner": inner, "size": len(data), "tail": data[data.index(0, 144) + 1:].hex(), "data": data.hex()})
            continue
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
    write(target, json.dumps({"rows": rows, "materials": materials, "xanims": xanims}).encode())
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
