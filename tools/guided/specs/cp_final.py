HEADER = ("cp_final", "The Beast from Beyond", "N31L and the Cryptids", "Solo or co-op. The fight is hard: bring Pack-a-Punched weapons.")

COMMENT = [
    "// Infinite Expansion - Guided Mode guide: The Beast from Beyond (cp_final).",
    "//",
    "// The main quest is the game's quest line \"MPQ\" (cp_final_mpq.gsc in",
    "// scripts/cp/maps/cp_final: N31L's head, the energy doors, the floppy disks,",
    "// the button, the lever grid, the boss fight), with the Entangler's line",
    "// \"ghostFive\" (cp_final_ghost_activation.gsc), the Theater portal and the",
    "// Pack-a-Punch bridge, and the Cryptid fight (cp_final_rhino_boss.gsc). Every",
    "// signal and marker is the stock scripts' own (research:",
    "// tools/guided/research/cp_final.md, TESTING.md V150). Where the game keeps a",
    "// step in a field the v1.1.0 compiler cannot name (KNOWN_LIMITATIONS.md C10),",
    "// the guide reads the world instead: the skull box's models, the Entangler in",
    "// a player's crafted slot, the opened portal, the game's own disk and scrap",
    "// counters. Steps done in any order (step.parallel) close by their own signal",
    "// or with the step that needs them (step.needs). When N31L's hack runs out he",
    "// turns evil again (neilIsEvil): the guide goes back to the lever grid.",
    "// Nothing here changes the quest.",
]

