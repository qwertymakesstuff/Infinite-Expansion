// Infinite Expansion - custom emotes: your own animations on a stand-in body.
//
// IW7 animates a player's body through its animation state machine, which no
// script can drive and x64-zt cannot build (KNOWN_LIMITATIONS.md L13). So a
// custom emote is played on a copy of the player instead (IW_API_NOTES.md
// section 24):
//   - the player is hidden (playerhide, as the stock fast travel does) and
//     held where they stand (a tag_origin anchor and playerlinktodelta, as
//     the menu holds them), with weapons, grenades, melee and Use off;
//   - a script_model takes their body (the model field) and every model
//     attached to it (head, hair), read the way the stock
//     scripts\code\character.gsc save() copies a character and attached
//     the way zombies_loadout.gsc dresses a player: attach( part, "", 1 );
//   - the animation plays on it with scriptmodelplayanim, as the stock
//     scripts play their character animations (cp_zmb_dj.gsc on the DJ,
//     cp_rave_boat.gsc on Kevin Smith), each one precached with
//     precachempanim while the level loads, as cp_zmb.gsc precache() does;
//   - the camera goes behind the player (emotes.gsc), so they see it.
// Everything is put back on every way out (stop(), called by emotes.gsc
// restore()): the end of the animation, moving or pressing Melee or Use,
// a zombie coming close, damage (emote_cancel_damage), going down, dying, the
// game taking the player, the match ending, or the player leaving.
//
// The animations come from iw7-mod/zone/ix_emotes.ff, which "Build Custom
// Emotes" makes on the player's PC (installer/IXEmotes.Core.ps1). The menu
// script loads it with loadzone and passes its list on in dvars:
//   ix_emotes_zone   1 when it asked the game to load the zone
//   ix_emote_count   how many entries
//   ix_emote_<n>     "id|animation|seconds|loop|category|wheel name|menu name",
//                    names with "_" for each space
// Only the host's list counts (the scripts run on the host); every player
// needs the same zone for the animation to exist in their game (L67).
//
// Setting:
//   emote_custom  1  custom emotes on; read when a map loads (precaching
//                    must happen then), also checked before each one

register()
{
    custom_scripts\ix\core\config::add_bool( "emote_custom", 1, "Emote: custom emotes", "Your animations from Build Custom Emotes (Custom category). Others need the same pack. Applies at the next map.", undefined );
    level.ix.emotes.custom = [];

    if ( !custom_scripts\ix\core\config::get( "emote_custom" ) )
    {
        custom_scripts\ix\core\log::info( "emotes: custom emotes off" );
        return;
    }

    if ( getdvar( "ix_emotes_zone" ) != "1" )
        return;

    count = getdvar( "ix_emote_count" );

    if ( !custom_scripts\ix\core\util::is_number( count, 0 ) )
        return;

    count = int( min( int( count ), max_count() ) );
    ids = [];

    for ( i = 1; i <= count; i++ )
    {
        text = getdvar( "ix_emote_" + i );
        emote = parse( text );

        if ( !isdefined( emote ) || isdefined( ids[emote.id] ) )
        {
            custom_scripts\ix\core\log::warn( "emotes: custom entry " + i + " skipped: " + text );
            continue;
        }

        // Must happen while the level loads, before any wait.
        precachempanim( emote.asset );
        ids[emote.id] = 1;
        level.ix.emotes.custom[level.ix.emotes.custom.size] = emote;
    }

    custom_scripts\ix\core\log::info( "emotes: " + level.ix.emotes.custom.size + " custom from ix_emotes" );
}

max_count()
{
    return 20;
}

list()
{
    return level.ix.emotes.custom;
}

