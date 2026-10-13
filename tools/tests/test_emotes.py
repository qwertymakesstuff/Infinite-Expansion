"""Checks the emotes (Phase 14) against the game's own scripts.

emote_data.gsc lists each map's emotes: data only, one case per map. Nothing
in it may be invented, so this test reads it the way the script builds it
(add_cast and the add_* helpers) and holds every emote to the decompiled
stock scripts of its map:
  - a character's Pack-a-Punch, entrance and card gesture are the weapons the
    map registers for that character (register_player_character, arguments
    8, 13 and 11 of <map>_player_character_setup.gsc);
  - an entrance's length is the gesture the map's own waitgesturelength()
    times it with, for the same character;
  - a card's sound is the one zombies_consumables.gsc plays with that card;
  - a hand gesture is one the map's own scripts play.
It also holds the names and texts to what the menu shows.

Run: python3 -m unittest discover -s tools/tests -v
"""
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SCRIPTS = REPO / "mods" / "infinite_expansion" / "custom_scripts"
DATA = SCRIPTS / "ix" / "fun" / "emote_data.gsc"
EMOTES = SCRIPTS / "ix" / "fun" / "emotes.gsc"
MENU = SCRIPTS / "ix" / "ui" / "menu.gsc"
MENU_TREE = SCRIPTS / "ix" / "ui" / "menu_tree.gsc"
DUMP = REPO / ".toolchain" / "src" / "iw7-gsc-dump" / "decompiled" / "scripts"
MAPS = ["cp_zmb", "cp_rave", "cp_disco", "cp_town", "cp_final"]

STRING = r'"([^"]*)"'
CASE = re.compile(r'case "(cp_[a-z]+)":(.*?)break;', re.S)
ARRAY = re.compile(r'^\s*(\w+) = \[([^\]]*)\];', re.M)
CALL = re.compile(r'^\s*list = (add_\w+)\( list, (.*)\);', re.M)
ARGUMENT = re.compile(r'"[^"]*"|\[\s*\]|\w+')
REGISTER = re.compile(r'register_player_character\(\s*(\d+),(.*?)\);')
# The ways the stock scripts play a hand gesture, or time one.
GESTURE_USE = re.compile(r'(?:playgestureviewmodel|gesture_activate|getgestureanimlength|wait_for_gesture_length)\(\s*"([a-z0-9_]+)"')
# menu.gsc: help text is wrapped to help_width() letters on help_lines() lines
# at a scale of 0.85 across the panel, less its margins.
HELP_SCALE = 0.85
MARGINS = 16
# A row shows "7. " and a name on the Favorites page; the value column is
# empty there.
ROW_CHARS = 30
# What persist.gsc save() takes: these letters, at most 64 of them.
SAVE_SAFE = re.compile(r"^[A-Za-z0-9_.\-]*$")
SAVE_MAX = 64


def strings(text):
    return re.findall(STRING, text)


def catalog():
    """{map: [emote dict]} as emote_data.gsc catalog() builds it."""
    text = DATA.read_text()
    helpers = {name: body for name, body in re.findall(r"^(add_\w+|new_emote|short_name|card_sound)\(([^)]*)\)", text, re.M)}
    for name in ("add_cast", "add_pap", "add_intro", "add_card", "add_gesture", "new_emote"):
        assert name in helpers, name
    found = {}
    for map_name, body in CASE.findall(text):
        arrays = {name: strings(items) for name, items in ARRAY.findall(body)}
        emotes = []
        for function, arguments in CALL.findall(body):
            words = ARGUMENT.findall(arguments)
            values = []
            for word in words:
                if word.startswith('"'):
                    values.append(word.strip('"'))
                elif word.startswith("["):
                    values.append([])
                else:
                    values.append(arrays[word])
            if function == "add_cast":
                who, pap, intro, length, card = values
                for i, name in enumerate(who):
                    if i < len(pap):
                        emotes.append(make("pap", "pap" + str(i + 1), name, pap[i], slot=i + 1))
                    if i < len(intro):
                        emotes.append(make("intro", "intro" + str(i + 1), name, intro[i], slot=i + 1,
                                           length=length[i] if i < len(length) else None))
                    if i < len(card):
                        emotes.append(make("card", "card" + str(i + 1), name, card[i], slot=i + 1))
            elif function == "add_pap":
                emote_id, who, asset = values
                emotes.append(make("pap", emote_id, who, asset))
            elif function == "add_intro":
                emote_id, who, asset, length = values
                emotes.append(make("intro", emote_id, who, asset, length=length))
            elif function == "add_card":
                emote_id, who, asset = values
                emotes.append(make("card", emote_id, who, asset))
            elif function == "add_gesture":
                emote_id, name, short, category, asset, help_text = values
                emotes.append({"type": "gesture", "id": emote_id, "name": name, "wheel": short, "category": category,
                               "kind": "gesture", "asset": asset, "length": asset, "help": help_text})
            else:
                raise AssertionError(f"{map_name}: unknown {function}")
        found[map_name] = emotes
    return found


