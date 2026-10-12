// Infinite Expansion - zombie speed, zombie health and the most zombies alive
// at once (Phase 7).
//
// What the stock zombies scripts do (IW_API_NOTES.md section 20):
//   - speed: every zombie runs a loop (mp\agents\zombie\zombie_agent.gsc)
//     that picks its move mode once ("slow_walk", "walk", "run" or "sprint",
//     faster in later rounds) and then, about once a second (at once on the
//     zombie's notify "speed_debuffs_changed", which only that loop waits
//     for), asks the hook level.movemodefunc[agent type] when there is one.
//     The stock hook only makes a round's last zombie run; on Spaceland the
//     map's own agent setup can leave regular zombies without one. The mod
//     puts its own hook in place for regular zombies and cops, whether or not
//     the game has one (clowns and skeletons always sprint and are left
//     alone): default asks the stock hook, if any; walk / run / sprint return
//     that mode. A zombie a trap is moving (scripted_mode) is left to the
//     game. A change reaches the zombies already out at once; back to
//     default, they keep their speed and new ones move as the game picks.
//     The hook is checked every second and put back if the game made the
//     table anew.
//   - health: the stock calculatezombiehealth() multiplies a zombie's health
//     by level._id_8CB3[type] when it is set; nothing in the game sets it, and
//     the spawner's setup empties it. The mod sets it for the regular zombie
//     types, so zombies that spawn afterwards get it, and scales the health
//     of the regular zombies already out when the option changes.
//   - most alive: level.max_static_spawned_enemies, which the wave loop sets
//     to 24 when a round starts and to 0 when it ends (quests set their own
//     for a while). While a round runs and the option is not 24, the mod sets
//     its own twice a second. Above it, the game itself takes zombies out of
//     view off the map and brings them back later.
//
// Settings:
//   zombie_speed   default  default / walk / run / sprint
//   zombie_health  100      percent of the game's zombie health (10-1000)
//   max_zombies    24       most zombies alive at once (1-64); 24 is the game's

register()
{
    custom_scripts\ix\core\config::add_enum( "zombie_speed", "default", "default walk run sprint", "Zombie speed", "How zombies move. default: the game's mix, faster each round.", ::on_speed_changed );
    custom_scripts\ix\core\config::add_int( "zombie_health", 100, 10, 1000, "Zombie health", "Percent of the game's zombie health, for zombies out now and new ones. 100 is the game's own.", ::on_health_changed );
    custom_scripts\ix\core\config::add_int( "max_zombies", 24, 1, 64, "Max zombies alive", "Most zombies out at once. 24 is the game's own; many more can slow the game down.", ::on_max_changed );

    level.ix.zombies.stock_movemode = [];
    custom_scripts\ix\zombies\zombies::on_ready( ::apply );
    level thread keep_speed_hook();
    level thread keep_max_zombies();
}

// At the spawner's setup and every round start.
apply()
{
    hook_speed();
    apply_health();
}

// Regular zombies alive now (the types both options change).
regular_zombies( types )
{
    found = [];

    if ( !isdefined( level.agentarray ) )
        return found;

    foreach ( agent in level.agentarray )
    {
        if ( isalive( agent ) && isdefined( agent.team ) && agent.team == "axis" && isdefined( agent.agent_type ) && custom_scripts\ix\core\util::array_contains( types, agent.agent_type ) )
            found[found.size] = agent;
    }

    return found;
}

// ---------------------------------------------------------------------------
// Speed

// The zombie types whose speed the option sets: the ones that take the
// stock random pick, so every move mode has its animations.
speed_types()
{
    return [ "generic_zombie", "zombie_cop", "cop_dlc2" ];
}

