# Zombies in Spaceland (cp_zmb): Main Easter Egg, Guided Mode research

STATUS: COMPLETE (2026-10-13). Script-verified. Walkthrough cross-checks were limited to search-result summaries because WebFetch was unavailable. See E for open items.

All script paths are relative to
`.toolchain/src/iw7-gsc-dump/decompiled/scripts/`.
`DJ` = cp/maps/cp_zmb/cp_zmb_dj.gsc, `UFO` = cp/maps/cp_zmb/cp_zmb_ufo.gsc, `FT` = cp/zombies/zombie_fast_travel.gsc,
`QUEST` = cp/zombies/zombie_quest.gsc, `PWR` = cp/zombies/zombie_power.gsc.

---------------------------------------------------------------------------------------------------

## A. Quest overview

- **Name.** The game's internal quest line is `"ufo"` (DJ:8-19). Walkthroughs call it the Zombies in Spaceland main Easter egg (UFO / Soul Key Easter egg). The reward is the map's Soul Key.
- **Player count.** Solo and co-op (1-4) both work.
  - Script: the alien fight spawns one grey per player (UFO:771). The speaker "play together" step needs one tone press per player at the same moment (DJ:938).
  - Walkthroughs say it can be done solo, and that solo is often easier because the boss spawns one alien per player.
- **Prerequisites.** The script does not check these as quest steps, but the steps below depend on them:
  - Power. The DJ only appears after `"power_on"` or `"moon power_on"` (DJ:1697). Each portal powers on with its area's power (FT:80-156). The UFO model changes colour on each of 5 `"activate_power"` notifies (UFO:46-60).
  - Portals and the Pack-a-Punch room. The center portal opens to the hidden PaP room only after each of the 4 area portals (moon, europa, mars, arcade) has been used once (FT:555-566, FT:339-341, FT:568-616). Quest step 1 waits for the PaP portal to be used (flag `pap_portal_used`).
  - A Pack-a-Punched (level 2) wonder weapon: Shredder, Dischord, Face Melter or Headcutter (UFO:1755-1778). Wonder weapons only PaP after the alien fuses are inserted (cp/cp_weapon.gsc:4895-4914, flag `fuses_inserted`). Exceptions: the Ephemeral Enhancement card path `can_upgrade(w,1)` (cp/zombies/zombies_consumables.gsc:861) and Director's Cut.
- **Overview.** First power the park and link the four portals to the Pack-a-Punch room. Then:
  1. Collect the DJ's three lost items (radio/boombox, calculator, umbrella).
  2. Enter the PaP room and survive a round.
  3. Talk to the DJ (David Hasselhoff, at one of several "Cosmic Tunes" DJ windows). He hands over a frequency device ("SETI-COM" in walkthroughs). Place it where your screen shakes and defend it from zombies. Do this three times (60, 90 and 120 s).
  4. After another round, the DJ gives you tone speakers. Place them on the 4 golden platforms around the center portal and play them together.
  5. The UFO breaks out of the ice mountain, hovers over the center portal and plays a 4-colour sequence. Repeat it on the speakers, 3 times.
  6. The UFO beams down 50 clown suicide bombers, then the alien greys (boss) spawn.
  7. Kill the greys. They drop 2 alien fuses; put them in the Pack-a-Punch machine and PaP a wonder weapon.
  8. Shoot the 5 blue panels on the SPACELAND sign at the main gate with it. The sign fires an energy beam that destroys the UFO.
  9. Pick up the Soul Key, which drops near the center portal.
- **Sources.**
  - Script, primary: DJ, UFO, FT, QUEST, PWR, cp/cp_weapon.gsc, aitypes/zombie_grey/behaviors.gsc, mp/agents/zombie_grey/zombie_grey_agent.gsc, cp/maps/cp_zmb/cp_zmb.gsc.
  - Walkthrough search summaries: segmentnext.com, accelerated-ideas.com, gameranx.com, twinfinite.net, magicgameworld.com, shacknews.com ("How to Build the Seti-Com"), itechpost.com (item locations), callofduty.fandom.com (Alien (Infinite Warfare)). WebFetch was unavailable, so only search-result summaries were read.

### Universal auto-detect (all quest steps)

QUEST:21-36 `start_quest_line` runs the steps in order. It sets `level.zombie_current_quest_step_index["ufo"] = N` (QUEST:28) right before step N's init. So step N is done when the index becomes N+1.

Step 11 is the last one, so its completion is detected by flag `ufo_destroyed` instead (UFO:901), followed by `ufo_quest_finished` (DJ:760).

Stock step table (DJ:8-19):

