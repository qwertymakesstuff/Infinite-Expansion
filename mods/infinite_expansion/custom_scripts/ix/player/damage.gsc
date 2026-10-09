// Infinite Expansion - damage players take: god mode, damage taken, friendly
// fire, rocket jump.
//
// fall_damage (movement.gsc) is applied here too: falls arrive as MOD_FALLING.
//
// All of a player's damage in zombies goes through level.callbackplayerdamage
// (scripts\mp\callbacksetup::codecallback_playerdamage, 12 arguments). The
// gametype sets scripts\cp\zombies\zombie_damage::callback_zombieplayerdamage;
// cp_rave, cp_disco, cp_town and cp_final set versions of their own, built on
// the same zombie_damage helpers (shouldtakedamage, isfriendlyfire,
// finishplayerdamagewrapper). Maps set it in their main(), which never waits,
// so on "ix_ready" the mod puts on_player_damage() in front of whichever one
// the map chose and passes it the damage it decided on (IW_API_NOTES.md 5.3).
// The stock callback never applies one player's damage to another outside
// hardcore (isfriendlyfire); friendly_fire does that itself, with the stock
// finishplayerdamagewrapper, so going down works as with any other damage.
//
// Settings:
//   god_mode           off   off / host / everyone: no damage at all
//   damage_taken       100   percent of the damage players take (10-500)
//   friendly_fire      off   off: as the game (none); on: players hurt each other,
//                            and can down each other; reflect: the shooter takes it
//   rocket_jump        0     1: your own explosions throw you instead of hurting you
//                            (only those that would hurt you; is_rocket_jump())
//   rocket_jump_power  100   percent of that throw (50-300)

register()
{
    custom_scripts\ix\core\config::add_enum( "god_mode", "off", "off host everyone", "God mode", "No damage at all. host: only the host; everyone: every player.", undefined );
    custom_scripts\ix\core\config::add_int( "damage_taken", 100, 10, 500, "Damage taken", "Percent of the damage players take: 50 takes half, 200 double. 100 is the game's own.", undefined );
    custom_scripts\ix\core\config::add_enum( "friendly_fire", "off", "off on reflect", "Friendly fire", "on: players can hurt and down each other; reflect: the shooter takes the hit.", undefined );
    custom_scripts\ix\core\config::add_bool( "rocket_jump", 0, "Rocket jump", "Your own explosions throw you instead of hurting you.", undefined );
    custom_scripts\ix\core\config::add_int( "rocket_jump_power", 100, 50, 300, "Rocket jump: power", "Percent of the throw.", undefined );

    level.ix.damage = spawnstruct();
    level thread wrap_when_ready();
}

wrap_when_ready()
{
    level endon( "game_ended" );

    if ( !level.ix.ready )
        level waittill( "ix_ready" );

    if ( !isdefined( level.callbackplayerdamage ) )
    {
        custom_scripts\ix\core\log::warn( "player damage: no level.callbackplayerdamage; god mode, damage taken, friendly fire and rocket jump do nothing" );
        return;
    }

    level.ix.damage.stock = level.callbackplayerdamage;
    level.callbackplayerdamage = ::on_player_damage;
    custom_scripts\ix\core\log::debug( "player damage: callback wrapped" );
}

// self: the player taking the damage. Same arguments as the stock callback.
on_player_damage( inflictor, attacker, damage, flags, mod, weapon, point, dir, hit_loc, time_offset, model_index, part_name )
{
    // Falls, with fall_damage OFF (movement.gsc).
    if ( isdefined( mod ) && mod == "MOD_FALLING" && !custom_scripts\ix\core\config::get( "fall_damage" ) )
        return;

    // Before god mode: a rocket jump throws a god-mode player too.
    if ( is_rocket_jump( inflictor, attacker, damage, flags, mod, weapon ) )
    {
        rocket_throw( dir, point );
        return;
    }

    if ( custom_scripts\ix\core\util::applies_to( "god_mode", self ) )
        return;

    if ( is_teammate( attacker ) )
    {
        switch ( custom_scripts\ix\core\config::get( "friendly_fire" ) )
        {
            case "on":
                hurt_by_teammate( inflictor, attacker, damage, flags, mod, weapon, point, dir, hit_loc, time_offset, model_index, part_name );
                return;
            case "reflect":
                reflect( inflictor, attacker, damage, mod );
                return;
        }
    }

    self [[ level.ix.damage.stock ]]( inflictor, attacker, scaled( damage ), flags, mod, weapon, point, dir, hit_loc, time_offset, model_index, part_name );
}

