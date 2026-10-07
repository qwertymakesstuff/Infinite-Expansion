// Infinite Expansion - character selection.
//
// Lets each player choose who they play as. The choice is made before the
// match, in the CHARACTER menu of the zombies lobby (ui_scripts/InfiniteExpansion),
// and applied on the player's first spawn. It lasts the whole match: there is
// no switching mid-match. Stock behaviour, read from the decompiled scripts:
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
// keeping level.available_player_characters consistent, before the stock code
// reads it on the first spawn. The mod replaces get_player_character_num()
// itself (iw7-mod's replacefunc), so the choice is made at the moment the
// stock code asks for it; see character_num_for_spawn().
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
// Settings (config.gsc; console: set ix_<id> <value>, chat: !ix set <id> <value>):
//   character_select    1   0 = off: the game picks characters as usual. From the
//                           next map: the stock function is replaced, or not, while
//                           the map loads
//   character_specials  1   0 = no special characters,
//                           1 = specials the player has unlocked, 2 = all
//   character_crossmap  0   1 = special characters on other maps too
//                           (experimental: KNOWN_LIMITATIONS.md L26). From the next
//                           map, because their models can only be precached while
//                           it loads
//   character_announce  0   1 = a "<player> is playing as <character>" line
//                           for everyone after a player's first spawn
// ix_character (the host's pick) is not a setting: the CHARACTER menu sets it.

register()
{
    custom_scripts\ix\core\config::add_bool( "character_select", 1, "Character selection", "Players start as the character they chose in the lobby. Takes effect from the next map.", undefined );
    custom_scripts\ix\core\config::add_int( "character_specials", 1, 0, 2, "Special characters", "0 = none, 1 = the ones each player has unlocked, 2 = all of them.", undefined );
    custom_scripts\ix\core\config::add_bool( "character_crossmap", 0, "Special characters on any map", "Experimental: their models may be missing on other maps. Takes effect from the next map.", undefined );
    custom_scripts\ix\core\config::add_bool( "character_announce", 0, "Announce characters", "A line for everyone saying who each player is playing as.", undefined );

    level.ix.character = spawnstruct();
    level.ix.character.cast = build_cast( level.ix.map );

    if ( !isdefined( level.ix.character.cast ) )
    {
        custom_scripts\ix\core\log::info( "character selection: no cast data for " + level.ix.map );
        return;
    }

    // Precaching is only allowed while the level loads, which is now.
    level.ix.character.crossmap = custom_scripts\ix\core\config::get( "character_crossmap" );

    if ( crossmap_enabled() )
        precache_crossmap_models();

    // With selection off the stock function stays, and the game picks as usual.
    if ( !enabled() )
    {
        custom_scripts\ix\core\log::info( "character selection: off (ix_character_select 0)" );
        return;
    }

    replacefunc( scripts\cp\zombies\zombies_loadout::get_player_character_num, ::character_num_for_spawn );
    custom_scripts\ix\core\log::info( "character selection: on" );
}

// ---------------------------------------------------------------------------
// Settings

enabled()
{
    return custom_scripts\ix\core\config::get( "character_select" );
}

specials_mode()
{
    return custom_scripts\ix\core\config::get( "character_specials" );
}

crossmap_enabled()
{
    return level.ix.character.crossmap;
}

announce_enabled()
{
    return custom_scripts\ix\core\config::get( "character_announce" );
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
    // (zombies_loadout::get_player_character_num), and the stats that unlock
    // them. The stock lobby (ui/frontend/cp/cpprivatematchmenu.lua) sets
    // characterSelect only with these stats: a map's soul key for its special,
    // and for Willard soul key 5 plus the merit for beating The Beast from
    // Beyond's final boss (it also requires Director's Cut, which this mod
    // does not; KNOWN_LIMITATIONS.md L27). The CHARACTER menu reads the same
    // stats and writes the same characterSelect values
    // (ui_scripts/InfiniteExpansion).
    cast[cast.size] = make_special( "hoff", "The Hoff", [ "hoff", "dj" ], "cp_zmb", 5, 1, "soul_key_1", undefined, "body_zmb_hero_dj", "viewmodel_zmb_hero_dj", "head_zmb_dj", 4 );
    cast[cast.size] = make_special( "willard", "Willard Wyler", [ "willard", "wyler" ], "cp_zmb", 6, 5, "soul_key_5", "mt_dlc4_troll2", "body_zmb_projectionist", "zmb_projectionist_viewmodel_arms", "head_zmb_projectionist", 5 );
    cast[cast.size] = make_special( "kevin", "Kevin Smith", [ "kevin", "smith" ], "cp_rave", 5, 2, "soul_key_2", undefined, "zmb_hero_k_smith", "viewmodel_zmb_hero_k_smith", undefined, 4 );
    cast[cast.size] = make_special( "pam", "Pam Grier", [ "pam", "grier" ], "cp_disco", 5, 3, "soul_key_3", undefined, "cp_disco_female_boss_pam_grier_hero", "cp_disco_female_boss_pam_grier_viewmodel_arms", undefined, 4 );
    cast[cast.size] = make_special( "elvira", "Elvira", [ "elvira" ], "cp_town", 5, 4, "soul_key_4", undefined, "fullbody_zmb_hero_elvira_player", "viewmodel_zmb_hero_elvira", undefined, 4 );

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

make_special( key, name, aliases, home, home_num, select_id, soul_key, merit, body, view, head, photo )
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
    entry.soul_key = soul_key;
    entry.merit = merit;
    entry.body = body;
    entry.view = view;
    entry.head = head;
    entry.photo = photo;
    return entry;
}

