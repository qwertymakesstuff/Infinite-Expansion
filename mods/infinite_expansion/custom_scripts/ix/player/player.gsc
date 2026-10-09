// Infinite Expansion - player module.
//
// Player and movement features (Phases 4 and 5):
//   character.gsc   character selection (Phase 1.5)
//   damage.gsc      god mode, damage taken, friendly fire, rocket jump
//   options.gsc     third person, zombies ignore players, players push apart,
//                   starting points
//   position.gsc    save / load position, teleport to crosshair (menu actions)

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "player" );
    custom_scripts\ix\player\character::register();
    custom_scripts\ix\player\damage::register();
    custom_scripts\ix\player\options::register();
}
