// Infinite Expansion - zombies module (Phase 7).
//
// Zombies options, one file each so one can be switched off or fixed alone:
//   agents.gsc   zombie speed, zombie health, most zombies alive at once
//   rounds.gsc   the round a match starts at
//   points.gsc   points multiplier, power-ups per round
//   perks.gsc    every perk at each spawn
// and the round and zombie counts the HUD and the Debug page show: the stock
// wave loop's own variables (IW_API_NOTES.md section 6:
// scripts\cp\zombies\zombies_spawning.gsc) and the agents alive.
//
// The stock spawner's setup (zombies_spawning.gsc enemy_spawner_init) clears
// the tables some options write to. It has run once the flag
// "init_spawn_volumes_done" is set, well before the first round: the options
// apply then, and again at the start of every round.

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "zombies" );

    level.ix.zombies = spawnstruct();
    level.ix.zombies.ready = 0;
    level.ix.zombies.appliers = [];

    custom_scripts\ix\zombies\agents::register();
    custom_scripts\ix\zombies\rounds::register();
    custom_scripts\ix\zombies\points::register();
    custom_scripts\ix\zombies\perks::register();

    custom_scripts\ix\core\events::subscribe( "round_start", ::on_round_start );
    level thread wait_for_spawner();
}

// fn runs on level once the stock spawner is set up, and again at the start
// of every round. It must not wait.
on_ready( fn )
{
    level.ix.zombies.appliers[level.ix.zombies.appliers.size] = fn;
}

is_ready()
{
    return isdefined( level.ix.zombies ) && level.ix.zombies.ready;
}

wait_for_spawner()
{
    level endon( "game_ended" );

    while ( !spawner_ready() )
        wait 0.25;

    level.ix.zombies.ready = 1;
    custom_scripts\ix\core\log::debug( "zombies: the stock spawner is set up" );
    apply_all();
}

spawner_ready()
{
    return scripts\engine\utility::flag_exist( "init_spawn_volumes_done" ) && scripts\engine\utility::flag( "init_spawn_volumes_done" );
}

on_round_start( wave )
{
    if ( is_ready() )
        apply_all();
}

apply_all()
{
    foreach ( fn in level.ix.zombies.appliers )
        level [[ fn ]]();
}

// ---------------------------------------------------------------------------
// Counts

// The round being played (0 before the first one).
round_number()
{
    if ( isdefined( level.wave_num ) )
        return level.wave_num;

    return 0;
}

// Zombies still to kill this round, alive or yet to spawn.
zombies_left()
{
    if ( !isdefined( level.desired_enemy_deaths_this_wave ) || !isdefined( level.current_enemy_deaths ) )
        return 0;

    return int( max( 0, level.desired_enemy_deaths_this_wave - level.current_enemy_deaths ) );
}

// Enemies alive now: every live agent on the zombies' team, brutes and
// bosses included, as the stock getaliveagentsofteam( "axis" ) counts them
// (scripts\cp\cp_agent_utils.gsc). (The wave loop's own
// level.current_num_spawned_enemies leaves brutes out and drifts on
// Spaceland, where the coaster's zombies are taken off it but never added.)
zombies_alive()
{
    if ( !isdefined( level.agentarray ) )
        return 0;

    count = 0;

    foreach ( agent in level.agentarray )
    {
        if ( isalive( agent ) && isdefined( agent.team ) && agent.team == "axis" )
            count++;
    }

    return count;
}
