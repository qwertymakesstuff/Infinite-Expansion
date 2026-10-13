# Attack of the Radioactive Thing (cp_town) - Main Easter Egg - Guided Mode research

STATUS: COMPLETE for the guide (sections A-E; section F: how the guide reads each step). Steps marked NEEDS RESEARCH still need a source; the guide names no place for them and relies on its markers.

Path convention: all file:line references are relative to
`.toolchain/src/iw7-gsc-dump/decompiled/scripts/cp/maps/cp_town/`
unless prefixed with `cp/...` (then relative to `.../decompiled/scripts/`).
Abbreviations: mpq = cp_town_mpq.gsc, int = cp_town_interactions.gsc, elv = cp_town_elvira.gsc,
chem = cp_town_chemistry.gsc, craft = cp_town_crafting.gsc, traps = cp_town_traps.gsc,
dmg = cp_town_damage.gsc, cbf = cp_town_crab_boss_fight.gsc, esc = cp_town_crab_boss_escort.gsc,
ray = cp_town_crab_boss_death_ray.gsc, wall = cp_town_crab_boss_death_wall.gsc,
ring = cp_town_crab_boss_sonic_ring.gsc, bomb = cp_town_crab_boss_bomb.gsc.

---------------------------------------------------------------------------------------------------

## A. Quest overview

- Quest name: main Easter egg of "Attack of the Radioactive Thing" (Absolution DLC). Ends with the
  "Radioactive Thing" / Crog boss (agent type "crab_boss") being blown up from inside with a nuke.
- Player count: solo and co-op (1-4). The scripts scale the boss fight by `level.players.size`
  (cbf.gsc:596 weak-spot HP = players * 30000; cbf.gsc:666-704 spawn tables for 1-4 players).
  Several steps need EVERY player at once: charging/teleporting the nuke (mpq.gsc:2184-2213, all
  players within 96 units holding Use), the beach cart teleporter (wall.gsc:531-610, all players
  within 150 units holding Use), the sonic-beam answer (ring.gsc:62-146, all within 400 units holding
  Use) and the final code entry (bomb.gsc:619-622, every player must finish the code).
- Prerequisites (script): power on (spell-book safe opens on `level notify("activate_power")`,
  elv.gsc:40); Crowbar (needed for mirrors, frozen meat, gauges: mpq.gsc:988, 1015, 1040, 1848);
  Cleaver (vial meter elv.gsc:651-681, cleaver-kill leg dmg.gsc:141-148); Seismic Wave Generator
  (arm, cp/crafted_trap_seismic.gsc:342 -> mpq.gsc:820-854); Deep Freeze trap repaired and fired
  (traps.gsc:443-492 -> mpq.gsc:1032). Walkthrough adds: Pack-a-Punch room access for the head
  (Prima). Crowbar and Cleaver share the melee slot and swap with each other (int.gsc:880-914), so
  only one can be held at a time per player.
