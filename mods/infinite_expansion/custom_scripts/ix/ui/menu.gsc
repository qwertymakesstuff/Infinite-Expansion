// Infinite Expansion - in-game menu.
//
// A HUD menu each player opens in a match (ARCHITECTURE.md section 5). Its
// pages are data (menu_tree.gsc); a row is a page link, a setting, an action or
// a read-out. A setting row takes its label, help, range and current value
// from config.gsc, so the console, the chat commands and the menu always show
// and change the same thing.
//
// Controls (IW_API_NOTES.md section 8), listed in small text at the bottom of
// the menu:
//   ADS + Melee                    open (menu_open; "!ix menu" in chat always)
//   W / S, left stick up / down    move up / down (ADS / Fire too)
//   A / D, left stick left / right change a value: less / more (Tactical / Frag too)
//   Use or Jump                    open a page, switch, run an action
//   Melee                          back; on the first page: close
// The movement keys are read with getnormalizedmovement() while the player is
// held in place, linked to a point where they stand, as the stock phone booth
// on Shaolin Shuffle reads them (its player is linked too). The buttons are
// polled as a working IW7 zombies menu does; Jump arrives as a "+goStand"
// command notify, as in the phone booth, and so does every Melee press
// ("+melee_zoom", the melee command the stock zombies scripts listen to), so
// a tap between two polls still opens the menu. While the menu is open, the player's
// weapons, grenades, melee and Use are off, so those buttons only steer the
// menu. That goes through the stock counters (scripts\engine\utility::
// allow_weapon and friends), so closing the menu never turns back on what the
// game itself turned off (last stand, traps).
//
// Settings apply to the whole match: only the host changes them, unless the
// host sets menu_access to everyone. Everyone can look.
//
// The HUD elements are made once, on the first opening, and then only change
// their text, values and alpha (KNOWN_LIMITATIONS.md L12). A player sees only
// so many HUD elements that are not "archived" (about 28 in IW7 zombies, the
// number a working IW7 menu keeps to; L49), so the menu has 26 of them and 2
// archived ones, and the stock game's own elements still fit.
//
// Opening (menu_open): ads_melee opens it on Melee while ADS is held or the
// player is aiming (playerads, so toggle ADS works too); crouch_melee on Melee
// after a moment crouched, not sliding (a slide ends crouched); chat leaves
// only "!ix menu". In the air it opens on landing, within a second; when it
// cannot open (down, on a ride, ...), a line says why. At the start of every
// round, a player who has not opened the menu yet in this match is told how,
// in the middle of the screen.
//
// Settings:
//   menu         1          feature: the menu; 0 closes it for everyone
//   menu_access  host       host: only the host changes settings; everyone: all players
//   menu_open    ads_melee  ads_melee / crouch_melee / chat: how it opens
//   menu_hint    1          at each round's start, how to open it, until opened

register()
{
    feature = custom_scripts\ix\core\features::add( "menu", "ui", "In-game menu", "Opens with the keys of Menu: open with, or !ix menu in chat.", 1 );
    feature.on_player = ::apply_menu;
    custom_scripts\ix\core\config::add_enum( "menu_access", "host", "host everyone", "Menu: who changes settings", "host: only the host. everyone: every player in the match.", undefined );
    custom_scripts\ix\core\config::add_enum( "menu_open", "ads_melee", "ads_melee crouch_melee chat", "Menu: open with", "Hold ADS, then Melee; or crouch, then Melee; or only !ix menu in chat.", ::on_open_changed );
    custom_scripts\ix\core\config::add_bool( "menu_hint", 1, "Menu: hint", "At the start of each round, how to open the menu, until you have opened it.", undefined );
    custom_scripts\ix\core\events::subscribe( "player_spawn", ::on_spawn );
    custom_scripts\ix\core\events::subscribe( "round_start", ::on_round_start );
    custom_scripts\ix\core\events::subscribe( "player_laststand", ::on_down );
    custom_scripts\ix\core\events::subscribe( "player_death", ::on_down );
    custom_scripts\ix\core\events::subscribe( "game_end", ::on_game_end );
    custom_scripts\ix\core\events::subscribe( "player_disconnect", ::on_disconnect );
    custom_scripts\ix\core\chat::add_command( "menu", ::chat_open, "opens the menu" );

    level.ix.menu = spawnstruct();
    level.ix.menu.pages = [];
    level.ix.menu.built = 0;
    level thread watch_settings();
}

// ---------------------------------------------------------------------------
// The tree: pages and their rows. menu_tree.gsc fills it on the first opening,
// when every module has registered its settings.

add_page( id, title, parent )
{
    page = spawnstruct();
    page.id = id;
    page.title = title;
    page.parent = parent;
    page.items = [];
    level.ix.menu.pages[id] = page;

    if ( isdefined( parent ) )
    {
        link = new_item( "page", title, "" );
        link.target = id;
        add_item( parent, link );
    }

    return page;
}

