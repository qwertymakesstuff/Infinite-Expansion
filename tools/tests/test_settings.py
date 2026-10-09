"""Checks the mod's settings against the menu and the documentation.

Every setting is registered in GSC with config::add_bool/add_int/add_float/
add_enum (or features::add, which adds an on/off setting). The menu
(ix/ui/menu_tree.gsc) names settings by id and quietly skips an id that does
not exist, so a typo would hide a row; README.md lists every setting with its
default and range, and the init line in README.md and TESTING.md counts them.
The menu shows a row's help under the list, word-wrapped into a few short
lines, and drops what does not fit. This test reads the scripts as text and
holds all of that together.

Run: python3 -m unittest discover -s tools/tests -v
"""
import re
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SCRIPTS = REPO / "mods" / "infinite_expansion" / "custom_scripts"
MENU = SCRIPTS / "ix" / "ui" / "menu.gsc"
MENU_TREE = SCRIPTS / "ix" / "ui" / "menu_tree.gsc"
README = REPO / "README.md"
TESTING = REPO / "TESTING.md"

ADD = re.compile(r'config::add_(bool|int|float|enum)\(\s*"([a-z0-9_]+)",\s*("[^"]*"|-?[\d.]+),\s*(?:("[^"]*")|(-?[\d.]+),\s*(-?[\d.]+))?')
FEATURE = re.compile(r'features::add\(\s*"([a-z0-9_]+)",\s*"[^"]*",\s*"[^"]*",\s*"[^"]*",\s*([01])\s*\)')
MENU_SETTING = re.compile(r'add_setting\(\s*"([a-z0-9_]+)",\s*"([a-z0-9_]+)",\s*(\d+)\s*\)')
README_ROW = re.compile(r"^\| `([a-z0-9_]+)` \| ([^|]+) \| ([^|]+) \|", re.M)
# The label and help after each kind's own arguments.
DESCRIBED = re.compile(
    r'(?:config::add_bool\(\s*"([a-z0-9_]+)",\s*[01]'
    r'|config::add_(?:int|float)\(\s*"([a-z0-9_]+)",\s*-?[\d.]+,\s*-?[\d.]+,\s*-?[\d.]+'
    r'|config::add_enum\(\s*"([a-z0-9_]+)",\s*"[^"]*",\s*"[^"]*"'
    r'|features::add\(\s*"([a-z0-9_]+)",\s*"[^"]*")'
    r',\s*"([^"]*)",\s*"([^"]*)"')
MENU_ACTION = re.compile(r'add_action\(\s*"([a-z0-9_]+)",\s*"([^"]*)",\s*"([^"]*)",\s*[^,]+,\s*([01]),\s*([01])\s*\)')
MENU_INFO = re.compile(r'add_info\(\s*"([a-z0-9_]+)",\s*"([^"]*)",\s*"([^"]*)"')
GUEST_NOTE = " Only the host can change it."  # menu.gsc item_help(), for a player who may not change it
# The keys at the bottom of the menu: small text (fontscale 0.7, about 5 of
# the 640-wide screen's units a character) in the panel's 224 usable units.
FOOTER_FUNCTION = re.compile(r"^(footer_\w+_text)\([^)]*\)\s*\{(.*?)^\}", re.M | re.S)
FOOTER_WIDTH = 44
# HUD elements a player sees: a working IW7 zombies menu (Synergy, S8) keeps
# 28 of its own non-archived and puts the rest in the archived set; the menu
# stays below that, so the stock game's own elements still fit
# (KNOWN_LIMITATIONS.md L49).
HUD_NOT_ARCHIVED = 26
HUD_ALL = 28


def registered():
    """{id: (type, default, extra)} for every setting the scripts register."""
    settings = {}
    for path in sorted(SCRIPTS.rglob("*.gsc")):
        text = path.read_text()
        for kind, setting, default, options, low, high in ADD.findall(text):
            if path.name == "features.gsc":
                continue  # the generic call inside features::add
            extra = options.strip('"').split() if kind == "enum" else (low, high)
            settings[setting] = (kind, default.strip('"'), extra, path.name)
        for setting, default in FEATURE.findall(text):
            if path.name != "features.gsc":
                settings[setting] = ("bool", default, None, path.name)
    return settings


def helps():
    """{id: help} for every setting the scripts register."""
    found = {}
    for path in sorted(SCRIPTS.rglob("*.gsc")):
        if path.name == "features.gsc":
            continue
        for match in DESCRIBED.finditer(path.read_text()):
            setting = next(group for group in match.groups()[:4] if group)
            found[setting] = match.group(6)
    return found


def menu_number(name):
    """A layout number that menu.gsc returns from a function of its own."""
    match = re.search(name + r"\(\)\s*\{\s*return (\d+);", MENU.read_text())
    return int(match.group(1))


def wrap(text, width):
    """menu.gsc wrap() without its line limit: every line the text needs."""
    lines, line = [], ""
    for word in text.split():
        if line and len(line) + 1 + len(word) > width:
            lines.append(line)
            line = ""
        line = word if not line else line + " " + word
    if line:
        lines.append(line)
    return lines


def describe_range(kind, extra):
    """config.gsc describe_range(), as item_help() appends it."""
    if kind == "enum":
        return "one of: " + ", ".join(extra)
    low, high = extra
    return ("a whole number from " if kind == "int" else "a number from ") + low + " to " + high


