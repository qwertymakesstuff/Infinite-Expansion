// Infinite Expansion - the fun features (Phases 14-21).
//
// Each fun feature is its own module, switched through the feature manager,
// and never touches core gameplay when off (ROADMAP.md, rules for Phases
// 14-21).
//   emotes.gsc       emotes: this map's character animations (Phase 14)
//   emote_data.gsc   which emotes each map has

register()
{
    custom_scripts\ix\core\bootstrap::register_module( "fun" );
    custom_scripts\ix\fun\emotes::register();
}