// A setting row; step: how much A / D change a number.
add_setting( page, id, step )
{
    setting = custom_scripts\ix\core\config::find( id );

    if ( !isdefined( setting ) )
        return undefined;

    item = new_item( "setting", setting.label, setting.help );
    item.setting = setting.id;
    item.step = step;
    add_item( page, item );
    return item;
}

// An action row: fn runs on the player; confirm: Use twice.
add_action( page, label, help, fn, confirm, host_only )
{
    item = new_item( "action", label, help );
    item.fn = fn;
    item.confirm = confirm;
    item.host_only = host_only;
    add_item( page, item );
    return item;
}

// A read-out: fn returns the value to show (a number or a short word).
add_info( page, label, help, fn )
{
    item = new_item( "info", label, help );
    item.fn = fn;
    add_item( page, item );
    return item;
}

new_item( kind, label, help )
{
    item = spawnstruct();
    item.kind = kind;
    item.label = label;
    item.help = help;
    return item;
}

add_item( page_id, item )
{
    page = level.ix.menu.pages[page_id];

    if ( !isdefined( page ) )
    {
        custom_scripts\ix\core\log::warn( "menu: no page '" + page_id + "' for '" + item.label + "'" );
        return;
    }

    page.items[page.items.size] = item;
}

build_tree()
{
    if ( level.ix.menu.built )
        return;

    level.ix.menu.built = 1;
    custom_scripts\ix\ui\menu_tree::build();

    // A page without rows is left out of its parent.
    foreach ( page in level.ix.menu.pages )
    {
        kept = [];

        foreach ( item in page.items )
        {
            if ( item.kind == "page" && level.ix.menu.pages[item.target].items.size == 0 )
                continue;

            kept[kept.size] = item;
        }

        page.items = kept;
    }
}

// ---------------------------------------------------------------------------
// Players

on_spawn( player )
{
    if ( !custom_scripts\ix\core\util::is_valid_player( player ) || !isdefined( player.ix ) )
        return;

    if ( !isdefined( player.ix.menu ) )
    {
        state = spawnstruct();
        state.open = 0;
        state.locked = 0;
        state.stack = [];
        state.opened = 0;
        player.ix.menu = state;
        player notifyonplayercommand( "ix_menu_jump", "+goStand" );
        player notifyonplayercommand( "ix_menu_melee", "+melee_zoom" );
        player notifyonplayercommand( "ix_menu_melee", "+melee_breath" );
        player thread listen_jump();
        player thread listen_melee();
        player thread input_loop();
    }

    // Spawned into a round already running (a late join): the hint now,
    // rather than at the next round's start.
    if ( player.ix.spawn_count == 1 && isdefined( level.wave_num ) && level.wave_num >= 1 )
        player thread hint_after_spawn();
}

hint_after_spawn()
{
    self endon( "disconnect" );
    wait 6;
    show_hint();
}

// A round started: the hint for everyone who has not opened the menu yet, a
// moment after the game's own round message.
on_round_start( wave )
{
    level endon( "game_ended" );
    wait 3;

    if ( !isdefined( level.players ) )
        return;

    foreach ( player in level.players )
    {
        if ( custom_scripts\ix\core\util::is_valid_player( player ) && isdefined( player.ix ) && isdefined( player.ix.menu ) )
            player show_hint();
    }
}

// How to open the menu, in the middle of the screen (iprintlnbold), until
// this player has opened it in this match; never twice within half a minute.
show_hint()
{
    state = self.ix.menu;

    if ( state.opened || !custom_scripts\ix\core\config::get( "menu_hint" ) || !custom_scripts\ix\core\features::is_enabled( "menu" ) )
        return;

    if ( isdefined( state.hint_time ) && gettime() - state.hint_time < 30000 )
        return;

    state.hint_time = gettime();
    keys = open_words();

    if ( keys == "" )
    {
        self iprintlnbold( "Type !ix menu in chat for the Infinite Expansion menu" );
        return;
    }

    self iprintlnbold( keys + ": Infinite Expansion menu" );
    self iprintln( "Or type !ix menu in chat. The menu lists its keys at the bottom." );
}

// The keys that open the menu, in words; "" when only the chat command does.
open_words()
{
    switch ( custom_scripts\ix\core\config::get( "menu_open" ) )
    {
        case "ads_melee":
            return "ADS + Melee";
        case "crouch_melee":
            return "Crouch + Melee";
    }

    return "";
}

// menu_open changed: everyone hears the new keys, and the round-start hint
// comes back until they have used them.
on_open_changed( value, old_value, id )
{
    if ( !isdefined( level.players ) )
        return;

    keys = open_words();

    foreach ( player in level.players )
    {
        if ( !custom_scripts\ix\core\util::is_valid_player( player ) || !isdefined( player.ix ) || !isdefined( player.ix.menu ) )
            continue;

        player.ix.menu.opened = 0;
        player.ix.menu.hint_time = undefined;

        if ( keys == "" )
            player iprintln( "The Infinite Expansion menu now opens with !ix menu in chat only." );
        else
            player iprintln( "The Infinite Expansion menu now opens with " + keys + "." );
    }
}

