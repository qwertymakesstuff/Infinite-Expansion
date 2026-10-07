// Infinite Expansion - player card.
//
// A small card in the bottom-right corner naming the character the player is
// playing as: a dark panel with a coloured edge, the character's picture, name
// and outfit on this map. It appears after the first spawn and follows its
// settings within half a second.
// The picture is the stock HUD's square team card of that character on this
// map (character::card_material; KNOWN_LIMITATIONS.md L28): its material loads
// with the map, for every player. A special character from another map has
// none here, and its card shows no picture.
//
// Settings (config.gsc; console: set ix_<id> <value>, chat: !ix set <id> <value>):
//   player_card          1   feature (features.gsc): 0 hides the card at once
//   player_card_picture  1   0: the card without the picture
//   player_card_x        16  distance from the right edge  (640 x 480 virtual screen)
//   player_card_y        96  distance from the bottom edge, above the ammo counter

register()
{
    feature = custom_scripts\ix\core\features::add( "player_card", "hud", "Player card", "The card in the bottom-right corner naming your character.", 1 );
    feature.on_player = ::apply_player_card;
    custom_scripts\ix\core\config::add_bool( "player_card_picture", 1, "Player card: picture", "The character's card from this map, as the HUD shows teammates.", undefined );
    custom_scripts\ix\core\config::add_int( "player_card_x", 16, 0, 600, "Player card: right margin", "Distance from the right edge of a 640 x 480 screen.", undefined );
    custom_scripts\ix\core\config::add_int( "player_card_y", 96, 0, 440, "Player card: bottom margin", "Distance from the bottom edge of a 640 x 480 screen.", undefined );
    custom_scripts\ix\core\events::subscribe( "player_spawn", ::on_spawn );

    // Now, while the level loads (the only time precaching is allowed), in a
    // thread of its own, so that a failure cannot stop the mod's start.
    level thread precache_pictures();
}

// The team cards of every character this map has. Stock zombies scripts use
// setshader without precaching; the multiplayer gametypes precache their
// materials first (mugger.gsc), which is the safer of the two.
precache_pictures()
{
    if ( !isdefined( level.ix.character ) || !isdefined( level.ix.character.cast ) )
        return;

    foreach ( entry in level.ix.character.cast )
    {
        material = custom_scripts\ix\player\character::card_material( entry, "team" );

        if ( isdefined( material ) )
            precacheshader( material );
    }
}

// Switched off: gone at once. Switched on: card_loop shows it within half a second.
apply_player_card( enabled )
{
    if ( !enabled && isdefined( self.ix ) )
        hide_card();
}

card_width()
{
    return 150;
}

card_height()
{
    return 34;
}

picture_size()
{
    return 30;
}

// The picture for this entry, or undefined (none on this map, or switched off).
card_picture( entry )
{
    if ( !custom_scripts\ix\core\config::get( "player_card_picture" ) )
        return undefined;

    return custom_scripts\ix\player\character::card_material( entry, "team" );
}

same_picture( a, b )
{
    if ( !isdefined( a ) || !isdefined( b ) )
        return !isdefined( a ) && !isdefined( b );

    return a == b;
}

on_spawn( player )
{
    if ( custom_scripts\ix\core\util::is_valid_player( player ) && isdefined( player.ix ) && !isdefined( player.ix.card_running ) )
        player thread card_loop();
}

card_loop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self.ix.card_running = 1;

    for (;;)
    {
        entry = custom_scripts\ix\player\character::entry_for_num( self.player_character_num );

        if ( isdefined( entry ) && custom_scripts\ix\core\features::is_enabled( "player_card" ) )
            show_card( entry );
        else
            hide_card();

        wait 0.5;
    }
}

show_card( entry )
{
    margin_x = custom_scripts\ix\core\config::get( "player_card_x" );
    margin_y = custom_scripts\ix\core\config::get( "player_card_y" );
    picture = card_picture( entry );

    if ( isdefined( self.ix.card ) && ( self.ix.card.margin_x != margin_x || self.ix.card.margin_y != margin_y || !same_picture( self.ix.card.picture, picture ) ) )
        hide_card();

    if ( !isdefined( self.ix.card ) )
        create_card( margin_x, margin_y, picture );

    card = self.ix.card;

    if ( isdefined( card.key ) && card.key == entry.key )
        return;

    card.key = entry.key;
    card.name settext( entry.name );
    card.role settext( card_subtitle( entry ) );
    card.edge.color = entry.color;
}

card_subtitle( entry )
{
    if ( entry.special )
        return "Special character";

    if ( entry.role != "" )
        return entry.role;

    return custom_scripts\ix\player\character::map_title( level.ix.map );
}

// With a picture, the card is wider by the picture, which sits after the edge.
create_card( margin_x, margin_y, picture )
{
    right = 640 - margin_x;
    bottom = 480 - margin_y;
    width = card_width();

    if ( isdefined( picture ) )
        width += picture_size() + 6;

    card = spawnstruct();
    card.margin_x = margin_x;
    card.margin_y = margin_y;
    card.picture = picture;

    card.panel = card_element( "right", right, bottom, 10 );
    card.panel setshader( "black", width, card_height() );
    card.panel.alpha = 0.55;

    card.edge = card_element( "left", right - width, bottom, 11 );
    card.edge setshader( "white", 3, card_height() );
    card.edge.alpha = 0.9;

    if ( isdefined( picture ) )
    {
        card.icon = card_element( "left", right - width + 6, bottom - 2, 12 );
        card.icon.alpha = 1;
        // In a thread of its own: should the game refuse the material, only
        // the picture is missing, not the card.
        level thread show_picture( card.icon, picture );
    }

    card.name = card_element( "right", right - 8, bottom - 16, 12 );
    card.name.font = "objective";
    card.name.fontscale = 1.2;
    card.name.alpha = 1;

    card.role = card_element( "right", right - 8, bottom - 4, 12 );
    card.role.font = "default";
    card.role.fontscale = 1;
    card.role.color = ( 0.8, 0.8, 0.8 );
    card.role.alpha = 1;

    self.ix.card = card;
}

show_picture( element, material )
{
    element setshader( material, picture_size(), picture_size() );
}

card_element( alignx, x, y, sort )
{
    element = newclienthudelem( self );
    element.horzalign = "fullscreen";
    element.vertalign = "fullscreen";
    element.alignx = alignx;
    element.aligny = "bottom";
    element.x = x;
    element.y = y;
    element.sort = sort;
    element.foreground = 1;
    element.hidewheninmenu = 1;
    element.hidewhendead = 1;
    element.archived = 0;
    return element;
}

hide_card()
{
    if ( !isdefined( self.ix.card ) )
        return;

    card = self.ix.card;
    card.panel destroy();
    card.edge destroy();
    card.name destroy();
    card.role destroy();

    if ( isdefined( card.icon ) )
        card.icon destroy();

    self.ix.card = undefined;
}
