// Infinite Expansion - Guided Mode on screen (Phase 13).
//
// The objective tracker, as Black Ops 6's Directed Mode shows it: a small
// panel at the side of the screen with the quest's step count, the current
// objective and its hint (more or less of it, guided_hints), a marker on the
// place to go with how far it is, and a line in the middle of the screen with
// the game's own challenge sounds when an objective is done and the next one
// begins (zmb_challenge_complete / zmb_challenge_start, which cp_challenge.gsc
// plays on every map).
//
// Elements: archived ones (KNOWN_LIMITATIONS.md L49), made once while Guided
// Mode is on and destroyed when it goes off: the panel's back and its bar,
// the header, the objective, four hint lines, the distance and its unit, and
// the marker while there is a place to mark (11). Texts change only when a
// step or the hint level does (the guide's own fixed texts), numbers go
// through setvalue. Hidden while the mod's menu is open, while the player is
// dead or spectating, and over the game's own menus.
//
// The marker: only on a place the game itself looks up for that step (the
// guide's "marker", a struct or entity by targetname), never on guessed
// coordinates; a waypoint (setwaypoint, settargetent for an entity) as the
// stock revive icons are made (cp_laststand.gsc).

// Runs on each player for the whole match (guided.gsc on_connect).
run()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    state = self.ix.guided;
    state.layout = -1;

    while ( !level.ix.guided.loaded )
        wait 0.5;

    // The match's intro first, as the game shows its own first messages.
    if ( scripts\engine\utility::flag_exist( "introscreen_over" ) )
        scripts\engine\utility::flag_wait( "introscreen_over" );

    for (;;)
    {
        if ( !custom_scripts\ix\core\config::get( "guided_mode" ) )
        {
            destroy_panel();
            state.notified = undefined;
            state.ahead_seen = undefined;
            custom_scripts\ix\core\config::wait_for_change();
            continue;
        }

        if ( !isdefined( level.ix.guided.guide ) )
        {
            show_unavailable();
            custom_scripts\ix\core\config::wait_for_change();
            continue;
        }

        if ( !isdefined( state.hud ) )
            create();

        if ( state.layout != level.ix.guided.layout )
            place();

        update();
        wait 0.25;
    }
}

// ---------------------------------------------------------------------------
// Layout

text_scale()
{
    switch ( custom_scripts\ix\core\config::get( "guided_text" ) )
    {
        case "small":
            return 0.65;
        case "large":
            return 0.9;
    }

    return 0.75;
}

// Characters a hint line holds at this size.
line_chars()
{
    return int( panel_width() / ( text_scale() * 7.2 ) );
}

line_height()
{
    return int( text_scale() * 14 );
}

panel_width()
{
    return 230;
}

hint_lines()
{
    return 4;
}

gold()
{
    return ( 1, 0.78, 0.25 );
}

panel_top()
{
    return 64 + custom_scripts\ix\core\config::get( "guided_height" );
}

// The panel's left edge: right side, just inside the 4:3 screen's right edge
// (horzalign "center", as the menu and the info HUD are placed); left side,
// from the screen's left edge.
panel_left()
{
    if ( custom_scripts\ix\core\config::get( "guided_side" ) == "right" )
        return 316 - panel_width();

    return 6;
}

horizontal()
{
    if ( custom_scripts\ix\core\config::get( "guided_side" ) == "right" )
        return "center";

    return "left";
}

opacity()
{
    return custom_scripts\ix\core\config::get( "guided_opacity" ) / 100.0;
}

// ---------------------------------------------------------------------------
// Elements

new_element( font )
{
    element = newclienthudelem( self );
    element.vertalign = "top";
    element.alignx = "left";
    element.aligny = "top";
    element.sort = 12;
    element.foreground = 1;
    element.hidewheninmenu = 1;
    element.hidewhendead = 1;
    element.archived = 1;
    element.alpha = 0;

    if ( isdefined( font ) )
        element.font = font;

    return element;
}

create()
{
    hud = spawnstruct();
    hud.back = new_element();
    hud.back.sort = 10;
    hud.bar = new_element();
    hud.bar.sort = 11;
    hud.header = new_element( "objective" );
    hud.objective = new_element( "objective" );
    hud.hints = [];

    for ( i = 0; i < hint_lines(); i++ )
        hud.hints[i] = new_element( "default" );

    hud.distance = new_element( "default" );
    hud.distance.alignx = "right";
    hud.unit = new_element( "default" );
    hud.unit settext( "m" );
    hud.shown = [];
    hud.back_height = -1;
    self.ix.guided.hud = hud;
    self.ix.guided.layout = -1;
}

