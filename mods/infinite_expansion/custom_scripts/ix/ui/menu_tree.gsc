// Infinite Expansion - the in-game menu's pages (data only; menu.gsc draws them).
//
// Runs once, on the first opening, when every module has registered its
// settings. A setting row shows the setting's own label, help and range
// (config.gsc); a row for a setting that does not exist is skipped, and a page
// without rows is left out.
//
//   add_page( id, title, parent )                    a page, linked from its parent
//   add_setting( page, setting, step )               step: A / D change numbers by it
//   add_action( page, label, help, fn, confirm, host_only )
//   add_info( page, label, help, fn )                fn returns a number or a short word
//   add_reset( page )                                "Reset this page", for a page of settings
//   add_dev_action( page, label, help, fn )          an action locked until dev_tools is ON

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
    add_reset( "player" );

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
    add_reset( "movement" );

    add_page( "weapons", "Weapons", "main" );
    add_setting( "weapons", "unlimited_ammo", 1 );
    add_setting( "weapons", "unlimited_grenades", 1 );
    add_setting( "weapons", "fire_rate", 10 );
    add_setting( "weapons", "no_recoil", 1 );
    add_setting( "weapons", "start_max_ammo", 1 );
    add_action( "weapons", "Refill ammo", "Every player gets max ammo and grenades now, as with a Max Ammo.", custom_scripts\ix\weapons\ammo::refill_everyone, 0, 1 );
    add_reset( "weapons" );

    add_page( "zombies", "Zombies", "main" );
    add_setting( "zombies", "zombie_speed", 1 );
    add_setting( "zombies", "zombie_health", 10 );
    add_setting( "zombies", "max_zombies", 4 );
    add_setting( "zombies", "points_multiplier", 50 );
    add_setting( "zombies", "powerup_limit", 1 );
    add_setting( "zombies", "start_round", 1 );
    add_setting( "zombies", "start_perks", 1 );
    add_reset( "zombies" );

    add_page( "hud", "HUD", "main" );
    add_setting( "hud", "hud_round", 1 );
    add_setting( "hud", "hud_zombies", 1 );
    add_setting( "hud", "hud_health", 1 );
    add_setting( "hud", "hud_speed", 1 );
    add_setting( "hud", "hud_side", 1 );
    add_setting( "hud", "hud_height", 10 );
    add_reset( "hud" );

    add_page( "game", "Game", "main" );
    add_setting( "game", "game_speed", 25 );
    add_setting( "game", "zombie_outlines", 1 );
    add_action( "game", "Restart the match", "Starts this map over from the first round, for everyone.", custom_scripts\ix\qol\game::restart_match, 1, 1 );
    add_reset( "game" );

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
    add_setting( "debug", "dev_tools", 1 );

    add_page( "debug_info", "Information", "debug" );
    add_info( "debug_info", "Map", "The map's name in the game files.", custom_scripts\ix\debug\debug::map_name );
    add_info( "debug_info", "Players", "Players in the match.", custom_scripts\ix\debug\debug::player_count );
    add_info( "debug_info", "Round", "The round being played.", custom_scripts\ix\zombies\zombies::round_number );
    add_info( "debug_info", "Zombies alive", "Enemies alive now, brutes and bosses too.", custom_scripts\ix\zombies\zombies::zombies_alive );
    add_info( "debug_info", "Zombies left", "Zombies still to kill this round, alive or yet to come.", custom_scripts\ix\zombies\zombies::zombies_left );
    add_info( "debug_info", "Position X", "Where you stand, in the map's units.", custom_scripts\ix\debug\debug::position_x );
    add_info( "debug_info", "Position Y", "Where you stand, in the map's units.", custom_scripts\ix\debug\debug::position_y );
    add_info( "debug_info", "Position Z", "Height, in the map's units.", custom_scripts\ix\debug\debug::position_z );

    add_info( "debug", "Zombie spawning", "on, paused (by this menu) or game paused (the map holds them).", custom_scripts\ix\debug\tools::spawning_state );
    add_dev_action( "debug", "Pause / resume spawning", "No new zombies until you resume; the ones out stay.", custom_scripts\ix\debug\tools::toggle_spawning );
    add_dev_action( "debug", "Kill all zombies", "As a Nuke, without points: bosses and brutes are spared.", custom_scripts\ix\debug\tools::kill_all );
    add_dev_action( "debug", "End this round", "Kills the round's zombies; the next round starts as usual.", custom_scripts\ix\debug\tools::end_round );
    add_dev_action( "debug", "Give yourself 10,000 points", "Adds 10,000 points to yours.", custom_scripts\ix\debug\tools::give_points );

    add_page( "debug_powerups", "Drop a power-up", "debug" );
    add_dev_action( "debug_powerups", "Max Ammo", "Drops a Max Ammo in front of you.", custom_scripts\ix\debug\tools::drop_max_ammo );
    add_dev_action( "debug_powerups", "Nuke", "Drops a Nuke in front of you.", custom_scripts\ix\debug\tools::drop_nuke );
    add_dev_action( "debug_powerups", "Insta-Kill", "Drops an Insta-Kill in front of you.", custom_scripts\ix\debug\tools::drop_instakill );
    add_dev_action( "debug_powerups", "Double Money", "Drops a Double Money in front of you.", custom_scripts\ix\debug\tools::drop_double_money );
    add_dev_action( "debug_powerups", "Fire Sale", "Drops a Fire Sale in front of you.", custom_scripts\ix\debug\tools::drop_fire_sale );
    add_dev_action( "debug_powerups", "Carpenter", "Drops a Carpenter (boards every window) in front of you.", custom_scripts\ix\debug\tools::drop_carpenter );
    add_dev_action( "debug_powerups", "Infinite Ammo", "Drops an Infinite Ammo in front of you.", custom_scripts\ix\debug\tools::drop_infinite_ammo );

    add_action( "debug", "What am I looking at?", "Names the thing in your crosshair: its kind, model and distance.", custom_scripts\ix\debug\tools::look_info, 0, 0 );

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
    return custom_scripts\ix\ui\menu::add_action( page, label, help, fn, confirm, host_only );
}

// A developer tool: host only, Use twice, and locked while dev_tools is OFF.
add_dev_action( page, label, help, fn )
{
    item = add_action( page, label, help, fn, 1, 1 );
    item.needs = "dev_tools";
}

add_info( page, label, help, fn )
{
    custom_scripts\ix\ui\menu::add_info( page, label, help, fn );
}

// The last row of a settings page: its settings back to their defaults
// (Use twice, host only).
add_reset( page )
{
    add_action( page, "Reset this page", "Every setting on this page back to its default. Other pages keep theirs.", custom_scripts\ix\ui\menu::reset_page_action, 1, 1 );
}
