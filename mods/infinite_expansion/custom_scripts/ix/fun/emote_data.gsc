// Infinite Expansion - the emotes of each map (Phase 14), data only.
//
// An emote is an animation this map itself plays on players, so it is
// certainly loaded here (IW_API_NOTES.md section 23; checked against the stock
// scripts by tools/tests/test_emotes.py):
//   offhand  a character gesture "thrown" as an off-hand weapon, as the game
//            plays it (scripts\cp\utility::firegesturegrenade): the character's
//            Pack-a-Punch celebration, their entrance at the start of the
//            match, their Fate & Fortune card trick. Each map registers these
//            for its characters (<map>_player_character_setup.gsc), so every
//            character's are loaded there, whoever plays.
//   gesture  a hand gesture the map plays on the view model
//            (playgestureviewmodel), with the third-person body event the
//            stock gesture_activate plays with it (zombies_pillage.gsc).
// Other maps' animations are not loaded here, and IW7 has no dances or props
// a script can use (KNOWN_LIMITATIONS.md L64): no emote is invented.
//
// Each emote: id (saved in favorites, at most six letters: seven of them fit
// what persist.gsc saves), name (menu row), short (wheel),
// category, kind, asset, help, and for timing either seconds or a gesture
// whose length the game knows (length), and for a card its sound.

