# Shaolin Shuffle (cp_disco) - Main Easter Egg, Guided Mode research

STATUS: COMPLETE (research pass 1). All 41 steps are mapped from script. Web cross-check uses search summaries only (WebFetch unavailable); see each step's status.

Script root (all file:line references are relative to this):
`.toolchain/src/iw7-gsc-dump/decompiled/scripts/`
Short names: `mpq` = cp/maps/cp_disco/disco_mpq.gsc, `kfm` = cp/maps/cp_disco/kung_fu_mode.gsc,
`rkf` = cp/maps/cp_disco/rat_king_fight.gsc, `pb` = cp/maps/cp_disco/phonebooth.gsc, `zp` = cp/zombies/zombie_power.gsc.

Debug flags: every quest step waits on `flag_wait_any_return( "<flag>", "<flag>dbg" )`. The `*dbg` twins (mpq:53-75) are developer skips. A tracker should watch the plain flag only.

---------------------------------------------------------------------------------------------------

## A. Quest overview

- Name: the script calls it "skq" (`mpq:4 skq()`, flags `skq_*`). Players know it as the Shaolin Shuffle main Easter egg: the Rat King quest, which awards the Soul Key.
- Started from: cp/maps/cp_disco/cp_disco.gsc:148 (`thread disco_mpq::skq()`). The boss fight is initialised at cp_disco.gsc:146 (`rkfightinit`), and the Rat King at cp_disco.gsc:113.
- Players: solo or co-op, 1-4 players. The script has explicit solo branches: `isplayingsolo()` tuning in rkf (for example rkf:719, rkf:1714, rkf:2096), and the missing-reel wave scales with `level.players.size` (mpq:2069). The 4-player-only checks are voice lines only (mpq:1620, mpq:2522, kfm:1303). Web sources also say solo or team (Escapist and SegmentNext summaries).
- Prerequisites, from script:
  - Pam Grier gives nothing quest-related before wave 5. `talk_to_trainer` returns early while `level.wave_num < 5` (kfm:1132-1163).
  - Chi styles cannot be chosen until Pam's first quest talk (`choose_martial_arts_style` needs `skq_phase_1` at kfm:1449; gourd station use needs it at kfm:1530).
  - Steps that need a shuriken require Chi style level 1 or higher. Every style's primary Chi power is a shuriken (kfm:844-851), and it is granted only when the style level is at least 1 (kfm:1764-1768, kfm:1576-1583).
  - The spotlight step requires the `disco_roof` power area to be on (mpq:1214).
  - The final step and the boss fight happen in the Rat King's lair (the sewer arena).
- Overview: After round 5, talk to Pam Grier in the Black Cat Dojo, pick a Chi style, use Chi mode, and talk to her again. She then sends you after three Rat King relics, one quest each, given in this order:
  1. EYE: free the rat Templeton by breaking cages with shurikens, clear a kill circle and a ninja wave, open the subway locker with the key, shoot four symbols in order, then summon and drive off the Rat King.
  2. BRAIN: use the Eye to find and shoot hidden symbols (phone booths turn red), answer the ringing phone (Morse code number), take the flyer with that number, put it on the rooftop spotlight (needs roof power), hit the rat at the X, beat a ninja wave, spell a word on the roof cipher, then summon and drive off the Rat King.
  3. HEART: after 3 more rounds the "Missing Reel" plays. Survive it, take the turnstile arm, fix the subway turnstile, shoot the glyph behind the window, fill 6 kill circles, start the disco turntable, kill the disco-fever zombie chain, then summon and drive off the Rat King.
  Hand each relic to Pam (just talk to her). After the heart, step into the Rat King's lair sewage to start the 7-stage final fight. That fight has 3 relic sub-quests (eye, brain and heart, in a random slot order). It ends in the outro video and the Soul Key drop.
- Sources:
  - Script, primary: mpq (whole file), kfm:132-162 and kfm:1032-1311, rkf (whole file), pb:425-1103, zp:94-131, cp/maps/cp_disco/ratking_damage.gsc:303-325, mp/agents/ratking/ratking_agent.gsc:226-236, cp/cp_weapon.gsc:390-445, cp/maps/cp_disco/cp_disco_interactions.gsc:36-103.
  - Web: WebSearch result summaries only; WebFetch is unavailable, so treat these as untrusted:
    - Escapist, "Everything You Need to Know About Shaolin Shuffle | Full Easter Egg Guide" (escapistmagazine.com)
    - Accelerated Ideas, "Shaolin Shuffle - All Easter Egg Steps" (accelerated-ideas.com)
    - Gameranx, "Infinite Warfare: Shaolin Shuffle - The Complete Easter Egg Guide" (gameranx.com/features/id/103727)
    - Attack of the Fanboy, Shaolin Shuffle Easter egg guide (attackofthefanboy.com)
    - SegmentNext, Shaolin Shuffle Easter egg steps guide (segmentnext.com/2017/04/19/...)
    - speedrun.com/iwzombies/guides/dl8r4, "(my) Ratking boss fight guide"
    - gameslearningsociety.org, "How many Rat King symbols are there?"

---------------------------------------------------------------------------------------------------

## B. Ordered steps

Legend: `flag_set` / `notify` references are the completion evidence. "init" is where `flag_init` happens.

### Step summary