// One entry of the menu script's list, checked again here: the dvars can be
// typed in the console too.
parse( text )
{
    fields = strtok( text, "|" );

    if ( fields.size != 7 )
        return undefined;

    id = fields[0];
    asset = fields[1];
    seconds = fields[2];
    loop = fields[3];

    if ( id.size < 2 || id.size > 6 || !custom_scripts\ix\core\util::starts_with( id, "u" ) || !only( id, "abcdefghijklmnopqrstuvwxyz0123456789" ) )
        return undefined;

    if ( asset.size > 48 || !custom_scripts\ix\core\util::starts_with( asset, "ix_emote_" ) || !only( asset, "abcdefghijklmnopqrstuvwxyz0123456789_" ) )
        return undefined;

    if ( !custom_scripts\ix\core\util::is_number( seconds, 1 ) || ( loop != "0" && loop != "1" ) )
        return undefined;

    category = words( fields[4], 16 );
    wheel = words( fields[5], 14 );
    name = words( fields[6], 27 );

    if ( !isdefined( category ) || !isdefined( wheel ) || !isdefined( name ) )
        return undefined;

    if ( !custom_scripts\ix\core\util::array_contains( custom_scripts\ix\fun\emote_data::categories(), category ) )
        category = "Custom";

    emote = custom_scripts\ix\fun\emote_data::new_emote( id, name, wheel, category, "custom", asset, "Your own animation, played on a copy of your character with the camera behind you. Move to stop it." );
    emote.seconds = clamp( float( seconds ), 0.5, 60 );
    emote.loop = loop == "1";
    return emote;
}

