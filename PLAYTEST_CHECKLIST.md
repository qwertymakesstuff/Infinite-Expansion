# Play-test checklist (0.14.0)

What to try in a real match, and what should happen. Each item names its row in `TESTING.md` §4 (in brackets), where the details are. Tick what works; for anything that does not, see *If something is wrong* below.

## Before you start

- Start the game with the launcher, so the setup updates the mod first. The console (`~`) and `iw7-mod\logs\console.log` show the mod's `[IX]` lines.
- First run: **Zombies in Spaceland**, solo. Other maps and co-op afterwards.
- Open the menu with **ADS + Melee** (or type `!ix menu` in chat). Each page ends with *Reset this page*.

### If something is wrong

1. **Switch that one option off**: in the menu, or in chat with `!ix reset <setting>` (the setting names are in `README.md`). Every option is its own setting, so the others keep working; carry on testing them.
2. **Note** the item's ID (for example *Z3*), what you did, and what happened.
3. **Copy** the `[IX]` lines and any `script runtime error` block from `iw7-mod\logs\console.log` (or type `!ix log 20` in chat and take a screenshot).
4. At the end, *Settings* → *Reset every setting*, so your next normal game is the game's own.

## 1. Start-up and the menu

- [ ] **S1** Start a match. The console shows one `[IX] INFO: init 0.14.0 map=cp_zmb modules=player,weapons,zombies,qol,debug,guided,fun,ui`, then `settings: 65 (0 changed from the default)`, then `ready`; no `script compile error` or `script link error`. *(R-S1)*
- [ ] **M1** ADS + Melee opens the menu **every** time, also with a quick tap and with toggle ADS. All its text shows: the title, eight rows, the help under the list and the two small lines of keys. *(R-M1, R-M11)*
- [ ] **M2** W / S move, A / D change a value, Use or Jump selects, Melee goes back and closes. Long pages (the first page, Player, Movement, Debug) scroll past their eighth row. Every page's text is all there. *(R-M2, R-M14)*
- [ ] **M3** While the menu is open you cannot shoot, throw or knife; after closing, everything works again. Going down closes it. *(R-S3, R-S4)*
- [ ] **M4** At the start of a round, until you have opened the menu once, a line in the middle of the screen says how to open it. *(R-M13)*
- [ ] **M5** *Reset this page* (bottom of Player, Movement, Weapons, Zombies, HUD, Game), Use twice: only that page goes back to its defaults, and a line says how many settings. *(R-Q1)*

## 2. Player (Phase 4)

- [ ] **P1** *God mode* host: zombies cannot hurt you; off: they can again. *(R-P2)*
- [ ] **P2** *Damage taken* 50 / 200: you go down after about twice / half as many hits. *(R-P3)*
- [ ] **P3** *Third person*: the camera is behind you, also after dying and coming back. *(R-P6)*
- [ ] **P4** *Zombies ignore players*: zombies walk past you; off: they come for you within a second. *(R-P7)*
- [ ] **P5** *Rocket jump*: a grenade at your feet throws you up, with no damage. *(R-P5)*
- [ ] **P6** *Position*: *Save position*, walk away, *Go to saved position*; *Teleport to crosshair* at a floor. You end up there, never inside a wall. *(R-P10)*

## 3. Movement (Phase 5)

- [ ] **MV1** *Move speed* 200 and *Gravity* 50: faster, and higher jumps; back to 100: the game's own. *(R-MV1, R-MV2)*
- [ ] **MV2** *Wall run*, *Double jump*, *Mantle*: each works, also after dying and coming back. Report a map where one does nothing. *(R-MV3–R-MV5)*
- [ ] **MV3** *Slide* off: no slide. *Fall damage* off: a high drop does not hurt. *(R-MV6, R-MV8)*
- [ ] **MV4** End the match, then type `g_speed` and `bg_gravity` in the console: 190 and 800. *(R-MV10)*

## 4. Weapons (Phase 6)

- [ ] **W1** *Unlimited ammo* clip: you never reload; reserve: you reload, but the spare ammo stays full. Report any weapon that acts oddly. *(R-W1)*
- [ ] **W2** *Unlimited grenades*: a thrown grenade is back within half a second. *(R-W2)*
- [ ] **W3** *Fire rate* 200: twice as fast; 100: normal again. *(R-W3)*
- [ ] **W4** *No recoil*: the sights barely move. *(R-W4)*
- [ ] **W5** *Refill ammo*: ammo and grenades full for everyone standing. *(R-W6)*
- [ ] **W6** *Give a weapon* (new in 0.10.1): pick a weapon on each class page and a wonder weapon; the menu closes and it is in your hands with full ammo; with every slot full, the one in your hands goes. Only this map's weapons are listed. Report one that arrives without attachments, empty, or not at all. *(R-W8)*