| # | id | objective | detect | marker | status |
|---|---|---|---|---|---|
| 1 | talk_pam_start | Talk to Pam Grier | flag_set skq_phase_1 | yes | VERIFIED |
| 2 | choose_style | Choose a Chi style | manual | yes | VERIFIED |
| 3 | enter_chi_mode | Drink Chi juice | flag_set first_kung_fu_mode | none | VERIFIED |
| 4 | chi_level_1 | Reach Chi style level 1 | manual | none | VERIFIED |
| 5 | talk_pam_eye_quest | Talk to Pam Grier again | flag_set skq_p2t1_0 | yes | VERIFIED |
| 6 | free_templeton | Break the rat's cages | level notify cage_win | yes | VERIFIED |
| 7 | cage_ring_kills | Kill zombies in the circle | level notify stop_this_challenge_ring_sfx | yes | VERIFIED |
| 8 | ninjas_and_key | Beat the ninjas, grab the key | flag_set skq_p2t1_2 | yes | VERIFIED |
| 9 | open_locker | Open the subway locker | flag_set skq_p2t1_3 | yes | VERIFIED |
| 10 | shoot_four_symbols | Shoot the 4 symbols in order | level notify active_word_done | yes | VERIFIED for the mechanic |
| 11 | summon_rk_eye | Use the Rat King symbol | flag_set skq_p2t1_4 | yes | VERIFIED |
| 12 | fight_rk_eye | Drive off the Rat King | entity notify (fake_death) | yes | VERIFIED |
| 13 | take_eye | Pick up the Rat King's Eye | flag_set eye_picked | dynamic (relic spawn pos) | VERIFIED |
| 14 | talk_pam_brain_quest | Return to Pam Grier | flag_set skq_p2t1_5 | yes | VERIFIED |
| 15 | eye_symbol_hunt | Find symbols with the Eye | flag_set skq_p2t2_1 | yes | VERIFIED |
| 16 | answer_phone | Answer the ringing phone | flag_set morse_code_heard | yes | VERIFIED |
| 17 | take_flyer | Take the matching flyer | flag_set correct_poster_got | yes | SCRIPT ONLY (mpq:1180-1359) |
| 18 | roof_power | Turn on the Disco roof power | flag_set disco_roof power_on | yes | SCRIPT ONLY for the requirement (mpq:1214, mpq:1232) |
| 19 | place_flyer_spotlight | Put the flyer on the spotlight | manual | yes | SCRIPT ONLY (mpq:1214-1219, mpq:1229-1275) |
| 20 | hit_rat_at_x | Hit the rat at the X | flag_set skq_p2t2_4 | yes | SCRIPT ONLY (mpq:1220-1226) |
| 21 | roof_ninjas | Defeat the ninja wave | flag_set skq_p2t2_5 | yes | SCRIPT ONLY (mpq:1366-1374, mpq:2619-2718) |
| 22 | roof_cipher_word | Spell the cipher word | manual | yes | SCRIPT ONLY (mpq:1376-1596, mpq:2833-2871) |
| 23 | summon_rk_brain | Use the Rat King symbol | flag_set skq_p2t2_6 | yes | SCRIPT ONLY |
| 24 | fight_rk_brain | Drive off the Rat King | entity notify (fake_death) | yes | SCRIPT ONLY (mpq:1598-1629, mpq:1848-1868) |
| 25 | take_brain | Pick up the Rat King's Brain | flag_set brain_picked | dynamic (relic spawn pos) | VERIFIED for the item existing (web lists "Rat King's Brain" in the inventory) |
| 26 | talk_pam_heart_quest | Return to Pam Grier | flag_set skq_p2t2_7 | yes | SCRIPT ONLY (mpq:1870-1884, kfm:1294-1297) |
| 27 | wait_three_rounds | Survive 3 more rounds | manual | none | SCRIPT ONLY (mpq:1910-1958, mpq:2895-2922) |
| 28 | survive_missing_reel | Survive the Missing Reel | flag_set cleanup_reel_assets | yes | SCRIPT ONLY (mpq:1950-1994, mpq:2019-2184) |
| 29 | take_turnstile_arm | Grab the turnstile arm | flag_set skq_p2t3_1 | candidates only | SCRIPT ONLY (mpq:1995-2016) |
| 30 | fix_turnstile | Fix the subway turnstile | flag_set turnstile_done | yes | SCRIPT ONLY (mpq:2219-2252) |
| 31 | shoot_window_glyph | Shoot the glyph in the window | flag_set turnstyle_glyph_hit | yes | SCRIPT ONLY (mpq:2186-2217) |
| 32 | six_kill_circles | Fill 6 kill circles | level notify task3RingDone | yes | SCRIPT ONLY (mpq:2254-2291, mpq:223-245) |
| 33 | start_disco_turntable | Spin the disco turntable | flag_set fever_started | yes | SCRIPT ONLY (mpq:2452-2493) |
| 34 | disco_fever_kills | Kill the disco ball zombies | flag_set skq_p2t3_4 | yes | VERIFIED |
| 35 | summon_rk_heart | Use the Rat King symbol | flag_set skq_p2t3_5 | yes | SCRIPT ONLY |
| 36 | fight_rk_heart | Drive off the Rat King | entity notify (fake_death) | yes | SCRIPT ONLY (mpq:2501-2553) |
| 37 | take_heart | Pick up the Rat King's Heart | flag_set heart_picked | dynamic (relic spawn pos) | VERIFIED for the item (web summary: the map's lethal grenade is "the Rat King's Heart"; script gives `power_heart` as a primary power, mpq:1803) |
| 38 | talk_pam_final | Bring the Heart to Pam Grier | flag_set skq_p2t3_6 | yes | SCRIPT ONLY (kfm:1299-1311, mpq:2555-2559) |
| 39 | enter_rk_lair | Enter the Rat King's lair | flag_set skq_phase_3 | yes | VERIFIED for the place (web: the final boss fight is in the Rat King's lair; lair = sewer area) |
| 40 | defeat_rat_king | Defeat the Rat King | flag_set rk_fight_ended | yes | VERIFIED for the overall structure |
| 41 | take_soul_key | Pick up the Soul Key | manual | none | SCRIPT ONLY for the mechanics |

### Phase 1: Pam Grier and Chi

#### 1. talk_pam_start
- objective: Talk to Pam Grier
- location: Black Cat Dojo
- hint_minimal: Pam Grier only has work for you from round 5 on.
- hint_standard: From round 5 on, go to the Black Cat Dojo and talk to Pam Grier. She unlocks the Chi style statues.
- hint_detailed: Reach round 5. Go to Pam Grier in the Black Cat Dojo and use her. Before round 5 she only says intro lines. This talk unlocks the four Chi animal style stations (Tiger, Crane, Snake, Dragon).
- detect: `flag_set( "skq_phase_1" )` kfm:1054 (`first_trainer_interaction`, runs via `level.trainer_quests[0]`, table kfm:1038-1044, dispatch kfm:1190-1191). Also set at kfm:1577-1578. init mpq:18.
- marker: `getent( "ma_trainer", "targetname" )` kfm:1045 (`level.trainer`). The interaction structs are `getstructarray( "martial_arts_trainer", "script_noteworthy" )` kfm:1035.
- status: VERIFIED. Script: wave gate kfm:1132 and flag kfm:1054. Web: Pam Grier at the Black Cat Dojo starts the egg (Escapist, Attack of the Fanboy summaries). The round-5 gate is SCRIPT ONLY.

#### 2. choose_style
- objective: Choose a Chi style
- location: Black Cat Dojo (style stations)
- hint_minimal: Pick one of the four animal styles.
- hint_standard: Use one of the animal style stations (Tiger, Crane, Snake or Dragon) to start training that Chi style.
- hint_detailed: Use a Tiger, Crane, Snake or Dragon style station. This sets your active style, starts its level-1 Chi challenge and gives you the gourd (Chi juice). Any style works for the quest, because every style's first power is a shuriken.
- detect: manual. There is no level flag. Per player, `kung_fu_progression.active_discipline` is set in `choose_martial_arts_style` kfm:1452 (function kfm:1441-1501), and the level challenge starts at kfm:1495.
- marker: `getstructarray( "martial_arts_animals", "script_noteworthy" )` kfm:897 (the `.name` field is tiger/snake/crane/dragon, kfm:904).
- status: VERIFIED. Script kfm:1441-1501. Web: "Pam ... offers one of four chi elemental abilities. Choose one and level it up" (Escapist summary). The style stations' exact placement is NEEDS RESEARCH: web only says "at the Dojo".

#### 3. enter_chi_mode
- objective: Drink Chi juice
- location: Anywhere
- hint_minimal: Use your gourd to enter Chi mode.
- hint_standard: Press the gourd button (d-pad right / actionslot 4) to drink the Chi juice and enter Chi mode once.
- hint_detailed: With a style chosen, press actionslot 4 (d-pad right) to drink from the gourd and enter Chi mode. The first time anyone in the lobby does this, Pam has a new quest. Refill the gourd at a gourd station.
- detect: `flag_set( "first_kung_fu_mode" )` kfm:160, together with `increase_trainer_interaction_progression()` kfm:161. init kfm:1034.
- marker: none, since it can be done anywhere. Gourd refill stations: `getstructarray( "gourd_station", "script_noteworthy" )` kfm:954.
- status: VERIFIED. Script kfm:132-162 (button `+actionslot 4` kfm:140). Web: "Drink a Chi juice from one of the coloured bottles to activate a Chi mode" (Escapist summary).

