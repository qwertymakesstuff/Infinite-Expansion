// built-ins from the game, built-ins added by iw7-mod, stock and compat calls
run()
{
    a = va( "%s", clamp( 5, 0, 1 ) );
    logprint( a );
    print( a );
    b = fileexists( "x" );
    self tell( "x" );
    level thread scripts\engine\utility::waittill_any( "x" );
    self custom_scripts\ix\core\compat::god_off();
}

watch()
{
    level endon( "game_ended" );
    level waittill( "never" );
}
