// Infinite Expansion - movement options (Phase 5): move speed, gravity, fall
// damage, slide, wall run, double jump, mantle (and iw7-mod's older-style
// mantle), bunny hop, unlimited boost, and three options of iw7-mod's develop
// builds (unlimited sprint, omni-movement, air control).
//
// What the stock zombies scripts do, and what the mod changes
// (IW_API_NOTES.md section 9):
//   - 0.1 s after each spawn, zombies_loadout.gsc gives the player the
//     "zom_suit" and switches double jump, wall run and dodge off and slide on
//     (raw allowdoublejump / allowwallrun / allowdodge / allowslide), sets the
//     boost energy (energy slot 0: 400, refilling at 1000), and switches
//     mantle off (allowmantle 0). The afterlife arcade does the same when a
//     player comes back from it. The mod's options turn those back on
//     ("as in multiplayer"): a thread per player re-applies them four times a
//     second while the player is playing, so the game's own switches at spawn
//     never stick; never while the player is down, in the afterlife arcade or
//     linked to something (a ride, the phone booth). When an option goes back
//     to the game's own, the game's own state is set once.
//   - slide: maps lock it for their own reasons through the stock counter
//     (scripts\engine\utility::allow_slide); Slide ON never undoes such a lock.
//   - move speed and gravity: iw7-mod's g_speed (190) and bg_gravity (800),
//     replicated and global; the stock zombies scripts never set them (they
//     scale each player with setmovespeedscale, which multiplies with g_speed).
//     bunny hop and the older-style mantle are iw7-mod dvars too (bg_bounces,
//     mantle_legacy). Global dvars outlive the match (KNOWN_LIMITATIONS.md L20),
//     so the mod writes them from its settings while the level loads and puts
//     the game's own values back when the match ends.
//   - fall damage: falls arrive in the damage callback as MOD_FALLING;
//     damage.gsc drops them while fall_damage is OFF.
//   - unlimited boost: energy slot 0 refilled to its maximum four times a second.
//   - unlimited sprint, omni-movement, air control: iw7-mod develop builds only
//     (bg_sprintUnlimited, bg_omnimovement, bg_airControl; KNOWN_LIMITATIONS.md
//     C4). Features with a "dvar:" requirement: N/A in the menu on v1.1.0.
//
// Settings:
//   move_speed        100  percent of the running speed (50-300)
//   gravity           100  percent of the gravity (10-125)
//   fall_damage       1    0: falls never hurt
//   slide             1    0: no sliding
//   wall_run          0    1: wall running
//   double_jump       0    1: double jump (boost)
//   mantle            0    1: climbing over ledges
//   legacy_mantle     0    1: mantle as in older Call of Duty games (iw7-mod)
//   bunny_hop         0    1: landing at speed keeps the speed (iw7-mod)
//   unlimited_boost   0    1: the boost never runs out
//   unlimited_sprint  0    feature, develop builds only
//   omni_movement     0    feature, develop builds only
//   air_control       0    feature, develop builds only