// A controller rather than a keyboard and mouse (the stock check; 1 on a console).
uses_gamepad()
{
    if ( !isdefined( level.console ) )
        return 0;

    return self scripts\engine\utility::is_player_gamepad_enabled();
}

// Jump selects: the notify only queues it for the input loop.
listen_jump()
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "ix_menu_jump" );

        if ( self.ix.menu.open )
            self.ix.menu.queued = "use";
    }
}

// Every Melee press, also one too short for the input loop's polls: with the
// open keys held, the input loop opens the menu on its next tick.
listen_melee()
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "ix_menu_melee" );
        state = self.ix.menu;

        if ( !state.open && open_keys_held() )
            state.open_request = gettime();
    }
}

// Left mid-menu: the point they were held at goes too.
on_disconnect( player, arg )
{
    if ( isdefined( player ) && isdefined( player.ix ) && isdefined( player.ix.menu ) && isdefined( player.ix.menu.anchor ) )
        player.ix.menu.anchor delete();
}

// Gone, last stand or dead: the menu closes, and gives back what it took.
on_down( player, arg )
{
    if ( isdefined( player ) && isdefined( player.ix ) && isdefined( player.ix.menu ) && player.ix.menu.open )
        player close_menu();
}

// The match is over: no menu over the end screen.
on_game_end( arg )
{
    if ( !isdefined( level.players ) )
        return;

    foreach ( player in level.players )
        on_down( player, undefined );
}

// The feature switched: off closes the menu.
apply_menu( enabled )
{
    if ( !enabled && isdefined( self.ix ) && isdefined( self.ix.menu ) && self.ix.menu.open )
        self close_menu();
}

chat_open( words )
{
    if ( !isdefined( self.ix ) || !isdefined( self.ix.menu ) || self.ix.menu.open )
        return;

    problem = open_problem();

    if ( problem == "" )
        self open_menu();
    else if ( problem == "-" )
        self tell( "The menu cannot open now." );
    else
        self tell( problem );
}

can_open()
{
    return open_problem() == "";
}

// Why the menu cannot open now: "" when it can; "-" when nothing need be
// said (the menu is off, the match is not ready, the player is not playing).
open_problem()
{
    if ( !level.ix.ready || !custom_scripts\ix\core\features::is_enabled( "menu" ) )
        return "-";

    if ( !isdefined( self.sessionstate ) || self.sessionstate != "playing" )
        return "-";

    if ( isdefined( self.inlaststand ) && self.inlaststand )
        return "The menu cannot open while you are down.";

    if ( isdefined( self.in_afterlife_arcade ) && self.in_afterlife_arcade )
        return "The menu cannot open in the afterlife arcade.";

    // Held in place while it is open: not linked to something already (a
    // ride, a trap) that the hold would take them off, and not in the air.
    if ( self islinked() )
        return "The menu cannot open while the game is moving you.";

    if ( !self isonground() )
        return "The menu opens when you are on the ground.";

    return "";
}

may_change()
{
    return custom_scripts\ix\core\config::get( "menu_access" ) == "everyone" || self ishost();
}

open_menu()
{
    if ( !can_open() )
        return 0;

    build_tree();
    state = self.ix.menu;
    state.open = 1;
    state.opened = 1;
    state.page = "main";
    state.cursor = 0;
    state.top = 0;
    state.stack = [];
    state.confirm = undefined;
    state.queued = undefined;
    lock( 1 );
    hold( 1 );

    if ( !isdefined( state.hud ) )
        create_hud();

    draw();
    return 1;
}

close_menu()
{
    state = self.ix.menu;
    state.open = 0;
    state.confirm = undefined;
    state.queued = undefined;
    state.open_request = undefined;
    hide_hud();
    hold( 0 );
    lock( 0 );
}

// Weapons, grenades, melee and Use off while the menu is open, through the
// stock counters, once each way.
lock( on )
{
    state = self.ix.menu;

    if ( state.locked == on )
        return;

    state.locked = on;
    allow = !on;
    self scripts\engine\utility::allow_weapon( allow );
    self scripts\engine\utility::allow_offhand_weapons( allow );
    self scripts\engine\utility::allow_melee( allow );
    self scripts\engine\utility::allow_usability( allow );
}

// Held where they stand while the menu is open, so the movement keys steer the
// menu instead of the player: linked to a point at their feet, the way the
// stock phone booth holds its player (a tag_origin model and
// playerlinktodelta), but free to look around. Only that link is ever undone.
hold( on )
{
    state = self.ix.menu;

    if ( on )
    {
        if ( isdefined( state.anchor ) )
            return;

        anchor = spawn( "script_model", self.origin );
        anchor setmodel( "tag_origin" );
        anchor.angles = ( 0, self.angles[1], 0 );
        self playerlinktodelta( anchor, "tag_origin", 1, 180, 180, 85, 85 );
        state.anchor = anchor;
        return;
    }

    if ( !isdefined( state.anchor ) )
        return;

    if ( is_held() )
        self unlink();

    state.anchor delete();
    state.anchor = undefined;
}