| idx | init | wait | complete |
|----|------|------|----------|
| 0 | init_fetch_quest | do_fetch_quest | complete_fetch_quest |
| 1 | blank | wait_use_pap_portal | blank |
| 2 | init_first_speaker_defense | do_first_speaker_defend | blank |
| 3 | init_second_speaker_defense | do_second_speaker_defend | blank |
| 4 | init_third_speaker_defense | do_third_speaker_defend | complete_all_speaker_defense |
| 5 | blank | wait_one_wave | blank |
| 6 | init_get_tone_generator | get_tone_generator | complete_get_tone_generator |
| 7 | init_place_tone_generator | place_tone_generator | complete_place_tone_generator |
| 8 | init_match_ufo_tone | match_ufo_tone | complete_match_ufo_tone |
| 9 | blank | ufo_suicide_bomber | blank |
| 10 | init_alien_grey_fight | alien_grey_fight | complete_grey_fight |
| 11 | init_ufo_projectile_attack | ufo_projectile_attack | complete_ufo_projectile_attack |

---------------------------------------------------------------------------------------------------

## B. Ordered steps

(Guided steps. "Quest idx" maps each one to the stock quest-line index. P* = prerequisite, not a stock quest step.)

### P1. power_on
- objective: Turn on the power
- location: Power switches around the park
- hint_minimal: Spaceland needs power before anything else works.
- hint_standard: Find and pull the power switches in each area of the park. The UFO stuck in the ice mountain lights up more with each one.
- hint_detailed: Open the park and pull every power switch (5 in total). Each switch changes the frozen UFO's lights (blue, green, yellow, red, then fully lit). Power also brings the DJ to his window and powers the area portals.
- detect: level notify( "activate_power" ) at PWR:135, counted to 5 the way the stock script counts it in power_on_monitor (UFO:46-60). The flag `power_on` (PWR:9 init, PWR:123 set) is only set by a generator whose script_parameters include "power_all", so it is not a per-switch count.
- marker: getstructarray( "generator", "script_noteworthy" ) at PWR:8 (level.generators). Each struct gets `.powered_on = 1` when its switch is pulled (PWR:181) and loses it on power-off (PWR:70).
- status: VERIFIED. The script counts 5 activate_power notifies for the UFO; a walkthrough says to turn on five generators before Pack-a-Punch. Which switch is in which area is NEEDS RESEARCH (it lives in map entity data).

### P2. link_portals
- objective: Use all four area portals
- location: Portals in the four park areas
- hint_minimal: Each powered portal must be used once.
- hint_standard: Use the teleporter in each of the four areas once. When all four are linked, the center portal opens to the Pack-a-Punch room.
- hint_detailed: After powering an area, use its portal (it sends you to the center hub). Do this for all four area portals (internal names moon, europa, mars, arcade). Each first use lights one light on the center portal. With all four lit, the center portal opens to the hidden Pack-a-Punch room.
- detect: level._id_8E61 == 1 (FT:616) once _id_1BF8() returns true (FT:555-566, all non-main_street portals have `.used_once`, set at FT:341). level notify( "turn_on_portal_light", idx ) at FT:364 on each first use. No named flag.
- marker: level.fast_travel_spots[ area ] (FT:60). Its source is getstructarray( "fast_travel", "script_noteworthy" ) at FT:12. Pick entries where `.used_once` is not set. The center portal model is getent( "center_portal", "targetname" ) at FT:103 / FT:497.
- status: VERIFIED. The script logic matches the walkthrough statement that Pack-a-Punch must be unlocked first. Area display names per portal are NEEDS RESEARCH.

### S0. collect_dj_items (quest idx 0)
- objective: Find the DJ's 3 lost items
- location: Random spots across the park
- hint_minimal: The DJ lost three things somewhere in the park.
- hint_standard: Find and pick up the DJ's boombox, calculator and umbrella. Each spawns at one of several spots, and each is in a different area group.
- hint_detailed: Pick up all three: the boombox (radio), the calculator and the umbrella. Each spawns at one of three random spots, all in different areas. Check benches, counters and tables in the start area, Kepler System, Astrocade, Polar Peak, Journey into Space and the underground.
- walkthrough_spots (WALKTHROUGH ONLY, not a hint field):
  - Umbrella: red bench near the slide by the Polar Peak bridge, the Polar Peak gift shop counter, or the dark corner by the Journey into Space Star Mission trap.
  - Calculator: yellow bench in the park center, a blue bin upstairs in the Astrocade, or a yellow table in upper Kepler by the Chronosphere.
  - Boombox: behind the cart on the lower bridge near the entrance, the top of Kepler by the power switch, or the underground break room. Another source lists the Racin' Stripes counter, a cart in Kepler, or the Moonlight Cafe counter instead.
