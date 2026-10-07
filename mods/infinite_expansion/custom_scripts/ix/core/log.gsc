// Infinite Expansion - logging.
//
// Every line goes to the iw7-mod console (and iw7-mod/logs/console.log) as
// "[IX] LEVEL: message" through iw7-mod's print(). The last log_size() lines
// are also kept in level.ix.log for the in-game debug views.

setup()
{
    level.ix.log = [];
    level.ix.log_next = 0;
}

info( message )
{
    write( "INFO", message );
}

warn( message )
{
    write( "WARN", message );
}

error( message )
{
    write( "ERROR", message );
}

// Printed only while the setting debug_log is on (config.gsc mirrors it to the
// dvar ix_debug_log, which works before the settings exist too).
debug( message )
{
    if ( getdvarint( "ix_debug_log", 0 ) == 0 )
        return;

    write( "DEBUG", message );
}

write( severity, message )
{
    line = "[IX] " + severity + ": " + message;
    print( line );

    // Before bootstrap creates level.ix (or when the mod is disabled) lines
    // are printed but not buffered.
    if ( !isdefined( level.ix ) || !isdefined( level.ix.log ) )
        return;

    level.ix.log[level.ix.log_next % log_size()] = line;
    level.ix.log_next++;
}

// Buffered lines, oldest first.
recent()
{
    lines = [];

    if ( !isdefined( level.ix ) || !isdefined( level.ix.log ) )
        return lines;

    first = 0;

    if ( level.ix.log_next > log_size() )
        first = level.ix.log_next - log_size();

    for ( i = first; i < level.ix.log_next; i++ )
        lines[lines.size] = level.ix.log[i % log_size()];

    return lines;
}

log_size()
{
    return 32;
}
