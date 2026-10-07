// Infinite Expansion - chat commands.
//
// Typed in the game's chat (iw7-mod reports every chat line as a "say" notify,
// events.gsc). Replies go to the player who typed, with iw7-mod's tell().
//
//   !ix                          the list of commands
//   !ix list [word]              settings and their values, optionally only ids containing word
//   !ix get <setting>            a setting's value, default and valid values
//   !ix set <setting> <value>    change a setting (host)
//   !ix on <setting>             switch an on/off setting on (host)
//   !ix off <setting>            ... off (host)
//   !ix reset <setting> | all    back to the default (host)
//   !ix version
// Modules add their own with add_command (the menu: "!ix menu").
//
// Settings apply to the whole match, so only the host may change them. Values
// go through config.gsc, which refuses anything outside a setting's range.

setup()
{
    level.ix.chat = spawnstruct();
    level.ix.chat.commands = [];
    level.ix.chat.order = [];
    custom_scripts\ix\core\events::subscribe( "chat", ::on_chat );
}

// A command of a module: "!ix <name> ..." runs player thread [[ fn ]]( words ),
// words being everything typed, split at spaces (words[1] is name).
add_command( name, fn, usage )
{
    command = spawnstruct();
    command.fn = fn;
    command.usage = usage;
    level.ix.chat.commands[name] = command;
    level.ix.chat.order[level.ix.chat.order.size] = name;
}

prefix()
{
    return "!ix";
}

on_chat( player, message )
{
    if ( !custom_scripts\ix\core\util::is_valid_player( player ) || !isstring( message ) )
        return;

    words = strtok( message, " " );

    if ( words.size == 0 || tolower( words[0] ) != prefix() )
        return;

    command = "help";

    if ( words.size > 1 )
        command = tolower( words[1] );

    switch ( command )
    {
        case "list":
            filter = "";

            if ( words.size > 2 )
                filter = tolower( words[2] );

            list( player, filter );
            break;
        case "get":
            if ( words.size < 3 )
                player tell( "Usage: " + prefix() + " get <setting>" );
            else
                show_setting( player, words[2] );
            break;
        case "set":
            if ( words.size < 4 )
                player tell( "Usage: " + prefix() + " set <setting> <value>" );
            else
                change( player, words[2], words[3] );
            break;
        case "on":
        case "off":
            if ( words.size < 3 )
                player tell( "Usage: " + prefix() + " " + command + " <setting>" );
            else
                switch_bool( player, words[2], command == "on" );
            break;
        case "reset":
            if ( words.size < 3 )
                player tell( "Usage: " + prefix() + " reset <setting> | all" );
            else
                reset_command( player, words[2] );
            break;
        case "version":
            player tell( "Infinite Expansion " + level.ix.version );
            break;
        default:
            if ( isdefined( level.ix.chat.commands[command] ) )
                player thread [[ level.ix.chat.commands[command].fn ]]( words );
            else
                help( player );

            break;
    }
}

help( player )
{
    player tell( "Infinite Expansion " + level.ix.version + " commands:" );
    player tell( prefix() + " list [word]  |  " + prefix() + " get <setting>" );
    player tell( prefix() + " set <setting> <value>  |  " + prefix() + " on/off <setting>" );
    player tell( prefix() + " reset <setting> | all  (changes: host only)" );

    foreach ( name in level.ix.chat.order )
        player tell( prefix() + " " + name + "  " + level.ix.chat.commands[name].usage );
}

// "id=value" pairs, a few per chat line.
list( player, filter )
{
    line = "";
    count = 0;

    foreach ( id in level.ix.config.order )
    {
        if ( filter != "" && !issubstr( id, filter ) )
            continue;

        setting = level.ix.config.settings[id];
        pair = id + "=" + setting.text;
        count++;

        if ( line != "" && line.size + pair.size > 90 )
        {
            player tell( line );
            line = "";
        }

        if ( line != "" )
            line += "  ";

        line += pair;
    }

    if ( line != "" )
        player tell( line );

    if ( count == 0 )
        player tell( "No setting matches " + echo( filter ) + "." );
}

show_setting( player, id )
{
    setting = custom_scripts\ix\core\config::find( id );

    if ( !isdefined( setting ) )
    {
        unknown( player, id );
        return;
    }

    player tell( setting.label + ": " + setting.id + " = " + setting.text + " (default " + custom_scripts\ix\core\config::to_text( setting, setting.default_value ) + ", " + custom_scripts\ix\core\config::describe_range( setting ) + ")" );

    if ( isdefined( setting.help ) && setting.help != "" )
        player tell( setting.help );
}

change( player, id, value )
{
    setting = custom_scripts\ix\core\config::find( id );

    if ( !isdefined( setting ) )
    {
        unknown( player, id );
        return;
    }

    if ( !host_only( player ) )
        return;

    if ( !custom_scripts\ix\core\config::set( setting.id, value, "chat, " + player.name ) )
    {
        player tell( setting.id + ": " + echo( value ) + " is not " + custom_scripts\ix\core\config::describe_range( setting ) + "." );
        return;
    }

    player tell( setting.label + ": " + setting.id + " = " + setting.text );
}

switch_bool( player, id, on )
{
    setting = custom_scripts\ix\core\config::find( id );

    if ( !isdefined( setting ) )
    {
        unknown( player, id );
        return;
    }

    if ( setting.type != "bool" )
    {
        player tell( setting.id + " is not an on/off setting: " + prefix() + " set " + setting.id + " <value>" );
        return;
    }

    change( player, setting.id, "" + on );
}

reset_command( player, id )
{
    if ( tolower( id ) == "all" )
    {
        if ( !host_only( player ) )
            return;

        custom_scripts\ix\core\config::reset_all( "chat, " + player.name );
        player tell( "Every setting is back to its default." );
        return;
    }

    setting = custom_scripts\ix\core\config::find( id );

    if ( !isdefined( setting ) )
    {
        unknown( player, id );
        return;
    }

    if ( !host_only( player ) )
        return;

    custom_scripts\ix\core\config::reset_default( setting.id, "chat, " + player.name );
    player tell( setting.label + ": " + setting.id + " = " + setting.text + " (default)" );
}

host_only( player )
{
    if ( player ishost() )
        return 1;

    player tell( "Only the host can change settings." );
    return 0;
}

unknown( player, id )
{
    player tell( "No setting " + echo( id ) + ". " + prefix() + " list shows them all." );
}

// Typed text, quoted, only when it is a plain word: tell() sends the reply as a
// quoted server command, which a stray quote in it would break.
echo( text )
{
    if ( custom_scripts\ix\core\persist::is_safe( text ) )
        return "'" + text + "'";

    return "that";
}