catalog( map )
{
    list = [];

    switch ( map )
    {
        case "cp_zmb":
            who = [ "Sally", "Poindexter", "Andre", "A.J.", "The Hoff", "Willard" ];
            pap = [ "iw7_pap_zm_vgirl", "iw7_pap_zm_nerd", "iw7_pap_zm_rapper", "iw7_pap_zm_jock", "iw7_pap_zm_hoff", "iw7_pap_zm_wyler" ];
            intro = [ "iw7_loadoutvalley_zm", "iw7_loadoutnerd_zm", "iw7_loadoutrapper_zm", "iw7_loadoutjock_zm", "iw7_loadouthoff_zm", "iw7_loadoutwyler_zm" ];
            card = [ "iw7_valleygirlcard_zm", "iw7_nerdcard_zm", "iw7_rappercard_zm", "iw7_jockcard_zm", "iw7_hoffcard_zm", "iw7_wylercard_zm" ];
            list = add_cast( list, who, pap, intro, [], card );
            list = add_gesture( list, "horns", "Devil Horns", "Horns", "Taunts", "ges_devil_horns_zm", "Devil horns, as Spaceland's DJ quest plays them." );
            break;
        case "cp_rave":
            who = [ "Sally", "Poindexter", "Andre", "A.J.", "Kevin Smith" ];
            pap = [ "iw7_pap_zm_chola", "iw7_pap_zm_raver", "iw7_pap_zm_grunge", "iw7_pap_zm_hiphop", "iw7_pap_zm_survivor" ];
            intro = [ "iw7_loadout_zm_chola", "iw7_loadout_zm_raver", "iw7_loadout_zm_grunge", "iw7_loadout_zm_hiphop", "iw7_loadout_zm_survivor" ];
            length = [ "ges_load_in_chola", "ges_load_in_raver", "ges_load_in_grunge", "ges_load_in_hiphop", "ges_load_in_survivor" ];
            card = [ "iw7_cholacard_zm", "iw7_ravercard_zm", "iw7_grungecard_zm", "iw7_hiphopcard_zm", "iw7_survivorcard_zm" ];
            list = add_cast( list, who, pap, intro, length, card );
            break;
        case "cp_disco":
            // Every Shaolin Shuffle character has A.J.'s Pack-a-Punch gesture
            // and a Spaceland card; Pam Grier's entrance is chosen at random
            // (cp_disco_player_character_setup.gsc), so it is left out.
            who = [ "Sally", "Poindexter", "Andre", "A.J." ];
            intro = [ "iw7_loadout_zm_disco_chick", "iw7_loadout_zm_punk", "iw7_loadout_zm_panther", "iw7_loadout_zm_pusher" ];
            length = [ "ges_load_in_disco_chick", "ges_load_in_punk", "ges_plyr_gesture008", "ges_plyr_gesture034" ];
            list = add_cast( list, who, [], intro, length, [] );
            list = add_card( list, "card1", "Sally", "iw7_valleygirlcard_zm" );
            list = add_card( list, "card2", "Poindexter", "iw7_nerdcard_zm" );
            list = add_card( list, "card3", "Andre", "iw7_rappercard_zm" );
            list = add_card( list, "card4", "A.J.", "iw7_jockcard_zm" );
            list = add_card( list, "card5", "Pam Grier", "iw7_hoffcard_zm" );
            list = add_pap( list, "pap", "Everyone", "iw7_pap_zm_jock" );
            list = add_gesture( list, "bang", "Bang", "Bang", "Taunts", "ges_plyr_gesture010", "The Bang gesture of Infinite Warfare's multiplayer." );
            list = add_gesture( list, "crush", "Crush", "Crush", "Taunts", "ges_plyr_gesture042", "The Crush gesture of Infinite Warfare's multiplayer." );
            list = add_gesture( list, "head", "Head Crush", "Head Crush", "Taunts", "ges_plyr_gesture002", "The Head Crush gesture of Infinite Warfare's multiplayer." );
            list = add_gesture( list, "begone", "Begone", "Begone", "Taunts", "ges_plyr_gesture041", "The Begone gesture of Infinite Warfare's multiplayer." );
            list = add_gesture( list, "no", "No", "No", "Taunts", "ges_plyr_gesture001", "The No gesture of Infinite Warfare's multiplayer." );
            break;
        case "cp_town":
            who = [ "Sally", "Poindexter", "Andre", "A.J.", "Elvira" ];
            pap = [ "iw7_pap_zm_school_girl", "iw7_pap_zm_scientist", "iw7_pap_zm_soldier", "iw7_pap_zm_rebel", "iw7_pap_zm_elvira" ];
            intro = [ "iw7_loadoutschoolgirl_zm", "iw7_loadoutscientist_zm", "iw7_loadoutsoldier_zm", "iw7_loadoutrebel_zm", "iw7_loadoutelvira_zm" ];
            length = [ "ges_load_in_schoolgirl", "ges_load_in_scientist", "ges_load_in_soldier", "ges_load_in_rebel", "ges_load_in_elvira" ];
            card = [ "iw7_schoolgirlcard_zm", "iw7_scientistcard_zm", "iw7_soldiercard_zm", "iw7_rebelcard_zm", "iw7_elviracard_zm" ];
            list = add_cast( list, who, pap, intro, length, card );
            list = add_gesture( list, "thumbs", "Thumbs Up", "Thumbs Up", "Greetings", "ges_thumbs_up_mp", "A thumbs up." );
            list = add_gesture( list, "point", "Point", "Point", "Greetings", "ges_point_gun", "Point with your gun, as the chemistry lab has you do." );
            break;
        case "cp_final":
            // The four share one of each (cp_final_player_character_setup.gsc).
            list = add_pap( list, "pap", "Everyone", "iw7_dlc4pap_zm" );
            list = add_intro( list, "intro", "Everyone", "iw7_dlc4loadin_zm", "ges_load_in_arx" );
            list = add_card( list, "card", "Everyone", "iw7_dlc4card_zm" );
            break;
    }

    return list;
}

// The order the browse pages list them in; a category without emotes on this
// map is left out.
categories()
{
    return [ "Celebration", "Poses", "Greetings", "Taunts", "Funny" ];
}

// ---------------------------------------------------------------------------
// Making the entries

