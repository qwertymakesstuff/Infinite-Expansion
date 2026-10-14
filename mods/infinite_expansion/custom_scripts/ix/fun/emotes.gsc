// Infinite Expansion - emotes (Phase 14).
//
// Each map's own character animations, played on demand: a character's
// Pack-a-Punch celebration, their entrance, their Fate & Fortune card trick,
// and the hand gestures the map uses (emote_data.gsc lists them; nothing
// else is loaded on a map). From the menu's Emotes page (the wheel, browsing,
// favorites, random, preview) or "!ix emote" in chat.
//
// How an emote plays (IW_API_NOTES.md section 23):
//   offhand  scripts\cp\utility::firegesturegrenade, as the game plays these
//            (an off-hand "throw": first person, and the body for others)
//   gesture  playgestureviewmodel with the body event the stock
//            gesture_activate plays with it ("power_active_cp", "gesture008")
//   custom   the player's own animation from Build Custom Emotes, on a copy
//            of their character while they are hidden and held in place
//            (emote_custom.gsc), in the Custom category
// While it plays, aiming and melee are off through the stock counters, so the
// game's own changes to them stand (and grenades, for a hand gesture, as
// gesture_activate does). The camera may go behind the player for
// it (emote_camera) and comes back as Third person has it.
//
// Safety, as AAE's emotes do it (BO3): an emote starts only on the ground,
// standing still or walking, with nothing else going on (not sprinting,
// reloading, throwing, mantling, wall running, on a ladder, held by anything,
// in a gesture) and no zombie within about three meters; it ends early on
// damage (emote_cancel_damage), on going down or dying, on a new emote, and
// when Emotes go off. While it plays the player is held where they stand
// (emote_custom.gsc hold, as the menu holds them), so the camera can go round
// the character while the body keeps facing one way; moving, Melee or Use, or
// a zombie coming close ends it. Their weapon is put away meanwhile
// (emote_empty_hands: the game's own empty hands, iw7_gunless_zm).
//
// Favorites: seven slots, the wheel's. The host's are saved
// (ix_emote_favorites, as settings are, persist.gsc); a guest's last for the
// match (the scripts run on the host, KNOWN_LIMITATIONS.md L65).
//
// Settings:
//   emotes               1     feature: emotes on
//   emote_camera         auto  auto: behind you for whole-body emotes; first; third
//   emote_cancel_damage  1     damage ends an emote
//   emote_empty_hands    1     the weapon put away during a stock emote
//   emote_custom         1     custom emotes (emote_custom.gsc)

register()
{
    feature = custom_scripts\ix\core\features::add( "emotes", "fun", "Emotes", "Your character's animations of this map, from the menu's Emotes page or !ix emote.", 1 );
    feature.on_player = ::on_feature;
    custom_scripts\ix\core\config::add_enum( "emote_camera", "auto", "auto first third", "Emote: camera", "auto: behind you for whole-body emotes, as you see your character; first; third.", undefined );
    custom_scripts\ix\core\config::add_bool( "emote_cancel_damage", 1, "Emote: stop when hit", "Taking damage ends an emote at once.", undefined );
    custom_scripts\ix\core\config::add_bool( "emote_empty_hands", 1, "Emote: empty hands", "Your weapon is put away for an emote, as in the afterlife arcade, and comes back after it.", undefined );

    level.ix.emotes = spawnstruct();
    level.ix.emotes.list = [];
    level.ix.emotes.by_id = [];
    custom_scripts\ix\fun\emote_custom::register();

    custom_scripts\ix\core\events::subscribe( "player_connect", ::on_connect );
    custom_scripts\ix\core\events::subscribe( "player_laststand", ::on_down );
    custom_scripts\ix\core\events::subscribe( "player_death", ::on_down );
    custom_scripts\ix\core\chat::add_command( "emote", ::emote_command, "[name | random | list]: plays one of this map's emotes" );
    custom_scripts\ix\core\chat::add_command( "wheel", ::wheel_command, "opens the emote wheel, or closes the menu (bind a key to it)" );
    level thread load_when_ready();
}

load_when_ready()
{
    level endon( "game_ended" );

    if ( !level.ix.ready )
        level waittill( "ix_ready" );

    level.ix.emotes.list = custom_scripts\ix\fun\emote_data::catalog( level.ix.map );

    foreach ( emote in custom_scripts\ix\fun\emote_custom::list() )
        level.ix.emotes.list[level.ix.emotes.list.size] = emote;

    foreach ( emote in level.ix.emotes.list )
        level.ix.emotes.by_id[emote.id] = emote;

    custom_scripts\ix\core\log::info( "emotes: " + level.ix.emotes.list.size + " on " + level.ix.map );
}

