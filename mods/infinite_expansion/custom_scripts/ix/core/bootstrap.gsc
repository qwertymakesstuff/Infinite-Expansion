// Infinite Expansion - bootstrap.
//
// Called once per level load by the entry script. It owns the init order, the
// duplicate-init guard, the master switch and the lifecycle notifies the rest
// of the mod builds on:
//
//   level notify( "ix_ready" )                       once, at the end of the frame in which
//                                                    the first player connects. The stock
//                                                    zombies maps assign their callbacks in
//                                                    main(), which never waits, so this is
//                                                    after them
//   level notify( "ix_player_connected", player )    once per player per level load
//   level notify( "ix_player_spawned", player )      every "spawned_player"
//   level notify( "ix_shutdown" )                    on "game_ended"
//
// Feature modules expose register() and core files setup(); only entry scripts
// define init(), because iw7-mod runs the init() of every file it auto-loads.
// bootstrap calls them synchronously, core first, then modules in the order the
// entry script lists them. They must not wait; anything that waits runs in its
// own thread.

start( modules )
{
    if ( isdefined( level.ix ) )
    {
        custom_scripts\ix\core\log::warn( "start() called again in the same level load; ignored" );
        return;
    }

    if ( getdvar( "ix_enabled" ) == "0" )
    {
        custom_scripts\ix\core\log::info( "disabled by dvar ix_enabled 0" );
        return;
    }

    level.ix = spawnstruct();
    level.ix.version = "0.1.1";
    level.ix.map = getdvar( "mapname" );
    level.ix.ready = 0;
    level.ix.modules = [];
    setdvar( "ix_version", level.ix.version );

    custom_scripts\ix\core\log::setup();
    custom_scripts\ix\core\compat::setup();

    foreach ( module_register in modules )
        [[ module_register ]]();

    custom_scripts\ix\core\log::info( "init " + level.ix.version + " map=" + level.ix.map + " modules=" + custom_scripts\ix\core\util::join( level.ix.modules, "," ) );
    custom_scripts\ix\core\log::info( "client " + custom_scripts\ix\core\compat::describe() );

    level thread wait_until_ready();
    level thread watch_players();
    level thread watch_shutdown();
}

// Called by each module's register() so the init log lists what actually ran.
register_module( name )
{
    level.ix.modules[level.ix.modules.size] = name;
}

wait_until_ready()
{
    level endon( "game_ended" );

    level waittill( "connected" );
    waittillframeend;
    level.ix.ready = 1;
    level notify( "ix_ready" );
    custom_scripts\ix\core\log::info( "ready" );
}

watch_players()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "connected", player );
        player thread player_lifecycle();
    }
}

// Runs on the player. The spawn watcher starts immediately: in zombies the
// first spawn follows "connected" after a single waittillframeend
// (scripts\cp\cp_globallogic::defaultplayerconnect).
player_lifecycle()
{
    if ( isdefined( self.ix ) )
        return;

    self.ix = spawnstruct();
    self.ix.spawn_count = 0;
    custom_scripts\ix\core\log::debug( "player connected: " + self.name );
    level notify( "ix_player_connected", self );
    self thread watch_spawns();
}

watch_spawns()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( "spawned_player" );
        self.ix.spawn_count++;
        custom_scripts\ix\core\log::debug( "player spawned: " + self.name + " (spawn " + self.ix.spawn_count + ")" );
        level notify( "ix_player_spawned", self );
    }
}

watch_shutdown()
{
    level waittill( "game_ended" );
    level notify( "ix_shutdown" );
    custom_scripts\ix\core\log::info( "shutdown" );
}
