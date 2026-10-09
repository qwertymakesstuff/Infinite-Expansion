// Infinite Expansion - points multiplier and power-ups per round (Phase 7).
//
// What the stock zombies scripts do (IW_API_NOTES.md section 20):
//   - points: every kill and hit reward is multiplied by level.cash_scalar
//     (scripts\cp\agents\gametype_zombie.gsc givekillreward and the hit
//     reward; also the Nuke's 400, window repairs and the challenge rewards).
//     The game keeps it at 1 and the Double Money power-up sets 2 for 30 s
//     (scripts\cp\loot.gsc), marking it in level.active_power_ups. While
//     points_multiplier is not 100 the mod sets the game's value times its
//     own four times a second, so Double Money still doubles; back at 100 it
//     puts the game's value back.
//   - power-ups: a kill drops one when the team's points pass a threshold,
//     at most level.powerup_drop_max_per_round times a round (5; the count
//     starts again when a round ends). The mod sets that number. Power-ups
//     the game hands out otherwise (an event round's last zombie, cards,
//     quests) are not counted.
//
// Settings:
//   points_multiplier  100  percent of the points kills and hits give (0-1000)
//   powerup_limit      5    most power-ups that drop from kills in a round (0-20)

register()
{
    custom_scripts\ix\core\config::add_int( "points_multiplier", 100, 0, 1000, "Points multiplier", "Percent of the points kills and hits give. Double Money still doubles them.", undefined );
    custom_scripts\ix\core\config::add_int( "powerup_limit", 5, 0, 20, "Power-ups per round", "Most power-ups zombies drop in a round. 5 is the game's own; 0: none from kills.", ::on_powerups_changed );

    custom_scripts\ix\zombies\zombies::on_ready( ::apply_powerups );
    level thread keep_points_multiplier();
}

// ---------------------------------------------------------------------------
// Points

// The game's own multiplier: 2 during Double Money, else 1.
game_multiplier()
{
    if ( isdefined( level.active_power_ups ) && isdefined( level.active_power_ups["double_money"] ) && level.active_power_ups["double_money"] )
        return 2;

    return 1;
}

keep_points_multiplier()
{
    level endon( "game_ended" );
    changed = 0;

    for (;;)
    {
        wait 0.25;
        percent = custom_scripts\ix\core\config::get( "points_multiplier" );

        if ( percent == 100 )
        {
            if ( changed )
            {
                level.cash_scalar = game_multiplier();
                changed = 0;
            }

            continue;
        }

        wanted = game_multiplier() * percent / 100.0;

        if ( !isdefined( level.cash_scalar ) || level.cash_scalar != wanted )
            level.cash_scalar = wanted;

        changed = 1;
    }
}

// ---------------------------------------------------------------------------
// Power-ups

on_powerups_changed( value, old_value, id )
{
    if ( custom_scripts\ix\zombies\zombies::is_ready() )
        apply_powerups();
}

apply_powerups()
{
    level.powerup_drop_max_per_round = custom_scripts\ix\core\config::get( "powerup_limit" );
}
