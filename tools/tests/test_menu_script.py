"""Runs the mod's menu script (ui_scripts/InfiniteExpansion/__init__.lua) in plain
Lua 5.1 with stand-ins for IW7's Lua UI (tools/tests/menu_harness.lua).

The CHARACTER button lives in the lobby that Solo Match and Custom Game open.
The stand-ins for that lobby follow the game's own ui/frontend/cp scripts
(IW_API_NOTES.md section 16): its button list, its two boss battle layouts, and
its reset of the lobby field characterSelect. The game may register those
types before or after the mod's script runs, and build them by name or through
MenuBuilder.m_types; the button must appear once in every case.

Run: python3 -m unittest discover -s tools/tests -v
"""
import itertools
import shutil
import subprocess
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MENU_LUA = REPO / "mods" / "infinite_expansion" / "ui_scripts" / "InfiniteExpansion" / "__init__.lua"
HARNESS = Path(__file__).resolve().parent / "menu_harness.lua"
LUA = shutil.which("lua5.1")

# The stock list with CHARACTER under SELECT SHOW (ChooseMap) and everything
# below it one 40-pixel step lower: (top, bottom) per element.
LOBBY_BOSS_OFF = {
    "StartMatch": (0, 30), "Loadout": (40, 70), "Barracks": (80, 110), "ChooseMap": (120, 150),
    "IXCharacterButton": (160, 190), "Tips": (200, 230), "Armory": (240, 270), "ForSpacing": (280, 285),
    "ButtonDescription": (350, 415), "ContractsButton": (280, 340),
}
LOBBY_BOSS_ON = {
    "StartMatch": (0, 30), "Loadout": (40, 70), "Barracks": (80, 110), "ChooseMap": (120, 150),
    "IXCharacterButton": (160, 190), "BossBattle": (200, 230), "Tips": (240, 270), "Armory": (280, 310),
    "ForSpacing": (280, 285), "ButtonDescription": (390, 455), "ContractsButton": (320, 380),
}


