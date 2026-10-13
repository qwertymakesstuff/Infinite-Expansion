HEADER = ("cp_rave", "Rave in the Redwoods", "The Super Slasher", "Solo or co-op. Power, the boat and the projector come first.")

COMMENT = [
    "// Infinite Expansion - Guided Mode guide: Rave in the Redwoods (cp_rave).",
    "//",
    "// The main quest is the game's quest lines \"jmem\" (cp_rave_j_mem_quest.gsc in",
    "// scripts/cp/maps/cp_rave: Jay's memories, three rituals) and \"superslasher\"",
    "// (cp_rave_super_slasher_fight.gsc), after the power, the boat and the",
    "// projector (Pack-a-Punch). Every signal and marker is the stock scripts' own",
    "// (research: tools/guided/research/cp_rave.md, TESTING.md V150). Steps the",
    "// game keeps in fields the v1.1.0 compiler cannot name (KNOWN_LIMITATIONS.md",
    "// C10: boat parts, film reels, meeting Kevin, the photos) read the world",
    "// instead: a part's model gone when taken, a memento's model at its spot when",
    "// the step starts and gone when it is picked up. Nothing here changes the",
    "// quest.",
]

STEPS = [
    {"use": "power_on", "detect": "notify:activate_power", "marker": "sn_structs:generator"},
    {"use": "boat_parts", "detect": "check", "marker": "locate", "extra": ["step.check = ::boat_parts_found;", "step.locate = ::boat_part;", "step.total = 3;", "step.progress = ::boat_part_count;"]},
    {"use": "ride_boat", "detect": "check", "marker": "locate", "extra": ["step.check = ::boat_started;", "step.locate = ::boat;"]},
    {"use": "film_reels", "detect": "check", "marker": "locate", "extra": ["step.check = ::film_reels_found;", "step.locate = ::film_reel;", "step.total = 2;", "step.progress = ::film_reel_count;"]},
    {"use": "fix_projector", "detect": "flag:pap_fixed", "marker": "locate", "extra": ["step.locate = ::projector;"]},
    {"use": "talk_kevin", "detect": "check", "marker": "sn_structs:survivor_interaction", "extra": ["step.check = ::met_kevin;"]},
    {"use": "find_photo_1", "detect": "check", "marker": "ent:j_mem_1", "extra": ["step.check = ::photo_1_taken;"]},
    {"use": "ritual_arms", "detect": "flag:photo_1_kev_given", "marker": "struct:circle_org_arm"},
    {"use": "give_photo_1", "detect": "flag:photo_1_kev_vo_done", "marker": "sn_structs:survivor_interaction"},
    {"use": "find_photo_2", "detect": "check", "marker": "ent:j_mem_2", "extra": ["step.check = ::photo_2_taken;"]},
    {"use": "ritual_legs", "detect": "flag:photo_2_kev_given", "marker": "struct:circle_org_leg"},
    {"use": "give_photo_2", "detect": "flag:photo_2_kev_vo_done", "marker": "sn_structs:survivor_interaction"},
    {"use": "find_skull", "detect": "check", "marker": "ent:j_mem_3", "extra": ["step.check = ::skull_taken;"]},
    {"use": "ritual_heads", "detect": "flag:survivor_trapped", "marker": "struct:circle_org_head"},
    {"use": "free_kevin", "detect": "flag:survivor_released", "marker": "none"},
    {"use": "boat_with_kevin", "detect": "flag:survivor_got_to_island", "marker": "locate", "extra": ["step.locate = ::boat;"]},
    {"use": "kill_super_slasher", "detect": "flag:super_slasher_fight_complete", "marker": "locate", "extra": ["step.locate = ::super_slasher;"]},
    {"use": "soul_key", "detect": "check", "marker": "locate", "extra": ["step.check = ::soul_key_taken;", "step.locate = ::soul_key;"]},
]