- Overview: The quest is built from four script quest lines that run in parallel
  (cp/zombies/zombie_quest.gsc:12-35; registered at mpq.gsc:6-20 and cbf.gsc:6-10):
  Phase 1 "deathray" (devgui group 1, VO "key_phase_1"): collect six zombie body parts and place them
  on the slab in the spawn area, collect three mirrors (bathroom shard, car mirror, Elvira's hand
  mirror) and set them on their stands, insert the Scantron card in the life/death-ray machine, enter
  the film-reel code to fire the Life Ray (body is built), enter the code backwards to fire the Death
  Ray, and take the garage key it leaves. Phase 2 "chemistry" (group 2): open the gas-station garage,
  build the chemistry set, solve the randomized chemistry puzzle to brew the bomb compound ("Chem
  Mix"). Phase 3 "launchcode" (group 3): set four pressure gauges to the numbers under the Beachside
  Market desk to open a safe and take the launch codes, collect three nuke/teleporter parts, build the
  nuke, add the Chem Mix, charge and teleport it. Boss "crabBoss" (group 4): escort the nuke cart to
  the water, shoot the weak spot with the Death Ray cannons, survive the Wall of Death, answer the
  sonic beam at the cart, then enter the launch codes inside the creature. Reward: soul key 4 +
  "SOUL_LESS" achievement (bomb.gsc:270-292).
- IMPORTANT for auto-detection: only the chemistry/launchcode/crabBoss lines advance on real flags.
  The "deathray" flags `deathray_step1..7` (init mpq.gsc:41-47) are set ONLY inside their own
  complete funcs (mpq.gsc:121-161), which run after `flag_wait` on the same flag (mpq.gsc:86-119);
  nothing else in the scripts tree sets them, so in normal play they never fire (devgui only).
  `chemistry_step2` likewise is only set by complete_chemistry_step_2 (mpq.gsc:318). Phase 1 must
  therefore be tracked by polling level variables (listed per step below).
- Sources:
  - Scripts (primary): files listed above, plus cp/zombies/zombie_quest.gsc, cp/zombies/zombie_power.gsc,
    cp/crafted_trap_seismic.gsc, cp/utility.gsc:5837-5862 (quest icon / quest mark omnvar bits).
  - Web (search-result summaries only; WebFetch unavailable): Prima Games "Zombies: Attack of the
    Radioactive Thing All Steps - Solve the Main Easter Egg"
    (https://primagames.com/tips/zombies-attack-radioactive-thing-all-steps-solve-main-easter-egg);
    Prima "Find the Cleaver" (https://primagames.com/tips/zombies-attack-radioactive-thing-find-cleaver);
    SegmentNext EE guide (https://segmentnext.com/2017/07/06/infinite-warfare-zombies-attack-of-the-radioactive-thing-easter-egg-steps-guide)
    and power guide (https://segmentnext.com/2017/07/06/infinite-warfare-zombies-attack-radioactive-thing-guide-turn-power-parts-locations);
    GameSkinny (https://www.gameskinny.com/?p=53177); Gameranx EE guide
    (https://gameranx.com/features/id/111779/article/call-of-duty-infinite-warfare-how-to-defeat-the-radioactive-thing-easter-egg-guide/);
    PSTHC trophy guide (https://www.psthc.fr/unjeu/callof-duty-infinite-warfare-ps4/guide-trophees-dlc3.htm).

Useful generic signals (cp/utility.gsc): `set_quest_icon(n)` sets omnvar bit `zombie_quest_piece`[n]
(:5843-5847); `set_completed_quest_mark(n)` sets omnvar bit `zm_completed_quest_marks`[n] (:5859-5862).
cp_town icon indices (from the call sites): 1 head, 2 arm(beach, script "left_arm"), 3 arm(script
"right_arm"), 4 leg(tree), 5 leg(cleaver), 6 torso (mpq.gsc:718-755); 7 car mirror, 8 Elvira mirror,
9 bathroom shard, 10 Scantron (mpq.gsc:738-749, elv.gsc:452); 12 beaker, 13 burner, 14 clamp
(craft.gsc:434-443); 16/17/18 nuke parts (mpq.gsc:1936-1942); 19 spell book (elv.gsc:477); 20 launch
codes (mpq.gsc:392); 21/22 spell page (elv.gsc:488-489); 23 vial (elv.gsc:361). Quest marks: 1 garage
key (mpq.gsc:481), 2 Elvira summoned (elv.gsc:635), 3 chem set built (craft.gsc:331), 4 boss beaten
(bomb.gsc:292), 5 Life Ray body built (mpq.gsc:1195), 6/7/8 chem parts placed (craft.gsc:294/302/298).

---------------------------------------------------------------------------------------------------

## B. Ordered steps

Order rationale: Phase 1 internal order follows the designed debug order of the "deathray" line
(mpq.gsc:163-268: body parts -> Scantron -> mirrors -> Life Ray -> reverse polarity -> key spawned ->
key taken) and the hard gates in ray_gun_activation_func (mpq.gsc:1140-1277). Phase 2 needs the
garage open (key). Phase 3 safe/parts can be done any time (gauge watchers start at game start,
mpq.gsc:365-369); presented after Phase 2 to match walkthrough order. Several early steps (power,
Crowbar, Cleaver, Elvira) are prerequisites for later ones.

### Prerequisites / setup

#### 1. id: get_power_lever
- objective: Find the power lever
- location: Beach (half-buried zombie hand)
- hint_minimal: The power switch at the Power Station is missing its lever.
- hint_standard: A half-buried zombie on the beach is holding the missing power lever. Pick it up.
- hint_detailed: Go to the beach and find the zombie half-buried in the sand. Interact with the lever in its hand to take it (shows as a carried part). The arm that held it sinks into the sand; it becomes a body part later.
- detect: flag_set( "found_missing_handle" ) at int.gsc:1930 (flag_init int.gsc:1901)
- marker: level.missing_handle_struct (its .model), chosen from getstructarray( "missing_handle", "script_noteworthy" ) at int.gsc:1903 (randomized at :1904, picked :1905)
- status: VERIFIED (script int.gsc:1927-1938; SegmentNext/Prima: lever held by a half-buried zombie in the sand)

#### 2. id: power_on
- objective: Turn on the power
- location: Power Station
- hint_minimal: Bring the lever to the broken power switch.
- hint_standard: Take the lever to the Power Station and fit it on the broken power switch to power the town.
- hint_detailed: With the lever, go to the Power Station and interact with the broken switch box to add the lever; the switch is thrown automatically and power comes on for the whole map (also opens Elvira's spell-book safe).
- detect: flag_set( "placed_missing_handle" ) at int.gsc:1958 (flag_init int.gsc:1902); level notify( "found_power" ) at int.gsc:1960; then generic power: flag_set( "power_on" ) at cp/zombies/zombie_power.gsc:123 (flag_init :9) and level notify( "activate_power" ) at cp/zombies/zombie_power.gsc:135
- marker: getent( "box", "script_noteworthy" ) at int.gsc:1973 (the power panel model). The switch itself is the "generator_broken" interaction struct (registered int.gsc:44; no direct getstruct in cp_town)
- status: VERIFIED (script int.gsc:1940-1977; SegmentNext/Prima: power switch at the Power Station, not in spawn). Note: SegmentNext also mentions a "Power Box on the hill near the Diner"; no separate power-box pickup was found in the scripts -> see E.

#### 3. id: get_crowbar
- objective: Get the Crowbar
- location: Motel room
- hint_minimal: A melee tool can break glass, gauges and frozen meat.
- hint_standard: Pick up the Crowbar in the motel room. It replaces your melee and is needed for mirrors, frozen meat and gauges.
- hint_detailed: Open the motel room and interact with the Crowbar to equip it. It swaps with the Cleaver (only one at a time); swap back at either pickup when needed.
- detect: per-player poll: player.currentmeleeweapon == "iw7_knife_zm_crowbar" (set in meleeweaponuse, int.gsc:880-899). No flag/notify.
- marker: getstruct( "iw7_knife_zm_crowbar", "script_noteworthy" ) at int.gsc:907 (model in .model, spawned int.gsc:2020-2048; array lookup int.gsc:2022)
- status: VERIFIED (script; Gameranx: crowbar in the opened room at the Motel; Prima ties it to the torso step)

#### 4. id: get_cleaver
- objective: Get the Cleaver
- location: Market meat counter
- hint_minimal: Check the shark at the market's meat counter.
- hint_standard: Take the Cleaver from the shark corpse at the meat counter in the market. It swaps with the Crowbar.
- hint_detailed: Go to the market meat counter and interact with the Cleaver in the shark corpse. Cleaver kills fill Elvira's vial and a Cleaver kill on a glowing zombie drops a leg. It swaps with the Crowbar.
- detect: per-player poll: player.currentmeleeweapon == "iw7_knife_zm_cleaver" (int.gsc:880-899). No flag/notify.
- marker: getstruct( "iw7_knife_zm_cleaver", "script_noteworthy" ) at int.gsc:912 (array lookup int.gsc:2023)
- status: VERIFIED (script; Prima "Find the Cleaver": shark corpse at the market meat counter)

#### 5. id: get_spellbook
- objective: Take Elvira's spell book
- location: NEEDS RESEARCH (Ice Cream Shop or Diner)
- hint_minimal: A safe opened when the power came on.
- hint_standard: After power is on, a safe opens. Take Elvira's spell book from inside it.
- hint_detailed: Turn the power on first; the safe model swaps to open and its interaction appears. Take the spell book from the safe, then bring it to Elvira in the TV Studio.
- detect: flag_set( "spellbook_found" ) at elv.gsc:472 (flag_init elv.gsc:6)
- marker: getent( "elvira_safe", "targetname" ) at elv.gsc:38; interaction getstruct( "take_spellbook", "script_noteworthy" ) at elv.gsc:36
- status: VERIFIED for mechanism (script elv.gsc:34-43, 469-478; Prima: safe, requires power). Location CONFLICT: Prima says Ice Cream Shop safe; SegmentNext says near the Skull Hop machine in the Diner.

#### 6. id: give_spellbook
- objective: Give the book to Elvira
- location: TV Studio
- hint_minimal: Elvira wants her book back.
- hint_standard: Talk to Elvira on her couch in the TV Studio and hand over the spell book. She gives you a vial to fill.
- hint_detailed: In the TV Studio, interact with Elvira while carrying the book. The book is placed on its stand and the vial icon appears; from now on Cleaver kills fill the vial.
- detect: flag_set( "spellbook_placed" ) at elv.gsc:461 (flag_init elv.gsc:8)
- marker: level.elvira (script_model) placed at getstruct( "elvira", "targetname" ) at elv.gsc:15 (fallback origin (353.5,-2560,534.5) at elv.gsc:20)
- status: VERIFIED (script elv.gsc:345-366; Prima/SegmentNext: Elvira in the TV Studio asks for the spell book and gives a vial)

#### 7. id: fill_vial
- objective: Fill the vial with Cleaver kills
- location: Anywhere
- hint_minimal: Elvira's vial needs to be filled.
- hint_standard: Kill enemies with the Cleaver until the vial meter is full. Crog kills fill it fastest.
- hint_detailed: Equip the Cleaver. Each Crog killed with it adds 10%, each zombie killed adds 5%, each Cleaver hit on a zombie adds 1%. When the meter is full the vial is filled.
- detect: flag_set( "vial_filled" ) at elv.gsc:672 (flag_init elv.gsc:7); meter value in omnvar "zom_general_fill_percent_2" (elv.gsc:671/679)
- marker: none
- status: SCRIPT ONLY (elv.gsc:651-681; notifies from dmg.gsc:136, 650, 653). Walkthrough CONFLICT: one web summary says the goo comes from green-uniform soldier zombies that burst into acid; scripts only count Cleaver kills/hits.

#### 8. id: summon_elvira
- objective: Give Elvira the full vial
- location: TV Studio
- hint_minimal: Return the filled vial to Elvira.
- hint_standard: Bring the full vial to Elvira in the TV Studio to summon her as an ally.
- hint_detailed: Interact with Elvira while the vial is full. She snaps her fingers, vanishes from the couch and fights beside you for a while. Do the next step (her mirror) while she is out.
- detect: flag_set( "elvira_summoned" ) at elv.gsc:402 (flag_init elv.gsc:13); set_completed_quest_mark( 2 ) at elv.gsc:635
- marker: level.elvira (see step 6)
- status: VERIFIED (script elv.gsc:388-418, 598-636; Prima: summon her, then take her mirror)

### Phase 1 - zombie body, mirrors, Life Ray / Death Ray (quest line "deathray")

#### 9. id: body_head
- objective: Collect the zombie head
- location: RV (via Pack-a-Punch wall button)
- hint_minimal: One body part is hidden inside an RV.
- hint_standard: From the Pack-a-Punch room, use the button on the wall to reach an RV and pick up the zombie head.
- hint_detailed: Reach the Pack-a-Punch room, press the wall button to be sent to an RV, and interact with the glowing zombie head to collect it.
- detect: no flag. Poll level.mpq_zom_parts_picked_up[ "head" ] (set mpq.gsc:683); icon bit 1 (mpq.gsc:721)
- marker: getent( "mpq_zom_head_part", "targetname" ) at mpq.gsc:571 (level.mpq_zom_body_parts["head"])
- status: VERIFIED for the pickup (script mpq.gsc:643-712, no extra gate); route via PaP button is WALKTHROUGH ONLY (Prima/GameSkinny)

#### 10. id: freeze_meat
- objective: Fire the freezer and smash the meat
- location: NEEDS RESEARCH (Deep Freeze trap room)
- hint_minimal: The torso is behind meat that needs to be frozen first.
- hint_standard: Repair and activate the Deep Freeze trap, then hit the frozen pig in front of the torso with the Crowbar.
- hint_detailed: Take the freeze-trap part and fit it on the trap panel, then activate the Deep Freeze trap (750). While frozen, melee the pig with the Crowbar; it shatters and the torso behind it is free.
- detect: flag_set( "frozen_meat_gone" ) at mpq.gsc:1048 (flag_init mpq.gsc:56). Sub-signals: flag_set( "freeze_trap_part_taken" ) traps.gsc:470 (init :24), flag_set( "freeze_trap_part_added" ) traps.gsc:449 (init :25), level notify( "start_freeze_trap" ) traps.gsc:492
- marker: getent( "frozen_meat", "targetname" ) at mpq.gsc:973; trap part getstructarray( "trap_freeze_part", "script_noteworthy" ) at traps.gsc:345; panel getstruct( "fix_freeze_trap", "script_noteworthy" ) at traps.gsc:425
- status: VERIFIED (script mpq.gsc:1030-1049, traps.gsc:443-492; Prima: repair/activate Deep Freeze trap, melee the pig with the Crowbar)

#### 11. id: body_torso
- objective: Collect the zombie torso
- location: NEEDS RESEARCH (behind the frozen meat)
- hint_minimal: The torso is free now.
- hint_standard: Pick up the zombie torso that was behind the frozen pig.
- hint_detailed: After the pig shatters, interact with the glowing torso to collect it (it cannot be taken before the meat is gone).
- detect: no flag. Poll level.mpq_zom_parts_picked_up[ "torso" ] (mpq.gsc:683); icon bit 6 (mpq.gsc:724)
- marker: getent( "mpq_zom_torso_part", "targetname" ) at mpq.gsc:572
- status: VERIFIED (script gate mpq.gsc:665-669; Prima)

#### 12. id: body_arm_firepit
- objective: Collect the arm in the firepit
- location: RV Park firepit
- hint_minimal: Check the firepit in the RV Park.
- hint_standard: An arm is lying in the firepit at the RV Park. Pick it up.
- hint_detailed: Go to the RV Park firepit and interact with the glowing arm. No other requirement.
- detect: no flag. Poll level.mpq_zom_parts_picked_up[ "right_arm" ] (mpq.gsc:683); icon bit 3 (mpq.gsc:730)
- marker: getent( "mpq_zom_r_arm_part", "targetname" ) at mpq.gsc:574
- status: VERIFIED with naming caveat: Prima calls this the LEFT arm; the script has no gate on "right_arm" and the gated "left_arm" is the beach arm, so by elimination this is script "right_arm" (inference). See E.

#### 13. id: build_seismic
- objective: Build the Seismic Wave Generator
- location: NEEDS RESEARCH (crafting bench)
- hint_minimal: A crafted device can shake the ground.
- hint_standard: Find the Seismic Wave Generator blueprint and its three parts, then build it at a crafting bench.
- hint_detailed: Blueprint: back of the building with red bricks at the bottom and tri-colour pennants, near the door. Parts are leg, magnet and piston. Add the blueprint to a bench, add the 3 parts, then take the device.
- detect: manual (no flag/notify for crafting the device found)
- marker: blueprint getstructarray( "seismic_blueprint", "script_noteworthy" ) at craft.gsc:105 (random one gets .blueprintmodel, craft.gsc:116-122); parts getstructarray( "crafting_piece", "script_noteworthy" ) at craft.gsc:56 (name "seismic_*", item in .item); benches getstructarray( "crafting_station", "script_noteworthy" ) at craft.gsc:44
- status: VERIFIED for blueprint/parts (script craft.gsc:56-122; GameSkinny/Prima: blueprint location). Exact part locations NEEDS RESEARCH (randomized per game).

#### 14. id: lift_beach_arm
- objective: Quake the arm out of the sand
- location: Beach (where the lever was)
- hint_minimal: The arm that held the lever is stuck in the sand.
- hint_standard: Place the Seismic Wave Generator on the sand right next to the buried arm so the quakes push it up.
- hint_detailed: Lever must already be taken. Place the device within about 100 units of the buried arm; the arm rises 4 units every 3 s until fully out (about 12 s). Then pick it up.
- detect: flag_set( "quake_lifts_arm" ) at mpq.gsc:853 (flag_init mpq.gsc:57; gate flag "allow_quake_lifts_arm" set mpq.gsc:766, init :58)
- marker: level.mpq_zom_body_parts[ "left_arm" ] = getent( "mpq_zom_l_arm_part", "targetname" ) at mpq.gsc:573
- status: VERIFIED (script mpq.gsc:757-768, 820-854, cp/crafted_trap_seismic.gsc:342; Prima: build the Seismic Wave Generator, go to the beach where you found the Power Handle and place it on the sand)

#### 15. id: body_arm_beach
- objective: Collect the arm on the beach
- location: Beach
- hint_minimal: The arm is out of the sand.
- hint_standard: Pick up the arm that the quakes pushed out of the sand.
- hint_detailed: Once the arm has fully risen, interact with it to collect it (needs both the lever taken and the quake done).
- detect: no flag. Poll level.mpq_zom_parts_picked_up[ "left_arm" ] (mpq.gsc:683); icon bit 2 (mpq.gsc:727)
- marker: getent( "mpq_zom_l_arm_part", "targetname" ) at mpq.gsc:573
- status: VERIFIED (script gate mpq.gsc:657-664; Prima calls it the RIGHT arm - naming swap, see E)

#### 16. id: leg_from_tree
- objective: Blast the leg out of the tree
- location: Tree behind the TV Studio
- hint_minimal: A leg is hanging up in a tree.
- hint_standard: Hit the leg in the tree behind the TV Studio with an explosive, then pick it up from the ground.
- hint_detailed: Throw a grenade or fire any explosive/projectile at the leg hanging in the tree behind the TV Studio. It drops to the ground; interact with it to collect it.
- detect: no flag. Poll level.leg_knocked_down (mpq.gsc:795) then level.mpq_zom_parts_picked_up[ "left_leg" ] (mpq.gsc:683); icon bit 4 (mpq.gsc:733)
- marker: getent( "mpq_zom_l_leg_part", "targetname" ) at mpq.gsc:575; after it falls getent( "mpq_zom_l_leg_part_ground", "targetname" ) at mpq.gsc:800
- status: VERIFIED (script mpq.gsc:775-818, explosive MODs mpq.gsc:815-818; Prima: grenade knocks the leg out of the tree behind the TV Studio)

#### 17. id: leg_from_glowing_zombie
- objective: Cleaver-kill a glowing zombie
- location: Anywhere (glowing soldier zombies)
- hint_minimal: One leg comes from a radioactive zombie.
- hint_standard: Kill one of the glowing soldier zombies with the Cleaver as the final blow; a leg appears where it died.
- hint_detailed: Equip the Cleaver. Glowing (radioactive) soldier zombies sprint; finish one with a Cleaver melee. A glowing leg appears at its death spot; interact with it to collect it.
- detect: no flag. Poll level.death_by_cleaver (dmg.gsc:146; read mpq.gsc:1433-1436) then level.mpq_zom_parts_picked_up[ "right_leg" ] (mpq.gsc:683); icon bit 5 (mpq.gsc:736)
- marker: level.death_by_cleaver_org (dmg.gsc:147); part getent( "mpq_zom_r_leg_part", "targetname" ) at mpq.gsc:576 is moved there (mpq.gsc:1441)
- status: VERIFIED in part (script dmg.gsc:141-148, mpq.gsc:1407-1445; Prima summary: "legs obtained by killing a radioactive zombie"). The Cleaver requirement is SCRIPT ONLY.

#### 18. id: place_body
- objective: Lay the body parts on the slab
- location: Spawn area
- hint_minimal: The parts belong together on the slab in spawn.
- hint_standard: Bring the collected parts to the zombie body slab in the spawn area and interact to lay them out.
- hint_detailed: Interact with the body slab in the spawn area; every part you have picked up so far is placed (glowing). You can place in batches. All 6 must be placed before the Life Ray can build the body.
- detect: no flag. Poll level.zom_parts_placed.size == 6 (set mpq.gsc:490)
- marker: bed parts getent( "mpq_zom_head" / "mpq_zom_torso" / "mpq_zom_l_arm" / "mpq_zom_r_arm" / "mpq_zom_l_leg" / "mpq_zom_r_leg", "targetname" ) at mpq.gsc:539-544; body origin hard-coded (4113.5, -4577.5, 20) at mpq.gsc:460
- status: VERIFIED (script mpq.gsc:475-501; Prima: "build a Zombie Body in the spawn area")

#### 19. id: mirror_bathroom
- objective: Break the RV Park bathroom mirror
- location: RV Park bathroom
- hint_minimal: A mirror at the RV Park can be broken.
- hint_standard: Melee the bathroom mirror at the RV Park with the Crowbar and take the glass shard.
- hint_detailed: Equip the Crowbar, go to the RV Park bathroom and melee the intact mirror. It shatters; interact with the glass shard to collect it.
- detect: no flag. Poll level.bathroom_mirror_hit (mpq.gsc:1020) then level.mirrors_picked_up[ "bathroom_mirror" ] (mpq.gsc:898); icon bit 9 (mpq.gsc:749)
- marker: getent( "bathroom_mirror", "targetname" ) at mpq.gsc:971; shard getent( "bathroom_mirror_piece", "targetname" ) at mpq.gsc:1008
- status: VERIFIED (script mpq.gsc:1002-1028, 889-900; Prima)

#### 20. id: mirror_car
- objective: Knock off the car mirror
- location: White car at the gas station
- hint_minimal: A car's side mirror is loose.
- hint_standard: Melee the passenger mirror of the white car in front of the gas station with the Crowbar, then pick it up.
- hint_detailed: Equip the Crowbar and melee the passenger-side mirror of the white car parked in front of the gas station. It falls to the ground; interact to collect it.
- detect: no flag. Poll level.car_mirror_hit (mpq.gsc:991) then level.mirrors_picked_up[ "car_mirror" ] (mpq.gsc:885); icon bit 7 (mpq.gsc:743)
- marker: getent( "car_mirror", "targetname" ) at mpq.gsc:969; fallen mirror getent( "car_mirror_ground", "targetname" ) at mpq.gsc:981
- status: VERIFIED (script mpq.gsc:977-1000, 876-888; Prima)

#### 21. id: mirror_elvira
- objective: Take Elvira's hand mirror
- location: TV Studio (Elvira's couch)
- hint_minimal: Elvira left something behind when she left her couch.
- hint_standard: While Elvira is summoned, go to where she was sitting in the TV Studio and take her hand mirror.
- hint_detailed: Summon Elvira with the full vial. While she is out (or on cooldown), interact at her couch spot in the TV Studio to take the hand mirror.
- detect: no flag. Poll level.mirrors_picked_up[ "elvira_mirror" ] (elv.gsc:456); icon bit 8 (elv.gsc:452)
- marker: getent( "elvira_mirror", "targetname" ) at elv.gsc:451
- status: VERIFIED (script elv.gsc:243-248, 444-457; Prima)

#### 22. id: place_mirrors
- objective: Set the 3 mirrors on their stands
- location: NEEDS RESEARCH (mirror stands, Life Ray path)
- hint_minimal: The ray needs mirrors to reach the slab.
- hint_standard: Place each mirror on its own stand along the ray path so the beam bounces to the body slab.
- hint_detailed: Interact with each mirror stand while holding that mirror (bathroom shard, Elvira's mirror, car mirror). The beam goes machine -> shard -> Elvira mirror -> car mirror -> slab.
- detect: no flag. Poll level.mirrors_placed.size == 3 (set mpq.gsc:940)
- marker: getstructarray( "mirror_placement", "script_noteworthy" ) at mpq.gsc:220 (model spot getstruct( struct.target, "targetname" ) mpq.gsc:224/936); beam points getstruct( "mirror_spot_1" / "mirror_spot_2" / "mirror_spot_3", "targetname" ) at mpq.gsc:1291/1312/1333
- status: SCRIPT ONLY (mpq.gsc:923-941, 1284-1363). Stand locations NEEDS RESEARCH.

#### 23. id: get_scantron
- objective: Take the Scantron card
- location: Ice Cream Shop
- hint_minimal: The machine in spawn needs a punch card.
- hint_standard: Pick up the Scantron punch card in the Ice Cream Shop.
- hint_detailed: Go to the Ice Cream Shop and interact with the Scantron card to take it, then bring it to the machine in the spawn area.
- detect: no flag. Poll level.punch_card_acquired (mpq.gsc:1067); icon bit 10 (mpq.gsc:740)
- marker: getent( "mpq_punch_card", "targetname" ) at mpq.gsc:1063
- status: VERIFIED (script mpq.gsc:1061-1068; Prima/Gameranx: Scantron in the Ice Cream Shop)

#### 24. id: insert_scantron
- objective: Insert the card in the machine
- location: Spawn area (ray machine)
- hint_minimal: Feed the card to the machine in spawn.
- hint_standard: Interact with the ray machine in the spawn area to insert the Scantron card.
- hint_detailed: Use the ray machine in spawn once while holding the card; it is slotted in. The code cannot be entered until all six body parts have been picked up.
- detect: no flag. Poll level.punch_card_added (mpq.gsc:1154)
- marker: getstruct( "punch_card_slot", "targetname" ) at mpq.gsc:1151; machine getstructarray( "ray_gun_start", "script_noteworthy" ) at mpq.gsc:1105
- status: VERIFIED (script mpq.gsc:1145-1157; Prima/Gameranx: place the Scantron in the machine in spawn)

#### 25. id: life_ray_code
- objective: Enter the film reel code
- location: Spawn area (ray machine)
- hint_minimal: The film reel cases hold the numbers.
- hint_standard: Read the five numbered film reel cases in order and enter that 5-digit code on the ray machine.
- hint_detailed: Needs all 6 parts picked up. Digits are 3,4,5,6,8 in a random order each game, shown on film reels 1-5. Use the machine and stop the cycling counter on each digit in order; 3 wrong digits kick you out (retry).
- detect: no flag. Poll level.terminal_unlocked (set mpq.gsc:1757)
- marker: getent( "film_reel_" + n, "targetname" ) n=1..5 at mpq.gsc:1541; code in level.liferaycode (mpq.gsc:1546)
- status: SCRIPT ONLY for the code source (mpq.gsc:1534-1547, 1558-1575, 1700-1766). Walkthrough agrees digits are only 3,4,5,6,8 but a summary said "nine numbers"; script uses 5 (mpq.gsc:1725-1728). Film-reel locations NEEDS RESEARCH.

#### 26. id: fire_life_ray
- objective: Fire the Life Ray
- location: Spawn area (ray machine)
- hint_minimal: Power up the machine with everything in place.
- hint_standard: With all 6 parts on the slab and all 3 mirrors placed, use the ray machine again to fire the Life Ray and build the body.
- hint_detailed: Use the machine again after the code is accepted. The beam bounces off the three mirrors onto the slab; if all parts and mirrors are placed the parts become one zombie body. If not, the beam stops early - fix and retry.
- detect: no flag. Poll level.body_made (mpq.gsc:1196); set_completed_quest_mark( 5 ) at mpq.gsc:1195
- marker: getstruct( "mirror_laser_start", "targetname" ) at mpq.gsc:1172; body level.knife_throw_target_body (origin mpq.gsc:460)
- status: SCRIPT ONLY (mpq.gsc:1170-1224). Not described in the walkthrough summaries read.

#### 27. id: reverse_code
- objective: Enter the code backwards
- location: Spawn area (ray machine)
- hint_minimal: Reverse the polarity.
- hint_standard: Use the ray machine again and enter the same film reel code in reverse order.
- hint_detailed: Enter the five digits from last to first. On success the danger signs change to Death Ray signs.
- detect: no flag. Poll level.polarity_reversed (mpq.gsc:1760)
- marker: same machine; getentarray( "death_ray_sign", "targetname" ) at mpq.gsc:1761
- status: VERIFIED (script mpq.gsc:1225-1231, 1563-1566, 1754-1766; Prima/Gameranx: input it again backwards)

#### 28. id: fire_death_ray
- objective: Fire the Death Ray
- location: Spawn area (ray machine)
- hint_minimal: Now kill what you built.
- hint_standard: Use the ray machine once more to fire the Death Ray at the body; it is vaporized and leaves a key.
- hint_detailed: Use the machine after the reversed code. The Death Ray vaporizes the body on the slab and a glowing key effect appears where it was.
- detect: no flag. Poll level.key_spawned (mpq.gsc:1238)
- marker: key fx level.key_fx at level.knife_throw_target_body.origin + (0,0,32) (mpq.gsc:561, body origin mpq.gsc:460)
- status: VERIFIED (script mpq.gsc:1232-1271; Prima/Gameranx: activate the Death Ray, the zombie is killed and drops a key)

#### 29. id: take_garage_key
- objective: Take the garage key
- location: Spawn area (body slab)
- hint_minimal: Something glints on the slab.
- hint_standard: Interact with the slab where the body was to pick up the key.
- hint_detailed: Use the body slab where the key glows. This is the key for the gas station garage.
- detect: no flag. Poll level.garage_key_found (mpq.gsc:483); set_completed_quest_mark( 1 ) at mpq.gsc:481
- marker: level.key_fx (mpq.gsc:561)
- status: VERIFIED (script mpq.gsc:475-485; Prima/Gameranx: key dropped). Key = garage key is SCRIPT ONLY (mpq.gsc:1082-1100).

#### 30. id: open_garage
- objective: Open the gas station garage
- location: Gas station
- hint_minimal: The key fits a roll-up door.
- hint_standard: Use the key on the gas station garage door to open it and reach the chemistry lab.
- hint_detailed: Interact with the gas station garage door while the key is found; it rolls up and the lab inside becomes reachable.
- detect: no flag. Poll level.garage_door_open (mpq.gsc:1096)
- marker: getent( "garage_door", "targetname" ) at mpq.gsc:1090 (sound pos (4767,1233,431) mpq.gsc:1092)
- status: VERIFIED (script mpq.gsc:1082-1100; web summary: "the gas station garage unlocks a chemical station")

### Phase 2 - chemistry (quest line "chemistry")

#### 31. id: chem_set_parts
- objective: Find the 3 chemistry set parts
- location: NEEDS RESEARCH (random spots)
- hint_minimal: The lab is missing its equipment.
- hint_standard: Find the beaker, the clamp and the burner for the chemistry set.
- hint_detailed: Each part spawns at one of several random spots each game. Interact to pick it up (shared for the team); then place them in the garage lab.
- detect: no flag. Poll level.chem_pieces.size == 3 (craft.gsc:426-429); icon bits 12/13/14 (craft.gsc:434-443)
- marker: getstructarray( "crafting_piece", "script_noteworthy" ) at craft.gsc:56; chem ones have .name "chem_beaker"/"chem_clamp"/"chem_burner" and the spawned model in .item (craft.gsc:90-99, spawned via spawn_crafting_pieces( "chem", ... ) craft.gsc:74)
- status: SCRIPT ONLY (craft.gsc:53-99, 413-445). Locations NEEDS RESEARCH (randomized).

#### 32. id: build_chem_set
- objective: Build the chemistry set
- location: Gas station garage lab
- hint_minimal: Assemble the lab.
- hint_standard: Add the three parts to the chemistry station in the gas station garage.
- hint_detailed: Interact with the chemistry station in the garage; each part you hold is added. When all 3 are in, the computer screen lights up and the beakers appear.
- detect: flag_set( "chemistry_step1" ) at craft.gsc:319 (flag_init mpq.gsc:48); set_completed_quest_mark( 3 ) at craft.gsc:331
- marker: getent( "chem_computer", "targetname" ) at chem.gsc:167 (station itself is the "crafting_station_chem" interaction, registered craft.gsc:11; no direct getstruct)
- status: VERIFIED (script craft.gsc:281-345; web: chemistry lab in the gas station garage; Prima: build the formula/chem step)

#### 33. id: learn_formula
- objective: Learn the formula on the radios
- location: NEEDS RESEARCH (radios around map)
- hint_minimal: Dr. Bright's tapes name the chemical that kills the beast.
- hint_standard: Play Dr. Bright's radio tapes to learn which compound can kill the monster and which elements build it.
- hint_detailed: Use the radios to hear Dr. Bright's tapes (a radio can replay only after the next round). Note the target compound and its ingredients; the chalkboards help work out the recipe.
- detect: manual
- marker: getstructarray( "chem_radio_interaction", "script_noteworthy" ) at chem.gsc:2102; chalkboards getentarray( "blackboard_model", "script_noteworthy" ) at chem.gsc:742
- status: VERIFIED in outline (script chem.gsc:2078-2200 radios, 2450-2465 random final compound; Prima: learn which chemical Dr. Bright says will kill the monster, helpful chalkboards). Recipes are in cp/zombies/compounds.csv / elements.csv, NOT in the dump -> NEEDS RESEARCH.

#### 34. id: brew_chem_mix
- objective: Create & carry Chem Mix
- location: Gas station garage lab
- hint_minimal: Mix the right elements with the right reaction number.
- hint_standard: Put the right elements in the beakers, enter the reaction number on the computer, start the reaction, then pick up the result.
- hint_detailed: Fill beakers with the needed elements. Number = sum of two diamond values of each element minus the O constant; the right colour view (Technicolor machine) shows which. Type it, press start, take the compound.
- detect: flag_set( "chemistry_step3" ) at chem.gsc:1105, 1736 or 1878 (flag_init mpq.gsc:50); set when a player takes level.bomb_compound.name from compound storage
- marker: reaction start getstruct( "reaction_start_model", "script_noteworthy" ) at chem.gsc:896; beakers getstructarray( "chemistry_container_model", "script_noteworthy" ) at chem.gsc:1561; outputs getstructarray( "compound_storage_model", "script_noteworthy" ) at chem.gsc:1604
- status: VERIFIED in outline (script chem.gsc:1113-1175 formula, 1092-1111/1713-1741/1855-1883 pickup; int.gsc ~1840-1897 colour views; Prima: add the top and left numbers of each ingredient's chemical diamond, subtract O; numbers/colours change each game). Exact recipes NEEDS RESEARCH. Devgui label for this step: " Create & carry Chem Mix " (mpq.gsc:15).

### Phase 3 - launch codes and nuke (quest line "launchcode")

#### 35. id: find_safe_numbers
- objective: Find the four safe numbers
- location: Beachside Market (under desk)
- hint_minimal: Look low in the back of the Beachside Market.
- hint_standard: Look under the desk in the back of the Beachside Market to read four numbers.
- hint_detailed: Go to the back of the Beachside Market and look under the desk; four number signs show the combination (random each game, digits from 1,2,4,6,7,8,9). Write them down.
- detect: manual
- marker: getentarray( "pressure_numbers", "targetname" ) at mpq.gsc:2091
- status: VERIFIED (script mpq.gsc:2076-2107; Prima: look under the desk in the back of the Beachside Market for four numbers). Prima summary says "using the crowbar" here; script shows no crowbar gate on reading the numbers.

#### 36. id: set_gauges
- objective: Set the 4 pressure gauges
- location: Gas station, Snack Shack, Power Stn, Motel
- hint_minimal: Four gauges around town must match the numbers.
- hint_standard: Hit each of the four pressure gauges with the Crowbar so its needle stops on one of the four numbers.
- hint_detailed: Gauges: behind the gas station, right side of the Snack Shack, behind the shack at the Power Station, in the Crowbar motel room. Crowbar-hit to freeze the swinging needle on a needed number; hit again to release.
- detect: flag_set( "launchcode_step1" ) at mpq.gsc:1873 (flag_init mpq.gsc:52)
- marker: getentarray( "mpq_gauge_trig", "targetname" ) at mpq.gsc:361 (needle ent getent( trig.target, "targetname" ) mpq.gsc:1836)
- status: VERIFIED (script mpq.gsc:1833-1879, 1952-2050, 2109-2142; Prima gauge locations). Note: any gauge can show any of the numbers (order-free match, mpq.gsc:2109-2142).

#### 37. id: take_launch_codes
- objective: Take the launch codes
- location: Beachside Market safe
- hint_minimal: The safe is open.
- hint_standard: Take the nuclear launch codes from the open safe in the Beachside Market. Write the code down.
- hint_detailed: Interact with the open safe in the back of the Beachside Market to take the codes. You cannot check them during code entry later, so note the 5-digit code.
- detect: flag_set( "launchcode_step2" ) at mpq.gsc:1920 (flag_init mpq.gsc:53); safe opens in launchcode_step_1_complete (mpq.gsc:372-377 -> phase3_open_safe mpq.gsc:1881-1911)
- marker: getstruct( "take_launchcodes", "script_noteworthy" ) at mpq.gsc:1887; safe getent( "town_safe", "targetname" ) at mpq.gsc:360
- status: VERIFIED (script; Prima/Gameranx: safe opens, take codes, write them down). Code = level.nuclear_code, 5 distinct digits 1-9 (bomb.gsc:487-502).

#### 38. id: nuke_parts
- objective: Find the 3 nuke parts
- location: NEEDS RESEARCH (red car, stream end, ?)
- hint_minimal: The nuke's teleporter is in three pieces.
- hint_standard: Collect the three nuke teleporter parts: one under the red car, one at the end of the stream, one more.
- hint_detailed: Part 1: go prone at the red car between the motel and the TV Studio (it can only be taken while prone). Part 2: end of the stream that runs under the bridge. Part 3: NEEDS RESEARCH.
- detect: no flag. Poll level.teleporter_pieces_found == 3 (mpq.gsc:1948); icon bits 16/17/18 (mpq.gsc:1936-1942)
- marker: none direct (interaction structs "bomb_teleporter_part", registered mpq.gsc:453; model getent( struct.target, "targetname" ) mpq.gsc:1925)
- status: VERIFIED for parts 1-2 (script prone check mpq.gsc:1932-1936; web: first part under the red car between motel and TV Studio, second at the end of the stream under the bridge). Third part location NEEDS RESEARCH.

#### 39. id: build_nuke
- objective: Build the bomb
- location: NEEDS RESEARCH (nuke stand)
- hint_minimal: Bring the parts to the nuke.
- hint_standard: Place all three teleporter parts on the nuke stand.
- hint_detailed: Interact with the nuke stand to place every part you hold; when the third goes in the teleporter is built.
- detect: flag_set( "launchcode_step3" ) at mpq.gsc:2232 (flag_init mpq.gsc:54)
- marker: getstruct( "place_bomb_parts", "script_noteworthy" ) at mpq.gsc:2193 (nuke model getent( struct.target, "targetname" ) mpq.gsc:2194)
- status: VERIFIED (script mpq.gsc:2221-2236; Prima: put supplies/formula onto the Nuke). Devgui label " Build bomb" (mpq.gsc:19).

#### 40. id: add_chem_mix
- objective: Add Chem Mix to the bomb
- location: NEEDS RESEARCH (nuke stand)
- hint_minimal: The bomb needs its payload.
- hint_standard: Carry the Chem Mix compound to the nuke and add it.
- hint_detailed: Carry the bomb compound from the lab (only one chemical can be carried) and interact with the nuke. The hero photo changes on success.
- detect: flag_set( "chemistry_step4" ) at mpq.gsc:2168 (flag_init mpq.gsc:51)
- marker: getstruct( "place_bomb_parts", "script_noteworthy" ) at mpq.gsc:2193
- status: VERIFIED (script mpq.gsc:2161-2180; Prima: add the formula to the nuke). Devgui label " Add Chem Mix to bomb" (mpq.gsc:16).

#### 41. id: charge_nuke
- objective: Charge the bomb teleporter
- location: NEEDS RESEARCH (nuke stand)
- hint_minimal: Everyone needs to power the teleporter together.
- hint_standard: All players stand at the nuke and hold Use together to start charging; defend it for 20 seconds.
- hint_detailed: Requires codes taken, bomb built, Chem Mix added. Every player within 96 units holds Use. It charges for 20 s; then it stays charged only 30 s, so be ready to teleport.
- detect: flag_set( "teleporter_charged" ) at mpq.gsc:2262 (flag_init mpq.gsc:356); cleared after 30 s at mpq.gsc:2277
- marker: getstruct( "place_bomb_parts", "script_noteworthy" ) at mpq.gsc:2251
- status: VERIFIED (script mpq.gsc:2204-2219, 2247-2279; Gameranx/Prima: everyone interacts with the Nuke so it can charge)

#### 42. id: teleport_nuke
- objective: Teleport the bomb
- location: NEEDS RESEARCH (nuke stand)
- hint_minimal: Send the bomb (and yourselves) to the beast.
- hint_standard: While charged, all players hold Use at the nuke again to teleport it and start the boss fight.
- hint_detailed: Within 30 s of full charge, every player within 96 units holds Use. The nuke leaves and all players are sent to the beach. If the window passes, charge again.
- detect: flag_set( "launchcode_step4" ) at mpq.gsc:2287 (flag_init mpq.gsc:55); level notify( "crab_boss_quest_completed" ) at mpq.gsc:2288; also level notify( "bomb_teleported" ) at mpq.gsc:2197
- marker: getstruct( "place_bomb_parts", "script_noteworthy" ) at mpq.gsc:2283
- status: VERIFIED (script mpq.gsc:2182-2202, 2281-2289; Gameranx: once charged, everyone interacts again and is teleported to the boss fight)

---------------------------------------------------------------------------------------------------

## C. Boss fight (quest line "crabBoss", cbf.gsc:6-10)

### Preparation
- The boss agent spawns at game start far out at sea (cbf.gsc:18-34, spawn (6491,11387,-439)).
  Its approach is gated by `advance_pre_combat_stage()` (cbf.gsc:57-63), which is called (a) when
  the "bridge_beach" volume is activated, i.e. the beach area is opened (cbf.gsc:71-83) and (b) when
  launchcode step 3 starts, i.e. right after the launch codes are taken (mpq.gsc:401-405). The first
  call sets flag "crab_boss_pre_combat_stage_1" (cbf.gsc:60), the second "crab_boss_pre_combat_stage_2"
  (cbf.gsc:62); after stage 2 it moves into the cove and sets flag "crab_boss_combat_ready"
  (cbf.gsc:193; init cbf.gsc:49). The escort waits on that flag (esc.gsc:17). So the beach area
  must be open AND codes taken before the fight can progress (script inference; see E).
- During the fight: teleport/fast travel disabled (cbf.gsc:230-248), respawn on the beach
  (cbf.gsc:347-365), lost-and-found moved to the beach (cbf.gsc:310-345), blockers around the arena
  (cbf.gsc:757-773), free Max Ammo every 180 s at (2933,1994,-31) (cbf.gsc:273-296). Elvira can be
  summoned at the beach with a full vial (elv.gsc:82-185). Bring explosives/lock-on launcher: weak
  spot takes 4500 per hit from "iw7_lockon_zm" weapons, 15000 per Death Ray cannon hit, 1 otherwise
  (ray.gsc:397-445).
- Start detection: level notify( "crab_boss_quest_completed" ) at mpq.gsc:2288 (waited at cbf.gsc:153);
  flag_set( "boss_fight_active" ) at cbf.gsc:227 (flag_init cbf.gsc:32).

### Boss objectives (in order)

#### B1. id: boss_escort
- objective: Escort the nuke to the water
- location: Beach
- hint_minimal: The nuke only moves while someone is next to it.
- hint_standard: Stay close to the nuke cart so it rolls down the stream to the water's edge. Shoot the egg sacs and Crogs.
- hint_detailed: The cart moves only while a standing player is within ~250 units. Egg sacs fly in and hatch Crogs or explode; kill them. At the water's edge the cart slingshots the nuke into the beast.
- detect: level notify( "escort_sequence_ended" ) at esc.gsc:374 (also level.escort_sequence_completed = 1 esc.gsc:252)
- marker: level.escort_vehicle (spawned at getvehiclenode( "bomb_vehicle_start", "targetname" ) esc.gsc:79); devgui label "Escort the Bomb" (cbf.gsc:7)
- status: VERIFIED (script esc.gsc:4-31, 105-153, 235-256; Gameranx/Prima: push the nuke to the water's edge, it is sent inside the Radioactive Thing)

#### B2. id: boss_cannon_hit
- objective: Hit the weak spot with a cannon
- location: Beach (Death Ray cannons)
- hint_minimal: The beach cannons can expose its weak spot.
- hint_standard: Mount a Death Ray cannon, hold fire to charge it and hit the glowing weak spot on the beast.
- hint_detailed: Use a Death Ray cannon (left, right, centre or back). Hold fire until the charge bar fills; it fires. Aim at the weak spot on its upper back. The first hit exposes the weak spot for everyone.
- detect: level notify( "crab_boss_weak_spot_initial_hit" ) at ray.gsc:444 (waited cbf.gsc:591)
- marker: getstructarray( "death_ray_cannon", "script_noteworthy" ) at ray.gsc:213 (level.death_ray_cannons, keys left/right/center/back ray.gsc:584-603); weak spot level.crab_boss.crab_boss_weak_spot (ray.gsc:569-582)
- status: SCRIPT ONLY (ray.gsc:210-232, 304-363, 427-455). Gameranx summary only says "keep firing at the core".

#### B3. id: boss_weak_spot
- objective: Damage the weak spot
- location: Beach
- hint_minimal: Keep hurting the exposed weak spot.
- hint_standard: Keep shooting the weak spot until the beast recoils. Cannon hits and lock-on launchers do the most damage.
- hint_detailed: Deal players x 30000 damage to the weak spot: cannon hit 15000, lock-on launcher hit 4500, other hits 1. Zombies spawn faster as it weakens. The phase ends when it recoils and heals.
- detect: level.crab_boss notify( "stop_death_ray_attack_logic" ) at cbf.gsc:610 (entity notify on the boss, not level); next step's start is the only level-side signal (none). Treat as: poll quest index level.zombie_current_quest_step_index[ "crabBoss" ] >= 3 (cp/zombies/zombie_quest.gsc:28)
- marker: level.crab_boss.crab_boss_weak_spot (ray.gsc:569-582)
- status: SCRIPT ONLY (cbf.gsc:581-614). Devgui label "Death Ray Cannon" (cbf.gsc:8).

#### B4. id: boss_arm_cart
- objective: Charge the cart teleporter
- location: Beach (nuke cart)
- hint_minimal: Everyone back to the cart.
- hint_standard: All players gather at the nuke cart and hold Use together to start its teleporter charging.
- hint_detailed: Every player (not downed, not carrying) within 150 units of the cart holds Use at once. This disables the cannons and starts the Wall of Death.
- detect: level notify( "players_trigger_vehicle_teleporter" ) at wall.gsc:606 (via wail_all_player_trigger_teleporter, called wall.gsc:234); level.escort_vehicle.teleporter_activated = 1 (wall.gsc:238)
- marker: interaction origin hard-coded (3001, 2858, -158) at wall.gsc:286 (same point checked at wall.gsc:556)
- status: SCRIPT ONLY (wall.gsc:44-55, 217-251, 531-610)

#### B5. id: boss_wall_of_death
- objective: Survive the Wall of Death
- location: Beach
- hint_minimal: Hold out against the toxic waves.
- hint_standard: Survive the beast's three toxic wall attacks and the zombies they bring.
- hint_detailed: The beast spits three toxic walls, spawning zombies after each. Downed players are revived every 60 s until the cart is charged. Stay alive until the third wave ends.
- detect: level notify( "wall_of_death_completed" ) at wall.gsc:149
- marker: none (boss: level.crab_boss)
- status: SCRIPT ONLY (wall.gsc:4-150). Devgui label "Wall of Death" (cbf.gsc:9).

#### B6. id: boss_sonic_beam
- objective: Hold Use at the cart during roar
- location: Beach (nuke cart)
- hint_minimal: When it roars, answer from the cart.
- hint_standard: When the beast starts its sonic beam, all players hold Use at the nuke cart before the countdown ends.
- hint_detailed: The beam starts with a roar; you have about 12 s (7 s then a 5..1 countdown). Every player within 400 units of the cart holds Use together. Success sends everyone inside the beast; failure repeats Wall of Death.
- detect: level notify( "sonic_ring_success" ) at ring.gsc:141 (fail: level notify( "sonic_ring_fail" ) ring.gsc:164; start: level notify( "sonic_ring_start" ) ring.gsc:153)
- marker: level.escort_vehicle (distance check ring.gsc:96); beam origin getstructarray( "sonic_ring_controlling_struct", "targetname" ) at ring.gsc:44
- status: SCRIPT ONLY (ring.gsc:4-170). Devgui label "Sonic Beam" (cbf.gsc:10).

#### B7. id: boss_enter_codes
- objective: Enter the launch codes
- location: Inside the beast
- hint_minimal: Arm the nuke from the inside.
- hint_standard: Inside the beast, use your bomb panel and enter the 5-digit launch code from the safe within 30 seconds.
- hint_detailed: Each player is teleported to a panel. Enter the safe's 5-digit code by stopping the cycling counter on each digit; 3 wrong digits eject you from the panel (use it again). All players must finish within 30 s or the final sequence repeats.
- detect: level notify( "nuclear_bomb_armed" ) at bomb.gsc:630; fail path: timer bomb.gsc:682-702 -> end_detonate_bomb( 0 ) -> replay_final_sequence (cbf.gsc:746-755)
- marker: getstructarray( "bomb_start", "script_noteworthy" ) at bomb.gsc:523 (panels, per-player random at bomb.gsc:9)
- status: SCRIPT ONLY (bomb.gsc:4-21, 49-172, 619-638, 682-702). Walkthrough summaries read do not cover this phase.

### End detection
- Success: flag_set( "boss_fight_finished" ) at bomb.gsc:195 (flag_init cbf.gsc:33) together with
  flag_clear( "boss_fight_active" ) bomb.gsc:194; level notify( "crab_boss_fight_complete" ) at
  bomb.gsc:217. (Director's-cut/direct-boss mode path: bomb.gsc:197-203.)
- Fail/retry: sonic beam fail or code timeout calls replay_final_sequence (cbf.gsc:746-755), which
  re-runs Wall of Death + Sonic Beam as quest line "replayCrabBossFinalSequence".

---------------------------------------------------------------------------------------------------

## D. Final objective and completion

- Final tracker objective: "Enter the launch codes" (B7), then "Easter egg complete".
- Completion detection (choose one):
  1. flag "boss_fight_finished" set (bomb.gsc:195) - immediate, fires on success only.
  2. level notify( "crab_boss_fight_complete" ) at bomb.gsc:217 - immediate.
  3. Rewards, 71.15 s later (bomb.gsc:270-292): level.defeated_crogboss = 1 (:274); per player
     setplayerdata cp haveSoulKeys soul_key_4 (:281), achievement "SOUL_LESS" (:282), merit
     "mt_dlc3_boss_killed" (:279); set_completed_quest_mark( 4 ) (:292); announcer VO
     "ww_easteregg_complete" (:293). Outro bink "sysmainunload" plays at 1.15 s (bomb.gsc:225-230).
  - Do NOT use level notify( "crab_boss_beaten" ) (bomb.gsc:265): only sent when Director's Cut is
    active.

---------------------------------------------------------------------------------------------------

## E. Open questions

1. Phase 1 (steps 9-30) has no flags or level notifies in normal play (deathray_step flags are dead,
   see A). Guided Mode must poll level variables (listed per step) or hook the functions. Decide
   whether polling `level.*` from a GSC mod thread is acceptable.
2. Arm naming: Prima calls the RV Park firepit arm the "left arm" and the seismic beach arm the
   "right arm"; the scripts call the seismic arm "left_arm" (mpq.gsc:657-664) and the ungated one
   "right_arm". Mapping is inferred by elimination; confirm in game which ent is in the firepit.
3. Locations NEEDS RESEARCH (no walkthrough text read): Deep Freeze trap/torso room (steps 10-11),
   crafting bench for the seismic device and its part spots (13), mirror stands (22), film reel
   cases (25), chemistry set part spots (31), radios and chalkboards (33), third nuke part (38),
   nuke stand (39-42). The scripts give ent/struct names, but not area names.
4. Spell book location conflict: Prima says Ice Cream Shop safe; SegmentNext says near the Skull Hop
   machine in the Diner. Script only says "elvira_safe".
5. Vial filling: one web summary says the goo comes from green-uniform soldier zombies; scripts
   (elv.gsc:651-681) fill it only from Cleaver kills/hits. Verify in game.
6. Power: SegmentNext mentions a "Power Box on the hill near the Diner" as well as the lever; the
   scripts only show the lever ("missing_handle") and the broken switch ("generator_broken"). The
   power-box model is getent( "box", "script_noteworthy" ) (int.gsc:1973) but no pickup was found.
7. Head route: walkthrough says the head is in an RV reached from the Pack-a-Punch room wall button.
   Pack-a-Punch access is its own quest (fuses, anomaly; int.gsc:917-1300) and was not researched
   here; add it as a prerequisite step if Guided Mode should cover it.
8. Chemistry: the recipe tables (cp/zombies/compounds.csv, elements.csv, diapi_table.csv) are not in
   the decompiled dump, so the element list, which compounds are intermediates, and the diamond
   values cannot be given. Script facts: bomb compound random from "final" rows (chem.gsc:2450-2465),
   correct colour random red/green/blue (chem.gsc:2467-2479), O constant random (chem.gsc:2546-2607).
   Some elements are harvested by melee: animal fat with the Cleaver, silver and copper with the
   Crowbar (chem.gsc:677-708). There is no flag for an intermediate step ("chemistry_step2" is dead).
9. Walkthrough summary said the Life Ray code shows "nine numbers"; scripts require exactly 5 digits
   (mpq.gsc:1725-1728) from {3,4,5,6,8} (mpq.gsc:1536). Treat the script as correct.
10. Boss gating: does the "bridge_beach" volume open on its own when players are teleported to the
    beach, or must players buy that door beforehand? If not opened, crab_boss_pre_combat_stage_2
    and crab_boss_combat_ready (cbf.gsc:57-63, 193) may never be set and the escort waits forever
    (esc.gsc:17). Needs an in-game check; a safe Guided Mode step is "Open the beach area" before
    teleporting the nuke, detected by flag "crab_boss_pre_combat_stage_2" (cbf.gsc:62).
11. Steps 3/4 detection is per player (currentmeleeweapon); in co-op only the player doing the
    melee step needs the tool. Decide how the tracker shows per-player items.

---------------------------------------------------------------------------------------------------

## Appendix: raw research notes (traceability)

- Quest framework: cp/zombies/zombie_quest.gsc. start_quest_system() (called from
  cp/gametypes/zombie.gsc:243) threads every registered quest line in PARALLEL
  (start_quest_line, zombie_quest.gsc:21-35): init_func, then quest_step_func (blocks), then
  complete_func. level.zombie_current_quest_step_index[line] holds the running step index (:28).
- cp_town registers: "deathray" 0-6, "chemistry" 0-3, "launchcode" 0-3 (mpq.gsc:6-20);
  "crabBoss" 0-4 (cbf.gsc:6-10). cp_town_mpq_init threaded from cp_town.gsc:113;
  init_crab_boss_stage from cp_town.gsc:115; init_elvira from cp_town.gsc:177; chemistry init
  from cp_town.gsc:133; nuclear code generated at cp_town.gsc:76.
- Life/Death Ray machine state machine (ray_gun_activation_func mpq.gsc:1140-1277):
  insert card -> (needs all 6 parts picked up, :1160) code -> terminal_unlocked -> Life Ray
  (needs mirrors_placed > 2 and zom_parts_placed > 5, :1178-1181) -> body_made -> reversed code ->
  polarity_reversed -> Death Ray -> key_spawned. Wrong code: 3 wrong digits exit (mpq.gsc:1705-1716).
- Bomb charge/teleport require all players within 96 units (distance2dsquared 9216) holding Use
  (mpq.gsc:2184-2213).
- Glowing zombies = generic zombies with is_soldier (mpq.gsc:1407-1429).
- Direct boss fight mode (town_start_direct_boss_fight_func cp_town.gsc:2590-2602) skips the quest,
  gives Cleaver and vial meter: not part of the normal quest.

---------------------------------------------------------------------------------------------

## F. How the guide reads the steps (written with the guide, 2026-10-13)

The deathray line's state is in fields the v1.1.0 compiler cannot name (`mpq_zom_parts_picked_up`,
`mirrors_placed`, `punch_card_added`, `body_made`, `key_spawned`, `garage_door_open` …,
`KNOWN_LIMITATIONS.md` C10), so `guides/cp_town.gsc` reads what the scripts do to the world:
- A body part taken: its glow (`fx_ent`, spawned by `play_glow_on_parts`, `mpq.gsc:603-634`) is
  deleted by `zom_body_part_activation_func` (`:711`); the slab copy gets a glow when placed
  (`glow_bed_part`, `:503`), and the Life Ray deletes those glows when it builds the body (`:1186-1193`).
- The tree leg moves to `mpq_zom_l_leg_part_ground` and keeps its glow (`knock_leg_down`, `:798-811`);
  the cleaver leg moves to where the zombie died (`listen_for_death_by_cleaver`, `:1431-1445`).
- Mirrors: the bathroom shard and the car mirror entities are deleted when taken (`:884`, `:897`),
  Elvira's mirror too (`elv.gsc:455`); a placed mirror is a script model of the stand's model
  on the stand (`mirror_placement_activation_func`, `:923-941`).
- The Scantron card is moved into `punch_card_slot` when inserted (`:1150-1153`).
- The reversed code turns the `death_ray_sign` entities into `cp_town_camp_danger_deathraysign`
  (`nuclear_bomb_armed_sequence`, `:1754-1765`).
- The garage door is lowered at the start (`movez( -96 )`, `:1074`) and raised by the key
  (`movez( 96 )`, `:1091`): the guide waits for its `movedone`.
- The weak spot: `death_ray_cannon` sends `stop_death_ray_attack_logic` to the beast itself
  (`cbf.gsc:610`); the guide waits on the `crab_boss` agent.
- Crafting pieces this match uses have an `item`, hidden (`item.hidden`) when taken
  (`craft.gsc:53-99`, `:414-422`); nuke parts are entities deleted when taken (`mpq.gsc:1923-1946`).
- Steps done in any order are `step.parallel`; the Life Ray needs the body, the mirrors and the
  Scantron, the chemistry set its parts, the charged nuke the codes and the built bomb
  (`step.needs`). A failed sonic beam (`sonic_ring_fail`) or a code entry that runs out
  (`end_detonate_bomb` without `boss_fight_finished`) replays the end of the fight
  (`replay_final_sequence`, `cbf.gsc:746-755`): the guide goes back to charging the cart.
