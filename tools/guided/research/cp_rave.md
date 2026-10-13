# Rave in the Redwoods (cp_rave) - Main Easter Egg for Guided Mode

STATUS: COMPLETE (script research done; web verification limited to search-result summaries, since WebFetch is unavailable). Last updated 2026-10-13.

Path abbreviations used below:
- `RAVE/` = .toolchain/src/iw7-gsc-dump/decompiled/scripts/cp/maps/cp_rave/
- `CPZ/`  = .toolchain/src/iw7-gsc-dump/decompiled/scripts/cp/zombies/
- `CP/`   = .toolchain/src/iw7-gsc-dump/decompiled/scripts/cp/
- `SCR/`  = .toolchain/src/iw7-gsc-dump/decompiled/scripts/

---------------------------------------------------------------------------------------------------

## A. Quest overview

- **Quest name:** Main Easter egg. Walkthroughs call it the Super Slasher Easter egg. The reward is a Soul Key piece (`soul_key_2`) and the outro cutscene.
- **Script quest lines (stock `zombie_quest` framework, `CPZ/zombie_quest.gsc`):**
  - `"jmem"`: 9 steps, registered at `RAVE/cp_rave_j_mem_quest.gsc:14-22`. The script calls the items "Jay memories" (Jay Mewes): 2 photos and 1 skull.
  - `"superslasher"`: 4 steps, registered at `RAVE/cp_rave_super_slasher_fight.gsc:12-15`.
  - Both quest lines start at match start (`start_quest_system`, `CPZ/zombie_quest.gsc:12`). The framework sets `level.zombie_current_quest_step_index["jmem"|"superslasher"]` to the running step index (`CPZ/zombie_quest.gsc:28`). This is a generic, always-available progress signal for Guided Mode.
- **Player count:** works with 1-4 players.
  - The script scales by player count: lair switches enabled = player count (`RAVE/cp_rave_interactions.gsc:1678-1746`, switch at `:1696`); soul charms = players+1 (`RAVE/cp_rave_super_slasher_fight.gsc:704-714`); weak-spot health is 900 x players (`RAVE/cp_rave_super_slasher_fight.gsc:553`).
  - A walkthrough search summary also says the Easter egg is soloable.
- **Prerequisites:**
  - **Required by script:**
    - A player must have talked to Kevin Smith (`level.met_kev`, waited on at `RAVE/cp_rave_j_mem_quest.gsc:71`).
    - The boat must be repaired (3 parts, `RAVE/cp_rave_boat.gsc:330-341`).
    - The boat must have made one trip, because Kevin only appears on it once it is docked (`RAVE/cp_rave_boat.gsc:748`). It is docked only at the pier stop (`RAVE/cp_rave_boat.gsc:561`).
  - **Required by walkthroughs (Prima: "must be done in order"):** power on, boat repaired, projector (Pack-a-Punch) repaired, then talk to Kevin over the projector-room radio.
    - The script does NOT hard-gate the jmem steps on power or `pap_fixed`.
    - However, the skull and the release switches are in the power/generator room.
    - Kevin's radio is on Turtle Island, which is only reachable by boat.
- **Overview:** Turn on the power, repair the boat, reach Turtle Island and fix the projector (Pack-a-Punch). Then talk to Kevin Smith on the projector-room radio. Three times, you collect a memento (photo, photo, skull) and place it at a ritual site with every player nearby and out of Rave Mode.
  - Each ritual forces unlimited Rave Mode. Dismember 10 zombies (arms, then legs, then heads) within 60 s, take the charged memento, kill the Slasher that appears, and inspect the memento it leaves behind.
  - Take the first two mementos back to Kevin. After the third ritual Kevin is trapped. All players hold the lit switches in the power room at once to free him.
  - Ride the boat with Kevin. The Super Slasher emerges and the fight moves to Turtle Island. Kill him over 3 rounds of soul charms, trap and weak spots, then pick up the Soul Key.
- **Direct boss-fight mode:** `level.direct_to_boss_fight` (`CPZ/direct_boss_fight.gsc:44-47`) skips the whole quest. It starts the fight through `rave_start_direct_boss_fight_func` (`RAVE/cp_rave.gsc:7471`), which ends with `direct_boss_fight::success_sequence` and drops no soul key. In this mode Guided Mode should jump straight to section C.
- **Sources:**
  - Scripts: all files listed above, read directly.
  - Prima Games, "Rave in the Redwoods – How to Complete the Main Easter Egg, Play as Kevin Smith": https://primagames.com/tips/rave-redwoods-how-complete-main-easter-egg-play-kevin-smith
  - Prima Games, "How to Find the Pack-A-Punch in Rave in the Redwoods": https://primagames.com/tips/how-find-pack-punch-rave-redwoods-upgrade-weapons
  - Accelerated Ideas, "Rave in the Redwoods - All Easter Egg Steps": https://www.accelerated-ideas.com/news/rave-in-the-redwoods-all-easter-egg-steps.aspx
  - Gameranx main EE guide: https://gameranx.com/features/id/91329/article/infinite-warfare-rave-in-the-redwoods-the-main-easter-egg-guide/
  - Mejoress (Spanish): https://www.mejoress.com/es/?p=4674
  - Gamerfuzion boat parts: https://gamerfuzion.com/rave-redwoods-build-boat-boat-parts-locations/
  - Player.One guide: https://www.player.one/call-duty-infinite-warfare-zombies-guide-easter-eggs-boat-parts-power-locations-rave-582094
  - NOTE: web content comes ONLY from WebSearch result summaries (WebFetch cannot resolve hosts here). Treat walkthrough wording as second-hand.

