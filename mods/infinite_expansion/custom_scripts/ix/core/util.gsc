// Infinite Expansion - shared helpers (all modes).
//
// For clamping use the native clamp( value, min, max ). Script functions cannot
// reuse a built-in's name: the compiler rejects them ("already defined as builtin").

is_valid_player( player )
{
    return isdefined( player ) && isplayer( player );
}

// A connected human player (not a bot).
is_human( player )
{
    return is_valid_player( player ) && !isbot( player );
}

// A dvar's value in lower case, or fallback while it is unset (settings use config.gsc).
dvar_string( name, fallback )
{
    value = getdvar( name );

    if ( value == "" )
        return fallback;

    return tolower( value );
}

// Joins array values into one string: join( [ "a", "b" ], "," ) returns "a,b".
join( items, separator )
{
    result = "";

    for ( i = 0; i < items.size; i++ )
    {
        if ( i > 0 )
            result += separator;

        result += items[i];
    }

    return result;
}

// 1 for "1", "true", "on", "yes"; 0 for "0", "false", "off", "no" (any case);
// undefined for anything else.
parse_bool( text )
{
    switch ( tolower( text ) )
    {
        case "1":
        case "true":
        case "on":
        case "yes":
            return 1;
        case "0":
        case "false":
        case "off":
        case "no":
            return 0;
    }

    return undefined;
}

// Digits with an optional leading "-", and with allow_fraction one ".":
// is_number( "-12", 0 ) and is_number( "0.5", 1 ) are true, is_number( "1e3", 1 ) is not.
is_number( text, allow_fraction )
{
    if ( !isstring( text ) || text.size == 0 )
        return 0;

    digits = 0;
    dots = 0;

    for ( i = 0; i < text.size; i++ )
    {
        // One character, the way the stock scripts take it (cp_disco_song_quest.gsc).
        c = getsubstr( text, i, i + 1 );

        if ( c == "-" && i == 0 )
            continue;

        if ( c == "." && allow_fraction && dots == 0 )
        {
            dots++;
            continue;
        }

        if ( !issubstr( "0123456789", c ) )
            return 0;

        digits++;
    }

    return digits > 0;
}

// True when items holds value (compared with ==, so give both the same type).
array_contains( items, value )
{
    foreach ( item in items )
    {
        if ( item == value )
            return 1;
    }

    return 0;
}

starts_with( text, prefix )
{
    return text.size >= prefix.size && getsubstr( text, 0, prefix.size ) == prefix;
}

// For a setting whose words are off / host / everyone: whether it is on for
// this player.
applies_to( id, player )
{
    scope = custom_scripts\ix\core\config::get( id );

    if ( scope == "everyone" )
        return 1;

    return scope == "host" && is_valid_player( player ) && player ishost();
}
