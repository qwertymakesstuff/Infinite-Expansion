# ROADMAP.md

The phase plan. `README.md` lists every phase with its status; this file holds the full scope of phases that are planned but **not started**, so nothing of what was asked for gets lost before its turn.

| Phase | Scope | Status |
|-------|-------|--------|
| 0–6 | Forensics, foundation, characters, core systems, in-game menu, player options, movement, weapons | Built (in-game tests pending; `README.md`, `TESTING.md`) |
| 7–10 | Zombies, HUD, quality of life, debug tools | In progress |
| 11–13 | Configuration presets, polish, testing | Planned (`FEATURE_STATUS.md`) |
| 14 | **Guided Easter egg mode**: an optional in-game guide to each map's main Easter egg quest | Planned, **not started** (below) |
| 15–22 | **The fun features**: emotes, fun toys, randomizer, favorites and presets, the FUN menu, secrets, co-op show-off features, their tests | Planned, **not started** (below) |

The fun features were added on 2026-10-09 by the project owner as Phases 14–21; the guided Easter egg mode was added the same day as Phase 14, and the fun features moved up one, to Phases 15–22. None of them is started; nothing below exists in the mod yet.

## Phase 14 — Guided Easter egg mode

An optional Guided Mode for Infinite Warfare zombies (the request calls the mod "All-Spectrum"; it is Infinite Expansion): an in-game companion that helps players follow each map's main Easter egg quest with contextual hints, objectives and directions. It makes the quests easier to follow; it never completes a step for the player. Added on 2026-10-09 by the project owner; not started.

**1. Guided Mode toggle.** A *Guided Easter Egg Mode* option set before loading into a zombies map, for example:

```text
ALL-SPECTRUM — GAME SETUP

Map: [Select Map]

Guided Easter Egg Mode: OFF

[Start Game] [Settings]
```

- OFF by default, and on a fresh installation. Never switched on by an update or by loading a map.
- Clearly shows whether it is on; the choice applies to the next map session; remembered for later sessions if possible (OFF stays the fresh-install default).
- Can also be switched off from the in-game menu. Switching it off hides every guide HUD element and notification and changes nothing in normal gameplay.
- If the game's own pre-match screen cannot be changed, a pre-map setup in the mod's own menu or the closest supported alternative; never pretend to change an interface that cannot be changed. *Known so far:* the mod already adds a CHARACTER button to the zombies lobby (Lua UI, `IW_API_NOTES.md` §16), the natural place for this toggle, and settings are remembered as archived dvars (`KNOWN_LIMITATIONS.md` L38).

