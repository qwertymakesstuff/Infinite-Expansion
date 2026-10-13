// Infinite Expansion - Guided Mode guide: Attack of the Radioactive Thing (cp_town).
//
// The main quest is four of the game's quest lines (cp_town_mpq.gsc and the
// cp_town_crab_boss_*.gsc files in scripts/cp/maps/cp_town): "deathray" (a
// zombie body, three mirrors, the Life and Death Rays, the garage key),
// "chemistry" (the lab and the Chem Mix), "launchcode" (the safe's codes and
// the nuke) and "crabBoss" (the fight), after Elvira (cp_town_elvira.gsc).
// Every signal and marker is the stock scripts' own (research: scratchpad
// guided/cp_town.md, TESTING.md V150). The deathray line keeps its state in
// fields the v1.1.0 compiler cannot name (KNOWN_LIMITATIONS.md C10), so its
// steps read what the game does to the world instead: a part's glow gone
// when it is taken, a mirror model on its stand, the card in its slot, the
// Death Ray signs, the garage door going up. Much of the quest can be done
// in any order (step.parallel): those steps close only themselves, and the
// Life Ray, the Chem Mix and the charged nuke close everything they need.
// A failed sonic beam or code entry makes the game play the end of the
// fight again: the guide goes back too. Nothing here changes the quest.