add_cast( list, who, pap, intro, length, card )
{
    for ( i = 0; i < who.size; i++ )
    {
        if ( i < pap.size )
            list = add_pap( list, "pap" + ( i + 1 ), who[i], pap[i] );

        if ( i < intro.size )
        {
            gesture = undefined;

            if ( i < length.size )
                gesture = length[i];

            list = add_intro( list, "intro" + ( i + 1 ), who[i], intro[i], gesture );
        }

        if ( i < card.size )
            list = add_card( list, "card" + ( i + 1 ), who[i], card[i] );
    }

    return list;
}

add_pap( list, id, who, asset )
{
    if ( who == "Everyone" )
        emote = new_emote( id, "Pack-a-Punch", "PaP", "Celebration", "offhand", asset, "The Pack-a-Punch celebration, as the game plays it when a weapon is upgraded." );
    else
        emote = new_emote( id, who + ": Pack-a-Punch", short_name( who ) + " PaP", "Celebration", "offhand", asset, who + "'s own Pack-a-Punch celebration, as the game plays it when a weapon is upgraded." );

    emote.seconds = 3.5;
    list[list.size] = emote;
    return list;
}

add_intro( list, id, who, asset, length )
{
    if ( who == "Everyone" )
        emote = new_emote( id, "Entrance", "Entrance", "Poses", "offhand", asset, "The entrance from the start of the match, again." );
    else
        emote = new_emote( id, who + ": Entrance", short_name( who ) + " entry", "Poses", "offhand", asset, who + "'s entrance from the start of the match, again." );

    emote.length = length;
    emote.seconds = 3;
    list[list.size] = emote;
    return list;
}

add_card( list, id, who, asset )
{
    if ( who == "Everyone" )
        emote = new_emote( id, "Card trick", "Card trick", "Funny", "offhand", asset, "How a Fate & Fortune card is played, with its sound. No card is used." );
    else
        emote = new_emote( id, who + ": Card trick", short_name( who ) + " card", "Funny", "offhand", asset, "How " + who + " plays a Fate & Fortune card, with its sound. No card is used." );

    emote.sound = card_sound( asset );
    emote.seconds = 3;
    list[list.size] = emote;
    return list;
}

add_gesture( list, id, name, short, category, asset, help )
{
    emote = new_emote( id, name, short, category, "gesture", asset, help );
    emote.length = asset;
    emote.seconds = 2;
    list[list.size] = emote;
    return list;
}

new_emote( id, name, short, category, kind, asset, help )
{
    emote = spawnstruct();
    emote.id = id;
    emote.name = name;
    emote.wheel_name = short;
    emote.category = category;
    emote.kind = kind;
    emote.asset = asset;
    emote.help = help;
    return emote;
}

// Names short enough for the wheel.
short_name( who )
{
    switch ( who )
    {
        case "The Hoff":
            return "Hoff";
        case "Kevin Smith":
            return "Kevin";
        case "Pam Grier":
            return "Pam";
    }

    return who;
}

// The sound the game plays with each card's gesture
// (zombies_consumables.gsc play_consumable_activate_sound; its default for
// the rest).
card_sound( asset )
{
    switch ( asset )
    {
        case "iw7_jockcard_zm":
            return "wondercard_jock_use_gesture";
        case "iw7_nerdcard_zm":
            return "wondercard_nerd_use_gesture";
        case "iw7_valleygirlcard_zm":
            return "wondercard_valleygirl_use_gesture";
        case "iw7_rappercard_zm":
            return "wondercard_rapper_use_gesture";
        case "iw7_grungecard_zm":
            return "wondercard_gesture_grunge";
        case "iw7_cholacard_zm":
            return "wondercard_gesture_chola";
        case "iw7_ravercard_zm":
            return "wondercard_gesture_raver";
        case "iw7_hiphopcard_zm":
            return "wondercard_gesture_hiphop";
        case "iw7_survivorcard_zm":
            return "wondercard_gesture_survivor";
        case "iw7_wylercard_zm":
            return "vm_gest_zmb_willard_wondercard";
    }

    return "wondercard_jock_use_gesture";
}