@unittest.skipUnless(LUA, "lua5.1 not found (Debian/Ubuntu package lua5.1)")
class MenuScript(unittest.TestCase):
    def run_harness(self, scenario, *options):
        result = subprocess.run([LUA, str(HARNESS), str(MENU_LUA), scenario, *options], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.splitlines()

    def lobby(self, *options):
        """{prefix: {"buttons": n, "order": [...], "rect": {id: (top, bottom)}}, "field": [...], "requests": str}"""
        report = {"field": []}
        for line in self.run_harness("lobby", *options):
            words = line.split(" ")
            if words[0] == "field":
                report["field"].append(int(words[1]))
            elif words[0] == "requests":
                report["requests"] = " ".join(words[1:])
            else:
                section = report.setdefault(words[0], {"rect": {}})
                if words[1] == "buttons":
                    section["buttons"] = int(words[2])
                elif words[1] == "order":
                    section["order"] = words[2].split(",")
                elif words[1] == "rect":
                    section["rect"][words[2]] = (float(words[4]), float(words[6]))
        return report

    def test_lobby_button_under_select_show_in_every_load_order(self):
        for order, build, boss in itertools.product(("registered", "lazy", "assigned"), ("byname", "direct"), (False, True)):
            options = [f"order={order}", f"build={build}"] + (["boss=1"] if boss else [])
            with self.subTest(options=options):
                report = self.lobby(*options)
                expected = LOBBY_BOSS_ON if boss else LOBBY_BOSS_OFF
                # After the stock list switches layouts again, and when the
                # lobby is opened a second time, the layout is the same.
                for prefix in ("first", "relayout", "second"):
                    section = report[prefix]
                    self.assertEqual(section["buttons"], 1, f"{prefix}: {section}")
                    self.assertEqual(section["rect"], {key: (float(a), float(b)) for key, (a, b) in expected.items()}, prefix)
                    order_ = section["order"]
                    self.assertEqual(order_[order_.index("ChooseMap") + 1], "IXCharacterButton", prefix)
                self.assertEqual(report["requests"], "open IXCharacterMenu")

    def test_lobby_puts_back_an_available_special_after_the_stock_reset(self):
        cases = [
            (["character=hoff", "keys=soul_key_1"], 1),
            (["character=hoff"], 0),
            (["character=hoff", "specials=2"], 1),
            (["character=hoff", "keys=soul_key_1", "specials=0"], 0),
            (["character=willard", "keys=soul_key_5", "merits=mt_dlc4_troll2"], 5),
            (["character=willard", "keys=soul_key_5"], 0),
            (["character=elvira", "keys=soul_key_4"], 4),
            (["character=sally", "keys=soul_key_1"], 0),
            ([], 0),
        ]
        for options, field in cases:
            with self.subTest(options=options):
                # Both the first and the second time the lobby opens.
                self.assertEqual(self.lobby(*options)["field"], [field, field])

    def test_lobby_field_when_the_game_bypasses_the_registered_builders(self):
        # The stock scripts register their types; if the game assigned them and
        # built the lobby directly, the field comes back from the second visit.
        report = self.lobby("order=assigned", "build=direct", "character=hoff", "keys=soul_key_1")
        self.assertEqual(report["field"], [0, 1])

    def menu(self, *options):
        lines = self.run_harness("menu", *options)
        texts = {}
        rows = []
        clicks = []
        for line in lines:
            if line.startswith("text "):
                words = line.split(" ")
                texts[words[1]] = {pair.split("=")[0]: float(pair.split("=")[1]) for pair in words[2:]}
            elif line.startswith("row "):
                rows.append(line)
            elif line.startswith("click "):
                clicks.append(line)
        return lines, texts, rows, clicks

    def test_character_menu_text_is_as_tall_as_its_font(self):
        _, texts, _, _ = self.menu()
        for name, text in texts.items():
            self.assertEqual(text["height"], text["font"], name)
        self.assertGreater(texts["IXInfoTitle"]["font"], texts["IXInfoText"]["font"])

    def test_character_menu_pictures_and_locks(self):
        lines, _, rows, clicks = self.menu("character=elvira", "keys=soul_key_1,soul_key_4")
        self.assertIn("selected Selected: Elvira", lines)
        self.assertIn("shown ELVIRA", lines)
        expected_rows = [
            "row 0 label=Random title=RANDOM status= initials=?",
            "row 1 label=Sally title=SALLY status=Regular character initials=S",
            "row 2 label=Poindexter title=POINDEXTER status=Regular character initials=P",
            "row 3 label=Andre title=ANDRE status=Regular character initials=A",
            "row 4 label=A.J. title=A.J. status=Regular character initials=AJ",
            "row 5 label=The Hoff title=THE HOFF status=Special character image=material:zm_character_select_hoff size=360x360",
            "row 6 label=Willard Wyler (locked) title=WILLARD WYLER status=Locked: beat the final boss of The Beast from Beyond. image=material:zm_character_willard size=180x360",
            "row 7 label=Kevin Smith (locked) title=KEVIN SMITH status=Locked: earn the soul key on Rave in the Redwoods. image=material:zm_character_select_smith size=180x360",
            "row 8 label=Pam Grier (locked) title=PAM GRIER status=Locked: earn the soul key on Shaolin Shuffle. image=material:zm_character_select_pam size=180x360",
            "row 9 label=Elvira title=ELVIRA status=Special character image=material:zm_character_select_elvira size=180x360",
        ]
        self.assertEqual(rows, expected_rows)
        save = "exec=seta ix_character {key};setCoopPlayerData zombiePlayerLoadout characterSelect {field};uploadstats requests=leave"
        self.assertEqual(clicks[3], "click 3 " + save.format(key="andre", field=0))
        self.assertEqual(clicks[5], "click 5 " + save.format(key="hoff", field=1))
        self.assertEqual(clicks[9], "click 9 " + save.format(key="elvira", field=4))
        # A locked special is not saved and the menu stays open.
        for index in (6, 7, 8):
            self.assertEqual(clicks[index], f"click {index} exec= requests=")

    def test_character_menu_follows_the_specials_setting(self):
        _, _, rows, clicks = self.menu("specials=2")
        self.assertFalse([row for row in rows if "(locked)" in row])
        self.assertTrue(clicks[6].startswith("click 6 exec=seta ix_character willard;"))

        _, _, rows, clicks = self.menu("specials=0", "keys=soul_key_1")
        for index in range(5, 10):
            self.assertIn("status=Special characters are off (ix_character_specials 0).", rows[index])
            self.assertEqual(clicks[index], f"click {index} exec= requests=")

    def test_main_menu_has_no_character_button(self):
        self.assertIn("main buttons 0", self.run_harness("mainmenu"))

    def test_steam_name_replaces_only_the_default(self):
        self.assertEqual(self.run_harness("name_default"), ["name Rankzies1", "sets 1"])
        self.assertEqual(self.run_harness("name_custom"), ["name Custom", "sets 0"])
        self.assertEqual(self.run_harness("name_missing"), ["name Unknown Soldier", "sets 0"])


if __name__ == "__main__":
    unittest.main()
