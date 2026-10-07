// Infinite Expansion - configuration manager.
//
// Every option of the mod is a setting with an id, a type, a default and a
// valid range. Its value lives in level.ix.config.settings[id].value and is
// mirrored to the dvar ix_<id>, so:
//   - set ix_<id> <value> in the console changes it live: a watcher reads the
//     dvars every half second, checks the value and applies it;
//   - the chat commands (chat.gsc) and later the menu call set();
//   - each change is saved with seta (persist.gsc), so it lasts across games.
// An invalid value is refused and the dvar is put back; numbers are kept inside
// their range.
//
// Types and how values are written:
//   bool   1 / 0 (also accepts true/false, on/off, yes/no)
//   int    whole number within [min, max]
//   float  number within [min, max]
//   enum   one of a fixed list of lower-case words
//
// Settings are registered by core files and modules while the level loads,
// before anything reads them. on_change, when given, runs as
//   level thread [[ on_change ]]( value, old_value, id )
// after every change, but not for the value found at registration.

setup()
{
    level.ix.config = spawnstruct();
    level.ix.config.settings = [];
    level.ix.config.order = [];
}

// Starts the console watcher; bootstrap calls it once every module has registered.
start()
{
    level thread watch_dvars();
}

add_bool( id, default_value, label, help, on_change )
{
    setting = new_setting( id, "bool", default_value, label, help, on_change );
    return finish( setting );
}

add_int( id, default_value, min_value, max_value, label, help, on_change )
{
    setting = new_setting( id, "int", default_value, label, help, on_change );
    setting.min = min_value;
    setting.max = max_value;
    return finish( setting );
}

add_float( id, default_value, min_value, max_value, label, help, on_change )
{
    setting = new_setting( id, "float", default_value, label, help, on_change );
    setting.min = min_value;
    setting.max = max_value;
    return finish( setting );
}

// options: the allowed words, separated by spaces ("off unlocked all").
add_enum( id, default_value, options, label, help, on_change )
{
    setting = new_setting( id, "enum", default_value, label, help, on_change );
    setting.options = strtok( options, " " );
    return finish( setting );
}

new_setting( id, type, default_value, label, help, on_change )
{
    setting = spawnstruct();
    setting.id = id;
    setting.type = type;
    setting.default_value = default_value;
    setting.label = label;
    setting.help = help;
    setting.on_change = on_change;
    setting.dvar = "ix_" + id;
    return setting;
}

// Registers the setting with the value its dvar already holds (saved from an
// earlier game, the command line or the console), else its default.
finish( setting )
{
    if ( isdefined( level.ix.config.settings[setting.id] ) )
    {
        custom_scripts\ix\core\log::warn( "config: setting '" + setting.id + "' registered twice; the first one stays" );
        return level.ix.config.settings[setting.id];
    }

    value = setting.default_value;
    found = getdvar( setting.dvar );

    if ( found != "" )
    {
        parsed = parse( setting, found );

        if ( isdefined( parsed ) )
            value = parsed;
        else
            custom_scripts\ix\core\log::warn( setting.dvar + " '" + found + "' is not " + describe_range( setting ) + "; using " + to_text( setting, value ) );
    }

    setting.value = value;
    setting.text = to_text( setting, value );

    if ( found != setting.text )
        setdvar( setting.dvar, setting.text );

    // An invalid saved value is replaced in the saved settings too.
    if ( found != "" && found != setting.text )
        custom_scripts\ix\core\persist::save( setting.dvar, setting.text );

    level.ix.config.settings[setting.id] = setting;
    level.ix.config.order[level.ix.config.order.size] = setting.id;
    return setting;
}

// The setting with this id, or undefined.
find( id )
{
    if ( !isdefined( level.ix ) || !isdefined( level.ix.config ) || !isstring( id ) )
        return undefined;

    return level.ix.config.settings[tolower( id )];
}

exists( id )
{
    return isdefined( find( id ) );
}

// The current value: 1/0 for bool, a number for int and float, a word for enum.
get( id )
{
    setting = find( id );

    if ( !isdefined( setting ) )
    {
        custom_scripts\ix\core\log::warn( "config: unknown setting '" + id + "'" );
        return undefined;
    }

    return setting.value;
}

