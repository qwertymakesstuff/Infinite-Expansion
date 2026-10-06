// Infinite Expansion - zombies module.
//
// Zombies features (Phase 7). CP only: referenced from
// custom_scripts/cp/ix_main.gsc and nowhere else.
// Phase 1 placeholder: registers itself so the init log shows the load order.

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "zombies" );
}
