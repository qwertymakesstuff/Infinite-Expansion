// Infinite Expansion - quality of life module (Phase 9).
//
// Chat shortcuts for the menu's actions, for players who would rather type
// (chat.gsc runs them on the player who typed):
//   !ix refill   Refill ammo: max ammo and grenades for every player standing
//   !ix save     Save position
//   !ix load     Go to saved position
//   !ix tp       Teleport to crosshair
// They follow the menu's rule for its actions: the host, or everyone when
// menu_access is everyone (menu.gsc may_change), and refuse what the menu
// refuses (position.gsc: not while down, dead or moved by the game).
//
// In the menu: "Reset this page" on every page of settings (menu.gsc
// reset_page_action), and the Game page (game.gsc: game speed, zombie
// outlines, restart).

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "qol" );
    custom_scripts\ix\qol\game::register();
    custom_scripts\ix\core\chat::add_command( "refill", ::refill_command, "max ammo and grenades for everyone" );
    custom_scripts\ix\core\chat::add_command( "save", ::save_command, "saves your position" );
    custom_scripts\ix\core\chat::add_command( "load", ::load_command, "back to your saved position" );
    custom_scripts\ix\core\chat::add_command( "tp", ::teleport_command, "teleports you to where you look" );
}

// The host, or everyone when menu_access is everyone.
may_act()
{
    if ( self custom_scripts\ix\ui\menu::may_change() )
        return 1;

    self tell( "Only the host can do that." );
    return 0;
}

refill_command( words )
{
    if ( may_act() )
        self custom_scripts\ix\weapons\ammo::refill_everyone();
}

save_command( words )
{
    if ( may_act() )
        self custom_scripts\ix\player\position::save_position();
}

load_command( words )
{
    if ( may_act() )
        self custom_scripts\ix\player\position::load_position();
}

teleport_command( words )
{
    if ( may_act() )
        self custom_scripts\ix\player\position::teleport_to_crosshair();
}