class Settings(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.settings = registered()

    def test_found_them(self):
        self.assertGreaterEqual(len(self.settings), 17)
        for setting in ("god_mode", "damage_taken", "friendly_fire", "rocket_jump", "third_person",
                        "zombies_ignore", "player_ejection", "starting_points", "menu", "debug_log"):
            self.assertIn(setting, self.settings)

    def test_defaults_are_valid(self):
        for setting, (kind, default, extra, where) in self.settings.items():
            if kind == "enum":
                self.assertIn(default, extra, f"{setting} ({where})")
            elif kind == "bool":
                self.assertIn(default, ("0", "1"), f"{setting} ({where})")
            else:
                low, high = (float(value) for value in extra)
                self.assertLessEqual(low, float(default), setting)
                self.assertLessEqual(float(default), high, setting)

    def test_menu_rows_name_real_settings(self):
        rows = MENU_SETTING.findall(MENU_TREE.read_text())
        self.assertGreater(len(rows), 10)
        for page, setting, step in rows:
            self.assertIn(setting, self.settings, f"menu page {page}")
            self.assertGreater(int(step), 0)

    def test_every_setting_is_in_the_menu(self):
        in_menu = {setting for _page, setting, _step in MENU_SETTING.findall(MENU_TREE.read_text())}
        self.assertEqual(sorted(set(self.settings) - in_menu), [])

    def test_readme_lists_every_setting_with_its_default(self):
        rows = {setting: (default.strip(), values.strip()) for setting, default, values in README_ROW.findall(README.read_text())}
        for setting, (kind, default, extra, _where) in self.settings.items():
            self.assertIn(setting, rows, f"README.md has no row for {setting}")
            self.assertEqual(rows[setting][0], default, f"README.md default of {setting}")
            if kind == "enum":
                for word in extra:
                    self.assertIn(word, rows[setting][1], f"README.md values of {setting}")

    def test_menu_help_fits(self):
        # What a guest sees is the longest: the help, the range, the note.
        lines, width = menu_number("help_lines"), menu_number("help_width")
        self.assertIn("wrap( item_help( current_item() ), help_width(), help_lines() )", MENU.read_text())
        texts = {}
        help_of = helps()
        self.assertEqual(set(help_of), set(self.settings))
        tree = MENU_TREE.read_text()
        for _page, setting, _step in MENU_SETTING.findall(tree):
            kind, _default, extra, _where = self.settings[setting]
            text = help_of[setting]
            if kind != "bool":
                text += " (" + describe_range(kind, extra) + ")"
            texts[setting] = text + GUEST_NOTE
        for _page, label, help_text, _confirm, host_only in MENU_ACTION.findall(tree):
            texts[label] = help_text + (GUEST_NOTE if host_only == "1" else "")
        for _page, label, help_text in MENU_INFO.findall(tree):
            texts[label] = help_text
        self.assertGreater(len(texts), 20)
        for row, text in texts.items():
            needed = wrap(text, width)
            self.assertLessEqual(len(needed), lines, f"{row}: {needed}")

    def test_menu_footer_fits(self):
        found = dict(FOOTER_FUNCTION.findall(MENU.read_text()))
        self.assertEqual(sorted(found), ["footer_move_text", "footer_open_text"])
        lines = [text for body in found.values() for text in re.findall(r'return "([^"]*)";', body)]
        self.assertGreaterEqual(len(lines), 5)
        for line in lines:
            self.assertLessEqual(len(line), FOOTER_WIDTH, line)
        # Every way to open the menu has its own line; the last is the fallback.
        kind, _default, options, _where = self.settings["menu_open"]
        self.assertEqual(kind, "enum")
        cases = re.findall(r'case "([a-z_]+)":', found["footer_open_text"])
        self.assertEqual(cases, options[:-1])

    def test_menu_hud_fits_the_element_budget(self):
        text = MENU.read_text()
        body = re.search(r"^create_hud\(\)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
        single = re.findall(r"hud\.\w+ = menu_(?:shader|text)\(", body)
        per_row = re.findall(r"hud\.\w+\[row\] = menu_(?:shader|text)\(", body)
        footer = re.findall(r"hud\.footer\[line\] = menu_text\(", body)
        help_lines = re.findall(r"hud\.help\[line\] = menu_text\(", body)
        self.assertEqual((len(footer), len(help_lines)), (1, 1))
        total = len(single) + len(per_row) * menu_number("rows") + menu_number("footer_lines") + menu_number("help_lines")
        archived_from = int(re.search(r"if \( line >= (\d+) \)\s*hud\.help\[line\]\.archived = 1;", body).group(1))
        archived = menu_number("help_lines") - archived_from
        self.assertLessEqual(total, HUD_ALL)
        self.assertLessEqual(total - archived, HUD_NOT_ARCHIVED)
        # Every element the menu makes is in the list it hides and shows.
        listed = re.search(r"^hud_elements\(\)\s*\{(.*?)^\}", text, re.M | re.S).group(1)
        for name in re.findall(r"hud\.(\w+) = menu_(?:shader|text)\(", body):
            self.assertIn("hud." + name, listed)
        for name in ("labels", "values", "help", "footer"):
            self.assertIn("hud." + name, listed)

    def test_init_line_counts_them(self):
        for path in (README, TESTING):
            counts = re.findall(r"settings: (\d+) \(0 changed from the default\)", path.read_text())
            self.assertTrue(counts, path.name)
            for count in counts:
                self.assertEqual(int(count), len(self.settings), path.name)


if __name__ == "__main__":
    unittest.main()
