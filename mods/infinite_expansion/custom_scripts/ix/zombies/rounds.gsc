// Infinite Expansion - the round a match starts at (Phase 7).
//
// The stock wave loop (scripts\cp\zombies\zombies_spawning.gsc) starts 15 s
// after the intro and plays whatever level.wave_num holds: 0 at first (a pass
// without zombies), then 1, 2, ... Stock scripts start later rounds the same
// way (Spaceland's boss-fight-only mode sets 28, Shaolin Shuffle's 30). Once
// the spawner is set up, well before that first pass, the mod sets
// level.wave_num to start_round, once per match, and level.last_event_wave
// with it, so a special round does not come at once (the stock event check
// counts the rounds since the last one). The round's zombies, their health and
// their speed follow from the round number, as in the game.
//
// Side effects (KNOWN_LIMITATIONS.md L53): a later start counts toward the
// players' highest round (career stats, merits), and the prize restock of
// every tenth round only comes when the match starts below round 10. Not in
// the boss-fight-only mode, which sets its own round.
//
// Settings:
//   start_round  1  the round a match starts at (1-100); from the next match

register()
{
    custom_scripts\ix\core\config::add_int( "start_round", 1, 1, 100, "Starting round", "The round the next match starts at. It counts toward your highest round.", undefined );
    custom_scripts\ix\zombies\zombies::on_ready( ::apply );
}

// At the spawner's setup, and at every round start (when it does nothing).
apply()
{
    if ( isdefined( level.ix.zombies.start_round_done ) )
        return;

    level.ix.zombies.start_round_done = 1;
    start = custom_scripts\ix\core\config::get( "start_round" );

    if ( start <= 1 )
        return;

    // Already under way (a round has started), or the boss-fight-only mode.
    if ( !isdefined( level.wave_num ) || level.wave_num != 0 || ( isdefined( level.direct_to_boss_fight ) && level.direct_to_boss_fight ) )
    {
        custom_scripts\ix\core\log::info( "zombies: start_round " + start + " not applied: the match is already under way or has its own round" );
        return;
    }

    level.wave_num = start;
    level.last_event_wave = start;
    custom_scripts\ix\core\log::info( "zombies: the match starts at round " + start );
}