// Still held by the menu. The game may have taken them since (a ride, a trap,
// a teleport); then the menu gives way.
is_held()
{
    state = self.ix.menu;
    return isdefined( state.anchor ) && self islinked() && self getlinkedparent() == state.anchor;
}

// For other modules: whether this player's link is only the menu holding them.
is_menu_link( player )
{
    return isdefined( player.ix ) && isdefined( player.ix.menu ) && player is_held();
}

// For an action that moves the player (position.gsc): the menu closes, which
// lets go of them.
close_menu_for_move()
{
    if ( isdefined( self.ix ) && isdefined( self.ix.menu ) && self.ix.menu.open )
        close_menu();
}

// ---------------------------------------------------------------------------
// Input

input_loop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    held = "";

    for (;;)
    {
        wait 0.05;
        state = self.ix.menu;

        if ( !state.open )
        {
            held = "";
            track_crouch();

            if ( open_wanted() )
            {
                // Everything let go first, or the ADS still held (or the
                // player still walking) would move the cursor.
                if ( self open_after_landing() )
                {
                    wait_released( "ads" );
                    wait_released( "move" );
                }

                wait_released( "melee" );
                state.open_request = undefined;
            }

            continue;
        }

        if ( !is_held() )
        {
            close_menu();
            held = "";
            continue;
        }

        button = pressed_button();

        if ( isdefined( state.queued ) )
        {
            button = state.queued;
            state.queued = undefined;
            held = "";
        }

        if ( button == "" )
        {
            held = "";
            continue;
        }

        again = button == held;
        held = button;

        switch ( button )
        {
            case "melee":
                go_back();
                wait_released( "melee" );
                held = "";

                // The press that closed the menu does not open it again.
                state.open_request = undefined;
                break;
            case "use":
                use_item();
                wait_released( "use" );
                held = "";
                break;
            case "up":
            case "ads":
                move_cursor( -1 );
                repeat_after( button, again );
                break;
            case "down":
            case "attack":
                move_cursor( 1 );
                repeat_after( button, again );
                break;
            case "more":
            case "frag":
                change_value( 1 );
                repeat_after( button, again );
                break;
            case "less":
            case "tactical":
                change_value( -1 );
                repeat_after( button, again );
                break;
        }
    }
}

// The open keys: a Melee press the notify caught in the last half second, or
// Melee seen held now, with the other key of menu_open.
open_wanted()
{
    state = self.ix.menu;

    if ( isdefined( state.open_request ) )
    {
        recent = gettime() - state.open_request <= 500;
        state.open_request = undefined;

        if ( recent )
            return 1;
    }

    return self meleebuttonpressed() && open_keys_held();
}

// The key that goes with Melee: ADS held or aiming (playerads, as the stock
// weapon scripts read it; toggle ADS leaves the button up while aiming), or a
// moment crouched.
open_keys_held()
{
    switch ( custom_scripts\ix\core\config::get( "menu_open" ) )
    {
        case "ads_melee":
            return self adsbuttonpressed() || self playerads() > 0.3;
        case "crouch_melee":
            return crouched_a_moment();
    }

    return 0;
}

// Opens the menu; in the air (a jump, a slide's hop), on landing within a
// second. When it cannot open, a line says why.
open_after_landing()
{
    for ( waited = 0; waited < 1 && isalive( self ) && !self isonground(); waited += 0.05 )
        wait 0.05;

    problem = open_problem();

    if ( problem != "" )
    {
        if ( problem != "-" )
            self iprintln( problem );

        return 0;
    }

    return self open_menu();
}

// Since when the player has been crouched without sliding (getstance and
// issprintsliding, as the stock damage callback reads them; only while alive,
// since this loop also runs while they are dead or watching).
track_crouch()
{
    state = self.ix.menu;

    if ( isalive( self ) && self getstance() == "crouch" && !self issprintsliding() )
    {
        if ( !isdefined( state.crouch_since ) )
            state.crouch_since = gettime();
    }
    else
        state.crouch_since = undefined;
}

crouched_a_moment()
{
    state = self.ix.menu;
    return isdefined( state.crouch_since ) && gettime() - state.crouch_since >= 300;
}

// The one menu input given now, or "". Two buttons of a pair at once count
// as none, so the keys that opened the menu do not also scroll.
pressed_button()
{
    if ( self meleebuttonpressed() )
        return "melee";

    if ( self usebuttonpressed() )
        return "use";

    direction = move_direction();

    if ( direction != "" )
        return direction;

    ads = self adsbuttonpressed();
    attack = self attackbuttonpressed();

    if ( ads && !attack )
        return "ads";

    if ( attack && !ads )
        return "attack";

    frag = self fragbuttonpressed();
    tactical = self secondaryoffhandbuttonpressed();

    if ( frag && !tactical )
        return "frag";

    if ( tactical && !frag )
        return "tactical";

    return "";
}

