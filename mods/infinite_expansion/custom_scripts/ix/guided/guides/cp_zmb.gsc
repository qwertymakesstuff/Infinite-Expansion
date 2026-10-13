// Infinite Expansion - Guided Mode guide: Zombies in Spaceland (cp_zmb).
//
// The main quest is the game's quest line "ufo" (cp_zmb_dj.gsc in
// scripts/cp/maps/cp_zmb, 12 steps), after the park's power and the portals to the
// Pack-a-Punch room. Every signal and marker below is the stock scripts' own
// (research: scratchpad guided/cp_zmb.md, TESTING.md V150):
//   power        5 x level notify "activate_power" (zombie_power.gsc), counted
//                as cp_zmb_ufo.gsc power_on_monitor counts them
//   portals      every area portal used once (zombie_fast_travel.gsc, the test
//                that opens the Pack-a-Punch room)
//   the quest    flags dj_fetch_quest_completed, pap_portal_used,
//                dj_request_defense_done, tone_generators_given,
//                all_structs_placed, all_center_positions_used,
//                tones_played_successfully, fuses_inserted, ufo_destroyed;
//                notifies speaker_defense_completed (x3),
//                complete_alien_grey_fight, spaceland_arc_fired
// Fields read here are all named in the v1.1.0 compiler's token table
// (KNOWN_LIMITATIONS.md C10). Nothing here changes the quest.