## 5. Zombies (Phase 7; fixed in 0.10.1, health in 0.10.2)

Turn on *HUD: zombies* (HUD page) first, to see the counts. *Zombies* → *In effect now* shows what the game is using right now; `!ix zombies` in chat says the same. If an option seems to do nothing, send a screenshot of either.

- [ ] **Z0** *In effect now*, a few seconds into the match: *Set up* yes, *Speed hook* on, *Zombie health* 100, *Points* 100, *Power-ups a round* 5. During a round, *A zombie's health* and *Game's own for it* are the same number. *(R-Z9)*
- [ ] **Z1** *Zombie speed* sprint in round 1–3: every regular zombie on the map starts sprinting at once; walk: they walk; default: new zombies move as the game picks. No zombie freezes or slides oddly. *(R-Z1)*
- [ ] **Z2** *Zombie health* 1000 (A / D go 50 at a time), with an ordinary gun, no Insta-Kill: a line says how many zombies out changed; they and every new one take about ten times the bullets, and *In effect now* shows *A zombie's health* ten times *Game's own for it*. 10: they drop at once; 100: normal. *(R-Z2)*
- [ ] **Z3** *Max zombies alive* 4 (round 5 or later, when many zombies come): at most about 4 alive (brutes come on top), and *Most alive now* says 4 during the round; 24: normal. *(R-Z3)*
- [ ] **Z4** *Points multiplier* 200: kills pay twice (*Points* says 200; with Double Money, 400); 0: nothing; 100: normal. *(R-Z4)*
- [ ] **Z5** *Power-ups per round* 0: no power-ups from kills for two rounds (*Power-ups a round* says 0); 20: more than five in a round. *(R-Z5)*
- [ ] **Z6** *Starting round* 20 (a line says it applies from the next match), then *Game* → *Restart the match*: the new match starts at round 20, with no special round at once. Set it back to 1 afterwards. *(R-Z6)*
- [ ] **Z7** *Start with perks* on: every perk within a second or two, right away, and again after dying and coming back (in solo without Up N' Atoms). *(R-Z7)*
- [ ] **Z8** Play three rounds with several Zombies options on, go down and get revived: rounds start and end as usual, and the console has no `script runtime error`. *(R-Z8)*

## 6. Info HUD (Phase 8)

- [ ] **H1** *HUD: round*, *zombies*, *health*, *speed* on, one at a time: each shows its name and number on the left, and the numbers follow the game (zombies left counts down to 0 at the round's end; speed about 190 when running). *(R-H1, R-H4)*
- [ ] **H2** *HUD: side* right, *HUD: height* 100 / -100: the numbers move; note anything of the game's own screen they cover. *(R-H2)*
- [ ] **H3** With every HUD row on, open the menu: the HUD hides, and **all** of the menu's text is still there (its last help lines too). The HUD also hides in the pause menu. *(R-H3)*

## 7. Game options and shortcuts (Phase 9)

- [ ] **Q1** *Game speed* 50: slow motion; 200: fast; 100: normal. A match ended at 50: the next one is at normal speed. *(R-Q2)*
- [ ] **Q2** *Zombie outlines* on: every zombie outlined in orange, also behind walls; off: gone within half a second. *(R-Q3)*
- [ ] **Q3** *Restart the match* (Use twice): "The match restarts." and the map starts over at round 1 with the starting points; note anything that carried over. *(R-Q4)*
- [ ] **Q4** Chat: `!ix` (every line of the list arrives), `!ix refill`, `!ix save`, walk away, `!ix load`, `!ix tp` looking at a floor. *(R-Q5)*

## 8. Developer tools (Phase 10)

- [ ] **D1** *Debug* with *Developer tools* OFF: the tools read "Locked" and do nothing. *(R-D1)*
- [ ] **D2** *Developer tools* ON, then *Pause / resume spawning*: no new zombies until you resume; *Developer tools* OFF resumes too. *(R-D2)*
- [ ] **D3** *Kill all zombies*: every zombie dies without points; a brute or boss stays. *(R-D3)*
- [ ] **D4** *End this round* mid-round: the zombies die and the next round starts after the usual pause. Between rounds it says no round is running. *(R-D4)*
- [ ] **D5** *Give yourself 10,000 points*; *Drop a power-up*: each of the seven appears in front of you and works. *(R-D5, R-D6)*
- [ ] **D6** *Information*: map, players, round, zombies and position look right. *What am I looking at?* at a zombie and a wall names them. *(R-D7)*
- [ ] **D7** Chat `!ix log`: the mod's last 8 log lines. *(R-D8)*

## 9. Presets (Phase 11)

- [ ] **PR1** *Presets* → *Enhanced* (Use twice): a line says how many settings changed; wall run, double jump and mantle work, the round and zombies are on the HUD; *In use* says Enhanced. Then *Testing*: god mode, unlimited ammo, every perk; *In use* says Testing. *(R-C10)*
- [ ] **PR2** Change any option by hand: *In use* says *Your own*. *Default*: everything back to the game's own, but your *Menu: open with*, the HUD's side and height and your character settings stay. *(R-C10)*
- [ ] **PR3** *Custom* before saving: it says nothing is saved. Set a few options, *Save as Custom*, *Default*, then *Custom*: your options are back. Quit the game, start it again: `!ix preset` still knows Custom. *(R-C10)*

## 10. After the polish (Phase 12)

In 0.12.0 the options that keep themselves applied sleep while they are off and wake when a setting changes.

- [ ] **PL1** Start with every option at its default (*Presets* → *Default*) and play a round. Then switch on, one at a time: *Unlimited ammo* clip, *Fire rate* 200, *Zombie outlines*, *Wall run*, *Zombies ignore players* host, *Points multiplier* 200, *Max zombies alive* 4, *HUD: round*. Each works within a second, and switched off again each goes back to the game's own. *(V146)*
- [ ] **PL2** *HUD: round* and *HUD: zombies* on, then hold D on *HUD: height*: the numbers glide up without flickering; *HUD: side* right moves them. *(R-H2)*
- [ ] **PL3** `!ix` and `!ix log 20`: every line arrives. *(R-Q5, R-D8)*

## 11. Guided Mode (Phase 13)

Switch it on in the zombies lobby with **GUIDED MODE** (under CHARACTER) before starting the map, then play the map's main Easter egg quest from the start of a match. Any map counts; note the map for every report.

- [ ] **G1** GUIDED MODE: ON in the lobby; after the match's intro the tracker shows on the right: *MAIN QUEST 1/n*, the first objective and a hint. Quit and start again: still ON. *(R-G1)*
- [ ] **G2** Do the first steps of the quest: each one closes by itself, with *Objective complete* and a sound, then *New objective*. Where the game knows the place, the item to use glows with a yellow outline (also through walls), or a gold marker shows where there is no item; the meters fall as you walk to it. Note any outline on the wrong thing. *(R-G2, R-G4)*
- [ ] **G3** A step that does not close by itself, closes too early, or whose hint names the wrong place: note its id (Guided Mode page → *Full guide*), then *Mark step complete* and go on. *(R-G2)*
- [ ] **G4** *Guide options*: try *Hints* minimal, detailed and full, *Reveal more*, side left, text large, panel compact; open the menu: the tracker hides. *(R-G3, R-G4)*
- [ ] **G5** Chat `!ix guide`: the current objective and hint. *(R-G6)*

## 12. Emotes (Phase 14, new)

Open the menu's **Emotes** page. Note the map and the emote's id (`!ix emote` lists them) for every report.

- [ ] **EM1** *Emote wheel*: seven names in a ring, *Back* at the bottom. Push the stick or W / A / S / D toward one: it lights up; Use plays it and the menu closes. *(R-E1)*
- [ ] **EM2** *Browse emotes*: play a Pack-a-Punch, an entrance, a card trick (with its sound) and, in Shaolin Shuffle, a hand gesture (*Bang*). The camera goes behind you for the first three and comes back. Note any that does nothing or looks wrong. *(R-E2)*
- [ ] **EM3** *Favorite* two emotes: they are first on the wheel. Quit and start again: still there. *(R-E4)*
- [ ] **EM4** Get hit during an emote: it ends at once, and you can aim and knife again. Try one while sprinting or next to a zombie: a line says why not. *(R-E5)*
- [ ] **EM5** Chat `!ix emote random`: one plays. *(R-E6)*

## 13. Co-op (when a friend can join)

- [ ] **C1** The friend joins (both with the mod installed by the setup); the host's settings apply to both; the friend's menu rows are grey ("Only the host can change it."). *(R-S2, R-C4)*
- [ ] **C2** *Zombie outlines* and the HUD work for the friend too; *Restart the match* restarts it for both. *(R-Q3, R-Q4)*
- [ ] **C3** Guided Mode on: both see the same objective, and a step one of you completes closes for both. *(R-G5)*
- [ ] **C4** Play an emote while the friend watches: note whether they see your character move. *(R-E3)*

## 14. Clean-up

- [ ] **E1** *Settings* → *Reset every setting*, then start a new match: the console says `0 changed from the default`, and the game plays as without the mod. *(R-C6)*
