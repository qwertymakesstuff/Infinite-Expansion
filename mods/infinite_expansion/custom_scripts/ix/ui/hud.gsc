// Infinite Expansion - info HUD (Phase 8): a few numbers at the side of the
// screen, each its own setting, all off by default.
//
//   Round                  level.wave_num
//   Zombies left / alive   level.desired_enemy_deaths_this_wave minus
//                          level.current_enemy_deaths (the stock wave loop),
//                          and the enemy agents alive (ix/zombies/zombies.gsc
//                          counts both)
//   Health                 self.health
//   Speed                  length2d( getvelocity() ), units a second
//
// Each row is a label (text set once) and a number (setvalue, so numbers
// never become new strings: KNOWN_LIMITATIONS.md L12). A player sees only so
// many HUD elements, and the menu holds most of the non-archived ones
// (L49), so the HUD's elements are archived ones: two per row, at most ten.
// The rows are made when an option changes and destroyed when it goes off,
// so a HUD that is all off has no elements at all; the game frees a player's
// elements when they leave, as it does the menu's. The HUD hides while the
// menu is open, while the player is not playing (dead, spectating after a
// bleed-out), and over the game's own menus.
//
// Settings:
//   hud_zombies  0  zombies left this round, and alive now
//   hud_health   0  your health
//   hud_speed    0  your speed
//   hud_round    0  the round number
//   hud_side     left  left / right
//   hud_height   0     -150 to 150: up (more) or down (less) from the middle

register()
{
    custom_scripts\ix\core\config::add_bool( "hud_zombies", 0, "HUD: zombies", "Zombies left this round and alive now, on screen while the menu is closed.", ::on_hud_changed );
    custom_scripts\ix\core\config::add_bool( "hud_health", 0, "HUD: health", "Your health as a number, on screen while the menu is closed.", ::on_hud_changed );
    custom_scripts\ix\core\config::add_bool( "hud_speed", 0, "HUD: speed", "How fast you move, in units a second, on screen while the menu is closed.", ::on_hud_changed );
    custom_scripts\ix\core\config::add_bool( "hud_round", 0, "HUD: round", "The round number, on screen while the menu is closed.", ::on_hud_changed );
    custom_scripts\ix\core\config::add_enum( "hud_side", "left", "left right", "HUD: side", "Which side of the screen the HUD's numbers are on.", ::on_hud_changed );
    custom_scripts\ix\core\config::add_int( "hud_height", 0, -150, 150, "HUD: height", "Moves the HUD's numbers up (more) or down (less) from the middle of the screen.", ::on_hud_changed );

    custom_scripts\ix\core\events::subscribe( "player_connect", ::on_connect );
}

on_connect( player, arg )
{
    if ( !custom_scripts\ix\core\util::is_valid_player( player ) || !isdefined( player.ix ) )
        return;

    player.ix.hud = spawnstruct();
    player.ix.hud.rows = [];
    player build_rows();
    player thread update_loop();
}

// An option changed: every player's rows are made again.
on_hud_changed( value, old_value, id )
{
    if ( !isdefined( level.players ) )
        return;

    foreach ( player in level.players )
    {
        if ( custom_scripts\ix\core\util::is_valid_player( player ) && isdefined( player.ix ) && isdefined( player.ix.hud ) )
            player build_rows();
    }
}

// The rows that are on, in a fixed order.
wanted_rows()
{
    rows = [];

    if ( custom_scripts\ix\core\config::get( "hud_round" ) )
        rows[rows.size] = "round";

    if ( custom_scripts\ix\core\config::get( "hud_zombies" ) )
    {
        rows[rows.size] = "zombies_left";
        rows[rows.size] = "zombies_alive";
    }

    if ( custom_scripts\ix\core\config::get( "hud_health" ) )
        rows[rows.size] = "health";

    if ( custom_scripts\ix\core\config::get( "hud_speed" ) )
        rows[rows.size] = "speed";

    return rows;
}

row_label( id )
{
    switch ( id )
    {
        case "round":
            return "Round";
        case "zombies_left":
            return "Zombies left";
        case "zombies_alive":
            return "Zombies alive";
        case "health":
            return "Health";
        case "speed":
            return "Speed";
    }

    return id;
}

row_value( id )
{
    switch ( id )
    {
        case "round":
            return custom_scripts\ix\zombies\zombies::round_number();
        case "zombies_left":
            return custom_scripts\ix\zombies\zombies::zombies_left();
        case "zombies_alive":
            return custom_scripts\ix\zombies\zombies::zombies_alive();
        case "health":
            return int( max( 0, self.health ) );
        case "speed":
            return int( length2d( self getvelocity() ) );
    }

    return 0;
}

build_rows()
{
    destroy_rows();
    hud = self.ix.hud;
    right = custom_scripts\ix\core\config::get( "hud_side" ) == "right";

    foreach ( id in wanted_rows() )
    {
        row = spawnstruct();
        row.id = id;
        top = hud.rows.size * 12 - custom_scripts\ix\core\config::get( "hud_height" );
        row.label = hud_text( right, top, ( 0.75, 0.75, 0.75 ), 0 );
        row.label settext( row_label( id ) );
        row.value = hud_text( right, top, ( 1, 1, 1 ), 1 );
        row.shown = undefined;
        hud.rows[hud.rows.size] = row;
    }
}

destroy_rows()
{
    hud = self.ix.hud;

    foreach ( row in hud.rows )
    {
        if ( isdefined( row.label ) )
            row.label destroy();

        if ( isdefined( row.value ) )
            row.value destroy();
    }

    hud.rows = [];
}

// A label (is_value 0) or a number (1) of a row. Left: from the screen's left
// edge; right: just inside the 4:3 screen's right edge (horzalign "center",
// as the menu is placed). Archived elements (L49).
hud_text( right, top, color, is_value )
{
    element = newclienthudelem( self );
    element.vertalign = "middle";
    element.aligny = "top";
    element.y = top - 40;

    if ( right )
    {
        element.horzalign = "center";

        if ( is_value )
        {
            element.alignx = "right";
            element.x = 316;
        }
        else
        {
            element.alignx = "right";
            element.x = 270;
        }
    }
    else
    {
        element.horzalign = "left";
        element.alignx = "left";

        if ( is_value )
            element.x = 78;
        else
            element.x = 6;
    }

    element.font = "default";
    element.fontscale = 0.9;
    element.color = color;
    element.sort = 10;
    element.foreground = 1;
    element.hidewheninmenu = 1;
    element.hidewhendead = 1;
    element.archived = 1;
    element.alpha = 0;
    return element;
}

// Five times a second: the numbers; hidden while the menu is open or the
// player is not playing.
update_loop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        wait 0.2;
        hud = self.ix.hud;

        if ( hud.rows.size == 0 )
            continue;

        hidden = ( isdefined( self.ix.menu ) && self.ix.menu.open ) || !isdefined( self.sessionstate ) || self.sessionstate != "playing";

        foreach ( row in hud.rows )
        {
            if ( hidden )
            {
                row.label.alpha = 0;
                row.value.alpha = 0;
                continue;
            }

            value = row_value( row.id );

            if ( !isdefined( row.shown ) || row.shown != value )
            {
                row.value setvalue( value );
                row.shown = value;
            }

            row.label.alpha = 0.9;
            row.value.alpha = 1;
        }
    }
}
