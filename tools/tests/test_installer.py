"""Tests for the Windows installer (installer/).

The installer's logic (installer/IXSetup.Core.ps1) runs here with PowerShell 7
on fake Steam libraries and game folders. The setup window itself needs Windows
(WPF), so its files are checked statically: PowerShell syntax and Windows
PowerShell 5.1 compatibility, plain-ASCII scripts, and a XAML file that is well
formed, loadable without code-behind, and consistent with the names and
resources the scripts use. Needs pwsh from tools/setup_compilers.sh (or on PATH).

Run: python3 -m unittest discover -s tools/tests -v
"""
import json
import re
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
INSTALLER = REPO / "installer"
CORE = INSTALLER / "IXSetup.Core.ps1"
GUI = INSTALLER / "IXSetup.ps1"
XAML = INSTALLER / "IXSetup.xaml"
LAUNCHER = REPO / "Infinite Expansion Setup.cmd"
PACKAGE = REPO / "mods" / "infinite_expansion"
LINT = Path(__file__).resolve().parent / "ps51_lint.ps1"

PWSH = shutil.which("pwsh") or (str(REPO / ".toolchain" / "pwsh" / "pwsh") if (REPO / ".toolchain" / "pwsh" / "pwsh").is_file() else None)

WPF = "{http://schemas.microsoft.com/winfx/2006/xaml/presentation}"
XAML_NS = "{http://schemas.microsoft.com/winfx/2006/xaml}"

# Routed events a XAML attribute could wire to code-behind, which XamlReader.Load rejects.
EVENT_ATTRIBUTES = {
    "Click", "Loaded", "Unloaded", "Initialized", "MouseDown", "MouseUp", "MouseMove", "MouseEnter", "MouseLeave",
    "MouseLeftButtonDown", "MouseLeftButtonUp", "MouseRightButtonDown", "PreviewMouseDown", "KeyDown", "KeyUp",
    "Checked", "Unchecked", "SelectionChanged", "TextChanged", "ContentRendered", "Closing", "Closed", "Activated",
    "GotFocus", "LostFocus", "SizeChanged", "RequestNavigate",
}

SCENARIO = r"""
param([string]$Core, [string]$Steam, [string]$Package, [string]$Out, [string]$Sentinel)
$ErrorActionPreference = 'Stop'
. $Core
$result = [ordered]@{}
$game = Find-IXGameDir -SteamRoots @($Steam)
$result.found = $game
$result.version = Get-IXPackageVersion $Package
$result.payload = @(Get-IXPayloadFiles $Package)
$result.before = Get-IXState $game $Package
$result.install = Install-IX $game $Package
$result.afterInstall = Get-IXState $game $Package
$result.record = Read-IXRecord $game

# An older version recorded a file this one no longer has, and the record also
# names files outside the mod's folders, which must never be touched.
$target = Get-IXTarget $game
$old = Join-IXPath $target @('custom_scripts', 'ix', 'old_module.gsc')
[IO.File]::WriteAllText($old, 'old')
$files = @($result.record.files) + @('custom_scripts/ix/old_module.gsc', '../outside.txt',
    'custom_scripts/../../outside2.txt', 'players2/config.cfg', $Sentinel, 'C:/Windows/win.ini')
Write-IXRecord $game '0.0.1' $files
$result.updateState = Get-IXState $game $Package
$result.reinstall = Install-IX $game $Package
$result.uninstall = Uninstall-IX $game $Package
$result.afterUninstall = Get-IXState $game $Package
$result.uninstallAgain = Uninstall-IX $game $Package
ConvertTo-Json -InputObject $result -Depth 6 | Set-Content -LiteralPath $Out
"""