// Sets a setting from a script, a chat command or the menu. value may be a
// number or text. Returns 1 when the value was accepted (it may have been kept
// inside the range), 0 when it was refused.
set( id, value, source )
{
    setting = find( id );

    if ( !isdefined( setting ) )
        return 0;

    parsed = parse( setting, "" + value );

    if ( !isdefined( parsed ) )
        return 0;

    apply( setting, parsed, source );
    return 1;
}

reset_default( id, source )
{
    setting = find( id );

    if ( !isdefined( setting ) )
        return 0;

    apply( setting, setting.default_value, source );
    return 1;
}

reset_all( source )
{
    foreach ( id in level.ix.config.order )
        reset_default( id, source );
}

// How many settings differ from their default.
changed_count()
{
    count = 0;

    foreach ( id in level.ix.config.order )
    {
        setting = level.ix.config.settings[id];

        if ( setting.text != to_text( setting, setting.default_value ) )
            count++;
    }

    return count;
}

// Stores a valid value, mirrors it to the dvar, saves it, and tells on_change.
apply( setting, value, source )
{
    old_value = setting.value;
    setting.value = value;
    setting.text = to_text( setting, value );

    if ( getdvar( setting.dvar ) != setting.text )
        setdvar( setting.dvar, setting.text );

    custom_scripts\ix\core\persist::save( setting.dvar, setting.text );

    if ( to_text( setting, old_value ) == setting.text )
        return;

    custom_scripts\ix\core\log::info( "setting " + setting.id + " = " + setting.text + " (" + source + ")" );
    level notify( "ix_setting_changed", setting.id );

    if ( isdefined( setting.on_change ) )
        level thread [[ setting.on_change ]]( value, old_value, setting.id );
}

// The value text means for this setting, or undefined when it means nothing.
parse( setting, text )
{
    text = tolower( text );

    switch ( setting.type )
    {
        case "bool":
            return custom_scripts\ix\core\util::parse_bool( text );
        case "int":
            if ( !custom_scripts\ix\core\util::is_number( text, 0 ) )
                return undefined;

            return clamp( int( text ), setting.min, setting.max );
        case "float":
            if ( !custom_scripts\ix\core\util::is_number( text, 1 ) )
                return undefined;

            return clamp( float( text ), setting.min, setting.max );
        case "enum":
            if ( custom_scripts\ix\core\util::array_contains( setting.options, text ) )
                return text;

            return undefined;
    }

    return undefined;
}

to_text( setting, value )
{
    if ( setting.type == "bool" )
    {
        if ( value )
            return "1";

        return "0";
    }

    return "" + value;
}

// "on or off", "a whole number from 0 to 2", "one of: off, unlocked, all".
describe_range( setting )
{
    switch ( setting.type )
    {
        case "bool":
            return "1 or 0";
        case "int":
            return "a whole number from " + setting.min + " to " + setting.max;
        case "float":
            return "a number from " + setting.min + " to " + setting.max;
        case "enum":
            return "one of: " + custom_scripts\ix\core\util::join( setting.options, ", " );
    }

    return "valid";
}

// Polls every ix_<id> dvar for changes made in the console.
watch_dvars()
{
    level endon( "game_ended" );

    for (;;)
    {
        wait 0.5;

        foreach ( id in level.ix.config.order )
        {
            setting = level.ix.config.settings[id];
            found = getdvar( setting.dvar );

            if ( found == setting.text )
                continue;

            // Cleared in the console: back to the default.
            if ( found == "" )
            {
                apply( setting, setting.default_value, "console" );
                continue;
            }

            parsed = parse( setting, found );

            if ( !isdefined( parsed ) )
            {
                custom_scripts\ix\core\log::warn( setting.dvar + " '" + found + "' is not " + describe_range( setting ) + "; it stays " + setting.text );
                setdvar( setting.dvar, setting.text );
                continue;
            }

            apply( setting, parsed, "console" );
        }
    }
}