- detect:
  - Done: flag_set( "dj_fetch_quest_completed" ) at DJ:302 (flag_init DJ:40). It is set when the 3rd item is picked up; turning the items in to the DJ is not required by the script.
  - Per-item progress: level.dj_part_1_found / level.dj_part_2_found / level.dj_part_3_found (DJ:215, DJ:233, DJ:250).
- marker: getstructarray( "dj_quest_part_1" | "dj_quest_part_2" | "dj_quest_part_3", "script_noteworthy" ) at DJ:269. The chosen struct is stored in level.selected_dj_parts[1..3] (DJ:332) and has `.part_model` (script_model spawned at getstruct( var_5.target, "targetname" ), DJ:285-292). Use level.selected_dj_parts[i].part_model.origin while it is defined (it is deleted at DJ:310).
- Item models: part_1 "zmb_frequency_device_radio" (DJ:210), part_2 "zmb_frequency_device_calculator" (DJ:228), part_3 "zmb_frequency_device_umbrella_ground" (DJ:245).
- status: VERIFIED for the 3 items and the random spawn spots. The spot list is WALKTHROUGH ONLY, because the script only knows struct groups `area_1..3` (DJ:267), and it conflicts between sources. For the boombox, segmentnext/itechpost list the lower-bridge cart, top of Kepler and the underground break room, while magicgameworld/shacknews list the Racin' Stripes perk counter, a cart in Kepler and the Moonlight Cafe counter. Walkthroughs call the three items the parts of the "SETI-COM". The script logs the DJ crafting the frequency device when the items are turned in (DJ:198), but the quest flag fires on the 3rd pickup.

### S1. enter_pap_room (quest idx 1)
- objective: Enter the Pack-a-Punch room
- location: Center portal (Main Street hub)
- hint_minimal: Visit the secret room behind the center portal, then survive.
- hint_standard: Go through the center portal to the Pack-a-Punch room, then survive until the next round starts.
- hint_detailed: Use the center portal to enter the Pack-a-Punch room (an earlier visit counts), then survive until the next round starts. The UFO frozen in the Polar Peak ice mountain then flashes and plays six tones.
- detect:
  - flag_set( "pap_portal_used" ) at FT:698 (flag_init FT:29).
  - Then the step ends on the next level notify "wave_start_sound_done" (DJ:389-397). For a robust check, use level.zombie_current_quest_step_index["ufo"] >= 2 (QUEST:28).
- marker: getent( "center_portal", "targetname" ) (FT:103) or level.fast_travel_spots[ level.end_portal_name ] (level.end_portal_name = "main_street", FT:7).
- status: VERIFIED. Walkthroughs say PaP must be open, then finish the current round and listen for the UFO lodged in Polar Peak to make noise and flash colours. The script matches: step 2 starts with ufo_light_sequence_pre_defense at DJ:490. The exact "PaP room visit" trigger is SCRIPT ONLY.

### S2. talk_to_dj (quest idx 2: before defense 1, and again after any failed defense)
- objective: Talk to the DJ
- location: Active DJ window (Cosmic Tunes booth)
- hint_minimal: The DJ has something for you.
- hint_standard: Find the open DJ window (the DJ moves between booths) and talk to him to get the frequency device.
- hint_detailed: The DJ sits behind one of the "Cosmic Tunes" DJ windows. His window shows "Talk to DJ"; the others say he is not here. Interact to get the device (SETI-COM). After a failed defense he moves, so find him again; the spot to defend stays the same.
- detect:
  - flag_set( "dj_request_defense_done" ) at DJ:450 (first request) or DJ:464 (after a failure). flag_init is at DJ:440.
  - The flag is only cleared on failure (DJ:1536). It stays set after a success, so defenses 2 and 3 start right away and no new DJ visit is needed. do_speaker_defense does flag_wait at DJ:506 and returns immediately.
  - After a failure, the same location struct is re-armed (DJ:517-519), and the DJ moves (choose_new_dj_door, DJ:1562).
- marker:
  - level.selected_dj_door: a struct from getstructarray( "dj_quest_door", "script_noteworthy" ) at DJ:337/374, chosen at DJ:345/384.
  - Also level.active_dj_door: getent from getentarray( "dj_doors", "targetname" ), DJ:1699/1715.
  - Also the closest getentarray( "cosmic_tunes", "targetname" ) sign (DJ:1997).
