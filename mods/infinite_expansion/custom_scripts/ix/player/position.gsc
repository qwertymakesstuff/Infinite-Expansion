// Infinite Expansion - position tools: save a spot, go back to it, teleport to
// where you look. Menu actions (menu_tree.gsc), host only unless menu_access is
// everyone. The saved spot lasts until the match ends.
//
// The menu holds its player in place by linking them (menu.gsc hold()), and
// a linked player cannot be moved, so a teleport closes the menu first. A
// teleport is refused while the player is down, dead, or linked to anything
// else (a ride, a trap, fast travel). It can put a player where the game does
// not expect one (KNOWN_LIMITATIONS.md L45).
//
// Teleport to crosshair: bullettrace from the eye along the view finds the
// surface (refused for the sky or nothing within 8000 units);
// playerphysicstrace then drops a player-sized box onto the floor just in
// front of it (stock MP scripts place players with it).

save_position()
{
    if ( !can_teleport() )
        return;

    self.ix.saved_origin = self.origin;
    self.ix.saved_angles = self getplayerangles();
    self iprintln( "Position saved." );
}

load_position()
{
    if ( !isdefined( self.ix.saved_origin ) )
    {
        self iprintln( "No saved position yet: use Save position first." );
        return;
    }

    if ( !can_teleport() )
        return;

    move_to( self.ix.saved_origin, self.ix.saved_angles );
}

teleport_to_crosshair()
{
    if ( !can_teleport() )
        return;

    eye = self geteye();
    forward = anglestoforward( self getplayerangles() );
    trace = bullettrace( eye, eye + forward * 8000, 0, self );

    // Nothing in reach, or the sky: the stock scripts read a trace this way
    // (cp_weapon.gsc: fraction 1; the MP vanguard: surfacetype "none").
    if ( trace["fraction"] == 1 || trace["surfacetype"] == "none" )
    {
        self iprintln( "Look at a floor or a wall first." );
        return;
    }

    hit = trace["position"];

    if ( distance( eye, hit ) < 48 )
    {
        self iprintln( "Too close: look further away." );
        return;
    }

    // A little before the surface, then down onto the floor.
    spot = hit - forward * 32;
    spot = playerphysicstrace( spot + ( 0, 0, 16 ), spot - ( 0, 0, 512 ) );
    move_to( spot, self getplayerangles() );
}

// Alive, playing, standing on their own feet, and not taken by the game.
can_teleport()
{
    if ( !isalive( self ) || !isdefined( self.sessionstate ) || self.sessionstate != "playing" )
        return 0;

    if ( isdefined( self.inlaststand ) && self.inlaststand )
    {
        self iprintln( "Not while you are down." );
        return 0;
    }

    if ( self islinked() && !custom_scripts\ix\ui\menu::is_menu_link( self ) )
    {
        self iprintln( "Not while the game is moving you." );
        return 0;
    }

    return 1;
}

move_to( origin, angles )
{
    self custom_scripts\ix\ui\menu::close_menu_for_move();
    self setorigin( origin );

    if ( isdefined( angles ) )
        self setplayerangles( angles );
}
