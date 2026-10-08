"""Checks the cast table in ix/player/character.gsc against the stock scripts.

The special characters' models, slots, lobby ids and unlock stats are copied
from the decompiled stock scripts; this test re-reads those scripts so a typo
cannot ship. The CHARACTER menu (ui_scripts/InfiniteExpansion) writes the same
lobby ids and checks the same unlock stats, so its table is checked too. The
setup's picture pack (installer/IXPictures.Core.ps1) must take each special
character's cards from the slot character.gsc gives them. Needs the stock dump
from tools/setup_compilers.sh.

Run: python3 -m unittest discover -s tools/tests -v
"""
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHARACTER_GSC = REPO / "mods" / "infinite_expansion" / "custom_scripts" / "ix" / "player" / "character.gsc"
MENU_LUA = REPO / "mods" / "infinite_expansion" / "ui_scripts" / "InfiniteExpansion" / "__init__.lua"
PICTURES_CORE = REPO / "installer" / "IXPictures.Core.ps1"
DUMP = REPO / ".toolchain" / "src" / "iw7-gsc-dump" / "decompiled" / "scripts"
MAPS = ("cp_zmb", "cp_rave", "cp_disco", "cp_town", "cp_final")

REGISTER = re.compile(r'register_player_character\(\s*(\d+),\s*"(yes|no)",\s*("[^"]*"|undefined|var_\d+),\s*("[^"]*"|undefined),\s*("[^"]*"|undefined),\s*("[^"]*"|undefined),\s*"(p\d_)",\s*"[^"]*",\s*[^,]+,\s*[^,]+,\s*(\d+)')
MENU_ROW = re.compile(r'^\s*\{ key = "(\w+)", (.*?)text = ', re.M | re.S)
MENU_FIELD = re.compile(r'\b(select|soulKey|merit|portrait) = "?(\w+)"?')
MAKE_REGULAR = re.compile(r'make_regular\(\s*\d+,\s*"(\w+)"')
# key, home map, slot, characterSelect, soul key, merit, body, view, head, photo
PLAN_MAP = re.compile(r"Map = '(cp_\w+)';.*?Main = '([^']+)'; Team = '([^']+)'; Special = (?:'(\w+)'|\$null)")
PLAN_WILLARD = re.compile(r"Source = '(zm_\w+)'; Name = 'ix_(card|icon)_willard'")
MAKE_SPECIAL = re.compile(r'make_special\(\s*"(\w+)",\s*"[^"]+",\s*\[[^\]]*\],\s*"(\w+)",\s*(\d+),\s*(\d+),\s*"(\w+)",\s*("\w+"|undefined),\s*"([^"]+)",\s*"([^"]+)",\s*("[^"]+"|undefined),\s*(\d+)\s*\)')


def unquote(token):
    return None if token == "undefined" else token.strip('"')


def stock_registrations(map_name):
    """{slot: (available, body, view, head, vo_prefix, photo)} from the map's character setup."""
    source = (DUMP / "cp" / "maps" / map_name / f"{map_name}_player_character_setup.gsc").read_text()
    rows = {}
    for match in REGISTER.finditer(source):
        slot, available, body, view, head, _hair, vo, photo = match.groups()
        rows[int(slot)] = (available, unquote(body), unquote(view), unquote(head), vo, int(photo))
    return rows


def lobby_values():
    """{map: {characterSelect value: slot}} from zombies_loadout::get_player_character_num."""
    source = (DUMP / "cp" / "zombies" / "zombies_loadout.gsc").read_text()
    body = source[source.index("\nget_player_character_num()\n"):source.index("\nsetplayerinside(")]
    values = {}
    for case in re.finditer(r'case "(cp_\w+)":(.*?)(?=case "|default:)', body, re.S):
        pairs = re.findall(r'"characterSelect" \) == (\d+) \)\s*\{\s*var_2 = (\d+);', case.group(2))
        values[case.group(1)] = {int(value): int(slot) for value, slot in pairs}
    return values


def soul_keys():
    """{map: soul key} from directors_cut::get_num_of_newbs_in_game."""
    source = (DUMP / "cp" / "zombies" / "directors_cut.gsc").read_text()
    body = source[source.index("\nget_num_of_newbs_in_game()\n"):]
    return dict(re.findall(r'case "(cp_\w+)":\s*var_1 = "(soul_key_\d)";', body))