**Runtime caveat for Guided Mode:** some flags are only `flag_init`-ed when their quest step begins. Guard every `flag()` check with `flag_exist()`. Affected flags:
- `survivor_got_to_island` (init `RAVE/cp_rave_super_slasher_fight.gsc:71`)
- `super_slasher_fight_complete` (init `:132`)
- `charm_sequence_complete` and `max_ammo_active` (init `:646-647`)
- `power_on` (init `CPZ/zombie_power.gsc:9`, after a 5 s wait)

---------------------------------------------------------------------------------------------------

## B. Ordered steps

### 1. power_on
- **objective:** Turn on the power
- **location:** Generator room, Old Hudson Mine
- **hint_minimal:** The power switch is deep underground, past the old mine.
- **hint_standard:** Go through the Old Hudson Mine below the Spawn Lodge to the generator room and pull the power switch.
- **hint_detailed:** Open the path from the Spawn Lodge basement into the Old Hudson Mine. Take the lower path to the generator room, where a zombie is strung up on a wooden wheel, and pull the switch. Power also opens the cellar door in the lodge.
- **detect:**
  - `level notify( "activate_power" )` at `CPZ/zombie_power.gsc:135`. This is reliable; rave code waits on it at `CPZ/cp_rave_doors.gsc:140` and `RAVE/cp_rave.gsc:511`.
  - `flag_set( "power_on" )` at `CPZ/zombie_power.gsc:123` (flag_init `CPZ/zombie_power.gsc:9`) fires ONLY if the generator's `script_parameters` contains "power_all". That is map data and not verified.
- **marker:** `getstructarray( "generator", "script_noteworthy" )` at `CPZ/zombie_power.gsc:8`
- **status:** VERIFIED for the switch and its detection (script plus walkthroughs: Prima and Gameranx say power is first; locations from Player.One and Gameranx summaries). The script does not gate later EE steps on power.

### 2. boat_parts
- **objective:** Find the 3 boat motor parts
- **location:** Mess Hall / Recreation Area
- **hint_minimal:** The broken boat at White Tail Beach is missing its motor parts.
- **hint_standard:** Collect the three boat motor parts (propeller, engine, tiller) around the camp. One is in the Mess Hall; another is in the Recreation Area.
- **hint_detailed:** Collect the propeller, engine and tiller parts. Guides put one in the Mess Hall by spawn and one in the Recreation Area, either beside the red/white-flag tent or upstairs near Tuff Nuff. Guides disagree on the third. Follow the markers.
- **detect:** manual. There is no flag; Guided Mode can poll `level.boat_pieces_found == 3`, incremented at `RAVE/cp_rave_interactions.gsc:715` (init 0 at `:681`). Quest icons 7/9/8 are set at `:723/:726/:729`.
- **marker:** `getstructarray( "boat_quest_piece", "script_noteworthy" )` at `RAVE/cp_rave_interactions.gsc:682`. Each struct has `.name` = propeller/engine/tiller and `.model` until it is collected.
- **status:** VERIFIED for the 3 parts (script and walkthroughs). Exact location per part is NEEDS RESEARCH (guides conflict: Prima, Gamerfuzion, Accelerated Ideas summaries).

### 3. ride_boat
- **objective:** Take the boat to Turtle Island
- **location:** White Tail Beach boat
- **hint_minimal:** With the motor fixed, the boat can take you across the lake.
- **hint_standard:** Use the repaired boat at White Tail Beach to ride to Turtle Island. The boat drops you off and returns to the dock by itself.
- **hint_detailed:** Use the boat at White Tail Beach; it leaves about 5 s after the first player boards. It drops riders on Turtle Island and returns to the dock. At least one trip is needed: Kevin can only board the boat later once it has docked after a trip.
- **detect:**
  - manual. There is no persistent flag.
  - `flag_set( "packboat_started" )` at `RAVE/cp_rave_boat.gsc:658` is cleared again 1 s later (`:660`).
  - `level.packboat_logic_started = 1` at `RAVE/cp_rave_boat.gsc:395` is a pollable level var.
  - `set_completed_quest_mark( 1 )` at `:343` (omnvar bit).
