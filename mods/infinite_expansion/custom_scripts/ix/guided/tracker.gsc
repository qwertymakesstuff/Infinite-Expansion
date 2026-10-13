// Infinite Expansion - Guided Mode: which step the quest is at (Phase 13).
//
// A step is done when the game says so (its "detect" in the guide: a flag the
// quest scripts set, a notify they send, or the guide's own check), or when
// players mark it done by hand. Evidence counts backwards: once the game
// reports a later step, every step before it is done too (the quest cannot
// get there otherwise). Nothing is assumed: a step without a signal stays
// open until someone marks it.
//
// The quest is the game's, so what the game reports is the same for every
// player (all scripts run on the host). Steps marked by hand are for everyone
// (guided_coop shared) or for that player only (personal).
//
// The game is asked twice a second while Guided Mode is on; notifies are
// caught from the moment the guide loads (a notify sent before then, for a
// step done before Guided Mode was on, is missed: that step is marked by hand
// or follows from a later one).

start( guide )
{
    level.ix.guided.reached = -1;

    foreach ( step in guide.steps )
    {
        if ( custom_scripts\ix\core\util::starts_with( step.detect, "notify:" ) )
            level thread watch_notify( step, getsubstr( step.detect, 7, step.detect.size ) );

        // "count:<notify>*<n>": done after n of them, as a stock script
        // counts them itself (the five power switches, three defenses).
        if ( custom_scripts\ix\core\util::starts_with( step.detect, "count:" ) )
        {
            parts = strtok( getsubstr( step.detect, 6, step.detect.size ), "*" );
            step.total = int( parts[1] );
            step.ix_count = 0;
            level thread watch_count( step, parts[0] );
        }
    }

    level thread track( guide );
}

watch_notify( step, name )
{
    level endon( "game_ended" );
    level waittill( name );
    step.seen = 1;
}

watch_count( step, name )
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( name );
        step.ix_count++;
    }
}

// How far into a step the game is, as " (2/3)", or "" when the step has no
// count (count: steps, and guide steps with a progress function and total).
progress_text( step )
{
    if ( !isdefined( step.total ) )
        return "";

    done = 0;

    if ( isdefined( step.ix_count ) )
        done = step.ix_count;
    else if ( isdefined( step.progress ) )
        done = [[ step.progress ]]();

    return " (" + int( min( done, step.total ) ) + "/" + step.total + ")";
}

// While Guided Mode is on: the furthest step the game reports.
track( guide )
{
    level endon( "game_ended" );

    for (;;)
    {
        if ( !custom_scripts\ix\core\config::get( "guided_mode" ) )
        {
            custom_scripts\ix\core\config::wait_for_change();
            continue;
        }

        for ( i = guide.steps.size - 1; i > level.ix.guided.reached; i-- )
        {
            step = guide.steps[i];

            if ( step.auto || detected( step ) )
            {
                step.auto = 1;
                level.ix.guided.reached = i;
                custom_scripts\ix\core\log::info( "guided: the game reports step " + ( i + 1 ) + " (" + step.id + ") done" );
                break;
            }
        }

        wait 0.5;
    }
}

detected( step )
{
    detect = step.detect;

    if ( custom_scripts\ix\core\util::starts_with( detect, "flag:" ) )
        return flag_set_by_game( getsubstr( detect, 5, detect.size ) );

    if ( custom_scripts\ix\core\util::starts_with( detect, "flags:" ) )
    {
        foreach ( name in strtok( getsubstr( detect, 6, detect.size ), "+" ) )
        {
            if ( !flag_set_by_game( name ) )
                return 0;
        }

        return 1;
    }

    if ( custom_scripts\ix\core\util::starts_with( detect, "notify:" ) )
        return step.seen;

    if ( custom_scripts\ix\core\util::starts_with( detect, "count:" ) )
        return step.ix_count >= step.total;

    if ( detect == "check" && isdefined( step.check ) )
        return [[ step.check ]]();

    return 0;
}

flag_set_by_game( name )
{
    return scripts\engine\utility::flag_exist( name ) && scripts\engine\utility::flag( name );
}

// ---------------------------------------------------------------------------
// For a player

is_done( index, player )
{
    if ( index <= level.ix.guided.reached )
        return 1;

    step = level.ix.guided.guide.steps[index];

    if ( step.marked )
        return 1;

    return isdefined( player ) && isdefined( player.ix ) && isdefined( player.ix.guided ) && isdefined( player.ix.guided.marked[step.id] );
}

// The first step not done for this player; steps.size once all are.
current_index( player )
{
    steps = level.ix.guided.guide.steps;

    for ( i = level.ix.guided.reached + 1; i < steps.size; i++ )
    {
        if ( !is_done( i, player ) )
            return i;
    }

    return steps.size;
}

done_count( player )
{
    count = 0;

    for ( i = 0; i < level.ix.guided.guide.steps.size; i++ )
    {
        if ( is_done( i, player ) )
            count++;
    }

    return count;
}

// Marked done by hand: for everyone, or for this player only.
mark( index, player, shared )
{
    step = level.ix.guided.guide.steps[index];

    if ( shared )
        step.marked = 1;
    else
        player.ix.guided.marked[step.id] = 1;

    custom_scripts\ix\core\log::info( "guided: step " + ( index + 1 ) + " (" + step.id + ") marked done by " + player.name );
}

// Opens the steps marked by hand again; returns how many.
clear_marks( player, shared )
{
    count = 0;

    if ( shared )
    {
        foreach ( step in level.ix.guided.guide.steps )
        {
            if ( step.marked )
            {
                step.marked = 0;
                count++;
            }
        }
    }
    else
    {
        count = player.ix.guided.marked.size;
        player.ix.guided.marked = [];
    }

    return count;
}
