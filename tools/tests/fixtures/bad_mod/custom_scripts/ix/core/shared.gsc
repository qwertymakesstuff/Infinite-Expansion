// shared code breaking several rules; the last four calls must NOT be reported
run()
{
    scripts\cp\utility::_hasperk( "specialty_x" );
    custom_scripts\ix\zombies\z::run();
    self disableinvulnerability();
    line( ( 0, 0, 0 ), ( 1, 1, 1 ) );
    self _meth_845E( 1 );
    // _meth_80A1 inside a comment is fine
    a = "_meth_80A1 inside a string is fine";
    b = va( "%s", 1 );
    logprint( "logprint is a stub in the table but iw7-mod implements it" );
    self tell( "tell is an iw7-mod extension method" );
    c = fileexists( "x" );
}
