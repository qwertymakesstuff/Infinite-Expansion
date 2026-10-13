// Infinite Expansion - Guided Mode (Phase 13).
//
// An optional companion for each map's main Easter egg quest, in the spirit
// of Black Ops 6's Directed Mode: an objective tracker on screen with the
// current step and a hint, a marker on the place to go when the game itself
// knows where that is, and objectives that move on by themselves when the
// game's own quest scripts mark a step done. It never does anything to the
// quest: it only reads the game's flags and notifies, and draws.
//
// Off by default. Players switch it on in the zombies lobby (the GUIDED MODE
// button, which saves the archived dvar ix_guided_mode, ui_scripts) or on the
// menu's Guided Mode page; like every setting, the host's choice applies to
// the match.
//
// The files:
//   guided.gsc      this module: settings, the guide of this map, the menu's
//                   rows and actions, "!ix guide"
//   tracker.gsc     which step the quest is at (the game's own signals, and
//                   steps players mark done by hand)
//   panel.gsc       the tracker on screen, the marker, the notifications
//   guides/<map>.gsc  one guide per map, data only (steps, hints, signals,
//                   where the marker goes); add a file there and a line in
//                   load_guide() for another map
//
// Settings:
//   guided_mode     0         1: the guide is on
//   guided_hints    standard  minimal / standard / detailed / full
//   guided_panel    full      full / compact (the objective only) / hidden
//   guided_marker   1         the marker and how far it is
//   guided_side     right     right / left
//   guided_height   0         -150 to 150: down (more) or up (less)
//   guided_text     normal    small / normal / large
//   guided_opacity  100       30 to 100: percent
//   guided_coop     shared    shared / personal: whom a step marked by hand is done for

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "guided" );

    custom_scripts\ix\core\config::add_bool( "guided_mode", 0, "Guided Mode", "A tracker for this map's main Easter egg quest: objective, hint, marker. Also in the lobby.", ::on_mode_changed );
    custom_scripts\ix\core\config::add_enum( "guided_hints", "standard", "minimal standard detailed full", "Guided: hints", "How much the guide says. full: every step and solution, ahead too.", ::on_view_changed );
    custom_scripts\ix\core\config::add_enum( "guided_panel", "full", "full compact hidden", "Guided: panel", "full: objective and hint. compact: the objective only. hidden: none.", ::on_view_changed );
    custom_scripts\ix\core\config::add_bool( "guided_marker", 1, "Guided: marker", "A marker on the objective and how far it is, where the game itself knows the place.", ::on_view_changed );
    custom_scripts\ix\core\config::add_enum( "guided_side", "right", "right left", "Guided: side", "Which side of the screen the tracker is on.", ::on_view_changed );
    custom_scripts\ix\core\config::add_int( "guided_height", 0, -150, 150, "Guided: height", "Moves the tracker down (more) or up (less).", ::on_view_changed );
    custom_scripts\ix\core\config::add_enum( "guided_text", "normal", "small normal large", "Guided: text size", "The tracker's text size.", ::on_view_changed );
    custom_scripts\ix\core\config::add_int( "guided_opacity", 100, 30, 100, "Guided: opacity", "Percent: how solid the tracker is.", ::on_view_changed );
    custom_scripts\ix\core\config::add_enum( "guided_coop", "shared", "shared personal", "Guided: co-op", "shared: a step marked done is done for all. personal: for you. The game's own steps count for all.", ::on_view_changed );

    level.ix.guided = spawnstruct();
    level.ix.guided.loaded = 0;
    level.ix.guided.layout = 0;

    custom_scripts\ix\core\events::subscribe( "player_connect", ::on_connect );
    custom_scripts\ix\core\chat::add_command( "guide", ::guide_command, "[next | prev | more | done]: the quest's current objective" );
    level thread start_when_ready();
}

// ---------------------------------------------------------------------------
// The guide of this map

// The stock maps set their quests up in main(), before "ix_ready".
start_when_ready()
{
    level endon( "game_ended" );

    if ( !level.ix.ready )
        level waittill( "ix_ready" );

    level.ix.guided.guide = load_guide( level.ix.map );
    level.ix.guided.loaded = 1;

    if ( isdefined( level.ix.guided.guide ) )
    {
        custom_scripts\ix\core\log::info( "guided: " + level.ix.guided.guide.map_name + ", " + level.ix.guided.guide.steps.size + " steps" );
        custom_scripts\ix\guided\tracker::start( level.ix.guided.guide );
    }
    else
        custom_scripts\ix\core\log::info( "guided: no verified guide for " + level.ix.map );
}