destroy_panel()
{
    hud = self.ix.guided.hud;

    if ( !isdefined( hud ) )
        return;

    foreach ( element in [ hud.back, hud.bar, hud.header, hud.objective, hud.distance, hud.unit ] )
    {
        if ( isdefined( element ) )
            element destroy();
    }

    foreach ( element in hud.hints )
    {
        if ( isdefined( element ) )
            element destroy();
    }

    remove_marker();
    self.ix.guided.hud = undefined;
}

// Puts every element where the settings say (also after a change of side,
// height, size or opacity, without making them again).
place()
{
    hud = self.ix.guided.hud;
    scale = text_scale();
    left = panel_left();
    top = panel_top();
    lines = line_height();

    foreach ( element in [ hud.back, hud.bar, hud.header, hud.objective, hud.distance, hud.unit ] )
        element.horzalign = horizontal();

    foreach ( element in hud.hints )
        element.horzalign = horizontal();

    hud.back.x = left;
    hud.back.y = top;
    hud.bar.x = left + 6;
    hud.bar.y = top + lines + 8;
    hud.header.x = left + 10;
    hud.header.y = top + 5;
    hud.header.fontscale = scale * 0.95;
    hud.header.color = gold();
    hud.objective.x = left + 12;
    hud.objective.y = top + lines + 8;
    hud.objective.fontscale = scale * 1.1;
    hud.objective.color = ( 1, 1, 1 );

    for ( i = 0; i < hud.hints.size; i++ )
    {
        hud.hints[i].x = left + 12;
        hud.hints[i].y = top + lines * ( i + 2 ) + 14;
        hud.hints[i].fontscale = scale;
        hud.hints[i].color = ( 0.82, 0.82, 0.82 );
    }

    hud.distance.x = left + panel_width() - 16;
    hud.distance.y = top + 5;
    hud.distance.fontscale = scale;
    hud.distance.color = ( 1, 1, 1 );
    hud.unit.x = left + panel_width() - 14;
    hud.unit.y = top + 5;
    hud.unit.fontscale = scale;
    hud.unit.color = ( 0.82, 0.82, 0.82 );
    hud.back_height = -1;
    hud.shown = [];
    self.ix.guided.layout = level.ix.guided.layout;
}

// Text only when it changed: the guide's own fixed strings.
show_text( element, key, text )
{
    hud = self.ix.guided.hud;

    if ( !isdefined( hud.shown[key] ) || hud.shown[key] != text )
    {
        element settext( text );
        hud.shown[key] = text;
    }
}

size_back( lines )
{
    hud = self.ix.guided.hud;
    height = line_height() * ( lines + 2 ) + 18;

    if ( hud.back_height != height )
    {
        hud.back setshader( "white", panel_width(), height );
        hud.bar setshader( "white", 2, height - line_height() - 14 );
        hud.back_height = height;
    }
}

// ---------------------------------------------------------------------------
// Every quarter of a second

update()
{
    hud = self.ix.guided.hud;
    guide = level.ix.guided.guide;
    steps = guide.steps;
    current = custom_scripts\ix\guided\tracker::current_index( self );
    index = self custom_scripts\ix\guided\guided::viewed_index();
    mode = custom_scripts\ix\core\config::get( "guided_panel" );
    hidden = mode == "hidden" || custom_scripts\ix\ui\menu::is_open_for( self ) || !isdefined( self.sessionstate ) || self.sessionstate != "playing";

    notify_progress( current );
    notify_ahead( current );

    if ( current >= steps.size && index >= steps.size )
    {
        show_text( hud.header, "header", "MAIN QUEST COMPLETE" );
        show_text( hud.objective, "objective", guide.quest );
        lines = [ "Every step of the quest is done." ];
        target = undefined;
    }
    else
    {
        step = steps[index];
        show_text( hud.header, "header", header_text( index, current, steps.size ) );
        objective = step.objective;

        if ( index == current )
            objective = objective + custom_scripts\ix\guided\tracker::progress_text( step );

        show_text( hud.objective, "objective", objective );
        lines = hint_page( step, index, current );
        target = undefined;

        if ( index == current )
            target = marker_target( step );
    }

    if ( mode == "compact" )
        lines = [];

    for ( i = 0; i < hud.hints.size; i++ )
    {
        if ( i < lines.size )
        {
            show_text( hud.hints[i], "hint" + i, lines[i] );
            hud.hints[i].alpha = visible( hidden );
        }
        else
            hud.hints[i].alpha = 0;
    }

    size_back( lines.size );
    hud.back.color = ( 0, 0, 0 );
    hud.back.alpha = visible( hidden ) * 0.5;
    hud.bar.color = gold();
    hud.bar.alpha = visible( hidden );
    hud.header.alpha = visible( hidden );
    hud.objective.alpha = visible( hidden );
    update_marker( target, hidden );
}

