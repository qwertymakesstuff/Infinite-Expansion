# Play-test checklist (0.10.0)

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

- [ ] **S1** Start a match. The console shows one `[IX] INFO: init 0.10.0 map=cp_zmb modules=player,weapons,zombies,qol,debug,ui`, then `settings: 52 (0 changed from the default)`, then `ready`; no `script compile error` or `script link error`. *(R-S1)*
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

## 5. Zombies (Phase 7, new)

Turn on *HUD: zombies* (HUD page) first, to see the counts.

- [ ] **Z1** *Zombie speed* sprint in round 1–3: every regular zombie sprints within a second; walk: they walk; default: new zombies move as the game picks. No zombie freezes or slides oddly. *(R-Z1)*
- [ ] **Z2** *Zombie health* 1000 (round 5 or later): new zombies take about ten times the bullets; 10: they drop at once; 100: normal. *(R-Z2)*
- [ ] **Z3** *Max zombies alive* 4: at most about 4 alive (brutes come on top); 64: many more at once, and the game does not slow down badly or stop spawning; 24: normal. *(R-Z3)*
- [ ] **Z4** *Points multiplier* 200: kills pay twice (with Double Money, four times); 0: nothing; 100: normal, also after Double Money ends. *(R-Z4)*
- [ ] **Z5** *Power-ups per round* 0: no power-ups from kills for two rounds; 20: more than five in a round. *(R-Z5)*
- [ ] **Z6** *Starting round* 20, then *Game* → *Restart the match*: the new match starts at round 20, with no special round at once. Set it back to 1 afterwards. *(R-Z6)*
- [ ] **Z7** *Start with perks* on: about a second after each spawn you have every perk (in solo without Up N' Atoms); also after dying and coming back. *(R-Z7)*
- [ ] **Z8** Play three rounds with several Zombies options on, go down and get revived: rounds start and end as usual, and the console has no `script runtime error`. *(R-Z8)*

## 6. Info HUD (Phase 8, new)

- [ ] **H1** *HUD: round*, *zombies*, *health*, *speed* on, one at a time: each shows its name and number on the left, and the numbers follow the game (zombies left counts down to 0 at the round's end; speed about 190 when running). *(R-H1, R-H4)*
- [ ] **H2** *HUD: side* right, *HUD: height* 100 / -100: the numbers move; note anything of the game's own screen they cover. *(R-H2)*
- [ ] **H3** With every HUD row on, open the menu: the HUD hides, and **all** of the menu's text is still there (its last help lines too). The HUD also hides in the pause menu. *(R-H3)*

## 7. Game options and shortcuts (Phase 9, new)

- [ ] **Q1** *Game speed* 50: slow motion; 200: fast; 100: normal. A match ended at 50: the next one is at normal speed. *(R-Q2)*
- [ ] **Q2** *Zombie outlines* on: every zombie outlined in orange, also behind walls; off: gone within half a second. *(R-Q3)*
- [ ] **Q3** *Restart the match* (Use twice): "The match restarts." and the map starts over at round 1 with the starting points; note anything that carried over. *(R-Q4)*
- [ ] **Q4** Chat: `!ix` (every line of the list arrives), `!ix refill`, `!ix save`, walk away, `!ix load`, `!ix tp` looking at a floor. *(R-Q5)*

## 8. Developer tools (Phase 10, new)

- [ ] **D1** *Debug* with *Developer tools* OFF: the tools read "Locked" and do nothing. *(R-D1)*
- [ ] **D2** *Developer tools* ON, then *Pause / resume spawning*: no new zombies until you resume; *Developer tools* OFF resumes too. *(R-D2)*
- [ ] **D3** *Kill all zombies*: every zombie dies without points; a brute or boss stays. *(R-D3)*
- [ ] **D4** *End this round* mid-round: the zombies die and the next round starts after the usual pause. Between rounds it says no round is running. *(R-D4)*
- [ ] **D5** *Give yourself 10,000 points*; *Drop a power-up*: each of the seven appears in front of you and works. *(R-D5, R-D6)*
- [ ] **D6** *Information*: map, players, round, zombies and position look right. *What am I looking at?* at a zombie and a wall names them. *(R-D7)*
- [ ] **D7** Chat `!ix log`: the mod's last 8 log lines. *(R-D8)*

## 9. Co-op (when a friend can join)

- [ ] **C1** The friend joins (both with the mod installed by the setup); the host's settings apply to both; the friend's menu rows are grey ("Only the host can change it."). *(R-S2, R-C4)*
- [ ] **C2** *Zombie outlines* and the HUD work for the friend too; *Restart the match* restarts it for both. *(R-Q3, R-Q4)*

## 10. Clean-up

- [ ] **E1** *Settings* → *Reset every setting*, then start a new match: the console says `0 changed from the default`, and the game plays as without the mod. *(R-C6)*