- **marker:** `level.boat_vehicle` (spawned at `RAVE/cp_rave_boat.gsc:8` at `getvehiclenode( "boat_start_struct", "targetname" )`, `:7`). The interaction struct is the `"interaction"` struct with `script_noteworthy == "interaction_packboat"` (collected via `getstructarray( "interaction", "targetname" )`, `CP/cp_interaction.gsc:22`).
- **status:** VERIFIED (script; Prima: boat at White Tail Beach reaches Turtle Island)

### 4. film_reels
- **objective:** Find the 2 film reels
- **location:** White Tail Beach dock / Turtle Island
- **hint_minimal:** The projector on Turtle Island needs two film reels.
- **hint_standard:** Find two film reels: one by the docks next to White Tail Beach, one on Turtle Island outside the cabin near the bonfire.
- **hint_detailed:** Reel 1 is reportedly in the docks next to White Tail Beach. Reel 2 is on Turtle Island, outside the cabin near the bonfire. The pickups have no hint text (`pap_quest_hint_func` returns ""), so press use on the reel model itself.
- **detect:** manual. There is no flag; poll `level.pap_pieces_found >= 2`, incremented at `RAVE/cp_rave_interactions.gsc:766` (init `:654`). Quest icons 11/12 are set at `:769/:771`.
- **marker:** `getstructarray( "pap_quest_piece", "script_noteworthy" )` at `RAVE/cp_rave_interactions.gsc:655`. Each named struct gets `.model` "cp_rave_projector_reel".
- **status:** VERIFIED for 2 reels (script); reel 2 location from Prima. Reel 1 location is WALKTHROUGH ONLY (a single, unnamed guide in a search summary).

### 5. fix_projector
- **objective:** Repair the projector
- **location:** Projector room, Turtle Island cabin
- **hint_minimal:** Bring the reels to the projector in the island cabin.
- **hint_standard:** In the Turtle Island cabin's projector room, use the projector with both reels to restore it and open the Pack-a-Punch portal.
- **hint_detailed:** With both reels, go to the projector room in the Turtle Island cabin and use the projector. It loads the reels and opens a wall portal to the Pack-a-Punch room. Kevin's radio is in this same room (next step).
- **detect:** `flag_set( "pap_fixed" )` at `RAVE/cp_rave_boat.gsc:682` (flag_init `RAVE/cp_rave_boat.gsc:12`, also `RAVE/cp_rave.gsc:902`)
- **marker:**
  - `level.projector_struct` (script_model spawned at (-6122.09, 4854.49, 149), `RAVE/cp_rave_interactions.gsc:653`).
  - Use spots: `"interaction"` structs with `script_noteworthy == "fix_pap"`. Two extra spots are added at `RAVE/cp_rave.gsc:879-897`.
  - `getstruct( "porta_effect_location", "targetname" )` (`RAVE/cp_rave_boat.gsc:30`) is the portal it opens.
- **status:** VERIFIED (script; Prima). The script does not require it for the EE, but walkthroughs order it before Kevin.

### 6. talk_kevin
- **objective:** Talk to Kevin Smith
- **location:** Projector room radio, Turtle Island
- **hint_minimal:** Someone is calling for help in the projector room.
- **hint_standard:** Use the radio in the Turtle Island projector room to talk to Kevin Smith. This starts the Easter egg proper.
- **hint_detailed:** In the projector room of the Turtle Island cabin, interact with the radio to talk to Kevin Smith. Wait for his dialogue to finish; the first memento only becomes collectable after a player has met him.
- **detect:** manual (no flag or notify). Poll `level.met_kev` (set at `RAVE/cp_rave_interactions.gsc:584`, also `level.metks` at `:585`). `jmem` step 0 waits on it at `RAVE/cp_rave_j_mem_quest.gsc:71`.
- **marker:**
  - `getstructarray( "survivor_interaction", "script_noteworthy" )[0]` (`RAVE/cp_rave_j_mem_quest.gsc:498`); this is the interaction struct.
  - The Kevin model `level.survivor` is spawned at `getstruct( "slasher_pos", "targetname" )` (`RAVE/cp_rave.gsc:5994-5995`).
- **status:** VERIFIED (script requires `met_kev`; Prima and Accelerated Ideas: radio in the projector room starts the first official step)

### 7. find_photo_1
- **objective:** Find the first photo
- **location:** Recreation Area, upper level
- **hint_minimal:** Kevin's lost memento lies where the rave takes place.
- **hint_standard:** Search the upper level of the Recreation Area (the rave area). The photo is lying on the floor; pick it up.
- **hint_detailed:** Go to the Recreation Area, where the rave is held, and climb to the upper level. The photo is on the floor; use it. Kevin's memory VO plays.
- **detect:**
  - manual (no flag).
  - Poll `level.j_mem["j_mem_1"]`, set at `RAVE/cp_rave_j_mem_quest.gsc:186`.
  - Quest icon 13 is set at `:76`.
  - `level.zombie_current_quest_step_index["jmem"]` goes 0 -> 1.