- status: VERIFIED. Walkthroughs say talk to the Hoff at one of the Cosmic Tunes DJ booths (one source says three booths). "No DJ visit between defenses 2 and 3" is SCRIPT ONLY; it matches the walkthrough wording "after the above step three times, return to the DJ".

### S3. place_device (quest idx 2/3/4)
- objective: Place the device where it shakes
- location: Random spot (screen shakes nearby)
- hint_minimal: Your screen will shake near the right spot.
- hint_standard: Carry the device around the park. Your screen and controller shake near the correct spot. Stand on flat ground there and place it.
- hint_detailed: The spot is random each time, and one of the three defenses is on the underground route. Walk around until your screen and controller shake, then place the device on flat ground near that spot. You cannot place it during special rounds.
- detect: level notify( "speaker_defense_started" ) at DJ:1158 (notify_objective, called from start_defense_sequence DJ:980). flag `defense_sequence_active` is set at DJ:1171 (initialised lazily at DJ:1169).
- marker: the active location is the struct from getstructarray( "dj_quest_speaker", "script_noteworthy" ) (DJ:551/863) that is currently in level.current_interaction_structs (added at DJ:914/926 by managespeakerlocactivation). get_speaker_loc returns it but does not store it on level (DJ:827-838).
- status: VERIFIED. Walkthroughs give the "screen shakes" cue and random locations.

### S4. defend_device (quest idx 2/3/4)
- objective: Defend the device
- location: Where the device was placed
- hint_minimal: Keep zombies off the device until the timer ends.
- hint_standard: Zombies rush the device. Kill them before they hit it. The timer is 60 s the first time, 90 s the second and 120 s the third.
- hint_detailed: Stay by the device and kill the park-worker zombies that sprint at it. It survives 10 hits (at most 1 per second). If it breaks, find the DJ again (he moves) and redo this defense at the same spot. Lengths: 60, 90, then 120 s.
- detect:
  - Success: level notify( "speaker_defense_completed" ) at DJ:1586.
  - Failure: level notify( "speaker_defense_failed" ) at DJ:1547.
  - The game's own timer and target use omnvars zm_speaker_defense_timer, zm_speaker_defense_target and zm_speaker_defense_health (DJ:1313-1315).
- marker: level.current_speaker (script_model, DJ:1212) during the defense. The game already shows its own objective icon via setomnvar( "zm_speaker_defense_target", <script_model spawned at DJ:1312> ) at DJ:1313.
- status: VERIFIED for the 3 defenses with increasing time.
  - "Restart if it is hit" is a simplification: the script allows 10 hits (DJ:1213, DJ:1285-1292).
  - Failure also forces a brute spawn: flag_set( "force_spawn_boss" ) at DJ:1066, consumed in cp/zombies/zombies_spawning.gsc:1409-1416, which spawns a zombie_brute at :1526.
  - Wave progression is paused during the defense (DJ:1028-1069).

### S5. pick_up_device (quest idx 2/3/4)
- objective: Pick up the device
- location: Where the device was defended
- hint_minimal: Grab the device back.
- hint_standard: After a successful defense, pick the device back up. The step finishes when the next regular round starts.
- hint_detailed: Interact with the device to pick it up. The step ends once it is picked up and a new regular round has begun. Then carry it to the next spot where the screen shakes (no DJ visit needed). After the third defense, wait a round and go back to the DJ.
- detect:
  - Pickup: level notify( "speaker_picked_up" ) at DJ:1367.
  - The step ends after waittill_multiple( "speaker_picked_up", "regular_wave_starting" ) at DJ:524. Use level.zombie_current_quest_step_index["ufo"] advancing (3 after defense 1, 4 after defense 2, 5 after defense 3).
- marker: none stored on level after success (level.current_speaker is cleared at DJ:1580). The S3 location struct is the closest usable proxy.
- status: SCRIPT ONLY. Walkthroughs do not mention picking the device back up.

### S6. survive_round (quest idx 5)
- objective: Survive the round
- location: Anywhere
- hint_minimal: The DJ needs a round to prepare.
- hint_standard: After the third defense, survive until the next regular round starts. The DJ moves to a new window.
- hint_detailed: Complete the current round. When the next regular round begins, the DJ (who moved booths after the third defense, DJ:535) has the tone speakers ready.
- detect: level notify "regular_wave_starting" (waited at DJ:429). Use level.zombie_current_quest_step_index["ufo"] >= 6.
- marker: none
- status: VERIFIED. Walkthroughs say the DJ gives the speaker after a few more rounds; the script waits one regular wave.