list()
{
    return level.ix.emotes.list;
}

find( id )
{
    return level.ix.emotes.by_id[id];
}

// This map's emotes of one category.
in_category( category )
{
    found = [];

    foreach ( emote in level.ix.emotes.list )
    {
        if ( emote.category == category )
            found[found.size] = emote;
    }

    return found;
}

// ---------------------------------------------------------------------------
// Players

on_connect( player, arg )
{
    if ( !custom_scripts\ix\core\util::is_valid_player( player ) || !isdefined( player.ix ) )
        return;

    state = spawnstruct();
    state.active = undefined;
    state.last = undefined;
    state.favorites = [];
    state.other_maps = [];
    state.locked = 0;
    state.offhands = 0;
    state.camera = 0;
    player.ix.emote = state;

    if ( player ishost() )
        player thread load_favorites();
}

on_down( player, arg )
{
    if ( isdefined( player ) && isdefined( player.ix ) && isdefined( player.ix.emote ) )
        player notify( "ix_emote_end" );
}

// Emotes switched off: an emote playing ends.
on_feature( enabled )
{
    if ( !enabled )
        self notify( "ix_emote_end" );
}

// Why this player cannot emote now, or "".
cannot_emote()
{
    if ( !custom_scripts\ix\core\features::is_enabled( "emotes" ) )
        return "Emotes are off (Emotes page).";

    if ( !custom_scripts\ix\core\util::is_playing( self ) )
        return "Not while down or out of the match.";

    if ( !self isonground() )
        return "Land first.";

    if ( self issprinting() || self isreloading() || self isthrowinggrenade() || self ismantling() || self iswallrunning() || self isonladder() )
        return "Not while sprinting, reloading, throwing or climbing.";

    // Held by anything but the menu (a ride, an arcade game, the afterlife):
    // the game is using the player.
    if ( self islinked() && !custom_scripts\ix\ui\menu::is_menu_link( self ) )
        return "Not now: the game is using you.";

    if ( self isgestureplaying() )
        return "Wait for the gesture to finish.";

    // As AAE does: not with a zombie at arm's length (about three meters).
    if ( zombie_near( 120 ) )
        return "Not with a zombie this close.";

    return "";
}

zombie_near( range )
{
    foreach ( enemy in scripts\cp\cp_agent_utils::get_alive_enemies() )
    {
        if ( isdefined( enemy ) && distancesquared( enemy.origin, self.origin ) < range * range )
            return 1;
    }

    return 0;
}

// An off-hand gesture also needs a weapon the game lets gestures play over
// (scripts\cp\utility::cangiveandfireoffhand: level.invalid_gesture_weapon).
cannot_play( emote )
{
    if ( emote.kind == "offhand" && !scripts\cp\utility::cangiveandfireoffhand( self getcurrentweapon() ) )
        return "Not with this weapon in hand.";

    if ( emote.kind == "custom" )
        return self custom_scripts\ix\fun\emote_custom::cannot_play();

    return "";
}

// Plays an emote on this player, ending one already playing. Returns 1 when
// it started.
play( emote, preview )
{
    if ( !isdefined( self.ix ) || !isdefined( self.ix.emote ) || !isdefined( emote ) )
        return 0;

    self notify( "ix_emote_end" );
    waittillframeend;
    self endon( "disconnect" );
    self endon( "ix_emote_end" );

    // From the menu, the player was held (linked) until a moment ago, and the
    // game counts them on the ground again only once it has moved them: wait
    // for that, as the menu does before it opens (menu.gsc open_after_landing),
    // and for a landing after a hop.
    for ( waited = 0; waited < 1 && isalive( self ) && !self islinked() && !self isonground(); waited += 0.05 )
        wait 0.05;

    problem = self cannot_emote();

    if ( problem == "" )
        problem = self cannot_play( emote );

    if ( problem != "" )
    {
        self iprintln( problem );
        return 0;
    }

    self.ix.emote.last = emote;
    self thread run( emote, isdefined( preview ) && preview );
    return 1;
}

