// Infinite Expansion - give yourself any weapon of this map (Weapons page,
// "Give a weapon"; host only unless menu_access is everyone).
//
// The list (IW_API_NOTES.md section 21):
//   - the map's own weapon table, level.coop_weapontable (Spaceland
//     cp/cp_weapontable.csv, Rave in the Redwoods cp/cp_rave_weapontable.csv,
//     and so on), read as the stock scripts\cp\zombies\coop_wall_buys.gsc
//     parse_weapons_table reads it: column 1 the weapon, column 2 its kinds.
//     The weapons the box offers ("magic") or a wall sells ("wall"), so only
//     weapons this map has loaded are listed, grouped by the class the stock
//     coop_getweaponclass() gives them;
//   - this map's own wonder weapons, as Director's Cut puts them in the box
//     (scripts\cp\zombies\directors_cut.gsc add_wonder_weapons_to_magic_wheel).
//     Another map's wonder weapons are not loaded here, so none is offered.
//
// Giving, as the box gives its weapon (interaction_magicwheel.gsc in
// scripts/cp/zombies, the plain branch, not upgraded): with every slot full
// (zombies_weapons::should_take_players_current_weapon: 3, or 4 with Mule
// Munchies) the weapon in hand goes (utility::getvalidtakeweapon) with its
// Pack-a-Punch level; fists go; the player's own build of that weapon is
// used when the game has one (self.weapon_build_models); the name gets the
// player's attachments (cp_weapon::return_weapon_name_with_like_attachments);
// utility::_giveweapon gives it; its Pack-a-Punch level is 1;
// then max ammo, and the player switches to it. A weapon the player has
// already gets max ammo and is switched to. The menu closes first: its own
// hold keeps weapons away while it is open. No points, merits or box state
// change.

register()
{
    level.ix.give = spawnstruct();
}

// ---------------------------------------------------------------------------
// The list

// The map's weapon table, as the stock parser picks it.
table_name()
{
    if ( isdefined( level.coop_weapontable ) )
        return level.coop_weapontable;

    return "cp/cp_weapontable.csv";
}

// Groups of weapons for the menu, made once: an array of structs with id,
// title and entries (structs with weapon, label).
groups()
{
    if ( isdefined( level.ix.give.groups ) )
        return level.ix.give.groups;

    titles = [];
    titles["weapon_assault"] = "Assault rifles";
    titles["weapon_smg"] = "SMGs";
    titles["weapon_shotgun"] = "Shotguns";
    titles["weapon_lmg"] = "LMGs";
    titles["weapon_sniper"] = "Snipers";
    titles["weapon_pistol"] = "Pistols";
    order = [ "weapon_assault", "weapon_smg", "weapon_shotgun", "weapon_lmg", "weapon_sniper", "weapon_pistol", "other" ];
    titles["other"] = "Other";

    by_class = [];
    seen = [];
    table = table_name();

    for ( row = 0; row < 500; row++ )
    {
        if ( tablelookupbyrow( table, row, 0 ) == "" )
            break;

        weapon = tablelookupbyrow( table, row, 1 );
        kinds = strtok( tablelookupbyrow( table, row, 2 ), " " );

        if ( weapon == "" || !( custom_scripts\ix\core\util::array_contains( kinds, "magic" ) || custom_scripts\ix\core\util::array_contains( kinds, "wall" ) ) )
            continue;

        base = scripts\cp\utility::getrawbaseweaponname( weapon );

        if ( isdefined( seen[base] ) )
            continue;

        seen[base] = 1;
        kind = weapon_class( weapon );

        if ( !isdefined( titles[kind] ) )
            kind = "other";

        if ( !isdefined( by_class[kind] ) )
            by_class[kind] = [];

        entry = spawnstruct();
        entry.weapon = weapon;
        entry.label = upper( base );
        by_class[kind][by_class[kind].size] = entry;
    }

    groups = [];

    foreach ( kind in order )
    {
        if ( !isdefined( by_class[kind] ) )
            continue;

        group = spawnstruct();
        group.id = kind;
        group.title = titles[kind];
        group.entries = by_class[kind];
        groups[groups.size] = group;
    }

    specials = wonder_weapons();

    if ( specials.size > 0 )
    {
        group = spawnstruct();
        group.id = "wonder";
        group.title = "Wonder weapons";
        group.entries = specials;
        groups[groups.size] = group;
    }

    level.ix.give.groups = groups;
    count = 0;

    foreach ( group in groups )
        count += group.entries.size;

    custom_scripts\ix\core\log::info( "give: " + count + " weapons from " + table + " and this map's wonder weapons" );
    return groups;
}

// The stock class ("weapon_assault", ...; "other" when the stats table has
// none), from the game's stats table.
weapon_class( weapon )
{
    if ( !isdefined( level.statstable ) )
        return "other";

    return scripts\cp\utility::coop_getweaponclass( weapon );
}