register()
{
    custom_scripts\ix\core\config::add_int( "move_speed", 100, 50, 300, "Move speed", "Percent of how fast players run. 100 is the game's own.", ::on_speed_changed );
    custom_scripts\ix\core\config::add_int( "gravity", 100, 10, 125, "Gravity", "Percent of the game's gravity: lower jumps higher and falls slower. 100 is the game's own.", ::on_gravity_changed );
    custom_scripts\ix\core\config::add_bool( "wall_run", 0, "Wall run", "ON: players can run along walls, as in multiplayer. OFF: the game's own (zombies has none).", undefined );
    custom_scripts\ix\core\config::add_bool( "double_jump", 0, "Double jump", "ON: a second, boosted jump in the air, as in multiplayer. OFF: the game's own.", undefined );
    custom_scripts\ix\core\config::add_bool( "unlimited_boost", 0, "Unlimited boost", "The boost for double jumps never runs out.", undefined );
    custom_scripts\ix\core\config::add_bool( "mantle", 0, "Mantle", "ON: players climb over ledges they jump at. OFF: the game's own (zombies has none).", undefined );
    custom_scripts\ix\core\config::add_bool( "legacy_mantle", 0, "Mantle: older style", "Mantle as in older Call of Duty games: ledges further away. Needs Mantle ON.", ::on_dvar_option_changed );
    custom_scripts\ix\core\config::add_bool( "slide", 1, "Slide", "OFF: players cannot slide.", undefined );
    custom_scripts\ix\core\config::add_bool( "bunny_hop", 0, "Bunny hop", "Landing at speed keeps your speed, so jumps can chain.", ::on_dvar_option_changed );
    custom_scripts\ix\core\config::add_bool( "fall_damage", 1, "Fall damage", "OFF: falls never hurt.", undefined );

    feature = custom_scripts\ix\core\features::add( "unlimited_sprint", "movement", "Unlimited sprint", "Sprint as long as you like. Needs a newer iw7-mod than v1.1.0.", 0 );
    needs_dvar( feature, "bg_sprintUnlimited", ::sprint_on, ::sprint_off );
    feature = custom_scripts\ix\core\features::add( "omni_movement", "movement", "Omni-movement", "Sprint and slide in any direction. Needs a newer iw7-mod than v1.1.0.", 0 );
    needs_dvar( feature, "bg_omnimovement", ::omni_on, ::omni_off );
    feature = custom_scripts\ix\core\features::add( "air_control", "movement", "Air control", "Steer much more in the air. Needs a newer iw7-mod than v1.1.0.", 0 );
    needs_dvar( feature, "bg_airControl", ::air_on, ::air_off );

    custom_scripts\ix\core\events::subscribe( "player_connect", ::on_connect );
    custom_scripts\ix\core\events::subscribe( "game_end", ::on_game_end );

    // While the level loads, before any player moves: the dvars as the
    // settings say, which also undoes a value an earlier match left behind.
    set_speed( custom_scripts\ix\core\config::get( "move_speed" ) );
    set_gravity( custom_scripts\ix\core\config::get( "gravity" ) );
    set_dvar_options();
    reset_develop_dvars();
}

// A develop-build option that is off: its dvar as the game has it (one that is
// on starts on "ix_ready", through the feature manager).
reset_develop_dvars()
{
    if ( !custom_scripts\ix\core\config::get( "unlimited_sprint" ) && custom_scripts\ix\core\compat::has_dvar( "bg_sprintUnlimited" ) )
        sprint_off();

    if ( !custom_scripts\ix\core\config::get( "omni_movement" ) && custom_scripts\ix\core\compat::has_dvar( "bg_omnimovement" ) )
        omni_off();

    if ( !custom_scripts\ix\core\config::get( "air_control" ) && custom_scripts\ix\core\compat::has_dvar( "bg_airControl" ) )
        air_off();
}

// A develop-build option: N/A (and refused) while the client lacks the dvar.
needs_dvar( feature, dvar, on_enable, on_disable )
{
    feature.requires[feature.requires.size] = "dvar:" + dvar;
    feature.on_enable = on_enable;
    feature.on_disable = on_disable;
}

// ---------------------------------------------------------------------------
// Global dvars

on_speed_changed( value, old_value, id )
{
    set_speed( value );
}

set_speed( percent )
{
    setdvar( "g_speed", int( 190 * percent / 100 ) );
}

on_gravity_changed( value, old_value, id )
{
    set_gravity( value );
}

set_gravity( percent )
{
    setdvar( "bg_gravity", 8 * percent );
}

on_dvar_option_changed( value, old_value, id )
{
    set_dvar_options();
}

set_dvar_options()
{
    setdvar( "bg_bounces", custom_scripts\ix\core\config::get( "bunny_hop" ) );
    setdvar( "mantle_legacy", custom_scripts\ix\core\config::get( "legacy_mantle" ) );
}