def make(kind, emote_id, who, asset, slot=None, length=None):
    """add_pap / add_intro / add_card, as the script names them."""
    text = DATA.read_text()
    short = {"The Hoff": "Hoff", "Kevin Smith": "Kevin", "Pam Grier": "Pam"}.get(who, who)
    for name, wanted in (("The Hoff", "Hoff"), ("Kevin Smith", "Kevin"), ("Pam Grier", "Pam")):
        assert re.search(r'case "' + re.escape(name) + r'":\s*return "' + wanted + '";', text), name
    everyone = who == "Everyone"
    if kind == "pap":
        name, wheel, category = "Pack-a-Punch", short + " PaP", "Celebration"
        help_text = who + "'s own Pack-a-Punch celebration, as the game plays it when a weapon is upgraded."
        if everyone:
            wheel, help_text = "PaP", "The Pack-a-Punch celebration, as the game plays it when a weapon is upgraded."
    elif kind == "intro":
        name, wheel, category = "Entrance", short + " entry", "Poses"
        help_text = who + "'s entrance from the start of the match, again."
        if everyone:
            wheel, help_text = "Entrance", "The entrance from the start of the match, again."
    else:
        name, wheel, category = "Card trick", short + " card", "Funny"
        help_text = "How " + who + " plays a Fate & Fortune card, with its sound. No card is used."
        if everyone:
            wheel, help_text = "Card trick", "How a Fate & Fortune card is played, with its sound. No card is used."
    if not everyone:
        name = who + ": " + name
    return {"type": kind, "id": emote_id, "who": who, "slot": slot, "name": name, "wheel": wheel,
            "category": category, "kind": "offhand", "asset": asset, "length": length, "help": help_text}


def characters(map_name):
    """{slot: register_player_character arguments} of the map, as strings."""
    path = DUMP / "cp" / "maps" / map_name / (map_name + "_player_character_setup.gsc")
    found = {}
    for slot, rest in REGISTER.findall(path.read_text()):
        arguments = [slot] + [word.strip() for word in rest.split(",")]
        found[int(slot)] = [word.strip('"') for word in arguments]
    return found


def intro_lengths(map_name):
    """{vo prefix: gesture} of the map's waitgesturelength()."""
    text = "\n".join(path.read_text() for path in (DUMP / "cp" / "maps" / map_name).glob("*.gsc"))
    match = re.search(r"^waitgesturelength\(\)\s*\{(.*?)^\}", text, re.M | re.S)
    if not match:
        return {}  # cp_zmb fires the entrance and waits for its flag
    body = match.group(1)
    return dict(re.findall(r'case "(p\d_)":\s*return self getgestureanimlength\( "([a-z0-9_]+)" \)', body))