### S7. get_tone_speakers (quest idx 6)
- objective: Get the speakers from the DJ
- location: Active DJ window (Cosmic Tunes booth)
- hint_minimal: Visit the DJ again.
- hint_standard: Find the DJ's current window and talk to him to receive the portable tone speakers.
- hint_detailed: The DJ moved after the last defense. Check the DJ windows for the "Talk to DJ" prompt and interact to receive the tone speakers.
- detect: flag_set( "tone_generators_given" ) at DJ:609 (flag_init DJ:585).
- marker: level.selected_dj_door / level.active_dj_door (see S2).
- status: VERIFIED. Walkthroughs say the DJ gives a portable speaker.

### S8. place_tone_speakers (quest idx 7)
- objective: Place 4 speakers on the pads
- location: Golden pads around the center portal
- hint_minimal: Four golden platforms surround the center portal.
- hint_standard: Place a speaker on each of the 4 golden platforms around the center portal: 3 around the portal and 1 on its steps.
- hint_detailed: Go to the center portal plaza. Interact with each of the 4 golden platforms to set down a speaker. After all 4 are placed, each speaker has its own colour and tone.
- detect: flag_set( "all_structs_placed" ) at DJ:1660 (flag_init DJ:623). Per pad: `.placed` on each struct (DJ:1647).
- marker: level.alldjcenterstructs[0..3] (spawned structs, DJ:1384-1401). Fixed origins come from DJ:1385: (300,663,60), (660,335,60), (985,665,60), (647,792,116), each dropped to ground +48.
- status: VERIFIED. Walkthroughs report 4 golden platforms (one says 3 around the portal plus one on the steps), and the script has 4 positions, one of them higher (z 116). One walkthrough also says you must defend the placed speakers from zombies; nothing in place_tone_generator_on / waitforplayertrigger (DJ:1630-1676) supports that, so it was left out.

### S9. play_speakers_together (quest idx 7, part 2)
- objective: Play the speakers together
- location: Golden pads around the center portal
- hint_minimal: Every player has to play a speaker.
- hint_standard: Each player stands at a different speaker and plays it at the same moment. Solo: play any one speaker.
- hint_detailed: After all 4 are placed, each player activates a different speaker within about 1 second of each other (the number of speakers played must equal the player count). This does not count during special (event) rounds. Success stops the park music and starts the UFO.
- detect: flag_set( "all_center_positions_used" ) at DJ:939 (flag_init DJ:624).
- marker: level.alldjcenterstructs (see S8).
- status: VERIFIED. Walkthroughs say each player must interact with a speaker to play a tone, and the script requires players.size simultaneous presses.

### S10. match_ufo_colors (quest idx 8)
- objective: Repeat the UFO's colors (3x)
- location: Center portal plaza
- hint_minimal: The UFO is signalling. Answer it with the speakers.
- hint_standard: The UFO flies over the center portal and flashes 4 colors. Play the speakers with the same colors in the same order. Succeed 3 times.
- hint_detailed: The UFO hovers over the center and flashes 4 colours (red/green/blue/yellow, random order). Play the matching speakers in the same order, each within 4 s (solo) or 2.5 s (co-op) of the last. A wrong press spawns a brute. Do it 3 times; the order changes.
- detect:
  - Done: flag_set( "tones_played_successfully" ) at UFO:410 and again at DJ:680 (flag_init DJ:650). level notify "tone_sequence_completed" at UFO:372.
  - Per round: the UFO entity notifies "completed_tone_match" (UFO:365).
  - Start: flag `ufo_intro_reach_center_portal` set at UFO:219 (flag_init DJ:651) when the UFO arrives. flag `ufo_listening` is set while input is accepted (UFO:473).
- marker: level.ufo (script_model, UFO:16; idle spot getstruct( "ufo_initial_position", "targetname" ) at UFO:9). For the pads, see level.alldjcenterstructs.
- status: VERIFIED. Walkthroughs describe Simon Says with the UFO's four colours, done three times.

### S11. kill_clown_wave (quest idx 9)
- objective: Kill the UFO's clown horde
- location: Center portal plaza / Main Street
- hint_minimal: The UFO is beaming down exploding clowns.
- hint_standard: The UFO beams down 50 suicide-bomber clowns around the center. Kill all of them, and keep your distance.
- hint_detailed: The UFO moves over the center portal and drops 50 clown suicide bombers from 3 spots (the center and both sides of Main Street). Zombies already alive also turn into bombers. Kill all 50 from range.
- detect:
  - No flag. Kill count: level.num_ufo_zombies_killed (UFO:98, incremented at UFO:739). Done when it reaches 50 (UFO:128).
  - Robust: level.zombie_current_quest_step_index["ufo"] >= 10 (QUEST:28).