- **marker:** `getent( "j_mem_1", "targetname" )` at `RAVE/cp_rave_j_mem_quest.gsc:150`. Model "cp_rave_quest_photo_03" is spawned at its origin at `:151-152`.
- **status:** VERIFIED (script: item 1 is a photo; location from the Accelerated Ideas and Prima summaries, which call it "photo 1")

### 8. ritual_arms
- **objective:** Do the bonfire ritual (arms)
- **location:** Adventure Course bonfire
- **hint_minimal:** The photo needs to be charged at a ritual fire.
- **hint_standard:** Place the photo at the Adventure Course bonfire with everyone nearby, shoot zombies' arms off, then kill the Slasher.
- **hint_detailed:** All players near and out of Rave Mode, hold to place the photo. Dismember 10 zombie arms within 60 s. Grab the glowing photo within 30 s. Kill the Slasher within 60 s and inspect the photo again. A failed ritual nukes and costs a perk; you can retry.
- **detect:** `flag_set( "photo_1_kev_given" )` at `RAVE/cp_rave_j_mem_quest.gsc:989` (flag_init `:6`). Sub-progress notifies (all in `RAVE/cp_rave_j_mem_quest.gsc`):
  - `"speaker_defense_completed"` at `:751`: 10 kills done.
  - `"slasher_photo_taken"` at `:912`
  - `"slasher_killed"` at `:970`
  - Fail notifies: `"speaker_defense_failed"` at `:720`, `"slasher_photo_timeout"` at `:918`, `"slasher_timeout"` at `:961`.
- **marker:** `getstruct( "circle_org_arm", "targetname" )` (looked up at `RAVE/cp_rave_j_mem_quest.gsc:250`, name passed from `:105`). After that, `level.photo` (script_model at the same spot, `:252-258`).
- **status:** VERIFIED (script; walkthrough: Accelerated Ideas says Adventure Course bonfire, arm shots; Mejoress gives the same flow; Gameranx says failure nukes and removes a perk)

### 9. give_photo_1
- **objective:** Give the photo to Kevin
- **location:** Projector room radio, Turtle Island
- **hint_minimal:** Kevin will want to hear about that memory.
- **hint_standard:** Return to the Turtle Island projector room and talk to Kevin on the radio to hand over the charged photo.
- **hint_detailed:** Go back to the projector room radio on Turtle Island and interact with it. Kevin reacts to the photo's memory; let his dialogue finish. After that, the second memento can be collected.
- **detect:** `flag_set( "photo_1_kev_vo_done" )` at `RAVE/cp_rave_interactions.gsc:601` (flag_init `RAVE/cp_rave_j_mem_quest.gsc:8`). The jmem step waits on it at `RAVE/cp_rave_j_mem_quest.gsc:1014`.
- **marker:** `getstructarray( "survivor_interaction", "script_noteworthy" )[0]` (`RAVE/cp_rave_j_mem_quest.gsc:498`)
- **status:** SCRIPT ONLY (no walkthrough summary mentioned returning to Kevin between rituals)

### 10. find_photo_2
- **objective:** Find the second photo
- **location:** Spawn cabin balcony (Tuff Nuff room)
- **hint_minimal:** Another memento lies on a balcony near where you started.
- **hint_standard:** Go upstairs in the spawn cabin and out onto the balcony outside the room with the Tuff Nuff machine. Pick up the photo.
- **hint_detailed:** From the main spawn cabin, go upstairs to the room with the Tuff Nuff perk machine and step out onto its balcony. The second photo is on the balcony; use it.
- **detect:** manual. Poll `level.j_mem["j_mem_2"]` (`RAVE/cp_rave_j_mem_quest.gsc:186`). Quest icon 14 is set at `:83`.
- **marker:** `getent( "j_mem_2", "targetname" )` at `RAVE/cp_rave_j_mem_quest.gsc:150` (model "cp_rave_quest_photo_04")
- **status:** VERIFIED (script; location from the Accelerated Ideas summary, which calls it "photo 2")

### 11. ritual_legs
- **objective:** Do the Quickies ritual (legs)
- **location:** Recreation Area, Quickies machine
- **hint_minimal:** Charge the second photo at another ritual site in the rave area.
- **hint_standard:** Place the photo in front of Quickies in the Recreation Area, blow zombies' legs off (explosives help), then kill the Slasher.
- **hint_detailed:** All players near and out of Rave Mode, hold to place the photo at Quickies. Remove 10 zombie legs within 60 s (explosives work well). Grab the glowing photo within 30 s. Kill the Slasher within 60 s and inspect the photo. A failure costs a perk; you can retry.
- **detect:** `flag_set( "photo_2_kev_given" )` at `RAVE/cp_rave_j_mem_quest.gsc:998` (flag_init `:7`). The sub-notifies are the same as in step 8.
- **marker:** `getstruct( "circle_org_leg", "targetname" )` (lookup `RAVE/cp_rave_j_mem_quest.gsc:250`, name from `:110`), then `level.photo`.
- **status:** VERIFIED (script counts leg dismemberments, types 4/8, at `:785-789`; Accelerated Ideas: explosive kills in front of Quickies; Mejoress: legs near Quickies)