def card_sounds():
    text = (DUMP / "cp" / "zombies" / "zombies_consumables.gsc").read_text()
    body = re.search(r"^play_consumable_activate_sound\( var_0 \)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
    sounds = dict(re.findall(r'case "([a-z0-9_]+)":\s*var_0 playlocalsound\( "([a-z0-9_]+)" \);', body))
    default = re.search(r'default:\s*var_0 playlocalsound\( "([a-z0-9_]+)" \);', body).group(1)
    return sounds, default


def script_sounds():
    """{card: sound} of emote_data.gsc card_sound(), and its default."""
    text = DATA.read_text()
    body = re.search(r"^card_sound\( asset \)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
    sounds = dict(re.findall(r'case "([a-z0-9_]+)":\s*return "([a-z0-9_]+)";', body))
    default = re.search(r'\}\s*return "([a-z0-9_]+)";', body).group(1)
    return sounds, default


def menu_number(name, cast=int):
    match = re.search(name + r"\(\)\s*\{\s*return ([\d.]+);", MENU.read_text())
    return cast(match.group(1))


def wrap(text, width):
    lines, line = [], ""
    for word in text.split():
        if line and len(line) + 1 + len(word) > width:
            lines.append(line)
            line = ""
        line = word if not line else line + " " + word
    if line:
        lines.append(line)
    return lines


@unittest.skipUnless(DUMP.is_dir(), "the decompiled stock scripts are not set up (tools/setup_compilers.sh)")
class Emotes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = catalog()

    def test_every_map_has_emotes(self):
        self.assertEqual(sorted(self.catalog), sorted(MAPS))
        for map_name in MAPS:
            self.assertGreaterEqual(len(self.catalog[map_name]), 3, map_name)

    def test_character_gestures_are_the_ones_the_map_registers(self):
        argument = {"pap": 8, "card": 11, "intro": 13}
        checked = 0
        for map_name, emotes in self.catalog.items():
            cast = characters(map_name)
            self.assertTrue(cast, map_name)
            for emote in emotes:
                if emote["kind"] != "offhand":
                    continue
                index = argument[emote["type"]]
                if emote["slot"] is not None:
                    owners = [cast[emote["slot"]]]
                elif emote["who"] == "Everyone":
                    owners = list(cast.values())
                else:
                    # add_card( list, "cardN", ... ): character N's card.
                    owners = [cast[int(emote["id"][-1])]]
                for owner in owners:
                    self.assertEqual(owner[index], emote["asset"], f"{map_name} {emote['id']}")
                checked += 1
        self.assertGreater(checked, 40)

    def test_shared_ones_are_shared(self):
        # "Everyone" is written only where every character has the same one.
        index = {"pap": 8, "card": 11, "intro": 13}
        for map_name, emotes in self.catalog.items():
            cast = characters(map_name)
            for emote in emotes:
                if emote.get("who") == "Everyone":
                    assets = {owner[index[emote["type"]]] for owner in cast.values()}
                    self.assertEqual(assets, {emote["asset"]}, f"{map_name} {emote['id']}")

    def test_entrances_last_as_the_map_times_them(self):
        for map_name, emotes in self.catalog.items():
            lengths = intro_lengths(map_name)
            for emote in emotes:
                if emote["type"] != "intro":
                    continue
                if emote["slot"] is not None:
                    prefixes = ["p" + str(emote["slot"]) + "_"]
                else:
                    prefixes = sorted(lengths)
                if emote["length"] is None:
                    # cp_zmb has no waitgesturelength(): its own seconds.
                    self.assertEqual(lengths.get(prefixes[0]), None, f"{map_name} {emote['id']}")
                    continue
                for prefix in prefixes:
                    self.assertEqual(lengths[prefix], emote["length"], f"{map_name} {emote['id']}")

    def test_card_sounds_are_the_games(self):
        stock, stock_default = card_sounds()
        mine, my_default = script_sounds()
        self.assertEqual(mine, stock)
        self.assertEqual(my_default, stock_default)
        self.assertIn('emote.sound = card_sound( asset );', DATA.read_text())
        self.assertIn("compat::local_sound( emote.sound )", EMOTES.read_text())

    def test_hand_gestures_are_played_on_their_map(self):
        for map_name, emotes in self.catalog.items():
            own = set()
            for path in (DUMP / "cp" / "maps" / map_name).rglob("*.gsc"):
                own.update(GESTURE_USE.findall(path.read_text()))
            for emote in emotes:
                if emote["kind"] == "gesture":
                    self.assertIn(emote["asset"], own, f"{map_name} {emote['id']}")
                if emote["type"] == "intro" and emote["length"]:
                    self.assertIn(emote["length"], own, f"{map_name} {emote['id']}")

    def test_ids_are_unique_and_favorites_can_be_saved(self):
        slots = int(re.search(r"^slot_count\(\)\s*\{\s*return (\d+);", EMOTES.read_text(), re.M).group(1))
        self.assertEqual(slots, 7)
        for map_name, emotes in self.catalog.items():
            ids = [emote["id"] for emote in emotes]
            self.assertEqual(len(ids), len(set(ids)), map_name)
            for emote_id in ids:
                self.assertRegex(emote_id, r"^[a-z0-9]+$")
                self.assertNotIn(emote_id, ("list", "random"), "a chat word")
            longest = max(len(emote_id) for emote_id in ids)
            saved = ".".join(["x" * longest] * slots)
            self.assertLessEqual(len(saved), SAVE_MAX, map_name)
            self.assertRegex(saved, SAVE_SAFE)
        self.assertIn('persist::save( "ix_emote_favorites", custom_scripts\\ix\\core\\util::join( ids, "." ) );', EMOTES.read_text())

    def test_favorites_of_other_maps_are_kept(self):
        # One saved list for every map: a favorite this map lacks is kept.
        text = EMOTES.read_text()
        load = re.search(r"^load_favorites\(\)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
        save = re.search(r"^save_favorites\(\)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
        self.assertIn("self.ix.emote.other_maps[slot] = ids[slot];", load)
        self.assertIn("ids[ids.size] = self.ix.emote.other_maps[slot];", save)
        self.assertIn("if ( !self ishost() )", save)
        # The same id is the same character's on every map (add_cast numbers
        # them by the character's place, as register_player_character does).
        for map_name, emotes in self.catalog.items():
            cast = characters(map_name)
            for emote in emotes:
                if emote.get("slot"):
                    self.assertEqual(int(cast[emote["slot"]][0]), emote["slot"], f"{map_name} {emote['id']}")

    def test_categories(self):
        listed = strings(re.search(r"^categories\(\)\s*\{\s*return \[([^\]]*)\];", DATA.read_text(), re.M).group(1))
        for map_name, emotes in self.catalog.items():
            for emote in emotes:
                self.assertIn(emote["category"], listed, f"{map_name} {emote['id']}")

    def test_names_fit_the_menu(self):
        width = menu_number("help_width")
        help_px = menu_number("menu_width") - MARGINS
        cell = menu_number("wheel_cell")
        scale = menu_number("wheel_scale", float)
        # Letters per pixel of the help text (scale 0.85), at the wheel's scale.
        wheel_chars = int(cell * width / help_px * HELP_SCALE / scale)
        self.assertGreaterEqual(wheel_chars, 16)
        self.assertIn("hud.labels[row].fontscale = wheel_scale();", MENU.read_text())
        for map_name, emotes in self.catalog.items():
            for emote in emotes:
                self.assertLessEqual(len(emote["wheel"]), wheel_chars, f"{map_name} {emote['id']}: {emote['wheel']}")
                self.assertLessEqual(len("7. " + emote["name"]), ROW_CHARS, f"{map_name} {emote['id']}")

    def test_help_fits(self):
        lines, width = menu_number("help_lines"), menu_number("help_width")
        text = EMOTES.read_text()
        # slot_help() adds the longer of its two notes.
        notes = re.findall(r'return emote\.help \+ "([^"]*)";', text)
        self.assertEqual(len(notes), 2)
        for map_name, emotes in self.catalog.items():
            for emote in emotes:
                for note in notes:
                    needed = wrap(emote["help"] + note, width)
                    self.assertLessEqual(len(needed), lines, f"{map_name} {emote['id']}: {needed}")
        for message in re.findall(r'self iprintln\( "([^"]*)" \);', text):
            self.assertLessEqual(len(message), 64, message)
        for problem in re.findall(r'return "([^"]+)";', re.search(r"^cannot_emote\(\)\s*\{(.*?)^\}", text, re.M | re.S).group(1)):
            self.assertLessEqual(len(problem), 64, problem)

    def test_menu_pages(self):
        tree = MENU_TREE.read_text()
        body = re.search(r"^emote_pages\(\)\s*\{(.*?)^\}", tree, re.M | re.S).group(1)
        self.assertIn("wheel.wheel = 1;", body)
        # Eight places on the ring: Back at the bottom, the seven slots around.
        self.assertIn("for ( position = 0; position < 8; position++ )", body)
        self.assertIn("if ( position == 4 )", body)
        self.assertEqual(menu_number("rows"), 8)
        for setting in ("emotes", "emote_camera", "emote_cancel_damage"):
            self.assertIn('add_setting( "emote_settings", "' + setting + '", 1 );', body)
        self.assertIn("emote_pages();", tree)

    def test_an_emote_cannot_hold_the_player(self):
        text = EMOTES.read_text()
        run = re.search(r"^run\( emote, preview \)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
        restore = re.search(r"^restore\( emote \)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
        # Everything taken is given back: the stock counters, the camera.
        for taken, given in (("allow_ads( 0 )", "allow_ads( 1 )"), ("allow_melee( 0 )", "allow_melee( 1 )"),
                             ("allow_offhand_weapons( 0 )", "allow_offhand_weapons( 1 )"),
                             ("compat::third_person( 1 )", "options::apply_view()")):
            self.assertIn(taken, run)
            self.assertIn(given, restore)
        for held in ("freezecontrols", "linkto", "allowmovement", "disableweapons", "takeweapon", "setstance"):
            self.assertNotIn(held, text)
        trouble = re.search(r"^end_on_trouble\(\)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
        for ending in ('"death"', '"last_stand"', '"damage"', '"ix_emote_end"'):
            self.assertIn(ending, trouble)
        self.assertIn("return min( max( seconds, 1 ), 8 );", text)


if __name__ == "__main__":
    unittest.main()
