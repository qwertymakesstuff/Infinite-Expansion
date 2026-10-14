# ROADMAP.md

The phase plan. `README.md` lists every phase with its status; this file holds the full scope of phases that are planned but **not started**, so nothing of what was asked for gets lost before its turn.

| Phase | Scope | Status |
|-------|-------|--------|
| 0–10 | Forensics, foundation, characters, core systems, in-game menu, player options, movement, weapons, zombies options, info HUD, quality of life, developer tools | Built (in-game tests pending; `README.md`, `PLAYTEST_CHECKLIST.md`, `TESTING.md`) |
| 11–12 | Configuration presets (0.11.0), polish (0.12.0) | Built (in-game tests pending) |
| 13 | **Guided Mode**: an optional tracker for each map's main Easter egg quest (0.13.0) | Built (in-game tests pending; the scope it was built to is kept below) |
| 14 | **Emotes**: each map's character animations on an emote wheel, with browsing, favorites, random and preview (0.14.0) | Built (in-game tests pending; the scope it was built to is kept below) |
| 14+ | **Custom emotes**: the owner's own animations on a copy of the player's character, packaged on the player's PC (four steps, below) | Step 1 built (a proof with one of the game's animations), in-game test pending; steps 2–4 not started |
| 15–21 | **The rest of the fun features**: fun toys, randomizer, favorites and presets, the FUN menu, secrets, co-op show-off features, their tests | Next is Phase 15; **not started** (below) |

The fun features were added on 2026-10-09 by the project owner as Phases 14–21; the guided Easter egg mode was added the same day as Phase 14, and the fun features moved up one, to Phases 15–22. On 2026-10-12 the owner removed Phase 13 (a testing phase: start-up, player, zombies, configuration and compatibility checks) and put the guided Easter egg mode in its place, so the fun features are Phases 14–21 again. Testing goes on with each phase as before (`PLAYTEST_CHECKLIST.md`, `TESTING.md`). Phase 13 was built in 0.13.0 (`README.md` *Guided Mode*); its scope stays below as the record of what was asked. Phase 14 was built in 0.14.0 (`README.md` *Emotes*); its scope stays below too. None of Phases 15–21 is started; nothing of them exists in the mod yet.

## Phase 13 — Guided Easter egg mode

An optional Guided Mode for Infinite Warfare zombies (the request calls the mod "All-Spectrum"; it is Infinite Expansion): an in-game companion that helps players follow each map's main Easter egg quest with contextual hints, objectives and directions. It makes the quests easier to follow; it never completes a step for the player. Added on 2026-10-09 by the project owner as Phase 14; made Phase 13 on 2026-10-12, in place of the testing phase, with the same scope. Built in 0.13.0 (2026-10-13), with the owner's emphasis that it should feel like Black Ops 6's guided mode, as if built into Infinite Warfare.

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

## Custom emotes (requested 2026-10-14; step 1 of 4 built, not released)

Full-body emotes from the owner's own animations, seen in third person by the player and by the others. A program on the player's Windows PC packages them into a zone the game loads, and the emote wheel plays them in a *Custom* category. Several input formats.

**Method: a stand-in body.** The player's body is driven by IW7's animation state machine, which x64-zt cannot build and GSC cannot drive (`KNOWN_LIMITATIONS.md` L13). During an emote the player is hidden, a script model with their own body and head plays the custom animation (`scriptmodelplayanim`, as the stock scripts play character animations), the camera goes behind the player, the player is held (the emote safety: ground only, no zombie within 3 m, ends on damage, down or death), and the copy is deleted and the player shown again on every way out (`IW_API_NOTES.md` §24).

