// Infinite Expansion - the in-game menu's pages (data only; menu.gsc draws them).
//
// Runs once, on the first opening, when every module has registered its
// settings. A setting row shows the setting's own label, help and range
// (config.gsc); a row for a setting that does not exist is skipped, and a page
// without rows is left out. Later phases add their pages here (Player,
// Movement, Weapons, Zombies, HUD, ...).
//
//   add_page( id, title, parent )                    a page, linked from its parent
//   add_setting( page, setting, step )               step: A / D change numbers by it
//   add_action( page, label, help, fn, confirm, host_only )
//   add_info( page, label, help, fn )                fn returns a number or a short word

build()
{
    add_page( "main", "Infinite Expansion", undefined );

    add_page( "characters", "Characters", "main" );
    add_setting( "characters", "character_select", 1 );
    add_setting( "characters", "character_specials", 1 );
    add_setting( "characters", "character_crossmap", 1 );
    add_setting( "characters", "character_announce", 1 );

    add_page( "player", "Player", "main" );
    add_setting( "player", "god_mode", 1 );
    add_setting( "player", "damage_taken", 10 );
    add_setting( "player", "third_person", 1 );
    add_setting( "player", "zombies_ignore", 1 );
    add_setting( "player", "rocket_jump", 1 );
    add_setting( "player", "rocket_jump_power", 25 );
    add_setting( "player", "friendly_fire", 1 );
    add_setting( "player", "starting_points", 500 );
    add_setting( "player", "player_ejection", 1 );

    add_page( "position", "Position", "player" );
    add_action( "position", "Save position", "Remembers where you stand, until the match ends.", custom_scripts\ix\player\position::save_position, 0, 1 );
    add_action( "position", "Go to saved position", "Back to the spot you saved. The menu closes.", custom_scripts\ix\player\position::load_position, 0, 1 );
    add_action( "position", "Teleport to crosshair", "To the spot you are looking at. The menu closes. It can put you where the game does not expect you.", custom_scripts\ix\player\position::teleport_to_crosshair, 0, 1 );

    add_page( "movement", "Movement", "main" );
    add_setting( "movement", "move_speed", 10 );
    add_setting( "movement", "gravity", 5 );
    add_setting( "movement", "wall_run", 1 );
    add_setting( "movement", "double_jump", 1 );
    add_setting( "movement", "unlimited_boost", 1 );
    add_setting( "movement", "mantle", 1 );
    add_setting( "movement", "legacy_mantle", 1 );
    add_setting( "movement", "slide", 1 );
    add_setting( "movement", "bunny_hop", 1 );
    add_setting( "movement", "fall_damage", 1 );
    add_setting( "movement", "unlimited_sprint", 1 );
    add_setting( "movement", "omni_movement", 1 );
    add_setting( "movement", "air_control", 1 );

    add_page( "weapons", "Weapons", "main" );
    add_setting( "weapons", "unlimited_ammo", 1 );
    add_setting( "weapons", "unlimited_grenades", 1 );
    add_setting( "weapons", "fire_rate", 10 );
    add_setting( "weapons", "no_recoil", 1 );
    add_setting( "weapons", "start_max_ammo", 1 );
    add_action( "weapons", "Refill ammo", "Every player gets max ammo and grenades now, as with a Max Ammo.", custom_scripts\ix\weapons\ammo::refill_everyone, 0, 1 );

    add_page( "menu", "Menu", "main" );
    add_setting( "menu", "menu_open", 1 );
    add_setting( "menu", "menu_access", 1 );
    add_setting( "menu", "menu_hint", 1 );
    add_setting( "menu", "menu", 1 );

    add_page( "settings", "Settings", "main" );
    add_info( "settings", "Changed from the default", "How many settings differ from their default.", custom_scripts\ix\ui\menu::changed_count_info );
    add_action( "settings", "Reset every setting", "Every setting back to its default. Saved settings are reset too.", custom_scripts\ix\ui\menu::reset_all_action, 1, 1 );
    add_info( "settings", "Version", "The loaded version of Infinite Expansion.", custom_scripts\ix\ui\menu::version_info );

    add_page( "debug", "Debug", "main" );
    add_setting( "debug", "debug_log", 1 );

    add_action( "main", "Close", "Closes the menu. Melee does too.", custom_scripts\ix\ui\menu::close_action, 0, 0 );
}

add_page( id, title, parent )
{
    custom_scripts\ix\ui\menu::add_page( id, title, parent );
}

add_setting( page, setting, step )
{
    custom_scripts\ix\ui\menu::add_setting( page, setting, step );
}

add_action( page, label, help, fn, confirm, host_only )
{
    custom_scripts\ix\ui\menu::add_action( page, label, help, fn, confirm, host_only );
}

add_info( page, label, help, fn )
{
    custom_scripts\ix\ui\menu::add_info( page, label, help, fn );
}