STEPS = [
    # N31L and the power
    {"use": "retrieve_n31l_head", "detect": "flag:neil_head_found", "marker": "locate", "extra": ["step.locate = ::n31l_head;"]},
    {"use": "install_n31l_head", "detect": "flag:neil_head_placed", "marker": "ent:neil_console"},

    # The Entangler (Ghosts n' Skulls), in any order with the rest
    {"use": "blow_open_skull_box", "location": "A wall box (random spot, marker)",
     "detect": "check", "marker": "locate",
     "extra": ["step.check = ::skull_box_done;", "step.locate = ::skull_box;", "step.parallel = 1;"]},
    {"use": "hold_pressure_plate", "detect": "notify:complete_stay_on_pressure_plates", "marker": "sn_structs:pressure_plate_center",
     "extra": ["step.needs = \"blow_open_skull_box\";", "step.parallel = 1;"]},
    {"use": "pick_up_entangler", "detect": "check", "marker": "sn_struct:entangler_spawner",
     "extra": ["step.needs = \"hold_pressure_plate\";", "step.check = ::has_entangler;", "step.parallel = 1;"]},
    {"use": "break_medbay_forcefield", "detect": "flag:security_doors_deactivated", "marker": "structs:med_bay_monitors",
     "extra": ["step.needs = \"pick_up_entangler\";"]},

    # The floppy disks
    {"id": "phantom_disk", "objective": "Kill a Phantom for its disk",
     "location": "Anywhere (a Phantom kill)",
     "minimal": "A big blue Cryptid is carrying a floppy disk.",
     "standard": "Kill a Phantom (big blue Cryptid). The first one killed where the disk can land drops a floppy disk: pick it up.",
     "detailed": "Phantoms come in rounds and after the Pack-a-Punch portal goes on cooldown. Kill one in the play area and take the disk it drops. Only one disk can be carried at a time: insert it in N31L's console before taking another.",
     "detect": "flag:phantom_disk_drop", "marker": "none", "extra": ["step.parallel = 1;"]},
    {"use": "send_disk_through_vent", "detect": "notify:vent_grabbed_puzzle_piece", "marker": "structs:air_suck_loc",
     "extra": ["step.needs = \"pick_up_entangler\";", "step.parallel = 1;"]},
    {"id": "insert_disks", "objective": "Insert the 4 disks into N31L",
     "location": "N31L's console, Spawn room",
     "minimal": "Four disks, four slots; a paper list gives the order.",
     "standard": "Disks: the Phantom's, the vent one, left of the PaP portal, the Forcefield Room table. Insert them in N31L's console in the paper list's order.",
     "detailed": "Carry one disk at a time. Note each disk's symbol; of the white paper lists around the map only one shows all four: its order is the slot order. A wrong order sends Cryptids and gives the disks new symbols: find the new list and try again.",
     "detect": "flag:fuse_puzzle_completed", "marker": "locate",
     "extra": ["step.needs = \"phantom_disk send_disk_through_vent\";", "step.locate = ::next_disk;", "step.total = 4;", "step.progress = ::disks_inserted;"]},

    # The button and the lever grid
    {"use": "open_theater_portal", "detect": "check", "marker": "ent:portal_gun_button",
     "extra": ["step.check = ::theater_portal_open;", "step.parallel = 1;"]},
    {"use": "button_to_poster", "detect": "flag:button_entered_poster", "marker": "struct:button_entangle_target",
     "extra": ["step.needs = \"open_theater_portal\";"]},
    {"use": "press_hidden_button", "detect": "flag:toggle_puzzle_button_pressed", "marker": "sn_structs:puzzle_door_button"},
    {"use": "build_pap_bridge", "location": "Three scrap pieces, then the gap",
     "standard": "Collect the 3 scrap pieces and use the bridge spot to build the way to the Pack-a-Punch portal. Do it before hacking N31L.",
     "detailed": "Each pickup brings a few Cryptids. With all 3, use the bridge site (the marker shows it): the bridge forms and the Pack-a-Punch portal can be reached. N31L's head has to go through that portal, so build it before the lever grid.",
     "detect": "flag:bridge_constructed", "marker": "locate",
     "extra": ["step.locate = ::bridge_target;", "step.total = 3;", "step.progress = ::scrap_found;", "step.parallel = 1;"]},
    {"use": "solve_lever_grid", "detect": "flag:disable_evil_neil", "marker": "sn_struct:entangler_button",
     "extra": ["step.reset = \"neilIsEvil\";"]},
    {"use": "carry_head_to_pap", "objective": "Take N31L's head to the PaP room",
     "location": "Spawn console, then Pack-a-Punch room",
     "standard": "While N31L is hacked, entangle his head at the Spawn console and carry it where it points, through the PaP portal to the computer on the right.",
     "detect": "flag:neils_head_placed_in_pap", "marker": "sn_struct:neil_head_final_pos",
     "extra": ["step.needs = \"build_pap_bridge\";"]},
    {"use": "start_boss_fight", "detect": "flag:players_triggered_bossfight", "marker": "sn_structs:neil_head_final_pos"},

    # The Cryptids
    {"id": "boss_rhinos", "objective": "Kill the 4 Rhinos",
     "location": "Boss arena",
     "minimal": "The laser frees Rhinos from the cargo containers.",
     "standard": "The laser cannon breaks open four cargo containers and four Rhinos come out. Kill all four.",
     "detailed": "Teleporting is off for the whole fight. Perk boxes appear in the arena and refill between stages, and there is an ammo crate. Kill all four Rhinos to move on.",
     "detect": "flag:rhino_stage_1", "marker": "locate", "extra": ["step.locate = ::rhino;"]},
    {"id": "boss_wave_1", "objective": "Survive the portal waves",
     "location": "Boss arena",
     "minimal": "Cryptids pour out of portals.",
     "standard": "Cryptids pour out of portals around the arena. Kill them until the wave ends; it is bigger with more players.",
     "detailed": "The wave is 40, 60, 80 or 100 Cryptids for 1 to 4 players. Keep moving, and use the perk boxes and the ammo crate between stages.",
     "detect": "flag:rhino_stage_2", "marker": "none"},
    {"id": "boss_wave_2", "objective": "Survive the Phantom wave",
     "location": "Boss arena, the new area",
     "minimal": "Another part of the arena opens. Phantoms come.",
     "standard": "A second area of the arena opens and Phantoms join the Cryptids. Kill them until the wave ends.",
     "detailed": "25, 40, 50 or 60 enemies for 1 to 4 players, Phantoms among them. Phantoms are the big blue Cryptids: focus them first.",
     "detect": "flag:rhino_stage_3", "marker": "none"},
    {"id": "boss_consoles", "objective": "Activate the 3 consoles",
     "location": "Boss arena",
     "minimal": "Three consoles must be on at once.",
     "standard": "The laser now aims at players. When the consoles light up, turn on all three so they are on at the same time.",
     "detailed": "About 45 s into the stage the three consoles light up. Each stays on for 20 s divided by the number of players, so split up or move fast: all three must be on together. Keep out of the laser.",
     "detect": "flag:rhino_stage_4", "marker": "structs:rhino_console"},
    {"id": "boss_emp", "objective": "Defend the EMP, then use it",
     "location": "Boss arena, EMP room",
     "minimal": "Protect the EMP console while it charges.",
     "standard": "The laser opens the EMP room and two sentry doors. Take the sentries, keep enemies off the EMP console while it charges, then use it.",
     "detailed": "Pick up the two sentry turrets and place them near the console. Its counter runs down from 99; when it reaches 0 the console can be used: use it to fire the EMP. The lights go out after.",
     "detect": "flag:rhino_stage_5", "marker": "ent:emp_console"},
    {"id": "boss_mammoths", "objective": "Kill both Mammoths",
     "location": "Boss arena, in the dark",
     "minimal": "The lights are out. Two Mammoths come.",
     "standard": "Two Mammoths are released in the dark. Keep out of their blue flame pools and kill both.",
     "detailed": "The Mammoths are huge Rhinos; their blue flame pools hurt badly, so keep moving. Killing both ends the fight and plays the ending. With Director's Cut on and all four talismans, Mephistopheles comes next.",
     "detect": "notify:rhino_fight_over", "marker": "locate", "extra": ["step.locate = ::rhino;"]},
]

