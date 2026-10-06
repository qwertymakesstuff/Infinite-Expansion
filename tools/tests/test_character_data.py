"""Checks the cast table in ix/player/character.gsc against the stock scripts.

The special characters' models, slots, lobby ids and unlock stats are copied
from the decompiled stock scripts; this test re-reads those scripts so a typo
cannot ship. Needs the stock dump from tools/setup_compilers.sh.

Run: python3 -m unittest discover -s tools/tests -v
"""
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHARACTER_GSC = REPO / "mods" / "infinite_expansion" / "custom_scripts" / "ix" / "player" / "character.gsc"
DUMP = REPO / ".toolchain" / "src" / "iw7-gsc-dump" / "decompiled" / "scripts"
MAPS = ("cp_zmb", "cp_rave", "cp_disco", "cp_town", "cp_final")

REGISTER = re.compile(r'register_player_character\(\s*(\d+),\s*"(yes|no)",\s*("[^"]*"|undefined|var_\d+),\s*("[^"]*"|undefined),\s*("[^"]*"|undefined),\s*("[^"]*"|undefined),\s*"(p\d_)",\s*"[^"]*",\s*[^,]+,\s*[^,]+,\s*(\d+)')
MAKE_SPECIAL = re.compile(r'make_special\(\s*"(\w+)",\s*"[^"]+",\s*\[[^\]]*\],\s*"(\w+)",\s*(\d+),\s*(\d+),\s*"(\w+)",\s*"(\w+)",\s*"([^"]+)",\s*"([^"]+)",\s*("[^"]+"|undefined),\s*(\d+)\s*\)')


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
        for key, (_, home, slot, _select, _type, _field, body, view, head, photo) in self.specials.items():
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

    def test_soul_keys_match_home_maps(self):
        keys = soul_keys()
        for key, (_, home, _slot, _select, unlock_type, unlock_field, *_rest) in self.specials.items():
            if unlock_type == "soul_key":
                self.assertEqual(keys[home], unlock_field, f"{key} unlock")
            else:
                self.assertEqual((key, unlock_type, unlock_field), ("willard", "merit", "mt_dlc4_troll2"))


if __name__ == "__main__":
    unittest.main()
