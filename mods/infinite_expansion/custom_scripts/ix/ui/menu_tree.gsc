// Infinite Expansion - the in-game menu's pages (data only; menu.gsc draws them).
//
// Runs once, on the first opening, when every module has registered its
// settings. A setting row shows the setting's own label, help and range
// (config.gsc); a row for a setting that does not exist is skipped, and a page
// without rows is left out.
//
//   add_page( id, title, parent )                    a page, linked from its parent
//   add_setting( page, setting, step )               step: A / D change numbers by it
//   add_action( page, label, help, fn, confirm, host_only [, arg] )   arg: fn gets it
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

    emote_pages();

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

    // Give a weapon: one page per class of this map's weapons (give.gsc).
    add_page( "give", "Give a weapon", "weapons" );
    groups = custom_scripts\ix\weapons\give::groups();

    if ( groups.size == 0 )
        add_info( "give", "No weapons found", "This map's weapon table listed none. Send the console's [IX] give line.", custom_scripts\ix\weapons\give::table_name );

    foreach ( group in groups )
    {
        add_page( "give_" + group.id, group.title, "give" );

        foreach ( entry in group.entries )
            add_action( "give_" + group.id, entry.label, custom_scripts\ix\weapons\give::entry_help(), custom_scripts\ix\weapons\give::give_entry, 0, 1, entry );
    }

    add_reset( "weapons" );

    add_page( "zombies", "Zombies", "main" );
    add_setting( "zombies", "zombie_speed", 1 );
    add_setting( "zombies", "zombie_health", 50 );
    add_setting( "zombies", "max_zombies", 4 );
    add_setting( "zombies", "points_multiplier", 50 );
    add_setting( "zombies", "powerup_limit", 1 );
    add_setting( "zombies", "start_round", 1 );
    add_setting( "zombies", "start_perks", 1 );

    add_page( "zombies_now", "In effect now", "zombies" );
    add_info( "zombies_now", "Set up", "yes once the game's spawner is ready; the options apply from then.", custom_scripts\ix\zombies\zombies::set_up_info );
    add_info( "zombies_now", "Speed hook", "on: Zombie speed reaches the zombies.", custom_scripts\ix\zombies\zombies::speed_hook_info );
    add_info( "zombies_now", "Zombie health", "Percent of the game's health that regular zombies get.", custom_scripts\ix\zombies\zombies::health_info );
    add_info( "zombies_now", "A zombie's health", "The full health of one zombie out now (0: none out).", custom_scripts\ix\zombies\zombies::health_now_info );
    add_info( "zombies_now", "Game's own for it", "What the game gave that zombie. With Zombie health 200, twice as much above.", custom_scripts\ix\zombies\zombies::health_stock_info );
    add_info( "zombies_now", "Most alive now", "The game's limit this round (0 between rounds).", custom_scripts\ix\zombies\zombies::max_alive_info );
    add_info( "zombies_now", "Points", "Percent the game pays for kills and hits now (Double Money included).", custom_scripts\ix\zombies\zombies::points_info );
    add_info( "zombies_now", "Power-ups a round", "Most power-ups kills can drop this round.", custom_scripts\ix\zombies\zombies::powerups_info );
    add_info( "zombies_now", "Round", "The round being played.", custom_scripts\ix\zombies\zombies::round_number );
    add_reset( "zombies" );

    add_page( "guided", "Guided Mode", "main" );
    add_setting( "guided", "guided_mode", 1 );
    add_info( "guided", "Guide for this map", "Ready, or None yet: no verified guide for this map yet.", custom_scripts\ix\guided\guided::guide_info );
    add_info( "guided", "Steps done", "Steps of the quest done: those the game reports and those marked by hand.", custom_scripts\ix\guided\guided::progress_info );
    add_info( "guided", "Steps in all", "The steps of this map's main quest in the guide.", custom_scripts\ix\guided\guided::steps_info );
    add_action( "guided", "Previous step", "The step before, on the tracker. Next step comes back to the current one.", custom_scripts\ix\guided\guided::previous_action, 0, 0 );
    add_action( "guided", "Next step", "The next step, on the tracker. Past the current one only with Guided: hints full.", custom_scripts\ix\guided\guided::next_action, 0, 0 );
    add_action( "guided", "Reveal more", "More of this step's hint on the tracker, up to the full solution.", custom_scripts\ix\guided\guided::more_action, 0, 0 );
    add_action( "guided", "Mark step complete", "For a step the game cannot report: done by hand. Use twice.", custom_scripts\ix\guided\guided::mark_action, 1, 0 );
    add_action( "guided", "Clear marks", "Steps marked done by hand are open again. Use twice.", custom_scripts\ix\guided\guided::clear_marks_action, 1, 0 );
    add_page( "guided_steps", "Full guide", "guided" );

    // One row a step, when this map has a guide (else the page is left out).
    if ( custom_scripts\ix\guided\guided::has_guide() )
    {
        steps = custom_scripts\ix\guided\guided::guide().steps;

        for ( i = 0; i < steps.size; i++ )
        {
            row = custom_scripts\ix\ui\menu::add_info( "guided_steps", "Step " + ( i + 1 ), "", custom_scripts\ix\guided\guided::step_state_info );
            row.arg = i;
            row.help_fn = custom_scripts\ix\guided\guided::step_help;
        }
    }

    add_page( "guided_options", "Guide options", "guided" );
    add_setting( "guided_options", "guided_hints", 1 );
    add_setting( "guided_options", "guided_panel", 1 );
    add_setting( "guided_options", "guided_marker", 1 );
    add_setting( "guided_options", "guided_outline", 1 );
    add_setting( "guided_options", "guided_side", 1 );
    add_setting( "guided_options", "guided_height", 10 );
    add_setting( "guided_options", "guided_text", 1 );
    add_setting( "guided_options", "guided_opacity", 10 );
    add_setting( "guided_options", "guided_coop", 1 );
    add_reset( "guided_options" );

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

    add_page( "presets", "Presets", "main" );
    add_info( "presets", "In use", "The preset your settings match now; Your own when none does.", custom_scripts\ix\core\presets::matching );

    foreach ( id in level.ix.presets.order )
    {
        preset = level.ix.presets.list[id];
        add_action( "presets", preset.title, preset.help, custom_scripts\ix\core\presets::apply_action, 1, 1, id );
    }

    add_action( "presets", "Save as Custom", "Your settings now become Custom, kept across games. Menu, HUD layout and characters are not in it.", custom_scripts\ix\core\presets::save_custom_action, 1, 1 );

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