- marker: level.ufo (UFO:16).
- status: SCRIPT ONLY. Walkthroughs only mention a clown wave loosely and put it in a different place in the order.

### S12. kill_alien_greys (quest idx 10): BOSS, see section C
- objective: Kill the alien greys
- location: Center portal plaza / Main Street
- hint_minimal: Aliens have landed. Stop them healing.
- hint_standard: One alien grey per player spawns. When one starts healing, melee the glowing fuse on its back to stop it. Kill all of them.
- hint_detailed: One grey per player spawns at the center. They teleport and shoot. Below ~20% health a grey heals under the UFO for up to 6 s: melee the exposed fuse on its back to stop it. After 2 stops it can't heal again. Kill every grey.
- detect: level notify( "complete_alien_grey_fight" ) at UFO:840 (sent when level.spawned_grey is empty).
- marker: level.spawned_grey[] (agents; the array is maintained in UFO:829). Spawn points come from the fixed list at UFO:769.
- status: VERIFIED. The fandom page says to melee the alien's back to expose a fuse.

### S13. insert_alien_fuses (after quest idx 10; needed for S14)
- objective: Put the fuses in Pack-a-Punch
- location: Center portal steps -> Pack-a-Punch room
- hint_minimal: The aliens dropped something near the portal.
- hint_standard: Pick up the 2 alien fuses on the center portal steps and install them in the Pack-a-Punch machine.
- hint_detailed: The fuses drop on the center portal steps (fixed position). Pick them up, go to the Pack-a-Punch room and use the machine to insert them. Wonder weapons can then be Pack-a-Punched, and normal weapons can be upgraded one more level.
- detect:
  - Pickup: level.num_fuse_in_possession > 0 (UFO:1020).
  - Insert: flag_set( "fuses_inserted" ) at UFO:1175 (flag_init UFO:23).
- marker:
  - Fuses: none stored. Only the script's own hardcoded spawn origins are known, (657,765,105) and (641,765,105) at UFO:967/970; there is no struct or ent lookup.
  - PaP machine: getent( "pap_machine", "targetname" ) at UFO:1187. Its interaction struct is getstructarray( "pap_upgrade", "script_noteworthy" ) at UFO:1201.
- status: VERIFIED. The fandom summary says to pick up the two alien fuses from the steps and plant them in the PaP machine; then normal weapons can be PaP'd twice and a wonder weapon once. The script matches:
  - level.pap_max starts at 2 (cp/gametypes/zombie.gsc:74) and becomes 3 on insert (UFO:1176).
  - can_upgrade blocks wonder weapons until `fuses_inserted` (cp/cp_weapon.gsc:4895-4914).
  - One interaction picks up both fuse models (UFO:999-1029).

### S14. pap_wonder_weapon (needed for S15)
- objective: Pack-a-Punch a wonder weapon
- location: Pack-a-Punch room
- hint_minimal: Only an upgraded wonder weapon can charge the sign.
- hint_standard: Pack-a-Punch the Shredder, Dischord, Face Melter or Headcutter once. Only these can charge the SPACELAND sign panels.
- hint_detailed: Get one of the Weapons of Rock (Shredder, Dischord, Face Melter or Headcutter) by finishing its build at its standee. One is enough. After the alien fuses are in, Pack-a-Punch it exactly once.
- detect: "manual" or derived. The script's own test is can_charge_power_nodes (UFO:1755-1778): getweaponbasename is one of iw7_{headcutter,facemelter,dischord,shredder}_zm[_pap1], and player get_weapon_level == 2 (cp/cp_weapon.gsc:4846).
- marker: PaP machine getent( "pap_machine", "targetname" ) (UFO:1187).
- status: VERIFIED. Walkthroughs recommend a Weapon of Rock (Shredder/Dischord) and say one is enough. The fandom summary says that after the fuses you can PaP a wonder weapon once.
  - The weapon list is from the script.
  - The standee/build system is cp/zombies/zombies_wor.gsc (hints CP_QUEST_WOR_TAKE_*, lines 13-16). Its build steps are a separate quest and are NOT covered here.
  - "Exactly once" is from the script: get_weapon_level == 2.

### S15. charge_sign_panels (quest idx 11, part 1)
- objective: Shoot the 5 SPACELAND panels
- location: SPACELAND sign at the main gate
- hint_minimal: The big SPACELAND sign has five panels to power up.
- hint_standard: Shoot the 5 blue panels around the SPACELAND sign at the main gate with the upgraded wonder weapon until all 5 turn yellow.
- hint_detailed: Dodge the UFO's slow homing shots. Shoot each of the 5 blue panels around the circular SPACELAND sign at the main gate with a once-upgraded wonder weapon until it turns yellow. Normal weapons do nothing. When all 5 are yellow, the sign powers up.
- detect:
  - Per panel: `.is_activated` on getstruct( "main_gate_powernode_1".."_5", "targetname" ) (UFO:1704-1710, UFO:1803-1816).
  - All 5: trigger_wmd runs, then level notify( "spaceland_arc_fired" ) at UFO:1850. The panels reset to not-activated at UFO:1842-1846.
