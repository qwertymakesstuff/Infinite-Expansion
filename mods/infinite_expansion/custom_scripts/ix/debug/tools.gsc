// Infinite Expansion - developer tools (Phase 10): the Debug page's actions.
//
// Every tool that changes the match is locked until the host switches
// dev_tools on, host only, and asks for a second Use (menu_tree.gsc
// add_dev_action). What the stock zombies scripts do, and what the tools use
// (IW_API_NOTES.md section 20):
//   - Spawning: level.zombies_paused makes the stock spawn loops wait; the
//     zombies already out stay. The game sets and clears it itself (the
//     afterlife arcade in solo, boss fights, quests, a co-op spawn), so while
//     the mod pauses spawning it sets it again twice a second. Resuming clears
//     it, also during a map event that paused spawning (KNOWN_LIMITATIONS.md
//     L52).
//   - Kill all zombies: as the Nuke power-up kills (scripts\cp\loot.gsc
//     kill_closest_enemies): every enemy agent alive except the ones the Nuke
//     spares (bosses, brutes: immune_against_nuke), with damage that has no
//     attacker, so nobody gets points or a power-up, and each kill counts for
//     the round as usual. One a frame.
//   - End this round: the round's kill count set to its goal
//     (level.current_enemy_deaths = level.desired_enemy_deaths_this_wave),
//     then every zombie killed as above, so none is left over for the next
//     round. The stock wave loop sees it within two seconds and moves on as
//     after a normal round. Refused while the map holds the round (the flag
//     "pause_wave_progression", or spawning paused by the game: boss fights,
//     quests), whose end the map's own scripts wait for.
//   - Give points: the stock give_player_currency, as the perk machines'
//     refund ("bonus" points, which do not bring power-ups closer).
//   - Drop a power-up: the stock drop_loot, as the Fate & Fortune cards drop
//     theirs, in front of the player, with the cards' power-up names (each is
//     in every map's power-up table). It does not count toward the round's
//     power-ups.
//   - What you look at: bullettrace from the eye along the view, and the
//     entity's own fields (classname, targetname, model; there are no getter
//     methods for them).

// ---------------------------------------------------------------------------
// Spawning

// "Pause / resume spawning" (a developer tool).
toggle_spawning()
{
    if ( spawning_paused_by_mod() )
    {
        resume_spawning();
        self iprintln( "Zombies spawn again." );
        return;
    }

    level.ix.spawning_paused = 1;
    level.zombies_paused = 1;
    level thread keep_spawning_paused();
    self iprintln( "Zombie spawning paused. The zombies already out stay." );
}

spawning_paused_by_mod()
{
    return isdefined( level.ix.spawning_paused ) && level.ix.spawning_paused;
}

resume_spawning()
{
    if ( !spawning_paused_by_mod() )
        return;

    level.ix.spawning_paused = 0;
    level notify( "ix_spawning_resumed" );
    level.zombies_paused = 0;
}

keep_spawning_paused()
{
    level endon( "game_ended" );
    level endon( "ix_spawning_resumed" );

    for (;;)
    {
        wait 0.5;
        level.zombies_paused = 1;
    }
}

// The Debug page's read-out: "paused" while the mod holds the spawns, "game
// paused" while the game does, else "on".
spawning_state()
{
    if ( spawning_paused_by_mod() )
        return "paused";

    if ( isdefined( level.zombies_paused ) && level.zombies_paused )
        return "game paused";

    return "on";
}

// ---------------------------------------------------------------------------
// Killing zombies

// The enemies a Nuke kills.
nuke_targets()
{
    targets = [];

    if ( !isdefined( level.agentarray ) )
        return targets;

    foreach ( enemy in scripts\cp\cp_agent_utils::getaliveagentsofteam( "axis" ) )
    {
        if ( isdefined( enemy.immune_against_nuke ) && enemy.immune_against_nuke )
            continue;

        targets[targets.size] = enemy;
    }

    return targets;
}

