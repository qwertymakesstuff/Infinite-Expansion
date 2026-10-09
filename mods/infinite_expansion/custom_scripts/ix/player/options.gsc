// Infinite Expansion - player options: third person, zombies ignoring players,
// players pushing each other apart, starting points.
//
// What the stock zombies scripts do, and what the mod changes:
//   - third person: the camera behind the player, setcamerathirdperson (stock
//     MP scripts switch it for the Reaper; no zombies script does), through
//     compat::third_person. Applied on every spawn.
//   - zombies ignore players: the AI leaves a player alone while .ignoreme is
//     set. The game counts its own reasons in .enabledignoreme
//     (scripts\cp\utility::allow_player_ignore_me: last stand, phase shift,
//     fast travel, ...) and resets that count on every spawn. The mod never
//     touches the count: while the setting is on it keeps .ignoreme set, and
//     when it goes off it puts .ignoreme back to what the count says.
//   - players push apart: iw7-mod's bg_playerEjection (default 1) pushes
//     players apart when they stand inside each other. A global dvar that
//     outlives the match (KNOWN_LIMITATIONS.md L20), so the game's 1 goes back
//     when the match ends.
//   - starting points: each player's first spawn takes
//     scripts\cp\cp_persistence::get_starting_currency(), which is
//     level.starting_currency, or 500 when that is not set. The mod sets it
//     while the level loads, before any spawn; a change applies to players
//     who join later. zombie.gsc's get_starting_currency() asks first for a
//     player back from spectating (their own points), the boss-fight-only
//     mode (20,000) and Director's Cut (25,000); those stay as they are.
//
// Settings:
//   third_person     off   off / host / everyone
//   zombies_ignore   off   off / host / everyone
//   player_ejection  1     players standing inside each other are pushed apart
//   starting_points  500   points each player starts with

register()
{
    custom_scripts\ix\core\config::add_enum( "third_person", "off", "off host everyone", "Third person", "The camera behind the player. host: only the host; everyone: every player.", ::on_scope_changed );
    custom_scripts\ix\core\config::add_enum( "zombies_ignore", "off", "off host everyone", "Zombies ignore players", "Zombies leave these players alone. host: only the host; everyone: every player.", ::on_scope_changed );
    custom_scripts\ix\core\config::add_bool( "player_ejection", 1, "Players push apart", "Players standing inside each other are pushed apart (the game's own). OFF: they are not.", ::on_ejection_changed );
    custom_scripts\ix\core\config::add_int( "starting_points", 500, 0, 999999, "Starting points", "Points each new player starts with; 500 is the game's own. Not in Director's Cut.", ::on_starting_points_changed );

    custom_scripts\ix\core\events::subscribe( "player_connect", ::on_connect );
    custom_scripts\ix\core\events::subscribe( "player_spawn", ::on_spawn );
    custom_scripts\ix\core\events::subscribe( "game_end", ::on_game_end );

    // Before any player spawns; the map's main() comes after this and leaves
    // level.starting_currency alone (only the escape gametype sets it).
    set_starting_points( custom_scripts\ix\core\config::get( "starting_points" ) );
    set_ejection( custom_scripts\ix\core\config::get( "player_ejection" ) );
}

on_connect( player, arg )
{
    if ( custom_scripts\ix\core\util::is_valid_player( player ) )
        player thread keep_ignored();
}

on_spawn( player, arg )
{
    if ( custom_scripts\ix\core\util::is_valid_player( player ) )
        player apply_view();
}

// third_person or zombies_ignore changed: every player now.
on_scope_changed( value, old_value, id )
{
    if ( !isdefined( level.players ) )
        return;

    foreach ( player in level.players )
    {
        if ( custom_scripts\ix\core\util::is_valid_player( player ) && isalive( player ) )
            player apply_view();
    }
}

apply_view()
{
    self custom_scripts\ix\core\compat::third_person( custom_scripts\ix\core\util::applies_to( "third_person", self ) );
}

// Runs on each player for the whole match. .ignoreme is checked four times a
// second, so the game's own changes to it (a revive, a spawn) never stick
// while the setting is on.
keep_ignored()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    forced = 0;

    for (;;)
    {
        if ( custom_scripts\ix\core\util::applies_to( "zombies_ignore", self ) )
        {
            self.ignoreme = 1;
            forced = 1;
        }
        else if ( forced )
        {
            self.ignoreme = isdefined( self.enabledignoreme ) && self.enabledignoreme >= 1;
            forced = 0;
        }

        wait 0.25;
    }
}

on_ejection_changed( value, old_value, id )
{
    set_ejection( value );
}

set_ejection( on )
{
    if ( on )
        setdvar( "bg_playerEjection", 1 );
    else
        setdvar( "bg_playerEjection", 0 );
}

on_starting_points_changed( value, old_value, id )
{
    set_starting_points( value );
}

// The game's own 500 leaves level.starting_currency as the game has it; only
// a value the mod set is taken back.
set_starting_points( points )
{
    if ( points != 500 )
    {
        level.starting_currency = points;
        level.ix.starting_points_set = 1;
    }
    else if ( isdefined( level.ix.starting_points_set ) && level.ix.starting_points_set )
    {
        level.starting_currency = undefined;
        level.ix.starting_points_set = 0;
    }
}

// The game's own ejection for whatever runs next in this game process.
on_game_end( arg )
{
    setdvar( "bg_playerEjection", 1 );
}
