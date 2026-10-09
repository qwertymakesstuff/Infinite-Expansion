// Infinite Expansion - zombie speed, zombie health and the most zombies alive
// at once (Phase 7).
//
// What the stock zombies scripts do (IW_API_NOTES.md section 20):
//   - speed: every zombie runs a loop (mp\agents\zombie\zombie_agent.gsc)
//     that picks its move mode once ("slow_walk", "walk", "run" or "sprint",
//     faster in later rounds) and then, about once a second, asks the hook
//     level.movemodefunc[agent type]. The stock hook only makes a round's last
//     zombie run. The mod puts its own hook in front of the stock one for
//     regular zombies and cops (clowns and skeletons always sprint and are
//     left alone): default asks the stock hook; walk / run / sprint return
//     that mode. A zombie a trap is moving (scripted_mode) is left to the
//     game. Back to default, zombies already out keep their speed; new ones
//     move as the game picks.
//   - health: the stock calculatezombiehealth() multiplies a zombie's health
//     by level._id_8CB3[type] when it is set; nothing in the game sets it, and
//     the spawner's setup empties it. The mod sets it for the regular zombie
//     types. It applies to zombies that spawn afterwards.
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
    custom_scripts\ix\core\config::add_enum( "zombie_speed", "default", "default walk run sprint", "Zombie speed", "How zombies move. default: the game's mix, faster each round.", undefined );
    custom_scripts\ix\core\config::add_int( "zombie_health", 100, 10, 1000, "Zombie health", "Percent of the game's zombie health, for zombies that spawn from now on. 100 is the game's own.", ::on_health_changed );
    custom_scripts\ix\core\config::add_int( "max_zombies", 24, 1, 64, "Max zombies alive", "Most zombies out at once. 24 is the game's own; many more can slow the game down.", ::on_max_changed );

    level.ix.zombies.stock_movemode = [];
    custom_scripts\ix\zombies\zombies::on_ready( ::apply );
    level thread keep_max_zombies();
}

// At the spawner's setup and every round start.
apply()
{
    hook_speed();
    apply_health();
}

// ---------------------------------------------------------------------------
// Speed

// The zombie types whose speed the option sets: the ones that take the
// stock random pick, so every move mode has its animations.
speed_types()
{
    return [ "generic_zombie", "zombie_cop", "cop_dlc2" ];
}

// Puts the mod's hook in front of each type's stock hook. A marker in the
// same array ("ix_" + type) shows it is still there: the stock agent setup
// makes the whole array anew at map load, which drops the marker too. A
// stock script that swaps one hook for a while (the final boss makes every
// zombie sprint) keeps the marker and puts the mod's hook back itself.
hook_speed()
{
    if ( !isdefined( level.movemodefunc ) )
        return;

    foreach ( type in speed_types() )
    {
        if ( !isdefined( level.movemodefunc[type] ) || isdefined( level.movemodefunc["ix_" + type] ) )
            continue;

        level.ix.zombies.stock_movemode[type] = level.movemodefunc[type];
        level.movemodefunc[type] = ::move_mode;
        level.movemodefunc["ix_" + type] = 1;
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

// ---------------------------------------------------------------------------
// Health

// The regular zombie types (the bosses, brutes and the rest keep the game's).
health_types()
{
    return [ "generic_zombie", "zombie_cop", "cop_dlc2", "skeleton", "zombie_clown", "skater" ];
}

on_health_changed( value, old_value, id )
{
    if ( custom_scripts\ix\zombies\zombies::is_ready() )
        apply_health();
}

apply_health()
{
    if ( !isdefined( level._id_8CB3 ) )
        return;

    percent = custom_scripts\ix\core\config::get( "zombie_health" );

    foreach ( type in health_types() )
    {
        if ( percent == 100 )
            level._id_8CB3[type] = undefined;
        else
            level._id_8CB3[type] = percent / 100.0;
    }
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
