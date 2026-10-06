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

// Integer setting: the dvar's value, or fallback while the dvar is unset.
dvar_int( name, fallback )
{
    if ( getdvar( name ) == "" )
        return fallback;

    return getdvarint( name );
}

// Lower-case string setting: the dvar's value, or fallback while it is unset.
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