// This map's wonder weapons, with the names Director's Cut gives the box.
wonder_weapons()
{
    list = [];

    switch ( level.script )
    {
        case "cp_zmb":
            list[list.size] = wonder( "Dischord", "iw7_dischord_zm_pap1" );
            list[list.size] = wonder( "Face Melter", "iw7_facemelter_zm_pap1" );
            list[list.size] = wonder( "Headcutter", "iw7_headcutter_zm_pap1" );
            list[list.size] = wonder( "Shredder", "iw7_shredder_zm_pap1" );
            break;
        case "cp_rave":
            list[list.size] = wonder( "Acid Rain", "iw7_harpoon1_zm" );
            list[list.size] = wonder( "Ben Franklin", "iw7_harpoon2_zm" );
            list[list.size] = wonder( "Trap-o-matic", "iw7_harpoon3_zm+akimbo" );
            list[list.size] = wonder( "Whirlwind", "iw7_harpoon4_zm" );
            break;
        case "cp_disco":
            list[list.size] = wonder( "Nunchucks", "iw7_nunchucks_zm_pap1" );
            break;
        case "cp_town":
            list[list.size] = wonder( "Cutie", "iw7_cutie_zm+cutiecrank+cutiegrip+cutieplunger" );
            break;
        case "cp_final":
            list[list.size] = wonder( "Venom-X", "iw7_venomx_zm_pap1" );
            break;
    }

    return list;
}

wonder( label, weapon )
{
    entry = spawnstruct();
    entry.weapon = weapon;
    entry.label = label;
    return entry;
}

// "ar57" -> "AR57" (the game has no upper-case built-in).
upper( text )
{
    lower_case = "abcdefghijklmnopqrstuvwxyz";
    upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    result = "";

    for ( i = 0; i < text.size; i++ )
    {
        c = getsubstr( text, i, i + 1 );

        for ( j = 0; j < lower_case.size; j++ )
        {
            if ( getsubstr( lower_case, j, j + 1 ) == c )
            {
                c = getsubstr( upper_case, j, j + 1 );
                break;
            }
        }

        result += c;
    }

    return result;
}

// The help line every weapon row shows (menu_tree.gsc; test_settings.py
// checks that it fits).
entry_help()
{
    return "Into your hands with full ammo. With every slot full, the weapon in your hands goes, as with the box.";
}

// ---------------------------------------------------------------------------
// Giving

// The menu row's action: entry is a struct from groups().
give_entry( entry )
{
    if ( !can_take_weapon() )
        return;

    self custom_scripts\ix\ui\menu::close_menu_for_move();
    self thread give_after_close( entry );
}

can_take_weapon()
{
    if ( !isalive( self ) || !isdefined( self.sessionstate ) || self.sessionstate != "playing" )
        return 0;

    if ( isdefined( self.inlaststand ) && self.inlaststand )
    {
        self iprintln( "Not while you are down." );
        return 0;
    }

    if ( isdefined( self.in_afterlife_arcade ) && self.in_afterlife_arcade )
    {
        self iprintln( "Not in the afterlife arcade." );
        return 0;
    }

    return 1;
}

// After the menu has let go of the player's weapons.
give_after_close( entry )
{
    self endon( "disconnect" );
    self endon( "death" );
    wait 0.1;

    if ( !can_take_weapon() )
        return;

    weapon = entry.weapon;
    base = scripts\cp\utility::getrawbaseweaponname( weapon );

    foreach ( owned in self getweaponslistprimaries() )
    {
        if ( scripts\cp\utility::getrawbaseweaponname( owned ) == base )
        {
            self givemaxammo( owned );
            self switchtoweapon( owned );
            self iprintln( entry.label + ": you have it already; ammo refilled." );
            return;
        }
    }

    if ( scripts\cp\zombies\zombies_weapons::should_take_players_current_weapon( self ) )
    {
        taken = self scripts\cp\utility::getvalidtakeweapon();
        taken_base = scripts\cp\utility::getrawbaseweaponname( taken );
        self takeweapon( taken );

        if ( isdefined( self.pap ) && isdefined( self.pap[taken_base] ) )
        {
            self.pap[taken_base] = undefined;
            self notify( "weapon_level_changed" );
        }
    }

    scripts\cp\utility::take_fists_weapon( self );

    if ( isdefined( self.weapon_build_models ) && isdefined( self.weapon_build_models[base] ) )
        weapon = self.weapon_build_models[base];

    built = self scripts\cp\cp_weapon::return_weapon_name_with_like_attachments( weapon, undefined, getweaponattachments( weapon ), undefined, undefined );

    // The builder answers undefined when the attachments do not fit.
    if ( isdefined( built ) )
        weapon = built;

    weapon = self scripts\cp\utility::_giveweapon( weapon, undefined, undefined, 0 );

    if ( isdefined( self.pap ) )
    {
        level_info = spawnstruct();
        level_info.lvl = 1;
        self.pap[scripts\cp\utility::getrawbaseweaponname( weapon )] = level_info;
        self notify( "weapon_level_changed" );
    }

    if ( issubstr( weapon, "g18_" ) )
        self.has_replaced_starting_pistol = 1;

    self givemaxammo( weapon );
    self switchtoweapon( weapon );
    custom_scripts\ix\core\log::info( "give: " + weapon + " to " + self.name );
}
