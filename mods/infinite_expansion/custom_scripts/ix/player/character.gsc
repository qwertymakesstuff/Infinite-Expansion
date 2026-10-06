// Infinite Expansion - character selection.
//
// Lets each player choose who they play as. The choice is made before the
// match, in the CHARACTER menu (ui_scripts/InfiniteExpansion), and applied when
// the player connects. It lasts the whole match: there is no switching
// mid-match. Stock behaviour, read from the decompiled scripts:
//   - each map registers its cast in level.player_character_info
//     (scripts\cp\maps\<map>\<map>_player_character_setup): slots 1-4 are the
//     four regular characters, 5 (and 6 on cp_zmb) the special characters;
//   - scripts\cp\zombies\zombies_loadout::get_player_character_num() keeps
//     self.player_character_num if it is set. Otherwise it gives the special
//     character named by the player's lobby field characterSelect, on that
//     character's own map, or a random free slot from
//     level.available_player_characters;
//   - every spawn applies self.player_character_num through
//     givedefaultloadout() -> setmodelfromcustomization().
// So choosing a character means setting self.player_character_num, and
// keeping level.available_player_characters consistent, before the first
// spawn.
//
// Where a choice comes from:
//   ix_character     the host's character (number or name; "random" or unset:
//                    none). The menu sets this dvar on the player's own PC, so
//                    the server sees it only for the player hosting the match.
//   characterSelect  the stock lobby field. It is part of each player's own
//                    stats, which reach the host's match. The menu writes it
//                    for special characters, so those follow a player into
//                    other players' matches. Regular characters have no lobby
//                    value (KNOWN_LIMITATIONS.md L29): a player who joins
//                    someone else's match gets a random one.
// A choice the rules below refuse gets a random character, as in the stock
// game, and a message after the first spawn says why.
//
// Settings (unset = default):
//   ix_character_select    1   0 = off: the game picks characters as usual
//   ix_character           ""  the host's character
//   ix_character_specials  1   0 = no special characters,
//                              1 = specials the player has unlocked, 2 = all
//   ix_character_crossmap  0   1 = special characters on other maps too
//                              (experimental: KNOWN_LIMITATIONS.md L26). Read once,
//                              while the map loads, because their models can only
//                              be precached then.
//   ix_character_announce  0   1 = a "<player> is playing as <character>" line
//                              for everyone after a player's first spawn

register()
{
    level.ix.character = spawnstruct();
    level.ix.character.cast = build_cast( level.ix.map );

    if ( !isdefined( level.ix.character.cast ) )
    {
        custom_scripts\ix\core\log::info( "character selection: no cast data for " + level.ix.map );
        return;
    }

    // Precaching is only allowed while the level loads, which is now.
    level.ix.character.crossmap = custom_scripts\ix\core\util::dvar_int( "ix_character_crossmap", 0 ) != 0;

    if ( crossmap_enabled() )
        precache_crossmap_models();

    level thread watch_connects();
}

// ---------------------------------------------------------------------------
// Settings

enabled()
{
    return custom_scripts\ix\core\util::dvar_int( "ix_character_select", 1 ) != 0;
}

specials_mode()
{
    return custom_scripts\ix\core\util::dvar_int( "ix_character_specials", 1 );
}

crossmap_enabled()
{
    return level.ix.character.crossmap;
}

announce_enabled()
{
    return custom_scripts\ix\core\util::dvar_int( "ix_character_announce", 0 ) != 0;
}

// ---------------------------------------------------------------------------
// Cast data

map_title( map )
{
    switch ( map )
    {
        case "cp_zmb":
            return "Zombies in Spaceland";
        case "cp_rave":
            return "Rave in the Redwoods";
        case "cp_disco":
            return "Shaolin Shuffle";
        case "cp_town":
            return "Attack of the Radioactive Thing";
        case "cp_final":
            return "The Beast from Beyond";
    }

    return map;
}

// Outfit labels for slots 1-4, made from each map's model names
// (zmb_body_hero_valley_girl, zmb_hero_female_gangster, ...). cp_final's
// models carry only the actors' names, so it has no labels.
map_roles( map )
{
    switch ( map )
    {
        case "cp_zmb":
            return [ "Valley Girl", "Nerd", "Rapper", "Jock" ];
        case "cp_rave":
            return [ "Gangster", "Raver", "Grunge", "Hip-Hop" ];
        case "cp_disco":
            return [ "Disco", "Punk", "Activist", "Sleaze Bag" ];
        case "cp_town":
            return [ "Schoolgirl", "Scientist", "Soldier", "Rebel" ];
        case "cp_final":
            return [ "", "", "", "" ];
    }

    return undefined;
}