// The movement keys or left stick: "up", "down", "less", "more", or "".
// getnormalizedmovement()[0] is forward (+) / back (-), [1] right (+) / left (-),
// as the stock dodge reads them (zombies_consumables.gsc).
move_direction()
{
    move = self getnormalizedmovement();

    if ( move[0] > 0.5 )
        return "up";

    if ( move[0] < -0.5 )
        return "down";

    if ( move[1] > 0.5 )
        return "more";

    if ( move[1] < -0.5 )
        return "less";

    return "";
}

is_pressed( button )
{
    switch ( button )
    {
        case "up":
        case "down":
        case "more":
        case "less":
            return move_direction() == button;
        case "move":
            return move_direction() != "";
        case "ads":
            return self adsbuttonpressed();
        case "attack":
            return self attackbuttonpressed();
        case "melee":
            return self meleebuttonpressed();
        case "use":
            return self usebuttonpressed();
        case "frag":
            return self fragbuttonpressed();
        case "tactical":
            return self secondaryoffhandbuttonpressed();
    }

    return 0;
}

wait_released( button )
{
    while ( is_pressed( button ) )
        wait 0.05;
}

// Held down: the first step waits a little longer than the ones after it.
repeat_after( button, again )
{
    delay = 0.35;

    if ( again )
        delay = 0.1;

    for ( waited = 0; waited < delay; waited += 0.05 )
    {
        if ( !is_pressed( button ) )
            return;

        wait 0.05;
    }
}

// ---------------------------------------------------------------------------
// Actions

current_page()
{
    return level.ix.menu.pages[self.ix.menu.page];
}

current_item()
{
    page = current_page();

    if ( self.ix.menu.cursor >= page.items.size )
        return undefined;

    return page.items[self.ix.menu.cursor];
}

move_cursor( step )
{
    state = self.ix.menu;
    count = current_page().items.size;

    if ( count == 0 )
        return;

    state.cursor = ( state.cursor + step + count ) % count;
    state.confirm = undefined;

    if ( state.cursor < state.top )
        state.top = state.cursor;
    else if ( state.cursor >= state.top + rows() )
        state.top = state.cursor - rows() + 1;

    draw();
}

go_back()
{
    state = self.ix.menu;

    if ( state.stack.size == 0 )
    {
        close_menu();
        return;
    }

    last = state.stack[state.stack.size - 1];
    state.stack[state.stack.size - 1] = undefined;
    state.page = last.page;
    state.cursor = last.cursor;
    state.top = last.top;
    state.confirm = undefined;
    draw();
}

open_page( id )
{
    state = self.ix.menu;
    back = spawnstruct();
    back.page = state.page;
    back.cursor = state.cursor;
    back.top = state.top;
    state.stack[state.stack.size] = back;
    state.page = id;
    state.cursor = 0;
    state.top = 0;
    draw();
}

use_item()
{
    item = current_item();

    if ( !isdefined( item ) )
        return;

    switch ( item.kind )
    {
        case "page":
            open_page( item.target );
            return;
        case "setting":
            setting = custom_scripts\ix\core\config::find( item.setting );

            // Use switches an on/off setting and steps an enum; numbers change
            // with A / D.
            if ( setting.type == "bool" || setting.type == "enum" )
                change_value( 1 );

            return;
        case "action":
            run_action( item );
            return;
    }
}

run_action( item )
{
    state = self.ix.menu;

    if ( isdefined( item.host_only ) && item.host_only && !may_change() )
    {
        draw();
        return;
    }

    if ( locked( item ) )
    {
        self iprintln( "Switch on " + custom_scripts\ix\core\config::find( item.needs ).label + " first." );
        draw();
        return;
    }

    if ( isdefined( item.confirm ) && item.confirm && !( isdefined( state.confirm ) && state.confirm == item.label ) )
    {
        state.confirm = item.label;
        draw();
        return;
    }

    state.confirm = undefined;
    self [[ item.fn ]]();

    if ( state.open )
        draw();
}

// direction 1: D or Frag (more, next); -1: A or Tactical (less, previous).
change_value( direction )
{
    item = current_item();

    if ( !isdefined( item ) || item.kind != "setting" )
        return;

    if ( !may_change() )
    {
        draw();
        return;
    }

    setting = custom_scripts\ix\core\config::find( item.setting );
    value = next_value( setting, item.step, direction );
    custom_scripts\ix\core\config::set( setting.id, value, "menu, " + self.name );
    draw();
}

next_value( setting, step, direction )
{
    switch ( setting.type )
    {
        case "bool":
            return !setting.value;
        case "enum":
            index = 0;

            for ( i = 0; i < setting.options.size; i++ )
            {
                if ( setting.options[i] == setting.value )
                    index = i;
            }

            index = ( index + direction + setting.options.size ) % setting.options.size;
            return setting.options[index];
    }

    if ( !isdefined( step ) )
        step = 1;

    return setting.value + step * direction;
}

