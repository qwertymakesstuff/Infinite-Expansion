// Infinite Expansion - Guided Mode guide: The Beast from Beyond (cp_final).
//
// The main quest is the game's quest line "MPQ" (cp_final_mpq.gsc in
// scripts/cp/maps/cp_final: N31L's head, the energy doors, the floppy disks,
// the button, the lever grid, the boss fight), with the Entangler's line
// "ghostFive" (cp_final_ghost_activation.gsc), the Theater portal and the
// Pack-a-Punch bridge, and the Cryptid fight (cp_final_rhino_boss.gsc). Every
// signal and marker is the stock scripts' own (research:
// tools/guided/research/cp_final.md, TESTING.md V150). Where the game keeps a
// step in a field the v1.1.0 compiler cannot name (KNOWN_LIMITATIONS.md C10),
// the guide reads the world instead: the skull box's models, the Entangler in
// a player's crafted slot, the opened portal, the game's own disk and scrap
// counters. Steps done in any order (step.parallel) close by their own signal
// or with the step that needs them (step.needs). When N31L's hack runs out he
// turns evil again (neilIsEvil): the guide goes back to the lever grid.
// Nothing here changes the quest.

guide()
{
    guide = custom_scripts\ix\guided\guided::new_guide( "cp_final", "The Beast from Beyond", "N31L and the Cryptids", "Solo or co-op. The fight is hard: bring Pack-a-Punched weapons." );

    step = custom_scripts\ix\guided\guided::add_step( guide, "retrieve_n31l_head", "Find N31L's head", "Ops Center pit (lower walkway)",
        "N31L's head is somewhere below the Ops Center.",
        "Drop through the hole in the middle of the Ops Center onto the ledge below and follow the lower walkway to its end to pick up N31L's head.",
        "In the Ops Center, drop through the hole in the floor and land on the ledge below (missing it is fatal). Follow the flooded lower walkway past the Tuff 'Nuff tunnel to its end and pick up N31L's head.",
        "flag:neil_head_found", "locate" );
    step.locate = ::n31l_head;

    step = custom_scripts\ix\guided\guided::add_step( guide, "install_n31l_head", "Install N31L's head at Spawn", "Spawn room, N31L terminal",
        "N31L needs his head back before the power comes on.",
        "Return to the Spawn room and use N31L's terminal to install his head. This turns the power on.",
        "Carry the head back to the Spawn room and interact with N31L's terminal. Installing it turns on facility power, enables the floppy disk slots and disks, and enables the Cargo Bay portal button. The power is not on until the head is actually installed.",
        "flag:neil_head_placed", "ent:neil_console" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "blow_open_skull_box", "Blow open the skull box", "A wall box (random spot, marker)",
        "An explosion will crack open a hidden wall box.",
        "Find the wall control box (random spot, one is above the curving Cargo Bay stairs) and hit it with explosive damage, then shoot the skull.",
        "The box spawns at one random spot (guides: 3; one is up and right from the landing of the curving Cargo Bay stairs). Damage it with any explosive (grenade, launcher splash). The door opens and a green 8-bit skull slides out: shoot it to finish.",
        "check", "locate" );
    step.check = ::skull_box_done;
    step.locate = ::skull_box;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "hold_pressure_plate", "Hold the pressure plate", "Pressure plate (map marker shown)",
        "Everyone has to stand together on the marked floor plate.",
        "All players stand on the pressure plate for 60 seconds while zombies attack, then reach the skull before it vanishes.",
        "Every player must stay inside the plate area; anyone leaving cancels the charge (retry next round). After 60 s the glowing skull flies to one of 4 nearby spots: walk into it within about 12 s or it times out. Collecting it unlocks the Entangler.",
        "notify:complete_stay_on_pressure_plates", "sn_structs:pressure_plate_center" );
    step.needs = "blow_open_skull_box";
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "pick_up_entangler", "Pick up the Entangler", "Cargo Bay (center)",
        "Something new is floating in the Cargo Bay.",
        "Collect the Entangler that now floats above a glowing marker. Equip it with the crafted-item button to grab outlined objects.",
        "Each player can take the Entangler from its spawn point. Equip it with the crafted-item button (action slot 3), aim at outlined objects to pull them toward you, then launch them. It is needed for the helmet, the vent disk, the Theater button and N31L's head.",
        "check", "sn_struct:entangler_spawner" );
    step.needs = "hold_pressure_plate";
    step.check = ::has_entangler;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "break_medbay_forcefield", "Break the Med Bay forcefield", "Medical Bay, Forcefield Room",
        "Something thrown at the right monitor could kill that forcefield.",
        "Entangle a white space helmet, take it to the Medical Bay and launch it at the green monitor behind the forcefield.",
        "Power must be on. Grab any space helmet with the Entangler, go to the Medical Bay forcefield room (Cryptid autopsy room) and launch the helmet so it lands on the green monitor behind the forcefield. The monitors crack and both energy doors are destroyed.",
        "flag:security_doors_deactivated", "structs:med_bay_monitors" );
    step.needs = "pick_up_entangler";

    step = custom_scripts\ix\guided\guided::add_step( guide, "phantom_disk", "Kill a Phantom for its disk", "Anywhere (a Phantom kill)",
        "A big blue Cryptid is carrying a floppy disk.",
        "Kill a Phantom (big blue Cryptid). The first one killed where the disk can land drops a floppy disk: pick it up.",
        "Phantoms come in rounds and after the Pack-a-Punch portal goes on cooldown. Kill one in the play area and take the disk it drops. Only one disk can be carried at a time: insert it in N31L's console before taking another.",
        "flag:phantom_disk_drop", "none" );
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "send_disk_through_vent", "Shoot the disk into the vent", "Bang Bangs hallway grate",
        "One disk is behind bars; the air vent nearby is pulling air in.",
        "In the hallway near Bang Bangs, entangle the floppy disk behind the bars and launch it at the sucking grate. It pops out of a vent elsewhere.",
        "Use the Entangler on the disk behind the bars near Bang Bangs, then launch it so it lands near the grate that is sucking air. The vent swallows it and blows it out at a random landing vent (guides mention the Medical Bay). Pick it up there.",
        "notify:vent_grabbed_puzzle_piece", "structs:air_suck_loc" );
    step.needs = "pick_up_entangler";
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "insert_disks", "Insert the 4 disks into N31L", "N31L's console, Spawn room",
        "Four disks, four slots; a paper list gives the order.",
        "Disks: the Phantom's, the vent one, left of the PaP portal, the Forcefield Room table. Insert them in N31L's console in the paper list's order.",
        "Carry one disk at a time. Note each disk's symbol; of the white paper lists around the map only one shows all four: its order is the slot order. A wrong order sends Cryptids and gives the disks new symbols: find the new list and try again.",
        "flag:fuse_puzzle_completed", "locate" );
    step.needs = "phantom_disk send_disk_through_vent";
    step.locate = ::next_disk;
    step.total = 4;
    step.progress = ::disks_inserted;

    step = custom_scripts\ix\guided\guided::add_step( guide, "open_theater_portal", "Open the Theater portal", "Cargo Bay upper catwalk button",
        "A button in the Cargo Bay controls a big cannon.",
        "With power on, press the wall button on the Cargo Bay upper catwalk. The cannon blasts open the portal doors to the Theater.",
        "Power must be on first. Press the wall button on the Cargo Bay upper catwalk; the laser cannon moves, fires and destroys the doors of the Cargo Bay portal, which leads to the Theater. Needed for the Theater button step and a Pack-a-Punch bridge piece.",
        "check", "ent:portal_gun_button" );
    step.check = ::theater_portal_open;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "button_to_poster", "Fire the button into the poster", "Theater, behind Brute cutout",
        "A small button on a Theater wall can be pulled off.",
        "Entangle the small button on the Theater wall behind the Brute cutout and launch it into a 'The Beast From Beyond' poster.",
        "After the disks are in, the button on the Theater wall behind the Brute cutout is outlined. Entangle it, carry it to a 'The Beast From Beyond' poster (guides: Theater Arcade, left of the Cryptid Attack machine) and launch it into the poster. If it hits, the button vanishes from the wall.",
        "flag:button_entered_poster", "struct:button_entangle_target" );
    step.needs = "open_theater_portal";

    step = custom_scripts\ix\guided\guided::add_step( guide, "press_hidden_button", "Crouch and press the button", "Forcefield Room desk (Med Bay)",
        "The button you moved reappeared somewhere low.",
        "Find the button under the desk in the Forcefield Room near the Medical Bay. Crouch or go prone and press it.",
        "The button reappears on the underside of a desk in the Forcefield Room near the Medical Bay. It only works while you are crouched or prone and not jumping. Pressing it opens the panels in front of the lever grid.",
        "flag:toggle_puzzle_button_pressed", "sn_structs:puzzle_door_button" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "build_pap_bridge", "Build the Pack-a-Punch bridge", "Three scrap pieces, then the gap",
        "Pack-a-Punch is cut off; scrap could bridge the gap.",
        "Collect the 3 scrap pieces and use the bridge spot to build the way to the Pack-a-Punch portal. Do it before hacking N31L.",
        "Each pickup brings a few Cryptids. With all 3, use the bridge site (the marker shows it): the bridge forms and the Pack-a-Punch portal can be reached. N31L's head has to go through that portal, so build it before the lever grid.",
        "flag:bridge_constructed", "locate" );
    step.locate = ::bridge_target;
    step.total = 3;
    step.progress = ::scrap_found;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "solve_lever_grid", "Set all levers the same way", "Medical Bay lever grid",
        "The lever grid wants every lever pointing the same way.",
        "Turn the levers until all 16 point the same way (all horizontal or all vertical). Each lever also flips several others.",
        "Look at a lever to highlight it and use it. Every lever flips itself plus a fixed group of others. Goal: all 16 horizontal or all 16 vertical. Note or screenshot the start layout first so you can undo. Success hacks N31L and starts a 3 min (co-op) / 4 min (solo) timer.",
        "flag:disable_evil_neil", "sn_struct:entangler_button" );
    step.reset = "neilIsEvil";

    step = custom_scripts\ix\guided\guided::add_step( guide, "carry_head_to_pap", "Take N31L's head to the PaP room", "Spawn console, then Pack-a-Punch room",
        "While N31L is hacked, his head can be moved. He knows the way.",
        "While N31L is hacked, entangle his head at the Spawn console and carry it where it points, through the PaP portal to the computer on the right.",
        "Entangle the head at N31L's console. Doors shut and zombies speed up while you carry it; follow the direction the head faces out to the PaP portal. In the PaP room launch it into the computer on the desk on the right. A miss or dropped head nukes the round; redo the levers.",
        "flag:neils_head_placed_in_pap", "sn_struct:neil_head_final_pos" );
    step.needs = "build_pap_bridge";

    step = custom_scripts\ix\guided\guided::add_step( guide, "start_boss_fight", "All players use the PaP computer", "Pack-a-Punch room computer",
        "Everyone must answer N31L's computer together.",
        "With the head placed, every player holds the use button on the PaP room computer at the same time to enter the boss fight.",
        "All living players must use the computer within about 2 seconds of each other; a lone press expires. Prepare first (perks, PaP weapons, ammo): you are teleported straight into the boss arena and interactions/teleports are locked during the fight.",
        "flag:players_triggered_bossfight", "sn_structs:neil_head_final_pos" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_rhinos", "Kill the 4 Rhinos", "Boss arena",
        "The laser frees Rhinos from the cargo containers.",
        "The laser cannon breaks open four cargo containers and four Rhinos come out. Kill all four.",
        "Teleporting is off for the whole fight. Perk boxes appear in the arena and refill between stages, and there is an ammo crate. Kill all four Rhinos to move on.",
        "flag:rhino_stage_1", "locate" );
    step.locate = ::rhino;

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_wave_1", "Survive the portal waves", "Boss arena",
        "Cryptids pour out of portals.",
        "Cryptids pour out of portals around the arena. Kill them until the wave ends; it is bigger with more players.",
        "The wave is 40, 60, 80 or 100 Cryptids for 1 to 4 players. Keep moving, and use the perk boxes and the ammo crate between stages.",
        "flag:rhino_stage_2", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_wave_2", "Survive the Phantom wave", "Boss arena, the new area",
        "Another part of the arena opens. Phantoms come.",
        "A second area of the arena opens and Phantoms join the Cryptids. Kill them until the wave ends.",
        "25, 40, 50 or 60 enemies for 1 to 4 players, Phantoms among them. Phantoms are the big blue Cryptids: focus them first.",
        "flag:rhino_stage_3", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_consoles", "Activate the 3 consoles", "Boss arena",
        "Three consoles must be on at once.",
        "The laser now aims at players. When the consoles light up, turn on all three so they are on at the same time.",
        "About 45 s into the stage the three consoles light up. Each stays on for 20 s divided by the number of players, so split up or move fast: all three must be on together. Keep out of the laser.",
        "flag:rhino_stage_4", "structs:rhino_console" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_emp", "Defend the EMP, then use it", "Boss arena, EMP room",
        "Protect the EMP console while it charges.",
        "The laser opens the EMP room and two sentry doors. Take the sentries, keep enemies off the EMP console while it charges, then use it.",
        "Pick up the two sentry turrets and place them near the console. Its counter runs down from 99; when it reaches 0 the console can be used: use it to fire the EMP. The lights go out after.",
        "flag:rhino_stage_5", "ent:emp_console" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_mammoths", "Kill both Mammoths", "Boss arena, in the dark",
        "The lights are out. Two Mammoths come.",
        "Two Mammoths are released in the dark. Keep out of their blue flame pools and kill both.",
        "The Mammoths are huge Rhinos; their blue flame pools hurt badly, so keep moving. Killing both ends the fight and plays the ending. With Director's Cut on and all four talismans, Mephistopheles comes next.",
        "notify:rhino_fight_over", "locate" );
    step.locate = ::rhino;

    return guide;
}

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
