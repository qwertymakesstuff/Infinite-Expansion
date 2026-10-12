// Infinite Expansion - configuration presets (Phase 11).
//
// A preset sets many settings at once: the menu's Presets page, or
// "!ix preset <name>" in chat; host only, like every setting. Each built-in
// preset is data: the settings it changes from their defaults, as
// "id=value" words (add_builtins). Applying one puts every setting a preset
// governs to the preset's value or, when the preset does not name it, to its
// default, so a preset gives the same result whatever was set before. Some
// settings are personal or about the menu itself, and no preset touches them
// (kept_settings): who opens the menu and how, where the HUD sits, and the
// characters.
//
// Custom is the host's own preset. "Save as Custom" stores the value of every
// governed setting as an archived dvar ix_custom_<id> (persist.gsc), so it
// lasts across games; applying Custom sets them back. A setting that a later
// version adds, which a saved Custom lacks, gets its default.
//
// Every value goes through config::set, which checks it as it checks a value
// typed in chat; settings change one by one, and each tells its own module
// (on_change), as when they are changed by hand.

setup()
{
    level.ix.presets = spawnstruct();
    level.ix.presets.list = [];
    level.ix.presets.order = [];
    add_builtins();
    custom_scripts\ix\core\chat::add_command( "preset", ::preset_command, "[name | save]: list, apply or save a preset" );
}

// The built-in presets. A value is written as config.gsc writes it (bool 1/0,
// an enum's word, a whole number); test_settings.py checks every one.
add_builtins()
{
    add( "default", "Default", "Every option the game's own, as on a fresh install. The menu, HUD layout and characters stay.", "" );
    add( "classic", "Classic", "Older Call of Duty: mantle the old way, no slide, the round on screen. The rest the game's own.", "mantle=1 legacy_mantle=1 slide=0 hud_round=1" );
    add( "enhanced", "Enhanced", "Wall run, double jump, mantle, max ammo at each spawn, the round and zombies on screen.", "wall_run=1 double_jump=1 mantle=1 start_max_ammo=1 hud_round=1 hud_zombies=1" );
    add( "testing", "Testing", "To try a map or a weapon: host god mode, unlimited ammo and grenades, every perk, 50,000 points.", "god_mode=host unlimited_ammo=clip unlimited_grenades=1 start_perks=1 starting_points=50000 hud_round=1 hud_zombies=1 zombie_outlines=1" );
    add( "developer", "Developer", "For work on the mod: developer tools unlocked, debug log, every HUD number, outlines, host god mode.", "dev_tools=1 debug_log=1 hud_round=1 hud_zombies=1 hud_health=1 hud_speed=1 zombie_outlines=1 god_mode=host" );
    add( "custom", "Custom", "Your own, from Save as Custom below; kept across games.", undefined );
}

// values: "id=value" words, or undefined for Custom (read from the saved dvars).
add( id, title, help, values )
{
    preset = spawnstruct();
    preset.id = id;
    preset.title = title;
    preset.help = help;
    preset.values = [];

    if ( isdefined( values ) )
    {
        foreach ( word in strtok( values, " " ) )
        {
            parts = strtok( word, "=" );

            if ( parts.size == 2 )
                preset.values[parts[0]] = parts[1];
        }
    }
    else
        preset.values = undefined;

    level.ix.presets.list[id] = preset;
    level.ix.presets.order[level.ix.presets.order.size] = id;
}

find( id )
{
    if ( !isdefined( level.ix.presets ) || !isstring( id ) )
        return undefined;

    return level.ix.presets.list[tolower( id )];
}

// No preset changes these.
kept_settings()
{
    return [ "menu", "menu_open", "menu_access", "menu_hint", "hud_side", "hud_height", "character_select", "character_specials", "character_crossmap", "character_announce" ];
}

// Every setting a preset governs, in the settings' own order.
governed()
{
    kept = kept_settings();
    list = [];

    foreach ( id in level.ix.config.order )
    {
        if ( !custom_scripts\ix\core\util::array_contains( kept, id ) )
            list[list.size] = id;
    }

    return list;
}

custom_saved()
{
    return getdvar( "ix_custom_saved" ) == "1";
}