// One a frame, so the game's death handling never piles up.
kill_targets( targets )
{
    level endon( "game_ended" );

    foreach ( enemy in targets )
    {
        if ( isdefined( enemy ) && isalive( enemy ) )
            enemy dodamage( enemy.health + 100, enemy.origin );

        wait 0.05;
    }
}

// "Kill all zombies" (a developer tool).
kill_all()
{
    targets = nuke_targets();
    level thread kill_targets( targets );
    self iprintln( targets.size + " zombies killed. Bosses and brutes are spared, as by a Nuke." );
}

// "End this round" (a developer tool).
end_round()
{
    if ( custom_scripts\ix\zombies\zombies::zombies_left() == 0 )
    {
        self iprintln( "No round is running: wait for the next one to start." );
        return;
    }

    if ( map_holds_round() )
    {
        self iprintln( "Not now: the map is holding this round (a boss fight or a quest)." );
        return;
    }

    resume_spawning();
    level.current_enemy_deaths = level.desired_enemy_deaths_this_wave;
    level thread kill_targets( nuke_targets() );
    self iprintln( "Round " + custom_scripts\ix\zombies\zombies::round_number() + " ends." );
}

// The map's own scripts hold the round: they stop kills from counting, or
// pause spawning themselves.
map_holds_round()
{
    if ( scripts\engine\utility::flag_exist( "pause_wave_progression" ) && scripts\engine\utility::flag( "pause_wave_progression" ) )
        return 1;

    return !spawning_paused_by_mod() && isdefined( level.zombies_paused ) && level.zombies_paused;
}

// ---------------------------------------------------------------------------
// Points and power-ups

// "Give yourself 10,000 points" (a developer tool).
give_points()
{
    self scripts\cp\cp_persistence::give_player_currency( 10000, undefined, undefined, 1, "bonus" );
    self iprintln( "10,000 points added." );
}

drop_powerup( ref, name )
{
    spot = self.origin + anglestoforward( ( 0, self.angles[1], 0 ) ) * 64;

    if ( level scripts\cp\loot::drop_loot( spot, self, ref, undefined, undefined, undefined ) )
        self iprintln( name + " dropped in front of you." );
    else
        self iprintln( "No room for a power-up here: try another spot." );
}

drop_max_ammo()
{
    drop_powerup( "ammo_max", "Max Ammo" );
}

drop_nuke()
{
    drop_powerup( "kill_50", "Nuke" );
}

drop_instakill()
{
    drop_powerup( "instakill_30", "Insta-Kill" );
}

drop_double_money()
{
    drop_powerup( "cash_2", "Double Money" );
}

drop_fire_sale()
{
    drop_powerup( "fire_30", "Fire Sale" );
}

drop_carpenter()
{
    drop_powerup( "board_windows", "Carpenter" );
}

drop_infinite_ammo()
{
    drop_powerup( "infinite_20", "Infinite Ammo" );
}

// ---------------------------------------------------------------------------
// What you look at (not locked: it only reads)

look_info()
{
    eye = self geteye();
    forward = anglestoforward( self getplayerangles() );
    trace = bullettrace( eye, eye + forward * 8000, 1, self );

    if ( trace["fraction"] == 1 )
    {
        self iprintln( "Nothing within 8000 units." );
        return;
    }

    away = int( distance( eye, trace["position"] ) );
    entity = trace["entity"];

    if ( !isdefined( entity ) )
    {
        self iprintln( "The map (" + trace["surfacetype"] + "), " + away + " units away." );
        return;
    }

    text = "Entity " + entity getentitynumber();

    if ( isdefined( entity.classname ) )
        text += ", " + entity.classname;

    if ( isdefined( entity.agent_type ) )
        text += ", agent " + entity.agent_type;

    if ( isdefined( entity.targetname ) )
        text += ", targetname " + entity.targetname;

    if ( isdefined( entity.model ) && entity.model != "" )
        text += ", model " + entity.model;

    if ( isdefined( entity.health ) && entity.health > 0 )
        text += ", health " + entity.health;

    self iprintln( text + ", " + away + " units away." );
}