run( emote, preview )
{
    self endon( "disconnect" );
    self endon( "ix_emote_end" );
    state = self.ix.emote;
    state.active = emote;
    state.camera = wants_third_person( emote, preview );
    self thread end_on_trouble();

    if ( state.camera )
        self custom_scripts\ix\core\compat::third_person( 1 );

    // The stand-in: emote_custom.gsc holds the player and does the rest.
    if ( emote.kind == "custom" )
    {
        self thread custom_scripts\ix\fun\emote_custom::end_on_game_end();
        custom_scripts\ix\core\log::debug( "emotes: " + self.name + " plays " + emote.id );
        self custom_scripts\ix\fun\emote_custom::start( emote );
        self custom_scripts\ix\fun\emote_custom::play_until_done( emote );
        self notify( "ix_emote_end" );
        return;
    }

    self scripts\engine\utility::allow_ads( 0 );
    self scripts\engine\utility::allow_melee( 0 );
    state.locked = 1;
    custom_scripts\ix\core\log::debug( "emotes: " + self.name + " plays " + emote.id );

    // Held in place, so the camera can go round the character while the body
    // keeps facing the way it did; moving ends it (emote_custom.gsc hold).
    self thread custom_scripts\ix\fun\emote_custom::end_on_game_end();
    self custom_scripts\ix\fun\emote_custom::hold();

    if ( custom_scripts\ix\core\config::get( "emote_empty_hands" ) )
        self empty_hands();

    if ( emote.kind == "offhand" )
    {
        scripts\cp\utility::firegesturegrenade( self, emote.asset );

        if ( isdefined( emote.sound ) )
            self custom_scripts\ix\core\compat::local_sound( emote.sound );
    }
    else
    {
        // As gesture_activate: no grenades over a hand gesture.
        self scripts\engine\utility::allow_offhand_weapons( 0 );
        state.offhands = 1;

        if ( self playgestureviewmodel( emote.asset, undefined, 1 ) )
            self playanimscriptevent( "power_active_cp", "gesture008" );
    }

    self custom_scripts\ix\fun\emote_custom::hold_until( duration( emote ) );
    self notify( "ix_emote_end" );
}

// The weapon out of the hands for the emote: the game's own empty hands
// (iw7_gunless_zm), given and taken as the stock scripts do it (the afterlife
// arcade, cp_town_crab_boss_bomb.gsc), with weapon switching off meanwhile.
// Not when the player already has them (the afterlife arcade).
empty_hands()
{
    state = self.ix.emote;

    if ( self hasweapon( gunless() ) )
        return;

    state.weapon = self getcurrentweapon();
    self giveweapon( gunless() );
    self switchtoweaponimmediate( gunless() );
    self scripts\engine\utility::allow_weapon_switch( 0 );
    // Let the switch finish before the gesture goes over it.
    wait 0.1;
}

gunless()
{
    return "iw7_gunless_zm";
}

// The weapon back in the hands, if empty_hands() took it.
weapon_back()
{
    state = self.ix.emote;

    if ( !isdefined( state.weapon ) )
        return;

    self scripts\engine\utility::allow_weapon_switch( 1 );

    if ( self hasweapon( gunless() ) )
        self takeweapon( gunless() );

    if ( self hasweapon( state.weapon ) )
        self switchtoweaponimmediate( state.weapon );

    state.weapon = undefined;
}

// Whatever ends an emote early; then everything is put back, once.
end_on_trouble()
{
    self endon( "disconnect" );
    emote = self.ix.emote.active;

    if ( custom_scripts\ix\core\config::get( "emote_cancel_damage" ) )
        self scripts\engine\utility::waittill_any( "ix_emote_end", "damage", "death", "last_stand" );
    else
        self scripts\engine\utility::waittill_any( "ix_emote_end", "death", "last_stand" );

    self notify( "ix_emote_end" );
    self restore( emote );
}

restore( emote )
{
    state = self.ix.emote;

    if ( !isdefined( state.active ) )
        return;

    if ( emote.kind == "gesture" && self isgestureplaying( emote.asset ) )
        self stopgestureviewmodel( emote.asset, 0.2 );

    if ( emote.kind == "custom" )
        self custom_scripts\ix\fun\emote_custom::stop();
    else
    {
        self custom_scripts\ix\fun\emote_custom::release();
        self weapon_back();
    }

    if ( state.locked )
    {
        self scripts\engine\utility::allow_ads( 1 );
        self scripts\engine\utility::allow_melee( 1 );
        state.locked = 0;
    }

    if ( state.offhands )
    {
        self scripts\engine\utility::allow_offhand_weapons( 1 );
        state.offhands = 0;
    }

    if ( state.camera )
    {
        self custom_scripts\ix\player\options::apply_view();
        state.camera = 0;
    }

    state.active = undefined;
}