- marker: getstruct( "main_gate_powernode_N", "targetname" ) for N = 1..5 (UFO:1809, UFO:1827-1831). The damage trigger is getent( "main_gate_powernode_damage_trigger", "targetname" ) (UFO:1688). The panel lights are getent( "gate_light_0N", "targetname" ) (UFO:1748).
- status: VERIFIED. Walkthroughs describe 5 blue panels turning yellow, then a beam, and the script has 5 power nodes and gate lights.

### S16. destroy_ufo (quest idx 11, part 2)
- objective: Destroy the UFO
- location: Above Main Street
- hint_minimal: Let the sign's beam hit the UFO.
- hint_standard: When all 5 panels are charged, the sign arcs power to the center portal and fires a beam straight up. Time it so the UFO is over the center.
- hint_detailed: About 5 s after the 5th panel charges, the beam fires straight up from the center portal plaza. Charge the last panel as the UFO approaches the center. Only this beam damages the UFO, and one hit destroys it. If it misses, the panels reset: recharge all 5.
- detect: flag_set( "ufo_destroyed" ) at UFO:901 (flag_init DJ:41). The quest then sets flag_set( "ufo_quest_finished" ) at DJ:760 (flag_init cp/zombies/zombie_ark_quest.gsc:19).
- marker: level.ufo (UFO:16), deleted at UFO:902.
- status: VERIFIED. Walkthroughs say the electricity hits the UFO and ends the quest, and one says to time the shots so the beam hits the ship directly.
  - Script basis for the timing hint: trigger_wmd waits 1.3-1.7 s + 1.3-1.7 s + 2.0 s (UFO:1838-1848), then magicbullet( "iw7_spaceland_wmd", (648,611,331) -> (648,611,2281) ) at UFO:1851. Arcs run from the sign to (669,1237) and on to the center (647,632) (UFO:1820-1841). Only this weapon can damage the UFO, and one hit ends it (UFO:865-870, UFO:930-936).
  - Afterwards zombies pause for 20 s and a nuke clears the map (UFO:905-921).
  - NEEDS RESEARCH: whether iw7_spaceland_wmd homes or has a large radius. The weapon file was not checked.

### S17. take_soul_key (final)
- objective: Pick up the Soul Key
- location: Center portal steps
- hint_minimal: Something glowing appeared near the center portal.
- hint_standard: Collect the Soul Key that appears at the center portal steps after the UFO is destroyed.
- hint_detailed: After the UFO explodes, a flaming Soul Key spawns at the center portal steps. Interact with it to collect it for the whole team.
- detect:
  - "manual" (no flag or level notify on pickup).
  - Derived options: poll for the script_model with model "zmb_soul_key_base" spawned at UFO:1034-1035 and treat its deletion (UFO:1085) as done. Alternatively, player getplayerdata( "cp", "haveSoulKeys", "soul_key_1" ) set at UFO:1062, but that is persistent across matches, so it is not reliable for this match.
- marker: none stored. Only the hardcoded spawn origin (646,774,105) at UFO:1034 is known.
- status: VERIFIED. Walkthroughs say the Soul Key can be collected at the main portal.

---------------------------------------------------------------------------------------------------

## C. Boss fight (alien greys, quest idx 10)

- **Preparation.**
  - Bring Pack-a-Punched weapons and perks. Walkthroughs recommend the Shredder or Dischord.
  - The arena is locked from S10 onward: portals are disabled (UFO:280-290), blocker VFX are placed at 3 exits (UFO:1530-1545), and grey_fight_clip is lowered (UFO:1504-1517).
  - Waves are paused and replaced by sprinting wave 28 zombies (UFO:135-156).
  - Fewer players means fewer greys: one per player (UFO:771).
- **Objectives.**
  - Kill every grey. Greys teleport and shoot (weapon iw7_zapper_grey, UFO:778).
  - Below 20% health a grey regenerates under the UFO (behaviors.gsc:127, :504-567, UFO:1490-1497). Melee the exposed alien fuse within ~15 units to stop the regen (zombie_grey_agent.gsc:442-449). After 2 interrupts it cannot regenerate again (behaviors.gsc:569-585).
