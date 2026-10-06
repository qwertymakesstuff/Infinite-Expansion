// Infinite Expansion - character selection.
//
// Lets each player choose who they play as. Stock behaviour, read from the
// decompiled scripts:
//   - each map registers its cast in level.player_character_info
//     (scripts\cp\maps\<map>\<map>_player_character_setup): slots 1-4 are the
//     four regular characters, 5 (and 6 on cp_zmb) the special characters;
//   - scripts\cp\zombies\zombies_loadout::get_player_character_num() keeps
//     self.player_character_num if it is set, and otherwise takes a random free
//     slot from level.available_player_characters;
//   - every spawn re-applies self.player_character_num through
//     givedefaultloadout() -> setmodelfromcustomization().
// So choosing a character means keeping level.available_player_characters
// consistent, setting self.player_character_num, and re-running
// setmodelfromcustomization() for a player who is already in the game.
//
// Ways to choose:
//   chat    "!char" lists this map's cast; "!char <number or name>" picks one
//   dvar    ix_character <number or name>: the host's character, applied on
//           connect and whenever the dvar changes
//   lobby   a special character picked in the stock lobby is also honoured on
//           other maps while ix_character_crossmap is 1
//
// Settings (unset = default):
//   ix_character_select    1   0 = off: the game picks characters as usual
//   ix_character           ""  the host's character
//   ix_character_specials  1   0 = never offer special characters,
//                              1 = specials the player has unlocked, 2 = all
//   ix_character_crossmap  0   1 = special characters from other maps
//                              (experimental: KNOWN_LIMITATIONS.md L26). Read once,
//                              while the map loads, because their models can only
//                              be precached then.

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
    level thread watch_chat( "say" );
    level thread watch_chat( "say_team" );
    level thread watch_host_setting();
}

// ---------------------------------------------------------------------------
// Settings

enabled()
{
    return isdefined( level.ix.character.cast ) && custom_scripts\ix\core\util::dvar_int( "ix_character_select", 1 ) != 0;
}

specials_mode()
{
    return custom_scripts\ix\core\util::dvar_int( "ix_character_specials", 1 );
}

