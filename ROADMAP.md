# ROADMAP.md

The phase plan. `README.md` lists every phase with its status; this file holds the full scope of phases that are planned but **not started**, so nothing of what was asked for gets lost before its turn.

| Phase | Scope | Status |
|-------|-------|--------|
| 0–3 | Forensics, foundation, characters, core systems, in-game menu | Complete (in-game tests pending) |
| 4 | Player features | In progress |
| 5–13 | Movement, weapons, zombies, HUD, quality of life, debug, presets, polish, testing | Planned (`FEATURE_STATUS.md`) |
| 14–21 | **The fun features**: emotes, fun toys, randomizer, favorites and presets, the FUN menu, secrets, co-op show-off features, their tests | Planned, **not started** (below) |

Phases 14–21 were added on 2026-10-09 by the project owner, to be done after the earlier phases. They are not started; nothing below exists in the mod yet.

## Rules for Phases 14–21

These come with the request and apply to every fun feature:

- **Verify first.** Do not assume an animation, an effect or a game system exists. Inspect what Infinite Warfare zombies actually offers (the stock scripts, both compilers' built-in tables, the game's assets) and test each feature on its own. A feature the game cannot support is left out or marked BLOCKED in `FEATURE_STATUS.md`, never faked (the rule of `IW_API_NOTES.md` §12).
- **Independent modules.** Each fun feature is its own module, switched through the feature manager (`ARCHITECTURE.md` §4.1). A broken or experimental fun feature must never compromise core zombies gameplay, player spawning, weapon systems, round progression, the HUD, the configuration or the mod's start-up.
- **Reversible.** Every effect has ENABLE, DISABLE and RESET. After it is switched off, nothing of it remains on the player, the zombies, the weapons, the HUD or the game state.
- **Honest co-op.** Do not assume network synchronization. A feature that cannot synchronize reliably is done locally, and a local-only effect is never presented as synchronized.
- **Fun first.** The goal is not competitive balance but the polished extras that make players open the mod and think "What does this thing do?": polished UI, fun animations, funny effects, discoverability, smooth controls, good feedback, reversibility, co-op where possible, easy customization and easter eggs. The result should feel like a serious Infinite Warfare zombies enhancement mod with a ridiculous amount of fun stuff hidden inside it.

## Phase 14 — Zombies emote system

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