// How long the emote holds the camera: the length the game knows for its
// gesture, else its own seconds.
duration( emote )
{
    seconds = emote.seconds;

    if ( isdefined( emote.length ) )
    {
        known = self getgestureanimlength( emote.length );

        if ( isdefined( known ) && known > 0 )
            seconds = known;
    }

    return min( max( seconds, 1 ), 8 );
}

// auto: whole-body emotes behind the player, so they see their character;
// hand gestures in first person, where they are seen. A preview is always
// behind the player.
wants_third_person( emote, preview )
{
    // A custom emote is only seen on the copy of the character.
    if ( preview || emote.kind == "custom" )
        return 1;

    switch ( custom_scripts\ix\core\config::get( "emote_camera" ) )
    {
        case "first":
            return 0;
        case "third":
            return 1;
    }

    return emote.kind == "offhand";
}

is_emoting( player )
{
    return isdefined( player.ix ) && isdefined( player.ix.emote ) && isdefined( player.ix.emote.active );
}

// ---------------------------------------------------------------------------
// From the menu (menu_tree.gsc): the menu closes first, which lets go of the
// player.

menu_play( emote )
{
    custom_scripts\ix\ui\menu::close_menu_for_move();
    self thread play( emote );
}

menu_preview( emote )
{
    custom_scripts\ix\ui\menu::close_menu_for_move();
    self thread play( emote, 1 );
}

random_action()
{
    emotes = list();

    if ( emotes.size == 0 )
    {
        self iprintln( "This map has no emotes." );
        return;
    }

    menu_play( emotes[randomint( emotes.size )] );
}

// The last emote played, behind the player.
preview_action()
{
    if ( !isdefined( self.ix.emote.last ) )
    {
        self iprintln( "Play an emote first; Preview shows it again from behind." );
        return;
    }

    menu_preview( self.ix.emote.last );
}

preview_label( arg )
{
    if ( !isdefined( self.ix.emote.last ) )
        return "Preview the last emote";

    return "Preview: " + self.ix.emote.last.wheel_name;
}

// ---------------------------------------------------------------------------
// Favorites: seven slots, also the wheel's.

slot_count()
{
    return 7;
}

favorite( slot )
{
    return self.ix.emote.favorites[slot];
}

// What a slot plays: its favorite, else this map's emotes in order.
slot_emote( slot )
{
    emote = favorite( slot );

    if ( isdefined( emote ) )
        return emote;

    if ( slot < list().size && !is_favorite( list()[slot] ) )
        return list()[slot];

    return undefined;
}

is_favorite( emote )
{
    foreach ( favorite in self.ix.emote.favorites )
    {
        if ( isdefined( favorite ) && favorite == emote )
            return 1;
    }

    return 0;
}

toggle_favorite( emote )
{
    state = self.ix.emote;

    for ( slot = 0; slot < slot_count(); slot++ )
    {
        if ( isdefined( state.favorites[slot] ) && state.favorites[slot] == emote )
        {
            state.favorites[slot] = undefined;
            self iprintln( emote.name + ": no longer a favorite." );
            save_favorites();
            return;
        }
    }

    // A free slot; one kept for another map's favorite only when no other is.
    slot = free_slot( 0 );

    if ( !isdefined( slot ) )
        slot = free_slot( 1 );

    if ( !isdefined( slot ) )
    {
        self iprintln( "Seven favorites already: take one off first." );
        return;
    }

    state.favorites[slot] = emote;
    state.other_maps[slot] = undefined;
    self iprintln( emote.name + ": favorite " + ( slot + 1 ) + ", on the wheel." );
    save_favorites();
}

free_slot( other_maps_too )
{
    state = self.ix.emote;

    for ( slot = 0; slot < slot_count(); slot++ )
    {
        if ( isdefined( state.favorites[slot] ) )
            continue;

        if ( other_maps_too || !isdefined( state.other_maps[slot] ) )
            return slot;
    }

    return undefined;
}

favorite_info( emote )
{
    if ( is_favorite( emote ) )
        return "Yes";

    return "No";
}