// Actions the tree uses.
close_action()
{
    close_menu();
}

reset_all_action()
{
    custom_scripts\ix\core\config::reset_all( "menu, " + self.name );
}

// "Reset this page" (menu_tree.gsc add_reset): the settings on the page the
// player is on back to their defaults; other pages keep theirs.
reset_page_action()
{
    page = current_page();
    count = 0;

    foreach ( item in page.items )
    {
        if ( item.kind != "setting" || !custom_scripts\ix\core\config::exists( item.setting ) )
            continue;

        custom_scripts\ix\core\config::reset_default( item.setting, "menu, " + self.name );
        count++;
    }

    self iprintln( page.title + ": " + count + " settings back to their defaults." );
}

changed_count_info()
{
    return custom_scripts\ix\core\config::changed_count();
}

version_info()
{
    return level.ix.version;
}

// A setting changed anywhere (console, chat, another player's menu): every
// open menu shows the new value.
watch_settings()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "ix_setting_changed", id );
        wait 0.05;

        if ( !isdefined( level.players ) )
            continue;

        foreach ( player in level.players )
        {
            if ( isdefined( player ) && isdefined( player.ix ) && isdefined( player.ix.menu ) && player.ix.menu.open )
                player draw();
        }
    }
}

// ---------------------------------------------------------------------------
// HUD: a panel right of the screen's centre (horzalign "center": 4:3-safe
// units, with x from the centre) that ends at the 4:3 screen's right edge.

// Eight rows (longer pages scroll): with the help and the keys, the menu
// stays inside the HUD elements a player can see (L49).
rows()
{
    return 8;
}

menu_left()
{
    return 80;
}

menu_top()
{
    return 96;
}

menu_width()
{
    return 240;
}

row_height()
{
    return 14;
}

first_row_top()
{
    return menu_top() + 38;
}

help_top()
{
    return first_row_top() + rows() * row_height() + 6;
}

// The row's help and range, word-wrapped: room for the longest help with
// " Only the host can change it." after it (tools/tests/test_settings.py).
help_lines()
{
    return 4;
}

help_width()
{
    return 40;
}

footer_top()
{
    return help_top() + help_lines() * 11 + 4;
}

// The keys, in small text under the help: two lines.
footer_lines()
{
    return 2;
}

footer_line()
{
    return 9;
}

// Right edge of the values; > for a page sits at the panel's edge.
value_right()
{
    return menu_left() + menu_width() - 18;
}

arrow_right()
{
    return menu_left() + menu_width() - 6;
}

accent()
{
    return ( 0.13, 0.89, 1 );
}

create_hud()
{
    hud = spawnstruct();
    height = footer_top() + footer_lines() * footer_line() + 4 - menu_top();

    // Made in order of importance, and all but the last two help lines not
    // archived: a player sees only so many elements of each kind (L49).
    hud.panel = menu_shader( "white", menu_left(), menu_top(), menu_width(), height, ( 0.04, 0.03, 0.08 ), 0.85, 20 );
    hud.cursor = menu_shader( "white", menu_left() + 2, first_row_top(), menu_width() - 4, row_height(), accent(), 0.25, 21 );
    hud.title = menu_text( "left", menu_left() + 8, menu_top() + 6, "objective", 1.2, accent() );
    hud.crumb = menu_text( "left", menu_left() + 8, menu_top() + 22, "default", 0.9, ( 0.7, 0.7, 0.7 ) );
    hud.labels = [];
    hud.values = [];

    for ( row = 0; row < rows(); row++ )
    {
        top = first_row_top() + row * row_height() + 1;
        hud.labels[row] = menu_text( "left", menu_left() + 8, top, "default", 1, ( 1, 1, 1 ) );
        hud.values[row] = menu_text( "right", value_right(), top, "default", 1, ( 1, 1, 1 ) );
    }

    // < and > around the value on the cursor row: A / D change it.
    hud.less = menu_text( "right", value_right(), first_row_top() + 1, "default", 1, accent() );
    hud.less settext( "<" );
    hud.more = menu_text( "right", arrow_right(), first_row_top() + 1, "default", 1, accent() );
    hud.more settext( ">" );

    // The keys, in small text: set by show_controls(), for a keyboard or a
    // controller, and for the keys that open the menu.
    hud.footer = [];

    for ( line = 0; line < footer_lines(); line++ )
        hud.footer[line] = menu_text( "left", menu_left() + 8, footer_top() + line * footer_line(), "default", 0.7, ( 0.85, 0.85, 0.85 ) );

    hud.help = [];

    for ( line = 0; line < help_lines(); line++ )
    {
        hud.help[line] = menu_text( "left", menu_left() + 8, help_top() + line * 11, "default", 0.85, ( 0.8, 0.8, 0.8 ) );

        // Only long help needs the last lines.
        if ( line >= 2 )
            hud.help[line].archived = 1;
    }

    self.ix.menu.hud = hud;
    self.ix.menu.pad = undefined;
    self.ix.menu.open_keys = undefined;
    custom_scripts\ix\core\log::debug( "menu: " + hud_elements().size + " HUD elements for " + self.name );
}

