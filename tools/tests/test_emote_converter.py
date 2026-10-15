"""The custom emote converter (installer/IXEmoteConvert.cs), run through
PowerShell 7 on made-up files (emote_fixtures.py; none of them game art):

  - its reader and writer give IW7 animations back byte for byte, short and
    long ones, and refuse ones whose data does not add up;
  - it learns header rules from sample animations, and refuses samples that
    disagree;
  - an FBX animation (ASCII, and binary with compressed arrays and user
    tangents) comes out as an animation whose every driven bone turns exactly
    as its bone in the FBX turns (in IW7's axes), whose hips move by the
    scaled amount, whose bones point the way the FBX's point at rest, and
    whose header is filled in as the game's samples show;
  - missing bones, long animations and curve interpolation;
  - it compiles under C# 5 (the .NET Framework compiler of Windows PowerShell
    5.1).

The expected values come from the fixtures' own construction (the bone
rotations the FBX was written from) and from a reader written in Python
from the same description of IW7's data (Greyhound's TranslateXAnim), not
from the converter.

Run: python3 -m unittest discover -s tools/tests -v
"""
import json
import math
import struct
import subprocess
import tempfile
import unittest
from pathlib import Path

import emote_fixtures as ef
from test_installer import CORE, EMOTES_CORE, PICTURES_CORE, PWSH

REPO = Path(__file__).resolve().parents[2]
CONVERTER = REPO / "installer" / "IXEmoteConvert.cs"

SCENARIO = r"""
param([string]$Setup, [string]$Pictures, [string]$Emotes, [string]$Dir, [string]$Out)
$ErrorActionPreference = 'Stop'
. $Setup
. $Pictures
. $Emotes
Import-IXEmoteConverter
$r = [ordered]@{}
function Bytes([string]$Name) { return [IO.File]::ReadAllBytes((Join-Path $Dir $Name)) }

$r.roundtrip = [ordered]@{}
foreach ($f in @(Get-ChildItem (Join-Path $Dir 'xab') -Filter *.xab | Sort-Object Name)) {
    $r.roundtrip[$f.BaseName] = [IXEmotes.Converter]::RoundTrip([IO.File]::ReadAllBytes($f.FullName), $f.BaseName)
}

function Learn([string[]]$Names) {
    $list = New-Object 'System.Collections.Generic.List[IXEmotes.XAnim]'
    foreach ($n in $Names) {
        $list.Add([IXEmotes.Converter]::ReadDecoded((Bytes ('xab\' + $n + '.xab')), $n))
    }
    return Invoke-IXEmoteConverter { [IXEmotes.XAnimRules]::Learn($list) }
}
$rules = Learn @('ix_test_short', 'ix_test_long_inline', 'ix_test_long_indices')
$r.rules = @($rules.LastFrameIsNumFrames, $rules.FrequencyPerNumFrames, $rules.NoneTranslatedCounted, $rules.Notes)
try {
    Learn @('ix_test_short', 'odd_frequency') | Out-Null
    $r.disagree = 'learned'
}
catch {
    $r.disagree = $_.Exception.Message
}

$rig = Bytes 'rig.xmb'
$template = Bytes 'xab\ix_test_short.xab'
$r.convert = [ordered]@{}
foreach ($case in @(Get-Content -Raw (Join-Path $Dir 'cases.json') | ConvertFrom-Json)) {
    $fbx = Bytes $case.fbx
    $loop = [bool]$case.loop
    try {
        $res = Invoke-IXEmoteConverter { [IXEmotes.Converter]::Convert($fbx, $rig, $template, $case.asset, $loop, $rules) }
        [IO.File]::WriteAllBytes((Join-Path $Dir ($case.name + '.out.xab')), $res.Xab)
        $r.convert[$case.name] = [ordered]@{ frames = $res.Frames; fps = $res.Framerate; seconds = $res.Seconds;
            mapped = @($res.Mapped); unused = @($res.Unused); missing = @($res.MissingInRig); report = $res.Report }
    }
    catch {
        $r.convert[$case.name] = [ordered]@{ error = $_.Exception.Message }
    }
}

$agree = 0.0
$r.compare = [IXEmotes.Converter]::CompareWithRig([IXEmotes.Converter]::ReadDecoded($template, 't'), [IXEmotes.Rig]::Read($rig, 'rig'), [ref]$agree)

# Curves: constant, linear, cubic with stored slopes, cubic with automatic ones.
$curves = [ordered]@{}
foreach ($kind in @(@('constant', 0x02), @('linear', 0x04), @('user', 0x408), @('auto', 0x108))) {
    $c = New-Object IXEmotes.FbxCurve
    $c.Times = [double[]]@(0, 1, 2)
    $c.Values = [double[]]@(0, 10, 0)
    $c.Flags = [int[]]@($kind[1], $kind[1], $kind[1])
    $c.RightSlope = [double[]]@(4, -6, 0)
    $c.NextLeftSlope = [double[]]@(8, 2, 0)
    $curves[$kind[0]] = @(@(-1, 0.25, 0.5, 1.5, 3) | ForEach-Object { $c.Evaluate($_) })
}
$r.curves = $curves
ConvertTo-Json -InputObject $r -Depth 6 | Set-Content -LiteralPath $Out
"""