HELPERS = r'''
// ---------------------------------------------------------------------------
// Checks (self = level)

// cp_final_ghost_activation.gsc box_open_sequence: the box becomes
// ship_hallway_control_box_body and a skull (zmb_8_bit_price_unlit) slides
// out; skull_damage_monitor deletes the skull when a player shoots it.
skull_box_done()
{
    box = custom_scripts\ix\guided\guided::find_model( "ship_hallway_control_box_body" );

    if ( !isdefined( box ) )
        return 0;

    foreach ( thing in getentarray( "script_model", "classname" ) )
    {
        if ( isdefined( thing.model ) && thing.model == "zmb_8_bit_price_unlit" && distancesquared( thing.origin, box.origin ) < 22500 )
            return 0;
    }

    return 1;
}

// cp/crafted_entangler.gsc give_crafted_entangler: the Entangler goes into
// the player's crafted slot (utility.gsc set_crafted_inventory_item).
has_entangler()
{
    if ( isdefined( level.ix.guided.final_entangler ) )
        return 1;

    foreach ( player in level.players )
    {
        slot = player.current_crafted_inventory;

        if ( isdefined( slot ) && isdefined( slot.item ) && slot.item == "crafted_entangler" )
        {
            level.ix.guided.final_entangler = 1;
            return 1;
        }
    }

    return 0;
}

// cp_final_fast_travel.gsc blast_doors_with_gun: the cargo_room portal opens.
theater_portal_open()
{
    foreach ( portal in scripts\engine\utility::getstructarray( "fast_travel_portal", "targetname" ) )
    {
        if ( isdefined( portal.script_noteworthy ) && portal.script_noteworthy == "cargo_room" )
            return scripts\engine\utility::is_true( portal.opened );
    }

    return 0;
}

// The game's own counters (cp_final_mpq.gsc: zm_floppy_count, zm_scrap_count).
counter( name )
{
    value = getomnvar( name );

    if ( !isdefined( value ) )
        return 0;

    return int( value );
}

disks_inserted()
{
    return counter( "zm_floppy_count" );
}

scrap_found()
{
    return counter( "zm_scrap_count" );
}

// ---------------------------------------------------------------------------
// Markers (self = the player)

// cp_final_mpq.gsc: the chosen neil_head spot holds the head (headmodel).
n31l_head()
{
    heads = [];

    foreach ( spot in scripts\engine\utility::getstructarray( "neil_head", "script_noteworthy" ) )
    {
        if ( isdefined( spot.headmodel ) )
            heads[heads.size] = spot.headmodel;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( heads );
}

// The closed box (set_up_ghost_box), then the opened one.
skull_box()
{
    box = custom_scripts\ix\guided\guided::find_model( "ship_hallway_control_box" );

    if ( isdefined( box ) )
        return box;

    return custom_scripts\ix\guided\guided::find_model( "ship_hallway_control_box_body" );
}

// A disk players can take now, else N31L's console.
next_disk()
{
    disk = self custom_scripts\ix\guided\panel::nearest_origin( custom_scripts\ix\guided\guided::active_interactions( "puzzle_pieces" ) );

    if ( isdefined( disk ) )
        return disk;

    return getent( "neil_console", "targetname" );
}

// A scrap piece players can take now; with all three, the bridge site.
bridge_target()
{
    if ( custom_scripts\ix\guided\tracker::flag_set_by_game( "bridge_pieces_collected" ) )
    {
        site = scripts\engine\utility::getstruct( "construct_bridge", "script_noteworthy" );

        if ( isdefined( site ) )
            return site.origin;

        return undefined;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( custom_scripts\ix\guided\guided::active_interactions( "pap_bridge" ) );
}

// Rhinos and Mammoths are agents of type alien_rhino (cp_final_rhino_boss.gsc).
rhino()
{
    return self custom_scripts\ix\guided\guided::nearest_agent( "alien_rhino" );
}
'''
