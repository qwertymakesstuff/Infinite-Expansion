HEADER = ("cp_disco", "Shaolin Shuffle", "The Rat King's relics", "Solo or co-op. Pam Grier has work for you from round 5 on.")

COMMENT = [
    "// Infinite Expansion - Guided Mode guide: Shaolin Shuffle (cp_disco).",
    "//",
    "// The main quest is the game's \"skq\" (disco_mpq.gsc in",
    "// scripts/cp/maps/cp_disco, flags skq_*), with Pam Grier's talks",
    "// (kung_fu_mode.gsc) and the final fight (rat_king_fight.gsc): Chi, then the",
    "// Rat King's Eye, Brain and Heart, each ending in a fight, then the lair.",
    "// Every signal and marker is the stock scripts' own (research:",
    "// tools/guided/research/cp_disco.md, TESTING.md V150). Steps without a signal",
    "// (a style chosen, Chi level 1, the rooftop cipher) follow from the next step",
    "// the game reports. A wrong flyer makes the game start the symbol hunt over",
    "// (puzzle_phone_reset): the guide goes back too. Markers only use names the",
    "// v1.1.0 compiler knows (KNOWN_LIMITATIONS.md C10): many of this map's own",
    "// fields (the next cage, the hunted symbol, the ringing phone) are not, so",
    "// those steps have text directions only. Nothing here changes the quest.",
]

