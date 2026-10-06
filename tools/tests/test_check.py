"""Tests for tools/check.py against the fixture mods in tools/tests/fixtures/.

bad_mod breaks every rule once (each file's first comment says which);
good_mod follows every rule. Needs the toolchain from tools/setup_compilers.sh.

Run: python3 -m unittest discover -s tools/tests -v
"""
import re
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHECK = REPO / "tools" / "check.py"
FIXTURES = Path(__file__).resolve().parent / "fixtures"
TOOLCHAIN = REPO / ".toolchain"
HAVE_LUAC = shutil.which("luac5.1") is not None
HAVE_TOOLCHAIN = all((TOOLCHAIN / "bin" / name).is_file() for name in ("ixcc-release", "ixcc-develop", "gsc-tool-iw7-develop"))


def run_check(mod, *extra):
    result = subprocess.run(
        [sys.executable, str(CHECK), "--mod", str(FIXTURES / mod), *extra],
        capture_output=True,
        text=True,
    )
    return result.returncode, result.stdout


@unittest.skipUnless(HAVE_TOOLCHAIN, "run tools/setup_compilers.sh first")
class BadMod(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.code, cls.output = run_check("bad_mod")
        cls.errors = [line for line in cls.output.splitlines() if line.startswith("ERROR")]

    def assert_reported(self, *fragments):
        for line in self.output.splitlines():
            if all(fragment in line for fragment in fragments):
                return
        self.fail(f"no line contains {fragments}:\n{self.output}")

    def test_fails(self):
        self.assertEqual(self.code, 1)
        self.assertIn("RESULT: FAIL", self.output)

    def test_compile(self):
        self.assert_reported("[compile]", "broken.gsc", "v1.1.0 compiler")
        self.assert_reported("[compile]", "broken.gsc", "develop compiler")
        self.assert_reported("[compile]", "develop_only.gsc", "v1.1.0 compiler", "couldn't determine function call type")

    def test_parity(self):
        self.assert_reported("[parity]", "shared.gsc")
        self.assertIn("- OP_CallBuiltinMethod0 disablegrenadetouchdamage", self.output)
        self.assertIn("+ OP_CallBuiltinMethod0 disableinvulnerability", self.output)

    def test_natives(self):
        self.assert_reported("[natives]", "shared.gsc", "line has no implementation")
        self.assert_reported("[natives]", "compat.gsc", "_meth_85CB")

    def test_calls(self):
        self.assert_reported("[calls]", "custom_scripts/ix/core/shared::not_defined", "function not defined there")
        self.assert_reported("[calls]", "custom_scripts/ix/core/nowhere::run", "no such script")
        self.assert_reported("[calls]", "scripts/engine/utility::not_a_stock_function", "not defined in the stock script")
        self.assert_reported("[calls]", "scripts/engine/no_such_script::run", "no such stock script")
        self.assert_reported("[calls]", "scripts/cp/maps/cp_town/cp_town_damage::callback_townzombieplayerdamage", "loaded only on cp_town")
        self.assert_reported("[calls]", "scripts/mp/hud_util::createfontstring", "loaded on no zombies map")

    def test_layout(self):
        self.assert_reported("[layout]", "custom_scripts/cp/no_entry.gsc", "neither init() nor main()")
        self.assert_reported("[layout]", "custom_scripts/loose.gsc", "unsupported location")
        self.assert_reported("[layout]", "custom_scripts/mp/entry.gsc", "unsupported location")
        self.assert_reported("[layout]", "custom_scripts/ix/x.gsc", "unsupported location")
        self.assert_reported("[layout]", "zombies/z.gsc", "only the entry script defines init() or main()")
        self.assert_reported("WARNING", "orphan.gsc", "not reachable")

    def test_raw_ids(self):
        self.assert_reported("[raw ids]", "shared.gsc:8", "_meth_845E outside ix/core/compat.gsc")
        self.assert_reported("[raw ids]", "compat.gsc:5", "_meth_FFF0", "extension built-ins")
        self.assert_reported("[raw ids]", "compat.gsc:6", "_meth_85CE", "extension built-ins")

    def test_source(self):
        self.assert_reported("[source]", "include_user.gsc:1", "#include")
        self.assert_reported("[source]", "include_user.gsc:6", "dev blocks")
        self.assert_reported("[source]", "swallow.gsc:4", "ends in a backslash")

    def test_lua(self):
        self.assert_reported("[lua]", "ui_scripts/Invented/__init__.lua:11", "Engine.SetPlayerData")
        self.assert_reported("[lua]", "ui_scripts/Invented/__init__.lua:12", ":SetMagicColor()")
        self.assert_reported("[lua]", "ui_scripts/Invented/__init__.lua:13", "MakeMagicHappen()")
        self.assert_reported("[lua]", "ui_scripts/MainMenu", "iw7-mod has a ui_scripts folder with this name")
        self.assert_reported("[lua]", "ui_scripts/NoInit", "no __init__.lua")
        if HAVE_LUAC:
            self.assert_reported("[lua]", "ui_scripts/Broken/__init__.lua:3", "syntax")
        for line in self.errors:
            # comments, strings, real iw7-mod API names and local functions are fine
            self.assertNotIn("Fake", line)
            self.assertIsNone(re.search(r"\b(Exec|RequestAddMenu|helper|lower)\b", line), line)

    def test_no_false_positives(self):
        # Comments and strings, iw7-mod extensions (logprint is a stub in the
        # table but iw7-mod implements it) and valid stock calls are fine.
        for name in ("_meth_80A1", "va", "logprint", "tell", "fileexists", "waittill_any", "isreallyalive", "swallow.gsc:6"):
            for line in self.errors:
                self.assertIsNone(re.search(rf"\b{re.escape(name)}\b", line), line)
        self.assertEqual(len(self.errors), 30 if HAVE_LUAC else 29, "\n".join(self.errors))


@unittest.skipUnless(HAVE_TOOLCHAIN, "run tools/setup_compilers.sh first")
class GoodMod(unittest.TestCase):
    def test_passes_cleanly(self):
        code, output = run_check("good_mod")
        self.assertEqual(code, 0, output)
        self.assertIn("RESULT: PASS (0 errors, 0 warnings)", output)

    def test_budget_limit(self):
        code, output = run_check("good_mod", "--budget", "100")
        self.assertEqual(code, 1, output)
        self.assertIn("ERROR   [budget] zombies:", output)


if __name__ == "__main__":
    unittest.main()
