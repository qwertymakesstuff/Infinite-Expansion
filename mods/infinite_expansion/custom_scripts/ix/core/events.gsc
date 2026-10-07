// Infinite Expansion - event bus.
//
// subscribe( event, fn ) calls fn every time the event happens. One listener
// thread per source notify (per player for player events) dispatches to every
// subscriber, so modules never wait on game notifies themselves. Each handler
// runs as its own thread on level:
//
//   level events    fn( arg )            round_start: wave number, round_end: wave number
//   player events   fn( player, arg )
//
// Events and their sources (IW_API_NOTES.md section 6; the stock zombies scripts):
//   player_connect     level "ix_player_connected" (bootstrap)
//   player_spawn       level "ix_player_spawned" (bootstrap)
//   player_death       player "death"
//   player_disconnect  player "disconnect"
//   player_laststand   player "last_stand", weapon       scripts\cp\cp_laststand
//   weapon_change      player "weapon_change", weapon
//   weapon_fired       player "weapon_fired"
//   reload             player "reload"
//   round_start        level "regular_wave_starting" and "event_wave_starting"
//                      (scripts\cp\zombies\zombies_spawning; level.wave_num is set)
//   round_end          level "spawn_wave_done"
//   game_end           level "game_ended"
//   chat               level "say", player, message      iw7-mod logprint.cpp; in
//                      zombies team chat arrives as "say" too
//
// A handler must not assume the player is still connected when it runs:
// player_disconnect handlers get the player as it leaves.

setup()
{
    level.ix.events = spawnstruct();
    level.ix.events.handlers = [];
    level.ix.events.listening = [];
    level thread watch_players();
}

subscribe( event, fn )
{
    if ( !is_event( event ) )
    {
        custom_scripts\ix\core\log::warn( "events: unknown event '" + event + "'" );
        return;
    }

    handlers = level.ix.events.handlers[event];

    if ( !isdefined( handlers ) )
        handlers = [];

    handlers[handlers.size] = fn;
    level.ix.events.handlers[event] = handlers;

    if ( is_player_event( event ) )
    {
        // Players already in the match get the listener now; later ones on
        // connect. Modules subscribe while the level loads, before level.players
        // exists.
        if ( isdefined( level.players ) )
        {
            foreach ( player in level.players )
                player listen_player( event );
        }
    }
    else
        start_level_listener( event );
}

is_event( event )
{
    return is_player_event( event ) || is_level_event( event );
}

// Events whose source is a notify on the player.
is_player_event( event )
{
    switch ( event )
    {
        case "player_death":
        case "player_disconnect":
        case "player_laststand":
        case "weapon_change":
        case "weapon_fired":
        case "reload":
            return 1;
    }

    return 0;
}

// Events whose source is a notify on level.
is_level_event( event )
{
    switch ( event )
    {
        case "player_connect":
        case "player_spawn":
        case "round_start":
        case "round_end":
        case "game_end":
        case "chat":
            return 1;
    }

    return 0;
}

has_handlers( event )
{
    return isdefined( level.ix.events.handlers[event] );
}

dispatch_level( event, arg )
{
    if ( !has_handlers( event ) )
        return;

    foreach ( fn in level.ix.events.handlers[event] )
        level thread [[ fn ]]( arg );
}

dispatch_player( event, player, arg )
{
    if ( !has_handlers( event ) )
        return;

    foreach ( fn in level.ix.events.handlers[event] )
        level thread [[ fn ]]( player, arg );
}

// Level listeners: one thread per event, started by the first subscriber.
start_level_listener( event )
{
    if ( isdefined( level.ix.events.listening[event] ) )
        return;

    level.ix.events.listening[event] = 1;

    switch ( event )
    {
        case "player_connect":
            level thread listen_level_player( "ix_player_connected", event );
            break;
        case "player_spawn":
            level thread listen_level_player( "ix_player_spawned", event );
            break;
        case "round_start":
            level thread listen_round_start( "regular_wave_starting" );
            level thread listen_round_start( "event_wave_starting" );
            break;
        case "round_end":
            level thread listen_round_end();
            break;
        case "game_end":
            level thread listen_game_end();
            break;
        case "chat":
            level thread listen_chat();
            break;
    }
}

listen_level_player( source, event )
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( source, player );
        dispatch_player( event, player );
    }
}

listen_round_start( source )
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( source );
        dispatch_level( "round_start", level.wave_num );
    }
}

listen_round_end()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "spawn_wave_done" );
        dispatch_level( "round_end", level.wave_num );
    }
}

listen_game_end()
{
    level waittill( "game_ended" );
    dispatch_level( "game_end" );
}

listen_chat()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "say", player, message );
        dispatch_player( "chat", player, message );
    }
}

// Player listeners: started for every connecting player, for each player event
// that has subscribers.
watch_players()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "ix_player_connected", player );

        foreach ( event in getarraykeys( level.ix.events.handlers ) )
        {
            if ( is_player_event( event ) )
                player listen_player( event );
        }
    }
}

// Runs on the player; starts the listener for one event once.
listen_player( event )
{
    if ( !isdefined( self.ix ) )
        return;

    if ( !isdefined( self.ix.listening ) )
        self.ix.listening = [];

    if ( isdefined( self.ix.listening[event] ) )
        return;

    self.ix.listening[event] = 1;

    switch ( event )
    {
        case "player_death":
            self thread listen_player_notify( "death", event );
            break;
        case "player_laststand":
            self thread listen_player_notify( "last_stand", event );
            break;
        case "weapon_change":
            self thread listen_player_notify( "weapon_change", event );
            break;
        case "weapon_fired":
            self thread listen_player_notify( "weapon_fired", event );
            break;
        case "reload":
            self thread listen_player_notify( "reload", event );
            break;
        case "player_disconnect":
            self thread listen_disconnect();
            break;
    }
}

listen_player_notify( source, event )
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( source, arg );
        dispatch_player( event, self, arg );
    }
}

// No endon( "disconnect" ) here: it would end this thread at the very notify it waits for.
listen_disconnect()
{
    level endon( "game_ended" );

    self waittill( "disconnect" );
    dispatch_player( "player_disconnect", self );
}