guide()
{
    guide = custom_scripts\ix\guided\guided::new_guide( "cp_zmb", "Zombies in Spaceland", "The UFO and the Soul Key", "Solo or co-op. Power, the portals and Pack-a-Punch come first." );

    step = custom_scripts\ix\guided\guided::add_step( guide, "power_on", "Turn on the power", "Power switches across the park",
        "Spaceland needs power before anything else works.",
        "Pull the power switch in each area of the park. The UFO frozen in the ice mountain lights up more with each one.",
        "Open the park and pull all five power switches. Each one changes the frozen UFO's lights, until it is fully lit. Power also brings the DJ to his window and wakes the area portals.",
        "count:activate_power*5", "locate" );
    step.locate = ::next_generator;

    step = custom_scripts\ix\guided\guided::add_step( guide, "link_portals", "Use all four area portals", "Teleporters in the four park areas",
        "Each powered portal must be used once.",
        "Use the teleporter in each of the four areas once. With all four linked, the center portal leads to the Pack-a-Punch room.",
        "After an area has power, use its portal: it sends you to the center. Do it in all four areas. Each first use lights a light on the center portal; with four lit, the center portal opens the hidden Pack-a-Punch room.",
        "check", "locate" );
    step.check = ::portals_linked;
    step.locate = ::next_portal;

    step = custom_scripts\ix\guided\guided::add_step( guide, "dj_items", "Find the DJ's three lost items", "Random spots around the park",
        "The DJ lost three things somewhere in the park.",
        "Find and pick up the DJ's boombox, calculator and umbrella. Each lies at one of a few spots, each in a different part of the park.",
        "Pick up the boombox, the calculator and the umbrella. Each spawns at one of three spots, in different areas: look on benches, counters and tables in the start area, Kepler, the Astrocade, Polar Peak, Journey into Space and underground.",
        "flag:dj_fetch_quest_completed", "locate" );
    step.locate = ::next_dj_item;
    step.total = 3;
    step.progress = ::dj_items_found;

    step = custom_scripts\ix\guided\guided::add_step( guide, "pap_room", "Enter the Pack-a-Punch room", "Through the center portal",
        "Visit the secret room behind the center portal.",
        "Go through the center portal into the Pack-a-Punch room. Then survive until the next round starts.",
        "Use the center portal to enter the Pack-a-Punch room (an earlier visit counts). When the next round starts, the UFO frozen in Polar Peak flashes and plays its tones, and the DJ is ready for you.",
        "flag:pap_portal_used", "ent:center_portal" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "talk_dj", "Talk to the DJ", "His DJ window (Cosmic Tunes)",
        "The DJ has something for you once the next round starts.",
        "Find the DJ window that says Talk to DJ (he moves between booths) and talk to him for the frequency device.",
        "The DJ sits behind one of the Cosmic Tunes windows; his window shows Talk to DJ, the others say he is not there. Talk to him to get the frequency device. If a defense fails later, he moves: find him again.",
        "flag:dj_request_defense_done", "locate" );
    step.locate = ::dj_window;

    step = custom_scripts\ix\guided\guided::add_step( guide, "defend_device", "Defend the device", "Where your screen shakes",
        "Carry the device until your screen shakes, then place it.",
        "Walk until your screen shakes, place the device there and keep zombies off it until its timer ends. Three times: 60, 90 and 120 seconds.",
        "The spot is random each time. Place the device on flat ground where the screen shakes (not in a special round) and kill the zombies running at it: it takes 10 hits. Pick it up after each win. If it breaks, find the DJ again and redo that defense.",
        "count:speaker_defense_completed*3", "locate" );
    step.locate = ::defended_device;

    step = custom_scripts\ix\guided\guided::add_step( guide, "get_speakers", "Get the speakers from the DJ", "His DJ window (Cosmic Tunes)",
        "Survive a round, then visit the DJ again.",
        "After the third defense, survive until the next round starts. Then talk to the DJ at his new window for the tone speakers.",
        "After the third defense the DJ moves to another window and needs a round. When the next regular round starts, find the window that says Talk to DJ and talk to him to get the portable tone speakers.",
        "flag:tone_generators_given", "locate" );
    step.locate = ::dj_window;

    step = custom_scripts\ix\guided\guided::add_step( guide, "place_speakers", "Place 4 speakers on the pads", "Golden pads by the center portal",
        "Four golden platforms surround the center portal.",
        "Put a speaker on each of the four golden platforms around the center portal: three around it, one on its steps.",
        "Go to the center portal plaza and use each of the four golden platforms to set down a speaker. Once all four stand, each speaker has its own color and tone.",
        "flag:all_structs_placed", "locate" );
    step.locate = ::next_speaker_pad;

    step = custom_scripts\ix\guided\guided::add_step( guide, "play_speakers", "Play the speakers together", "Golden pads by the center portal",
        "Every player plays a speaker at the same moment.",
        "Each player stands at a different speaker and plays it at the same time. Solo: play one speaker.",
        "With all four placed, each player uses a different speaker within about a second of the others (as many speakers as players). It does not count in a special round. When it works, the park music stops and the UFO breaks free.",
        "flag:all_center_positions_used", "locate" );
    step.locate = ::nearest_speaker_pad;

    step = custom_scripts\ix\guided\guided::add_step( guide, "match_ufo", "Repeat the UFO's colors (3x)", "Center portal plaza",
        "The UFO is signalling. Answer it with the speakers.",
        "The UFO hovers over the center portal and flashes four colors. Play the speakers in the same order. Do it three times.",
        "The UFO flashes four colors (red, green, blue, yellow) in a random order. Play the matching speakers in that order, each within 4 seconds of the last (2.5 in co-op). A wrong one brings a brute. Three rounds; the order changes.",
        "flag:tones_played_successfully", "locate" );
    step.locate = ::the_ufo;

    step = custom_scripts\ix\guided\guided::add_step( guide, "clown_horde", "Kill the UFO's clown horde", "Center portal and Main Street",
        "The UFO beams down exploding clowns.",
        "The UFO beams down 50 suicide-bomber clowns around the center. Kill all of them from a distance.",
        "The UFO hovers over the center and drops 50 clown suicide bombers from three spots: the center and both sides of Main Street. Zombies already out turn into bombers too. Kill all 50 from range.",
        "check", "locate" );
    step.check = ::clowns_killed;
    step.locate = ::the_ufo;
    step.total = 50;
    step.progress = ::clown_count;

    step = custom_scripts\ix\guided\guided::add_step( guide, "alien_greys", "Kill the alien greys", "Center portal and Main Street",
        "Aliens have landed. Stop them healing.",
        "One alien grey per player. When one starts healing under the UFO, melee the glowing fuse on its back. Kill them all.",
        "One grey per player spawns at the center; they teleport and shoot. Low on health, a grey heals under the UFO for up to 6 seconds: melee the fuse on its back to stop it (after two stops it cannot heal again). Kill every grey.",
        "notify:complete_alien_grey_fight", "locate" );
    step.locate = ::nearest_grey;

    step = custom_scripts\ix\guided\guided::add_step( guide, "alien_fuses", "Put the fuses in Pack-a-Punch", "Center portal steps, then PaP",
        "The aliens dropped something near the center portal.",
        "Pick up the two alien fuses on the center portal steps and put them in the Pack-a-Punch machine.",
        "The fuses drop on the center portal steps. Pick them up, go to the Pack-a-Punch room and use the machine to insert them. Wonder weapons can then be Pack-a-Punched, and other weapons one level more.",
        "flag:fuses_inserted", "ent:pap_machine" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "wonder_weapon", "Pack-a-Punch a wonder weapon", "Pack-a-Punch room",
        "Only an upgraded wonder weapon can charge the sign.",
        "Pack-a-Punch the Shredder, Dischord, Face Melter or Headcutter once. Only these charge the SPACELAND sign's panels.",
        "Build one of the Weapons of Rock (Shredder, Dischord, Face Melter or Headcutter) at its stand; one is enough. With the alien fuses in, Pack-a-Punch it exactly once: twice is too much for the sign.",
        "check", "ent:pap_machine" );
    step.check = ::has_charged_wonder_weapon;

    step = custom_scripts\ix\guided\guided::add_step( guide, "sign_panels", "Shoot the 5 SPACELAND panels", "SPACELAND sign at the main gate",
        "The SPACELAND sign has five panels to power up.",
        "Shoot the five blue panels around the SPACELAND sign at the main gate with the upgraded wonder weapon until each turns yellow.",
        "Dodge the UFO's slow homing shots. Shoot each of the five blue panels around the round SPACELAND sign with the once-upgraded wonder weapon until it turns yellow; other weapons do nothing. With all five yellow, the sign powers up.",
        "notify:spaceland_arc_fired", "locate" );
    step.locate = ::next_sign_panel;
    step.total = 5;
    step.progress = ::sign_panels_charged;

    step = custom_scripts\ix\guided\guided::add_step( guide, "destroy_ufo", "Destroy the UFO", "Above the center portal",
        "Let the sign's beam hit the UFO.",
        "With all five panels charged, the sign fires a beam straight up from the center. Charge the last panel as the UFO nears the center.",
        "About 5 seconds after the fifth panel, a beam fires straight up from the center portal plaza. Charge the last panel as the UFO comes over the center: only this beam hurts it, and one hit destroys it. After a miss the panels reset.",
        "flag:ufo_destroyed", "locate" );
    step.locate = ::the_ufo;

    step = custom_scripts\ix\guided\guided::add_step( guide, "soul_key", "Pick up the Soul Key", "Center portal steps",
        "Something glowing appeared near the center portal.",
        "Pick up the Soul Key that appears on the center portal steps after the UFO is destroyed.",
        "After the UFO explodes, a flaming Soul Key appears on the center portal steps. Use it to collect it for the whole team.",
        "check", "locate" );
    step.check = ::soul_key_taken;
    step.locate = ::soul_key;

    return guide;
}