// The text each governed setting has under this preset (id -> text), or
// undefined for Custom before anything is saved.
target_values( preset )
{
    if ( !isdefined( preset.values ) && !custom_saved() )
        return undefined;

    wanted = [];

    foreach ( id in governed() )
    {
        setting = level.ix.config.settings[id];
        text = custom_scripts\ix\core\config::to_text( setting, setting.default_value );

        if ( isdefined( preset.values ) )
        {
            if ( isdefined( preset.values[id] ) )
                text = preset.values[id];
        }
        else
        {
            saved = getdvar( "ix_custom_" + id );

            if ( saved != "" )
                text = saved;
        }

        wanted[id] = text;
    }

    return wanted;
}

// Applies a preset. Returns how many settings changed, or -1 when it cannot
// (unknown, or Custom with nothing saved).
apply( id, source )
{
    preset = find( id );

    if ( !isdefined( preset ) )
        return -1;

    wanted = target_values( preset );

    if ( !isdefined( wanted ) )
        return -1;

    changed = 0;

    foreach ( setting_id in governed() )
    {
        setting = level.ix.config.settings[setting_id];
        before = setting.text;

        if ( before == wanted[setting_id] )
            continue;

        // A saved value this version refuses: the setting's default instead.
        if ( !custom_scripts\ix\core\config::set( setting_id, wanted[setting_id], source ) )
            custom_scripts\ix\core\config::reset_default( setting_id, source );

        if ( setting.text != before )
            changed++;
    }

    custom_scripts\ix\core\log::info( "preset " + preset.id + " applied (" + source + "): " + changed + " settings changed" );
    return changed;
}

// Stores every governed setting's value as Custom. Returns how many.
save_custom( source )
{
    count = 0;

    foreach ( id in governed() )
    {
        custom_scripts\ix\core\persist::save( "ix_custom_" + id, level.ix.config.settings[id].text );
        count++;
    }

    custom_scripts\ix\core\persist::save( "ix_custom_saved", "1" );
    custom_scripts\ix\core\log::info( "preset custom saved (" + source + "): " + count + " settings" );
    return count;
}

// The preset the settings match now, or "Your own".
matching()
{
    foreach ( id in level.ix.presets.order )
    {
        preset = level.ix.presets.list[id];
        wanted = target_values( preset );

        if ( isdefined( wanted ) && matches( wanted ) )
            return preset.title;
    }

    return "Your own";
}

matches( wanted )
{
    foreach ( id in governed() )
    {
        if ( level.ix.config.settings[id].text != wanted[id] )
            return 0;
    }

    return 1;
}

names()
{
    return custom_scripts\ix\core\util::join( level.ix.presets.order, " " );
}

// ---------------------------------------------------------------------------
// The menu (menu_tree.gsc) and chat

// A preset's row on the Presets page: on the player who chose it.
apply_action( id )
{
    preset = find( id );
    changed = apply( id, "menu, " + self.name );

    if ( changed < 0 )
        self iprintln( "Nothing saved as Custom yet: use Save as Custom first." );
    else
        self iprintln( "Preset " + preset.title + ": " + changed + " settings changed." );
}

save_custom_action()
{
    count = save_custom( "menu, " + self.name );
    self iprintln( "Saved as Custom: " + count + " settings." );
}

// "!ix preset", "!ix preset <name>", "!ix preset save" (on the player).
preset_command( words )
{
    if ( words.size < 3 )
    {
        self tell( "Presets: " + names() + ". In use: " + matching() + "." );
        self tell( custom_scripts\ix\core\chat::prefix() + " preset <name> applies one; " + custom_scripts\ix\core\chat::prefix() + " preset save saves yours as Custom (host)." );
        return;
    }

    name = tolower( words[2] );

    if ( name == "save" )
    {
        if ( !custom_scripts\ix\core\chat::host_only( self ) )
            return;

        self tell( "Saved as Custom: " + save_custom( "chat, " + self.name ) + " settings." );
        return;
    }

    preset = find( name );

    if ( !isdefined( preset ) )
    {
        self tell( "No preset " + custom_scripts\ix\core\chat::echo( name ) + ". Presets: " + names() + "." );
        return;
    }

    if ( !custom_scripts\ix\core\chat::host_only( self ) )
        return;

    changed = apply( name, "chat, " + self.name );

    if ( changed < 0 )
        self tell( "Nothing saved as Custom yet: " + custom_scripts\ix\core\chat::prefix() + " preset save" );
    else
        self tell( "Preset " + preset.title + ": " + changed + " settings changed." );
}