#### 4. chi_level_1
- objective: Reach Chi style level 1
- location: Anywhere
- hint_minimal: Finish your style's first Chi challenge to earn the shuriken.
- hint_standard: Complete the level-1 Chi challenge of your style. At level 1 your Chi mode gets a shuriken, which you need for the next steps.
- hint_detailed: Complete your style's first Chi challenge (its progress shows on the HUD). At level 1, Chi mode gives your primary Chi power, a shuriken for every style. The rat cages can only be broken by a shuriken.
- detect: manual. Per player, `disciplines_levels[style]` is incremented in `update_player_abilities` kfm:1566-1569, called from `challenge_success` cp/maps/cp_disco/cp_disco_challenges.gsc:79-81. No level flag.
- marker: none.
- status: VERIFIED. The shuriken requirement is script: the cage only accepts damage from a weapon containing "shuriken" (mpq:351-354), and the shuriken is the level-1 power (kfm:844-851, kfm:1764-1768). Web: "level it up", then "throw a Shuriken" (Escapist summary). What each style's level-1 challenge asks for is NEEDS RESEARCH; it is not quest-specific.

#### 5. talk_pam_eye_quest
- objective: Talk to Pam Grier again
- location: Black Cat Dojo
- hint_minimal: Pam has a new task now that you have used Chi.
- hint_standard: After someone has used Chi mode, talk to Pam Grier again. She asks for the Rat King's Eye, and the rat cages appear.
- hint_detailed: Return to Pam Grier and talk to her. The talk only progresses after someone has entered Chi mode once; otherwise she has nothing new. She asks for the Rat King's Eye, and the rat-cage hunt begins.
- detect: `flag_set( "skq_p2t1_0" )` kfm:1286 (`start_phase_2_task1`, run from `complete_trainer_quest_1` kfm:1059-1062), then `flag_set( "skq_p2t1_1" )` mpq:156. init mpq:21-22.
- marker: `getent( "ma_trainer", "targetname" )` kfm:1045.
- status: VERIFIED. Script kfm:1057-1077 and mpq:141-157. Web: "you may have to talk to Pam (inside Dojo) twice before the rat spawns into the cage" (Escapist/Accelerated Ideas summary).

### Phase 2, task 1: Rat King's Eye

#### 6. free_templeton
- objective: Break the rat's cages
- location: Rat cages around the map
- hint_minimal: One caged rat starts a chase. Shuriken only.
- hint_standard: In Chi mode, hit a rat cage with a shuriken. The rat runs to another cage; follow it and shuriken that cage. Repeat until the chain ends.
- hint_detailed: Cages appear when you are within about 1024 units. Hit any cage with a shuriken. The rat (Templeton) runs to a random cage; hit that cage. 6 correct hits in total (1 + 4 + final). Hitting the wrong cage fails the step and resets it.
- detect: `level notify( "cage_win" )` mpq:285 (`remove_cage_quest`, after `monitor_cage_destruction` returns 1, mpq:168-178). A failure sends `level notify( "cage_fail" )` mpq:293.
- marker: the next correct cage is `level.next_cage` (set mpq:544 from `getstructarray( "mpq_rat_cage", "targetname" )` mpq:537). Before the first hit, all cages are `getstructarray( "mpq_rat_cage", "targetname" )` mpq:163.
- status: VERIFIED. Script mpq:159-178 and mpq:322-622. Web: shuriken the cage with the live rat; the rat moves to the next cage; "Repeat this step another four times until the final cage is broken" (Escapist summary).

#### 7. cage_ring_kills
- objective: Kill zombies in the circle
- location: At the last rat cage
- hint_minimal: Kill zombies inside the glowing circle by the last cage.
- hint_standard: A glowing circle appears at the last cage. Kill 15 zombies inside it.
- hint_detailed: Stand by the glowing circle at the final cage and kill 15 zombies within about 150 units of its centre. The script counts any zombie kill there; it does not check for Chi. Web guides say to use Chi.
- detect: `level notify( "stop_this_challenge_ring_sfx" )` mpq:243 (end of `zombie_challenge_ring`). The task-3 rings reuse this notify, so only trust it while `skq_p2t1_1` is set and `skq_p2t1_2` is not.
- marker: `getstructarray( "cage_challenge_ring", "targetname" )` mpq:188, filtered by `script_noteworthy == level.next_cage.script_noteworthy` (mpq:190-196).
- status: VERIFIED. Script mpq:199 and mpq:223-245 (15 kills; radius check `distancesquared <= 22500`, mpq:237). Web: "Charge the circle by getting zombie kills using a Chi ability" (Escapist summary).

#### 8. ninjas_and_key
- objective: Beat the ninjas, grab the key
- location: At the last rat cage
- hint_minimal: Ninjas come next. Then pick up what they guard.
- hint_standard: About 10 seconds after the circle, 8 ninja (karate master) zombies attack. Kill them all, then pick up the locker key at the circle.
- hint_detailed: About 10 s after the circle completes, 8 karate-master ninjas spawn nearby. Kill them all; the wave also ends after a 300 s timeout. A locker key then glows above the circle. Use it to take it.
- detect: `flag_set( "skq_p2t1_2" )` mpq:220. init mpq:23.
- marker: same ring struct as step 7. The key appears at `ring.origin + (0,0,32)` (mpq:202-203).
- status: VERIFIED. Script mpq:200-220, mpq:257-261, mpq:2619-2718. Web: "fight a group of zombies and then ninjas ... you'll earn a key" (Escapist summary).

#### 9. open_locker
- objective: Open the subway locker
- location: Subway lockers near Bang Bangs
- hint_minimal: The key fits a locker underground.
- hint_standard: Take the key to the subway lockers by the Bang Bangs perk machine and open the locker.
- hint_detailed: Go to the subway station with Bang Bangs. On the lockers there, use the locker. It swings open (it reads SOULKEY inside, per guides) and the symbol puzzle starts.
- detect: `flag_set( "skq_p2t1_3" )` mpq:655. init mpq:24.
- marker: `getent( "subway_locker_door", "targetname" )` mpq:628. The use point is `getstruct( door.target, "targetname" )` mpq:629.
- status: VERIFIED. Script mpq:624-656. Web: "go to the Bang Bangs subway station and look for the lockers on the right side ... the inside says SOULKEY" (summary).

#### 10. shoot_four_symbols
- objective: Shoot the 4 symbols in order
- location: Dojo, Disco Inferno, Deadeye Dewdrops
- hint_minimal: Four painted symbols must be shot in the right order.
- hint_standard: Shoot the four white Chinese symbols in order. A wrong symbol buzzes and resets the order.
- hint_detailed: Order from guides: 1) right of the Black Cat Dojo, 2) Disco Inferno restroom stall, 3) by the statue at Deadeye Dewdrops, 4) directly right of the 3rd. A wrong or repeated hit buzzes and you restart from 1.
- detect: `level notify( "active_word_done" )` mpq:759.
- marker: `getstructarray( "graffiti_check_struct", "targetname" )` mpq:770. `script_noteworthy` is `chinese_symbol_0`..`chinese_symbol_3`, and the order logic is mpq:678-753. Clip ents: `getent( "graffiti_quest_clip" / "graffiti_quest_fail_clip" / "graffiti_quest_clip_alt", "targetname" )` mpq:662-664.
- status: VERIFIED for the mechanic. Script accepts symbol_0 -> 1 -> 2 -> 3, or symbol_0 -> 1 -> 3 -> "alt" clip (mpq:719-752). Web gives the four locations (Accelerated Ideas / Gameranx summaries). Mapping web locations to `chinese_symbol_N` is NEEDS RESEARCH, as is what the alt clip is.