### 12. give_photo_2
- **objective:** Give the photo to Kevin
- **location:** Projector room radio, Turtle Island
- **hint_minimal:** Kevin should see this memory too.
- **hint_standard:** Talk to Kevin on the Turtle Island projector room radio again to hand over the second photo.
- **hint_detailed:** Return to the projector room radio on Turtle Island and interact with it. Let Kevin's dialogue about the second memory finish; the final memento then becomes collectable.
- **detect:** `flag_set( "photo_2_kev_vo_done" )` at `RAVE/cp_rave_interactions.gsc:606` (flag_init `RAVE/cp_rave_j_mem_quest.gsc:9`). The jmem step waits on it at `RAVE/cp_rave_j_mem_quest.gsc:1016`.
- **marker:** `getstructarray( "survivor_interaction", "script_noteworthy" )[0]` (`RAVE/cp_rave_j_mem_quest.gsc:498`)
- **status:** SCRIPT ONLY

### 13. find_skull
- **objective:** Find the skull
- **location:** Generator room, by the zombie wheel
- **hint_minimal:** The last memento waits where the power comes from.
- **hint_standard:** Go back to the generator (power switch) room and pick up the skull on the floor beside the wheel with the zombie on it.
- **hint_detailed:** Return to the generator room in the Old Hudson Mine where you pulled the power switch. The final memento, a skull, is on the floor beside the wooden wheel with the zombie strung on it. Pick it up.
- **detect:** manual. Poll `level.j_mem["j_mem_3"]` (`RAVE/cp_rave_j_mem_quest.gsc:186`). Quest icon 15 is set at `:90`.
- **marker:** `getent( "j_mem_3", "targetname" )` at `RAVE/cp_rave_j_mem_quest.gsc:150` (model "p7_skulls_bones_head_01"; the trigger is raised 15 units at `:154-155`)
- **status:** VERIFIED (script: item is a skull; location from the Accelerated Ideas and Prima summaries, which describe a "photo"/"skull piece" in the generator room by the wheel)

### 14. ritual_heads
- **objective:** Do the Bang Bang ritual (heads)
- **location:** Bear Lake, Bang Bang machine
- **hint_minimal:** The skull needs a ritual at the lake.
- **hint_standard:** Place the skull in front of the Bang Bang machine at Bear Lake, score headshot kills that pop heads, then kill the Slasher.
- **hint_detailed:** All players near and out of Rave Mode, hold to place the skull at Bang Bang. Get 10 head-popping headshots within 60 s. Grab the charged skull within 30 s. Kill the Slasher within 60 s and inspect the skull. Kevin is then taken, so there is no hand-in.
- **detect:** `flag_set( "survivor_trapped" )` at `RAVE/cp_rave_j_mem_quest.gsc:143` (flag_init `RAVE/cp_rave.gsc:762`). Also `level notify( "third_quest_part_done" )` at `RAVE/cp_rave_j_mem_quest.gsc:145`. The `"superslasher"` quest step 0 completes on it (`RAVE/cp_rave_interactions.gsc:1628`).
- **marker:** `getstruct( "circle_org_head", "targetname" )` (lookup `RAVE/cp_rave_j_mem_quest.gsc:250`, name from `:115`), then `level.photo`.
- **status:** VERIFIED (script counts head dismemberments, type 16, at `:791-793`; Accelerated Ideas: headshots in front of Bang Bang at Bear Lake)

### 15. free_kevin
- **objective:** Free Kevin from the cellar
- **location:** Power room switches
- **hint_minimal:** Kevin is trapped. Listen for pounding and find the switches.
- **hint_standard:** Kevin is locked in the cellar. In the power room, every player must hold one of the unlit switches at the same time.
- **hint_detailed:** Unlit switches in the power room are the ones to use, one per player (solo: one). Every player holds use on a different unlit switch at the same time, within arm's reach, until a buzzer sounds. Kevin teleports to the boat.
- **detect:** `flag_set( "survivor_released" )` at `RAVE/cp_rave_interactions.gsc:1790` (flag_init `RAVE/cp_rave.gsc:761`)
- **marker:**
  - `getstructarray( "lair_secret_door", "script_noteworthy" )` at `RAVE/cp_rave_interactions.gsc:1589`.
  - Use only structs whose `.script_objective` is `trap_door_switch1`..`trap_door_switchN`, where N = player count (enabled in `lair_door_player_monitor`, `:1678-1746`).
  - Lights: `getent( "trap_door_switch1", "targetname" )` etc. at `:1681-1684`.
  - The pounding sound comes from (-84, -1859, 117) (`:1637`).
- **status:** VERIFIED (script; one search summary: "In the power room, you'll now find circular lights. Every player must interact with them at the same time." The exact source page was not identified)

