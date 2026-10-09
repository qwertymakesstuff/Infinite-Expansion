// Infinite Expansion - ui module.
//
// The in-game menu (Phase 3: menu.gsc draws it, menu_tree.gsc lists its
// pages) and the info HUD (Phase 8: hud.gsc).

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "ui" );
    custom_scripts\ix\ui\menu::register();
    custom_scripts\ix\ui\hud::register();
}