#### 11. summon_rk_eye
- objective: Use the Rat King symbol
- location: Outside the Black Cat Dojo
- hint_minimal: A Rat King symbol now glows on the ground.
- hint_standard: A gong sounds and a Rat King symbol appears on the ground outside the Dojo. Use it to summon the Rat King.
- hint_detailed: After the 4th symbol a gong plays and a glowing Rat King glyph appears on the ground outside the Black Cat Dojo. Stand on it and press use. The Rat King appears; get ready to fight.
- detect: `flag_set( "skq_p2t1_4" )` mpq:2998 (`rk_symbol_handler( "rk_symbol_punk_streets", "skq_p2t1_4" )` called mpq:760). init mpq:25.
- marker: `getstruct( "rk_symbol_punk_streets", "targetname" )` mpq:2981.
- status: VERIFIED. Script mpq:760 and mpq:2978-2999. Web: "A Rat King symbol will appear on the ground outside of the Dojo. Interact with the symbol to spawn in the Rat King" (summary).

#### 12. fight_rk_eye
- objective: Drive off the Rat King
- location: Outside the Black Cat Dojo
- hint_minimal: Damage the Rat King until he flees.
- hint_standard: Deal enough damage to the Rat King to make him retreat. He blocks, teleports, melees and summons rats.
- hint_detailed: The Rat King has 1000 health here. He blocks often (keep shooting through it), teleports, melees and summons. Bring his health to 0: he fakes death and leaves, dropping the Rat King's Eye.
- detect: entity notify `level.rat_king notify( "fake_death" )` mp/agents/ratking/ratking_agent.gsc:235, waited at mpq:915. After that, `level.rat_king` is undefined (mpq:1663). No level flag.
- marker: the boss entity is `level.rat_king`. Its spawn point is `getstruct( "p2t1_4", "script_noteworthy" )` mpq:819.
- status: VERIFIED. Script mpq:816-835 and mpq:911-941. Web: "Inflict as much damage as possible to take him down and claim the Rat Kings eyeball" (summary).

#### 13. take_eye
- objective: Pick up the Rat King's Eye
- location: Where the Rat King fell
- hint_minimal: He left something behind.
- hint_standard: Pick up the floating Rat King's Eye where he fell. It becomes a power that reveals hidden symbols for 5 s.
- hint_detailed: Use the floating relic. Each player can take an Eye; it becomes your secondary power. Using it makes you "wear" the eye for 5 seconds, which reveals hidden Rat King symbols. You cannot take it while in Chi mode or downed.
- detect: `flag_set( "eye_picked" )` mpq:1811. init mpq:15.
- marker: no named struct. The relic spawns at `getrelicspawnpos()` mpq:1718-1730 (based on `level.rat_king_death_pos`, set at ratking_agent.gsc:230). It is a spawned struct with `script_noteworthy = "mpq_relics"` (mpq:1668), added to the interaction list.
- status: VERIFIED. Script mpq:1659-1690, mpq:1759-1826, cp/cp_weapon.gsc:402-445. Web: "Rat King ... drops a special Eye item ... reveal secret Rat King symbols" (summary).

#### 14. talk_pam_brain_quest
- objective: Return to Pam Grier
- location: Black Cat Dojo
- hint_minimal: Pam wants to hear about the Eye.
- hint_standard: Go back to Pam Grier and talk to her. She asks for the Rat King's Brain, and the hidden symbols start appearing.
- hint_detailed: Talk to Pam Grier in the Dojo. The script does not check that the Eye was picked up, but you need the Eye power for the next step. Pam asks for the Brain and the eye-only symbol hunt begins.
- detect: `flag_set( "skq_p2t1_5" )` kfm:1291, then `flag_set( "skq_p2t2_0" )` mpq:970. init mpq:26/27.
- marker: `getent( "ma_trainer", "targetname" )` kfm:1045.
- status: VERIFIED. Script mpq:829-831 and mpq:955-971. Web: "make sure you talk to pam after picking up the eye to progress to the next step" (summary).

### Phase 2, task 2: Rat King's Brain

#### 15. eye_symbol_hunt
- objective: Find symbols with the Eye
- location: Around the map (random spots)
- hint_minimal: Some symbols can only be seen through the Rat King's Eye.
- hint_standard: Activate the Eye to reveal a hidden symbol, then shoot it while the Eye is active. Each hit turns a phone booth red; repeat until one is left.
- hint_detailed: Use the Eye power (5 s) to see the current orange symbol at a random spot, and shoot it while the Eye is active. Each hit turns one phone booth red. The next symbol then spawns elsewhere. Repeat until only one booth is left; it starts ringing.
- detect: `flag_set( "skq_p2t2_1" )` mpq:1013. Each symbol hit: `level notify( "symbol_updated" )` mpq:1058. init mpq:28.
- marker: `level.active_hunt_symbol`, set mpq:994/1007 from `getstructarray( "symbol_point", "targetname" )` mpq:989. Shooting is done on `getent( "symbol_point_clip", "targetname" )` mpq:1029, which is moved to the symbol (mpq:1032).
- status: VERIFIED. Script mpq:984-1107 (hit counts only if the attacker has `wearing_rat_king_eye`, mpq:1042). Web: "orange Rat King symbols ... shoot them ... only one spawns at a time and their locations seem random"; "phone booths ... turn red for every successful symbol hit" (summaries). Symbol count = number of phone booths - 1 (mpq:996-1008). The web says six, which is NEEDS RESEARCH, as is the booth count.

#### 16. answer_phone
- objective: Answer the ringing phone
- location: The ringing phone booth
- hint_minimal: Something is ringing. Listen carefully.
- hint_standard: Answer the last (still lit) phone booth that is ringing and listen to the whole Morse code message. It is a 3-digit number.
- hint_detailed: Use the ringing booth and stay still until it ends. 3 digits, 5 tones each (dot short, dash long): 1 .---- 2 ..--- 3 ...-- 4 ....- 5 ..... 6 -.... 7 --... 8 ---.. 9 ----. 0 -----. It is 281, 407, 420, 596, 713 or 818.
- detect: `flag_set( "morse_code_heard" )` pb:1088, then `flag_set( "skq_p2t2_3" )` mpq:1158. Answering: `level notify( "puzzle_phone_answered" )` pb:935. init mpq:42 / mpq:30.
- marker: `level.phone_puzzle_phone` (mpq:1011, or mpq:1139 on reset). It is a struct from `getstructarray( "phonebooth", "script_noteworthy" )` mpq:988.
- status: VERIFIED. Script pb:425-447, pb:933-1103, mpq:1130-1178. Web: "Answering a ringing phone gives a message in morse code" (summary). The digit table is SCRIPT ONLY (pb:1013-1081), and so is the number list (pb:996 / mpq:1296).

#### 17. take_flyer
- objective: Take the matching flyer
- location: Film flyer posters (see open questions)
- hint_minimal: One flyer carries the number you just heard.
- hint_standard: Find the movie flyer whose registration number matches the Morse code and take it. The wrong flyer resets the symbol hunt.
- hint_detailed: Several flyers have 3-digit registration decals (281, 407, 420, 596, 713, 818). Take only the one that matches the Morse number. Taking a wrong one restarts the hunt with a new number: red booths reset and the symbols return.
- detect: `flag_set( "correct_poster_got" )` mpq:1354. init mpq:52. Failure: `level notify( "puzzle_phone_reset" )` mpq:1113 and `flag_clear( "skq_p2t2_1" )` mpq:1114, so the tracker must go back to step 15.
- marker: `getentarray( "mpq_poster_model", "targetname" )` mpq:1282. Select the ent with `.model_num == level.morse_number` (mpq:1298, mpq:1305).
- status: SCRIPT ONLY (mpq:1180-1359). The web summaries never described this step. The poster locations are NEEDS RESEARCH.