// The cast for a map: the four regular characters, then every special
// character. Slot -> actor is the same on every map: the stock VO code maps
// p1_ to sally, p2_ to pdex, p3_ to andre and p4_ to aj
// (cp_disco_vo.gsc, cp_town_vo.gsc), and cp_final's models are named
// sally, dexter, andre and aj.
build_cast( map )
{
    roles = map_roles( map );

    if ( !isdefined( roles ) )
        return undefined;

    cast = [];
    cast[cast.size] = make_regular( 1, "sally", "Sally", roles[0], [ "sally" ], ( 1, 0.45, 0.7 ) );
    cast[cast.size] = make_regular( 2, "poindexter", "Poindexter", roles[1], [ "poindexter", "pdex", "dexter" ], ( 0.35, 0.65, 1 ) );
    cast[cast.size] = make_regular( 3, "andre", "Andre", roles[2], [ "andre" ], ( 1, 0.6, 0.2 ) );
    cast[cast.size] = make_regular( 4, "aj", "A.J.", roles[3], [ "aj", "a.j." ], ( 0.45, 0.9, 0.35 ) );

    // Special characters, with the slot, models and photo index their home
    // map registers, the stock lobby's characterSelect value
    // (zombies_loadout::get_player_character_num), and the stat that unlocks
    // them (KNOWN_LIMITATIONS.md L27). The CHARACTER menu writes the same
    // characterSelect values (ui_scripts/InfiniteExpansion).
    cast[cast.size] = make_special( "hoff", "The Hoff", [ "hoff", "dj" ], "cp_zmb", 5, 1, "soul_key", "soul_key_1", "body_zmb_hero_dj", "viewmodel_zmb_hero_dj", "head_zmb_dj", 4 );
    cast[cast.size] = make_special( "willard", "Willard Wyler", [ "willard", "wyler" ], "cp_zmb", 6, 5, "merit", "mt_dlc4_troll2", "body_zmb_projectionist", "zmb_projectionist_viewmodel_arms", "head_zmb_projectionist", 5 );
    cast[cast.size] = make_special( "kevin", "Kevin Smith", [ "kevin", "smith" ], "cp_rave", 5, 2, "soul_key", "soul_key_2", "zmb_hero_k_smith", "viewmodel_zmb_hero_k_smith", undefined, 4 );
    cast[cast.size] = make_special( "pam", "Pam Grier", [ "pam", "grier" ], "cp_disco", 5, 3, "soul_key", "soul_key_3", "cp_disco_female_boss_pam_grier_hero", "cp_disco_female_boss_pam_grier_viewmodel_arms", undefined, 4 );
    cast[cast.size] = make_special( "elvira", "Elvira", [ "elvira" ], "cp_town", 5, 4, "soul_key", "soul_key_4", "fullbody_zmb_hero_elvira_player", "viewmodel_zmb_hero_elvira", undefined, 4 );

    foreach ( entry in cast )
    {
        if ( entry.special )
        {
            entry.native = entry.home == map;

            if ( entry.native )
                entry.num = entry.home_num;
        }
    }

    return cast;
}

make_regular( num, key, name, role, aliases, color )
{
    entry = spawnstruct();
    entry.key = key;
    entry.name = name;
    entry.role = role;
    entry.aliases = aliases;
    entry.color = color;
    entry.num = num;
    entry.special = 0;
    entry.native = 1;
    return entry;
}

make_special( key, name, aliases, home, home_num, select_id, unlock_type, unlock_field, body, view, head, photo )
{
    entry = spawnstruct();
    entry.key = key;
    entry.name = name;
    entry.role = map_title( home );
    entry.aliases = aliases;
    entry.color = ( 1, 0.82, 0.3 );
    entry.special = 1;
    entry.home = home;
    entry.home_num = home_num;
    entry.select_id = select_id;
    entry.unlock_type = unlock_type;
    entry.unlock_field = unlock_field;
    entry.body = body;
    entry.view = view;
    entry.head = head;
    entry.photo = photo;
    return entry;
}

// "Sally (Valley Girl)", or only the name where there is no outfit name.
describe( entry )
{
    if ( entry.special || entry.role == "" )
        return entry.name;

    return entry.name + " (" + entry.role + ")";
}

// The host's ix_character, or "" when the game should pick.
wanted_character()
{
    value = custom_scripts\ix\core\util::dvar_string( "ix_character", "" );

    if ( value == "random" )
        return "";

    return value;
}