- **Start detection.**
  - level.zombie_current_quest_step_index["ufo"] == 10 (QUEST:28). alien_grey_fight calls start_grey_sequence (DJ:703-707, UFO:761-800).
  - Analytics: log_grey_sequence_activated (UFO:764). level.spawned_grey becomes non-empty.
  - Arena lock (from S10): flag `disable_portals` set at UFO:282 (flag_init FT:28).
- **End detection.**
  - level notify( "complete_alien_grey_fight" ) at UFO:840, together with level notify( "stop_ufo_zombie_spawn" ) at UFO:839.
  - complete_grey_fight (DJ:709-739) clears the clip and VFX, drops the fuses, re-enables portals (flag_clear "disable_portals" at UFO:294) and nukes.
  - Direct boss fight mode uses the same notify (cp/maps/cp_zmb/cp_zmb.gsc:3059-3063).
- **Final encounter (UFO, S15-S16).** The UFO flies over Main Street firing iw7_ufo_proj homing shots every 10-15 s (UFO:1591-1637). It can only be damaged by iw7_spaceland_wmd.
  - Start: level.zombie_current_quest_step_index["ufo"] == 11.
  - End: flag `ufo_destroyed` (UFO:901).

## D. Final objective and completion

- **Final objective.** "Pick up the Soul Key" (S17) at the center portal steps.
- **Completion signal for the quest.**
  - flag_set( "ufo_destroyed" ) at UFO:901, followed by flag_set( "ufo_quest_finished" ) at DJ:760 (flag_init cp/zombies/zombie_ark_quest.gsc:19). The Soul Key then spawns (DJ:766-777, UFO:1032-1040).
  - In a Willard (p6_) game it spawns only after flag `pause_spawn_after_UFO_destroyed` clears (DJ:770-774).
- **Soul Key pickup.** No notify or flag. Side effects on pickup (UFO:1042-1086):
  - setplayerdata( "cp", "haveSoulKeys", "soul_key_1", 1 ) for every player.
  - achievement update "SOUL_KEY".
  - DJ VO "dj_quest_ufo_soulkey_achieve".
  - If any player is Willard, bink "sysload_o4" plays.
  - For detection, use the soul key model "zmb_soul_key_base" disappearing (derived).

## E. Open questions

1. **Area names.** The display names for power switches, portals (moon/europa/mars/arcade), DJ windows (dj_quest_door structs), the DJ item areas (area_1..3) and speaker-defense spots (dj_quest_speaker structs) are in map entity data, not GSC. The item spot list comes from walkthroughs only.
2. **Beam miss.** Can the SPACELAND sign beam miss the UFO? The WMD is fired straight up from a fixed point (UFO:1851) while the UFO keeps moving (UFO:1575-1589). Walkthroughs do not mention retries; the script resets the panels after every shot (UFO:1842-1846).
3. **Clown wave order.** Walkthroughs put the clown wave during the defense phase. The script runs the 50-clown UFO wave after the colour puzzle (idx 9). The script order is used here.
4. **Hoff summoned by N31L.** If the side-quest robot N31L summons the Hoff, the DJ windows are disabled (cp/zombies/interaction_neil.gsc:539-575). Guided Mode may need to say "DJ unavailable".
5. **Direct boss fight / Director's Cut variants.** Not covered: cp_zmb.gsc:2982-3063 skips straight to the greys, and directors_cut changes the PaP rules (cp/cp_weapon.gsc:4897).
6. **Number of power switches.** The value 5 is inferred from the UFO's 5-stage power monitor plus one walkthrough. Which switch is "power_all" (flag `power_on`) is unknown.
7. **Walkthrough conflicts.**
   - (a) Boombox spawn spots differ between sources (see S0).
   - (b) One source says there are three DJ booths; the script just uses all "dj_quest_door" structs (count unknown).
   - (c) One source says the tone speakers must be defended. The script has no damage logic on them (DJ:1645-1676), so this is not included.
   - (d) One source says the Soul Key lets you double-PaP. In the script, the alien fuses do that (UFO:1170-1183, cp/cp_weapon.gsc:4910-4914).
8. **Walkthrough depth.** Walkthrough pages could not be opened in full (WebFetch blocked). Every WALKTHROUGH claim above comes from search-engine summaries of segmentnext, accelerated-ideas, gameranx, twinfinite, magicgameworld, shacknews, itechpost and fandom. Re-check them against a full guide or video if possible.
9. **Willard / Director's Cut extras.** p6_ "Willard" handling (bink sysload_o4, merit mt_dlc4_troll, UFO:1066-1075, UFO:1149-1153) only adds side effects; it is noted, not a step.
