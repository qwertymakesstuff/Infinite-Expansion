"""Runs the mod's menu script (ui_scripts/InfiniteExpansion/__init__.lua) in plain
Lua 5.1 with stand-ins for IW7's Lua UI (tools/tests/menu_harness.lua).

iw7-mod loads ui_scripts from <game>/iw7-mod/ before its own scripts, and from a
Mods-menu folder after them, and its own MainMenu script replaces the zombies
menu's button list. The CHARACTER button must survive both orders, once.

Run: python3 -m unittest discover -s tools/tests -v
"""
import shutil
import subprocess
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MENU_LUA = REPO / "mods" / "infinite_expansion" / "ui_scripts" / "InfiniteExpansion" / "__init__.lua"
HARNESS = Path(__file__).resolve().parent / "menu_harness.lua"
LUA = shutil.which("lua5.1")


@unittest.skipUnless(LUA, "lua5.1 not found (Debian/Ubuntu package lua5.1)")
class MenuScript(unittest.TestCase):
    def run_harness(self, scenario):
        result = subprocess.run([LUA, str(HARNESS), str(MENU_LUA), scenario], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.splitlines()

    def test_character_button_survives_both_load_orders(self):
        for scenario in ("iw7mod_folder", "mods_menu"):
            lines = self.run_harness(scenario)
            self.assertEqual(len(lines), 3, lines)
            for line in lines:
                self.assertTrue(line.endswith("builtBy=iw7-mod buttons=1 text=CHARACTER"), f"{scenario}: {line}")

    def test_steam_name_replaces_only_the_default(self):
        self.assertEqual(self.run_harness("name_default"), ["name Rankzies1", "sets 1"])
        self.assertEqual(self.run_harness("name_custom"), ["name Custom", "sets 0"])
        self.assertEqual(self.run_harness("name_missing"), ["name Unknown Soldier", "sets 0"])


if __name__ == "__main__":
    unittest.main()