// The wheel shows short names.
wheel_label( slot )
{
    emote = slot_emote( slot );

    if ( !isdefined( emote ) )
        return "(empty)";

    return emote.wheel_name;
}

favorite_label( emote )
{
    return "Favorite: " + favorite_info( emote );
}

count_info()
{
    return list().size;
}

slot_label( slot )
{
    emote = slot_emote( slot );

    if ( !isdefined( emote ) )
        return ( slot + 1 ) + ". (empty)";

    return ( slot + 1 ) + ". " + emote.name;
}

slot_help( slot )
{
    emote = slot_emote( slot );

    if ( !isdefined( emote ) )
        return "An empty slot. Favorite an emote on its page (Browse emotes) to put it here.";

    if ( isdefined( favorite( slot ) ) )
        return emote.help + " Favorite.";

    return emote.help + " (Until you pick favorites.)";
}

play_slot( slot )
{
    emote = slot_emote( slot );

    if ( !isdefined( emote ) )
    {
        self iprintln( "An empty slot." );
        return;
    }

    menu_play( emote );
}

clear_favorites()
{
    self.ix.emote.favorites = [];
    self.ix.emote.other_maps = [];
    save_favorites();
    self iprintln( "Favorites cleared." );
}

// The host's favorites, kept across games: "id.id.-.id" (- for an empty slot).
save_favorites()
{
    if ( !self ishost() )
        return;

    ids = [];

    for ( slot = 0; slot < slot_count(); slot++ )
    {
        emote = self.ix.emote.favorites[slot];

        if ( isdefined( emote ) )
            ids[ids.size] = emote.id;
        else if ( isdefined( self.ix.emote.other_maps[slot] ) )
            ids[ids.size] = self.ix.emote.other_maps[slot];
        else
            ids[ids.size] = "-";
    }

    custom_scripts\ix\core\persist::save( "ix_emote_favorites", custom_scripts\ix\core\util::join( ids, "." ) );
}

// Favorites name emotes by id, the same on every map ("pap3" is the third
// character's). One this map does not have leaves its slot empty here and is
// kept for the maps that have it, until the slot gets a favorite of this map.
load_favorites()
{
    self endon( "disconnect" );

    while ( level.ix.emotes.list.size == 0 && !level.ix.ready )
        wait 0.5;

    wait 0.5;
    ids = strtok( getdvar( "ix_emote_favorites" ), "." );

    for ( slot = 0; slot < ids.size && slot < slot_count(); slot++ )
    {
        emote = find( ids[slot] );

        if ( isdefined( emote ) )
            self.ix.emote.favorites[slot] = emote;
        else if ( ids[slot] != "-" )
            self.ix.emote.other_maps[slot] = ids[slot];
    }
}

// ---------------------------------------------------------------------------
// Chat: "!ix wheel" opens the menu at the emote wheel, or closes the menu when
// it is open. A script cannot read a key of the keyboard, only chat lines
// (iw7-mod's "say" notify) and the game's own commands, so a key works through
// a bind that says it: bind b "say !ix wheel" (KNOWN_LIMITATIONS.md L70).

wheel_command( words )
{
    if ( list().size == 0 )
    {
        self tell( "This map has no emotes." );
        return;
    }

    self custom_scripts\ix\ui\menu::toggle_at_page( "emote_wheel" );
}

// ---------------------------------------------------------------------------
// Chat: "!ix emote [name | random | list]" (chat.gsc runs it on the player)

emote_command( words )
{
    emotes = list();

    if ( words.size <= 2 || tolower( words[2] ) == "list" )
    {
        names = [];

        foreach ( emote in emotes )
            names[names.size] = emote.id;

        lines = [ "Emotes here: " + custom_scripts\ix\core\util::join( names, ", " ), custom_scripts\ix\core\chat::prefix() + " emote <name>, or random. The menu's Emotes page has the wheel." ];
        custom_scripts\ix\core\chat::tell_lines( self, lines );
        return;
    }

    wanted = tolower( words[2] );

    if ( wanted == "random" && emotes.size > 0 )
    {
        self thread play( emotes[randomint( emotes.size )] );
        return;
    }

    emote = find( wanted );

    if ( !isdefined( emote ) )
    {
        self tell( "No emote " + wanted + " on this map. " + custom_scripts\ix\core\chat::prefix() + " emote list" );
        return;
    }

    self thread play( emote );
}
