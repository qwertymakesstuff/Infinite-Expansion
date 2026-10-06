// Infinite Expansion - multiplayer (MP) entry point.
//
// iw7-mod auto-loads every .gsc directly inside custom_scripts/mp/ and runs its
// init() when the level loads, before the map's own main(). The rest of the mod
// lives in custom_scripts/ix/, which is never auto-loaded: those files are
// compiled and loaded only because this file references them.

init()
{
    custom_scripts\ix\core\bootstrap::start( "mp", modules() );
}

// Module register() functions in the order bootstrap calls them. MP-only
// modules are referenced from this file only (ARCHITECTURE.md section 7). ui
// comes last so it can see everything the other modules registered.
modules()
{
    list = [];
    list[list.size] = custom_scripts\ix\player\player::register;
    list[list.size] = custom_scripts\ix\weapons\weapons::register;
    list[list.size] = custom_scripts\ix\mp\mp::register;
    list[list.size] = custom_scripts\ix\debug\debug::register;
    list[list.size] = custom_scripts\ix\ui\ui::register;
    return list;
}
