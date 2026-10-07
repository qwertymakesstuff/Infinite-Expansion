// Infinite Expansion - ui module.
//
// The in-game menu (Phase 3: menu.gsc draws it, menu_tree.gsc lists its
// pages), the player card (Phase 1.5, player_card.gsc), and later the info HUD
// (Phase 8).

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "ui" );
    custom_scripts\ix\ui\player_card::register();
    custom_scripts\ix\ui\menu::register();
}
