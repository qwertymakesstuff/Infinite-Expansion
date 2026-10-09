// Infinite Expansion - weapons module.
//
// Weapon features (Phase 6):
//   ammo.gsc       unlimited ammo, unlimited grenades, max ammo at spawn,
//                  refill for everyone (menu action)
//   handling.gsc   fire rate, no recoil

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "weapons" );
    custom_scripts\ix\weapons\ammo::register();
    custom_scripts\ix\weapons\handling::register();
}