crossmap_enabled()
{
    return level.ix.character.crossmap;
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
    // them (KNOWN_LIMITATIONS.md L27).
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

// Why the player cannot take this character now, or undefined if they can.
// from_lobby: the stock lobby already checked the unlock.
unavailable_reason( entry, from_lobby )
{
    if ( entry.special )
    {
        if ( specials_mode() == 0 )
            return "special characters are off (ix_character_specials 0)";

        if ( !entry.native && !crossmap_enabled() )
            return entry.name + " belongs to " + map_title( entry.home ) + " (set ix_character_crossmap 1, then reload the map)";

        if ( !entry.native && !isdefined( entry.num ) )
            return entry.name + " could not be set up on this map";

        if ( !from_lobby && specials_mode() == 1 && !has_unlocked( entry ) )
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

// Makes entry the player's character. Returns 1 if it changed.
assign( entry )
{
    num = entry.num;
    old = self.player_character_num;

    if ( isdefined( old ) && old == num )
        return 0;

    available = level.available_player_characters;

    if ( !isdefined( available ) )
        available = [];

    if ( isdefined( old ) && is_regular_num( old ) && !scripts\engine\utility::array_contains( available, old ) )
        available = scripts\engine\utility::array_add( available, old );

    if ( is_regular_num( num ) )
        available = scripts\engine\utility::array_remove( available, num );

    level.available_player_characters = only_regular( available );
    self.player_character_num = num;
    return 1;
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

// Re-applies the character to a player who is already in the game, the way
// the stock loadout does on spawn, and swaps the character knife.
apply_now()
{
    num = self.player_character_num;
    old_melee = self.melee_weapon;
    new_melee = level.player_character_info[num].melee_weapon;

    self detachall();
    self.headmodel = undefined;
    self.hairmodel = undefined;
    self thread scripts\cp\zombies\zombies_loadout::setmodelfromcustomization( num );

    if ( !isdefined( old_melee ) || !isdefined( new_melee ) || old_melee == new_melee )
        return;

    if ( self hasweapon( old_melee ) )
    {
        holding = self getcurrentweapon() == old_melee;
        self takeweapon( old_melee );
        self giveweapon( new_melee );

        if ( holding )
            self switchtoweaponimmediate( new_melee );

        if ( isdefined( self.currentmeleeweapon ) && self.currentmeleeweapon == old_melee )
            self.currentmeleeweapon = new_melee;
    }

    // givedefaultloadout() hands out this knife on every later spawn.
    if ( isdefined( self.default_starting_melee_weapon ) && self.default_starting_melee_weapon == old_melee )
        self.default_starting_melee_weapon = new_melee;
}

// Not while downed or in the afterlife arcade (cp_zmb); the next spawn applies it.
can_apply_now()
{
    if ( !isdefined( self.vo_prefix ) || !isalive( self ) || self.sessionstate != "playing" )
        return 0;

    return !scripts\engine\utility::is_true( self.inlaststand ) && !scripts\engine\utility::is_true( self.in_afterlife_arcade );
}

// Validates and applies a choice. Returns a message for the player.
choose( entry, source )
{
    if ( entry.special && !entry.native && crossmap_enabled() )
        register_crossmap();

    reason = unavailable_reason( entry, 0 );

    if ( isdefined( reason ) )
        return "Can't pick " + entry.name + ": " + reason;

    if ( isdefined( self.ix.character_next_switch ) && gettime() < self.ix.character_next_switch )
        return "Wait a moment before switching again";

    if ( !assign( entry ) )
        return "You are already " + entry.name;

    self.ix.character_next_switch = gettime() + 2000;
    custom_scripts\ix\core\log::info( "character: " + self.name + " -> " + entry.name + " (" + source + ")" );

    if ( can_apply_now() )
    {
        apply_now();
        return "You are now " + entry.name;
    }

    return "You will be " + entry.name + " from your next spawn";
}

// ---------------------------------------------------------------------------
// Connect: host setting and lobby choice, before the first spawn

watch_connects()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "ix_player_connected", player );

        // Own thread, so an error for one player cannot stop this loop. It never
        // waits, so it still finishes before the player's first spawn.
        player thread on_connect();
    }
}

on_connect()
{
    if ( !enabled() )
        return;

    if ( crossmap_enabled() )
        register_crossmap();

    self thread watch_disconnect();
    notice = "Type !char in chat to choose your character";

    if ( self ishost() )
    {
        wanted = custom_scripts\ix\core\util::dvar_string( "ix_character", "" );
        entry = find_entry( wanted );

        if ( wanted != "" && !isdefined( entry ) )
        {
            notice = "ix_character: unknown character '" + wanted + "'";
        }
        else if ( isdefined( entry ) )
        {
            reason = unavailable_reason( entry, 0 );

            if ( isdefined( reason ) )
            {
                notice = "ix_character: can't pick " + entry.name + ": " + reason;
            }
            else if ( assign( entry ) )
            {
                custom_scripts\ix\core\log::info( "character: " + self.name + " -> " + entry.name + " (ix_character)" );
                self thread notice_after_spawn( notice );
                return;
            }
        }
    }

    self thread notice_after_spawn( notice );

    // A special character picked in the stock lobby. On its home map the stock
    // code applies it, so only other maps need this.
    entry = lobby_special();

    if ( isdefined( entry ) && !entry.native && !isdefined( unavailable_reason( entry, 1 ) ) && assign( entry ) )
    {
        self setplayerdata( "cp", "zombiePlayerLoadout", "characterSelect", 0 );
        custom_scripts\ix\core\log::info( "character: " + self.name + " -> " + entry.name + " (lobby)" );
    }
}

lobby_special()
{
    if ( isbot( self ) )
        return undefined;

    value = self getrankedplayerdata( "cp", "zombiePlayerLoadout", "characterSelect" );

    foreach ( entry in level.ix.character.cast )
    {
        if ( entry.special && entry.select_id == value )
            return entry;
    }

    return undefined;
}

notice_after_spawn( message )
{
    self endon( "disconnect" );
    self waittill( "spawned_player" );
    wait 2;
    self iprintln( message );
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

// ---------------------------------------------------------------------------
// Host setting: ix_character, applied whenever it changes

watch_host_setting()
{
    level endon( "game_ended" );
    last = custom_scripts\ix\core\util::dvar_string( "ix_character", "" );

    for (;;)
    {
        wait 1;
        value = custom_scripts\ix\core\util::dvar_string( "ix_character", "" );

        if ( value == last )
            continue;

        last = value;
        host = find_host();

        if ( !isdefined( host ) || value == "" || !enabled() )
            continue;

        entry = find_entry( value );

        if ( !isdefined( entry ) )
        {
            host iprintln( "ix_character: unknown character '" + value + "'" );
            continue;
        }

        host iprintln( host choose( entry, "ix_character" ) );
    }
}

find_host()
{
    foreach ( player in level.players )
    {
        if ( player ishost() )
            return player;
    }

    return undefined;
}

// ---------------------------------------------------------------------------
// Chat: !char / !character

watch_chat( message_type )
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( message_type, player, message );

        if ( custom_scripts\ix\core\util::is_human( player ) )
            player thread on_chat( message );
    }
}

on_chat( message )
{
    words = strtok( tolower( message ), " " );

    if ( words.size == 0 || ( words[0] != "!char" && words[0] != "!character" ) )
        return;

    if ( !enabled() )
    {
        self tell( "Character selection is off (ix_character_select 0)" );
        return;
    }

    if ( words.size == 1 )
    {
        list_cast();
        return;
    }

    entry = find_entry( words[1] );

    if ( !isdefined( entry ) )
    {
        self tell( "Unknown character '" + words[1] + "'. Type !char for the list." );
        return;
    }

    self tell( choose( entry, "chat" ) );
}

list_cast()
{
    if ( crossmap_enabled() )
        register_crossmap();

    regulars = [];
    specials = [];

    foreach ( entry in level.ix.character.cast )
    {
        label = entry.name;

        if ( entry.special )
            label = entry.key + " " + label;
        else
            label = entry.num + " " + label;

        if ( entry.role != "" && !entry.special )
            label = label + " (" + entry.role + ")";

        status = list_status( entry );

        if ( status != "" )
            label = label + " [" + status + "]";

        if ( entry.special )
        {
            if ( entry.native || crossmap_enabled() )
                specials[specials.size] = label;
        }
        else
        {
            regulars[regulars.size] = label;
        }
    }

    self tell( "Characters on " + map_title( level.ix.map ) + " - type !char <number or name>:" );
    self tell( custom_scripts\ix\core\util::join( regulars, ", " ) );

    if ( specials.size > 0 && specials_mode() != 0 )
        self tell( "Specials: " + custom_scripts\ix\core\util::join( specials, ", " ) );
}

list_status( entry )
{
    if ( isdefined( entry.num ) && isdefined( self.player_character_num ) && self.player_character_num == entry.num )
        return "you";

    other = taken_by( entry );

    if ( isdefined( other ) )
        return other.name;

    if ( entry.special && specials_mode() == 1 && !has_unlocked( entry ) )
        return "locked";

    if ( entry.special && !entry.native )
        return map_title( entry.home );

    return "";
}