// damage_taken applied; never rounded down to nothing.
scaled( damage )
{
    percent = custom_scripts\ix\core\config::get( "damage_taken" );

    if ( percent == 100 || damage <= 0 )
        return damage;

    return int( max( 1, damage * percent / 100.0 ) );
}

is_splash( mod )
{
    return isdefined( mod ) && ( mod == "MOD_EXPLOSIVE" || mod == "MOD_GRENADE_SPLASH" || mod == "MOD_PROJECTILE_SPLASH" );
}

// Rocket jump: a blast of the player's own that the game would hurt them
// with. The stock callbacks let many of a player's own blasts pass harmlessly
// (the wonder weapons, a meteor, an upgraded G18: the game's own
// get_explosive_damage_on_player gives 0 for them; harpoons, Venom-X,
// shuriken, fireworks and IMS: zeroed by the callbacks themselves); those
// still do nothing. A downed player is never thrown.
is_rocket_jump( inflictor, attacker, damage, flags, mod, weapon )
{
    if ( !isdefined( attacker ) || attacker != self || !is_splash( mod ) || !isdefined( weapon ) )
        return 0;

    if ( !custom_scripts\ix\core\config::get( "rocket_jump" ) )
        return 0;

    if ( isdefined( self.inlaststand ) && self.inlaststand )
        return 0;

    if ( is_harmless_to_owner( weapon ) )
        return 0;

    return scripts\cp\zombies\zombie_damage::get_explosive_damage_on_player( inflictor, attacker, damage, flags, mod, weapon ) > 0;
}

// The own-blast weapons the stock callbacks zero by name (zombie_damage.gsc
// and cp_rave / cp_disco / cp_town / cp_final's *_damage.gsc).
is_harmless_to_owner( weapon )
{
    if ( issubstr( weapon, "iw7_harpoon1_zm" ) || issubstr( weapon, "iw7_harpoon2_zm" ) || issubstr( weapon, "iw7_acid_rain_projectile_zm" ) )
        return 1;

    if ( issubstr( weapon, "venomx" ) || issubstr( weapon, "iw7_shuriken_" ) )
        return 1;

    return weapon == "zmb_fireworksprojectile_mp" || weapon == "zmb_imsprojectile_mp";
}

// Another player on this player's team.
is_teammate( attacker )
{
    return isdefined( attacker ) && isplayer( attacker ) && attacker != self && attacker.team == self.team;
}

// friendly_fire on: a teammate's hit, applied the way the stock callback
// applies any other damage (last stand included), with its red flash; the
// pain sounds and lines are left out.
hurt_by_teammate( inflictor, attacker, damage, flags, mod, weapon, point, dir, hit_loc, time_offset, model_index, part_name )
{
    if ( !scripts\cp\zombies\zombie_damage::shouldtakedamage( damage, attacker, weapon, flags ) )
        return;

    damage = scaled( damage );

    if ( damage <= 0 )
        return;

    scripts\cp\zombies\zombie_damage::finishplayerdamagewrapper( inflictor, attacker, damage, flags, mod, weapon, point, dir, hit_loc, time_offset, 0.0, model_index, part_name );
    self notify( "player_damaged" );

    // The red flash the stock callback shows for a hit from anyone.
    self thread scripts\cp\cp_hud_util::zom_player_damage_flash();
}

// friendly_fire reflect: the shooter damages themselves, as the stock
// callback does with ricochet damage in hardcore; their own callback (this
// one) applies it, god mode and damage_taken included.
reflect( inflictor, attacker, damage, mod )
{
    if ( isdefined( inflictor ) )
        attacker dodamage( damage, attacker.origin, attacker, inflictor, mod );
    else
        attacker dodamage( damage, attacker.origin, attacker );
}

// Rocket jump: away from the blast and up, the way the stock scripts throw
// players (setvelocity, e.g. scripts\cp\zombies\zombies_weapons::fling_zombie).
// dir points from the blast to the player; point is the fallback.
rocket_throw( dir, point )
{
    power = custom_scripts\ix\core\config::get( "rocket_jump_power" ) / 100.0;
    away = ( 0, 0, 0 );

    if ( isdefined( dir ) && lengthsquared( dir ) > 0.01 )
        away = vectornormalize( dir );
    else if ( isdefined( point ) && lengthsquared( self.origin - point ) > 1 )
        away = vectornormalize( self.origin - point );

    self setvelocity( self getvelocity() + away * 350 * power + ( 0, 0, 250 * power ) );
}