// Puts the mod's hook in place for each type, in front of the stock one when
// there is one. A marker in the same array ("ix_" + type) shows it is still
// there: a stock agent setup that makes the whole array anew drops the
// marker too. A stock script that swaps one hook for a while (the final boss
// makes every zombie sprint) keeps the marker and puts the mod's hook back
// itself.
hook_speed()
{
    if ( !isdefined( level.movemodefunc ) )
        level.movemodefunc = [];

    hooked = 0;

    foreach ( type in speed_types() )
    {
        if ( isdefined( level.movemodefunc["ix_" + type] ) )
            continue;

        // undefined when the game has no hook for this type.
        level.ix.zombies.stock_movemode[type] = level.movemodefunc[type];
        level.movemodefunc[type] = ::move_mode;
        level.movemodefunc["ix_" + type] = 1;
        hooked++;
    }

    if ( hooked > 0 )
        custom_scripts\ix\core\log::info( "zombies: speed hook in place for " + hooked + " zombie types" );
}

speed_hooked()
{
    return isdefined( level.movemodefunc ) && isdefined( level.movemodefunc["ix_generic_zombie"] );
}

// Once the spawner is set up: the hook is checked every second.
keep_speed_hook()
{
    level endon( "game_ended" );

    for (;;)
    {
        wait 1;

        if ( custom_scripts\ix\zombies\zombies::is_ready() )
            hook_speed();
    }
}

// The hook, on a zombie: its move mode, or undefined to keep the one it has.
move_mode( wave )
{
    speed = custom_scripts\ix\core\config::get( "zombie_speed" );

    if ( speed == "default" || ( isdefined( self.scripted_mode ) && self.scripted_mode ) )
    {
        stock = level.ix.zombies.stock_movemode[self.agent_type];

        if ( isdefined( stock ) )
            return self [[ stock ]]( wave );

        return undefined;
    }

    return speed;
}

// The zombies out now take the new speed at once instead of within a second.
on_speed_changed( value, old_value, id )
{
    if ( !custom_scripts\ix\zombies\zombies::is_ready() )
        return;

    hook_speed();

    foreach ( zombie in regular_zombies( speed_types() ) )
        zombie notify( "speed_debuffs_changed" );
}

// ---------------------------------------------------------------------------
// Health

// The regular zombie types (the bosses, brutes and the rest keep the game's).
health_types()
{
    return [ "generic_zombie", "zombie_cop", "cop_dlc2", "skeleton", "zombie_clown", "skater" ];
}

on_health_changed( value, old_value, id )
{
    if ( !custom_scripts\ix\zombies\zombies::is_ready() )
        return;

    apply_health();

    // The zombies out now: scaled from the old percentage to the new one.
    ratio = value / ( old_value * 1.0 );

    foreach ( zombie in regular_zombies( health_types() ) )
    {
        zombie.maxhealth = int( max( 1, zombie.maxhealth * ratio ) );
        zombie.health = int( max( 1, zombie.health * ratio ) );
    }
}

apply_health()
{
    if ( !isdefined( level._id_8CB3 ) )
        level._id_8CB3 = [];

    percent = custom_scripts\ix\core\config::get( "zombie_health" );

    foreach ( type in health_types() )
    {
        if ( percent == 100 )
            level._id_8CB3[type] = undefined;
        else
            level._id_8CB3[type] = percent / 100.0;
    }
}

// The health percentage new zombies get (the Debug page's read-out).
health_scale()
{
    if ( !isdefined( level._id_8CB3 ) || !isdefined( level._id_8CB3["generic_zombie"] ) )
        return 100;

    return int( level._id_8CB3["generic_zombie"] * 100 + 0.5 );
}

// ---------------------------------------------------------------------------
// Most alive at once

on_max_changed( value, old_value, id )
{
    // Back to the game's 24 during a round: at once, not at the next round.
    if ( value == 24 && isdefined( level.max_static_spawned_enemies ) && level.max_static_spawned_enemies > 0 )
        level.max_static_spawned_enemies = 24;
}

keep_max_zombies()
{
    level endon( "game_ended" );

    for (;;)
    {
        wait 0.5;
        wanted = custom_scripts\ix\core\config::get( "max_zombies" );

        // 0: between rounds, before the first, and at a map event's end.
        if ( wanted == 24 || !isdefined( level.max_static_spawned_enemies ) || level.max_static_spawned_enemies <= 0 )
            continue;

        if ( level.max_static_spawned_enemies != wanted )
            level.max_static_spawned_enemies = wanted;
    }
}
