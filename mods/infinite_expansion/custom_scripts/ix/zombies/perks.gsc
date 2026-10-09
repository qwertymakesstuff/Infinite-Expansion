// Infinite Expansion - every perk at each spawn (Phase 7).
//
// The stock "permanent perks" reward (scripts\cp\gametypes\zombie.gsc
// give_permanent_perks) gives a player every perk of the map a second after
// it starts, one a frame, skipping perks the player has: the map's own list
// when it has one (level.all_perk_list), else the ten perks of the first map,
// and without Up N' Atoms in solo (its self-revives come from the machine).
// The mod calls it at each spawn while start_perks is on. Perks lost when a
// player goes down stay lost, as in the game.
//
// Settings:
//   start_perks  0  1: every perk at each spawn

register()
{
    custom_scripts\ix\core\config::add_bool( "start_perks", 0, "Start with perks", "Every player gets every perk of the map a second after spawning.", undefined );
    custom_scripts\ix\core\events::subscribe( "player_spawn", ::on_spawn );
}

on_spawn( player, arg )
{
    if ( !custom_scripts\ix\core\util::is_valid_player( player ) || !custom_scripts\ix\core\config::get( "start_perks" ) )
        return;

    player thread give_perks();
}

give_perks()
{
    self endon( "disconnect" );

    // give_permanent_perks reads level.only_one_player, which the game sets
    // once it knows how many players there are.
    while ( !isdefined( level.only_one_player ) )
        wait 0.25;

    self scripts\cp\gametypes\zombie::give_permanent_perks( self );
}