visible( hidden )
{
    if ( hidden )
        return 0;

    return opacity();
}

header_text( index, current, total )
{
    count = ( index + 1 ) + "/" + total;

    if ( index < current )
        return "DONE  " + count;

    if ( index > current )
        return "AHEAD  " + count;

    return "MAIN QUEST  " + count;
}

// The hint lines for this step at this player's level, a page at a time:
// a hint longer than four lines turns its pages every six seconds.
hint_page( step, index, current )
{
    rank = self custom_scripts\ix\guided\guided::hint_level();
    text = step.location + ". " + step.hints[rank];

    if ( rank == 0 )
        text = step.hints[0];

    if ( custom_scripts\ix\guided\guided::full_walkthrough() && index == current && index + 1 < level.ix.guided.guide.steps.size )
        text = text + " Next: " + level.ix.guided.guide.steps[index + 1].objective + ".";

    all = custom_scripts\ix\ui\menu::wrap( text, line_chars(), 32 );

    if ( all.size <= hint_lines() )
        return all;

    pages = int( ( all.size + hint_lines() - 1 ) / hint_lines() );
    page = int( gettime() / 6000 ) % pages;
    lines = [];

    for ( i = page * hint_lines(); i < all.size && lines.size < hint_lines(); i++ )
        lines[lines.size] = all[i];

    lines[lines.size - 1] = lines[lines.size - 1] + "  (" + ( page + 1 ) + "/" + pages + ")";
    return lines;
}

// ---------------------------------------------------------------------------
// Notifications: once per change, with the game's own challenge sounds

notify_progress( current )
{
    state = self.ix.guided;

    if ( isdefined( state.notified ) && state.notified == current )
        return;

    previous = state.notified;
    state.notified = current;
    self thread announce( previous, current );
}

// A step done in any order (step.parallel) past this player's current one:
// announced once, as the game reports it. A player who joins later hears
// only what is done from then on.
notify_ahead( current )
{
    state = self.ix.guided;
    done = level.ix.guided.done_ahead;

    if ( !isdefined( state.ahead_seen ) )
        state.ahead_seen = done.size;

    if ( state.ahead_seen >= done.size )
        return;

    index = done[state.ahead_seen];
    state.ahead_seen++;

    if ( index > current )
    {
        self custom_scripts\ix\core\compat::local_sound( "zmb_challenge_complete" );
        self iprintlnbold( "Objective complete: " + level.ix.guided.guide.steps[index].objective );
    }
}

announce( previous, current )
{
    self endon( "disconnect" );
    self notify( "ix_guided_announce" );
    self endon( "ix_guided_announce" );
    steps = level.ix.guided.guide.steps;

    if ( isdefined( previous ) && previous < current )
    {
        self custom_scripts\ix\core\compat::local_sound( "zmb_challenge_complete" );
        self iprintlnbold( "Objective complete: " + steps[previous].objective );
        wait 3;
    }

    if ( current >= steps.size )
    {
        self iprintlnbold( level.ix.guided.guide.quest + ": complete" );
        return;
    }

    self custom_scripts\ix\core\compat::local_sound( "zmb_challenge_start" );
    self iprintlnbold( "New objective: " + steps[current].objective );
}

// ---------------------------------------------------------------------------
// The marker