// ---------------------------------------------------------------------------
// Checks: what the stock scripts test themselves

// zombie_fast_travel.gsc: every portal but the center one used once.
portals_linked()
{
    if ( !isdefined( level.fast_travel_spots ) || !isdefined( level.end_portal_name ) )
        return 0;

    foreach ( spot in level.fast_travel_spots )
    {
        if ( spot.script_area == level.end_portal_name )
            continue;

        if ( !scripts\engine\utility::is_true( spot.used_once ) )
            return 0;
    }

    return 1;
}

dj_items_found()
{
    count = 0;

    if ( scripts\engine\utility::is_true( level.dj_part_1_found ) )
        count++;

    if ( scripts\engine\utility::is_true( level.dj_part_2_found ) )
        count++;

    if ( scripts\engine\utility::is_true( level.dj_part_3_found ) )
        count++;

    return count;
}

// cp_zmb_ufo.gsc: the horde step ends at 50 kills.
clowns_killed()
{
    return clown_count() >= 50;
}

clown_count()
{
    if ( !isdefined( level.num_ufo_zombies_killed ) )
        return 0;

    return level.num_ufo_zombies_killed;
}

// cp_zmb_ufo.gsc can_charge_power_nodes: a Weapon of Rock at weapon level 2
// (Pack-a-Punched once), with any player.
has_charged_wonder_weapon()
{
    foreach ( player in level.players )
    {
        if ( !custom_scripts\ix\core\util::is_valid_player( player ) )
            continue;

        foreach ( weapon in player getweaponslistprimaries() )
        {
            switch ( getweaponbasename( weapon ) )
            {
                case "iw7_headcutter_zm_pap1":
                case "iw7_headcutter_zm":
                case "iw7_facemelter_zm_pap1":
                case "iw7_facemelter_zm":
                case "iw7_dischord_zm_pap1":
                case "iw7_dischord_zm":
                case "iw7_shredder_zm_pap1":
                case "iw7_shredder_zm":
                    if ( player scripts\cp\cp_weapon::get_weapon_level( weapon ) == 2 )
                        return 1;

                    break;
            }
        }
    }

    return 0;
}

