// Infinite Expansion - ammo: unlimited ammo, unlimited grenades, max ammo at
// spawn, and a refill for everyone (Phase 6).
//
// The mod does what the stock zombies scripts do for their own power-ups
// (IW_API_NOTES.md section 10):
//   - unlimited ammo "clip": the Infinite Ammo power-up (scripts\cp\loot.gsc
//     unlimited_ammo) fills the current weapon's clip, both hands, every
//     0.05 s, except the weapons in level.opweaponsarray (Venom-X). No reload.
//   - unlimited ammo "reserve": the Max Ammo power-up (loot.gsc
//     give_max_ammo_to_player) gives each primary weapon its max ammo with
//     givemaxammo, and fills the clip of a weapon that has no reserve.
//     Reloads still happen. Here every half second.
//   - unlimited grenades: grenades are "powers" with charges in zombies
//     (scripts\cp\powers\coop_powers.gsc); Max Ammo tops up every power that
//     is not in the "secondary" slot with loot.gsc recharge_power. The mod does
//     the same whenever one has been used. The stock Infinite Grenades
//     power-up uses level.infinite_grenades instead, which the power-up itself
//     clears when it ends, so the mod leaves that flag alone.
//   - start with max ammo: Max Ammo (give_max_ammo_to_player) a second after
//     each spawn, when the game has given the starting weapons.
//   - Refill ammo (a menu action, host only): Max Ammo for every player who is
//     not down.
//
// Settings:
//   unlimited_ammo      off  off / reserve / clip
//   unlimited_grenades  0    1: lethal grenades never run out
//   start_max_ammo      0    1: max ammo at every spawn

register()
{
    custom_scripts\ix\core\config::add_enum( "unlimited_ammo", "off", "off reserve clip", "Unlimited ammo", "reserve: spare ammo stays full, you still reload. clip: the clip stays full, no reloading.", undefined );
    custom_scripts\ix\core\config::add_bool( "unlimited_grenades", 0, "Unlimited grenades", "Lethal grenades never run out.", undefined );
    custom_scripts\ix\core\config::add_bool( "start_max_ammo", 0, "Start with max ammo", "Every player gets max ammo a second after spawning.", undefined );

    custom_scripts\ix\core\events::subscribe( "player_connect", ::on_connect );
    custom_scripts\ix\core\events::subscribe( "player_spawn", ::on_spawn );
}

on_connect( player, arg )
{
    if ( custom_scripts\ix\core\util::is_valid_player( player ) )
    {
        player thread keep_clip_full();
        player thread keep_reserve_full();
    }
}

on_spawn( player, arg )
{
    if ( custom_scripts\ix\core\util::is_valid_player( player ) && custom_scripts\ix\core\config::get( "start_max_ammo" ) )
        player thread max_ammo_after_spawn();
}

// After the game's own loadout (zombies_loadout.gsc gives it 0.1 s after the
// spawn).
max_ammo_after_spawn()
{
    self endon( "disconnect" );
    self endon( "death" );
    wait 1;

    if ( can_have_ammo() )
        self scripts\cp\loot::give_max_ammo_to_player( self );
}

// Refill ammo (menu action): every player as with a Max Ammo power-up.
refill_everyone()
{
    count = 0;

    foreach ( player in level.players )
    {
        if ( !custom_scripts\ix\core\util::is_valid_player( player ) || !player can_have_ammo() )
            continue;

        player scripts\cp\loot::give_max_ammo_to_player( player );
        count++;
    }

    self iprintln( "Ammo and grenades refilled for " + count + " player(s)." );
}

// unlimited_ammo clip: as the Infinite Ammo power-up, every 0.05 s.
keep_clip_full()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        wait 0.05;

        if ( custom_scripts\ix\core\config::get( "unlimited_ammo" ) != "clip" || !can_have_ammo() )
            continue;

        current = self getcurrentweapon();

        foreach ( weapon in self getweaponslistprimaries() )
        {
            if ( weapon != current || is_excluded( weapon ) )
                continue;

            self setweaponammoclip( weapon, weaponclipsize( weapon ), "left" );
            self setweaponammoclip( weapon, weaponclipsize( weapon ), "right" );
        }
    }
}

// unlimited_ammo reserve and unlimited_grenades: every half second.
keep_reserve_full()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        wait 0.5;

        if ( !can_have_ammo() )
            continue;

        if ( custom_scripts\ix\core\config::get( "unlimited_ammo" ) == "reserve" )
            refill_reserve();

        if ( custom_scripts\ix\core\config::get( "unlimited_grenades" ) )
            refill_grenades();
    }
}

// The primary weapons' half of give_max_ammo_to_player (loot.gsc).
refill_reserve()
{
    foreach ( weapon in self getweaponslistprimaries() )
    {
        if ( is_excluded( weapon ) )
            continue;

        parts = strtok( weapon, "_" );

        if ( parts[0] != "alt" )
            self givemaxammo( weapon );

        if ( weaponmaxammo( weapon ) == weaponclipsize( weapon ) )
            self setweaponammoclip( weapon, weaponclipsize( weapon ) );
    }
}

// The powers' half: each one not in the secondary slot that has been used.
refill_grenades()
{
    if ( !isdefined( self.powers ) || !isdefined( level.powers ) )
        return;

    foreach ( key in getarraykeys( self.powers ) )
    {
        power = self.powers[key];

        if ( !isdefined( power ) || !isdefined( power.slot ) || power.slot == "secondary" || !isdefined( level.powers[key] ) )
            continue;

        if ( isdefined( power.charges ) && power.charges < level.powers[key].maxcharges )
            self scripts\cp\loot::recharge_power( key );
    }
}

// Weapons the Infinite Ammo power-up leaves alone (zombie.gsc: Venom-X).
is_excluded( weapon )
{
    if ( !isdefined( level.opweaponsarray ) )
        return 0;

    foreach ( other in level.opweaponsarray )
    {
        if ( weapon == other )
            return 1;
    }

    return 0;
}

// Playing, alive and not down.
can_have_ammo()
{
    if ( !isalive( self ) || !isdefined( self.sessionstate ) || self.sessionstate != "playing" )
        return 0;

    return !( isdefined( self.inlaststand ) && self.inlaststand );
}
