HEADER = ("cp_town", "Attack of the Radioactive Thing", "Nuke the Radioactive Thing", "Solo or co-op. Some steps need every player at once.")

COMMENT = [
    "// Infinite Expansion - Guided Mode guide: Attack of the Radioactive Thing (cp_town).",
    "//",
    "// The main quest is four of the game's quest lines (cp_town_mpq.gsc and the",
    "// cp_town_crab_boss_*.gsc files in scripts/cp/maps/cp_town): \"deathray\" (a",
    "// zombie body, three mirrors, the Life and Death Rays, the garage key),",
    "// \"chemistry\" (the lab and the Chem Mix), \"launchcode\" (the safe's codes and",
    "// the nuke) and \"crabBoss\" (the fight), after Elvira (cp_town_elvira.gsc).",
    "// Every signal and marker is the stock scripts' own (research:",
    "// tools/guided/research/cp_town.md, TESTING.md V150). The deathray line keeps",
    "// its state in fields the v1.1.0 compiler cannot name (KNOWN_LIMITATIONS.md",
    "// C10), so its steps read what the game does to the world instead: a part's",
    "// glow gone when it is taken, a mirror model on its stand, the card in its",
    "// slot, the Death Ray signs, the garage door going up. Much of the quest can",
    "// be done in any order (step.parallel): those steps close by their own signal,",
    "// or with the step that needs them (step.needs: the Life Ray, the chemistry",
    "// set, the charged nuke). A failed sonic beam or code entry makes the game",
    "// play the end of the fight again: the guide goes back too. Nothing here",
    "// changes the quest.",
]

