// Infinite Expansion - entry point. The mod targets zombies only.
//
// iw7-mod auto-loads every .gsc directly inside custom_scripts/cp/ (zombies
// only) and runs its init() when the level loads, before the map's own main().
// The rest of the mod lives in custom_scripts/ix/, which is never auto-loaded:
// those files are compiled and loaded only because this file references them.

init()
{
    custom_scripts\ix\core\bootstrap::start( modules() );
}

// Module register() functions in the order bootstrap calls them. ui comes
// last so it can see everything the other modules registered.
modules()
{
    list = [];
    list[list.size] = custom_scripts\ix\player\player::register;
    list[list.size] = custom_scripts\ix\weapons\weapons::register;
    list[list.size] = custom_scripts\ix\zombies\zombies::register;
    list[list.size] = custom_scripts\ix\qol\qol::register;
    list[list.size] = custom_scripts\ix\debug\debug::register;
    list[list.size] = custom_scripts\ix\ui\ui::register;
    return list;
}
