// Infinite Expansion - feature manager.
//
// A feature is something that can be switched on and off while playing. Each
// one is backed by an on/off setting with the same id (config.gsc), so the
// console (set ix_<id> 1), the chat commands and later the menu all switch it
// the same way. A module adds a feature in its register() and sets its hooks:
//
//   feature = custom_scripts\ix\core\features::add( "menu", "ui", "In-game menu", "...", 1 );
//   feature.on_enable = ::enable_x;     global: runs once when switched on
//   feature.on_disable = ::disable_x;   global: must undo everything on_enable did
//   feature.on_player = ::apply_x;      per player, self = player, argument 1/0:
//                                       on every player when switched, and on each
//                                       spawn while on
//   feature.requires[feature.requires.size] = "dvar:bg_omnimovement";
//
// Requirements: "dvar:<name>" (the client has that dvar, compat.gsc) and
// "fs_game" (the mod was loaded from the Mods menu). A feature whose
// requirements are missing stays off, and switching it on is refused.
//
// Nothing is applied before "ix_ready": the stock maps set their callbacks up
// first. Global features that are on then start; player features follow each
// player's spawns.

setup()
{
    level.ix.features = spawnstruct();
    level.ix.features.list = [];
    level.ix.features.order = [];
    custom_scripts\ix\core\events::subscribe( "player_spawn", ::on_player_spawn );
    level thread start_when_ready();
}

add( id, category, label, help, default_on )
{
    if ( isdefined( level.ix.features.list[id] ) )
    {
        custom_scripts\ix\core\log::warn( "features: '" + id + "' added twice; the first one stays" );
        return level.ix.features.list[id];
    }

    feature = spawnstruct();
    feature.id = id;
    feature.category = category;
    feature.label = label;
    feature.requires = [];
    feature.active = 0;
    level.ix.features.list[id] = feature;
    level.ix.features.order[level.ix.features.order.size] = id;
    custom_scripts\ix\core\config::add_bool( id, default_on, label, help, ::on_setting_changed );
    return feature;
}

find( id )
{
    if ( !isdefined( level.ix ) || !isdefined( level.ix.features ) || !isstring( id ) )
        return undefined;

    return level.ix.features.list[tolower( id )];
}

is_feature( id )
{
    return isdefined( find( id ) );
}

// On, and everything it needs is there.
is_enabled( id )
{
    feature = find( id );

    if ( !isdefined( feature ) )
        return 0;

    return custom_scripts\ix\core\config::get( feature.id ) && missing_requirement( feature ) == "";
}

enable( id, source )
{
    return custom_scripts\ix\core\config::set( id, 1, source );
}

disable( id, source )
{
    return custom_scripts\ix\core\config::set( id, 0, source );
}

toggle( id, source )
{
    return custom_scripts\ix\core\config::set( id, !custom_scripts\ix\core\config::get( id ), source );
}

// The first requirement the client does not meet, or "".
missing_requirement( feature )
{
    foreach ( requirement in feature.requires )
    {
        if ( custom_scripts\ix\core\util::starts_with( requirement, "dvar:" ) )
        {
            name = getsubstr( requirement, 5, requirement.size );

            if ( !custom_scripts\ix\core\compat::has_dvar( name ) )
                return requirement;
        }
        else if ( requirement == "fs_game" )
        {
            if ( !level.ix.client.has_fs_game )
                return requirement;
        }
        else
            return requirement;
    }

    return "";
}

// The setting changed (console, chat or menu).
on_setting_changed( value, old_value, id )
{
    feature = find( id );

    if ( value && missing_requirement( feature ) != "" )
    {
        custom_scripts\ix\core\log::warn( "feature " + id + " needs " + missing_requirement( feature ) + "; it stays off" );
        custom_scripts\ix\core\config::set( id, 0, "requirement" );
        return;
    }

    if ( level.ix.ready )
        apply( feature, value );
}

start_when_ready()
{
    level endon( "game_ended" );

    if ( !level.ix.ready )
        level waittill( "ix_ready" );

    foreach ( id in level.ix.features.order )
    {
        feature = level.ix.features.list[id];

        if ( !custom_scripts\ix\core\config::get( id ) )
            continue;

        if ( missing_requirement( feature ) != "" )
        {
            custom_scripts\ix\core\log::warn( "feature " + id + " needs " + missing_requirement( feature ) + "; it stays off" );
            continue;
        }

        apply( feature, 1 );
    }
}

apply( feature, enabled )
{
    if ( enabled && !feature.active && isdefined( feature.on_enable ) )
        level [[ feature.on_enable ]]();
    else if ( !enabled && feature.active && isdefined( feature.on_disable ) )
        level [[ feature.on_disable ]]();

    feature.active = enabled;

    if ( !isdefined( feature.on_player ) || !isdefined( level.players ) )
        return;

    foreach ( player in level.players )
        player thread [[ feature.on_player ]]( enabled );
}

on_player_spawn( player )
{
    if ( !custom_scripts\ix\core\util::is_valid_player( player ) )
        return;

    foreach ( id in level.ix.features.order )
    {
        feature = level.ix.features.list[id];

        if ( isdefined( feature.on_player ) && is_enabled( id ) )
            player thread [[ feature.on_player ]]( 1 );
    }
}