SCENARIO_MANUAL = r"""
param([string]$Core, [string]$Steam, [string]$Package, [string]$Out, [string]$CopyTo)
$ErrorActionPreference = 'Stop'
. $Core
$result = [ordered]@{}
$game = Find-IXGameDir -SteamRoots @($Steam)
$result.found = $game
$result.libraries = @(Get-IXSteamLibraries @($Steam))
$result.state = Get-IXState $game $Package
$result.uninstall = Uninstall-IX $game $Package
$result.after = Get-IXState $game $Package
$result.registryRoots = @(Get-IXSteamRoots)
$result.registered = Register-IXUninstaller $game '1.0' (Split-Path -Parent $Package)
Copy-IXSetup (Split-Path -Parent (Split-Path -Parent $Package)) $CopyTo
$result.same = Test-IXSamePath ($CopyTo + '/') $CopyTo
$result.notFound = Find-IXGameDir -SteamRoots @()
ConvertTo-Json -InputObject $result -Depth 6 | Set-Content -LiteralPath $Out
"""


def run_pwsh(script_text, *args, workdir):
    script = Path(workdir) / "scenario.ps1"
    script.write_text(script_text)
    result = subprocess.run([PWSH, "-NoProfile", "-NonInteractive", "-File", str(script), *map(str, args)],
                            capture_output=True, text=True)
    if result.returncode != 0:
        raise AssertionError(f"pwsh failed ({result.returncode}):\n{result.stdout}\n{result.stderr}")
    return result


def payload_files():
    files = []
    for folder in ("custom_scripts", "ui_scripts"):
        files += [p.relative_to(PACKAGE).as_posix() for p in (PACKAGE / folder).rglob("*") if p.is_file()]
    return sorted(files)


def make_game(root, vdf_style="new"):
    """A Steam root and a second library holding the game, the iw7-mod client,
    another mod's script, iw7-mod's player data, and a Mods-menu copy."""
    steam = root / "Steam"
    library = root / "Library Two"
    game = library / "steamapps" / "common" / "Call of Duty Infinite Warfare"
    (steam / "steamapps").mkdir(parents=True)
    if vdf_style == "new":
        vdf = ('"libraryfolders"\n{\n\t"0"\n\t{\n\t\t"path"\t\t"%s"\n\t\t"label"\t\t""\n\t\t"contentid"\t\t"77"\n'
               '\t\t"apps"\n\t\t{\n\t\t\t"228980"\t\t"123"\n\t\t}\n\t}\n\t"1"\n\t{\n\t\t"path"\t\t"%s"\n'
               '\t\t"apps"\n\t\t{\n\t\t\t"292730"\t\t"456"\n\t\t}\n\t}\n}\n') % (steam, library)
    else:
        vdf = '"LibraryFolders"\n{\n\t"TimeNextStatsReport"\t\t"1700000000"\n\t"ContentStatsID"\t\t"-42"\n\t"1"\t\t"%s"\n}\n' % library
    (steam / "steamapps" / "libraryfolders.vdf").write_text(vdf)
    (library / "steamapps").mkdir(parents=True)
    (library / "steamapps" / "appmanifest_292730.acf").write_text(
        '"AppState"\n{\n\t"appid"\t\t"292730"\n\t"installdir"\t\t"Call of Duty Infinite Warfare"\n}\n')
    game.mkdir(parents=True)
    (game / "iw7_ship.exe").write_bytes(b"")
    (game / "iw7-mod.exe").write_bytes(b"")
    (game / "iw7-mod" / "custom_scripts" / "cp").mkdir(parents=True)
    (game / "iw7-mod" / "custom_scripts" / "cp" / "other_mod.gsc").write_text("init() {}\n")
    (game / "iw7-mod" / "players2").mkdir(parents=True)
    (game / "iw7-mod" / "players2" / "config.cfg").write_text("seta ix_character andre\n")
    (game / "outside.txt").write_text("keep")
    (game / "outside2.txt").write_text("keep")
    old_copy = game / "mods" / "infinite_expansion"
    shutil.copytree(PACKAGE, old_copy)
    (old_copy / "notes.txt").write_text("the player's own file")
    return steam, game


