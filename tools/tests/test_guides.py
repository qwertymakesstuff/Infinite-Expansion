"""Checks the Guided Mode guides (Phase 13) against the game's own scripts.

Each map's guide (mods/.../ix/guided/guides/<map>.gsc) is data: new_guide()
and one add_step() per step, with the objective, the location, three hints,
how the game reports the step ("detect") and where its marker goes
("marker"). Nothing in a guide may be invented, so this test holds every
signal and every marker to the decompiled stock scripts: a flag must be one
the game sets, a notify one the game sends, a targetname one the game's own
scripts look up. It also holds the texts to what the tracker on screen and
the menu show.

Run: python3 -m unittest discover -s tools/tests -v
"""
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GUIDES = REPO / "mods" / "infinite_expansion" / "custom_scripts" / "ix" / "guided" / "guides"
GUIDED = REPO / "mods" / "infinite_expansion" / "custom_scripts" / "ix" / "guided" / "guided.gsc"
DUMP = REPO / ".toolchain" / "src" / "iw7-gsc-dump" / "decompiled" / "scripts"
MAPS = ["cp_zmb", "cp_rave", "cp_disco", "cp_town", "cp_final"]

# A quoted GSC string (no escapes are used in the guides).
STRING = r'"((?:[^"\\]|\\.)*)"'
NEW_GUIDE = re.compile(r'new_guide\(\s*' + r',\s*'.join([STRING] * 4) + r'\s*\)')
ADD_STEP = re.compile(r'add_step\(\s*guide,\s*' + r',\s*'.join([STRING] * 8) + r'\s*\)')
LIMITS = {"objective": 32, "location": 40, "minimal": 70, "standard": 150, "detailed": 300}
DETECT = re.compile(r'^(flag|flags|notify|count):([a-z0-9_+ ]+)(?:\*([1-9][0-9]*))?$|^(check|manual)$')
MARKER = re.compile(r'^(struct|ent|structs|ents|sn_struct|sn_structs|interaction):([a-z0-9_]+)$|^(locate|none)$')


def stock_text(map_name):
    """The stock scripts a map runs: its own, the shared zombies ones and cp/."""
    paths = list((DUMP / "cp" / "maps" / map_name).rglob("*.gsc"))
    paths += list((DUMP / "cp" / "zombies").glob("*.gsc"))
    paths += list((DUMP / "cp").glob("*.gsc"))
    return "\n".join(path.read_text(errors="replace") for path in paths)


def looked_up(stock, name, function, key):
    """The stock scripts look this name up: getstruct( "name", "targetname" ),
    or pass "name" to a function that looks up its argument the same way
    (disco_mpq.gsc rk_symbol_handler( "rk_symbol_punk_streets", ... ) does
    getstruct( var_0, "targetname" ))."""
    literal = re.search(function + r'(?:array)?\(\s*"' + re.escape(name) + r'",\s*"' + key + '"', stock)
    if literal:
        return True
    passed = re.search(r'[(,]\s*"' + re.escape(name) + r'"\s*[,)]', stock)
    by_variable = re.search(function + r'(?:array)?\(\s*var_\d+,\s*"' + key + '"', stock)
    return bool(passed and by_variable)


def sets_flag(stock, name):
    """The stock scripts set this flag: flag_set( "name" ), or flag_init it
    and pass "name" to a function that does flag_set( var_N ) (disco_mpq.gsc
    rk_symbol_handler( "rk_symbol_punk_streets", "skq_p2t1_4" ))."""
    if re.search(r'flag_set\(\s*"' + re.escape(name) + '"', stock):
        return True
    initialised = re.search(r'flag_init\(\s*"' + re.escape(name) + '"', stock)
    passed = re.search(r'\w+\([^;\n]*"' + re.escape(name) + r'"\s*\)', stock)
    by_variable = re.search(r'flag_set\(\s*var_\d+\s*\)', stock)
    return bool(initialised and passed and by_variable)