#### 18. roof_power
- objective: Turn on the Disco roof power
- location: Disco rooftop power switch
- hint_minimal: The rooftop spotlight needs power.
- hint_standard: Turn on the power switch that powers the Disco rooftop. The spotlight there lights up when it is on.
- hint_detailed: Pull the power lever for the "disco_roof" area. It can be done any time before this step, and many players do it early with the other three switches. When it is on, the rooftop spotlight switches on and flares.
- detect: `flag_set( "disco_roof power_on" )` zp:131 (`generic_generator`). init mpq:20.
- marker: `level.generators = getstructarray( "generator", "script_noteworthy" )` zp:8. Pick the one whose `strtok( script_parameters, "," )` contains `"disco_roof"` (zp:106-131).
- status: SCRIPT ONLY for the requirement (mpq:1214, mpq:1232). Web: "four different switches to turn on the power" (SegmentNext summary). Which switch is the disco_roof one is NEEDS RESEARCH.

#### 19. place_flyer_spotlight
- objective: Put the flyer on the spotlight
- location: Rooftop spotlight
- hint_minimal: The flyer belongs on the big rooftop light.
- hint_standard: With the roof power on, take the flyer to the rooftop spotlight and use it. The light then projects an X somewhere.
- hint_detailed: Go to the rooftop searchlight (it glows once roof power is on) and press use to place the torn flyer on it. The light dims and an X mark appears where the beam points. A rat waits there.
- detect: manual. The only signal is the entity notify "trigger" on the poster ent (mpq:1216, mpq:1249). No level flag.
- marker: `getent( "spotlight_light", "targetname" )` mpq:1185. The flyer slot is `getent( light.target, "targetname" )` mpq:1186.
- status: SCRIPT ONLY (mpq:1214-1219, mpq:1229-1275). The spotlight's area name is NEEDS RESEARCH.

#### 20. hit_rat_at_x
- objective: Hit the rat at the X
- location: Where the spotlight X points
- hint_minimal: Something is waiting where the X is.
- hint_standard: Go to the spotlight's X mark and damage the rat sitting there. A grenade or any damage works.
- hint_detailed: A rat model sits at the X spot ("nade_toss_point"). Any damage kills it; the script name suggests a thrown grenade. This triggers a ninja wave on the Disco roof.
- detect: `flag_set( "skq_p2t2_4" )` mpq:1226. init mpq:31.
- marker: `getstruct( "nade_toss_point", "targetname" )` mpq:1220. The X FX is at `getstruct( "spotlight_x_marker", "targetname" )` mpq:1257.
- status: SCRIPT ONLY (mpq:1220-1226). The X location is NEEDS RESEARCH.

#### 21. roof_ninjas
- objective: Defeat the ninja wave
- location: Disco rooftop
- hint_minimal: Ninjas answer the call. Beat them.
- hint_standard: Ten karate-master ninjas spawn around the Disco roof. Kill them all to continue.
- hint_detailed: 10 ninja zombies spawn on navmesh points within about 1024 units of the roof spawn point. Kill all of them; the wave also ends after 300 s. The rooftop letter cipher then starts.
- detect: `flag_set( "skq_p2t2_5" )` mpq:1373. init mpq:32.
- marker: `getstruct( "kf_zombies_disco_roof", "targetname" )` mpq:1370.
- status: SCRIPT ONLY (mpq:1366-1374, mpq:2619-2718).

#### 22. roof_cipher_word
- objective: Spell the cipher word
- location: Rooftop letter puzzle
- hint_minimal: A word's first letter appears. Shoot the right glyph next.
- hint_standard: A word is spelled one letter at a time. Each turn cipher glyphs appear; shoot the one that is the next letter. A miss buzzes and gives a new word.
- hint_detailed: The first letter shows on the board. For each following letter, glyphs (one per slot) appear; one is the correct letter in cipher form. Shoot it. A wrong glyph resets to a new word. Words are from 7 themed lists (map names, Willard, etc.); there is a rare joke word, "savagemadethis".
- detect: manual. There is no flag; completion is when `rk_symbol_handler( "rk_symbol_punk_rooftops", ... )` starts (mpq:1484), and `level.rooftopcypherglyphs` becomes undefined (mpq:1483).
- marker: `getstruct( "letter_puzzle_solve_struct", "targetname" )` mpq:1388 (the board, chained through `.target`). The glyph slots are `getstructarray( "letter_puzzle_struct", "script_noteworthy" )` mpq:1511 and the shot clip is `getent( "letter_puzzle_clip", "targetname" )` mpq:1512.
- status: SCRIPT ONLY (mpq:1376-1596, mpq:2833-2871). How the cipher glyph art maps to letters cannot be shown from script (they are FX `cipher_alphabet_<letter>`), so the readable cipher key is NEEDS RESEARCH.

#### 23. summon_rk_brain
- objective: Use the Rat King symbol
- location: Rooftops
- hint_minimal: Another Rat King symbol has appeared.
- hint_standard: After the word, a gong sounds and a Rat King symbol appears on the rooftops. Use it to summon him again.
- hint_detailed: Find the glowing Rat King glyph on the ground in the rooftops area (script name "rk_symbol_punk_rooftops") and press use. The Rat King spawns.
- detect: `flag_set( "skq_p2t2_6" )` mpq:2998 (via mpq:1484). init mpq:33.
- marker: `getstruct( "rk_symbol_punk_rooftops", "targetname" )` mpq:2981.
- status: SCRIPT ONLY. The area name comes from the struct name; the exact spot is NEEDS RESEARCH.

#### 24. fight_rk_brain
- objective: Drive off the Rat King
- location: Rooftops
- hint_minimal: He is back. Drive him off again.
- hint_standard: Damage the Rat King until he retreats. This time he throws his shield, teleports, melees and summons.
- hint_detailed: The Rat King has 1000 health. He uses shield throws, melee, teleport and summon, and does not block. Bring him to 0 and he fakes death, dropping the Rat King's Brain.
- detect: entity notify `"fake_death"` on `level.rat_king` (ratking_agent.gsc:235, waited mpq:1623 -> mpq:915).
- marker: `level.rat_king`. Spawn point: `getstruct( "p2t2_6", "script_noteworthy" )` mpq:1601.
- status: SCRIPT ONLY (mpq:1598-1629, mpq:1848-1868).

#### 25. take_brain
- objective: Pick up the Rat King's Brain
- location: Where the Rat King fell
- hint_minimal: Collect what he dropped.
- hint_standard: Pick up the Rat King's Brain relic where he fell.
- hint_detailed: Use the floating Brain relic. Only one is needed. It vanishes after the first pickup and goes into the quest inventory.
- detect: `flag_set( "brain_picked" )` mpq:1772. init mpq:17.
- marker: dynamic, same as step 13 (`getrelicspawnpos()` mpq:1718; struct `script_noteworthy "mpq_relics"`).
- status: VERIFIED for the item existing (web lists "Rat King's Brain" in the inventory). The pickup mechanics are SCRIPT ONLY (mpq:1769-1785).

#### 26. talk_pam_heart_quest
- objective: Return to Pam Grier
- location: Black Cat Dojo
- hint_minimal: Bring news of the Brain to Pam.
- hint_standard: Talk to Pam Grier again. She asks for the Rat King's Heart. A three-round countdown starts.
- hint_detailed: Talk to Pam Grier. She asks for the Heart. A countdown (4, 3, 2, 1) appears on the HUD and drops at each new round. After 3 rounds plus about 35 s, the Missing Reel starts.
- detect: `flag_set( "skq_p2t2_7" )` kfm:1296, then `flag_set( "skq_p2t3_0" )` mpq:1883. init mpq:34/35.
- marker: `getent( "ma_trainer", "targetname" )` kfm:1045.
- status: SCRIPT ONLY (mpq:1870-1884, kfm:1294-1297).