menu_element( alignx, x, y, sort )
{
    element = newclienthudelem( self );
    element.horzalign = "center";
    element.vertalign = "top";
    element.alignx = alignx;
    element.aligny = "top";
    element.x = x;
    element.y = y;
    element.sort = sort;
    element.foreground = 1;
    element.hidewheninmenu = 1;
    element.hidewhendead = 1;
    element.archived = 0;
    element.alpha = 0;
    return element;
}

menu_shader( material, x, y, width, height, color, alpha, sort )
{
    element = menu_element( "left", x, y, sort );
    element setshader( material, width, height );
    element.color = color;
    element.shown_alpha = alpha;
    return element;
}

menu_text( alignx, x, y, font, scale, color )
{
    element = menu_element( alignx, x, y, 22 );
    element.font = font;
    element.fontscale = scale;
    element.color = color;
    element.shown_alpha = 1;
    return element;
}

hud_elements()
{
    hud = self.ix.menu.hud;
    list = [ hud.panel, hud.cursor, hud.title, hud.crumb, hud.less, hud.more ];

    foreach ( element in hud.footer )
        list[list.size] = element;

    foreach ( element in hud.labels )
        list[list.size] = element;

    foreach ( element in hud.values )
        list[list.size] = element;

    foreach ( element in hud.help )
        list[list.size] = element;

    return list;
}

hide_hud()
{
    if ( !isdefined( self.ix.menu.hud ) )
        return;

    foreach ( element in hud_elements() )
        element.alpha = 0;
}

draw()
{
    state = self.ix.menu;

    if ( !state.open || !isdefined( state.hud ) )
        return;

    hud = state.hud;
    page = current_page();
    hud.title settext( page.title );
    hud.crumb settext( crumb( page ) );
    hud.panel.alpha = hud.panel.shown_alpha;
    hud.title.alpha = 1;
    hud.crumb.alpha = 1;
    show_controls();

    for ( row = 0; row < rows(); row++ )
    {
        index = state.top + row;

        if ( index >= page.items.size )
        {
            hud.labels[row].alpha = 0;
            hud.values[row].alpha = 0;
            continue;
        }

        draw_row( hud.labels[row], hud.values[row], page.items[index] );
    }

    if ( page.items.size == 0 )
        hud.cursor.alpha = 0;
    else
    {
        hud.cursor.y = first_row_top() + ( state.cursor - state.top ) * row_height();
        hud.cursor.alpha = hud.cursor.shown_alpha;
    }

    show_arrows();

    lines = wrap( item_help( current_item() ), help_width(), help_lines() );

    for ( line = 0; line < help_lines(); line++ )
    {
        if ( line < lines.size )
        {
            hud.help[line] settext( lines[line] );
            hud.help[line].alpha = 1;
        }
        else
            hud.help[line].alpha = 0;
    }
}

draw_row( label, value, item )
{
    label settext( item.label );
    label.color = ( 1, 1, 1 );
    label.alpha = 1;
    value.alpha = 1;
    value.color = ( 0.8, 0.8, 0.8 );
    value.x = value_right();

    switch ( item.kind )
    {
        case "page":
            value.x = arrow_right();
            value settext( ">" );
            return;
        case "action":
            if ( locked( item ) )
            {
                label.color = ( 0.5, 0.5, 0.5 );
                value settext( "Locked" );
                value.color = ( 0.5, 0.5, 0.5 );
            }
            else if ( isdefined( self.ix.menu.confirm ) && self.ix.menu.confirm == item.label )
            {
                value settext( "Use again" );
                value.color = ( 1, 0.4, 0.4 );
            }
            else
                value settext( "" );

            return;
        case "info":
            show_value( value, self [[ item.fn ]]() );
            return;
    }

    setting = custom_scripts\ix\core\config::find( item.setting );

    if ( unavailable( setting ) )
    {
        label.color = ( 0.5, 0.5, 0.5 );
        value settext( "N/A" );
        value.color = ( 0.5, 0.5, 0.5 );
        return;
    }

    if ( setting.type == "bool" )
    {
        value settext( value_text( setting ) );

        if ( setting.value )
            value.color = ( 0.22, 1, 0.08 );
        else
            value.color = ( 1, 0.18, 0.59 );
    }
    else
        show_value( value, setting.value );

    if ( !may_change() )
        value.color = ( 0.5, 0.5, 0.5 );
}

// A feature that needs what this map does not have: shown as N/A.
unavailable( setting )
{
    if ( !custom_scripts\ix\core\features::is_feature( setting.id ) )
        return 0;

    feature = custom_scripts\ix\core\features::find( setting.id );
    return custom_scripts\ix\core\features::missing_requirement( feature ) != "";
}