// One guide per map; undefined for a map without one (never another map's).
load_guide( map )
{
    switch ( map )
    {
        case "cp_zmb":
            return custom_scripts\ix\guided\guides\cp_zmb::guide();
        case "cp_rave":
            return custom_scripts\ix\guided\guides\cp_rave::guide();
        case "cp_disco":
            return custom_scripts\ix\guided\guides\cp_disco::guide();
        case "cp_town":
            return custom_scripts\ix\guided\guides\cp_town::guide();
        case "cp_final":
            return custom_scripts\ix\guided\guides\cp_final::guide();
    }

    return undefined;
}

guide()
{
    return level.ix.guided.guide;
}

has_guide()
{
    return isdefined( level.ix.guided.guide );
}

is_on()
{
    return custom_scripts\ix\core\config::get( "guided_mode" );
}

// ---------------------------------------------------------------------------
// The guides' own vocabulary (guides/<map>.gsc)

new_guide( map, map_name, quest, prerequisites )
{
    guide = spawnstruct();
    guide.map = map;
    guide.map_name = map_name;
    guide.quest = quest;
    guide.prerequisites = prerequisites;
    guide.steps = [];
    return guide;
}

// detect: "flag:<name>" (done once the game sets that flag), "flags:<a>+<b>"
// (all of them), "notify:<name>" (done once level gets that notify),
// "count:<name>*<n>" (after n of that notify, shown as (2/3)), "check"
// (the step's own check function, step.check) or "manual" (players mark it).
// marker: "struct:<targetname>", "ent:<targetname>", "structs:<targetname>" /
// "ents:<targetname>" (the nearest of them), "locate" (the step's own
// function, step.locate) or "none". Only places the game's own quest scripts
// look up themselves.
add_step( guide, id, objective, location, minimal, standard, detailed, detect, marker )
{
    step = spawnstruct();
    step.id = id;
    step.index = guide.steps.size;
    step.objective = objective;
    step.location = location;
    step.hints = [ minimal, standard, detailed ];
    step.detect = detect;
    step.marker = marker;
    step.auto = 0;
    step.seen = 0;
    step.marked = 0;
    guide.steps[guide.steps.size] = step;
    return step;
}

// ---------------------------------------------------------------------------
// Players

on_connect( player, arg )
{
    if ( !custom_scripts\ix\core\util::is_valid_player( player ) || !isdefined( player.ix ) )
        return;

    state = spawnstruct();
    state.marked = [];
    state.view = undefined;
    state.extra = 0;
    state.notified = undefined;
    player.ix.guided = state;
    player thread custom_scripts\ix\guided\panel::run();
}

on_mode_changed( value, old_value, id )
{
    if ( !isdefined( level.players ) )
        return;

    foreach ( player in level.players )
    {
        if ( !custom_scripts\ix\core\util::is_valid_player( player ) )
            continue;

        if ( value )
            player iprintln( "Guided Mode on: the quest's objective is at the side of the screen." );
        else
            player iprintln( "Guided Mode off." );
    }
}

// A setting of how the tracker looks: the panels place themselves again.
on_view_changed( value, old_value, id )
{
    level.ix.guided.layout++;
}

// The step this player looks at: the current one, unless they browse.
viewed_index()
{
    current = custom_scripts\ix\guided\tracker::current_index( self );

    if ( !isdefined( self.ix.guided.view ) )
        return current;

    return self.ix.guided.view;
}

// The hint level for this player's view: the setting, raised by Reveal more.
hint_level()
{
    switch ( custom_scripts\ix\core\config::get( "guided_hints" ) )
    {
        case "minimal":
            rank = 0;
            break;
        case "standard":
            rank = 1;
            break;
        default:
            rank = 2;
            break;
    }

    return int( min( 2, rank + self.ix.guided.extra ) );
}

full_walkthrough()
{
    return custom_scripts\ix\core\config::get( "guided_hints" ) == "full";
}

// ---------------------------------------------------------------------------
// Menu: Guided Mode page (menu_tree.gsc)

guide_info()
{
    if ( !level.ix.guided.loaded )
        return "...";

    if ( !has_guide() )
        return "None yet";

    return "Ready";
}

progress_info()
{
    if ( !has_guide() )
        return 0;

    return custom_scripts\ix\guided\tracker::done_count( self );
}

steps_info()
{
    if ( !has_guide() )
        return 0;

    return guide().steps.size;
}

