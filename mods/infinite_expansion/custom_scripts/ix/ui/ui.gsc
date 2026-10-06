// Infinite Expansion - ui module.
//
// Menu engine and menu tree (Phase 3) and the info HUD (Phase 8). The player
// card (Phase 1.5) lives in player_card.gsc.

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "ui" );
    custom_scripts\ix\ui\player_card::register();
}