// An action that needs an on/off setting ON (item.needs; the Debug page's
// tools need dev_tools), while that setting is OFF.
locked( item )
{
    if ( item.kind != "action" || !isdefined( item.needs ) || !custom_scripts\ix\core\config::exists( item.needs ) )
        return 0;

    return !custom_scripts\ix\core\config::get( item.needs );
}

// What a setting row shows as its value.
value_text( setting )
{
    if ( setting.type == "bool" )
    {
        if ( setting.value )
            return "ON";

        return "OFF";
    }

    return "" + setting.value;
}

// < and > around the value on the cursor row, when A / D can change it. The
// text's width is not known to scripts, so < goes by its length (a character
// of the default font at scale 1 is at most about 6.5 units wide).
show_arrows()
{
    state = self.ix.menu;
    hud = state.hud;
    hud.less.alpha = 0;
    hud.more.alpha = 0;
    item = current_item();

    if ( !isdefined( item ) || item.kind != "setting" || !may_change() )
        return;

    setting = custom_scripts\ix\core\config::find( item.setting );

    if ( unavailable( setting ) )
        return;

    y = first_row_top() + ( state.cursor - state.top ) * row_height() + 1;
    hud.less.x = value_right() - value_text( setting ).size * 6.5 - 5;
    hud.less.y = y;
    hud.more.y = y;
    hud.less.alpha = 1;
    hud.more.alpha = 1;
}

// The controls along the bottom, in the words of the player's device; set
// again only when they switch between a keyboard and a controller.
show_controls()
{
    state = self.ix.menu;
    hud = state.hud;
    pad = uses_gamepad();
    keys = custom_scripts\ix\core\config::get( "menu_open" );

    // Text only when it changes (KNOWN_LIMITATIONS.md L12).
    if ( !isdefined( state.pad ) || state.pad != pad )
    {
        state.pad = pad;
        hud.footer[0] settext( footer_move_text( pad ) );
    }

    if ( !isdefined( state.open_keys ) || state.open_keys != keys )
    {
        state.open_keys = keys;
        hud.footer[1] settext( footer_open_text( keys ) );
    }

    foreach ( element in hud.footer )
        element.alpha = 1;
}

// The footer's lines (tools/tests/test_settings.py checks that they fit).
footer_move_text( pad )
{
    if ( pad )
        return "Stick: move and change    Use / Jump: select";

    return "W/S: move   A/D: change   Use/Jump: select";
}

footer_open_text( keys )
{
    switch ( keys )
    {
        case "ads_melee":
            return "Melee: back / close    Open: ADS + Melee";
        case "crouch_melee":
            return "Melee: back / close    Open: Crouch + Melee";
    }

    return "Melee: back / close    Open: !ix menu";
}

// Numbers with setvalue, words with settext: numbers never become new strings.
show_value( element, value )
{
    if ( isstring( value ) )
        element settext( value );
    else
        element setvalue( value );
}

crumb( page )
{
    text = "";
    parent = page.parent;

    while ( isdefined( parent ) )
    {
        title = level.ix.menu.pages[parent].title;

        if ( text == "" )
            text = title;
        else
            text = title + " > " + text;

        parent = level.ix.menu.pages[parent].parent;
    }

    if ( text == "" )
        return "Infinite Expansion " + level.ix.version;

    return text;
}

item_help( item )
{
    if ( !isdefined( item ) )
        return "";

    if ( item.kind == "action" && isdefined( self.ix.menu.confirm ) && self.ix.menu.confirm == item.label )
        return "Press Use again to confirm. Anything else cancels.";

    text = item.help;

    if ( item.kind == "setting" )
    {
        setting = custom_scripts\ix\core\config::find( item.setting );

        if ( setting.type == "int" || setting.type == "float" || setting.type == "enum" )
            text = text + " (" + custom_scripts\ix\core\config::describe_range( setting ) + ")";
    }

    if ( ( item.kind == "setting" || ( item.kind == "action" && isdefined( item.host_only ) && item.host_only ) ) && !may_change() )
        text = text + " Only the host can change it.";

    if ( locked( item ) )
        text = text + " Locked: " + custom_scripts\ix\core\config::find( item.needs ).label + " is OFF.";

    return text;
}

// Words into at most max_lines lines of at most width characters.
wrap( text, width, max_lines )
{
    lines = [];

    if ( !isdefined( text ) || text == "" )
        return lines;

    line = "";

    foreach ( word in strtok( text, " " ) )
    {
        if ( line != "" && line.size + 1 + word.size > width )
        {
            lines[lines.size] = line;
            line = "";

            if ( lines.size == max_lines )
                return lines;
        }

        if ( line == "" )
            line = word;
        else
            line = line + " " + word;
    }

    if ( line != "" && lines.size < max_lines )
        lines[lines.size] = line;

    return lines;
}