@unittest.skipUnless(PWSH, "PowerShell 7 not found: run tools/setup_compilers.sh")
class InstallUpdateUninstall(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        root = Path(cls.tmp.name)
        cls.steam, cls.game = make_game(root)
        out = root / "result.json"
        cls.sentinel = root / "sentinel.txt"
        cls.sentinel.write_text("keep")
        run_pwsh(SCENARIO, CORE, cls.steam, PACKAGE, out, cls.sentinel, workdir=root)
        cls.r = json.loads(out.read_text(encoding="utf-8-sig"))
        cls.payload = payload_files()
        cls.version = re.search(r'level\.ix\.version = "([^"]+)"',
                                (PACKAGE / "custom_scripts/ix/core/bootstrap.gsc").read_text()).group(1)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_finds_the_game_in_a_second_library(self):
        self.assertEqual(Path(self.r["found"]), self.game)

    def test_package(self):
        self.assertEqual(self.r["version"], self.version)
        self.assertEqual(self.r["payload"], self.payload)
        self.assertIn("custom_scripts/cp/ix_main.gsc", self.payload)
        self.assertIn("ui_scripts/InfiniteExpansion/__init__.lua", self.payload)

    def test_state_before(self):
        before = self.r["before"]
        self.assertTrue(before["GameFound"])
        self.assertTrue(before["ClientFound"])
        self.assertTrue(before["PackageFound"])
        self.assertFalse(before["Installed"])
        self.assertTrue(before["OldCopy"])
        self.assertEqual(before["PackageVersion"], self.version)

    def test_install(self):
        install = self.r["install"]
        self.assertEqual(install["Copied"], len(self.payload))
        self.assertEqual(install["StaleRemoved"], 0)
        record = self.r["record"]
        self.assertEqual(record["version"], self.version)
        self.assertEqual(record["files"], self.payload)
        after = self.r["afterInstall"]
        self.assertTrue(after["Installed"])
        self.assertTrue(after["HasRecord"])
        self.assertEqual(after["InstalledVersion"], self.version)

    def test_install_removes_only_the_old_copys_own_files(self):
        install = self.r["install"]
        self.assertEqual(install["OldCopyRemoved"], len(self.payload) + 1)  # + desc.txt
        self.assertEqual(install["OldCopyLeft"], 1)
        self.assertFalse(self.r["afterInstall"]["OldCopy"])
        old_copy = self.game / "mods" / "infinite_expansion"
        self.assertEqual([p.name for p in old_copy.rglob("*") if p.is_file()], ["notes.txt"])

    def test_update_removes_files_an_older_version_left(self):
        self.assertEqual(self.r["updateState"]["InstalledVersion"], self.version)
        self.assertEqual(self.r["reinstall"]["StaleRemoved"], 1)
        self.assertEqual(self.r["reinstall"]["Copied"], len(self.payload))

    def test_entries_outside_the_mod_folders_are_never_touched(self):
        for path in ("outside.txt", "outside2.txt", "iw7-mod/players2/config.cfg"):
            self.assertTrue((self.game / path).is_file(), path)
        self.assertTrue(self.sentinel.is_file())

    def test_uninstall(self):
        self.assertEqual(self.r["uninstall"]["Removed"], len(self.payload))
        target = self.game / "iw7-mod"
        for relative in self.payload:
            self.assertFalse((target / relative).exists(), relative)
        self.assertFalse((target / "infinite-expansion.json").exists())
        self.assertFalse((target / "ui_scripts").exists())
        self.assertFalse((target / "custom_scripts" / "ix").exists())
        self.assertTrue((target / "custom_scripts" / "cp" / "other_mod.gsc").is_file())
        self.assertTrue((target / "players2" / "config.cfg").is_file())
        self.assertFalse(self.r["afterUninstall"]["Installed"])
        self.assertEqual(self.r["uninstallAgain"]["Removed"], 0)


@unittest.skipUnless(PWSH, "PowerShell 7 not found: run tools/setup_compilers.sh")
class ManualInstallAndSetupCopy(unittest.TestCase):
    """An old-format libraryfolders.vdf, a copy made by hand (no record), and the setup copy."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        root = Path(cls.tmp.name)
        cls.steam, cls.game = make_game(root, vdf_style="old")
        shutil.copytree(PACKAGE / "custom_scripts", cls.game / "iw7-mod" / "custom_scripts", dirs_exist_ok=True)
        shutil.copytree(PACKAGE / "ui_scripts", cls.game / "iw7-mod" / "ui_scripts")
        cls.copy = root / "SetupCopy"
        out = root / "result.json"
        run_pwsh(SCENARIO_MANUAL, CORE, cls.steam, PACKAGE, out, cls.copy, workdir=root)
        cls.r = json.loads(out.read_text(encoding="utf-8-sig"))

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_old_vdf_format(self):
        self.assertEqual(Path(self.r["found"]), self.game)
        self.assertEqual(len(self.r["libraries"]), 2)

    def test_manual_copy_is_detected_and_uninstalled(self):
        self.assertTrue(self.r["state"]["Installed"])
        self.assertFalse(self.r["state"]["HasRecord"])
        self.assertEqual(self.r["uninstall"]["Removed"], len(payload_files()))
        self.assertFalse(self.r["after"]["Installed"])
        self.assertTrue((self.game / "iw7-mod" / "custom_scripts" / "cp" / "other_mod.gsc").is_file())

    def test_no_registry_or_appdata_outside_windows(self):
        self.assertEqual(self.r["registryRoots"], [])
        self.assertFalse(self.r["registered"])
        self.assertIsNone(self.r["notFound"])

    def test_setup_copy(self):
        self.assertTrue(self.r["same"])
        for relative in ("installer/IXSetup.ps1", "installer/IXSetup.Core.ps1", "installer/IXSetup.xaml",
                         "mods/infinite_expansion/custom_scripts/cp/ix_main.gsc"):
            self.assertTrue((self.copy / relative).is_file(), relative)


@unittest.skipUnless(PWSH, "PowerShell 7 not found: run tools/setup_compilers.sh")
class SetupScriptWithoutWindow(unittest.TestCase):
    """installer/IXSetup.ps1 -NoWindow: the setup script itself, minus WPF."""

    def run_setup(self, *args):
        return subprocess.run([PWSH, "-NoProfile", "-NonInteractive", "-File", str(GUI), "-NoWindow", *args],
                              capture_output=True, text=True)

    def test_install_and_uninstall(self):
        with tempfile.TemporaryDirectory() as tmp:
            _steam, game = make_game(Path(tmp))
            result = self.run_setup("-GameDir", str(game))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"Installed {len(payload_files())} files", result.stdout)
            self.assertTrue((game / "iw7-mod" / "custom_scripts" / "cp" / "ix_main.gsc").is_file())
            self.assertTrue((game / "iw7-mod" / "infinite-expansion.json").is_file())
            result = self.run_setup("-Uninstall", "-GameDir", str(game))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"Removed {len(payload_files())} files", result.stdout)
            self.assertFalse((game / "iw7-mod" / "custom_scripts" / "cp" / "ix_main.gsc").exists())
            self.assertTrue((game / "iw7-mod" / "custom_scripts" / "cp" / "other_mod.gsc").is_file())

    def test_wrong_folder_fails_cleanly(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = self.run_setup("-GameDir", tmp)
            self.assertEqual(result.returncode, 1)
            self.assertIn("Infinite Warfare was not found", result.stderr)
            self.assertEqual(list(Path(tmp).iterdir()), [])


def xaml_tree():
    return ET.parse(XAML).getroot()


def local(tag):
    return tag.split("}", 1)[1] if "}" in tag else tag


class SetupFiles(unittest.TestCase):
    def test_scripts_are_ascii(self):
        for path in (CORE, GUI, LINT, LAUNCHER):
            data = path.read_bytes()
            self.assertTrue(all(b < 128 for b in data), f"{path.name} has non-ASCII bytes")

    def test_launcher_uses_crlf(self):
        data = LAUNCHER.read_bytes()
        self.assertEqual(data.count(b"\n"), data.count(b"\r\n"), "cmd.exe needs CRLF line endings")
        self.assertIn(b"installer\\IXSetup.ps1", data)

    @unittest.skipUnless(PWSH, "PowerShell 7 not found: run tools/setup_compilers.sh")
    def test_powershell_51_compatible(self):
        result = subprocess.run([PWSH, "-NoProfile", "-NonInteractive", "-File", str(LINT), str(CORE), str(GUI)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "")

    def test_xaml_loads_without_code_behind(self):
        root = xaml_tree()
        self.assertEqual(root.tag, WPF + "Window")
        for element in root.iter():
            self.assertNotIn(XAML_NS + "Class", element.attrib, "XamlReader.Load rejects x:Class")
            for name in element.attrib:
                self.assertNotIn(local(name), EVENT_ATTRIBUTES, f"event handler attribute {name} on {local(element.tag)}")

    def test_named_controls_exist(self):
        names = {e.attrib[XAML_NS + "Name"] for e in xaml_tree().iter() if XAML_NS + "Name" in e.attrib}
        wanted = re.search(r"\$IXControlNames = @\(([^)]*)\)", GUI.read_text(), re.S)
        self.assertIsNotNone(wanted, "IXSetup.ps1 lists its controls in $IXControlNames")
        listed = re.findall(r"'(\w+)'", wanted.group(1))
        self.assertGreater(len(listed), 10)
        for name in listed:
            self.assertIn(name, names, f"{name} is not an x:Name in IXSetup.xaml")
        used = set(re.findall(r"\$ui\.(\w+)", GUI.read_text()))
        self.assertLessEqual(used, set(listed), "every $ui.<name> must be in $IXControlNames")

    def test_resources_and_storyboard_targets_exist(self):
        root = xaml_tree()
        text = XAML.read_text()
        keys = {e.attrib[XAML_NS + "Key"] for e in root.iter() if XAML_NS + "Key" in e.attrib}
        for key in re.findall(r"\{(?:StaticResource|DynamicResource) (\w+)\}", text):
            self.assertIn(key, keys, f"resource {key} is not defined")
        names = {e.attrib[XAML_NS + "Name"] for e in root.iter() if XAML_NS + "Name" in e.attrib}
        for element in root.iter():
            target = element.attrib.get("Storyboard.TargetName")
            if target:
                self.assertIn(target, names, f"Storyboard.TargetName {target}")
        # Setter TargetName in a ControlTemplate names an element of that template.
        for template in root.iter(WPF + "ControlTemplate"):
            inside = {e.attrib[XAML_NS + "Name"] for e in template.iter() if XAML_NS + "Name" in e.attrib}
            for setter in template.iter(WPF + "Setter"):
                if "TargetName" in setter.attrib:
                    self.assertIn(setter.attrib["TargetName"], inside)

    def test_only_known_wpf_types(self):
        # Catches a misspelled element type, which only fails when Windows loads the window.
        known = {
            "Window", "Style", "Setter", "ControlTemplate", "Trigger", "Border", "Grid", "RowDefinition",
            "ColumnDefinition", "Canvas", "StackPanel", "DockPanel", "TextBlock", "Run", "Button", "Ellipse",
            "Rectangle", "Path", "Image", "ContentPresenter", "LinearGradientBrush", "RadialGradientBrush",
            "GradientStop", "SolidColorBrush", "DrawingBrush", "DrawingImage", "DrawingGroup", "GeometryDrawing",
            "Pen", "DropShadowEffect", "TranslateTransform", "RotateTransform", "ScaleTransform", "SkewTransform",
            "TransformGroup", "Storyboard", "DoubleAnimation", "BeginStoryboard", "EventTrigger", "PowerEase",
            "SineEase", "BackEase", "CubicEase", "ResourceDictionary", "Viewbox", "ToolTip",
        }
        for element in xaml_tree().iter():
            name = local(element.tag)
            owner = name.split(".")[0]
            self.assertIn(owner, known, f"unexpected element <{name}>")