**2. One guide per map.** A separate guide for each supported map, never one generic guide reused. First establish which maps have a main quest documented well enough for a reliable guide; candidates: Zombies in Spaceland, Rave in the Redwoods, Shaolin Shuffle, Attack of the Radioactive Thing, The Beast from Beyond (other content only if it is in the player's game and verifiable). Each guide holds: the map, the quest's name, prerequisites, the steps in order, required items and where they are, the interactable objects, puzzle instructions, important locations, boss-fight preparation and objectives where there is one, the final objective, and tips for hard steps. Research and verify every step against reliable references and the game's own scripts; never invent a step, an item location, a puzzle solution or a game trigger. A step that cannot be verified is marked as needing research, not presented as fact.

**3. Contextual guidance.** The next relevant hint as the player progresses:

```text
GUIDED MODE — SPACELAND

CURRENT OBJECTIVE
Find the required item near the specified attraction.

HINT
Search the nearby area for an interactable object.

PROGRESS
Objective 2 of 8
```

The text and the count come from the map's guide data. Where the game exposes reliable events or state, progress is detected automatically; where it does not, the player navigates by hand: *Next Hint*, *Previous Hint*, *Mark Step Complete*, *Show Full Guide*. A step is never assumed complete without evidence.

**4. Location and direction.** Location names, landmarks, directions, and (only when the game gives a reliable way to find the target) on-screen arrows, world markers, highlighted objects, map markers and distances. Never a marker at guessed coordinates or an invented object position; when positions cannot be tracked accurately, useful text directions instead:

```text
NEXT OBJECTIVE

Travel toward the central area.

Look for the interactable object
near the marked landmark.
```

**5. Hint levels.** *Minimal* (the objective and a short hint, no full solution), *Standard* (the objective, clearer directions and landmarks, what to accomplish; the default when Guided Mode is first switched on), *Detailed* (step-by-step instructions, puzzle mechanics, solutions when needed), *Full Walkthrough* (the whole guide, upcoming steps, item locations and puzzle solutions). The level changes only how much is shown, never the quest.

**6. HUD panel.** Small and polished, in the mod's style, clear of the zombies HUD:

```text
┌──────────────────────────────┐
│       GUIDED EASTER EGG       │
├──────────────────────────────┤
│ OBJECTIVE 3                   │
│ Locate the next quest item.   │
│                               │
│ HINT                          │
│ Check the area near the       │
│ relevant map landmark.        │
│                               │
│ [Previous] [Next Hint]        │
│ [Full Guide] [Hide]           │
└──────────────────────────────┘
```

Repositionable if supported; can be hidden or minimized; text size and opacity adjustable if possible; subtle notifications when the objective changes, never the same one twice; cleans itself up on death, respawn and map changes. *Known so far:* a player sees only so many HUD elements (`KNOWN_LIMITATIONS.md` L49), which the menu and the info HUD share, so the panel has to fit that budget.

**7. Step database.** Guide content kept apart from the Guided Mode code, data-driven in the form GSC allows, conceptually:

```text
GuidedMode/
├── Core
├── UI
├── ProgressTracker
└── Guides/
    ├── Spaceland
    ├── RaveInTheRedwoods
    ├── ShaolinShuffle
    ├── AttackOfTheRadioactiveThing
    └── BeastFromBeyond
```

Each guide defines its steps, hints, requirements, locations and progress conditions, so a guide for another map can be added without rewriting the system.

**8. Co-op.** Settings for local-only guidance, shared quest progress (if reliably detectable) and synchronized guidance (if supported). No network synchronization is assumed and none is claimed untested; when the game shares quest progress but the mod cannot detect it reliably, progress is tracked by hand.

**9. Compatibility.** Guided Mode stays optional and never touches the quest itself: it never triggers a step, teleports a player to an objective, spawns a quest item, skips a puzzle, changes the quest's order, breaks round progression, or changes anything while it is off. An unsupported map shows:

```text
GUIDED MODE UNAVAILABLE

A verified guide has not been added
for this map yet.
```

never another map's guide. A step that cannot be detected is navigated by hand, never reported as done.

**10. Testing.** On each supported map: off by default on a fresh install; can be switched on before a map; the right guide loads; objectives in the right order; automatic progress where supported; manual progress; previous and next hint; *Detailed* and *Full Walkthrough* show the right information; the HUD disappears when Guided Mode is switched off; death, going down, being revived and respawning do not break it; map changes load the right guide; unsupported maps are handled; the normal Easter egg works with Guided Mode off. A list of verified steps and open questions is kept for each map.

**Design philosophy.** An optional in-game Easter egg companion, not a cheat that completes the quest. Players who want to find the Easter eggs themselves leave it off and never see it; players who want help get accurate instructions without leaving the game for a walkthrough. Accuracy, contextual guidance, a clean HUD and normal zombies gameplay come first.

## Rules for Phases 15–22

These come with the request and apply to every fun feature:

- **Verify first.** Do not assume an animation, an effect or a game system exists. Inspect what Infinite Warfare zombies actually offers (the stock scripts, both compilers' built-in tables, the game's assets) and test each feature on its own. A feature the game cannot support is left out or marked BLOCKED in `FEATURE_STATUS.md`, never faked (the rule of `IW_API_NOTES.md` §12).
- **Independent modules.** Each fun feature is its own module, switched through the feature manager (`ARCHITECTURE.md` §4.1). A broken or experimental fun feature must never compromise core zombies gameplay, player spawning, weapon systems, round progression, the HUD, the configuration or the mod's start-up.
- **Reversible.** Every effect has ENABLE, DISABLE and RESET. After it is switched off, nothing of it remains on the player, the zombies, the weapons, the HUD or the game state.
- **Honest co-op.** Do not assume network synchronization. A feature that cannot synchronize reliably is done locally, and a local-only effect is never presented as synchronized.
- **Fun first.** The goal is not competitive balance but the polished extras that make players open the mod and think "What does this thing do?": polished UI, fun animations, funny effects, discoverability, smooth controls, good feedback, reversibility, co-op where possible, easy customization and easter eggs. The result should feel like a serious Infinite Warfare zombies enhancement mod with a ridiculous amount of fun stuff hidden inside it.

## Phase 15 — Zombies emote system

A polished, standalone Emotes system made for Infinite Warfare zombies: a real feature of the mod, not a single animation command.

- **Study first:** how the BO3 All-Around Enhancement files do emotes (their UI, animation handling, selection and player-state management; `tools/bo3_reference/extract_aae.sh` unpacks them again), then recreate the functionality with what Infinite Warfare offers.
- **Animations:** inspect the player animations and assets Infinite Warfare actually has, and use only those that can be played safely. New animations would need new assets (`KNOWN_LIMITATIONS.md` L13).
- **Menu:** an `EMOTES` category in the zombies menu:

  ```text
  EMOTES
  ├── Emote Wheel
  ├── Browse Emotes
  ├── Favorites
  ├── Random Emote
  ├── Emote Settings
  └── Preview Emote
  ```

  The player opens the emote interface, browses, highlights, previews and activates an emote, cancels, favorites, and picks one at random. It matches the look and polish of the main menu.
- **Categories:** Greetings, Reactions, Celebration, Funny, Taunts, Dance, Poses, Miscellaneous; a category holds only animations that can be used safely.
- **Preview:** where possible a preview screen (the player, the animation, its name and description, then Use / Favorite / Back). If a true isolated preview is impossible, the closest stable alternative.
- **Emote wheel:** if technically possible, a radial wheel (for example Dance at the top; Wave, Laugh, Point, Taunt, Salute and Pose around it; Back at the bottom) with the selected emote clearly highlighted, usable during a match without getting in the way of the game's HUD.
- **Safety:** emotes handle death, respawn, going down, reviving and being revived, weapon changes, round transitions, teleports and loading sections, pausing or opening a menu, and being interrupted. An emote never traps the player in an animation and never interferes with normal zombies gameplay.

## Phase 16 — Zombies fun toys

A `FUN` category of optional, entertaining, fully reversible gameplay toys:

```text
FUN
├── Player Effects
├── Movement Effects
├── Zombie Effects
├── Weapon Effects
├── Visual Effects
└── Miscellaneous
```

- **Player effects**, where supported: super jump, low and high gravity, speed boost, slow movement, spin or rotation effects, a random player animation, a forced pose, dramatic landings, temporary movement modifiers, third-person experiments, and small or large players if technically possible. Each with ENABLE, DISABLE and RESET.
- **Zombie effects**, harmless and only where the game exposes what they need: speed and health multipliers, slow or fast zombies, giant or small zombies if possible, random zombie effects, launch and knock-back, frozen zombies, temporary behaviour changes, randomized modifiers. Test each one on its own.
- **Weapon effects**, separate from the core weapon system of Phase 6: rapid fire, very slow fire, infinite ammo, a huge magazine, damage up or down, experimental recoil, random weapon behaviour, one-shot mode where supported.
- **Known so far** (for when this starts): several of these use the same game mechanisms as Phases 4–7 (gravity and speed dvars, `setmovespeedscale`, the fire-rate methods, `player_sustainAmmo`, damage callbacks; `IW_API_NOTES.md` §9–10). The global dvars affect every player and outlive the match (L17, L20), so their toys must put the old value back.

## Phase 17 — Zombies randomizer

A randomizer of fun gameplay modifiers:

```text
ZOMBIES RANDOMIZER
Random Movement
Random Weapon
Random Emote
Random Player Effect
Random Zombie Effect
Random Weapon Effect
Random Gameplay Modifier
Random Everything
```

A run shows what it rolled, for example: movement speed 1.35x, jump height 1.75x, gravity 0.80x, weapon modifier Rapid Fire, zombie speed 1.25x, zombie health 0.75x, emote Dance, HUD Minimal. Only supported systems are randomized. `RESET RANDOMIZER` restores every modified setting to its original or default state.

## Phase 18 — Favorites and presets

Save favorites and presets of the fun features: favorite emotes, fun effects, zombies modifiers, randomizer setups and combinations of effects:

```text
MY PRESETS
Chaos
Low Gravity
Zombie Party
Fast Zombies
Classic
Custom
```

A preset switches on several compatible features at once (for example CHAOS: Super Jump, Low Gravity, Fast Zombies, Random Weapon and Random Emote on). Presets persist across sessions only if the mod environment allows it reliably, otherwise they last for the session. The settings already persist as archived dvars (`KNOWN_LIMITATIONS.md` L38), which is the first thing to try; Phase 11 (configuration presets) is related.

## Phase 19 — Fun menu polish

A dedicated section of the zombies menu:

```text
ALL-SPECTRUM
├── Player
├── Movement
├── Weapons
├── Zombies
├── HUD
├── Gameplay
├── Quality of Life
├── FUN
│   ├── Emotes
│   ├── Randomizer
│   ├── Player Effects
│   ├── Zombie Effects
│   ├── Weapon Effects
│   └── Favorites
├── Utilities
├── Debug
└── Settings
```

`FUN` should look polished and intentional, something a player wants to explore, not a debug or developer menu. The request names the menu's root "ALL-SPECTRUM"; today it is titled "Infinite Expansion" (`ix/ui/menu_tree.gsc`), so settle the title when this phase starts.

## Phase 20 — Secret and easter egg system

A small system for hidden, zombies-specific features, not all shown in the normal menus: secret emotes, rare animations, hidden player effects, funny zombie modifiers, secret menu themes, rare randomizer outcomes, hidden menu interactions, references to the zombies easter eggs, developer jokes. Built so that new easter eggs can be added later without rewriting the menu:

```text
SecretFeatureManager
├── Secret Emotes
├── Secret Player Effects
├── Secret Zombie Effects
├── Secret Menus
└── Easter Eggs
```

Every secret effect stays reversible and never permanently damages or changes the game.

## Phase 21 — Zombies social and show-off features

Co-op zombies only, where technically possible: emotes other players can see, synchronized emotes, group poses and group emote effects, fun player introductions, victory and end-of-round poses, team-wide randomizer challenges, shared fun modifiers, emotes shown to spectators. Nothing is assumed to synchronize: what cannot synchronize reliably is done locally and never presented as synchronized. Features handle players joining and leaving, death, going down, reviving, spectating and round transitions.

## Phase 22 — Fun feature testing

A dedicated zombies checklist in `TESTING.md`, written as the features are built:

- **Emotes:** open the emote menu, browse, select, cancel, preview, favorite, random emote, interrupt an emote; die, go down, get revived and respawn during one; switch weapons; a round transition.
- **Randomizer:** randomize, randomize repeatedly, reset, presets, unsupported combinations; death, going down, respawn, round transitions, map loading.
- **Player effects:** enable, disable, reset; death, going down, revive, respawn, round transition.
- **Zombie effects:** existing zombies, newly spawned zombies, zombie death, a new round and round transitions, reset, player death.
- **Co-op**, where supported: several players, joining, leaving, death, going down, reviving, spectating, round transitions, shared or synchronized effects.

No fun feature may permanently change the player, the zombies, the weapons, the HUD or the game state after it is switched off.
