// Infinite Expansion - mp module.
//
// Multiplayer-only helpers. MP only: referenced from
// custom_scripts/mp/ix_main.gsc and nowhere else.
// Phase 1 placeholder: registers itself so the init log shows the load order.

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "mp" );
}