// Emotes (Phase 14, ix/fun/emotes.gsc): the wheel, every emote by category
// with its own page (Play, Favorite, Preview), the favorites, a random one,
// the settings, and the last one played again from behind.
emote_pages()
{
    add_page( "emotes", "Emotes", "main" );
    emotes = custom_scripts\ix\fun\emotes::list();

    if ( emotes.size == 0 )
        add_info( "emotes", "Emotes here", "This map has no emotes the mod can play.", custom_scripts\ix\fun\emotes::count_info );
    else
    {
        // The ring, clockwise from the top: the seven favorites' slots
        // around, Back at the bottom (menu.gsc draws page.wheel as a ring).
        wheel = custom_scripts\ix\ui\menu::add_page( "emote_wheel", "Emote wheel", "emotes" );
        wheel.wheel = 1;

        for ( position = 0; position < 8; position++ )
        {
            if ( position == 4 )
            {
                add_action( "emote_wheel", "Back", "Back to the Emotes page. Melee does too.", custom_scripts\ix\ui\menu::go_back, 0, 0 );
                continue;
            }

            slot = position;

            if ( position > 4 )
                slot = position - 1;

            row = add_action( "emote_wheel", "", "", custom_scripts\ix\fun\emotes::play_slot, 0, 0, slot );
            row.label_fn = custom_scripts\ix\fun\emotes::wheel_label;
            row.help_fn = custom_scripts\ix\fun\emotes::slot_help;
        }

        add_page( "emote_browse", "Browse emotes", "emotes" );

        foreach ( category in custom_scripts\ix\fun\emote_data::categories() )
        {
            found = custom_scripts\ix\fun\emotes::in_category( category );

            if ( found.size == 0 )
                continue;

            add_page( "emote_cat_" + category, category, "emote_browse" );

            foreach ( emote in found )
            {
                page = "emote_" + emote.id;
                add_page( page, emote.name, "emote_cat_" + category );
                add_action( page, "Play", emote.help, custom_scripts\ix\fun\emotes::menu_play, 0, 0, emote );
                row = add_action( page, "Favorite", "On the wheel and the Favorites page (seven slots). Use again to take it off.", custom_scripts\ix\fun\emotes::toggle_favorite, 0, 0, emote );
                row.label_fn = custom_scripts\ix\fun\emotes::favorite_label;
                add_action( page, "Preview", "Plays it with the camera behind you, so you see your character do it.", custom_scripts\ix\fun\emotes::menu_preview, 0, 0, emote );
            }
        }

        add_page( "emote_favorites", "Favorites", "emotes" );

        for ( slot = 0; slot < custom_scripts\ix\fun\emotes::slot_count(); slot++ )
        {
            row = add_action( "emote_favorites", "", "", custom_scripts\ix\fun\emotes::play_slot, 0, 0, slot );
            row.label_fn = custom_scripts\ix\fun\emotes::slot_label;
            row.help_fn = custom_scripts\ix\fun\emotes::slot_help;
        }

        add_action( "emote_favorites", "Clear favorites", "Empties every slot. Use twice.", custom_scripts\ix\fun\emotes::clear_favorites, 1, 0 );
        add_action( "emotes", "Random emote", "Plays one of this map's emotes, picked at random.", custom_scripts\ix\fun\emotes::random_action, 0, 0 );
    }

    add_page( "emote_settings", "Emote settings", "emotes" );
    add_setting( "emote_settings", "emotes", 1 );
    add_setting( "emote_settings", "emote_camera", 1 );
    add_setting( "emote_settings", "emote_cancel_damage", 1 );
    add_setting( "emote_settings", "emote_custom", 1 );
    add_reset( "emote_settings" );

    if ( emotes.size > 0 )
    {
        row = add_action( "emotes", "Preview emote", "The last emote you played, again, with the camera behind you.", custom_scripts\ix\fun\emotes::preview_action, 0, 0 );
        row.label_fn = custom_scripts\ix\fun\emotes::preview_label;
    }
}

add_page( id, title, parent )
{
    custom_scripts\ix\ui\menu::add_page( id, title, parent );
}

add_setting( page, setting, step )
{
    custom_scripts\ix\ui\menu::add_setting( page, setting, step );
}

add_action( page, label, help, fn, confirm, host_only, arg )
{
    return custom_scripts\ix\ui\menu::add_action( page, label, help, fn, confirm, host_only, arg );
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