find_entry( text )
{
    text = tolower( text );

    foreach ( entry in level.ix.character.cast )
    {
        if ( !entry.special && text == "" + entry.num )
            return entry;

        if ( text == entry.key )
            return entry;

        foreach ( alias in entry.aliases )
        {
            if ( text == alias )
                return entry;
        }
    }

    return undefined;
}

// The cast entry for a player_character_info slot, or undefined.
entry_for_num( num )
{
    if ( !isdefined( level.ix.character ) || !isdefined( level.ix.character.cast ) || !isdefined( num ) )
        return undefined;

    foreach ( entry in level.ix.character.cast )
    {
        if ( isdefined( entry.num ) && entry.num == num )
            return entry;
    }

    return undefined;
}

is_regular_num( num )
{
    return num >= 1 && num <= 4;
}

// ---------------------------------------------------------------------------
// Special characters from other maps (experimental)

precache_crossmap_models()
{
    foreach ( entry in level.ix.character.cast )
    {
        if ( !entry.special || entry.native )
            continue;

        precachemodel( entry.body );
        precachemodel( entry.view );

        if ( isdefined( entry.head ) )
            precachemodel( entry.head );
    }
}

// Adds the other maps' special characters to level.player_character_info
// (slots 11+). They take their models from their home map and everything
// else (knife, gestures, card, intro) from a character this map registers, so
// no weapon from another map is needed. Their VO prefix names no sound on
// this map, so they stay silent instead of speaking another character's lines
// (the stock VO code checks soundexists() first).
register_crossmap()
{
    if ( isdefined( level.ix.character.crossmap_ready ) || !isdefined( level.player_character_info ) )
        return;

    level.ix.character.crossmap_ready = 1;
    donor = level.player_character_info[5];

    if ( !isdefined( donor ) )
        donor = level.player_character_info[1];

    if ( !isdefined( donor ) )
        return;

    next = 11;

    foreach ( entry in level.ix.character.cast )
    {
        if ( !entry.special || entry.native )
            continue;

        info = spawnstruct();
        info.body_model = entry.body;
        info.view_model = entry.view;
        info.head_model = entry.head;
        info.vo_prefix = "ix_" + entry.key + "_";
        info.vo_suffix = "_ix_" + entry.key;
        info.photo_index = entry.photo;
        info.pap_gesture = donor.pap_gesture;
        info.pap_gesture_anim = donor.pap_gesture_anim;
        info.revive_gesture = donor.revive_gesture;
        info.fate_card_weapon = donor.fate_card_weapon;
        info.intro_music = donor.intro_music;
        info.intro_gesture = donor.intro_gesture;
        info.melee_weapon = donor.melee_weapon;
        info.starting_weapon = donor.starting_weapon;
        level.player_character_info[next] = info;
        entry.num = next;
        next++;
    }
}

// ---------------------------------------------------------------------------
// Rules

// Why the player cannot be this character, or undefined if they can. The
// unlock is checked for every choice, also one from the stock lobby field,
// because the CHARACTER menu cannot read the unlock stats and writes that
// field anyway.
unavailable_reason( entry )
{
    if ( entry.special )
    {
        if ( specials_mode() == 0 )
            return "special characters are off (ix_character_specials 0)";

        if ( !entry.native && !crossmap_enabled() )
            return entry.name + " belongs to " + map_title( entry.home ) + " (the host can allow it with ix_character_crossmap 1)";

        if ( !entry.native && !isdefined( entry.num ) )
            return entry.name + " could not be set up on this map";

        if ( specials_mode() == 1 && !has_unlocked( entry ) )
            return entry.name + " is locked: " + unlock_hint( entry );
    }

    other = taken_by( entry );

    if ( isdefined( other ) )
        return entry.name + " is taken by " + other.name;

    return undefined;
}

has_unlocked( entry )
{
    if ( isbot( self ) )
        return 0;

    if ( entry.unlock_type == "soul_key" )
        return self getrankedplayerdata( "cp", "haveSoulKeys", entry.unlock_field ) != 0;

    return self getrankedplayerdata( "cp", "meritState", entry.unlock_field ) > 0;
}

unlock_hint( entry )
{
    if ( entry.unlock_type == "soul_key" )
        return "earn the soul key on " + map_title( entry.home );

    return "beat the final boss of The Beast from Beyond";
}

taken_by( entry )
{
    if ( !isdefined( entry.num ) )
        return undefined;

    foreach ( player in level.players )
    {
        if ( player != self && isdefined( player.player_character_num ) && player.player_character_num == entry.num )
            return player;
    }

    return undefined;
}

// ---------------------------------------------------------------------------
// Applying a choice