1. **Proof with none of the owner's art** (built; in-game test pending): `Build Custom Emotes.cmd` dumps one of the game's own character animations that the stock scripts already play on a model (The Hoff's `IW7_cp_zom_hoff_dj_desk_01`) with x64-zt, renames it and builds `iw7-mod/zone/ix_emotes.ff`; the mod plays it on the stand-in from a Custom row. Test as host, as a guest with the zone, as a guest without it (`TESTING.md` R-E7–R-E9). If it fails, stop and find out why.
2. **The converter**, several formats through one intermediate model: SEAnim and Cast first (documented open formats), then glTF/GLB; Unity `.anim` clips (asked for on 2026-10-14) only if a sample shows they are text-serialized bone curves (a humanoid clip's muscle curves need Unity itself, so those go through Unity's FBX export and Blender); FBX by exporting to glTF from Blender, or only with a verified, licence-compatible library. The `.xab` layout from x64-zt's `xanim.cpp`, a reader and a writer, proven by round trips: game `.xab` files dumped on the owner's PC go to the intermediate and back and must match byte for byte, or the program refuses to build. Bone names checked against the IW7 player body rig, unknown or missing bones reported. Test fixtures without game art.
3. **Packaging**: a *Build Custom Emotes* step in the setup (PowerShell, like *Build Character Pictures*) reading a folder of animations and a small manifest (name, wheel name, category, looping, length), building the zone and writing the list the mod reads. GSC / Lua: the Custom category on the wheel, a setting to switch it off, host-side: custom emotes only when every player reports having the zone (if that can be verified), clear messages when the zone is missing.
4. **Docs, tests, version bump, release**; then verify that the release zip matches the commit.

## Rules for Phases 14–21

These come with the request and apply to every fun feature:

- **Verify first.** Do not assume an animation, an effect or a game system exists. Inspect what Infinite Warfare zombies actually offers (the stock scripts, both compilers' built-in tables, the game's assets) and test each feature on its own. A feature the game cannot support is left out or marked BLOCKED in `FEATURE_STATUS.md`, never faked (the rule of `IW_API_NOTES.md` §12).
- **Independent modules.** Each fun feature is its own module, switched through the feature manager (`ARCHITECTURE.md` §4.1). A broken or experimental fun feature must never compromise core zombies gameplay, player spawning, weapon systems, round progression, the HUD, the configuration or the mod's start-up.
- **Reversible.** Every effect has ENABLE, DISABLE and RESET. After it is switched off, nothing of it remains on the player, the zombies, the weapons, the HUD or the game state.
- **Honest co-op.** Do not assume network synchronization. A feature that cannot synchronize reliably is done locally, and a local-only effect is never presented as synchronized.
- **Fun first.** The goal is not competitive balance but the polished extras that make players open the mod and think "What does this thing do?": polished UI, fun animations, funny effects, discoverability, smooth controls, good feedback, reversibility, co-op where possible, easy customization and easter eggs. The result should feel like a serious Infinite Warfare zombies enhancement mod with a ridiculous amount of fun stuff hidden inside it.

## Phase 14 — Zombies emote system

A polished, standalone Emotes system made for Infinite Warfare zombies: a real feature of the mod, not a single animation command.

Built in 0.14.0 (2026-10-13). What Infinite Warfare allowed: the emotes are the gestures each map loads (every character's Pack-a-Punch, entrance and card trick, and the map's hand gestures); there are no dances, props or other body animations a script can play, so the Dance, Reactions and Miscellaneous categories are BLOCKED (`KNOWN_LIMITATIONS.md` L64). The wheel is a ring of the menu's own rows (seven emotes, Back at the bottom); the preview is the emote played with the camera behind the player, the closest stable alternative to a preview screen. AAE's emotes were studied first (`IW_API_NOTES.md` §23).

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

## Phase 15 — Zombies fun toys

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

## Phase 16 — Zombies randomizer

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

## Phase 17 — Favorites and presets

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

## Phase 18 — Fun menu polish

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

## Phase 19 — Secret and easter egg system

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

## Phase 20 — Zombies social and show-off features

Co-op zombies only, where technically possible: emotes other players can see, synchronized emotes, group poses and group emote effects, fun player introductions, victory and end-of-round poses, team-wide randomizer challenges, shared fun modifiers, emotes shown to spectators. Nothing is assumed to synchronize: what cannot synchronize reliably is done locally and never presented as synchronized. Features handle players joining and leaving, death, going down, reviving, spectating and round transitions.

## Phase 21 — Fun feature testing

A dedicated zombies checklist in `TESTING.md`, written as the features are built:

- **Emotes:** open the emote menu, browse, select, cancel, preview, favorite, random emote, interrupt an emote; die, go down, get revived and respawn during one; switch weapons; a round transition.
- **Randomizer:** randomize, randomize repeatedly, reset, presets, unsupported combinations; death, going down, respawn, round transitions, map loading.
- **Player effects:** enable, disable, reset; death, going down, revive, respawn, round transition.
- **Zombie effects:** existing zombies, newly spawned zombies, zombie death, a new round and round transitions, reset, player death.
- **Co-op**, where supported: several players, joining, leaving, death, going down, reviving, spectating, round transitions, shared or synchronized effects.

No fun feature may permanently change the player, the zombies, the weapons, the HUD or the game state after it is switched off.