SCENARIO_CSHARP5 = r"""
param([string]$Source, [string]$Work)
$ErrorActionPreference = 'Stop'
# installer\IXEmoteConvert.cs is written for the C# 5 compiler of .NET Framework 4
# (Windows PowerShell 5.1's Add-Type); PowerShell 7 compiles it here with C# 5 rules.
$dll = Join-Path $Work 'convert.dll'
Add-Type -TypeDefinition ([IO.File]::ReadAllText($Source)) -OutputAssembly $dll -OutputType Library -CompilerOptions '/langversion:5' -ReferencedAssemblies @('System.Collections', 'System.IO.Compression', 'System.Runtime.Extensions') -IgnoreWarnings -WarningAction SilentlyContinue
'compiled'
"""


def subtree(root):
    names = {root}
    grew = True
    while grew:
        grew = False
        for n, p, _ in ef.SOURCE_BONES:
            if p in names and n not in names:
                names.add(n)
                grew = True
    return names


ARM, CHEST, ALL = subtree("upper_arm_L"), subtree("chest"), subtree("hips")
_ROOT, BIND = ef.source_rig()


def turned(q, pos, rot, pivot):
    off = qsub(pos, pivot)
    r = ef.qrot(rot, off)
    return ef.qnorm(ef.qmul(rot, q)), tuple(pivot[i] + r[i] for i in range(3))


def qsub(a, b):
    return tuple(a[i] - b[i] for i in range(3))


def dance(frames):
    """A motion: the left arm rises 80 degrees sideways, the upper body twists
    and back, the whole body tips forward 10 degrees, and the hips drop 10 cm
    and sway 5 cm to the right."""
    def motion(name, f):
        t = f / (frames - 1)
        q, pos = BIND[name]
        if name in ARM:
            q, pos = turned(q, pos, ef.qaxis((0, 0, -1), 80 * t), BIND["upper_arm_L"][1])
        if name in CHEST:
            q, pos = turned(q, pos, ef.qaxis((0, 1, 0), 30 * math.sin(t * math.pi)), BIND["chest"][1])
        if name in ALL:
            q, pos = turned(q, pos, ef.qaxis((1, 0, 0), 10 * t), BIND["hips"][1])
            pos = (pos[0] + 5 * t, pos[1] - 10 * t, pos[2])
        return q, pos
    return motion