STEPS = [
    # Prerequisites: the power, Elvira
    {"use": "get_power_lever", "detect": "flag:found_missing_handle", "marker": "locate", "extra": ["step.locate = ::power_lever;"]},
    {"use": "power_on", "detect": "flag:power_on", "marker": "interaction:generator_broken"},
    {"use": "get_spellbook", "location": "The safe the power opened",
     "detect": "flag:spellbook_found", "marker": "ent:elvira_safe"},
    {"use": "give_spellbook", "detect": "flag:spellbook_placed", "marker": "struct:elvira"},
    {"use": "get_cleaver", "detect": "check", "marker": "sn_struct:iw7_knife_zm_cleaver",
     "extra": ["step.check = ::has_cleaver;", "step.parallel = 1;"]},
    {"use": "fill_vial", "detect": "flag:vial_filled", "marker": "none", "extra": ["step.needs = \"get_cleaver\";"]},
    {"use": "summon_elvira", "detect": "flag:elvira_summoned", "marker": "struct:elvira"},
    {"use": "mirror_elvira", "detect": "check", "marker": "ent:elvira_mirror", "extra": ["step.check = ::elvira_mirror_taken;"]},

    # The zombie body and the mirrors, in any order
    {"use": "get_crowbar", "detect": "check", "marker": "sn_struct:iw7_knife_zm_crowbar",
     "extra": ["step.check = ::has_crowbar;", "step.parallel = 1;"]},
    {"use": "body_head", "detect": "check", "marker": "ent:mpq_zom_head_part",
     "extra": ["step.check = ::head_taken;", "step.parallel = 1;"]},
    {"id": "freeze_trap_part", "objective": "Find the Deep Freeze trap part",
     "location": "One of several spots (marker)",
     "minimal": "The Deep Freeze trap is broken. Its part lies somewhere.",
     "standard": "The torso is behind meat that must be frozen first. Find the Deep Freeze trap's missing part: the game puts it at one of several spots.",
     "detailed": "Each match the trap part lies at one random spot of several; the marker shows it. Pick it up (it shows as a carried part), then take it to the trap's sparking control panel.",
     "detect": "flag:freeze_trap_part_taken", "marker": "locate", "extra": ["step.locate = ::freeze_trap_part;", "step.parallel = 1;"]},
    {"id": "fix_freeze_trap", "objective": "Repair the Deep Freeze trap",
     "location": "The trap's control panel",
     "minimal": "Put the part back where it belongs.",
     "standard": "Bring the part to the Deep Freeze trap's sparking control panel and fit it.",
     "detailed": "Use the sparking control panel while carrying the part. The panel is replaced and the trap's buttons work again; using the trap costs 750.",
     "detect": "flag:freeze_trap_part_added", "marker": "sn_struct:fix_freeze_trap", "extra": ["step.needs = \"freeze_trap_part\";", "step.parallel = 1;"]},
    {"use": "freeze_meat", "objective": "Freeze and smash the pig",
     "location": "Where the Deep Freeze trap fires",
     "standard": "Use the Deep Freeze trap (750), then hit the frozen pig in front of the torso with the Crowbar.",
     "detailed": "Use the repaired trap. Once it has fired, the pig can be broken: melee it with the Crowbar (nothing else works). It shatters and the torso behind it can be taken.",
     "detect": "flag:frozen_meat_gone", "marker": "ent:frozen_meat", "extra": ["step.needs = \"fix_freeze_trap get_crowbar\";", "step.parallel = 1;"]},
    {"use": "body_torso", "location": "Behind the frozen pig",
     "detect": "check", "marker": "ent:mpq_zom_torso_part", "extra": ["step.needs = \"freeze_meat\";", "step.check = ::torso_taken;", "step.parallel = 1;"]},
    {"use": "body_arm_firepit", "detect": "check", "marker": "ent:mpq_zom_r_arm_part",
     "extra": ["step.check = ::firepit_arm_taken;", "step.parallel = 1;"]},
    {"id": "quake_beach_arm", "objective": "Quake the buried arm loose",
     "location": "Beach, where the lever was",
     "minimal": "A crafted device can shake the buried arm out of the sand.",
     "standard": "Build a Seismic Wave Generator (blueprint and 3 parts, at a crafting bench) and place it right next to the buried arm on the beach.",
     "detailed": "Find the blueprint, then the leg, magnet and piston (one carried at a time; the marker shows the next). Build it at a crafting bench, then place it within about 2.5 m of the buried arm: it rises a little every 3 s until it is out.",
     "detect": "flag:quake_lifts_arm", "marker": "locate", "extra": ["step.locate = ::seismic_target;", "step.parallel = 1;"]},
    {"use": "body_arm_beach", "detect": "check", "marker": "ent:mpq_zom_l_arm_part",
     "extra": ["step.needs = \"quake_beach_arm\";", "step.check = ::beach_arm_taken;", "step.parallel = 1;"]},
    {"use": "leg_from_tree", "detect": "check", "marker": "ent:mpq_zom_l_leg_part",
     "extra": ["step.check = ::tree_leg_taken;", "step.parallel = 1;"]},
    {"use": "leg_from_glowing_zombie", "detect": "check", "marker": "locate",
     "extra": ["step.needs = \"get_cleaver\";", "step.check = ::cleaver_leg_taken;", "step.locate = ::cleaver_leg;", "step.parallel = 1;"]},
    {"use": "place_body", "detect": "check", "marker": "interaction:mpq_zom_body",
     "extra": ["step.needs = \"body_head body_torso body_arm_firepit body_arm_beach leg_from_tree leg_from_glowing_zombie\";", "step.check = ::body_laid;", "step.total = 6;", "step.progress = ::parts_on_slab;", "step.parallel = 1;"]},
    {"use": "mirror_bathroom", "objective": "Break the RV bathroom mirror", "detect": "check", "marker": "ent:bathroom_mirror_piece",
     "extra": ["step.needs = \"get_crowbar\";", "step.check = ::bathroom_shard_taken;", "step.parallel = 1;"]},
    {"use": "mirror_car", "detect": "check", "marker": "ent:car_mirror_ground",
     "extra": ["step.needs = \"get_crowbar\";", "step.check = ::car_mirror_taken;", "step.parallel = 1;"]},
    {"use": "place_mirrors", "objective": "Set the mirrors on their stands", "location": "Mirror stands (marker)",
     "detect": "check", "marker": "locate",
     "extra": ["step.needs = \"mirror_bathroom mirror_car\";", "step.check = ::all_mirrors_placed;", "step.locate = ::next_mirror_stand;", "step.total = 3;", "step.progress = ::mirrors_placed;", "step.parallel = 1;"]},
    {"id": "scantron", "objective": "Put the Scantron in the machine",
     "location": "Ice Cream Shop, then the spawn machine",
     "minimal": "The machine in spawn needs a punch card.",
     "standard": "Take the Scantron punch card from the Ice Cream Shop, then use the ray machine in the spawn area to slot it in.",
     "detailed": "Pick up the Scantron card in the Ice Cream Shop and use the ray machine in spawn once to insert it. The machine only takes its code once all six body parts have been picked up.",
     "detect": "check", "marker": "ent:mpq_punch_card", "extra": ["step.check = ::card_inserted;", "step.parallel = 1;"]},

    # The rays and the garage
    {"id": "fire_life_ray", "objective": "Fire the Life Ray",
     "location": "Spawn area (ray machine)",
     "minimal": "The film reel cases hold the numbers.",
     "standard": "Enter the 5-digit code from the five numbered film reel cases on the ray machine, then use it again to fire the Life Ray at the slab.",
     "detailed": "Digits 3,4,5,6,8 in a random order, read from film reels 1-5. Stop the cycling counter on each digit; 3 wrong ones kick you out. The beam then needs all 6 parts on the slab and all 3 mirrors placed, or it stops early.",
     "detect": "check", "marker": "interaction:ray_gun_start", "extra": ["step.check = ::body_made;", "step.needs = \"place_body place_mirrors scantron\";"]},
    {"use": "reverse_code", "detect": "check", "marker": "interaction:ray_gun_start", "extra": ["step.check = ::polarity_reversed;"]},
    {"id": "death_ray_key", "objective": "Fire the Death Ray, get the key",
     "location": "Spawn machine, then the garage",
     "minimal": "Destroy what you built, then use what it leaves.",
     "standard": "Use the ray machine once more to fire the Death Ray. Take the key from the slab and open the gas station garage with it.",
     "detailed": "The Death Ray vaporizes the body and a glowing key appears on the slab: use the slab to take it. Then use the roll-up door of the gas station garage; the chemistry lab is inside.",
     "detect": "check", "marker": "interaction:garage_door", "extra": ["step.check = ::garage_open;"]},

    # The chemistry
    {"use": "chem_set_parts", "location": "Random spots (marker)",
     "detect": "check", "marker": "locate",
     "extra": ["step.check = ::all_chem_parts;", "step.locate = ::next_chem_part;", "step.total = 3;", "step.progress = ::chem_parts_found;", "step.parallel = 1;"]},
    {"use": "build_chem_set", "detect": "flag:chemistry_step1", "marker": "interaction:crafting_station_chem", "extra": ["step.needs = \"chem_set_parts\";"]},
    {"id": "brew_chem_mix", "objective": "Brew the Chem Mix",
     "location": "Radios, then the garage lab",
     "minimal": "Dr. Bright's tapes name the chemical that kills the beast.",
     "standard": "Play Dr. Bright's radio tapes to learn the compound and its elements, then make it in the lab: beakers, reaction number, start, take it.",
     "detailed": "Fill the beakers with the needed elements. Reaction number: add the top and left values of each element's diamond, minus the O constant; the colour view shows which. Type it on the computer, press start and take the compound.",
     "detect": "flag:chemistry_step3", "marker": "ent:chem_computer"},
    {"use": "add_chem_mix", "location": "The nuke (marker)", "detect": "flag:chemistry_step4", "marker": "sn_struct:place_bomb_parts"},

    # The launch codes and the nuke, in any order until it charges
    {"id": "set_gauges", "objective": "Set the 4 pressure gauges",
     "location": "Gas station, Snack Shack, Power, Motel",
     "minimal": "Four gauges around town must match four hidden numbers.",
     "standard": "Read the four numbers under the desk in the back of the Beachside Market, then hit each pressure gauge with the Crowbar to stop it on one.",
     "detailed": "Gauges: behind the gas station, right side of the Snack Shack, behind the shack at the Power Station, in the Crowbar motel room. A Crowbar hit stops the swinging needle; hit again to free it. Any gauge can show any of the numbers.",
     "detect": "flag:launchcode_step1", "marker": "ents:mpq_gauge_trig", "extra": ["step.needs = \"get_crowbar\";", "step.parallel = 1;"]},
    {"use": "take_launch_codes", "detect": "flag:launchcode_step2", "marker": "sn_struct:take_launchcodes", "extra": ["step.needs = \"set_gauges\";", "step.parallel = 1;"]},
    {"use": "nuke_parts", "location": "Red car, stream end, one more",
     "detailed": "Part 1: go prone at the red car between the motel and the TV Studio (only prone works). Part 2: the end of the stream that runs under the bridge. Part 3: follow the marker.",
     "detect": "check", "marker": "locate",
     "extra": ["step.check = ::all_nuke_parts;", "step.locate = ::next_nuke_part;", "step.total = 3;", "step.progress = ::nuke_parts_found;", "step.parallel = 1;"]},
    {"use": "build_nuke", "location": "The nuke (marker)", "detect": "flag:launchcode_step3", "marker": "sn_struct:place_bomb_parts", "extra": ["step.needs = \"nuke_parts\";", "step.parallel = 1;"]},
    {"use": "charge_nuke", "location": "The nuke", "detect": "flag:teleporter_charged", "marker": "sn_struct:place_bomb_parts", "extra": ["step.needs = \"take_launch_codes build_nuke\";"]},
    {"use": "teleport_nuke", "location": "The nuke", "detect": "flag:launchcode_step4", "marker": "sn_struct:place_bomb_parts"},

    # The Radioactive Thing
    {"use": "boss_escort", "detect": "notify:escort_sequence_ended", "marker": "none"},
    {"use": "boss_cannon_hit", "detect": "notify:crab_boss_weak_spot_initial_hit", "marker": "sn_structs:death_ray_cannon"},
    {"use": "boss_weak_spot", "detect": "check", "marker": "none", "extra": ["step.check = ::weak_spot_broken;"]},
    {"use": "boss_arm_cart", "detect": "notify:players_trigger_vehicle_teleporter", "marker": "none",
     "extra": ["step.reset = \"sonic_ring_fail end_detonate_bomb\";"]},
    {"use": "boss_wall_of_death", "detect": "notify:wall_of_death_completed", "marker": "none"},
    {"use": "boss_sonic_beam", "detect": "notify:sonic_ring_success", "marker": "none"},
    {"use": "boss_enter_codes",
     "detailed": "Each player is sent to a panel. Enter the safe's 5-digit code by stopping the cycling counter on each digit; 3 wrong digits eject you (use it again). Everyone must finish in 30 s, or the beast's last attacks start over.",
     "detect": "flag:boss_fight_finished", "marker": "sn_structs:bomb_start"},
]