// A name as the menu script passes it: letters, digits, "." and "-", with
// "_" for each space. Returns it with its spaces, or undefined.
words( text, longest )
{
    if ( text.size > longest || !only( text, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-" ) )
        return undefined;

    result = "";

    for ( i = 0; i < text.size; i++ )
    {
        c = getsubstr( text, i, i + 1 );

        if ( c == "_" )
            c = " ";

        result += c;
    }

    return result;
}

only( text, allowed )
{
    for ( i = 0; i < text.size; i++ )
    {
        if ( !issubstr( allowed, getsubstr( text, i, i + 1 ) ) )
            return 0;
    }

    return 1;
}

// What stops a custom emote from starting, beyond emotes.gsc cannot_emote().
cannot_play()
{
    if ( !custom_scripts\ix\core\config::get( "emote_custom" ) )
        return "Custom emotes are off (Emote settings).";

    if ( !isdefined( self.model ) || self.model == "" )
        return "Your character has no body to copy yet.";

    return "";
}

// Hides and holds the player and puts the stand-in in their place, playing
// the animation. Never waits, so nothing can end the emote halfway through.
start( emote )
{
    state = self.ix.emote;
    self hold();

    self scripts\engine\utility::allow_weapon( 0 );
    self scripts\engine\utility::allow_offhand_weapons( 0 );
    self scripts\engine\utility::allow_melee( 0 );
    self scripts\engine\utility::allow_usability( 0 );
    state.held = 1;

    standin = spawn( "script_model", self.origin );
    standin.angles = ( 0, self.angles[1], 0 );
    standin setmodel( self.model );
    count = self getattachsize();

    // Each part as the game dresses a character: with no tag, so the part
    // follows the body's own bones (zombies_loadout.gsc setcharactermodels,
    // cp_agent_utils.gsc set_agent_model: attach( part, "", 1 )). Attached to
    // the tag the game reports instead, the head stayed put while the body
    // moved, and vanished once the animation started (second in-game report).
    parts = [];

    for ( i = 0; i < count; i++ )
    {
        model = self getattachmodelname( i );

        if ( isdefined( model ) && model != "" )
        {
            standin attach( model, "", 1 );
            parts[parts.size] = model;
        }
    }

    // The head by the stock field setcharactermodels fills (headmodel, a
    // token in v1.1.0's table), when the attachment list did not give it
    // (third in-game report: the copy had no head).
    if ( isdefined( self.headmodel ) && self.headmodel != "" && !custom_scripts\ix\core\util::array_contains( parts, self.headmodel ) )
    {
        standin attach( self.headmodel, "", 1 );
        parts[parts.size] = self.headmodel + " (headmodel)";
    }

    custom_scripts\ix\core\log::debug( "emotes: copy of " + self.name + ": body " + self.model + ", " + count + " attached, parts: " + custom_scripts\ix\core\util::join( parts, ", " ) );

    state.standin = standin;
    self playerhide();
    state.hidden = 1;
    level thread clean_up_if_gone( self, undefined, standin );
    standin scriptmodelplayanim( emote.asset, 1 );
}

// Holds the player where they stand, as the menu does (menu.gsc hold): a
// tag_origin anchor at their feet and playerlinktodelta with the view free,
// so the camera behind them can go all the way round. Every emote does this
// (emotes.gsc run); release() lets go.
hold()
{
    state = self.ix.emote;
    anchor = spawn( "script_model", self.origin );
    anchor setmodel( "tag_origin" );
    anchor.angles = ( 0, self.angles[1], 0 );
    self playerlinktodelta( anchor, "tag_origin", 1, 180, 180, 85, 85 );
    state.anchor = anchor;
    level thread clean_up_if_gone( self, anchor, undefined );
}

release()
{
    state = self.ix.emote;

    if ( !isdefined( state.anchor ) )
        return;

    if ( self islinked() && self getlinkedparent() == state.anchor )
        self unlink();

    state.anchor delete();
    state.anchor = undefined;
}

// A held stock emote (emotes.gsc run): until its time is up, the player moves
// or presses Melee or Use, a zombie comes close, or the game takes the player.
hold_until( seconds )
{
    state = self.ix.emote;
    armed = 0;

    for ( waited = 0; waited < seconds; waited += 0.05 )
    {
        wait 0.05;

        if ( !self islinked() || self getlinkedparent() != state.anchor )
            return;

        if ( self custom_scripts\ix\fun\emotes::zombie_near( 120 ) )
            return;

        if ( !wants_out() )
            armed = 1;
        else if ( armed )
            return;
    }
}

// Until the animation ends (a looping one: until stopped). A key or button
// held when it starts (the menu's Use) only counts once it was let go.
play_until_done( emote )
{
    state = self.ix.emote;
    armed = 0;
    played = 0;

    for (;;)
    {
        wait 0.05;
        played += 0.05;

        if ( played >= emote.seconds )
        {
            if ( !emote.loop )
                return;

            // Again from the start, as cp_rave_boat.gsc loops its idle.
            state.standin scriptmodelplayanim( emote.asset, 1 );
            played = 0;
        }

        if ( !self islinked() || self getlinkedparent() != state.anchor )
            return;

        if ( self custom_scripts\ix\fun\emotes::zombie_near( 120 ) )
            return;

        if ( !wants_out() )
            armed = 1;
        else if ( armed )
            return;
    }
}

// Moving, Melee or Use: the player wants to go.
wants_out()
{
    move = self getnormalizedmovement();

    if ( abs( move[0] ) > 0.5 || abs( move[1] ) > 0.5 )
        return 1;

    return self meleebuttonpressed() || self usebuttonpressed();
}

// Puts everything back that start() changed; safe to call more than once,
// and after a start() that did not get far.
stop()
{
    state = self.ix.emote;

    if ( isdefined( state.standin ) )
    {
        state.standin delete();
        state.standin = undefined;
    }

    if ( isdefined( state.hidden ) && state.hidden )
    {
        self playershow();
        state.hidden = 0;
    }

    self release();

    if ( isdefined( state.held ) && state.held )
    {
        self scripts\engine\utility::allow_weapon( 1 );
        self scripts\engine\utility::allow_offhand_weapons( 1 );
        self scripts\engine\utility::allow_melee( 1 );
        self scripts\engine\utility::allow_usability( 1 );
        state.held = 0;
    }
}

// The match ending also ends an emote (emotes.gsc runs this on the player).
end_on_game_end()
{
    self endon( "disconnect" );
    self endon( "ix_emote_end" );
    level waittill( "game_ended" );
    self notify( "ix_emote_end" );
}

// A player who leaves mid-emote takes nothing of theirs along: their own
// threads end with them, so the level removes the anchor and the stand-in.
clean_up_if_gone( player, anchor, standin )
{
    player endon( "ix_emote_end" );
    player waittill( "disconnect" );

    if ( isdefined( standin ) )
        standin delete();

    if ( isdefined( anchor ) )
        anchor delete();
}