STEPS = [
    {"use": "talk_pam_start", "detect": "flag:skq_phase_1", "marker": "ent:ma_trainer"},
    {"id": "chi_style", "objective": "Choose a Chi style and drink",
     "location": "Black Cat Dojo (style stations)",
     "minimal": "Pick an animal style, then drink its Chi juice once.",
     "standard": "Use one of the animal style stations (Tiger, Crane, Snake or Dragon), then press the gourd button (d-pad right) to enter Chi mode once.",
     "detailed": "Use a Tiger, Crane, Snake or Dragon station: it sets your style, starts its level-1 challenge and gives you the gourd. Any style works. Then press actionslot 4 (d-pad right) to drink and enter Chi mode once; Pam then has a new task.",
     "detect": "flag:first_kung_fu_mode", "marker": "sn_structs:martial_arts_animals"},
    {"use": "chi_level_1", "detect": "manual", "marker": "none"},
    {"use": "talk_pam_eye_quest", "detect": "flag:skq_p2t1_0", "marker": "ent:ma_trainer"},
    {"use": "free_templeton", "detect": "notify:cage_win", "marker": "none"},
    {"id": "ring_and_ninjas", "objective": "Clear the circle and the ninjas",
     "location": "At the last rat cage",
     "minimal": "Kill zombies in the glowing circle, then the ninjas.",
     "standard": "Kill 15 zombies inside the glowing circle at the last cage. Then kill the 8 ninjas that come and pick up the locker key.",
     "detailed": "Stand by the glowing circle at the last cage and kill 15 zombies near its center. About 10 seconds later 8 karate-master ninjas attack: kill them all (the wave also ends after 300 seconds). Then pick up the locker key glowing above the circle.",
     "detect": "flag:skq_p2t1_2", "marker": "none"},
    {"use": "open_locker", "detect": "flag:skq_p2t1_3", "marker": "ent:subway_locker_door"},
    {"use": "shoot_four_symbols", "detect": "notify:active_word_done", "marker": "structs:graffiti_check_struct"},
    {"use": "summon_rk_eye", "detect": "flag:skq_p2t1_4", "marker": "struct:rk_symbol_punk_streets"},
    {"id": "rat_king_eye", "objective": "Beat the Rat King, take the Eye",
     "location": "Outside the Black Cat Dojo",
     "minimal": "Damage the Rat King until he flees, then take what he drops.",
     "standard": "Damage the Rat King until he retreats (he blocks, teleports and summons rats). Then pick up the Rat King's Eye where he fell.",
     "detailed": "He has 1000 health here and blocks often: keep shooting. At 0 he fakes death and leaves. Pick up the floating Rat King's Eye where he fell: a power that shows hidden Rat King symbols for 5 seconds. Not while in Chi mode or downed.",
     "detect": "flag:eye_picked", "marker": "locate", "extra": ["step.locate = ::rat_king;"]},
    {"use": "talk_pam_brain_quest", "detect": "flag:skq_p2t1_5", "marker": "ent:ma_trainer"},
    {"use": "eye_symbol_hunt", "detect": "flag:skq_p2t2_1", "marker": "none", "extra": ["step.reset = \"puzzle_phone_reset\";"]},
    {"use": "answer_phone", "detect": "flag:morse_code_heard", "marker": "none"},
    {"use": "take_flyer", "detect": "flag:correct_poster_got", "marker": "none"},
    {"use": "roof_power", "detect": "flag:disco_roof power_on", "marker": "locate", "extra": ["step.locate = ::roof_switch;"]},
    {"id": "flyer_spotlight", "objective": "Light the flyer, hit the rat",
     "location": "Rooftop spotlight",
     "minimal": "The flyer belongs on the big rooftop light.",
     "standard": "With roof power on, use the flyer on the rooftop spotlight. Then damage the rat sitting where the light's X points.",
     "detailed": "Go to the rooftop searchlight (it glows once the roof has power) and use it to place the flyer. The light dims and an X appears where the beam points. A rat sits there: any damage kills it, a grenade works. That brings ninjas to the roof.",
     "detect": "flag:skq_p2t2_4", "marker": "ent:spotlight_light"},
    {"use": "roof_ninjas", "detect": "flag:skq_p2t2_5", "marker": "struct:kf_zombies_disco_roof"},
    {"use": "roof_cipher_word", "detect": "manual", "marker": "struct:letter_puzzle_solve_struct"},
    {"use": "summon_rk_brain", "detect": "flag:skq_p2t2_6", "marker": "struct:rk_symbol_punk_rooftops"},
    {"id": "rat_king_brain", "objective": "Beat him again, take the Brain",
     "location": "Rooftops",
     "minimal": "He is back. Drive him off, then take what he drops.",
     "standard": "Damage the Rat King until he retreats (he throws his shield, teleports and summons). Then pick up the Rat King's Brain.",
     "detailed": "The Rat King has 1000 health and does not block this time: he throws his shield, melees, teleports and summons. At 0 he fakes death and drops the Rat King's Brain. Pick up the floating relic; one is enough.",
     "detect": "flag:brain_picked", "marker": "locate", "extra": ["step.locate = ::rat_king;"]},
    {"use": "talk_pam_heart_quest", "detect": "flag:skq_p2t2_7", "marker": "ent:ma_trainer"},
    {"id": "missing_reel", "objective": "Survive the Missing Reel",
     "location": "Anywhere, then the Missing Reel",
     "minimal": "Something happens in three rounds. Then fight.",
     "standard": "Survive three more rounds (a counter shows on the HUD). The Missing Reel then plays and you are teleported: kill the zombies, avoid the fire.",
     "detailed": "Play three round changes, then about 35 seconds more (not while anyone fast-travels or is in a minigame). The Missing Reel plays and everyone is teleported. Kill the zombies around you and keep out of the fire; it ends when they die or after 60 s.",
     "detect": "flag:cleanup_reel_assets", "marker": "none"},
    {"use": "take_turnstile_arm", "detect": "flag:skq_p2t3_1", "marker": "none"},
    {"use": "fix_turnstile", "detect": "flag:turnstile_done", "marker": "sn_struct:turnstile"},
    {"use": "shoot_window_glyph", "detect": "flag:turnstyle_glyph_hit", "marker": "struct:window_cover_struct"},
    {"use": "six_kill_circles", "detect": "flag:skq_p2t3_3", "marker": "none"},
    {"use": "start_disco_turntable", "detect": "flag:fever_started", "marker": "sn_struct:disco_fever_interact"},
    {"use": "disco_fever_kills", "detect": "flag:skq_p2t3_4", "marker": "struct:disco_fever_spawn_struct"},
    {"use": "summon_rk_heart", "detect": "flag:skq_p2t3_5", "marker": "struct:rk_symbol_disco_streets"},
    {"id": "rat_king_heart", "objective": "Beat him again, take the Heart",
     "location": "Disco streets",
     "minimal": "He is tougher now. Drive him off a third time.",
     "standard": "Damage the Rat King (2500 health) until he retreats; keep away from his staff stomps. Then pick up the Rat King's Heart.",
     "detailed": "He has 2500 health and uses staff projectiles, a staff stomp, melee, summons and teleports: keep away from the stomps. At 0 he fakes death and drops the Rat King's Heart. Pick it up (not in Chi mode or downed); it becomes a power.",
     "detect": "flag:heart_picked", "marker": "locate", "extra": ["step.locate = ::rat_king;"]},
    {"use": "talk_pam_final", "detect": "flag:skq_p2t3_6", "marker": "ent:ma_trainer"},
    {"use": "enter_rk_lair", "detect": "flag:skq_phase_3", "marker": "ent:slime_pool"},
    {"use": "defeat_rat_king", "detect": "flag:rk_fight_ended", "marker": "locate", "extra": ["step.locate = ::rat_king;"]},
    {"use": "take_soul_key", "detect": "check", "marker": "locate", "extra": ["step.check = ::soul_key_taken;", "step.locate = ::soul_key;"]},
]

HELPERS = r'''
// ---------------------------------------------------------------------------
// Checks and markers (self = the player)

// The Rat King himself, among the agents (agent_type "ratking", cp_disco.gsc).
rat_king()
{
    return self custom_scripts\ix\guided\guided::nearest_agent( "ratking" );
}

// zombie_power.gsc: the generator whose script_parameters name the roof.
roof_switch()
{
    if ( !isdefined( level.generators ) )
        return undefined;

    foreach ( generator in level.generators )
    {
        if ( !isdefined( generator.script_parameters ) )
            continue;

        if ( custom_scripts\ix\core\util::array_contains( strtok( generator.script_parameters, "," ), "disco_roof" ) )
            return generator.origin;
    }

    return undefined;
}

// rat_king_fight.gsc drop_soul_key: model tag_origin_soul_key, deleted when a
// player takes it; the game sends no signal for it.
soul_key_taken()
{
    return custom_scripts\ix\guided\guided::taken_after( "rk_fight_ended", "tag_origin_soul_key" );
}

soul_key()
{
    return custom_scripts\ix\guided\guided::find_model( "tag_origin_soul_key" );
}
'''
