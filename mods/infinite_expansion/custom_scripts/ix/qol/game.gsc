// Infinite Expansion - game speed, zombie outlines and a restart (Phase 9).
//
//   - game speed: iw7-mod's setslowmotion( start, end, seconds ), which
//     replaces the game's own (IW_API_NOTES.md section 20), sets the time
//     scale of the whole match; setslowmotion( s, s, 0 ) sets it at once.
//     Always with all three arguments: iw7-mod's version fails with fewer.
//     The game's speed comes back at 100, when the match ends, and (iw7-mod)
//     when the map loads again.
//   - zombie outlines: what the stock outline effects do
//     (scripts\cp\cp_outline.gsc set_outline_for_player, which no stock
//     script uses): every enemy alive outlined for each player, orange,
//     through walls (depth 0; depth 1 for enemies the game hides that way),
//     twice a second. The enemies the game leaves out of its own outlines are
//     left out too. Off: the mod takes its outlines off.
//   - restart: the console command map_restart (iw7-mod's: the match starts
//     over and the scripts load again), from the host's menu.
//
// Settings:
//   game_speed       100  percent of the game's speed (25-200)
//   zombie_outlines  0    1: zombies outlined through walls, for everyone

register()
{
    custom_scripts\ix\core\config::add_int( "game_speed", 100, 25, 200, "Game speed", "Percent of the speed of the whole match: 50 is slow motion. 100 is the game's own.", ::on_speed_changed );
    custom_scripts\ix\core\config::add_bool( "zombie_outlines", 0, "Zombie outlines", "Every player sees zombies outlined in orange, also through walls.", undefined );

    custom_scripts\ix\core\events::subscribe( "player_connect", ::on_connect );
    custom_scripts\ix\core\events::subscribe( "game_end", ::on_game_end );
    level thread apply_speed_when_ready();
}

// ---------------------------------------------------------------------------
// Game speed

apply_speed_when_ready()
{
    level endon( "game_ended" );

    if ( !level.ix.ready )
        level waittill( "ix_ready" );

    if ( custom_scripts\ix\core\config::get( "game_speed" ) != 100 )
        set_speed( custom_scripts\ix\core\config::get( "game_speed" ) );
}

on_speed_changed( value, old_value, id )
{
    if ( level.ix.ready )
        set_speed( value );
}

set_speed( percent )
{
    scale = percent / 100.0;
    setslowmotion( scale, scale, 0 );
}

on_game_end( arg )
{
    if ( custom_scripts\ix\core\config::get( "game_speed" ) != 100 )
        setslowmotion( 1.0, 1.0, 0 );
}

// ---------------------------------------------------------------------------
// Zombie outlines

on_connect( player, arg )
{
    if ( custom_scripts\ix\core\util::is_valid_player( player ) )
        player thread keep_outlines();
}

keep_outlines()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    shown = 0;

    for (;;)
    {
        wait 0.5;

        if ( !isdefined( level.agentarray ) )
            continue;

        if ( custom_scripts\ix\core\config::get( "zombie_outlines" ) )
        {
            foreach ( enemy in scripts\cp\cp_agent_utils::get_alive_enemies() )
            {
                if ( !outlined_by_game( enemy ) )
                    continue;

                depth = 0;

                if ( isdefined( enemy.feral_occludes ) )
                    depth = 1;

                scripts\cp\cp_outline::enable_outline_for_player( enemy, self, 4, depth, 0, "high" );
            }

            shown = 1;
        }
        else if ( shown )
        {
            foreach ( enemy in scripts\cp\cp_agent_utils::get_alive_enemies() )
            {
                if ( outlined_by_game( enemy ) )
                    scripts\cp\cp_outline::disable_outline_for_player( enemy, self );
            }

            shown = 0;
        }
    }
}

// The enemies the stock outline effects outline (cp_outline.gsc skips the
// ones players have damaged in a challenge and the marked ones).
outlined_by_game( enemy )
{
    return !isdefined( enemy.damaged_by_players ) && !isdefined( enemy.marked_for_challenge );
}

// ---------------------------------------------------------------------------
// Restart (a menu action: host only, Use twice)

restart_match()
{
    custom_scripts\ix\core\log::info( "restart: map_restart by " + self.name );

    foreach ( player in level.players )
    {
        if ( custom_scripts\ix\core\util::is_valid_player( player ) )
            player iprintlnbold( "The match restarts." );
    }

    executecommand( "map_restart" );
}