sign_panels_charged()
{
    count = 0;

    for ( i = 1; i <= 5; i++ )
    {
        panel = scripts\engine\utility::getstruct( "main_gate_powernode_" + i, "targetname" );

        if ( isdefined( panel ) && scripts\engine\utility::is_true( panel.is_activated ) )
            count++;
    }

    return count;
}

// The Soul Key (cp_zmb_ufo.gsc: model zmb_soul_key_base) appears once the
// quest is finished and is deleted when a player takes it; the game sends
// no signal for it.
soul_key_taken()
{
    if ( !custom_scripts\ix\guided\tracker::flag_set_by_game( "ufo_quest_finished" ) )
        return 0;

    if ( isdefined( soul_key() ) )
    {
        level.ix.guided.soul_key_seen = 1;
        return 0;
    }

    return isdefined( level.ix.guided.soul_key_seen );
}

// ---------------------------------------------------------------------------
// Markers: places the stock scripts look up themselves (self = the player)

// zombie_power.gsc level.generators: a switch not pulled yet.
next_generator()
{
    if ( !isdefined( level.generators ) )
        return undefined;

    open = [];

    foreach ( generator in level.generators )
    {
        if ( !scripts\engine\utility::is_true( generator.powered_on ) )
            open[open.size] = generator;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( open );
}

next_portal()
{
    if ( !isdefined( level.fast_travel_spots ) || !isdefined( level.end_portal_name ) )
        return undefined;

    open = [];

    foreach ( spot in level.fast_travel_spots )
    {
        if ( spot.script_area != level.end_portal_name && !scripts\engine\utility::is_true( spot.used_once ) )
            open[open.size] = spot;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( open );
}

// cp_zmb_dj.gsc level.selected_dj_parts: the items still lying in the park.
next_dj_item()
{
    if ( !isdefined( level.selected_dj_parts ) )
        return undefined;

    items = [];

    foreach ( part in level.selected_dj_parts )
    {
        if ( isdefined( part ) && isdefined( part.part_model ) )
            items[items.size] = part.part_model;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( items );
}

dj_window()
{
    if ( isdefined( level.selected_dj_door ) && isdefined( level.selected_dj_door.origin ) )
        return level.selected_dj_door.origin;

    return undefined;
}

// While a defense runs: the device itself (cp_zmb_dj.gsc level.current_speaker).
defended_device()
{
    if ( isdefined( level.current_speaker ) )
        return level.current_speaker;

    return undefined;
}

next_speaker_pad()
{
    if ( !isdefined( level.alldjcenterstructs ) )
        return undefined;

    open = [];

    foreach ( pad in level.alldjcenterstructs )
    {
        if ( !scripts\engine\utility::is_true( pad.placed ) )
            open[open.size] = pad;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( open );
}

nearest_speaker_pad()
{
    if ( !isdefined( level.alldjcenterstructs ) )
        return undefined;

    return self custom_scripts\ix\guided\panel::nearest_origin( level.alldjcenterstructs );
}

the_ufo()
{
    if ( isdefined( level.ufo ) )
        return level.ufo;

    return undefined;
}

nearest_grey()
{
    if ( !isdefined( level.spawned_grey ) )
        return undefined;

    alive = [];

    foreach ( grey in level.spawned_grey )
    {
        if ( isdefined( grey ) && isalive( grey ) )
            alive[alive.size] = grey;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( alive );
}

next_sign_panel()
{
    open = [];

    for ( i = 1; i <= 5; i++ )
    {
        panel = scripts\engine\utility::getstruct( "main_gate_powernode_" + i, "targetname" );

        if ( isdefined( panel ) && !scripts\engine\utility::is_true( panel.is_activated ) )
            open[open.size] = panel;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( open );
}

soul_key()
{
    foreach ( thing in getentarray( "script_model", "classname" ) )
    {
        if ( isdefined( thing.model ) && thing.model == "zmb_soul_key_base" )
            return thing;
    }

    return undefined;
}
