// Infinite Expansion - player module.
//
// Player and movement features (Phases 4 and 5). Character selection
// (Phase 1.5) lives in character.gsc.

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "player" );
    custom_scripts\ix\player\character::register();
}
