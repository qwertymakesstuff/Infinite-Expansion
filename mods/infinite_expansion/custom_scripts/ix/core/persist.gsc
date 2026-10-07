// Infinite Expansion - saving settings.
//
// Settings are saved as archived dvars: "seta ix_<id> <value>", run through
// iw7-mod's executecommand(). The game keeps archived dvars in the host's own
// config (iw7-mod/players2), and the next game starts with them, the same way
// the CHARACTER menu saves ix_character. This needs neither fs_game nor GSC
// file access, so it works in the install friends can join (KNOWN_LIMITATIONS
// L9, L30). Only the host's settings count: the scripts run on the host.
//
// Only short values made of letters, digits, "_", "." and "-" are ever written,
// so a value can never add another console command. config.gsc only passes
// values it has checked.
//
// ix_settings_version records which layout of settings was saved. When a
// later version renames or changes a setting, migrate() converts the old
// values once.

setup()
{
    saved = getdvar( "ix_settings_version" );

    if ( saved == "" + version() )
        return;

    if ( saved != "" )
    {
        custom_scripts\ix\core\log::info( "settings: saved by layout " + saved + ", now " + version() );
        migrate( int( saved ) );
    }

    save( "ix_settings_version", "" + version() );
}

// The current layout of the saved settings.
version()
{
    return 1;
}

// No setting has changed its meaning since layout 1.
migrate( from_version )
{
}

save( dvar, text )
{
    if ( !is_safe( dvar ) || !is_safe( text ) )
    {
        custom_scripts\ix\core\log::warn( "settings: not saved, unexpected characters in " + dvar );
        return;
    }

    executecommand( "seta " + dvar + " " + text );
}

// Letters, digits, "_", "." and "-", at most 64 characters.
is_safe( text )
{
    if ( !isstring( text ) || text.size == 0 || text.size > 64 )
        return 0;

    allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-";

    for ( i = 0; i < text.size; i++ )
    {
        if ( !issubstr( allowed, getsubstr( text, i, i + 1 ) ) )
            return 0;
    }

    return 1;
}