guide()
{
    guide = custom_scripts\ix\guided\guided::new_guide( "cp_town", "Attack of the Radioactive Thing", "Nuke the Radioactive Thing", "Solo or co-op. Some steps need every player at once." );

    step = custom_scripts\ix\guided\guided::add_step( guide, "get_power_lever", "Find the power lever", "Beach (half-buried zombie hand)",
        "The power switch at the Power Station is missing its lever.",
        "A half-buried zombie on the beach is holding the missing power lever. Pick it up.",
        "Go to the beach and find the zombie half-buried in the sand. Interact with the lever in its hand to take it (shows as a carried part). The arm that held it sinks into the sand; it becomes a body part later.",
        "flag:found_missing_handle", "locate" );
    step.locate = ::power_lever;

    step = custom_scripts\ix\guided\guided::add_step( guide, "power_on", "Turn on the power", "Power Station",
        "Bring the lever to the broken power switch.",
        "Take the lever to the Power Station and fit it on the broken power switch to power the town.",
        "With the lever, go to the Power Station and interact with the broken switch box to add the lever; the switch is thrown automatically and power comes on for the whole map (also opens Elvira's spell-book safe).",
        "flag:power_on", "interaction:generator_broken" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "get_spellbook", "Take Elvira's spell book", "The safe the power opened",
        "A safe opened when the power came on.",
        "After power is on, a safe opens. Take Elvira's spell book from inside it.",
        "Turn the power on first; the safe model swaps to open and its interaction appears. Take the spell book from the safe, then bring it to Elvira in the TV Studio.",
        "flag:spellbook_found", "ent:elvira_safe" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "give_spellbook", "Give the book to Elvira", "TV Studio",
        "Elvira wants her book back.",
        "Talk to Elvira on her couch in the TV Studio and hand over the spell book. She gives you a vial to fill.",
        "In the TV Studio, interact with Elvira while carrying the book. The book is placed on its stand and the vial icon appears; from now on Cleaver kills fill the vial.",
        "flag:spellbook_placed", "struct:elvira" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "get_cleaver", "Get the Cleaver", "Market meat counter",
        "Check the shark at the market's meat counter.",
        "Take the Cleaver from the shark corpse at the meat counter in the market. It swaps with the Crowbar.",
        "Go to the market meat counter and interact with the Cleaver in the shark corpse. Cleaver kills fill Elvira's vial and a Cleaver kill on a glowing zombie drops a leg. It swaps with the Crowbar.",
        "check", "sn_struct:iw7_knife_zm_cleaver" );
    step.check = ::has_cleaver;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "fill_vial", "Fill the vial with Cleaver kills", "Anywhere",
        "Elvira's vial needs to be filled.",
        "Kill enemies with the Cleaver until the vial meter is full. Crog kills fill it fastest.",
        "Equip the Cleaver. Each Crog killed with it adds 10 percent, each zombie killed adds 5 percent, each Cleaver hit on a zombie adds 1 percent. When the meter is full the vial is filled.",
        "flag:vial_filled", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "summon_elvira", "Give Elvira the full vial", "TV Studio",
        "Return the filled vial to Elvira.",
        "Bring the full vial to Elvira in the TV Studio to summon her as an ally.",
        "Interact with Elvira while the vial is full. She snaps her fingers, vanishes from the couch and fights beside you for a while. Do the next step (her mirror) while she is out.",
        "flag:elvira_summoned", "struct:elvira" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "mirror_elvira", "Take Elvira's hand mirror", "TV Studio (Elvira's couch)",
        "Elvira left something behind when she left her couch.",
        "While Elvira is summoned, go to where she was sitting in the TV Studio and take her hand mirror.",
        "Summon Elvira with the full vial. While she is out (or on cooldown), interact at her couch spot in the TV Studio to take the hand mirror.",
        "check", "ent:elvira_mirror" );
    step.check = ::elvira_mirror_taken;

    step = custom_scripts\ix\guided\guided::add_step( guide, "get_crowbar", "Get the Crowbar", "Motel room",
        "A melee tool can break glass, gauges and frozen meat.",
        "Pick up the Crowbar in the motel room. It replaces your melee and is needed for mirrors, frozen meat and gauges.",
        "Open the motel room and interact with the Crowbar to equip it. It swaps with the Cleaver (only one at a time); swap back at either pickup when needed.",
        "check", "sn_struct:iw7_knife_zm_crowbar" );
    step.check = ::has_crowbar;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "body_head", "Collect the zombie head", "RV (via Pack-a-Punch wall button)",
        "One body part is hidden inside an RV.",
        "From the Pack-a-Punch room, use the button on the wall to reach an RV and pick up the zombie head.",
        "Reach the Pack-a-Punch room, press the wall button to be sent to an RV, and interact with the glowing zombie head to collect it.",
        "check", "ent:mpq_zom_head_part" );
    step.check = ::head_taken;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "freeze_trap_part", "Find the Deep Freeze trap part", "One of several spots (marker)",
        "The Deep Freeze trap is broken. Its part lies somewhere.",
        "The torso is behind meat that must be frozen first. Find the Deep Freeze trap's missing part: the game puts it at one of several spots.",
        "Each match the trap part lies at one random spot of several; the marker shows it. Pick it up (it shows as a carried part), then take it to the trap's sparking control panel.",
        "flag:freeze_trap_part_taken", "locate" );
    step.locate = ::freeze_trap_part;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "fix_freeze_trap", "Repair the Deep Freeze trap", "The trap's control panel",
        "Put the part back where it belongs.",
        "Bring the part to the Deep Freeze trap's sparking control panel and fit it.",
        "Use the sparking control panel while carrying the part. The panel is replaced and the trap's buttons work again; using the trap costs 750.",
        "flag:freeze_trap_part_added", "sn_struct:fix_freeze_trap" );
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "freeze_meat", "Freeze and smash the pig", "Where the Deep Freeze trap fires",
        "The torso is behind meat that needs to be frozen first.",
        "Use the Deep Freeze trap (750), then hit the frozen pig in front of the torso with the Crowbar.",
        "Use the repaired trap. Once it has fired, the pig can be broken: melee it with the Crowbar (nothing else works). It shatters and the torso behind it can be taken.",
        "flag:frozen_meat_gone", "ent:frozen_meat" );
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "body_torso", "Collect the zombie torso", "Behind the frozen pig",
        "The torso is free now.",
        "Pick up the zombie torso that was behind the frozen pig.",
        "After the pig shatters, interact with the glowing torso to collect it (it cannot be taken before the meat is gone).",
        "check", "ent:mpq_zom_torso_part" );
    step.check = ::torso_taken;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "body_arm_firepit", "Collect the arm in the firepit", "RV Park firepit",
        "Check the firepit in the RV Park.",
        "An arm is lying in the firepit at the RV Park. Pick it up.",
        "Go to the RV Park firepit and interact with the glowing arm. No other requirement.",
        "check", "ent:mpq_zom_r_arm_part" );
    step.check = ::firepit_arm_taken;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "quake_beach_arm", "Quake the buried arm loose", "Beach, where the lever was",
        "A crafted device can shake the buried arm out of the sand.",
        "Build a Seismic Wave Generator (blueprint and 3 parts, at a crafting bench) and place it right next to the buried arm on the beach.",
        "Find the blueprint, then the leg, magnet and piston (one carried at a time; the marker shows the next). Build it at a crafting bench, then place it within about 2.5 m of the buried arm: it rises a little every 3 s until it is out.",
        "flag:quake_lifts_arm", "locate" );
    step.locate = ::seismic_target;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "body_arm_beach", "Collect the arm on the beach", "Beach",
        "The arm is out of the sand.",
        "Pick up the arm that the quakes pushed out of the sand.",
        "Once the arm has fully risen, interact with it to collect it (needs both the lever taken and the quake done).",
        "check", "ent:mpq_zom_l_arm_part" );
    step.check = ::beach_arm_taken;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "leg_from_tree", "Blast the leg out of the tree", "Tree behind the TV Studio",
        "A leg is hanging up in a tree.",
        "Hit the leg in the tree behind the TV Studio with an explosive, then pick it up from the ground.",
        "Throw a grenade or fire any explosive/projectile at the leg hanging in the tree behind the TV Studio. It drops to the ground; interact with it to collect it.",
        "check", "ent:mpq_zom_l_leg_part" );
    step.check = ::tree_leg_taken;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "leg_from_glowing_zombie", "Cleaver-kill a glowing zombie", "Anywhere (glowing soldier zombies)",
        "One leg comes from a radioactive zombie.",
        "Kill one of the glowing soldier zombies with the Cleaver as the final blow; a leg appears where it died.",
        "Equip the Cleaver. Glowing (radioactive) soldier zombies sprint; finish one with a Cleaver melee. A glowing leg appears at its death spot; interact with it to collect it.",
        "check", "locate" );
    step.check = ::cleaver_leg_taken;
    step.locate = ::cleaver_leg;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "place_body", "Lay the body parts on the slab", "Spawn area",
        "The parts belong together on the slab in spawn.",
        "Bring the collected parts to the zombie body slab in the spawn area and interact to lay them out.",
        "Interact with the body slab in the spawn area; every part you have picked up so far is placed (glowing). You can place in batches. All 6 must be placed before the Life Ray can build the body.",
        "check", "interaction:mpq_zom_body" );
    step.check = ::body_laid;
    step.total = 6;
    step.progress = ::parts_on_slab;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "mirror_bathroom", "Break the RV bathroom mirror", "RV Park bathroom",
        "A mirror at the RV Park can be broken.",
        "Melee the bathroom mirror at the RV Park with the Crowbar and take the glass shard.",
        "Equip the Crowbar, go to the RV Park bathroom and melee the intact mirror. It shatters; interact with the glass shard to collect it.",
        "check", "ent:bathroom_mirror_piece" );
    step.check = ::bathroom_shard_taken;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "mirror_car", "Knock off the car mirror", "White car at the gas station",
        "A car's side mirror is loose.",
        "Melee the passenger mirror of the white car in front of the gas station with the Crowbar, then pick it up.",
        "Equip the Crowbar and melee the passenger-side mirror of the white car parked in front of the gas station. It falls to the ground; interact to collect it.",
        "check", "ent:car_mirror_ground" );
    step.check = ::car_mirror_taken;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "place_mirrors", "Set the mirrors on their stands", "Mirror stands (marker)",
        "The ray needs mirrors to reach the slab.",
        "Place each mirror on its own stand along the ray path so the beam bounces to the body slab.",
        "Interact with each mirror stand while holding that mirror (bathroom shard, Elvira's mirror, car mirror). The beam goes machine to shard to Elvira mirror to car mirror to slab.",
        "check", "locate" );
    step.check = ::all_mirrors_placed;
    step.locate = ::next_mirror_stand;
    step.total = 3;
    step.progress = ::mirrors_placed;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "scantron", "Put the Scantron in the machine", "Ice Cream Shop, then the spawn machine",
        "The machine in spawn needs a punch card.",
        "Take the Scantron punch card from the Ice Cream Shop, then use the ray machine in the spawn area to slot it in.",
        "Pick up the Scantron card in the Ice Cream Shop and use the ray machine in spawn once to insert it. The machine only takes its code once all six body parts have been picked up.",
        "check", "ent:mpq_punch_card" );
    step.check = ::card_inserted;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "fire_life_ray", "Fire the Life Ray", "Spawn area (ray machine)",
        "The film reel cases hold the numbers.",
        "Enter the 5-digit code from the five numbered film reel cases on the ray machine, then use it again to fire the Life Ray at the slab.",
        "Digits 3,4,5,6,8 in a random order, read from film reels 1-5. Stop the cycling counter on each digit; 3 wrong ones kick you out. The beam then needs all 6 parts on the slab and all 3 mirrors placed, or it stops early.",
        "check", "interaction:ray_gun_start" );
    step.check = ::body_made;

    step = custom_scripts\ix\guided\guided::add_step( guide, "reverse_code", "Enter the code backwards", "Spawn area (ray machine)",
        "Reverse the polarity.",
        "Use the ray machine again and enter the same film reel code in reverse order.",
        "Enter the five digits from last to first. On success the danger signs change to Death Ray signs.",
        "check", "interaction:ray_gun_start" );
    step.check = ::polarity_reversed;

    step = custom_scripts\ix\guided\guided::add_step( guide, "death_ray_key", "Fire the Death Ray, get the key", "Spawn machine, then the garage",
        "Destroy what you built, then use what it leaves.",
        "Use the ray machine once more to fire the Death Ray. Take the key from the slab and open the gas station garage with it.",
        "The Death Ray vaporizes the body and a glowing key appears on the slab: use the slab to take it. Then use the roll-up door of the gas station garage; the chemistry lab is inside.",
        "check", "interaction:garage_door" );
    step.check = ::garage_open;

    step = custom_scripts\ix\guided\guided::add_step( guide, "chem_set_parts", "Find the 3 chemistry set parts", "Random spots (marker)",
        "The lab is missing its equipment.",
        "Find the beaker, the clamp and the burner for the chemistry set.",
        "Each part spawns at one of several random spots each game. Interact to pick it up (shared for the team); then place them in the garage lab.",
        "check", "locate" );
    step.check = ::all_chem_parts;
    step.locate = ::next_chem_part;
    step.total = 3;
    step.progress = ::chem_parts_found;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "build_chem_set", "Build the chemistry set", "Gas station garage lab",
        "Assemble the lab.",
        "Add the three parts to the chemistry station in the gas station garage.",
        "Interact with the chemistry station in the garage; each part you hold is added. When all 3 are in, the computer screen lights up and the beakers appear.",
        "flag:chemistry_step1", "interaction:crafting_station_chem" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "brew_chem_mix", "Brew the Chem Mix", "Radios, then the garage lab",
        "Dr. Bright's tapes name the chemical that kills the beast.",
        "Play Dr. Bright's radio tapes to learn the compound and its elements, then make it in the lab: beakers, reaction number, start, take it.",
        "Fill the beakers with the needed elements. Reaction number: add the top and left values of each element's diamond, minus the O constant; the colour view shows which. Type it on the computer, press start and take the compound.",
        "flag:chemistry_step3", "ent:chem_computer" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "add_chem_mix", "Add Chem Mix to the bomb", "The nuke (marker)",
        "The bomb needs its payload.",
        "Carry the Chem Mix compound to the nuke and add it.",
        "Carry the bomb compound from the lab (only one chemical can be carried) and interact with the nuke. The hero photo changes on success.",
        "flag:chemistry_step4", "sn_struct:place_bomb_parts" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "set_gauges", "Set the 4 pressure gauges", "Gas station, Snack Shack, Power, Motel",
        "Four gauges around town must match four hidden numbers.",
        "Read the four numbers under the desk in the back of the Beachside Market, then hit each pressure gauge with the Crowbar to stop it on one.",
        "Gauges: behind the gas station, right side of the Snack Shack, behind the shack at the Power Station, in the Crowbar motel room. A Crowbar hit stops the swinging needle; hit again to free it. Any gauge can show any of the numbers.",
        "flag:launchcode_step1", "ents:mpq_gauge_trig" );
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "take_launch_codes", "Take the launch codes", "Beachside Market safe",
        "The safe is open.",
        "Take the nuclear launch codes from the open safe in the Beachside Market. Write the code down.",
        "Interact with the open safe in the back of the Beachside Market to take the codes. You cannot check them during code entry later, so note the 5-digit code.",
        "flag:launchcode_step2", "sn_struct:take_launchcodes" );
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "nuke_parts", "Find the 3 nuke parts", "Red car, stream end, one more",
        "The nuke's teleporter is in three pieces.",
        "Collect the three nuke teleporter parts: one under the red car, one at the end of the stream, one more.",
        "Part 1: go prone at the red car between the motel and the TV Studio (only prone works). Part 2: the end of the stream that runs under the bridge. Part 3: follow the marker.",
        "check", "locate" );
    step.check = ::all_nuke_parts;
    step.locate = ::next_nuke_part;
    step.total = 3;
    step.progress = ::nuke_parts_found;
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "build_nuke", "Build the bomb", "The nuke (marker)",
        "Bring the parts to the nuke.",
        "Place all three teleporter parts on the nuke stand.",
        "Interact with the nuke stand to place every part you hold; when the third goes in the teleporter is built.",
        "flag:launchcode_step3", "sn_struct:place_bomb_parts" );
    step.parallel = 1;

    step = custom_scripts\ix\guided\guided::add_step( guide, "charge_nuke", "Charge the bomb teleporter", "The nuke",
        "Everyone needs to power the teleporter together.",
        "All players stand at the nuke and hold Use together to start charging; defend it for 20 seconds.",
        "Requires codes taken, bomb built, Chem Mix added. Every player within 96 units holds Use. It charges for 20 s; then it stays charged only 30 s, so be ready to teleport.",
        "flag:teleporter_charged", "sn_struct:place_bomb_parts" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "teleport_nuke", "Teleport the bomb", "The nuke",
        "Send the bomb (and yourselves) to the beast.",
        "While charged, all players hold Use at the nuke again to teleport it and start the boss fight.",
        "Within 30 s of full charge, every player within 96 units holds Use. The nuke leaves and all players are sent to the beach. If the window passes, charge again.",
        "flag:launchcode_step4", "sn_struct:place_bomb_parts" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_escort", "Escort the nuke to the water", "Beach",
        "The nuke only moves while someone is next to it.",
        "Stay close to the nuke cart so it rolls down the stream to the water's edge. Shoot the egg sacs and Crogs.",
        "The cart moves only while a standing player is within ~250 units. Egg sacs fly in and hatch Crogs or explode; kill them. At the water's edge the cart slingshots the nuke into the beast.",
        "notify:escort_sequence_ended", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_cannon_hit", "Hit the weak spot with a cannon", "Beach (Death Ray cannons)",
        "The beach cannons can expose its weak spot.",
        "Mount a Death Ray cannon, hold fire to charge it and hit the glowing weak spot on the beast.",
        "Use a Death Ray cannon (left, right, centre or back). Hold fire until the charge bar fills; it fires. Aim at the weak spot on its upper back. The first hit exposes the weak spot for everyone.",
        "notify:crab_boss_weak_spot_initial_hit", "sn_structs:death_ray_cannon" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_weak_spot", "Damage the weak spot", "Beach",
        "Keep hurting the exposed weak spot.",
        "Keep shooting the weak spot until the beast recoils. Cannon hits and lock-on launchers do the most damage.",
        "Deal players x 30000 damage to the weak spot: cannon hit 15000, lock-on launcher hit 4500, other hits 1. Zombies spawn faster as it weakens. The phase ends when it recoils and heals.",
        "check", "none" );
    step.check = ::weak_spot_broken;

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_arm_cart", "Charge the cart teleporter", "Beach (nuke cart)",
        "Everyone back to the cart.",
        "All players gather at the nuke cart and hold Use together to start its teleporter charging.",
        "Every player (not downed, not carrying) within 150 units of the cart holds Use at once. This disables the cannons and starts the Wall of Death.",
        "notify:players_trigger_vehicle_teleporter", "none" );
    step.reset = "sonic_ring_fail end_detonate_bomb";

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_wall_of_death", "Survive the Wall of Death", "Beach",
        "Hold out against the toxic waves.",
        "Survive the beast's three toxic wall attacks and the zombies they bring.",
        "The beast spits three toxic walls, spawning zombies after each. Downed players are revived every 60 s until the cart is charged. Stay alive until the third wave ends.",
        "notify:wall_of_death_completed", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_sonic_beam", "Hold Use at the cart during roar", "Beach (nuke cart)",
        "When it roars, answer from the cart.",
        "When the beast starts its sonic beam, all players hold Use at the nuke cart before the countdown ends.",
        "The beam starts with a roar; you have about 12 s (7 s then a 5..1 countdown). Every player within 400 units of the cart holds Use together. Success sends everyone inside the beast; failure repeats Wall of Death.",
        "notify:sonic_ring_success", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boss_enter_codes", "Enter the launch codes", "Inside the beast",
        "Arm the nuke from the inside.",
        "Inside the beast, use your bomb panel and enter the 5-digit launch code from the safe within 30 seconds.",
        "Each player is sent to a panel. Enter the safe's 5-digit code by stopping the cycling counter on each digit; 3 wrong digits eject you (use it again). Everyone must finish in 30 s, or the beast's last attacks start over.",
        "flag:boss_fight_finished", "sn_structs:bomb_start" );

    // What only shows as a change from the start of the match.
    watch_town();

    return guide;
}

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
