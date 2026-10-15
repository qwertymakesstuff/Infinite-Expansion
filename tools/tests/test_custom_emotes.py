"""Checks the custom emotes (emote_custom.gsc, the menu script's list loader and
the proof build of installer/IXEmotes.Core.ps1) against each other and against
the decompiled stock scripts.

A custom emote hides and holds the player and plays an animation on a copy of
their character (IW_API_NOTES.md section 24). This test holds the script to:
  - precaching while the level loads (register() runs synchronously, before
    any wait), as the stock maps precache their character animations;
  - putting back everything start() changes, in stop();
  - the same limits as the menu script (ids, names, how many);
  - names and help that fit the menu;
  - built-ins the stock scripts use the same way, and a proof animation that
    the stock scripts precache and play on a character model.

Run: python3 -m unittest discover -s tools/tests -v
"""
import re
import unittest
from pathlib import Path

import test_emotes

REPO = Path(__file__).resolve().parents[2]
SCRIPTS = REPO / "mods" / "infinite_expansion" / "custom_scripts"
CUSTOM = SCRIPTS / "ix" / "fun" / "emote_custom.gsc"
EMOTES = SCRIPTS / "ix" / "fun" / "emotes.gsc"
MENU_LUA = REPO / "mods" / "infinite_expansion" / "ui_scripts" / "InfiniteExpansion" / "__init__.lua"
EMOTES_CORE = REPO / "installer" / "IXEmotes.Core.ps1"
DUMP = REPO / ".toolchain" / "src" / "iw7-gsc-dump" / "decompiled" / "scripts"


def function(text, name):
    found = re.search(r"^" + name + r"\([^)]*\)\s*\{(.*?)^\}", text, re.M | re.S)
    assert found, name
    # Without comments, which may mention what the code must not do.
    return re.sub(r"//[^\n]*", "", found.group(1))