@unittest.skipUnless(PWSH, "PowerShell 7 not found: run tools/setup_compilers.sh")
class Converter(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        d = Path(cls.tmp.name)
        (d / "xab").mkdir()
        cls.samples = ef.sample_animations()
        for name, data in cls.samples.items():
            (d / "xab" / (name + ".xab")).write_bytes(data)
        short = cls.samples["ix_test_short"]
        bad_counts = bytearray(short)
        bad_counts[6 + 121] += 1
        (d / "xab" / "bad_counts.xab").write_bytes(bytes(bad_counts))
        (d / "xab" / "bad_padding.xab").write_bytes(ef.sample_animation("bad_padding", "short", pad_byte=True))
        (d / "xab" / "bad_truncated.xab").write_bytes(short[:-40])
        # A translated bone (1, j_mainroot) in the list of bones without one.
        (d / "xab" / "bad_untranslated.xab").write_bytes(ef.sample_animation("bad_untranslated", "short", untranslated=[0, 1, 4, 5, 6]))
        (d / "xab" / "odd_frequency.xab").write_bytes(ef.sample_animation("odd_frequency", "short", frequency=1.0))
        cls.rig, cls.names, cls.rows = ef.make_rig()
        (d / "rig.xmb").write_bytes(cls.rig)
        cls.truth = {}
        cases = []

        def case(name, frames, loop=False, motion=None, **options):
            data, truth, _bind = ef.make_fbx(motion or dance(frames), frames=frames, **options)
            (d / (name + ".fbx")).write_bytes(data)
            cls.truth[name] = truth
            cases.append({"name": name, "fbx": name + ".fbx", "asset": "ix_emote_" + name, "loop": loop})

        case("ascii", 31)
        case("binary", 31, loop=True, binary=True, user_tangents=True)
        case("rest", 5, motion=lambda n, f: None)
        case("missing", 5, drop=("thigh_L", "shin_L", "foot_L", "toe_L"))
        case("long", 301, motion=lambda n, f: None)
        (d / "cases.json").write_text(json.dumps(cases))
        out = d / "out.json"
        (d / "scenario.ps1").write_text(SCENARIO)
        result = subprocess.run([PWSH, "-NoProfile", "-NonInteractive", "-File", str(d / "scenario.ps1"),
                                 str(CORE), str(PICTURES_CORE), str(EMOTES_CORE), str(d), str(out)],
                                capture_output=True, text=True, timeout=900)
        assert result.returncode == 0, result.stdout + result.stderr
        cls.r = json.loads(out.read_text(encoding="utf-8-sig"))
        cls.dir = d

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def decoded(self, name):
        return ef.decode_xanim((self.dir / (name + ".out.xab")).read_bytes())

    def mapping(self, name):
        return dict(m.split("<-") for m in self.r["convert"][name]["mapped"])

    def test_game_animations_round_trip_byte_for_byte(self):
        rt = self.r["roundtrip"]
        for name in self.samples:
            self.assertIsNone(rt[name], name)
        self.assertIn("ends before its tracks do", rt["bad_counts"])
        self.assertIn("do not use all of its data", rt["bad_padding"])
        self.assertIn("dataByte", rt["bad_padding"])
        self.assertIn("ends early", rt["bad_truncated"])
        self.assertIn("the bones listed after its translations are not the bones without one (0 1 4 5 6). (boneCount 1 2 2 1 3 1 1 2 5 9, numframes 40)", rt["bad_untranslated"])
        # The bones without a translation follow the translations, in order.
        for name, data in self.samples.items():
            self.assertEqual(ef.decode_xanim(data).untranslated, [0, 3, 4, 5, 6], name)

    def test_rules_are_learned_from_the_samples(self):
        self.assertEqual(self.r["rules"][:3], [True, True, True])
        self.assertIn("frequency = framerate / numframes", self.r["rules"][3])
        self.assertIn("do not show how their frequency is set", self.r["disagree"])

    def test_every_driven_bone_turns_as_in_the_fbx(self):
        for name in ("ascii", "binary"):
            d = self.decoded(name)
            self.assertEqual(d.unread, {})
            mapping = self.mapping(name)
            self.assertEqual(len(mapping), 48)
            truth = self.truth[name]
            frames = d.numframes + 1
            self.assertEqual(frames, 31)
            w0, _ = ef.rig_world(d, self.names, self.rows, 0)
            worst = 0.0
            for f in range(frames):
                w, _ = ef.rig_world(d, self.names, self.rows, f)
                for iw, src in mapping.items():
                    b = self.names.index(iw)
                    turn_iw = ef.qmul(w[b], ef.qconj(w0[b]))
                    if "+" in src:
                        # Halfway between the two (j_spineupper).
                        a, c = src.split("+")
                        da = ef.qmul(truth[a][f][0], ef.qconj(truth[a][0][0]))
                        dc = ef.qmul(truth[c][f][0], ef.qconj(truth[c][0][0]))
                        self.assertLess(ef.qangle(turn_iw, ef.qmul(ef.qmul(ef.TURN, da), ef.qconj(ef.TURN))),
                                        ef.qangle(da, dc) / 2 + 0.1)
                        continue
                    d_src = ef.qmul(truth[src][f][0], ef.qconj(truth[src][0][0]))
                    expected = ef.qmul(ef.qmul(ef.TURN, d_src), ef.qconj(ef.TURN))
                    worst = max(worst, ef.qangle(turn_iw, expected))
            self.assertLess(worst, 0.05, name)

    def test_hips_move_by_the_scaled_amount(self):
        d = self.decoded("ascii")
        truth = self.truth["ascii"]
        b = self.names.index("j_mainroot")
        rest_z = self.rows[b][2][2]
        ground_iw = min(self.rows[i][2][2] for i, n in enumerate(self.names) if n in d.bones)
        ground_src = min(BIND[n][1][1] for n, _, _ in ef.SOURCE_BONES)
        scale = (rest_z - ground_iw) / (BIND["hips"][1][1] - ground_src)
        _, t0 = ef.rig_world(d, self.names, self.rows, 0)
        # It starts where the body model's hips are, sideways.
        self.assertAlmostEqual(t0[b][0], self.rows[b][2][0], places=2)
        self.assertAlmostEqual(t0[b][1], self.rows[b][2][1], places=2)
        for f in (10, 20, 30):
            _, t = ef.rig_world(d, self.names, self.rows, f)
            moved = ef.qrot(ef.TURN, qsub(truth["hips"][f][1], truth["hips"][0][1]))
            for k in range(3):
                self.assertAlmostEqual(t[b][k] - t0[b][k], moved[k] * scale, delta=0.01)

    def test_bones_point_as_in_the_fbx_at_rest(self):
        d = self.decoded("rest")
        w, t = ef.rig_world(d, self.names, self.rows, 0)
        pairs = [("j_shoulder_le", "j_elbow_le", "upper_arm_L", "forearm_L"), ("j_elbow_ri", "j_wrist_ri", "forearm_R", "hand_R"),
                 ("j_hip_le", "j_knee_le", "thigh_L", "shin_L"), ("j_knee_ri", "j_ankle_ri", "shin_R", "foot_R"),
                 ("j_index_le_1", "j_index_le_2", "f_index_01_L", "f_index_02_L"), ("j_neck", "j_head", "neck", "head")]
        for iw, iw_child, src, src_child in pairs:
            got = qsub(t[self.names.index(iw_child)], t[self.names.index(iw)])
            want = ef.qrot(ef.TURN, qsub(BIND[src_child][1], BIND[src][1]))
            cos = sum(a * b for a, b in zip(got, want)) / math.sqrt(sum(a * a for a in got) * sum(b * b for b in want))
            self.assertGreater(cos, math.cos(math.radians(0.5)), iw)

    def test_bones_without_a_source_keep_their_rest_pose(self):
        d = self.decoded("ascii")
        for name in ("tag_origin", "j_chest", "j_clavicle_le", "j_thumb_ri_1", "tag_weapon_right"):
            self.assertNotIn(name, d.bones)
        self.assertEqual(self.r["convert"]["ascii"]["missing"], [])

    def test_header(self):
        template = ef.decode_xanim(self.samples["ix_test_short"])
        for name, loop in (("ascii", 0), ("binary", 1)):
            d = self.decoded(name)
            self.assertEqual(d.name, "ix_emote_" + name)
            self.assertEqual((d.numframes, d.framerate, d.flags), (30, 30.0, loop))
            self.assertAlmostEqual(d.frequency, 1.0, places=6)
            self.assertEqual(d.counts, [0, 0, 48, 0, 0, 0, 1, 0, 47, 48])
            hips = d.bones.index("j_mainroot")
            self.assertEqual(d.untranslated, [b for b in range(48) if b != hips])
            self.assertEqual(d.asset_type, template.asset_type)
            data = (self.dir / (name + ".out.xab")).read_bytes()
            head = data[6:6 + 0x88]
            for offset in (48, 56, 64, 72, 80):
                self.assertEqual(struct.unpack_from("<Q", head, offset)[0], 0, offset)
            self.assertEqual(head[129], 0)
            r = self.r["convert"][name]
            self.assertEqual((r["frames"], r["fps"], r["seconds"]), (31, 30.0, 1.0))
            self.assertEqual(r["unused"], [])

    def test_missing_bones_are_named(self):
        error = self.r["convert"]["missing"]["error"]
        self.assertIn("lacks thigh_L, shin_L, foot_L", error)
        self.assertFalse((self.dir / "missing.out.xab").exists())

    def test_long_animation_fits_256_frames(self):
        r = self.r["convert"]["long"]
        self.assertEqual(r["frames"], 256)
        self.assertAlmostEqual(r["fps"], 255 / 10.0, places=6)
        self.assertAlmostEqual(r["seconds"], 10.0, places=6)
        self.assertIn("Longer than 256 frames", r["report"])
        self.assertEqual(self.decoded("long").numframes, 255)

    def test_curves(self):
        c = self.r["curves"]
        self.assertEqual(c["constant"], [0, 0, 0, 10, 0])
        self.assertEqual(c["linear"], [0, 2.5, 5, 5, 0])
        # Hermite with the stored slopes (value per second): key 0 to 1 with 4 and 8.
        u = 0.25
        h = lambda u, v0, v1, m0, m1: (2 * u ** 3 - 3 * u ** 2 + 1) * v0 + (u ** 3 - 2 * u ** 2 + u) * m0 + (-2 * u ** 3 + 3 * u ** 2) * v1 + (u ** 3 - u ** 2) * m1
        self.assertAlmostEqual(c["user"][1], h(u, 0, 10, 4, 8), places=9)
        self.assertAlmostEqual(c["user"][3], h(0.5, 10, 0, -6, 2), places=9)
        # Automatic: slopes through the neighbouring keys (5, 0, -5 here).
        self.assertAlmostEqual(c["auto"][2], h(0.5, 0, 10, 10, 0), places=9)
        self.assertEqual((c["user"][0], c["user"][4]), (0, 0))

    def test_rig_comparison_is_reported(self):
        self.assertRegex(self.r["compare"], r"^\d+ of \d+ bones point the same way, median length ratio ")

    def test_compiles_as_csharp_5(self):
        with tempfile.TemporaryDirectory() as tmp:
            script = Path(tmp) / "c5.ps1"
            script.write_text(SCENARIO_CSHARP5)
            result = subprocess.run([PWSH, "-NoProfile", "-NonInteractive", "-File", str(script), str(CONVERTER), tmp],
                                    capture_output=True, text=True, timeout=600)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("compiled", result.stdout)

    def test_no_system_core_types(self):
        # Windows PowerShell 5.1's Add-Type references mscorlib and System.dll;
        # HashSet, LINQ and friends live in System.Core there.
        text = CONVERTER.read_text()
        for name in ("HashSet", "System.Linq", ".Select(", ".Where(", ".ToList(", "$\"", "?."):
            self.assertNotIn(name, text, name)


if __name__ == "__main__":
    unittest.main()
