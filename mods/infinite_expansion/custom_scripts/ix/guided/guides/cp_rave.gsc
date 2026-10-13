// Infinite Expansion - Guided Mode guide: Rave in the Redwoods (cp_rave).
//
// The main quest is the game's quest lines "jmem" (cp_rave_j_mem_quest.gsc in
// scripts/cp/maps/cp_rave: Jay's memories, three rituals) and "superslasher"
// (cp_rave_super_slasher_fight.gsc), after the power, the boat and the
// projector (Pack-a-Punch). Every signal and marker is the stock scripts' own
// (research: scratchpad guided/cp_rave.md, TESTING.md V150). Steps the game
// keeps in fields the v1.1.0 compiler cannot name (KNOWN_LIMITATIONS.md C10:
// boat parts, film reels, meeting Kevin, the photos) follow from the next
// step the game reports. Nothing here changes the quest.

guide()
{
    guide = custom_scripts\ix\guided\guided::new_guide( "cp_rave", "Rave in the Redwoods", "The Super Slasher", "Solo or co-op. Power, the boat and the projector come first." );

    step = custom_scripts\ix\guided\guided::add_step( guide, "power_on", "Turn on the power", "Generator room, Old Hudson Mine",
        "The power switch is deep underground, past the old mine.",
        "Go through the Old Hudson Mine below the Spawn Lodge to the generator room and pull the power switch.",
        "Open the path from the Spawn Lodge basement into the Old Hudson Mine. Take the lower path to the generator room, where a zombie is strung up on a wooden wheel, and pull the switch. Power also opens the cellar door in the lodge.",
        "notify:activate_power", "sn_structs:generator" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boat_parts", "Find the 3 boat motor parts", "Mess Hall / Recreation Area",
        "The broken boat at White Tail Beach is missing its motor parts.",
        "Collect the three boat motor parts (propeller, engine, tiller) around the camp. One is in the Mess Hall; another is in the Recreation Area.",
        "Collect the propeller, engine and tiller parts. Guides put one in the Mess Hall by spawn and one in the Recreation Area, either beside the red/white-flag tent or upstairs near Tuff Nuff. Guides disagree on the third. Follow the markers.",
        "manual", "locate" );
    step.locate = ::boat_part;

    step = custom_scripts\ix\guided\guided::add_step( guide, "ride_boat", "Take the boat to Turtle Island", "White Tail Beach boat",
        "With the motor fixed, the boat can take you across the lake.",
        "Use the repaired boat at White Tail Beach to ride to Turtle Island. The boat drops you off and returns to the dock by itself.",
        "Use the boat at White Tail Beach; it leaves about 5 s after the first player boards. It drops riders on Turtle Island and returns to the dock. At least one trip is needed: Kevin can only board the boat later once it has docked after a trip.",
        "check", "locate" );
    step.check = ::boat_started;
    step.locate = ::boat;

    step = custom_scripts\ix\guided\guided::add_step( guide, "film_reels", "Find the 2 film reels", "White Tail Beach dock / Turtle Island",
        "The projector on Turtle Island needs two film reels.",
        "Find two film reels: one by the docks next to White Tail Beach, one on Turtle Island outside the cabin near the bonfire.",
        "Reel 1 is reportedly in the docks next to White Tail Beach. Reel 2 is on Turtle Island, outside the cabin near the bonfire. The pickups have no hint text (pap_quest_hint_func returns ''), so press use on the reel model itself.",
        "manual", "locate" );
    step.locate = ::film_reel;

    step = custom_scripts\ix\guided\guided::add_step( guide, "fix_projector", "Repair the projector", "Projector room, Turtle Island cabin",
        "Bring the reels to the projector in the island cabin.",
        "In the Turtle Island cabin's projector room, use the projector with both reels to restore it and open the Pack-a-Punch portal.",
        "With both reels, go to the projector room in the Turtle Island cabin and use the projector. It loads the reels and opens a wall portal to the Pack-a-Punch room. Kevin's radio is in this same room (next step).",
        "flag:pap_fixed", "locate" );
    step.locate = ::projector;

    step = custom_scripts\ix\guided\guided::add_step( guide, "talk_kevin", "Talk to Kevin Smith", "Projector room radio, Turtle Island",
        "Someone is calling for help in the projector room.",
        "Use the radio in the Turtle Island projector room to talk to Kevin Smith. This starts the Easter egg proper.",
        "In the projector room of the Turtle Island cabin, interact with the radio to talk to Kevin Smith. Wait for his dialogue to finish; the first memento only becomes collectable after a player has met him.",
        "manual", "sn_structs:survivor_interaction" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "find_photo_1", "Find the first photo", "Recreation Area, upper level",
        "Kevin's lost memento lies where the rave takes place.",
        "Search the upper level of the Recreation Area (the rave area). The photo is lying on the floor; pick it up.",
        "Go to the Recreation Area, where the rave is held, and climb to the upper level. The photo is on the floor; use it. Kevin's memory VO plays.",
        "manual", "ent:j_mem_1" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "ritual_arms", "Do the bonfire ritual (arms)", "Adventure Course bonfire",
        "The photo needs to be charged at a ritual fire.",
        "Place the photo at the Adventure Course bonfire with everyone nearby, shoot zombies' arms off, then kill the Slasher.",
        "All players near and out of Rave Mode, hold to place the photo. Dismember 10 zombie arms within 60 s. Grab the glowing photo within 30 s. Kill the Slasher within 60 s and inspect the photo again. A failed ritual nukes and costs a perk; you can retry.",
        "flag:photo_1_kev_given", "struct:circle_org_arm" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "give_photo_1", "Give the photo to Kevin", "Projector room radio, Turtle Island",
        "Kevin will want to hear about that memory.",
        "Return to the Turtle Island projector room and talk to Kevin on the radio to hand over the charged photo.",
        "Go back to the projector room radio on Turtle Island and interact with it. Kevin reacts to the photo's memory; let his dialogue finish. After that, the second memento can be collected.",
        "flag:photo_1_kev_vo_done", "sn_structs:survivor_interaction" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "find_photo_2", "Find the second photo", "Spawn cabin balcony (Tuff Nuff room)",
        "Another memento lies on a balcony near where you started.",
        "Go upstairs in the spawn cabin and out onto the balcony outside the room with the Tuff Nuff machine. Pick up the photo.",
        "From the main spawn cabin, go upstairs to the room with the Tuff Nuff perk machine and step out onto its balcony. The second photo is on the balcony; use it.",
        "manual", "ent:j_mem_2" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "ritual_legs", "Do the Quickies ritual (legs)", "Recreation Area, Quickies machine",
        "Charge the second photo at another ritual site in the rave area.",
        "Place the photo in front of Quickies in the Recreation Area, blow zombies' legs off (explosives help), then kill the Slasher.",
        "All players near and out of Rave Mode, hold to place the photo at Quickies. Remove 10 zombie legs within 60 s (explosives work well). Grab the glowing photo within 30 s. Kill the Slasher within 60 s and inspect the photo. A failure costs a perk; you can retry.",
        "flag:photo_2_kev_given", "struct:circle_org_leg" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "give_photo_2", "Give the photo to Kevin", "Projector room radio, Turtle Island",
        "Kevin should see this memory too.",
        "Talk to Kevin on the Turtle Island projector room radio again to hand over the second photo.",
        "Return to the projector room radio on Turtle Island and interact with it. Let Kevin's dialogue about the second memory finish; the final memento then becomes collectable.",
        "flag:photo_2_kev_vo_done", "sn_structs:survivor_interaction" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "find_skull", "Find the skull", "Generator room, by the zombie wheel",
        "The last memento waits where the power comes from.",
        "Go back to the generator (power switch) room and pick up the skull on the floor beside the wheel with the zombie on it.",
        "Return to the generator room in the Old Hudson Mine where you pulled the power switch. The final memento, a skull, is on the floor beside the wooden wheel with the zombie strung on it. Pick it up.",
        "manual", "ent:j_mem_3" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "ritual_heads", "Do the Bang Bang ritual (heads)", "Bear Lake, Bang Bang machine",
        "The skull needs a ritual at the lake.",
        "Place the skull in front of the Bang Bang machine at Bear Lake, score headshot kills that pop heads, then kill the Slasher.",
        "All players near and out of Rave Mode, hold to place the skull at Bang Bang. Get 10 head-popping headshots within 60 s. Grab the charged skull within 30 s. Kill the Slasher within 60 s and inspect the skull. Kevin is then taken, so there is no hand-in.",
        "flag:survivor_trapped", "struct:circle_org_head" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "free_kevin", "Free Kevin from the cellar", "Power room switches",
        "Kevin is trapped. Listen for pounding and find the switches.",
        "Kevin is locked in the cellar. In the power room, every player must hold one of the unlit switches at the same time.",
        "Unlit switches in the power room are the ones to use, one per player (solo: one). Every player holds use on a different unlit switch at the same time, within arm's reach, until a buzzer sounds. Kevin teleports to the boat.",
        "flag:survivor_released", "none" );

    step = custom_scripts\ix\guided\guided::add_step( guide, "boat_with_kevin", "Ride the boat with Kevin", "White Tail Beach boat",
        "Kevin is waiting on the boat. Don't leave anyone behind.",
        "Go to the boat at White Tail Beach where Kevin is waiting. All players must stand by the boat before using it.",
        "Kevin waits in the docked boat at White Tail Beach. Gather every player (none downed) right next to the boat, then use it; if anyone is missing, Kevin nags and the boat stays. On the lake Kevin falls overboard and the Super Slasher rises.",
        "flag:survivor_got_to_island", "locate" );
    step.locate = ::boat;

    step = custom_scripts\ix\guided\guided::add_step( guide, "kill_super_slasher", "Defeat the Super Slasher", "Turtle Island",
        "Fill the soul charms, trap him, and break his weak spots.",
        "On Turtle Island, fill the soul charms in Rave Mode, lure him into the trap, shoot the glowing weak spots. Repeat 3 times, then kill him.",
        "In Rave Mode, kill zombies near the floating charms until all are full. Lead him into the open trap and shoot the chest weak spot. Shoot the 8 glowing weak spots in turn. In shockwaves, stand in a safe circle and kill skeletons. Round 3: kill him.",
        "flag:super_slasher_fight_complete", "locate" );
    step.locate = ::super_slasher;

    step = custom_scripts\ix\guided\guided::add_step( guide, "soul_key", "Pick up the Soul Key", "Turtle Island",
        "He dropped something important.",
        "About 8 seconds after the Super Slasher dies, a glowing Soul Key appears where he fell. Pick it up to finish the Easter egg.",
        "Wait about 8 s after the death animation; the Soul Key spawns, rotating, at his death spot. Use it. Every player is credited with Soul Key 2, the outro cutscene plays, and normal rounds resume about 37 s later.",
        "check", "locate" );
    step.check = ::soul_key_taken;
    step.locate = ::soul_key;

    return guide;
}
// ---------------------------------------------------------------------------
// Checks and markers (self = the player)

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

// cp_rave_interactions.gsc: a part's struct holds its model until taken.
boat_part()
{
    return self pieces_left( "boat_quest_piece" );
}

film_reel()
{
    return self pieces_left( "pap_quest_piece" );
}

pieces_left( name )
{
    left = [];

    foreach ( piece in scripts\engine\utility::getstructarray( name, "script_noteworthy" ) )
    {
        if ( isdefined( piece.model ) )
            left[left.size] = piece;
    }

    return self custom_scripts\ix\guided\panel::nearest_origin( left );
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