// Full guide: a step's state, and its help line.
step_state_info( index )
{
    current = custom_scripts\ix\guided\tracker::current_index( self );

    if ( custom_scripts\ix\guided\tracker::is_done( index, self ) )
        return "Done";

    if ( index == current )
        return "Now";

    return "";
}

step_help( index )
{
    step = guide().steps[index];
    current = custom_scripts\ix\guided\tracker::current_index( self );

    if ( index > current && !full_walkthrough() && !custom_scripts\ix\guided\tracker::is_done( index, self ) )
        return "Ahead. Guided: hints full shows every step.";

    return step.objective + ". " + step.location + ". " + step.hints[0];
}

previous_action()
{
    if ( !guide_ready() )
        return;

    view = viewed_index();

    if ( view <= 0 )
    {
        self iprintln( "This is the first step." );
        return;
    }

    show_view( view - 1 );
}

next_action()
{
    if ( !guide_ready() )
        return;

    view = viewed_index();
    current = custom_scripts\ix\guided\tracker::current_index( self );

    if ( view + 1 >= guide().steps.size )
    {
        self iprintln( "This is the last step." );
        return;
    }

    if ( view + 1 > current && !full_walkthrough() )
    {
        self iprintln( "The next steps show with Guided: hints full." );
        show_view( current );
        return;
    }

    show_view( view + 1 );
}

show_view( index )
{
    current = custom_scripts\ix\guided\tracker::current_index( self );

    if ( index == current )
        self.ix.guided.view = undefined;
    else
        self.ix.guided.view = index;

    self.ix.guided.extra = 0;
    self iprintln( "Step " + ( index + 1 ) + ": " + guide().steps[index].objective );
}

more_action()
{
    if ( !guide_ready() )
        return;

    if ( hint_level() >= 2 )
    {
        self iprintln( "The guide already shows everything it has for this step." );
        return;
    }

    self.ix.guided.extra++;
    self iprintln( "More of the hint for this step." );
}

// Marks the step the player looks at done (shared or personal, guided_coop).
mark_action()
{
    if ( !guide_ready() )
        return;

    index = viewed_index();

    if ( index >= guide().steps.size )
    {
        self iprintln( "The quest is complete." );
        return;
    }

    shared = custom_scripts\ix\core\config::get( "guided_coop" ) == "shared";

    if ( shared && !self custom_scripts\ix\ui\menu::may_change() )
    {
        self iprintln( "Only the host marks steps for everyone (Guided: co-op shared)." );
        return;
    }

    custom_scripts\ix\guided\tracker::mark( index, self, shared );
    self.ix.guided.view = undefined;
    self.ix.guided.extra = 0;
}

clear_marks_action()
{
    if ( !guide_ready() )
        return;

    shared = custom_scripts\ix\core\config::get( "guided_coop" ) == "shared";

    if ( shared && !self custom_scripts\ix\ui\menu::may_change() )
    {
        self iprintln( "Only the host clears the marks for everyone (Guided: co-op shared)." );
        return;
    }

    count = custom_scripts\ix\guided\tracker::clear_marks( self, shared );
    self iprintln( count + " steps marked by hand are open again. Steps the game reports stay done." );
}

guide_ready()
{
    if ( !is_on() )
    {
        self iprintln( "Switch Guided Mode on first." );
        return 0;
    }

    if ( !has_guide() )
    {
        self iprintln( "Guided Mode is unavailable: no verified guide for this map yet." );
        return 0;
    }

    return 1;
}

// ---------------------------------------------------------------------------
// Chat: "!ix guide [next | prev | more | done]" (chat.gsc runs it on the player)

guide_command( words )
{
    if ( words.size > 2 )
    {
        switch ( tolower( words[2] ) )
        {
            case "next":
                next_action();
                return;
            case "prev":
            case "previous":
                previous_action();
                return;
            case "more":
                more_action();
                return;
            case "done":
                mark_action();
                return;
        }
    }

    if ( !has_guide() )
    {
        self tell( "Guided Mode: no verified guide for this map yet." );
        return;
    }

    index = viewed_index();

    if ( index >= guide().steps.size )
    {
        self tell( guide().quest + ": complete." );
        return;
    }

    step = guide().steps[index];
    lines = [];
    lines[0] = guide().quest + ", step " + ( index + 1 ) + " of " + guide().steps.size + ": " + step.objective + " (" + step.location + ")";
    lines[1] = step.hints[hint_level()];

    if ( !is_on() )
        lines[2] = "Guided Mode is off; " + custom_scripts\ix\core\chat::prefix() + " on guided_mode shows it on screen.";

    custom_scripts\ix\core\chat::tell_lines( self, lines );
}