class CustomEmotes(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.custom = CUSTOM.read_text()
        cls.emotes = EMOTES.read_text()
        cls.lua = MENU_LUA.read_text()

    def test_precached_while_the_level_loads(self):
        register = function(self.custom, "register")
        self.assertIn("precachempanim( emote.asset );", register)
        self.assertNotIn("wait", register)
        self.assertNotIn("thread", register)
        # emotes.gsc register() calls it directly, and bootstrap calls that directly.
        self.assertIn("    custom_scripts\\ix\\fun\\emote_custom::register();", function(self.emotes, "register"))

    def test_start_never_waits_and_stop_undoes_it(self):
        start, stop = function(self.custom, "start"), function(self.custom, "stop")
        hold, release = function(self.custom, "hold"), function(self.custom, "release")
        self.assertIn("self hold();", start)
        self.assertIn("self release();", stop)
        self.assertIn("playerlinktodelta", hold)
        self.assertIn("unlink()", release)
        self.assertIn("delete()", release)
        self.assertIn("level thread clean_up_if_gone( self, anchor, undefined );", hold)
        self.assertNotIn("wait", start)
        for flag in re.findall(r"allow_(\w+)\( 0 \)", start):
            self.assertIn(f"allow_{flag}( 1 )", stop, flag)
        self.assertEqual(len(re.findall(r"allow_\w+\( 0 \)", start)), 4)
        self.assertIn("playerhide()", start)
        self.assertIn("playershow()", stop)
        # The anchor and the stand-in: deleted on the way out, or by the level
        # when the player leaves.
        self.assertEqual(start.count('spawn( "script_model"'), 1)
        self.assertEqual(hold.count('spawn( "script_model"'), 1)
        self.assertEqual(stop.count("delete()"), 1)
        self.assertEqual(function(self.custom, "clean_up_if_gone").count("delete()"), 2)
        self.assertIn("level thread clean_up_if_gone( self, undefined, standin );", start)
        # emotes.gsc puts it back on every way out (restore), and ends it with the match.
        self.assertIn("emote_custom::stop();", function(self.emotes, "restore"))
        self.assertIn("emote_custom::end_on_game_end();", function(self.emotes, "run"))
        self.assertIn('"damage", "death", "last_stand"', function(self.emotes, "end_on_trouble"))

    def test_copies_the_character_as_the_stock_scripts_do(self):
        start = function(self.custom, "start")
        for call in ("setmodel( self.model )", "getattachsize()", "getattachmodelname( i )",
                     'attach( model, "", 1 )', "scriptmodelplayanim( emote.asset, 1 )"):
            self.assertIn(call, start)
        # The tag the game reports is not used: with it the head did not follow
        # the animated body (second in-game report).
        self.assertNotIn("getattachtagname", start)
        character = (DUMP / "code" / "character.gsc").read_text()
        for call in ("self.model", "getattachsize()", "getattachmodelname("):
            self.assertIn(call, character)
        # How the game dresses a player and an agent: every part with no tag.
        loadout = (DUMP / "cp" / "zombies" / "zombies_loadout.gsc").read_text()
        self.assertIn('self attach( var_1, "", 1 );', function(loadout, "setcharactermodels"))
        # The head also by the stock field setcharactermodels fills.
        self.assertIn("self.headmodel = var_1;", function(loadout, "setcharactermodels"))
        self.assertIn('standin attach( self.headmodel, "", 1 );', start)
        agents = (DUMP / "cp" / "cp_agent_utils.gsc").read_text()
        self.assertIn('var_0 attach( var_4, "", 1 );', function(agents, "set_agent_model"))

    def test_built_ins_are_used_as_the_stock_scripts_use_them(self):
        uses = {
            "playerhide": DUMP / "cp" / "zombies" / "zombie_fast_travel.gsc",
            "playershow": DUMP / "cp" / "zombies" / "zombie_fast_travel.gsc",
            "precachempanim": DUMP / "cp" / "maps" / "cp_zmb" / "cp_zmb.gsc",
            "scriptmodelplayanim": DUMP / "cp" / "maps" / "cp_rave" / "cp_rave_boat.gsc",
        }
        for name, path in uses.items():
            self.assertIn(name + "(", path.read_text(), name)
        self.assertIn('scriptmodelplayanim( "IW7_cp_survivor_boat_idle", 1 )', uses["scriptmodelplayanim"].read_text())

    def test_limits_match_the_menu_script(self):
        parse = function(self.custom, "parse")
        self.assertIn("id.size > 6", parse)
        self.assertIn("asset.size > 48", parse)
        self.assertIn("words( fields[4], 16 )", parse)
        self.assertIn("words( fields[5], 14 )", parse)
        self.assertIn("words( fields[6], 27 )", parse)
        self.assertIn("return 20;", function(self.custom, "max_count"))
        self.assertIn("local maxEmotes = 20", self.lua)
        self.assertIn("string.len(id) > 6 or string.len(asset) > 48", self.lua)
        for field, longest in (("category", 16), ("wheel", 14), ("name", 27)):
            self.assertIn(f"{field} = emoteText({field}, {longest})", self.lua)
        # The menu script writes spaces as "_"; the script reads them back.
        self.assertIn('string.gsub(text, " ", "_")', self.lua)
        self.assertIn('if ( c == "_" )', function(self.custom, "words"))

    def test_names_and_help_fit_the_menu(self):
        width = test_emotes.menu_number("help_width")
        help_px = test_emotes.menu_number("menu_width") - test_emotes.MARGINS
        cell = test_emotes.menu_number("wheel_cell")
        scale = test_emotes.menu_number("wheel_scale", float)
        wheel_chars = int(cell * width / help_px * test_emotes.HELP_SCALE / scale)
        self.assertLessEqual(14, wheel_chars)
        self.assertLessEqual(len("7. ") + 27, test_emotes.ROW_CHARS)
        help_text = re.search(r'"custom", asset, "([^"]*)" \);', self.custom).group(1)
        notes = re.findall(r'return emote\.help \+ "([^"]*)";', self.emotes)
        lines = test_emotes.menu_number("help_lines")
        for note in notes:
            self.assertLessEqual(len(test_emotes.wrap(help_text + note, width)), lines, note)
        for problem in re.findall(r'return "([^"]+)";', function(self.custom, "cannot_play")):
            self.assertLessEqual(len(problem), 64, problem)

    def test_proof_names_pass_the_list_rules(self):
        core = EMOTES_CORE.read_text()
        proof = dict(re.findall(r"^\s+(\w+)\s+= '([^']*)'", re.search(r"\$IXEmoteProof = \[pscustomobject\]@\{(.*?)\}", core, re.S).group(1), re.M))
        self.assertRegex(proof["Id"], r"^u[a-z0-9]{1,5}$")
        self.assertRegex(proof["Asset"], r"^ix_emote_[a-z0-9_]+$")
        for field, longest in (("Wheel", 14), ("Name", 27)):
            self.assertRegex(proof[field], r"^[A-Za-z0-9 .\-]+$")
            self.assertLessEqual(len(proof[field]), longest)

    def test_proof_animation_is_one_the_game_plays_on_a_character(self):
        core = EMOTES_CORE.read_text()
        source = re.search(r"Source = '([^']+)'", core).group(1)
        zmb = (DUMP / "cp" / "maps" / "cp_zmb" / "cp_zmb.gsc").read_text().lower()
        self.assertIn(f'precachempanim( "{source}" );', zmb)
        dj = (DUMP / "cp" / "maps" / "cp_zmb" / "cp_zmb_dj.gsc").read_text()
        idle = function(dj, "dj_idle")
        self.assertIn("%" + source, idle)
        self.assertIn("scriptmodelplayanimdeltamotionfrompos( var_2,", idle)
        self.assertIn('level.dj setmodel( "fullbody_zmb_hero_dj" );', dj)


    def test_play_waits_for_landing(self):
        # From the menu the player was linked until the same frame; the game
        # counts them on the ground only after it has moved them again
        # ("Land first" in the first in-game report).
        play = function(self.emotes, "play")
        loop = play.index("!self isonground()")
        self.assertLess(play.index("waittillframeend;"), loop)
        self.assertLess(loop, play.index("problem = self cannot_emote();"))
        self.assertIn("waited < 1", play)
        self.assertIn('self endon( "ix_emote_end" );', play)

    def test_wheel_command_toggles_the_menu(self):
        self.assertIn('chat::add_command( "wheel", ::wheel_command,', function(self.emotes, "register"))
        self.assertIn('menu::toggle_at_page( "emote_wheel" );', function(self.emotes, "wheel_command"))
        menu = (SCRIPTS / "ix" / "ui" / "menu.gsc").read_text()
        toggle = function(menu, "toggle_at_page")
        self.assertLess(toggle.index("close_menu();"), toggle.index("chat_open( undefined );"))
        self.assertIn("open_page( id );", toggle)
        tree = (SCRIPTS / "ix" / "ui" / "menu_tree.gsc").read_text()
        self.assertIn('add_page( "emote_wheel", "Emote wheel", "emotes" )', tree)


# The bones of the game's own body animation the proof copies
# (iw7_cp_zom_hoff_dj_desk_01), as Build Custom Emotes listed them on the
# owner's PC (0.14.x log). Bone names only; no animation data.
HOFF_BONES = """tag_sync j_spine4 j_chest j_helmet j_mainroot tag_ik_foot_loc_ri tag_ik_foot_loc_le j_hip_le j_hip_ri
j_spinelower j_knee_le j_knee_ri j_spineupper j_ankle_le j_ball_le j_ankle_ri j_ball_ri j_clavicle_le j_clavicle_ri j_neck
tag_inhand j_shoulder_le j_shoulder_ri j_head j_elbow_le j_wrist_le j_shield_le tag_accessory_left tag_weapon_left
j_metapinky_le_1 j_thumb_le_1 j_metaindex_le_1 j_metamid_le_1 j_metaring_le_1 j_pinky_le_1 j_ring_le_1 j_thumb_le_2
j_index_le_1 j_mid_le_1 j_index_le_2 j_index_le_3 j_mid_le_2 j_mid_le_3 j_pinky_le_2 j_pinky_le_3 j_ring_le_2 j_ring_le_3
j_thumb_le_3 j_gun tag_weapon_right j_elbow_ri j_shield_ri j_wrist_ri j_metaindex_ri_1 j_metapinky_ri_1 j_metaring_ri_1
j_thumb_ri_1 tag_accessory_right j_index_ri_1 j_mid_ri_1 j_pinky_ri_1 j_ring_ri_1 j_thumb_ri_2 j_index_ri_2 j_index_ri_3
j_mid_ri_2 j_mid_ri_3 j_pinky_ri_2 j_pinky_ri_3 j_ring_ri_2 j_ring_ri_3 j_thumb_ri_3 j_metamid_ri_1""".split()
CONVERTER = REPO / "installer" / "IXEmoteConvert.cs"


class YourAnimations(unittest.TestCase):
    """Step 2: the converter's bone map, the rig it reads and the list of your
    animations, against the stock scripts, the game's bone names and the menu
    script."""

    @classmethod
    def setUpClass(cls):
        cls.core = EMOTES_CORE.read_text()
        cls.converter = CONVERTER.read_text()

    def bone_map(self):
        """The IW7 bones Humanoid() names, its "<prefix>" + i + "<suffix>"
        written out for both sides ("le", "ri")."""
        body = re.search(r"public static List<BoneLink> Humanoid\(\)(.*?)\n        \}\n", self.converter, re.S).group(1)
        iw = set()
        for side in ("le", "ri"):
            for prefix, plus, suffix in re.findall(r'"(j_[a-z0-9_]*)"(\s*\+\s*i(?:\s*\+\s*"([a-z0-9_]*)")?)?', body):
                iw.add(prefix + (side + suffix if plus else ""))
            for finger in ("index", "mid", "ring", "pinky"):
                for n in (1, 2, 3):
                    iw.add("j_%s_%s_%d" % (finger, side, n))
        # fi + "1": the finger prefix built above, not a bone itself.
        return {b for b in iw if not b.endswith("_")}

    def test_every_driven_bone_is_one_the_game_animates(self):
        bones = self.bone_map()
        self.assertGreaterEqual(len(bones), 40)
        self.assertEqual(sorted(b for b in bones if b not in HOFF_BONES), [])
        self.assertEqual(len(HOFF_BONES), 73)

    def test_rig_models_come_from_the_stock_scripts(self):
        models = re.findall(r"'([a-z_]+)'", re.search(r"\$IXEmoteRigModels = @\(([^)]*)\)", self.core).group(1))
        setup = (DUMP / "cp" / "maps" / "cp_zmb" / "cp_zmb_player_character_setup.gsc").read_text()
        bodies = re.findall(r'register_player_character\( \d+, "\w+", "(\w+)"', setup)
        self.assertTrue(set(models[:4]) <= set(bodies))
        dj = (DUMP / "cp" / "maps" / "cp_zmb" / "cp_zmb_dj.gsc").read_text()
        self.assertEqual(models[4], "fullbody_zmb_hero_dj")
        self.assertIn('level.dj setmodel( "%s" );' % models[4], dj)

    def test_list_limits_match_the_menu_script(self):
        self.assertIn("$IXEmoteMax = 20", self.core)
        self.assertIn("return 20;", function(CUSTOM.read_text(), "max_count"))
        self.assertIn("@('wheel name', $fields[2], 14), @('menu name', $fields[3], 27)", self.core)
        self.assertIn("'^[A-Za-z0-9 .\\-]+$'", self.core)
        # The loop is asked for every emote: no default.
        self.assertIn("there is no default", self.core)

    def test_asset_names_pass_the_list_rules(self):
        # ix_emote_ + at most 34 + _NN: within the 48 the menu script allows.
        self.assertIn("$base.Length -gt 34", self.core)
        self.assertLessEqual(len("ix_emote_") + 34 + len("_20"), 48)


if __name__ == "__main__":
    unittest.main()