def sends_notify(stock, name):
    """The stock scripts send this level notify: level notify( "name" ), or
    pass "name" to a function that does level notify( var_N )
    (cp_town_crab_boss_death_wall.gsc wail_all_player_trigger_teleporter(
    undefined, "players_trigger_vehicle_teleporter" ))."""
    if re.search(r'level notify\(\s*"' + re.escape(name) + '"', stock):
        return True
    passed = re.search(r'[(,]\s*"' + re.escape(name) + r'"\s*[,)]', stock)
    by_variable = re.search(r'level notify\(\s*var_\d+\s*\)', stock)
    return bool(passed and by_variable)


def after_step(text, step_id):
    """A guide's text from the add_step of step_id to the next add_step."""
    start = text.index(f'add_step( guide, "{step_id}"')
    following = text.find("add_step(", start + 1)
    return text[start:] if following < 0 else text[start:following]


def guides():
    """{map: (header, [steps])} for every map whose guide is written."""
    found = {}
    for map_name in MAPS:
        text = (GUIDES / f"{map_name}.gsc").read_text()
        header = NEW_GUIDE.search(text)
        if not header:
            continue
        steps = [dict(zip(("id", "objective", "location", "minimal", "standard", "detailed", "detect", "marker"), match))
                 for match in ADD_STEP.findall(text)]
        found[map_name] = (header.groups(), steps, text)
    return found