// Where the step's marker goes: an entity, a point, or undefined.
marker_target( step )
{
    if ( !custom_scripts\ix\core\config::get( "guided_marker" ) || step.marker == "none" )
        return undefined;

    if ( step.marker == "locate" )
    {
        if ( isdefined( step.locate ) )
            return self [[ step.locate ]]();

        return undefined;
    }

    parts = strtok( step.marker, ":" );

    if ( parts.size != 2 )
        return undefined;

    switch ( parts[0] )
    {
        case "struct":
            found = scripts\engine\utility::getstruct( parts[1], "targetname" );

            if ( isdefined( found ) )
                return found.origin;

            return undefined;
        case "ent":
            return getent( parts[1], "targetname" );
        case "structs":
            return nearest_origin( scripts\engine\utility::getstructarray( parts[1], "targetname" ) );
        case "ents":
            return nearest_origin( getentarray( parts[1], "targetname" ) );
        case "sn_struct":
            found = scripts\engine\utility::getstruct( parts[1], "script_noteworthy" );

            if ( isdefined( found ) )
                return found.origin;

            return undefined;
        case "sn_structs":
            return nearest_origin( scripts\engine\utility::getstructarray( parts[1], "script_noteworthy" ) );
        case "interaction":
            return nearest_origin( custom_scripts\ix\guided\guided::interactions( parts[1] ) );
    }

    return undefined;
}

nearest_origin( things )
{
    best = undefined;
    best_distance = 0;

    foreach ( thing in things )
    {
        if ( !isdefined( thing ) || !isdefined( thing.origin ) )
            continue;

        gap = distancesquared( self.origin, thing.origin );

        if ( !isdefined( best ) || gap < best_distance )
        {
            best = thing.origin;
            best_distance = gap;
        }
    }

    return best;
}

update_marker( target, hidden )
{
    hud = self.ix.guided.hud;

    if ( !isdefined( target ) )
    {
        remove_marker();
        hud.distance.alpha = 0;
        hud.unit.alpha = 0;
        return;
    }

    position = target;

    if ( !isvector( target ) )
        position = target.origin;

    if ( !isdefined( hud.marker ) || !same_target( hud.marker_target, target ) )
    {
        remove_marker();
        marker = newclienthudelem( self );
        marker setshader( "white", 7, 7 );
        marker.color = gold();
        marker.archived = 1;
        marker.hidewhendead = 1;
        marker.hidewheninmenu = 1;
        marker setwaypoint( 1, 1 );

        if ( isvector( target ) )
        {
            marker.x = position[0];
            marker.y = position[1];
            marker.z = position[2] + 40;
        }
        else
        {
            // Above the entity's origin, as an offset.
            marker.x = 0;
            marker.y = 0;
            marker.z = 40;
            marker settargetent( target );
        }

        hud.marker = marker;
        hud.marker_target = target;
    }

    hud.marker.alpha = visible( hidden );
    meters = int( distance( self.origin, position ) * 0.0254 + 0.5 );

    if ( !isdefined( hud.meters ) || hud.meters != meters )
    {
        hud.distance setvalue( meters );
        hud.meters = meters;
    }

    hud.distance.alpha = visible( hidden );
    hud.unit.alpha = visible( hidden );
}

same_target( a, b )
{
    if ( !isdefined( a ) || !isdefined( b ) )
        return 0;

    if ( isvector( a ) != isvector( b ) )
        return 0;

    return a == b;
}

remove_marker()
{
    hud = self.ix.guided.hud;

    if ( !isdefined( hud ) )
        return;

    if ( isdefined( hud.marker ) )
        hud.marker destroy();

    hud.marker = undefined;
    hud.marker_target = undefined;
}

// ---------------------------------------------------------------------------
// A map without a guide: said once each time Guided Mode goes on, then gone.

show_unavailable()
{
    if ( !isdefined( self.ix.guided.hud ) )
        create();

    place();
    hud = self.ix.guided.hud;
    show_text( hud.header, "header", "GUIDED MODE UNAVAILABLE" );
    show_text( hud.objective, "objective", "No guide for this map yet" );
    show_text( hud.hints[0], "hint0", "A verified guide has not been added" );
    show_text( hud.hints[1], "hint1", "for this map yet." );
    size_back( 2 );

    for ( i = 0; i < 48 && custom_scripts\ix\core\config::get( "guided_mode" ); i++ )
    {
        hidden = custom_scripts\ix\ui\menu::is_open_for( self ) || !isdefined( self.sessionstate ) || self.sessionstate != "playing";
        hud.back.color = ( 0, 0, 0 );
        hud.back.alpha = visible( hidden ) * 0.5;
        hud.bar.color = gold();
        hud.bar.alpha = visible( hidden );
        hud.header.alpha = visible( hidden );
        hud.objective.alpha = visible( hidden );
        hud.hints[0].alpha = visible( hidden );
        hud.hints[1].alpha = visible( hidden );
        wait 0.25;
    }

    destroy_panel();
}