GUIDE_EXTRA = [
    "// What only shows as a change from the start of the match.",
    "watch_town();",
]

HELPERS = r'''
// ---------------------------------------------------------------------------
// What the guide notes from the start of the match (self = level)

// Things whose state shows only as a change: which pickups were in the world
// when the match began, where the cleaver leg waits, the garage door, the
// beast's weak spot.
watch_town()
{
    state = spawnstruct();
    state.present = [];
    state.held = [];

    foreach ( name in [ "elvira_mirror", "bathroom_mirror_piece", "car_mirror_ground" ] )
        state.present[name] = isdefined( getent( name, "targetname" ) );

    // cp_town_mpq.gsc phase3_take_bomb_part: each part is the entity its
    // interaction targets, deleted when taken.
    state.nuke_parts = [];

    foreach ( spot in custom_scripts\ix\guided\guided::interactions( "bomb_teleporter_part" ) )
    {
        if ( isdefined( spot.target ) && isdefined( getent( spot.target, "targetname" ) ) )
            state.nuke_parts[state.nuke_parts.size] = spot.target;
    }

    // listen_for_death_by_cleaver moves this part to where the zombie died.
    leg = getent( "mpq_zom_r_leg_part", "targetname" );

    if ( isdefined( leg ) )
        state.leg_start = leg.origin;

    level.ix.guided.town = state;
    level thread watch_garage_door( state );
    level thread watch_weak_spot( state );
}

// garage_door_init_func lowers the door (movez -96) and the key raises it
// again (movez 96): open once it has gone up from the lowest point seen.
watch_garage_door( state )
{
    level endon( "game_ended" );
    door = getent( "garage_door", "targetname" );

    if ( !isdefined( door ) )
        return;

    lowest = door.origin[2];

    for (;;)
    {
        door waittill( "movedone" );

        if ( door.origin[2] < lowest )
            lowest = door.origin[2];
        else if ( door.origin[2] >= lowest + 90 )
        {
            state.garage_open = 1;
            return;
        }
    }
}

// cp_town_crab_boss_fight.gsc death_ray_cannon: once the weak spot has taken
// its damage the game tells the beast itself (no level notify).
watch_weak_spot( state )
{
    level endon( "game_ended" );
    level waittill( "crab_boss_weak_spot_initial_hit" );
    beast = the_beast();

    if ( !isdefined( beast ) )
        return;

    beast waittill( "stop_death_ray_attack_logic" );
    state.weak_spot_broken = 1;
}

// The Radioactive Thing among the agents (agent_type "crab_boss").
the_beast()
{
    if ( !isdefined( level.agentarray ) )
        return undefined;

    foreach ( agent in level.agentarray )
    {
        if ( isdefined( agent ) && isalive( agent ) && isdefined( agent.agent_type ) && agent.agent_type == "crab_boss" )
            return agent;
    }

    return undefined;
}

// ---------------------------------------------------------------------------
// Checks (self = level)

game_flag( name )
{
    return custom_scripts\ix\guided\tracker::flag_set_by_game( name );
}

// A pickup the game deletes when taken, and that was there at the start.
taken( name )
{
    state = level.ix.guided.town;
    return isdefined( state.present[name] ) && state.present[name] && !isdefined( getent( name, "targetname" ) );
}

// Someone holds this melee weapon now, or has before (cp_town_interactions.gsc
// meleeweaponuse sets currentmeleeweapon; the Crowbar and the Cleaver swap).
held( weapon )
{
    state = level.ix.guided.town;

    if ( isdefined( state.held[weapon] ) )
        return 1;

    foreach ( player in level.players )
    {
        if ( isdefined( player.currentmeleeweapon ) && player.currentmeleeweapon == weapon )
        {
            state.held[weapon] = 1;
            return 1;
        }
    }

    return 0;
}

// Or something only the Cleaver does: its kills fill the vial.
has_cleaver()
{
    return held( "iw7_knife_zm_cleaver" ) || game_flag( "vial_filled" );
}

// Or something only the Crowbar does: the pig, the two mirrors, the gauges.
has_crowbar()
{
    if ( held( "iw7_knife_zm_crowbar" ) || game_flag( "frozen_meat_gone" ) || game_flag( "launchcode_step1" ) )
        return 1;

    return taken( "bathroom_mirror_piece" ) || taken( "car_mirror_ground" );
}

elvira_mirror_taken()
{
    return taken( "elvira_mirror" );
}

bathroom_shard_taken()
{
    return taken( "bathroom_mirror_piece" );
}

car_mirror_taken()
{
    return taken( "car_mirror_ground" );
}

// A body part: zom_body_part_activation_func deletes its glow (fx_ent) when
// it is taken, and zom_body_bed_activation_func lights its copy on the slab
// (the part's name without "_part").
part_taken( name )
{
    part = getent( name, "targetname" );

    if ( !isdefined( part ) )
        return 0;

    if ( isdefined( part.fx_ent ) )
    {
        part.ix_glowed = 1;
        return 0;
    }

    if ( isdefined( part.ix_glowed ) || isdefined( level.ix.guided.town.body_laid ) )
        return 1;

    slab = getent( getsubstr( name, 0, name.size - 5 ), "targetname" );
    return isdefined( slab ) && isdefined( slab.fx_ent );
}

head_taken()
{
    return part_taken( "mpq_zom_head_part" );
}

torso_taken()
{
    return part_taken( "mpq_zom_torso_part" );
}

firepit_arm_taken()
{
    return part_taken( "mpq_zom_r_arm_part" );
}

beach_arm_taken()
{
    return part_taken( "mpq_zom_l_arm_part" );
}

tree_leg_taken()
{
    return part_taken( "mpq_zom_l_leg_part" );
}

cleaver_leg_taken()
{
    return part_taken( "mpq_zom_r_leg_part" );
}

// The parts lit on the slab; the Life Ray puts them all out when it builds
// the body.
parts_on_slab()
{
    count = 0;

    foreach ( name in [ "mpq_zom_head", "mpq_zom_torso", "mpq_zom_l_arm", "mpq_zom_r_arm", "mpq_zom_l_leg", "mpq_zom_r_leg" ] )
    {
        slab = getent( name, "targetname" );

        if ( isdefined( slab ) && isdefined( slab.fx_ent ) )
            count++;
    }

    if ( count == 6 )
        level.ix.guided.town.body_laid = 1;

    return count;
}

body_laid()
{
    parts_on_slab();
    return isdefined( level.ix.guided.town.body_laid );
}

body_made()
{
    return body_laid() && parts_on_slab() == 0;
}

// mirror_placement_activation_func: a script model of the stand's model
// (the script_noteworthy of the struct the interaction targets) on the stand.
mirror_stands()
{
    stands = [];

    foreach ( spot in scripts\engine\utility::getstructarray( "mirror_placement", "script_noteworthy" ) )
    {
        if ( !isdefined( spot.target ) )
            continue;

        stand = scripts\engine\utility::getstruct( spot.target, "targetname" );

        if ( isdefined( stand ) && isdefined( stand.script_noteworthy ) )
            stands[stands.size] = stand;
    }

    return stands;
}

mirror_on( stand, models )
{
    foreach ( thing in models )
    {
        if ( isdefined( thing.model ) && thing.model == stand.script_noteworthy && distancesquared( thing.origin, stand.origin ) < 4 )
            return 1;
    }

    return 0;
}

mirrors_placed()
{
    models = getentarray( "script_model", "classname" );
    count = 0;

    foreach ( stand in mirror_stands() )
    {
        if ( mirror_on( stand, models ) )
            count++;
    }

    return count;
}

all_mirrors_placed()
{
    return mirrors_placed() >= 3;
}

// ray_gun_activation_func moves the card into its slot.
card_inserted()
{
    card = getent( "mpq_punch_card", "targetname" );
    slot = scripts\engine\utility::getstruct( "punch_card_slot", "targetname" );
    return isdefined( card ) && isdefined( slot ) && distancesquared( card.origin, slot.origin ) < 4;
}

// nuclear_bomb_armed_sequence: the reversed code turns the signs.
polarity_reversed()
{
    foreach ( sign in getentarray( "death_ray_sign", "targetname" ) )
    {
        if ( isdefined( sign.model ) && sign.model == "cp_town_camp_danger_deathraysign" )
            return 1;
    }

    return 0;
}

garage_open()
{
    return isdefined( level.ix.guided.town.garage_open );
}

// cp_town_crafting.gsc: the crafting pieces this match uses have an item,
// hidden when taken.
crafting_pieces( prefix, want_taken )
{
    found = [];

    foreach ( piece in scripts\engine\utility::getstructarray( "crafting_piece", "script_noteworthy" ) )
    {
        if ( !isdefined( piece.name ) || !isdefined( piece.item ) || !custom_scripts\ix\core\util::starts_with( piece.name, prefix ) )
            continue;

        if ( scripts\engine\utility::is_true( piece.item.hidden ) == want_taken )
            found[found.size] = piece.item;
    }

    return found;
}

chem_parts_found()
{
    return crafting_pieces( "chem_", 1 ).size;
}

all_chem_parts()
{
    return chem_parts_found() >= 3;
}

nuke_parts_found()
{
    count = 0;

    foreach ( name in level.ix.guided.town.nuke_parts )
    {
        if ( !isdefined( getent( name, "targetname" ) ) )
            count++;
    }

    return count;
}

all_nuke_parts()
{
    return nuke_parts_found() >= 3;
}

weak_spot_broken()
{
    return isdefined( level.ix.guided.town.weak_spot_broken );
}

// ---------------------------------------------------------------------------
// Markers (self = the player)

// cp_town_interactions.gsc missinghandleinit: the chosen spot holds the
// lever's model until it is taken.
power_lever()
{
    return self things_with( "missing_handle", "model" );
}

// cp_town_traps.gsc freeze_trap_init: the chosen spot holds the part.
freeze_trap_part()
{
    return self things_with( "trap_freeze_part", "part" );
}

things_with( name, field )
{
    found = [];

    foreach ( spot in scripts\engine\utility::getstructarray( name, "script_noteworthy" ) )
    {
        if ( field == "model" && isdefined( spot.model ) )
            found[found.size] = spot.model;
        else if ( field == "part" && isdefined( spot.part ) )
            found[found.size] = spot.part;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( found );
}

// The next Seismic Wave Generator part, then the buried arm.
seismic_target()
{
    left = crafting_pieces( "seismic_", 0 );

    if ( left.size > 0 )
        return self custom_scripts\ix\guided\panel::nearest_origin( left );

    return getent( "mpq_zom_l_arm_part", "targetname" );
}

// Where the glowing zombie died, once one has (the part has moved there).
cleaver_leg()
{
    leg = getent( "mpq_zom_r_leg_part", "targetname" );
    state = level.ix.guided.town;

    if ( !isdefined( leg ) || !isdefined( state.leg_start ) || distancesquared( leg.origin, state.leg_start ) < 4 )
        return undefined;

    return leg;
}

next_mirror_stand()
{
    models = getentarray( "script_model", "classname" );
    left = [];

    foreach ( stand in mirror_stands() )
    {
        if ( !mirror_on( stand, models ) )
            left[left.size] = stand;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( left );
}

next_chem_part()
{
    return self custom_scripts\ix\guided\panel::nearest_origin( crafting_pieces( "chem_", 0 ) );
}

next_nuke_part()
{
    left = [];

    foreach ( name in level.ix.guided.town.nuke_parts )
    {
        part = getent( name, "targetname" );

        if ( isdefined( part ) )
            left[left.size] = part;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( left );
}
'''