### 16. boat_with_kevin
- **objective:** Ride the boat with Kevin
- **location:** White Tail Beach boat
- **hint_minimal:** Kevin is waiting on the boat. Don't leave anyone behind.
- **hint_standard:** Go to the boat at White Tail Beach where Kevin is waiting. All players must stand by the boat before using it.
- **hint_detailed:** Kevin waits in the docked boat at White Tail Beach. Gather every player (none downed) right next to the boat, then use it; if anyone is missing, Kevin nags and the boat stays. On the lake Kevin falls overboard and the Super Slasher rises.
- **detect:** `flag_set( "survivor_got_to_island" )` at `RAVE/cp_rave_boat.gsc:923` (flag_init `RAVE/cp_rave_super_slasher_fight.gsc:71`, so guard with `flag_exist`). `set_completed_quest_mark( 4 )` is at `RAVE/cp_rave_boat.gsc:920`.
- **marker:** `level.boat_survivor` (Kevin on the boat, `RAVE/cp_rave_boat.gsc:758`) or `level.boat_vehicle` (`RAVE/cp_rave_boat.gsc:8`)
- **status:** SCRIPT ONLY (no walkthrough summary described the Kevin boat ride; the rule that all players must be within 140 units is at `RAVE/cp_rave_boat.gsc:349` and `:421-434`, 19600 = 140^2)

### 17. kill_super_slasher
- **objective:** Defeat the Super Slasher
- **location:** Turtle Island
- **hint_minimal:** Fill the soul charms, trap him, and break his weak spots.
- **hint_standard:** On Turtle Island, fill the soul charms in Rave Mode, lure him into the trap, shoot the glowing weak spots. Repeat 3 times, then kill him.
- **hint_detailed:** In Rave Mode, kill zombies near the floating charms until all are full. Lead him into the open trap and shoot the chest weak spot. Shoot the 8 glowing weak spots in turn. In shockwaves, stand in a safe circle and kill skeletons. Round 3: kill him.
- **detect:**
  - Start: `level notify( "ss_intro_finished" )` at `RAVE/cp_rave_super_slasher_fight.gsc:168`.
  - Death: `level notify( "super_slasher_death" )` at `SCR/mp/agents/superslasher/superslasher_agent.gsc:187`.
  - Step done: `flag_set( "super_slasher_fight_complete" )` at `RAVE/cp_rave_super_slasher_fight.gsc:214` (flag_init `:132`).
  - See section C for the sub-objectives.
- **marker:** `level.superslasher` (agent spawned at `RAVE/cp_rave_super_slasher_fight.gsc:152`)
- **status:** VERIFIED (script; Prima, Gamerfuzion and Accelerated Ideas summaries describe weak spots shot in normal mode, circles with skeletons, and repeating phases until he dies)

### 18. soul_key
- **objective:** Pick up the Soul Key
- **location:** Turtle Island
- **hint_minimal:** He dropped something important.
- **hint_standard:** About 8 seconds after the Super Slasher dies, a glowing Soul Key appears where he fell. Pick it up to finish the Easter egg.
- **hint_detailed:** Wait about 8 s after the death animation; the Soul Key spawns, rotating, at his death spot. Use it. Every player is credited with Soul Key 2, the outro cutscene plays, and normal rounds resume about 37 s later.
- **detect:** manual. There is no flag or notify on pickup (`RAVE/cp_rave_super_slasher_fight.gsc:1450-1483`). Indirect signals:
  - `setplayerdata( "cp", "haveSoulKeys", "soul_key_2", 1 )` at `:1469`. This is persistent, so compare against the value at match start.
  - Bink `"zombies_cp_rave_outro"` at `:1478`.
  - Announcer VO `"ww_easteregg_complete"` 37 s later at `:1496`.
- **marker:** `level.soul_key_drop_pos` (set at `SCR/mp/agents/superslasher/superslasher_agent.gsc:176`). The fallback is (-4880, 4710, -87) at `RAVE/cp_rave_super_slasher_fight.gsc:1437`. The key model itself is a local in `drop_soul_key` (`:1435`).
- **status:** VERIFIED (script; Accelerated Ideas: collect the Soul Key after the boss, then the ending cutscene)

### Step count summary
- **18 steps.**
- **Auto-detected by a stock flag or level notify: 10.**
  - power_on (notify `activate_power`)
  - fix_projector
  - ritual_arms
  - give_photo_1
  - ritual_legs
  - give_photo_2
  - ritual_heads
  - free_kevin
  - boat_with_kevin
  - kill_super_slasher
- **Manual: 8.**
  - boat_parts
  - ride_boat
  - film_reels
  - talk_kevin
  - find_photo_1
  - find_photo_2
  - find_skull
  - soul_key
