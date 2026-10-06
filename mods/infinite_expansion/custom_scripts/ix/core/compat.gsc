// Infinite Expansion - client compatibility layer.
//
// The two compilers players may be running (iw7-mod v1.1.0 and develop)
// resolve some built-in names differently (IW_API_NOTES.md section 4,
// KNOWN_LIMITATIONS.md C1-C3). Raw _meth_XXXX ids compile to the same native
// on both, so every raw id the mod needs lives here, behind a readable name.
// tools/check.py rejects raw ids anywhere else.
//
// The wrappers are methods: call them as  player custom_scripts\ix\core\compat::god_off();

setup()
{
    client = spawnstruct();
    client.has_fs_game = getdvar( "fs_game" ) != "";

    // Movement dvars added to iw7-mod after v1.1.0 (KNOWN_LIMITATIONS.md C4).
    client.has_omnimovement = has_dvar( "bg_omnimovement" );
    client.has_sprint_unlimited = has_dvar( "bg_sprintUnlimited" );
    client.has_air_control = has_dvar( "bg_airControl" );

    level.ix.client = client;
}

// getdvar() returns "" for a dvar that is not registered. A registered dvar
// whose value is the empty string also reads as missing; only use this for
// dvars that always hold a value.
has_dvar( name )
{
    return getdvar( name ) != "";
}

describe()
{
    client = level.ix.client;
    return "fs_game=" + client.has_fs_game + " omnimovement=" + client.has_omnimovement + " sprint_unlimited=" + client.has_sprint_unlimited + " air_control=" + client.has_air_control;
}

// disableinvulnerability(): v1.1.0 compiles that name to disablegrenadetouchdamage (C1).
god_off()
{
    self _meth_80A1();
}

// playlocalsound( alias ): v1.1.0 compiles that name to playercommandbot (C2).
local_sound( alias )
{
    self _meth_8242( alias );
}

// setcamerathirdperson( enabled ): name unknown to v1.1.0.
third_person( enabled )
{
    self _meth_845E( enabled );
}

// setfiretimescaleon( percent ): fire time as a percentage of normal, lower is
// faster (stock: scripts\cp\cp_weaponpassives uses 65). Name unknown to v1.1.0.
fire_rate_on( percent )
{
    self _meth_85C1( percent );
}

// setfiretimescaleoff(): name unknown to v1.1.0.
fire_rate_off()
{
    self _meth_85C2();
}

// player_getrecoilscale(): below 0 while no override is active. Name unknown to v1.1.0.
recoil_get()
{
    return self _meth_85C0();
}

// player_recoilscaleoff(): name unknown to v1.1.0.
recoil_off()
{
    self _meth_822C();
}

// resetspreadoverride(): name unknown to v1.1.0.
spread_reset()
{
    self _meth_8263();
}

// hasperk( perk ): name unknown to v1.1.0.
has_perk( perk )
{
    return self _meth_8181( perk );
}
