// Infinite Expansion - debug module (Phase 10).
//
// Developer tools that change the match (tools.gsc) sit behind a lock: the
// Debug page shows them as "Locked" until the host switches dev_tools on, and
// each one is host only and asks for a second Use (menu_tree.gsc
// add_dev_action). Read-outs (round, zombies, position, ...) are always there
// and change nothing.
//
// Settings:
//   dev_tools  0  1: unlocks the Debug page's tools
//   debug_log  0  (core) extra DEBUG lines in the console log
//
// Chat: "!ix log [n]": the mod's last n log lines (8 when n is left out, at
// most 32), to the player who asked. Anyone may read them.

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "debug" );
    custom_scripts\ix\core\config::add_bool( "dev_tools", 0, "Developer tools", "Unlocks the tools below it. Each is host only and asks for a second Use.", ::on_dev_tools_changed );
    custom_scripts\ix\core\chat::add_command( "log", ::log_command, "[n]: the mod's last n log lines" );
}

// Developer tools switched off: what they left running stops.
on_dev_tools_changed( value, old_value, id )
{
    if ( !value )
        custom_scripts\ix\debug\tools::resume_spawning();
}

// "!ix log [n]" (chat.gsc runs it on the player who typed it).
log_command( words )
{
    self endon( "disconnect" );
    count = 8;

    if ( words.size > 2 && custom_scripts\ix\core\util::is_number( words[2], 0 ) )
        count = clamp( int( words[2] ), 1, custom_scripts\ix\core\log::log_size() );

    lines = custom_scripts\ix\core\log::recent();

    if ( lines.size == 0 )
    {
        self tell( "The log is empty." );
        return;
    }

    first = lines.size - count;

    if ( first < 0 )
        first = 0;

    self tell( "Infinite Expansion log, the last " + ( lines.size - first ) + " lines:" );

    // A few lines a frame: the game drops a reply when a player's command
    // buffer is full (IW_API_NOTES.md section 19).
    for ( i = first; i < lines.size; i++ )
    {
        self tell( without_quotes( lines[i] ) );

        if ( ( i - first ) % 4 == 3 )
            wait 0.05;
    }
}

// tell() puts its text inside double quotes, so a " in a line would cut it.
without_quotes( text )
{
    if ( !issubstr( text, "\"" ) )
        return text;

    result = "";

    for ( i = 0; i < text.size; i++ )
    {
        c = getsubstr( text, i, i + 1 );

        if ( c == "\"" )
            c = "'";

        result += c;
    }

    return result;
}

// ---------------------------------------------------------------------------
// Read-outs for the Debug page (menu_tree.gsc add_info; they run on the
// player looking).

position_x()
{
    return int( self.origin[0] );
}

position_y()
{
    return int( self.origin[1] );
}

position_z()
{
    return int( self.origin[2] );
}

player_count()
{
    if ( !isdefined( level.players ) )
        return 0;

    return level.players.size;
}

map_name()
{
    return level.ix.map;
}