sprint_on()
{
    setdvar( "bg_sprintUnlimited", 1 );
}

sprint_off()
{
    setdvar( "bg_sprintUnlimited", 0 );
}

omni_on()
{
    setdvar( "bg_omnimovement", 1 );
}

omni_off()
{
    setdvar( "bg_omnimovement", 0 );
}

// bg_airControl: 1 is the game's own, 100 the most.
air_on()
{
    setdvar( "bg_airControl", 10 );
}

air_off()
{
    setdvar( "bg_airControl", 1 );
}

// The game's own values for whatever runs next in this game process.
on_game_end( arg )
{
    setdvar( "g_speed", 190 );
    setdvar( "bg_gravity", 800 );
    setdvar( "bg_bounces", 0 );
    setdvar( "mantle_legacy", 0 );

    if ( custom_scripts\ix\core\compat::has_dvar( "bg_sprintUnlimited" ) )
        setdvar( "bg_sprintUnlimited", 0 );

    if ( custom_scripts\ix\core\compat::has_dvar( "bg_omnimovement" ) )
        setdvar( "bg_omnimovement", 0 );

    if ( custom_scripts\ix\core\compat::has_dvar( "bg_airControl" ) )
        setdvar( "bg_airControl", 1 );
}

// ---------------------------------------------------------------------------
// Each player's abilities

on_connect( player, arg )
{
    if ( custom_scripts\ix\core\util::is_valid_player( player ) )
        player thread keep_movement();
}

// For the whole match: what the options say, four times a second.
keep_movement()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    state = spawnstruct();
    state.wall_run = 0;
    state.double_jump = 0;
    state.mantle = 0;
    state.slide_off = 0;

    for (;;)
    {
        wait 0.25;

        if ( !can_move_freely() )
            continue;

        // On: again and again, since the game switches them off at each
        // spawn. Back to the game's own: once.
        if ( custom_scripts\ix\core\config::get( "wall_run" ) )
        {
            self allowwallrun( 1 );
            state.wall_run = 1;
        }
        else if ( state.wall_run )
        {
            self allowwallrun( 0 );
            state.wall_run = 0;
        }

        if ( custom_scripts\ix\core\config::get( "double_jump" ) )
        {
            self allowdoublejump( 1 );
            state.double_jump = 1;
        }
        else if ( state.double_jump )
        {
            self allowdoublejump( 0 );
            state.double_jump = 0;
        }

        if ( custom_scripts\ix\core\config::get( "mantle" ) )
        {
            self allowmantle( 1 );
            state.mantle = 1;
        }
        else if ( state.mantle )
        {
            self allowmantle( 0 );
            state.mantle = 0;
        }

        // Off: again and again. Back on: once, unless the game itself holds
        // slide off through its counter (a map's own lock).
        if ( !custom_scripts\ix\core\config::get( "slide" ) )
        {
            self allowslide( 0 );
            state.slide_off = 1;
        }
        else if ( state.slide_off )
        {
            if ( !isdefined( self.disabledslide ) || self.disabledslide <= 0 )
                self allowslide( 1 );

            state.slide_off = 0;
        }

        if ( custom_scripts\ix\core\config::get( "unlimited_boost" ) )
            self energy_setenergy( 0, self energy_getmax( 0 ) );
    }
}

// Playing on their own feet: not down, not in the afterlife arcade, not taken
// by a ride or a booth, where the game sets movement for its own purposes.
can_move_freely()
{
    if ( !isalive( self ) || !isdefined( self.sessionstate ) || self.sessionstate != "playing" )
        return 0;

    if ( isdefined( self.inlaststand ) && self.inlaststand )
        return 0;

    if ( isdefined( self.in_afterlife_arcade ) && self.in_afterlife_arcade )
        return 0;

    return !self islinked();
}