HELPERS = r'''
// ---------------------------------------------------------------------------
// Checks (self = level) and markers (self = the player)

// cp_rave_boat.gsc: the boat's logic starts with its first trip.
boat_started()
{
    return scripts\engine\utility::is_true( level.packboat_logic_started );
}

boat()
{
    if ( isdefined( level.boat_vehicle ) )
        return level.boat_vehicle;

    return undefined;
}

// cp_rave_interactions.gsc init_boat_quest / init_pap_quest: each piece's
// struct (the ones with a name) holds its model until a player takes it.
boat_part()
{
    return self custom_scripts\ix\guided\panel::nearest_origin( pieces( "boat_quest_piece", 1 ) );
}

film_reel()
{
    return self custom_scripts\ix\guided\panel::nearest_origin( pieces( "pap_quest_piece", 1 ) );
}

pieces( name, left )
{
    found = [];

    foreach ( piece in scripts\engine\utility::getstructarray( name, "script_noteworthy" ) )
    {
        if ( isdefined( piece.name ) && isdefined( piece.model ) == left )
            found[found.size] = piece;
    }

    // Seen in the world once: only then does "none left" mean all taken.
    if ( left && found.size > 0 )
    {
        state = rave_state();
        state.seen[name] = 1;
    }

    return found;
}

rave_state()
{
    if ( !isdefined( level.ix.guided.rave ) )
    {
        level.ix.guided.rave = spawnstruct();
        level.ix.guided.rave.seen = [];
    }

    return level.ix.guided.rave;
}

pieces_found( name )
{
    pieces( name, 1 );

    if ( !isdefined( rave_state().seen[name] ) )
        return 0;

    return pieces( name, 0 ).size;
}

all_found( name )
{
    return isdefined( rave_state().seen[name] ) && pieces( name, 1 ).size == 0 && pieces( name, 0 ).size > 0;
}

boat_part_count()
{
    return pieces_found( "boat_quest_piece" );
}

boat_parts_found()
{
    return all_found( "boat_quest_piece" );
}

film_reel_count()
{
    return pieces_found( "pap_quest_piece" );
}

film_reels_found()
{
    return all_found( "pap_quest_piece" );
}

// cp_rave_j_mem_quest.gsc find_thing: once Kevin has been met, a memento's
// model appears at its spot (j_mem_1, 2, 3) and is deleted when picked up.
memento_out( name, model )
{
    spot = getent( name, "targetname" );

    if ( !isdefined( spot ) )
        return 0;

    foreach ( thing in getentarray( "script_model", "classname" ) )
    {
        if ( isdefined( thing.model ) && thing.model == model && distancesquared( thing.origin, spot.origin ) < 900 )
        {
            state = rave_state();
            state.seen[name] = 1;
            return 1;
        }
    }

    return 0;
}

memento_taken( name, model )
{
    return !memento_out( name, model ) && isdefined( rave_state().seen[name] );
}

// The first memento only shows once Kevin has been met (do_find_thing_1).
met_kevin()
{
    return memento_out( "j_mem_1", "cp_rave_quest_photo_03" ) || isdefined( rave_state().seen["j_mem_1"] );
}

photo_1_taken()
{
    return memento_taken( "j_mem_1", "cp_rave_quest_photo_03" );
}

photo_2_taken()
{
    return memento_taken( "j_mem_2", "cp_rave_quest_photo_04" );
}

skull_taken()
{
    return memento_taken( "j_mem_3", "p7_skulls_bones_head_01" );
}

// cp_interaction.gsc: the "interaction" structs named fix_pap.
projector()
{
    spots = [];

    foreach ( spot in scripts\engine\utility::getstructarray( "interaction", "targetname" ) )
    {
        if ( isdefined( spot.script_noteworthy ) && spot.script_noteworthy == "fix_pap" )
            spots[spots.size] = spot;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( spots );
}

// The Super Slasher himself (agent_type "superslasher", cp_rave.gsc).
super_slasher()
{
    return self custom_scripts\ix\guided\guided::nearest_agent( "superslasher" );
}

// cp_rave_super_slasher_fight.gsc drop_soul_key: model zmb_soul_key_single,
// deleted when a player takes it; the game sends no signal for it.
soul_key_taken()
{
    return custom_scripts\ix\guided\guided::taken_after( "super_slasher_fight_complete", "zmb_soul_key_single" );
}

soul_key()
{
    return custom_scripts\ix\guided\guided::find_model( "zmb_soul_key_single" );
}
'''