@unittest.skipUnless(DUMP.is_dir(), "run tools/setup_compilers.sh first")
class CharacterData(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.registrations = {name: stock_registrations(name) for name in MAPS}
        cls.specials = {m.group(1): m.groups() for m in MAKE_SPECIAL.finditer(CHARACTER_GSC.read_text())}

    def test_every_map_registers_four_regular_slots(self):
        for name, rows in self.registrations.items():
            for slot in (1, 2, 3, 4):
                self.assertEqual(rows[slot][0], "yes", f"{name} slot {slot}")
                self.assertEqual(rows[slot][4], f"p{slot}_", f"{name} slot {slot} VO prefix")
            for slot, row in rows.items():
                if slot > 4:
                    self.assertEqual(row[0], "no", f"{name} special slot {slot}")

    def test_specials_match_their_home_map(self):
        self.assertEqual(set(self.specials), {"hoff", "willard", "kevin", "pam", "elvira"})
        for key, (_, home, slot, _select, _soul_key, _merit, body, view, head, photo) in self.specials.items():
            stock = self.registrations[home][int(slot)]
            self.assertEqual(stock[0], "no", key)
            self.assertEqual(stock[1], body, f"{key} body model")
            self.assertEqual(stock[2], view, f"{key} view model")
            self.assertEqual(stock[3], unquote(head), f"{key} head model")
            self.assertEqual(stock[5], int(photo), f"{key} photo index")

    def test_every_stock_special_is_in_the_table(self):
        listed = {(s[1], int(s[2])) for s in self.specials.values()}
        for name, rows in self.registrations.items():
            for slot in rows:
                if slot > 4:
                    self.assertIn((name, slot), listed, f"{name} slot {slot} missing from character.gsc")

    def test_lobby_values_match_stock(self):
        stock = lobby_values()
        for key, (_, home, slot, select, *_rest) in self.specials.items():
            self.assertEqual(stock[home].get(int(select)), int(slot), f"{key}: characterSelect {select} on {home}")

    def test_menu_matches_the_cast(self):
        rows = {key: dict(MENU_FIELD.findall(fields)) for key, fields in MENU_ROW.findall(MENU_LUA.read_text())}
        regular = MAKE_REGULAR.findall(CHARACTER_GSC.read_text())
        self.assertEqual(len(regular), 4)
        self.assertEqual(set(rows), {"random", *regular, *self.specials})
        for key in ("random", *regular):
            self.assertEqual(rows[key], {}, f"{key} must not write a lobby value or need an unlock")
        for key, (_, _home, _slot, select, soul_key, merit, *_rest) in self.specials.items():
            row = rows[key]
            self.assertEqual(row.get("select"), select, f"{key}: the menu's lobby value")
            self.assertEqual(row.get("soulKey"), soul_key, f"{key}: the menu's soul key")
            self.assertEqual(row.get("merit"), unquote(merit), f"{key}: the menu's merit")
            self.assertTrue(row.get("portrait", "").startswith("zm_character_"), f"{key}: the menu's picture")

    def test_soul_keys_match_home_maps(self):
        # Each special needs its own map's soul key. Willard needs the key of
        # The Beast from Beyond, where he is earned, and that map's merit; the
        # stock lobby (ui/frontend/cp/cpprivatematchmenu.lua) asks for both.
        keys = soul_keys()
        for key, (_, home, _slot, _select, soul_key, merit, *_rest) in self.specials.items():
            if key == "willard":
                self.assertEqual((soul_key, unquote(merit)), (keys["cp_final"], "mt_dlc4_troll2"))
            else:
                self.assertEqual(soul_key, keys[home], f"{key} unlock")
                self.assertIsNone(unquote(merit), f"{key} needs no merit")

    def test_picture_pack_specials_match_the_cast(self):
        # The lobby card and the CHARACTER menu show a special character's own
        # card from the pack: the setup copies it from slot 5 of their home map,
        # where character.gsc has them, and Willard Wyler's from slot 6
        # (patch_cp_zmb, named after the last map). test_installer.py checks
        # the card names themselves.
        plan = PLAN_MAP.findall(PICTURES_CORE.read_text())
        self.assertEqual({row[0] for row in plan}, set(MAPS))
        specials = [special for _map, _main, _team, special in plan if special]
        self.assertEqual(sorted(specials), ["elvira", "hoff", "kevin", "pam"])
        for map_name, _main, _team, special in plan:
            if special:
                self.assertEqual((self.specials[special][1], int(self.specials[special][2])), (map_name, 5), special)
        willard = dict((kind, source) for source, kind in PLAN_WILLARD.findall(PICTURES_CORE.read_text()))
        self.assertEqual(willard, {"card": "zm_main_plyr_6_dlc4", "icon": "zm_team_plyr_6_dlc4"})
        self.assertEqual((self.specials["willard"][1], int(self.specials["willard"][2])), ("cp_zmb", 6))

if __name__ == "__main__":
    unittest.main()