// The stock HUD's character cards (KNOWN_LIMITATIONS.md L28): a main card and a
// small square team card per slot, named in each map's playercash_images table.
// Their materials are in the map's techsets zone, which loads with every match
// on that map, for every player. The setup's picture pack copies the same cards
// (installer/IXPictures.Core.ps1; tools/tests/test_character_data.py checks
// that both use the same names). Returns the parts around kind and slot:
// parts[0] + kind + parts[1] + slot + parts[2].
card_name_parts( map )
{
    switch ( map )
    {
        case "cp_zmb":
            return [ "zm_pc_score_", "_plyr_", "" ];
        case "cp_rave":
            return [ "zm_", "_plyr_", "_dlc1" ];
        case "cp_disco":
            return [ "zm_", "_plyr_", "_dlc2" ];
        case "cp_town":
            return [ "zm_", "_plyr_", "_dlc3" ];
        case "cp_final":
            return [ "zm_", "_plyr_", "_dlc4" ];
    }

    return undefined;
}

// The material of a character's card on this map, kind "main" or "team", or
// undefined: a special character from another map has no card loaded here.
card_material( entry, kind )
{
    if ( !isdefined( entry ) || !entry.native || !isdefined( entry.num ) )
        return undefined;

    // Willard Wyler's cards are in patch_cp_zmb, named after the last map.
    if ( entry.key == "willard" )
        return "zm_" + kind + "_plyr_6_dlc4";

    parts = card_name_parts( level.ix.map );

    if ( !isdefined( parts ) )
        return undefined;

    return parts[0] + kind + parts[1] + entry.num + parts[2];
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
// CHARACTER menu already refuses locked special characters, but the unlock is
// checked here for every choice too: ix_character can be set in the console,
// and the lobby field comes from each player's own game.
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

    if ( self getrankedplayerdata( "cp", "haveSoulKeys", entry.soul_key ) == 0 )
        return 0;

    if ( isdefined( entry.merit ) && self getrankedplayerdata( "cp", "meritState", entry.merit ) <= 0 )
        return 0;

    return 1;
}

unlock_hint( entry )
{
    if ( isdefined( entry.merit ) )
        return "beat the final boss of The Beast from Beyond";

    return "earn the soul key on " + map_title( entry.home );
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
// When the choice is applied: when the stock code asks for it
//
// The stock code picks a character with
// zombies_loadout::get_player_character_num(), called on the player inside
// givedefaultloadout() on every spawn (and once more on cp_rave after the
// intro). It keeps the number in self.player_character_num. Two earlier ways
// of choosing before that call did not hold in-game (KNOWN_LIMITATIONS.md L36):
// a choice made from a notify after "connected" arrived after the first spawn,
// and wrapping level.custom_giveloadout depends on when the gametype sets it.
// So register() replaces the stock function with this one. iw7-mod's
// replacefunc sends every call of the stock function here, for the whole level
// load (gsc/script_extension.cpp); the stock function itself can no longer be
// called, so this one also does its work for players without a choice.

character_num_for_spawn()
{
    if ( !isdefined( self.player_character_num ) )
        self choose_once();

    if ( !isdefined( self.player_character_num ) )
        self pick_random_character();

    return self.player_character_num;
}

// Makes the player's choice once per match. Also starts the message thread,
// which catches the first spawn: this runs inside that spawn's loadout,
// before its "spawned_player".
choose_once()
{
    if ( isdefined( self.ix_character_chosen ) )
        return;

    self.ix_character_chosen = 1;
    message = apply_choice();
    self thread announce_after_spawn( message );
}

// The stock function's pick for a player without a choice: a random free
// regular character, taken out of the pool. Needs nothing from this mod, so it
// works even if the rest of the module did not start.
pick_random_character()
{
    if ( isdefined( level.available_player_characters ) && level.available_player_characters.size > 0 )
    {
        num = scripts\engine\utility::random( level.available_player_characters );
        level.available_player_characters = scripts\engine\utility::array_remove( level.available_player_characters, num );
    }
    else
    {
        // Every regular character is taken: share one, as the stock code would.
        num = scripts\engine\utility::random( [ 1, 2, 3, 4 ] );
    }

    self.player_character_num = num;
}

// Applies the player's choice, if any. Returns a message for the player when
// the choice could not be honoured. Every outcome is logged, so the console
// (and iw7-mod/logs/console.log) shows why a player got their character.
apply_choice()
{
    if ( !isdefined( level.ix ) || !isdefined( level.ix.character ) || !isdefined( level.ix.character.cast ) )
        return undefined;

    if ( crossmap_enabled() )
        register_crossmap();

    self thread watch_disconnect();
    message = undefined;
    entry = undefined;
    source = "lobby";
    is_host = self ishost();

    if ( is_host )
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
    {
        custom_scripts\ix\core\log::info( "character: " + self.name + ": no choice (" + choice_sources( is_host ) + "); the game picks" );
        return message;
    }

    reason = unavailable_reason( entry );

    if ( isdefined( reason ) )
    {
        assign_random();
        custom_scripts\ix\core\log::info( "character: " + self.name + " can't play as " + entry.name + " (" + source + "): " + reason );
        return "Can't play as " + entry.name + ": " + reason;
    }

    assign( entry );
    custom_scripts\ix\core\log::info( "character: " + self.name + " -> " + entry.name + " (" + source + ")" );
    return message;
}

// What the player's choice was read from, for the log.
choice_sources( is_host )
{
    text = "host " + is_host;

    if ( is_host )
        text += ", ix_character '" + getdvar( "ix_character" ) + "'";

    if ( !isbot( self ) )
        text += ", lobby characterSelect " + self getrankedplayerdata( "cp", "zombiePlayerLoadout", "characterSelect" );

    return text;
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