// Makes entry the player's character.
assign( entry )
{
    num = entry.num;
    old = self.player_character_num;

    if ( isdefined( old ) && old == num )
        return;

    available = level.available_player_characters;

    if ( !isdefined( available ) )
        available = [];

    if ( isdefined( old ) && is_regular_num( old ) && !scripts\engine\utility::array_contains( available, old ) )
        available = scripts\engine\utility::array_add( available, old );

    if ( is_regular_num( num ) )
        available = scripts\engine\utility::array_remove( available, num );

    level.available_player_characters = only_regular( available );
    self.player_character_num = num;
}

// What the stock code does for a player without a choice: a random free
// regular character. Used when a choice was refused, because the stock code
// would otherwise still hand out a special character named in the lobby
// field, without checking the unlock or whether someone else has it.
assign_random()
{
    if ( !isdefined( level.available_player_characters ) || level.available_player_characters.size == 0 )
        return;

    entry = entry_for_num( scripts\engine\utility::random( level.available_player_characters ) );

    if ( isdefined( entry ) )
        assign( entry );
}

// The stock disconnect handler returns every slot except 5 and 6 to the
// random pool, which would include this mod's cross-map slots.
only_regular( list )
{
    result = [];

    foreach ( num in list )
    {
        if ( is_regular_num( num ) )
            result[result.size] = num;
    }

    return result;
}

// ---------------------------------------------------------------------------
// Connect: the choice is applied before the first spawn

watch_connects()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "ix_player_connected", player );

        // Own thread, so an error for one player cannot stop this loop. It never
        // waits before choosing, so it still finishes before the first spawn.
        player thread on_connect();
    }
}

on_connect()
{
    message = undefined;

    if ( enabled() )
        message = apply_choice();

    self thread announce_after_spawn( message );
}

// Applies the player's choice, if any. Returns a message for the player when
// the choice could not be honoured.
apply_choice()
{
    if ( crossmap_enabled() )
        register_crossmap();

    self thread watch_disconnect();
    message = undefined;
    entry = undefined;
    source = "lobby";

    if ( self ishost() )
    {
        wanted = wanted_character();

        if ( wanted != "" )
        {
            entry = find_entry( wanted );
            source = "ix_character";

            if ( !isdefined( entry ) )
                message = "ix_character: unknown character '" + wanted + "'";
        }
    }

    if ( !isdefined( entry ) )
    {
        entry = lobby_choice();
        source = "lobby";
    }

    if ( !isdefined( entry ) )
        return message;

    reason = unavailable_reason( entry );

    if ( isdefined( reason ) )
    {
        assign_random();
        return "Can't play as " + entry.name + ": " + reason;
    }

    assign( entry );
    custom_scripts\ix\core\log::info( "character: " + self.name + " -> " + entry.name + " (" + source + ")" );
    return message;
}

// The special character named by the player's lobby field characterSelect,
// or undefined. Set by the stock lobby and by the CHARACTER menu.
lobby_choice()
{
    if ( isbot( self ) )
        return undefined;

    value = self getrankedplayerdata( "cp", "zombiePlayerLoadout", "characterSelect" );

    if ( !isdefined( value ) )
        return undefined;

    foreach ( entry in level.ix.character.cast )
    {
        if ( entry.special && entry.select_id == value )
            return entry;
    }

    return undefined;
}

// After the first spawn and the intro: the player's own message, if any, then,
// with ix_character_announce 1, a line for everyone saying who this player is
// playing as.
announce_after_spawn( message )
{
    self endon( "disconnect" );
    self waittill( "spawned_player" );

    // The zombies gametype sets this flag when the intro ends; the stock
    // loadout waits for it the same way (zombies_loadout::givedefaultloadout).
    if ( scripts\engine\utility::flag_exist( "introscreen_over" ) )
        scripts\engine\utility::flag_wait( "introscreen_over" );

    wait 2;

    if ( isdefined( message ) )
        self iprintln( message );

    if ( !announce_enabled() )
        return;

    entry = entry_for_num( self.player_character_num );

    if ( !isdefined( entry ) )
        return;

    text = self.name + " is playing as " + describe( entry );

    foreach ( player in level.players )
        player iprintln( text );
}

watch_disconnect()
{
    self waittill( "disconnect" );
    level thread clean_pool_after_disconnect();
}

// Runs on level: the disconnecting player's entity goes away.
clean_pool_after_disconnect()
{
    waittillframeend;

    if ( isdefined( level.available_player_characters ) )
        level.available_player_characters = only_regular( level.available_player_characters );
}
