// Infinite Expansion - player card.
//
// A small card in the bottom-right corner naming the character the player is
// playing as: a dark panel with a coloured edge, the character's name and
// their outfit on this map. It appears after the first spawn and follows its
// settings within half a second.
// The stock HUD's character portrait is drawn by the client UI from image
// names scripts cannot see, so the card has no picture (KNOWN_LIMITATIONS.md
// L28); the stock portrait itself does follow the chosen character.
//
// Settings (unset = default):
//   ix_player_card    1   0 hides the card
//   ix_player_card_x  16  distance from the right edge  (640 x 480 virtual screen)
//   ix_player_card_y  96  distance from the bottom edge, above the ammo counter

register()
{
    level thread watch_spawns();
}

card_width()
{
    return 150;
}

card_height()
{
    return 34;
}

watch_spawns()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "ix_player_spawned", player );

        if ( !isdefined( player.ix.card_running ) )
            player thread card_loop();
    }
}

card_loop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self.ix.card_running = 1;

    for (;;)
    {
        entry = custom_scripts\ix\player\character::entry_for_num( self.player_character_num );

        if ( isdefined( entry ) && custom_scripts\ix\core\util::dvar_int( "ix_player_card", 1 ) != 0 )
            show_card( entry );
        else
            hide_card();

        wait 0.5;
    }
}

show_card( entry )
{
    margin_x = custom_scripts\ix\core\util::dvar_int( "ix_player_card_x", 16 );
    margin_y = custom_scripts\ix\core\util::dvar_int( "ix_player_card_y", 96 );

    if ( isdefined( self.ix.card ) && ( self.ix.card.margin_x != margin_x || self.ix.card.margin_y != margin_y ) )
        hide_card();

    if ( !isdefined( self.ix.card ) )
        create_card( margin_x, margin_y );

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

create_card( margin_x, margin_y )
{
    right = 640 - margin_x;
    bottom = 480 - margin_y;

    card = spawnstruct();
    card.margin_x = margin_x;
    card.margin_y = margin_y;

    card.panel = card_element( "right", right, bottom, 10 );
    card.panel setshader( "black", card_width(), card_height() );
    card.panel.alpha = 0.55;

    card.edge = card_element( "left", right - card_width(), bottom, 11 );
    card.edge setshader( "white", 3, card_height() );
    card.edge.alpha = 0.9;

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
    self.ix.card = undefined;
}