@unittest.skipUnless(DUMP.exists(), "the stock script dump is not set up (tools/setup_compilers.sh)")
class Guides(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.guides = guides()

    def test_every_map_has_a_guide_file_and_a_loader_line(self):
        loader = GUIDED.read_text()
        for map_name in MAPS:
            self.assertTrue((GUIDES / f"{map_name}.gsc").exists(), map_name)
            self.assertIn(f'case "{map_name}":\n            return custom_scripts\\ix\\guided\\guides\\{map_name}::guide();', loader)

    def test_a_guide_without_steps_is_no_guide(self):
        # A guide file either returns undefined (Guided Mode says it is
        # unavailable) or a guide with steps, never an empty one.
        for map_name in MAPS:
            text = (GUIDES / f"{map_name}.gsc").read_text()
            if map_name in self.guides:
                self.assertGreater(len(self.guides[map_name][1]), 0, map_name)
                self.assertEqual(len(self.guides[map_name][1]), text.count("add_step("), f"{map_name}: an add_step the test cannot read")
            else:
                self.assertIn("return undefined;", text, map_name)

    def test_headers(self):
        for map_name, ((guide_map, map_title, quest, prerequisites), _steps, _text) in self.guides.items():
            self.assertEqual(guide_map, map_name)
            self.assertTrue(map_title and quest and prerequisites, map_name)
            self.assertLessEqual(len(quest), 40, f"{map_name}: quest name")

    def test_texts_fit(self):
        for map_name, (_header, steps, _text) in self.guides.items():
            ids = [step["id"] for step in steps]
            self.assertEqual(len(ids), len(set(ids)), f"{map_name}: step ids twice")
            for step in steps:
                self.assertRegex(step["id"], r"^[a-z0-9_]+$")
                for key, limit in LIMITS.items():
                    self.assertTrue(step[key].strip(), f"{map_name} {step['id']}: no {key}")
                    self.assertLessEqual(len(step[key]), limit, f"{map_name} {step['id']}: {key}")
                    self.assertNotIn("%", step[key], "chat and iprintln lines may go through a printf")

    def test_signals_are_the_games_own(self):
        for map_name, (_header, steps, text) in self.guides.items():
            stock = stock_text(map_name)
            for step in steps:
                match = DETECT.match(step["detect"])
                self.assertTrue(match, f"{map_name} {step['id']}: detect {step['detect']}")
                kind, names = match.group(1), match.group(2)
                # A count is "count:<notify>*<n>"; only a count has "*<n>".
                self.assertEqual(kind == "count", match.group(3) is not None, f"{map_name} {step['id']}: detect {step['detect']}")
                if kind in ("flag", "flags"):
                    for name in names.split("+"):
                        self.assertTrue(sets_flag(stock, name), f"{map_name} {step['id']}: the game never sets flag {name}")
                elif kind in ("notify", "count"):
                    self.assertTrue(sends_notify(stock, names), f"{map_name} {step['id']}: the game never notifies {names}")
                elif match.group(4) == "check":
                    self.assertIn("step.check = ::", after_step(text, step["id"]), f"{map_name} {step['id']}: no check function")

    def test_resets_are_the_games_own(self):
        # step.reset names a notify the game sends when it undoes a step.
        for map_name, (_header, steps, text) in self.guides.items():
            stock = stock_text(map_name)
            for step in steps:
                for names in re.findall(r'step\.reset = "([a-z0-9_ ]+)";', after_step(text, step["id"])):
                    for name in names.split():
                        self.assertTrue(sends_notify(stock, name), f"{map_name} {step['id']}: the game never notifies {name}")

    def test_parallel_steps_are_closed_by_a_later_step(self):
        # A step done in any order (step.parallel = 1) closes only by its own
        # signal or with a later step that needs it (step.needs, directly or
        # through another step): every one is needed by a step after it.
        for map_name, (_header, steps, text) in self.guides.items():
            needs = {}
            for step in steps:
                found = re.findall(r'step\.needs = "([a-z0-9_ ]+)";', after_step(text, step["id"]))
                needs[step["id"]] = found[0].split() if found else []
            needed = set()
            for names in needs.values():
                needed.update(names)
            for step in steps:
                if "step.parallel = 1;" in after_step(text, step["id"]):
                    self.assertIn(step["id"], needed, f"{map_name} {step['id']}: a parallel step no later step needs")

    def test_needs_name_earlier_steps(self):
        # step.needs lists the ids of earlier steps a step cannot be done
        # without; the tracker closes them with it.
        for map_name, (_header, steps, text) in self.guides.items():
            ids = [step["id"] for step in steps]
            for index, step in enumerate(steps):
                for names in re.findall(r'step\.needs = "([a-z0-9_ ]+)";', after_step(text, step["id"])):
                    for name in names.split():
                        self.assertIn(name, ids[:index], f"{map_name} {step['id']}: needs {name}, not an earlier step")

    def test_markers_are_places_the_game_looks_up(self):
        for map_name, (_header, steps, text) in self.guides.items():
            stock = stock_text(map_name)
            for step in steps:
                match = MARKER.match(step["marker"])
                self.assertTrue(match, f"{map_name} {step['id']}: marker {step['marker']}")
                kind, name = match.group(1), match.group(2)
                lookups = {"struct": ("getstruct", "targetname"), "structs": ("getstruct", "targetname"),
                           "ent": ("getent", "targetname"), "ents": ("getent", "targetname"),
                           "sn_struct": ("getstruct", "script_noteworthy"), "sn_structs": ("getstruct", "script_noteworthy")}
                if kind in lookups:
                    self.assertTrue(looked_up(stock, name, *lookups[kind]), f"{map_name} {step['id']}: the stock scripts never look up {kind} {name}")
                elif kind == "interaction":
                    # An interaction the game registers itself:
                    # register_interaction( "name", ... ) (cp_interaction.gsc),
                    # town_register_interaction( 1, "name", ... ) (cp_town).
                    registered = re.search(r'register_interaction\(\s*(?:\d+,\s*)?"' + re.escape(name) + '"', stock)
                    self.assertTrue(registered, f"{map_name} {step['id']}: the game registers no interaction {name}")
                elif match.group(3) == "locate":
                    self.assertIn("step.locate = ::", after_step(text, step["id"]), f"{map_name} {step['id']}: no locate function")


if __name__ == "__main__":
    unittest.main()