### Phase 2, task 3: Rat King's Heart

#### 27. wait_three_rounds
- objective: Survive 3 more rounds
- location: Anywhere
- hint_minimal: Something will happen in a few rounds.
- hint_standard: Survive three more rounds. The HUD counter counts down. Do not be mid fast-travel or in a minigame when it ends.
- hint_detailed: Play 3 round changes (the HUD counter goes 4 -> 1), then about 35 s more. The event waits while anyone is fast-travelling, off-grid, using a clock interaction or in Ghosts n' Skulls. Then the "Missing Reel" video plays and everyone is teleported.
- detect: manual. Countdown omnvar `zom_escape_gate_score` (mpq:2905, mpq:2919) via `wait_for_wave_change( 3, 1 )` mpq:1920. No flag at the end of the wait.
- marker: none.
- status: SCRIPT ONLY (mpq:1910-1958, mpq:2895-2922).

#### 28. survive_missing_reel
- objective: Survive the Missing Reel
- location: Missing Reel set (teleported)
- hint_minimal: You have been pulled into a lost film. Fight.
- hint_standard: After the video you are teleported. Kill the zombies around you and avoid the fire. It ends when they die or after 60 s.
- hint_detailed: Each player is placed at a reel spawn spot. Zombies spawn around each player (6 minus half the player count each). Touching the fire trigger kills you. Kill them all, or survive 60 s. The round number jumps by 2-3.
- detect: `flag_set( "cleanup_reel_assets" )` mpq:1982 (init mpq:46). `flag_set( "reel_zoms_beaten" )` mpq:2108 if every zombie was killed (init mpq:45).
- marker: `getstructarray( "missing_reel_tp_struct", "targetname" )` mpq:1950. The fire trigger is `getent( "missing_reel_fire_trig", "targetname" )` mpq:1951.
- status: SCRIPT ONLY (mpq:1950-1994, mpq:2019-2184). The in-world area name is NEEDS RESEARCH.

#### 29. take_turnstile_arm
- objective: Grab the turnstile arm
- location: Missing Reel set
- hint_minimal: Something spinning was left behind.
- hint_standard: A spinning turnstile arm appears at one of the reel spawn spots. Pick it up.
- hint_detailed: When the reel fight ends, a glowing, spinning turnstile arm appears at one of the player spawn spots of the reel scene (random). Press use on it to take it.
- detect: `flag_set( "skq_p2t3_1" )` mpq:2016. init mpq:36.
- marker: none exact. It is placed at a random element of `getstructarray( "missing_reel_tp_struct", "targetname" )` (mpq:1995-1997) and not stored on `level`; the struct list from mpq:1950 gives the candidates.
- status: SCRIPT ONLY (mpq:1995-2016).

#### 30. fix_turnstile
- objective: Fix the subway turnstile
- location: Subway turnstile (broken arm)
- hint_minimal: The arm belongs on a broken subway turnstile.
- hint_standard: Find the subway turnstile with the missing arm and use it to attach the arm. A window cover nearby slides up.
- hint_detailed: Use the subway turnstile that is missing an arm. It spins, and you get the "Message Received" achievement. A metal window cover nearby rises and shows a glowing symbol.
- detect: `flag_set( "turnstile_done" )` mpq:2244. init mpq:43.
- marker: `getstruct( "turnstile", "script_noteworthy" )` mpq:2221.
- status: SCRIPT ONLY (mpq:2219-2252). The script awards achievement `MESSAGE_RECEIVED` here (mpq:2247). Web: the achievement "Message Received" exists ("The end of the longest journey is a single step", PSN log summary) but no source ties it to the turnstile. Which subway it is: NEEDS RESEARCH.

#### 31. shoot_window_glyph
- objective: Shoot the glyph in the window
- location: Near the subway turnstile
- hint_minimal: Look behind the window cover that just opened.
- hint_standard: Shoot the glowing symbol revealed behind the raised window cover. The cover drops back down.
- hint_detailed: After the turnstile, the window cover moves up over about 8 s and a glyph glows behind it. Damage it with anything. The cover slams shut and a gong-marked kill-circle chain starts.
- detect: `flag_set( "turnstyle_glyph_hit" )` mpq:2214, then `flag_set( "skq_p2t3_2" )` mpq:2200. init mpq:44 / mpq:37.
- marker: `getstruct( "window_cover_struct", "targetname" )` mpq:2205. The cover is `getent( "window_cover", "targetname" )` mpq:2189.
- status: SCRIPT ONLY (mpq:2186-2217).

#### 32. six_kill_circles
- objective: Fill 6 kill circles
- location: Circles around the map (random)
- hint_minimal: Kill zombies inside each circle as it appears.
- hint_standard: A glowing circle appears. Kill 6-9 zombies inside it, then the next one appears elsewhere. Clear 6 circles in total.
- hint_detailed: Ring 1 is at a fixed spot, then 5 more at random spots. Each needs 6-9 kills (random) within about 150 units of its centre. A gong plays when all 6 are done.
- detect: `level notify( "task3RingDone" )` mpq:2269, then `flag_set( "skq_p2t3_3" )` mpq:2275. init mpq:38.
- marker: `level.task3ring_fxstruct`. The first ring is `getstruct( "task_3_ring_struct", "targetname" )` mpq:2257; the next ones come from `getstructarray( "task_3_ring_struct_rand", "targetname" )` mpq:2280 (set mpq:2287).
- status: SCRIPT ONLY (mpq:2254-2291, mpq:223-245).

#### 33. start_disco_turntable
- objective: Spin the disco turntable
- location: Disco Inferno (turntable)
- hint_minimal: The record is spinning. Put the needle on it.
- hint_standard: Use the spinning turntable to start "disco fever". A zombie with a disco-fever effect then appears.
- hint_detailed: After the circles, a turntable record starts rotating. Use it. This sets disco fever and spawns a dancing fever zombie at the disco spawn point.
- detect: `flag_set( "fever_started" )` mpq:2492. init mpq:47.
- marker: `getstruct( "disco_fever_interact", "script_noteworthy" )` mpq:2454.
- status: SCRIPT ONLY (mpq:2452-2493). Turntable in the Disco Inferno is NEEDS RESEARCH; the fever kills happen in the Disco per Gameranx.

#### 34. disco_fever_kills
- objective: Kill the disco ball zombies
- location: Disco Inferno dance floor
- hint_minimal: Only the dancing zombie with the disco ball matters.
- hint_standard: Kill the disco-ball zombie. It jumps to the nearest zombie on the dance floor; kill that one too. Keep about 10 kills chained.
- hint_detailed: Lure zombies onto the dance floor and kill only the one wearing the disco ball. On death it passes to the closest zombie on the floor. If none is on the floor, the chain resets after 10 s. Chain 10 kills to finish.
- detect: `flag_set( "skq_p2t3_4" )` mpq:2386. init mpq:39.
- marker: `getstruct( "disco_fever_spawn_struct", "targetname" )` mpq:2337. The floor volume is `getent( "disco_fever_vol", "targetname" )` mpq:2410.
- status: VERIFIED. Script mpq:2330-2450. Web (Gameranx summary): "Enter the Disco Inferno to find a zombie with a Disco Ball ... ONLY KILL ZOMBIES WITH THE DISCO BALL ... it will jump to another zombie. Keep killing ... until it completely stops spawning."

