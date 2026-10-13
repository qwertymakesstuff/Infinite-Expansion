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
//   - health: the stock spawners give each zombie its health
//     (calculatezombiehealth: by round, cops and skeletons a few rounds
//     ahead) and then notify "agent_spawned". The mod sets the option's share
//     of that health on every regular zombie it is told about, and on the
//     regular zombies already out when the option changes. (Up to 0.10.1 the
//     mod set the stock multiplier table level._id_8CB3 instead; that did
//     not change the zombies in game, KNOWN_LIMITATIONS.md L58.)
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
    // The default is the game's own, stock_max_zombies() (a literal here, which
    // test_settings.py and README.md read).
    custom_scripts\ix\core\config::add_int( "max_zombies", 24, 1, 64, "Max zombies alive", "Most zombies out at once. 24 is the game's own; many more can slow the game down.", ::on_max_changed );

    level.ix.zombies.stock_movemode = [];
    custom_scripts\ix\zombies\zombies::on_ready( ::apply );
    level thread keep_speed_hook();
    level thread watch_spawns();
    level thread keep_max_zombies();
}

// At the spawner's setup and every round start.
apply()
{
    hook_speed();
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

// Every new zombie, as the game spawns it. The stock spawners give a zombie
// its health (calculatezombiehealth) before they notify "agent_spawned"
// (zombies_spawning.gsc and each DLC map's own spawning script).
watch_spawns()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "agent_spawned", agent );

        if ( isdefined( agent ) && isalive( agent ) && isdefined( agent.agent_type ) && custom_scripts\ix\core\util::array_contains( health_types(), agent.agent_type ) )
            scale_new_zombie( agent );
    }
}

// Remembers the game's health and sets the option's share of it. A zombie the
// game took off the map and brings back (level.respawn_data) starts with the
// health it had, already scaled: only a fresh one, whose health is still the
// game's full value, is set to the new full value.
scale_new_zombie( zombie )
{
    stock = zombie.maxhealth;
    percent = custom_scripts\ix\core\config::get( "zombie_health" );
    zombie.ix_stock_health = stock;
    zombie.ix_health_percent = percent;

    if ( percent == 100 )
        return;

    wanted = scaled_health( stock, percent );

    if ( zombie.health == stock )
        zombie.health = wanted;
    else
        zombie.health = int( max( 1, min( zombie.health, wanted ) ) );

    zombie.maxhealth = wanted;

    if ( !isdefined( level.ix.zombies.health_logged ) )
    {
        level.ix.zombies.health_logged = 1;
        custom_scripts\ix\core\log::info( "zombies: health " + wanted + " for a " + zombie.agent_type + " (the game's " + stock + ")" );
    }
}

scaled_health( stock, percent )
{
    return int( max( 1, stock * percent / 100.0 ) );
}

// The game's own full health of a zombie out now: remembered at its spawn, or
// worked out from its health when it came another way.
stock_health( zombie, percent )
{
    if ( isdefined( zombie.ix_stock_health ) && isdefined( zombie.ix_health_percent ) && zombie.ix_health_percent == percent )
    {
        if ( percent == 100 && zombie.maxhealth == zombie.ix_stock_health )
            return zombie.ix_stock_health;

        if ( percent != 100 && zombie.maxhealth == scaled_health( zombie.ix_stock_health, percent ) )
            return zombie.ix_stock_health;
    }

    return int( max( 1, zombie.maxhealth * 100.0 / percent ) );
}

// The zombies out now get the new share at once, keeping how hurt they are.
on_health_changed( value, old_value, id )
{
    count = 0;

    foreach ( zombie in regular_zombies( health_types() ) )
    {
        stock = stock_health( zombie, old_value );
        wanted = scaled_health( stock, value );
        zombie.health = int( max( 1, zombie.health * wanted / ( max( 1, zombie.maxhealth ) * 1.0 ) ) );
        zombie.maxhealth = wanted;
        zombie.ix_stock_health = stock;
        zombie.ix_health_percent = value;
        count++;
    }

    level.ix.zombies.health_logged = undefined;
    level thread say_health_changed( value, count );
}

// One line once the value stops changing (A / D held down steps it fast).
say_health_changed( value, count )
{
    level notify( "ix_zombie_health_said" );
    level endon( "ix_zombie_health_said" );
    level endon( "game_ended" );
    wait 1;

    custom_scripts\ix\core\log::info( "zombies: health " + value + " percent; " + count + " zombies out changed" );

    foreach ( player in level.players )
    {
        if ( custom_scripts\ix\core\util::is_valid_player( player ) )
            player iprintln( "Zombie health " + value + " percent: " + count + " zombies out now and every new one." );
    }
}

// A regular zombie out now (the In effect now read-outs), or undefined.
sample_zombie()
{
    zombies = regular_zombies( health_types() );

    if ( zombies.size == 0 )
        return undefined;

    return zombies[0];
}

// ---------------------------------------------------------------------------
// Most alive at once

// What the wave loop sets when a round starts (zombies_spawning.gsc).
stock_max_zombies()
{
    return 24;
}

on_max_changed( value, old_value, id )
{
    // Back to the game's own during a round: at once, not at the next round.
    if ( value == stock_max_zombies() && isdefined( level.max_static_spawned_enemies ) && level.max_static_spawned_enemies > 0 )
        level.max_static_spawned_enemies = stock_max_zombies();
}

keep_max_zombies()
{
    level endon( "game_ended" );

    for (;;)
    {
        // The game's own number: asleep until a setting changes.
        if ( custom_scripts\ix\core\config::get( "max_zombies" ) == stock_max_zombies() )
        {
            custom_scripts\ix\core\config::wait_for_change();
            continue;
        }

        wait 0.5;
        wanted = custom_scripts\ix\core\config::get( "max_zombies" );

        // 0: between rounds, before the first, and at a map event's end.
        if ( wanted == stock_max_zombies() || !isdefined( level.max_static_spawned_enemies ) || level.max_static_spawned_enemies <= 0 )
            continue;

        if ( level.max_static_spawned_enemies != wanted )
            level.max_static_spawned_enemies = wanted;
    }
}