- 7 of the 8 manual steps can still be polled reliably through stock level variables: `level.boat_pieces_found`, `level.packboat_logic_started`, `level.pap_pieces_found`, `level.met_kev`, and `level.j_mem["j_mem_1".."j_mem_3"]`. Only soul_key has no in-match signal besides persistent playerdata.
- **Steps with a script-derived world marker: 18 of 18.** Each has a getent/getstruct(array) lookup or a level entity var. For soul_key the marker is `level.soul_key_drop_pos`.

---------------------------------------------------------------------------------------------------

## C. Boss fight (Super Slasher), `RAVE/cp_rave_super_slasher_fight.gsc`

### Preparation
- **Script facts:**
  - The fight forces the wave number to at least 38 for zombie stats (`level.wave_num_override = max(38, wave)`, `:140`).
  - Teleporting is disabled (`watch_for_player_connect`, `:192-210`).
  - A stair barrier traps players on the island (`:144`, `deploy_stair_barrier` `:1501`).
  - Powerup drops are off (`:148`).
  - A Max Ammo drops at (-5181, 4623, -103) on each phase change and every 360 s while none is active (`try_drop_max_ammo` `:1379`, `unlimited_max_ammo` `:1396-1407`).
  - Players who go down respawn on the island (`:164`).
- **Walkthrough advice (Gamerfuzion and Prima summaries):** bring strong Pack-a-Punched weapons and be well levelled; Fate & Fortune cards help.

### Phases
A round loop with 3 rounds; `level.superslasher.fight_round` is incremented at `:675`.

1. **Soul collection** (`soul_collection_sequence` `:667`)
   - Every player is forced into unlimited Rave Mode (`:669-673`).
   - Players+1 floating soul charms spawn at fixed spots (positions `:644-665`, spawn `:704-725`).
   - Zombies killed within about 500 units of a charm send it a soul (`zom_die_soul_mon` `:903-927`, check at `:918`). Each charm needs 30 souls (`:829-834`, `:867-879`). A charm drains if it gets no souls for 50 s (`soul_deplete_mon` `:836-853`).
   - **objective:** Fill the soul charms
   - **marker:** `level.soul_collection_models[i]` (`:724`)
   - **detect:** `flag_set( "charm_sequence_complete" )` at `:768` (flag_init `:646`; cleared at the start of each round at `:679`)
2. **Trap**
   - The full charms fly to a random memory trap (`mem_trap_seq` `:762`, `get_trap_trigger` `:321`).
   - Lure the Super Slasher within 150 units of it (`slasher_in_trap` `:400-417`, 22500 = 150^2 at `:403`).
   - A weak spot then appears on his chest; any player shot on it traps him for 6 s (`:419-468`, then `slasher_trapped` `:300-319`).
   - **objective:** Lure him into the trap
   - **marker:** the struct in `getstructarray( "memory_trap_trigger", "script_noteworthy" )` (`:323`) that has `.memory_trap_vfx_ent` defined (set `:378`); use its `.memory_trap_loc`.
   - **detect:** `level notify( "super_slasher_is_trapped" )` at `:303`
3. **Weak spots** (`activate_weak_spots` `:517`)
   - 8 glowing weak spots on his body appear one at a time, 5 s apart. Each needs 900 x players damage (`:553`).
   - The hit VFX spell J-A-Y-M-E-W-E-S (`:616-620`).
   - **objective:** Shoot the glowing weak spots
   - **marker:** `level.superslasher`
   - **detect:** manual (no notify per spot)
4. **Shockwave** (rounds 1-2; `SCR/asm/superslasher/superslasher_actions.gsc:233-287`)
   - Stand inside one of the 5 safe circles: centres at `superslasher_actions.gsc:332`, volumes `getentarray( "superslasher_shockwave_safe_area", "targetname" )` at `:339`. Outside them, each pulse deals 30% of max health (`:272`).
   - Skeletons spawn into the circles (`superslasher_actions.gsc:250`, `cp_rave_super_slasher_fight.gsc:1137`, `:1189-1199`). The shockwave is requested at `cp_rave_super_slasher_fight.gsc:543`.
   - Afterwards the next soul collection round starts (`superslasher_actions.gsc:285-286`).
   - **objective:** Stand in a safe circle
   - **marker:** the hard-coded centres or the volume entities above
   - **detect:** manual. The next round's `flag_clear( "charm_sequence_complete" )` at `:679` marks the end.
5. **Final (round 3)**
   - After the 8 weak spots, his face turns sad and his damage shield is removed (`:535-539`, `slasher_abilities_final` `:622-632`). Kill him normally.
   - **objective:** Kill the Super Slasher
   - **detect:** `level notify( "super_slasher_death" )` (`SCR/mp/agents/superslasher/superslasher_agent.gsc:187`)

Other mechanics:
- Barriers (`super_slasher_barrier_N` ents, `:1223`) rise during his wire attack in rounds 2-3 (`domaskwires`, `superslasher_actions.gsc:355-376`). Hitting the trap's chest weak spot lowers them (`:306`).