#### 35. summon_rk_heart
- objective: Use the Rat King symbol
- location: Disco streets
- hint_minimal: The last Rat King symbol is waiting.
- hint_standard: A gong sounds and a Rat King symbol appears in the disco streets area. Use it for the final relic fight.
- hint_detailed: Find the glowing Rat King glyph on the ground (script name "rk_symbol_disco_streets") and press use. The Rat King spawns, stronger this time.
- detect: `flag_set( "skq_p2t3_5" )` mpq:2998 (via mpq:2498). init mpq:40.
- marker: `getstruct( "rk_symbol_disco_streets", "targetname" )` mpq:2981.
- status: SCRIPT ONLY. The exact spot is NEEDS RESEARCH.

#### 36. fight_rk_heart
- objective: Drive off the Rat King
- location: Disco streets
- hint_minimal: He is tougher now. Drive him off a third time.
- hint_standard: Damage the Rat King until he retreats. He has 2500 health here and uses staff stomps and staff projectiles.
- hint_detailed: The Rat King has 2500 health. He uses staff projectiles, staff stomp, melee, summon and teleport. Keep distance from the stomps. At 0 he fakes death and drops the Rat King's Heart.
- detect: entity notify `"fake_death"` on `level.rat_king` (ratking_agent.gsc:235; waited mpq:2525 -> mpq:915).
- marker: `level.rat_king`. Spawn point: `getstruct( "p2t3_5", "script_noteworthy" )` mpq:2503.
- status: SCRIPT ONLY (mpq:2501-2553).

