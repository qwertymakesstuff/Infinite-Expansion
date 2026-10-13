// Infinite Expansion - Guided Mode guide: Shaolin Shuffle (cp_disco).
//
// The main quest is the game's "skq" (disco_mpq.gsc in scripts/cp/maps/cp_disco,
// flags skq_*), with Pam Grier's talks (kung_fu_mode.gsc) and the final fight
// (rat_king_fight.gsc): Chi, then the Rat King's Eye, Brain and Heart, each
// ending in a fight, then the lair. Every signal and marker is the stock
// scripts' own (research: scratchpad guided/cp_disco.md, TESTING.md V150).
// Steps without a signal (a style chosen, Chi level 1, the rooftop cipher)
// follow from the next step the game reports. A wrong flyer makes the game
// start the symbol hunt over (puzzle_phone_reset): the guide goes back too.
// Markers only use names the v1.1.0 compiler knows (KNOWN_LIMITATIONS.md
// C10): many of this map's own fields (the next cage, the hunted symbol,
// the ringing phone) are not, so those steps have text directions only.
// Nothing here changes the quest.

guide()
{
    guide = custom_scripts\ix\guided\guided::new_guide( "cp_disco", "Shaolin Shuffle", "The Rat King's relics", "Solo or co-op. Pam Grier has work for you from round 5 on." );

    step = custom_scripts\ix\guided\guided::add_step( guide, "talk_pam_start", "Talk to Pam Grier", "Black Cat Dojo",
        "Pam Grier only has work for you from round 5 on.",
        "From round 5 on, go to the Black Cat Dojo and talk to Pam Grier. She unlocks the Chi style statues.",
        "Reach round 5. Go to Pam Grier in the Black Cat Dojo and use her. Before round 5 she only says intro lines. This talk unlocks the four Chi animal style stations (Tiger, Crane, Snake, Dragon).",
        "flag:skq_phase_1", "ent:ma_trainer" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "chi_style", "Choose a Chi style and drink", "Black Cat Dojo (style stations)",
        "Pick an animal style, then drink its Chi juice once.",
        "Use one of the animal style stations (Tiger, Crane, Snake or Dragon), then press the gourd button (d-pad right) to enter Chi mode once.",
        "Use a Tiger, Crane, Snake or Dragon station: it sets your style, starts its level-1 challenge and gives you the gourd. Any style works. Then press actionslot 4 (d-pad right) to drink and enter Chi mode once; Pam then has a new task.",
        "flag:first_kung_fu_mode", "sn_structs:martial_arts_animals" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "chi_level_1", "Reach Chi style level 1", "Anywhere",
        "Finish your style's first Chi challenge to earn the shuriken.",
        "Complete the level-1 Chi challenge of your style. At level 1 your Chi mode gets a shuriken, which you need for the next steps.",
        "Complete your style's first Chi challenge (its progress shows on the HUD). At level 1, Chi mode gives your primary Chi power, a shuriken for every style. The rat cages can only be broken by a shuriken.",
        "manual", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "talk_pam_eye_quest", "Talk to Pam Grier again", "Black Cat Dojo",
        "Pam has a new task now that you have used Chi.",
        "After someone has used Chi mode, talk to Pam Grier again. She asks for the Rat King's Eye, and the rat cages appear.",
        "Return to Pam Grier and talk to her. The talk only progresses after someone has entered Chi mode once; otherwise she has nothing new. She asks for the Rat King's Eye, and the rat-cage hunt begins.",
        "flag:skq_p2t1_0", "ent:ma_trainer" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "free_templeton", "Break the rat's cages", "Rat cages around the map",
        "One caged rat starts a chase. Shuriken only.",
        "In Chi mode, hit a rat cage with a shuriken. The rat runs to another cage; follow it and shuriken that cage. Repeat until the chain ends.",
        "Cages appear when you are within about 1024 units. Hit any cage with a shuriken. The rat (Templeton) runs to a random cage; hit that cage. 6 correct hits in total (1 + 4 + final). Hitting the wrong cage fails the step and resets it.",
        "notify:cage_win", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "ring_and_ninjas", "Clear the circle and the ninjas", "At the last rat cage",
        "Kill zombies in the glowing circle, then the ninjas.",
        "Kill 15 zombies inside the glowing circle at the last cage. Then kill the 8 ninjas that come and pick up the locker key.",
        "Stand by the glowing circle at the last cage and kill 15 zombies near its center. About 10 seconds later 8 karate-master ninjas attack: kill them all (the wave also ends after 300 seconds). Then pick up the locker key glowing above the circle.",
        "flag:skq_p2t1_2", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "open_locker", "Open the subway locker", "Subway lockers near Bang Bangs",
        "The key fits a locker underground.",
        "Take the key to the subway lockers by the Bang Bangs perk machine and open the locker.",
        "Go to the subway station with Bang Bangs. On the lockers there, use the locker. It swings open (it reads SOULKEY inside, per guides) and the symbol puzzle starts.",
        "flag:skq_p2t1_3", "ent:subway_locker_door" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "shoot_four_symbols", "Shoot the 4 symbols in order", "Dojo, Disco Inferno, Deadeye Dewdrops",
        "Four painted symbols must be shot in the right order.",
        "Shoot the four white Chinese symbols in order. A wrong symbol buzzes and resets the order.",
        "Order from guides: 1) right of the Black Cat Dojo, 2) Disco Inferno restroom stall, 3) by the statue at Deadeye Dewdrops, 4) directly right of the 3rd. A wrong or repeated hit buzzes and you restart from 1.",
        "notify:active_word_done", "structs:graffiti_check_struct" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "summon_rk_eye", "Use the Rat King symbol", "Outside the Black Cat Dojo",
        "A Rat King symbol now glows on the ground.",
        "A gong sounds and a Rat King symbol appears on the ground outside the Dojo. Use it to summon the Rat King.",
        "After the 4th symbol a gong plays and a glowing Rat King glyph appears on the ground outside the Black Cat Dojo. Stand on it and press use. The Rat King appears; get ready to fight.",
        "flag:skq_p2t1_4", "struct:rk_symbol_punk_streets" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "rat_king_eye", "Beat the Rat King, take the Eye", "Outside the Black Cat Dojo",
        "Damage the Rat King until he flees, then take what he drops.",
        "Damage the Rat King until he retreats (he blocks, teleports and summons rats). Then pick up the Rat King's Eye where he fell.",
        "He has 1000 health here and blocks often: keep shooting. At 0 he fakes death and leaves. Pick up the floating Rat King's Eye where he fell: a power that shows hidden Rat King symbols for 5 seconds. Not while in Chi mode or downed.",
        "flag:eye_picked", "locate" );
    step.locate = ::rat_king;

    step = custom_scripts\ix\guided\guided::add_step( guide, "talk_pam_brain_quest", "Return to Pam Grier", "Black Cat Dojo",
        "Pam wants to hear about the Eye.",
        "Go back to Pam Grier and talk to her. She asks for the Rat King's Brain, and the hidden symbols start appearing.",
        "Talk to Pam Grier in the Dojo. The script does not check that the Eye was picked up, but you need the Eye power for the next step. Pam asks for the Brain and the eye-only symbol hunt begins.",
        "flag:skq_p2t1_5", "ent:ma_trainer" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "eye_symbol_hunt", "Find symbols with the Eye", "Around the map (random spots)",
        "Some symbols can only be seen through the Rat King's Eye.",
        "Activate the Eye to reveal a hidden symbol, then shoot it while the Eye is active. Each hit turns a phone booth red; repeat until one is left.",
        "Use the Eye power (5 s) to see the current orange symbol at a random spot, and shoot it while the Eye is active. Each hit turns one phone booth red. The next symbol then spawns elsewhere. Repeat until only one booth is left; it starts ringing.",
        "flag:skq_p2t2_1", "none" );
    step.reset = "puzzle_phone_reset";

    step = custom_scripts\ix\guided\guided::add_step( guide, "answer_phone", "Answer the ringing phone", "The ringing phone booth",
        "Something is ringing. Listen carefully.",
        "Answer the last (still lit) phone booth that is ringing and listen to the whole Morse code message. It is a 3-digit number.",
        "Use the ringing booth and stay still until it ends. 3 digits, 5 tones each (dot short, dash long): 1 .---- 2 ..--- 3 ...-- 4 ....- 5 ..... 6 -.... 7 --... 8 ---.. 9 ----. 0 -----. It is 281, 407, 420, 596, 713 or 818.",
        "flag:morse_code_heard", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "take_flyer", "Take the matching flyer", "Film flyer posters (see open questions)",
        "One flyer carries the number you just heard.",
        "Find the movie flyer whose registration number matches the Morse code and take it. The wrong flyer resets the symbol hunt.",
        "Several flyers have 3-digit registration decals (281, 407, 420, 596, 713, 818). Take only the one that matches the Morse number. Taking a wrong one restarts the hunt with a new number: red booths reset and the symbols return.",
        "flag:correct_poster_got", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "roof_power", "Turn on the Disco roof power", "Disco rooftop power switch",
        "The rooftop spotlight needs power.",
        "Turn on the power switch that powers the Disco rooftop. The spotlight there lights up when it is on.",
        "Pull the power lever for the 'disco_roof' area. It can be done any time before this step, and many players do it early with the other three switches. When it is on, the rooftop spotlight switches on and flares.",
        "flag:disco_roof power_on", "locate" );
    step.locate = ::roof_switch;

    step = custom_scripts\ix\guided\guided::add_step( guide, "flyer_spotlight", "Light the flyer, hit the rat", "Rooftop spotlight",
        "The flyer belongs on the big rooftop light.",
        "With roof power on, use the flyer on the rooftop spotlight. Then damage the rat sitting where the light's X points.",
        "Go to the rooftop searchlight (it glows once the roof has power) and use it to place the flyer. The light dims and an X appears where the beam points. A rat sits there: any damage kills it, a grenade works. That brings ninjas to the roof.",
        "flag:skq_p2t2_4", "ent:spotlight_light" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "roof_ninjas", "Defeat the ninja wave", "Disco rooftop",
        "Ninjas answer the call. Beat them.",
        "Ten karate-master ninjas spawn around the Disco roof. Kill them all to continue.",
        "10 ninja zombies spawn on navmesh points within about 1024 units of the roof spawn point. Kill all of them; the wave also ends after 300 s. The rooftop letter cipher then starts.",
        "flag:skq_p2t2_5", "struct:kf_zombies_disco_roof" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "roof_cipher_word", "Spell the cipher word", "Rooftop letter puzzle",
        "A word's first letter appears. Shoot the right glyph next.",
        "A word is spelled one letter at a time. Each turn cipher glyphs appear; shoot the one that is the next letter. A miss buzzes and gives a new word.",
        "The first letter shows on the board. For each following letter, glyphs (one per slot) appear; one is the correct letter in cipher form. Shoot it. A wrong glyph resets to a new word. Words are from 7 themed lists (map names, Willard, etc.); there is a rare joke word, 'savagemadethis'.",
        "manual", "struct:letter_puzzle_solve_struct" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "summon_rk_brain", "Use the Rat King symbol", "Rooftops",
        "Another Rat King symbol has appeared.",
        "After the word, a gong sounds and a Rat King symbol appears on the rooftops. Use it to summon him again.",
        "Find the glowing Rat King glyph on the ground in the rooftops area (script name 'rk_symbol_punk_rooftops') and press use. The Rat King spawns.",
        "flag:skq_p2t2_6", "struct:rk_symbol_punk_rooftops" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "rat_king_brain", "Beat him again, take the Brain", "Rooftops",
        "He is back. Drive him off, then take what he drops.",
        "Damage the Rat King until he retreats (he throws his shield, teleports and summons). Then pick up the Rat King's Brain.",
        "The Rat King has 1000 health and does not block this time: he throws his shield, melees, teleports and summons. At 0 he fakes death and drops the Rat King's Brain. Pick up the floating relic; one is enough.",
        "flag:brain_picked", "locate" );
    step.locate = ::rat_king;

    step = custom_scripts\ix\guided\guided::add_step( guide, "talk_pam_heart_quest", "Return to Pam Grier", "Black Cat Dojo",
        "Bring news of the Brain to Pam.",
        "Talk to Pam Grier again. She asks for the Rat King's Heart. A three-round countdown starts.",
        "Talk to Pam Grier. She asks for the Heart. A countdown (4, 3, 2, 1) appears on the HUD and drops at each new round. After 3 rounds plus about 35 s, the Missing Reel starts.",
        "flag:skq_p2t2_7", "ent:ma_trainer" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "missing_reel", "Survive the Missing Reel", "Anywhere, then the Missing Reel",
        "Something happens in three rounds. Then fight.",
        "Survive three more rounds (a counter shows on the HUD). The Missing Reel then plays and you are teleported: kill the zombies, avoid the fire.",
        "Play three round changes, then about 35 seconds more (not while anyone fast-travels or is in a minigame). The Missing Reel plays and everyone is teleported. Kill the zombies around you and keep out of the fire; it ends when they die or after 60 s.",
        "flag:cleanup_reel_assets", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "take_turnstile_arm", "Grab the turnstile arm", "Missing Reel set",
        "Something spinning was left behind.",
        "A spinning turnstile arm appears at one of the reel spawn spots. Pick it up.",
        "When the reel fight ends, a glowing, spinning turnstile arm appears at one of the player spawn spots of the reel scene (random). Press use on it to take it.",
        "flag:skq_p2t3_1", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "fix_turnstile", "Fix the subway turnstile", "Subway turnstile (broken arm)",
        "The arm belongs on a broken subway turnstile.",
        "Find the subway turnstile with the missing arm and use it to attach the arm. A window cover nearby slides up.",
        "Use the subway turnstile that is missing an arm. It spins, and you get the 'Message Received' achievement. A metal window cover nearby rises and shows a glowing symbol.",
        "flag:turnstile_done", "sn_struct:turnstile" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "shoot_window_glyph", "Shoot the glyph in the window", "Near the subway turnstile",
        "Look behind the window cover that just opened.",
        "Shoot the glowing symbol revealed behind the raised window cover. The cover drops back down.",
        "After the turnstile, the window cover moves up over about 8 s and a glyph glows behind it. Damage it with anything. The cover slams shut and a gong-marked kill-circle chain starts.",
        "flag:turnstyle_glyph_hit", "struct:window_cover_struct" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "six_kill_circles", "Fill 6 kill circles", "Circles around the map (random)",
        "Kill zombies inside each circle as it appears.",
        "A glowing circle appears. Kill 6-9 zombies inside it, then the next one appears elsewhere. Clear 6 circles in total.",
        "Ring 1 is at a fixed spot, then 5 more at random spots. Each needs 6-9 kills (random) within about 150 units of its centre. A gong plays when all 6 are done.",
        "flag:skq_p2t3_3", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "start_disco_turntable", "Spin the disco turntable", "Disco Inferno (turntable)",
        "The record is spinning. Put the needle on it.",
        "Use the spinning turntable to start 'disco fever'. A zombie with a disco-fever effect then appears.",
        "After the circles, a turntable record starts rotating. Use it. This sets disco fever and spawns a dancing fever zombie at the disco spawn point.",
        "flag:fever_started", "sn_struct:disco_fever_interact" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "disco_fever_kills", "Kill the disco ball zombies", "Disco Inferno dance floor",
        "Only the dancing zombie with the disco ball matters.",
        "Kill the disco-ball zombie. It jumps to the nearest zombie on the dance floor; kill that one too. Keep about 10 kills chained.",
        "Lure zombies onto the dance floor and kill only the one wearing the disco ball. On death it passes to the closest zombie on the floor. If none is on the floor, the chain resets after 10 s. Chain 10 kills to finish.",
        "flag:skq_p2t3_4", "struct:disco_fever_spawn_struct" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "summon_rk_heart", "Use the Rat King symbol", "Disco streets",
        "The last Rat King symbol is waiting.",
        "A gong sounds and a Rat King symbol appears in the disco streets area. Use it for the final relic fight.",
        "Find the glowing Rat King glyph on the ground (script name 'rk_symbol_disco_streets') and press use. The Rat King spawns, stronger this time.",
        "flag:skq_p2t3_5", "struct:rk_symbol_disco_streets" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "rat_king_heart", "Beat him again, take the Heart", "Disco streets",
        "He is tougher now. Drive him off a third time.",
        "Damage the Rat King (2500 health) until he retreats; keep away from his staff stomps. Then pick up the Rat King's Heart.",
        "He has 2500 health and uses staff projectiles, a staff stomp, melee, summons and teleports: keep away from the stomps. At 0 he fakes death and drops the Rat King's Heart. Pick it up (not in Chi mode or downed); it becomes a power.",
        "flag:heart_picked", "locate" );
    step.locate = ::rat_king;

    step = custom_scripts\ix\guided\guided::add_step( guide, "talk_pam_final", "Bring the Heart to Pam Grier", "Black Cat Dojo",
        "Pam has one last thing to say.",
        "Talk to Pam Grier one last time. She sends you to face the Rat King in his lair.",
        "Talk to Pam Grier. She plays the final Rat King line, and the lair entrance (the sewage pool trigger) becomes the fight starter.",
        "flag:skq_p2t3_6", "ent:ma_trainer" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "enter_rk_lair", "Enter the Rat King's lair", "Rat King's Lair (sewers)",
        "Face him where he lives.",
        "Go to the Rat King's lair in the sewers and step into the sewage pool. Everyone is pulled into the boss arena.",
        "Make sure nobody is fast-travelling, rewinding or off-grid, and no clock interaction is active. Then step into the sewage pool in the Rat King's lair. The screen fades to black and all players are placed in the arena.",
        "flag:skq_phase_3", "ent:slime_pool" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "defeat_rat_king", "Defeat the Rat King", "Rat King's Lair (arena)",
        "Use his own relics against him.",
        "Damage the Rat King. When he hides on his platform, pick a relic, place it at the centre and finish its trial. Repeat 3 times, then kill him.",
        "7 stages: damage to 75 percent; relic 1; damage to 50 percent; relic 2; damage to 25 percent; relic 3; kill. Relic trials: Eye = shoot glowing targets while they pulse; Heart = kill zombies on the sludge pools; Brain = see section C.",
        "flag:rk_fight_ended", "locate" );
    step.locate = ::rat_king;

    step = custom_scripts\ix\guided\guided::add_step( guide, "take_soul_key", "Pick up the Soul Key", "Rat King's Lair (arena)",
        "He dropped something important.",
        "After the outro video, pick up the Soul Key the Rat King dropped.",
        "After the ending video (about 55 s), the Soul Key floats where the Rat King died (or on the arena floor if he died on the rafters). Pick it up for the Soul Key and the Pest Control achievement.",
        "check", "locate" );
    step.check = ::soul_key_taken;
    step.locate = ::soul_key;

    return guide;
}

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