### Start and end detection
- **Fight step begins:** `superslasher` step 3 runs `init_super_slasher_fight` (`:130`), which does `flag_init( "super_slasher_fight_complete" )` at `:132`.
- **Visible start:** `level notify( "ss_intro_finished" )` at `:168`; the first soul round starts at `:175`.
- **End:**
  - `level notify( "super_slasher_death" )` at `SCR/mp/agents/superslasher/superslasher_agent.gsc:187`.
  - Then `flag_set( "super_slasher_fight_complete" )` at `RAVE/cp_rave_super_slasher_fight.gsc:214`.
  - The soul key drops 8 s later (`:222-227`).
- **Direct boss-fight mode:** same fight via `RAVE/cp_rave.gsc:7471-7513`. It ends at `level waittill( "super_slasher_death" )` (`:7513`) and has no soul key.

---------------------------------------------------------------------------------------------------

## D. Final objective
- **Objective:** "Pick up the Soul Key" (step 18).
- **What the game does on pickup** (`soul_key_pick_up_monitor`, `RAVE/cp_rave_super_slasher_fight.gsc:1450-1483`, plus `:1485-1499`):
  - Pauses waves.
  - Sets `haveSoulKeys.any_soul_key` and `haveSoulKeys.soul_key_2` for every player (`:1468-1469`).
  - Awards the LOCKSMITH achievement progress (`:1470`).
  - Plays the bink `zombies_cp_rave_outro` (`:1478`).
  - About 32 s later, tries to drop the Director's Cut talisman (`:1480`, `:1485-1490`).
  - About 37 s later, plays announcer VO `ww_easteregg_complete` and resumes waves (`:1492-1499`).
- **Completion detection:** no stock flag or notify on the pickup itself. Options for Guided Mode:
  - (a) Treat `flag( "super_slasher_fight_complete" )` as "EE done, collect key" and mark complete when the player uses the key. This requires Guided Mode's own hook; there is no stock signal.
  - (b) Poll `getplayerdata( "cp", "haveSoulKeys", "soul_key_2" )` against its value at match start. This does not work if the player already owned the key.
  - (c) Wrap or hook `soul_key_pick_up_monitor`.
- Marked **manual**.

---------------------------------------------------------------------------------------------------

## E. Open questions (NEEDS RESEARCH)
1. **Boat part locations:** exact per-part locations (propeller/engine/tiller). Guides conflict, and the struct positions live in map data, which is not in the dump. Markers work from the structs at runtime regardless.
2. **Film reel 1:** only one unnamed guide (search summary) says it is "in the docks next to White Tail Beach". Unconfirmed.
3. **Kevin's radio vs Kevin's model:** the script spawns a Kevin model at struct `slasher_pos` and uses a separate `survivor_interaction` struct. Walkthroughs say you talk to him via the radio in the projector room. Whether the model is visible in that room is unconfirmed. Use the interaction struct as the marker.
4. **Hand-in steps:** steps 9 and 12 (talk to Kevin after rituals 1 and 2) are script-required (`photo_N_kev_vo_done`), but no walkthrough text confirming them was read.
5. **Release switch location:** the free_kevin switch room. One search summary says "power room" with "circular lights", but the source page was not pinned. The Kevin pounding sound is at (-84, -1859, 117), near the lodge cellar.
6. **Boss "red buttons" conflict:** Prima's summary mentions "pressing the red buttons ties the boss to the ground". In the stock script the trap interaction `memory_trap_trigger` has an EMPTY use function (`use_memory_trap`, `RAVE/cp_rave_super_slasher_fight.gsc:295-298`) and is removed from the interaction list (`init_memory_traps` `:339-348`). The trap activates automatically when the charms are full. Possibly an older build, or a misdescription; the script behaviour is documented above.
7. **"Turtle Island ritual with a blue-light Slasher":** a search summary mentioned this, but no script evidence of a 4th ritual exists. There are only 3 circle fights (`RAVE/cp_rave_j_mem_quest.gsc:103-116`). Treated as a summary error.
8. **Generator flag:** whether the cp_rave generator's `script_parameters` contains `power_all` (decides whether flag `power_on` is ever set). Use the `activate_power` notify instead.
9. **Item-to-location mapping:** walkthrough photo numbering (1 = Recreation upper, 2 = spawn balcony, 3 = generator room) is assumed to match script items `j_mem_1`/`j_mem_2`/`j_mem_3`. This is consistent with the script (item 3 is a skull; the guides call it a skull piece), but there are no map entity origins to prove it.
10. **Prompt text:** use prompts are localization keys (`CP_RAVE_INSPECT_ITEM`, `CP_RAVE_PICKUP_ITEM`, `CP_RAVE_PLACE_ITEM`, `CP_RAVE_FIX_PAP`, `CP_RAVE_KEVIN`, `CP_RAVE_USEBOAT`, `CP_RAVE_PICK_UP_SOUL_KEY`). Their English text was not read, so the hints avoid quoting prompt text (except "hold to place item", which walkthroughs quote).