#### 37. take_heart
- objective: Pick up the Rat King's Heart
- location: Where the Rat King fell
- hint_minimal: Take what he left behind.
- hint_standard: Pick up the Rat King's Heart relic. Each player can take one; it becomes a power.
- hint_detailed: Use the Heart relic. Each player can take it; it gives the "power_heart" primary power. You cannot take it while in Chi mode or downed.
- detect: `flag_set( "heart_picked" )` mpq:1789. init mpq:16.
- marker: dynamic, same as step 13.
- status: VERIFIED for the item (web summary: the map's lethal grenade is "the Rat King's Heart"; script gives `power_heart` as a primary power, mpq:1803). The pickup mechanics are SCRIPT ONLY (mpq:1786-1807).

#### 38. talk_pam_final
- objective: Bring the Heart to Pam Grier
- location: Black Cat Dojo
- hint_minimal: Pam has one last thing to say.
- hint_standard: Talk to Pam Grier one last time. She sends you to face the Rat King in his lair.
- hint_detailed: Talk to Pam Grier. She plays the final Rat King line, and the lair entrance (the sewage pool trigger) becomes the fight starter.
- detect: `flag_set( "skq_p2t3_6" )` kfm:1301 (`completephase3`). init mpq:41.
- marker: `getent( "ma_trainer", "targetname" )` kfm:1045.
- status: SCRIPT ONLY (kfm:1299-1311, mpq:2555-2559).

### Phase 3: final fight

#### 39. enter_rk_lair
- objective: Enter the Rat King's lair
- location: Rat King's Lair (sewers)
- hint_minimal: Face him where he lives.
- hint_standard: Go to the Rat King's lair in the sewers and step into the sewage pool. Everyone is pulled into the boss arena.
- hint_detailed: Make sure nobody is fast-travelling, rewinding or off-grid, and no clock interaction is active. Then step into the sewage pool in the Rat King's lair. The screen fades to black and all players are placed in the arena.
- detect: `flag_set( "skq_phase_3" )` mpq:2610. init mpq:19. The fight start that follows is in section C.
- marker: `getent( "slime_pool", "targetname" )` mpq:2564 (the same trigger is used for the arena sewage, rkf:1522).
- status: VERIFIED for the place (web: the final boss fight is in the Rat King's lair; lair = sewer area). The sewage-pool trigger is SCRIPT ONLY. The exact entry route to the lair is NEEDS RESEARCH.

#### 40. defeat_rat_king
- objective: Defeat the Rat King
- location: Rat King's Lair (arena)
- hint_minimal: Use his own relics against him.
- hint_standard: Damage the Rat King. When he hides on his platform, pick a relic, place it at the centre and finish its trial. Repeat 3 times, then kill him.
- hint_detailed: 7 stages: damage to 75%; relic 1; damage to 50%; relic 2; damage to 25%; relic 3; kill. Relic trials: Eye = shoot glowing targets while they pulse; Heart = kill zombies on the sludge pools; Brain = see section C.
- detect: `flag_set( "rk_fight_ended" )` rkf:1142 (init rkf:6), followed by `level notify( "rk_fight_completed" )` rkf:1161. Kill: `level notify( "rat_king_killed", origin )` cp/maps/cp_disco/ratking_damage.gsc:317. Details are in section C.
- marker: `level.rat_king`. Arena centre: `getstruct( "rk_arena_center", "script_noteworthy" )` rkf:1328.
- status: VERIFIED for the overall structure. Web: "fighting the Rat King ... ultimately beating him in a three part boss battle"; heart step "kill zombies over the acid spots" (speedrun.com). Stage logic is from script, rkf:689-1162.

#### 41. take_soul_key
- objective: Pick up the Soul Key
- location: Rat King's Lair (arena)
- hint_minimal: He dropped something important.
- hint_standard: After the outro video, pick up the Soul Key the Rat King dropped.
- hint_detailed: After the ending video (about 55 s), the Soul Key floats where the Rat King died (or on the arena floor if he died on the rafters). Pick it up for the Soul Key and the Pest Control achievement.
- detect: manual. There is no flag. On pickup: `setplayerdata( "cp", "haveSoulKeys", "soul_key_3", 1 )` rkf:1295 and achievement `PEST_CONTROL` rkf:1296. The pickup entity is deleted at rkf:1287.
- marker: none named. It is a spawned model `tag_origin_soul_key` at the Rat King's death origin + (0,0,32), or `(-873, 1821, 231)` if that z > 283 (rkf:1157, rkf:1230-1252). It is not stored on `level`.
- status: SCRIPT ONLY for the mechanics. Web: the egg's goal is the third Soul Key piece (Accelerated Ideas summary).

---------------------------------------------------------------------------------------------------

## C. Boss fight (final Rat King fight)

- Preparation (script facts):
  - Pickup and powerup drops stop at the fight start (`flag_clear( "pillage_enabled" )` rkf:329, `flag_clear( "zombie_drop_powerups" )` rkf:330). Stock up before stepping into the pool.
  - Every Chi style is usable. The speedrun.com guide (summary) recommends dual-wield Kendall-style weapons, Jugger-Nog, Bang Bangs, Quickies and Deadeye Dewdrops, and says to bring any Chi because only the shuriken is used on the Rat King during the brain trial. This is web advice and is NOT script-verified.
  - In the arena there are breakable perk crates (`rk_perk_crate`, rkf:37-100) and candy perk boxes (`perk_candy_box`, rkf:102-270). Pam Grier joins as an AI ally (`spawnpamgrier` rkf:410-423) and can revive players (`revive_player` toggle, rkf:745). Web (summary) agrees: "Pam Grier will show up herself to help you in the boss fight, providing never-ending revives". Gourds respawn (rkf:386). Lost-and-found is moved into the arena (rkf:387, rkf:561).
- Start:
  - Trigger: `flag_set( "skq_phase_3" )` mpq:2610, then `start_rk_fight()` mpq:2616.
  - `flag_set( "rk_fight_started" )` rkf:328 (init rkf:7). Players are moved to `getstructarray( "rk_player_spawns", "script_noteworthy" )` rkf:339, and there is a black-screen intro.
  - `level notify( "rk_intro_done" )` rkf:494 (rkf:470 in direct-boss mode) marks the boss spawning. The boss spawns at the `rat_king_spawner` closest to (-628.8, 1422.4, 178) (rkf:381-384).
- Stage tracking: `level.rat_king_stage` runs 0..6 (rkf:24-25, incremented in `increaserkstage` rkf:701-705). It is a reliable per-stage progress value.
  1. Stage 1 (`runrkstage1` rkf:712): damage the Rat King to 75% (`watchfordamagestagecomplete( 0.75, 0.85 )` rkf:730). A gong marks completion (rkf:2827-2831).
  2. Stage 2 (rkf:752): relic trial. `flag_set( "rk_fight_relic_stage" )` rkf:778. The Rat King goes to his platform and takes no damage (rkf:1393-1394). Three relics sit at `getstructarray( "rk_relic_pos", "script_noteworthy" )` rkf:1343, randomly assigned heart, brain or eye (rkf:1344-1349). Pick one up (`pickuprkrelic` rkf:2385, `level notify( "relic_selected" )` rkf:2388; the flag is cleared at rkf:2387). Place it on the centre (`getstruct( "rk_arena_center", "script_noteworthy" )` rkf:1328; `level notify( <relic> + "_relic_placed_in_center" )` rkf:2645; `flag_set( "relic_active" )` rkf:2646). Then complete that relic's trial. End: `level notify( "relic_quest_completed" )`, handled at rkf:2796-2824 (max ammo try plus a gong).
  3. Stage 3 (rkf:857): damage to 50% (rkf:873). Ninjas are summoned.
  4. Stage 4 (rkf:973): second relic trial (flag rkf:986).
  5. Stage 5 (rkf:1007): damage to 25% (rkf:1022).
  6. Stage 6 (rkf:1040): third relic trial (flag rkf:1053).
  7. Stage 7 (rkf:1066): kill him. `level waittill( "rat_king_killed" )` rkf:1113, notify sent at cp/maps/cp_disco/ratking_damage.gsc:317.
- Relic trials (script):
  - EYE (`runeyerelicquest` rkf:1983-2033): target models appear at `getstructarray( "rk_eye_damage_structs", "targetname" )` rkf:2009. There are 12 active solo and 20 in co-op (rkf:2094-2102). Targets "pulse" active for 5 s, then off for 5 s (rkf:2063-2084; `flag "eye_active"` rkf:2066/2075), and the cycle restarts when someone uses the Eye power (rkf:2035-2046). Shoot active targets only while they are lit. Shooting while unlit re-activates a destroyed target (rkf:2333-2337). It is done when all are destroyed (rkf:2314-2327).
  - HEART (`runheartrelicquest` rkf:1440, `startheartquestfunctionality` rkf:1518-1557): sludge pools appear at `getstructarray( "sewage_pool_loc", "script_noteworthy" )` rkf:1521. A pool clears when a player kills a zombie within 128 units of it (fan-trap kills do not count; rkf:1595-1629). Standing in sludge does 20 damage per second, unless you touched the arena water (`getent( "arena_water", "targetname" )` rkf:1526) in the last 5 s (rkf:1559-1582, rkf:1631-1672). After any pool is cleaned, if any remain, all pools refill after 35 s co-op / 50 s solo (rkf:1704-1745). Web (speedrun.com): "Kill zombies over the acid spots on the outer ring of the sewers until you hear a gong". VERIFIED.
  - BRAIN (`runbrainrelicquest` rkf:1748-1819): up to 4 zombies at a time (red/"turned" eyes) are sent to `getstructarray( "brain_targets", "targetname" )` around the centre (rkf:1875-1973). The Rat King prioritises `attack_zombies` (rkf:1799-1801). The trial ends when attracted zombies have been within 100 units of the centre for a running total of 100 one-second checks (`waitforbraindestroyed` rkf:1829-1855). So the script expects attracted zombies to REACH the brain, and the Rat King tries to kill them. The intended player strategy is NEEDS RESEARCH: speedrun.com hints at using the shuriken on the Rat King during this step.
- End:
  - `flag_clear( "rk_fight_started" )` rkf:1139
  - `flag_set( "rk_fight_ended" )` rkf:1142
  - outro bink `zombies_cp_disco_outro` (55 s) rkf:1156
  - Soul Key drop rkf:1157
  - `level notify( "rk_fight_completed" )` rkf:1161
  - waves resume 60 s later (rkf:1308-1317)
  - Merit `mt_dlc2_rat_king` for all players (rkf:1126). Achievement `EXTERMINATOR` only for the Pam Grier character, p5_ (rkf:1128-1129).
- Failure: there is no explicit fail path in rkf. Downed players respawn in the arena (`respawninrkarena` rkf:554-559). Speedrun.com claims "if ninjas spawn before the final Rat King, the run ends"; this is NOT found in script and is NEEDS RESEARCH.

## D. Final objective and completion detection

- Final objective: "Pick up the Soul Key" (step 41) after "Defeat the Rat King" (step 40).
- Most reliable quest-complete signal: `flag "rk_fight_ended"` (set rkf:1142, init rkf:6), or `level notify( "rk_fight_completed" )` rkf:1161. Both happen only after the Rat King's real death in the final fight (`rat_king_killed`, ratking_damage.gsc:317).
- The Soul Key pickup itself has no flag: it is a `trigger` on a spawned model, rkf:1266-1288. Mark it complete manually, or by polling for the `tag_origin_soul_key` model disappearing. The player data `haveSoulKeys/soul_key_3` is written at rkf:1295.
- Announcer lines afterwards (rkf:2894-2903: "ww_ratking_finaldeath", "soul_key_1", "ww_easteregg_complete") play 60 s after the fight from `delay_resume_wave_progression` rkf:1316.

## E. Open questions (NEEDS RESEARCH)

1. Locations that only map data (not GSC) can give, and that the web summaries did not cover:
   - rat cages
   - Missing Reel scene
   - subway turnstile (which subway)
   - window glyph
   - kill-circle spots
   - turntable
   - the three `rk_symbol_*` glyphs (only the first is web-confirmed as outside the Dojo)
   - Rat King lair entrance route
   - disco_roof power switch
   - rooftop spotlight
   - flyer posters
   - X spot
   Markers can still be placed at runtime from the struct/ent lookups listed above.
2. Mapping of web symbol locations (Dojo right side / restroom / Deadeye statue / right of 3rd) to `chinese_symbol_0..3`, and what the "alt" clip (mpq:741-753, mpq:800-814) represents.
3. Number of phone booths, which sets the number of eye symbols. The web says six symbols.
4. Readable key for the rooftop letter cipher (the glyphs are FX, `cipher_alphabet_<x>`).
5. Brain relic trial: the intended player action. See section C.
6. Whether rank-3 "Ultimate Chi" or the chi doors are needed to reach any quest location. One web summary says "To accomplish the EE we must unlock each of the Ultimate Chi abilities (rank 3) in order to open the secret doors"; the quest script itself never checks level 3.
7. The speedrun.com claim that ninjas spawning before the final stage ends the run is not seen in script.
8. Web says "first Rat King fight in the sewer area" (gameslearningsociety). The script spawns it at struct `p2t1_4`, after a glyph named `rk_symbol_punk_streets`, and other sources say "outside the Dojo". That struct's actual position is unconfirmed.
9. Step 4: what the level-1 Chi challenge is for each style (generic `solo_challenges` goal; not quest-specific).
10. Round-5 gate (kfm:1132) is script-only. One web summary instead says chi styles unlock after talking to Pam and "complete the first round of roller-skating zombies". In script the skater/goon event is random from wave 5 on (cp/maps/cp_disco/cp_disco.gsc:1516-1535) and is NOT checked by the quest. Trust the script: talk to Pam on round 5 or later.
