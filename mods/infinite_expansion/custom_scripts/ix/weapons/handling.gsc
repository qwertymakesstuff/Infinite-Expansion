// Infinite Expansion - weapon handling: fire rate and recoil (Phase 6).
//
// What the stock zombies scripts do, and what the mod changes
// (IW_API_NOTES.md section 10):
//   - fire rate: setfiretimescaleon( percent ) sets the time between shots as
//     a percentage of the weapon's own, setfiretimescaleoff() ends it. The
//     stock Berserk weapon passive (scripts\cp\cp_weaponpassives.gsc) sets 65
//     on a kill and ends it 2 s later or on a weapon change. The mod sets its
//     own time four times a second while fire_rate is not 100, the faster of
//     the two while Berserk is on, and ends it once when fire_rate goes back
//     to 100 (unless Berserk is on, which ends itself). Through compat.gsc:
//     v1.1.0's compiler does not know these names.
//   - recoil: player_recoilscaleon( percent ) / player_recoilscaleoff(). The
//     stock cp_weapon.gsc sets each weapon's recoil after stance changes,
//     sprints and weapon switches (stancerecoilupdate), and the Deadeye perk
//     sets 0. no_recoil sets 0 four times a second; when it goes off, the
//     stock stancerecoilupdate() puts the weapon's own recoil back (Deadeye's
//     0 stays).
//   Never while the player is down or not playing.
//
// Settings:
//   fire_rate  100  percent of the weapons' fire rate (50-300)
//   no_recoil  0    1: no recoil

register()
{
    custom_scripts\ix\core\config::add_int( "fire_rate", 100, 50, 300, "Fire rate", "Percent of how fast every weapon fires: 200 = twice as fast. 100 is the game's own.", undefined );
    custom_scripts\ix\core\config::add_bool( "no_recoil", 0, "No recoil", "Weapons do not kick when they fire.", undefined );

    custom_scripts\ix\core\events::subscribe( "player_connect", ::on_connect );
}

on_connect( player, arg )
{
    if ( custom_scripts\ix\core\util::is_valid_player( player ) )
        player thread keep_handling();
}

keep_handling()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    fire_rate_set = 0;
    recoil_set = 0;

    for (;;)
    {
        wait 0.25;

        if ( !isalive( self ) || !isdefined( self.sessionstate ) || self.sessionstate != "playing" )
            continue;

        if ( isdefined( self.inlaststand ) && self.inlaststand )
            continue;

        berserk = isdefined( self.berserk ) && self.berserk;
        rate = custom_scripts\ix\core\config::get( "fire_rate" );

        if ( rate != 100 )
        {
            // Time between shots: 200 % fire rate is 50 % of the time.
            time = int( 10000 / rate );

            if ( berserk && time > 65 )
                time = 65;

            self custom_scripts\ix\core\compat::fire_rate_on( time );
            fire_rate_set = 1;
        }
        else if ( fire_rate_set )
        {
            if ( !berserk )
                self custom_scripts\ix\core\compat::fire_rate_off();

            fire_rate_set = 0;
        }

        if ( custom_scripts\ix\core\config::get( "no_recoil" ) )
        {
            self player_recoilscaleon( 0 );
            recoil_set = 1;
        }
        else if ( recoil_set )
        {
            if ( !( isdefined( self.onhelisniper ) && self.onhelisniper ) )
                self scripts\cp\cp_weapon::stancerecoilupdate( self getstance() );

            recoil_set = 0;
        }
    }
}
