# The Beast from Beyond (cp_final) - Main Easter Egg Quest (Guided Mode research)

STATUS: COMPLETE (script research, then a verification pass while writing the guide, 2026-10-13; see section E).

Script root for every file:line below: `.toolchain/src/iw7-gsc-dump/decompiled/scripts/`.
Unless a path is given, files are in `cp/maps/cp_final/` (e.g. `cp_final_mpq.gsc:2137`).
Web sources were read only as search-result summaries (WebFetch cannot resolve hosts here),
so walkthrough wording is second-hand and is marked as such.

---------------------------------------------------------------------------------------------

## A. Quest overview

**Quest name (in game data):** the main quest line is registered as quest `"MPQ"`
(`cp_final_mpq.gsc:198-208`). Its step descriptions are the game's own strings:
0 "Retrieve N31L's head", 1 "Place Neil's Head", 2 "Destroy Energy Doors", 3 "Fuse Puzzle",
4 "Entangle Button", 5 "Press Button", 6 "Complete Toggle Puzzle", 7 "Enter Bossfight".
The quest ends in the Rhino/Mammoth ("Cryptid") boss fight, which awards achievement `THE_END`
("The End?") (`cp_final_rhino_boss.gsc:2104`). A second, conditional boss, Mephistopheles,
follows only under Director's Cut conditions (section C/D).

**Players:** solo or co-op, 1-4 players. Script evidence: every boss/quest tuning array is indexed
`[level.players.size - 1]` with 4 entries (e.g. `cp_final_rhino_boss.gsc:695-699`), and the N31L
hack timer has a solo branch (`cp_final_mpq.gsc:876`: 240 s solo / 180 s co-op). The pressure
plate step has a solo-specific debounce (`cp_final_ghost_activation.gsc:153-159`).
Walkthrough (TrueAchievements comments, via search summary): the boss fight is hard; recommend
no more than two inexperienced players.

**Prerequisites (things the MPQ steps physically depend on but do not themselves track):**
1. Power on = N31L's head installed (this *is* MPQ steps 0-1; `turnonfacilitypower`, `cp_final_mpq.gsc:2497-2501`).
2. The Entangler (crafted item). It is unlocked by the separate "ghostFive" quest line
   (Ghosts n' Skulls / "Skull Breaker"), steps 0-1 (`cp_final_ghost_activation.gsc:6-7`, unlock at
   `cp/crafted_entangler.gsc:18-33`). Needed for MPQ steps 2, 3 (vent disk), 4 and 6.
3. Theater access: the Cargo Bay "portal gun" button blasts open the cargo portal
   (`cp_final_fast_travel.gsc:418-436`, `298-362`); needed for the Theater button (MPQ step 4)
   and, per walkthrough, for one Pack-a-Punch bridge piece.
4. Pack-a-Punch reachable: bridge of 3 scrap pieces (`cp_final_mpq.gsc:2649-2663`, `2874-2922`,
   `2994-3030`); the head must be carried through the PaP portal (MPQ step 6) and the boss is
   entered from the PaP room computer (MPQ step 7).
5. For the Mephistopheles fight only: Director's Cut active and a player owning talismans
   `item_1..item_4` (`cp_final_rhino_boss.gsc:2066-2087`). Director's Cut also requires an online
   game (`cp/zombies/directors_cut.gsc:39-48`).
6. Venom-X wonder weapon quest ("Venom Quest", `cp_final_venomx_quest.gsc:1960-1963`) is NOT
   checked by any MPQ step (no MPQ step waits on its flags). Optional.

**Overview (one paragraph):** Drop into the Ops Center pit to recover N31L's head and install it
in the Spawn-room terminal, which turns the power on. In parallel, open the random wall box with
an explosive and shoot the skull, then hold the Cargo Bay pressure plate until a skull rises to
unlock the Entangler; open the Theater portal and build the Pack-a-Punch bridge. Use the Entangler
to throw a space helmet at the green monitor behind the Medical Bay forcefield, which destroys the
energy doors. Gather the four floppy disks (a Phantom drop, one near the PaP portal, one sent
through the Bang Bangs vent, one in the Forcefield Room), find the paper list that shows their
order and insert them into N31L's console; N31L turns evil. Entangle the small button from the
Theater wall into a "Beast From Beyond" poster, crouch to press it where it reappears under a desk
in the Forcefield Room, then make all 16 levers of the Medical Bay grid point the same way to hack
N31L. While he is hacked (3 min co-op / 4 min solo), entangle his head from the console and carry
it, following where it points, through the PaP portal into the computer on the right of the PaP
room. All players then use that computer to start the Cryptid boss fight (4 Rhinos, waves, consoles,
EMP defence, 2 Mammoths). Killing both Mammoths ends the quest (cutscene, "The End?"); with
Director's Cut + the four talismans, the Mephistopheles fight follows.

**Generic auto-detection hook (script-verified):** `cp/zombies/zombie_quest.gsc:21-36` runs each
registered quest line step by step and writes `level.zombie_current_quest_step_index[<quest>] = <step>`
at the start of each step (`zombie_quest.gsc:28`). So for quest `"MPQ"`, index N means steps 0..N-1
have completed (their complete_func ran). Same works for `"ghostFive"` (Entangler line). The last
step of a line never advances the index, so use its flag instead.

**Sources:**
- Scripts: `cp_final_mpq.gsc`, `cp_final_ghost_activation.gsc`, `cp/crafted_entangler.gsc`,
  `cp_final_rhino_boss.gsc`, `cp_final_final_boss.gsc`, `cp_final_fast_travel.gsc`,
  `cp_final_interactions.gsc`, `cp_final.gsc`, `cp/zombies/zombie_quest.gsc`,
  `cp/zombies/directors_cut.gsc`, `asm/dlc4_boss/dlc4_boss_asm.gsc`.
- Web (search summaries only): TrueAchievements "The End?" guide and walkthrough
  (https://www.trueachievements.com/a242141/the-end-achievement,
  https://www.trueachievements.com/game/Call-of-Duty-Infinite-Warfare/walkthrough/9);
  SegmentNext (https://segmentnext.com/infinite-warfare-zombies-the-beast-from-beyond-easter-egg/);
  Gameranx (https://gameranx.com/features/id/120160/article/cod-zombies-the-beast-from-beyond-the-complete-easter-egg-guide/);
  Zombies Codex (https://www.zombiescodex.com/infinite-warfare/the-beast-from-beyond/);
  mmmrkennedy (https://mmmrkennedy.com/games/IW/the_beast_from_beyond/the_beast_from_beyond_guide);
  player.one (https://www.player.one/call-duty-infinite-warfare-zombies-guide-beast-beyond-easter-egg-120086);
  CoD fandom mirrors (Rhino / Mammoth pages); Mejoress (Spanish PaP guide,
  https://www.mejoress.com/es/pack-a-punch-en-the-beast-from-beyond/).

---------------------------------------------------------------------------------------------

## B. Ordered steps

Order = the order a team must actually complete things (MPQ steps interleaved with their
prerequisites). `MPQ#n` = MPQ quest step index n.

### 1. retrieve_n31l_head  (MPQ#0 "Retrieve N31L's head")
- objective: Find N31L's head
- location: Ops Center pit (lower walkway)
- hint_minimal: N31L's head is somewhere below the Ops Center.
- hint_standard: Drop through the hole in the middle of the Ops Center onto the ledge below and follow the lower walkway to its end to pick up N31L's head.
- hint_detailed: In the Ops Center, drop through the hole in the floor and land on the ledge below (missing it is fatal). Follow the flooded lower walkway past the Tuff 'Nuff tunnel to its end and pick up N31L's head.
- detect: `flag_set( "neil_head_found" )` at `cp_final_mpq.gsc:2137` (headusefunc); `flag_init` at `cp_final_mpq.gsc:15`. Also `level.zombie_current_quest_step_index["MPQ"]` becomes 1.
- marker: `getstructarray( "neil_head", "script_noteworthy" )` at `cp_final_mpq.gsc:1978` (array is randomized; the chosen struct gets `.headmodel` at `cp_final_mpq.gsc:1988`, and the model is stored in `level._id_BEC5` at `cp_final_mpq.gsc:1990`). Use the struct whose `.headmodel` is defined, or `level._id_BEC5.origin`, before pickup.
- status: VERIFIED. Script: pickup interaction "neil_head" (`cp_final_mpq.gsc:301`, `2135-2141`). Walkthrough: Zombies Codex, mmmrkennedy, Gameranx power guide (search summaries) all place it at the end of the walkway under the Ops Center pit. Note: script picks randomly among `neil_head` structs, guides describe one fixed spot (see E).

### 2. install_n31l_head  (MPQ#1 "Place Neil's Head") - turns the power on
- objective: Install N31L's head at Spawn
- location: Spawn room, N31L terminal
- hint_minimal: N31L needs his head back before the power comes on.
- hint_standard: Return to the Spawn room and use N31L's terminal to install his head. This turns the power on.
- hint_detailed: Carry the head back to the Spawn room and interact with N31L's terminal. Installing it turns on facility power, enables the floppy disk slots and disks, and enables the Cargo Bay portal button. The power is not on until the head is actually installed.
- detect: `flag_set( "neil_head_placed" )` at `cp_final_mpq.gsc:2063` (consoleusefunc); `flag_init` at `cp_final_mpq.gsc:16`. Power: `level notify( "power_on" )` `cp_final_mpq.gsc:2499`, `flag_set( "restorepower_step1" )` `:2500` (init `cp_final_venomx_quest.gsc:1971`), `flag_set( "power_on" )` `:2501`.
- marker: `getent( "neil_console", "targetname" )` at `cp_final_mpq.gsc:33` (`level.neil_console`); interaction structs `getstructarray( "neil_console", "script_noteworthy" )` at `cp_final_mpq.gsc:1698`.
- status: VERIFIED. Script: completeplaceneilshead -> turnonfacilitypower (`cp_final_mpq.gsc:2312-2318`, `2497-2501`). Walkthrough: Zombies Codex / mmmrkennedy / Gameranx summaries ("install at Spawn terminal").

### 3. open_theater_portal  (prerequisite, not an MPQ step)
- objective: Open the Theater portal
- location: Cargo Bay upper catwalk button
- hint_minimal: A button in the Cargo Bay controls a big cannon.
- hint_standard: With power on, press the wall button on the Cargo Bay upper catwalk. The cannon blasts open the portal doors to the Theater.
- hint_detailed: Power must be on first. Press the wall button on the Cargo Bay upper catwalk; the laser cannon moves, fires and destroys the doors of the Cargo Bay portal, which leads to the Theater. Needed for the Theater button step and a Pack-a-Punch bridge piece.
- detect: manual. No flag/notify; script sets `level.portal_gun_activated = 1` at `cp_final_fast_travel.gsc:434` (pollable variable). Portal opened as `.opened = 1` on the "cargo_room" `fast_travel_portal` struct (`cp_final_fast_travel.gsc:343-354`).
- marker: `getent( "portal_gun_button", "targetname" )` at `cp_final_fast_travel.gsc:424` (interaction struct noteworthy "portal_gun_button", activated at `cp_final_mpq.gsc:2318`).
- status: VERIFIED. Script: `portal_gun_activate_func` requires `power_on` (`cp_final_fast_travel.gsc:420-436`) and `blast_doors_with_gun` (`:298-362`) opens the cargo_room portal. Walkthrough: Zombies Codex summary ("press the wall button in the Cargo Bay upper catwalk, which opens the portal to the Theatre film set"). That the cargo portal's destination is the Theater is walkthrough-only.

### 4. blow_open_skull_box  (prerequisite: quest "ghostFive" step 0 "Blow up Ghost-n-Skull box")
- objective: Blow open the skull box
- location: Random wall box (1 of 3 spots)
- hint_minimal: An explosion will crack open a hidden wall box.
- hint_standard: Find the wall control box (random spot, one is above the curving Cargo Bay stairs) and hit it with explosive damage, then shoot the skull.
- hint_detailed: The box spawns at one random spot (guides: 3; one is up and right from the landing of the curving Cargo Bay stairs). Damage it with any explosive (grenade, launcher splash). The door opens and a green 8-bit skull slides out: shoot it to finish.
- detect: manual / quest index. No flag or notify; completion is `level.zombie_current_quest_step_index["ghostFive"]` becoming 1 (`cp/zombies/zombie_quest.gsc:28`), complete_func `cp_final_ghost_activation.gsc:131-134` only plays a sound.
- marker: `getstructarray( "ghost_n_skull_box", "script_noteworthy" )` at `cp_final_ghost_activation.gsc:22` (one picked at random; the picked struct gets the box model in `._id_2F12` at `:128`).
- status: VERIFIED. Script: explosive MODs accepted at `cp_final_ghost_activation.gsc:90-103`, skull must be damaged by a player (`:53-71`). Walkthrough: Gameranx summary ("crack open a power box with a grenade explosion", "8-bit skull will appear. Shoot it!", "one of three random locations", Cargo Bay spot); SegmentNext summary ("use a grenade to open a Fuse Box containing a Skull").

### 5. hold_pressure_plate  (prerequisite: "ghostFive" step 1 "Stay at pressure plates")
- objective: Hold the pressure plate
- location: Pressure plate (map marker shown)
- hint_minimal: Everyone has to stand together on the marked floor plate.
- hint_standard: All players stand on the pressure plate for 60 seconds while zombies attack, then reach the skull before it vanishes.
- hint_detailed: Every player must stay inside the plate area; anyone leaving cancels the charge (retry next round). After 60 s the glowing skull flies to one of 4 nearby spots: walk into it within about 12 s or it times out. Collecting it unlocks the Entangler.
- detect: `level notify( "complete_stay_on_pressure_plates" )` at `cp_final_ghost_activation.gsc:256`.
- marker: `getent( "pressure_plate_volume", "targetname" )` at `cp_final_ghost_activation.gsc:355`; `getstructarray( "pressure_plate_center", "script_noteworthy" )` at `:201` (the game turns on its own map marker here, `:199-205`). Skull: `level.skull_meter` (`:277`), moved to one of 4 fixed origins (`:290`).
- status: VERIFIED for mechanics (script `cp_final_ghost_activation.gsc:141-192`, `238-252`, `352-366`); walkthrough summaries: "standing on the red X markers and killing zombies until a skull rises" (Zombies Codex/others), "failed attempt means next round". Exact room name of the plate: NEEDS RESEARCH (script coords near (1467, 2775, -277); guides say Entangler appears in the Cargo Bay).

### 6. pick_up_entangler
- objective: Pick up the Entangler
- location: Cargo Bay (center)
- hint_minimal: Something new is floating in the Cargo Bay.
- hint_standard: Collect the Entangler that now floats above a glowing marker. Equip it with the crafted-item button to grab outlined objects.
- hint_detailed: Each player can take the Entangler from its spawn point. Equip it with the crafted-item button (action slot 3), aim at outlined objects to pull them toward you, then launch them. It is needed for the helmet, the vent disk, the Theater button and N31L's head.
- detect: manual. Per-player `player.hascraftedentangler = 1` at `cp/crafted_entangler.gsc:56` (and `.hascollectedentangler` at `:74`). Availability: notify in step 5.
- marker: `getstruct( "entangler_spawner", "script_noteworthy" )` at `cp/crafted_entangler.gsc:24`.
- status: VERIFIED. Script `cp/crafted_entangler.gsc:18-58`, `cp_final_mpq.gsc:548-555`; walkthrough: Gameranx/SegmentNext summaries ("Entangler appearing in the center of the Cargo Bay after a second skull is collected").

### 7. build_pap_bridge  (prerequisite: Pack-a-Punch quest)
- objective: Build the Pack-a-Punch bridge
- location: Cargo Bay, Medical Bay, Theater
- hint_minimal: Pack-a-Punch is cut off; scrap could bridge the gap.
- hint_standard: Collect the 3 scrap pieces (Cargo Bay, Medical Bay, Theater) and use the bridge spot to build the bridge to the Pack-a-Punch portal.
- hint_detailed: Pick up three scrap pieces: one in the Cargo Bay, one in the Medical Bay, one in the Theater (open the Theater portal first). Each pickup spawns a few Cryptids. Place them at the bridge site; the 3rd piece completes it and opens the way to the PaP portal.
- detect: `flag_set( "bridge_constructed" )` at `cp_final_mpq.gsc:3025` (flag_init `:2956`). Pieces: `flag_set( "bridge_pieces_collected" )` at `:2921` (init `:2662`).
- marker: pieces `getstructarray( "pap_bridge", "script_noteworthy" )` at `cp_final_mpq.gsc:2651`; build spot `getstruct( "construct_bridge", "script_noteworthy" )` at `:2958`; PaP portal `getstruct( "pap_portal", "script_noteworthy" )` at `cp_final_interactions.gsc:652`.
- status: VERIFIED (counts and flags). Script: 3 pieces required (`cp_final_mpq.gsc:2920`), each pickup calls `trigger_goon_event` (`:2881`). Walkthrough: mmmrkennedy summary ("three scrap pieces for the bridge, one each in Cargo Bay, Medical Bay, and the Theatre"); Mejoress (Spanish) lists different piece spots (see E).

### 8. break_medbay_forcefield  (MPQ#2 "Destroy Energy Doors")
- objective: Break the Med Bay forcefield
- location: Medical Bay, Forcefield Room
- hint_minimal: Something thrown at the right monitor could kill that forcefield.
- hint_standard: Entangle a white space helmet, take it to the Medical Bay and launch it at the green monitor behind the forcefield.
- hint_detailed: Power must be on. Grab any space helmet with the Entangler, go to the Medical Bay forcefield room (Cryptid autopsy room) and launch the helmet so it lands on the green monitor behind the forcefield. The monitors crack and both energy doors are destroyed.
- detect: `flag_set( "security_doors_deactivated" )` at `cp_final_mpq.gsc:1692` (flag_init `:20`); then `level notify( "kill_energy_doors" )` at `:2539` when the step completes.
- marker: `getstructarray( "med_bay_monitors", "targetname" )` at `cp_final_mpq.gsc:1774` (item must collide within 56 units, `:1683`); helmets `getstructarray( "entangler_structs", "targetname" )` at `cp/crafted_entangler.gsc:369`; doors are spawned at hard-coded origins (16,5583,115) and (144,6168,115) at `cp_final_mpq.gsc:3097` (`level.all_quest_doors`).
- status: VERIFIED. Script: waits `restorepower_step1` then any `entangler_item_collision` near a monitor (`cp_final_mpq.gsc:1673-1694`; notify sent for thrown items at `cp/crafted_entangler.gsc:823`). Walkthrough: SegmentNext ("launch the Space Helmet at the Green Monitor in the Forcefield Room"), Gameranx ("throw a white helmet through the Cryptid autopsy room forcefield at a green monitor").

### 9. get_phantom_disk  (part of MPQ#3 "Fuse Puzzle")
- objective: Get the Phantom's floppy disk
- location: Anywhere (first Phantom kill)
- hint_minimal: A big blue Cryptid is carrying a floppy disk.
- hint_standard: Kill a Phantom (big blue Cryptid). The first one killed in a reachable spot drops a floppy disk; pick it up.
- hint_detailed: Phantoms spawn in rounds and after the Pack-a-Punch portal goes on cooldown. Kill one where the disk can land in the play area and pick up the dropped disk. You can only carry one disk at a time, so insert it before taking another.
- detect: `flag_set( "phantom_disk_drop" )` at `cp_final.gsc:1976` / `:1982` (flag_init `cp_final_mpq.gsc:22`). Pickup itself: per-player `.haspuzzlepiece` (`cp_final_mpq.gsc:2052`) - manual.
- marker: none static (disk lands where the Phantom died; the game registers a new `puzzle_pieces` interaction struct at `cp_final.gsc:1992-2007`, so it is found via `getstructarray( "puzzle_pieces", "script_noteworthy" )` afterwards).
- status: VERIFIED. Script: `level.on_zombie_killed_quests_func = ::phantomfloppydiskdrop` (`cp_final.gsc:84`, `1940-1990`); PaP cooldown spawns a Phantom (`cp_final_fast_travel.gsc:786-848`). Walkthrough: SegmentNext/Zombies Codex ("first floppy from PaP area after the portal deactivates", "blue Cryptid spawns after you leave Pack-a-Punch", disk "from the Phantom").

### 10. send_disk_through_vent  (part of MPQ#3)
- objective: Shoot the disk into the vent
- location: Bang Bangs hallway grate
- hint_minimal: One disk is behind bars; the air vent nearby is pulling air in.
- hint_standard: In the hallway near Bang Bangs, entangle the floppy disk behind the bars and launch it at the sucking grate. It pops out of a vent elsewhere.
- hint_detailed: Use the Entangler on the disk behind the bars near Bang Bangs, then launch it so it lands near the grate that is sucking air. The vent swallows it and blows it out at a random landing vent (guides mention the Medical Bay). Pick it up there.
- detect: `level notify( "vent_grabbed_puzzle_piece", <disk> )` at `cp_final_mpq.gsc:436`.
- marker: vents `getstructarray( "air_suck_loc", "targetname" )` at `cp_final_mpq.gsc:389` (disk must land within 96 units, `:424`); landing spots `getstructarray( "puzzle_piece_landing", "targetname" )` at `:1893` (one picked at random, final spot = its `.target` struct `:1901`).
- status: VERIFIED. Script `cp_final_mpq.gsc:387-443`, `1881-1919`, `cp/crafted_entangler.gsc:446-450`. Walkthrough: SegmentNext/Gameranx/player.one summaries (Bang Bangs hallway, behind bars, shoot toward grate; player.one: Medical Bay landing areas).

### 11. collect_other_disks  (part of MPQ#3)
- objective: Collect the other floppy disks
- location: Left of PaP portal; Forcefield Room
- hint_minimal: Two more disks lie in plain sight once the way is open.
- hint_standard: One disk is on the left side of the Pack-a-Punch portal; another is on a table in the Forcefield Room behind the destroyed energy doors.
- hint_detailed: Power must be on for disks to be usable. Get the disk on the left-hand side of the PaP portal and the one on the tabletop in the Medical Bay Forcefield Room (needs step 8). Carry one disk at a time: insert each in its slot (step 13) before taking the next.
- detect: manual (pickup only sets per-player `.haspuzzlepiece`, `cp_final_mpq.gsc:2052`).
- marker: `getstructarray( "puzzle_pieces", "script_noteworthy" )` at `cp_final_mpq.gsc:1795` (each struct's `.model` is the disk; active only after power, `:2316-2317`).
- status: WALKTHROUGH ONLY for the two locations (SegmentNext: "left-hand side of Pack-a-Punch Portal"; TrueAchievements: "fourth disk on the tabletop in the Forcefield Room"); SCRIPT confirms map disks come from `puzzle_pieces` structs and are interactable only after power. Exact count of map structs: NEEDS RESEARCH (see E).

### 12. find_disk_order
- objective: Find the floppy disk order list
- location: Paper lists around the map
- hint_minimal: Each disk has a symbol; somewhere a list shows them together.
- hint_standard: Note the symbol on each of your four disks, then find the white paper list on the map that contains all four symbols. It gives the slot order.
- hint_detailed: Note the four disk symbols. Several white papers around the map list symbol combinations; only one contains all four. Its order is the slot order (guides disagree on reading direction, see notes). A wrong attempt rerolls the disk symbols, so recheck the list after a failure.
- detect: manual (no script event; papers are map art).
- marker: none.
- status: WALKTHROUGH ONLY (Gameranx summary: "find the white lists of floppy combinations across the map, find the list that has all four symbols"; TrueAchievements: "order ... listed right to left on the line"; Zombies Codex: "use the paper that matches the symbols"). Script only confirms the answer is one row of `cp/zombies/cp_final_puzzle_combos.csv` (`cp_final_mpq.gsc:1737-1754`, `1968-1974`), which is not in the dump. Reading direction: NEEDS RESEARCH.

### 13. insert_disks  (MPQ#3 "Fuse Puzzle" completion)
- objective: Insert the disks into N31L
- location: Spawn room, N31L console
- hint_minimal: N31L's console has four disk slots; order matters.
- hint_standard: Insert each disk into the matching numbered slot on N31L's console, following the order from the paper list.
- hint_detailed: The console has slots 1-4; the prompt shows the slot number. After the 4th disk the order is checked. Wrong: buzzer, disks respawn with new symbols and Cryptids attack - find the new list and retry. Right: N31L turns angry and starts using traps and doors.
- detect: `flag_set( "fuse_puzzle_completed" )` at `cp_final_mpq.gsc:2239` (flag_init `:17`). Progress: `level.insertedpieces.size` and omnvar `zm_floppy_count` (`:2213`). Failure: buzzer + `spawnpuzzlepieces()` reroll (`:2215-2232`).
- marker: slot structs `getstructarray( "fuse_puzzle", "script_noteworthy" )` (via `activateinteractionsbynoteworthy( "fuse_puzzle" )` at `cp_final_mpq.gsc:2316` -> `:1731`); console `level.neil_console` (`:33`).
- status: VERIFIED. Script `cp_final_mpq.gsc:2143-2256`, `2573-2642` (N31L goes evil: `neildoevilstuff` `:2579`, `:3395-3482`; achievement FRIENDS_FOREVER `:2584`). Walkthrough: TrueAchievements ("once entered correctly N31L will become Angry, activating Traps and Doors"; "a wrong attempt changes the symbols").

### 14. button_to_poster  (MPQ#4 "Entangle Button")
- objective: Fire the button into the poster
- location: Theater, behind Brute cutout
- hint_minimal: A small button on a Theater wall can be pulled off.
- hint_standard: Entangle the small button on the Theater wall behind the Brute cutout and launch it into a "The Beast From Beyond" poster.
- hint_detailed: After the disks are in, the button on the Theater wall behind the Brute cutout is outlined. Entangle it, carry it to a "The Beast From Beyond" poster (guides: Theater Arcade, left of the Cryptid Attack machine) and launch it into the poster. If it hits, the button vanishes from the wall.
- detect: `flag_set( "button_entered_poster" )` at `cp_final_mpq.gsc:191` (flag_init `:23`).
- marker: button `getstruct( "button_entangle_target", "targetname" )` at `cp_final_mpq.gsc:157`; posters `getstructarray( "dlc4_poster", "targetname" )` at `:180` (hit must be within 36 units of the closest one, `:184`; the script also adds one extra poster struct at (5516, -5725.15, 140.268), `:48-51`).
- status: VERIFIED. Script: button becomes entangle-able only after `fuse_puzzle_completed` (`cp_final_mpq.gsc:155-196`). Walkthrough: TrueAchievements ("Entangle the Button on the wall behind [the Brute cutout]... 'The Beast From Beyond' Poster in the Theater Arcade to the left of the Cryptid Attack arcade machine... Button will teleport"); Zombies Codex says the poster is in the Theatre hallway (see E).

### 15. press_hidden_button  (MPQ#5 "Press Button")
- objective: Crouch and press the button
- location: Forcefield Room desk (Med Bay)
- hint_minimal: The button you moved reappeared somewhere low.
- hint_standard: Find the button under the desk in the Forcefield Room near the Medical Bay. Crouch or go prone and press it.
- hint_detailed: The button reappears on the underside of a desk in the Forcefield Room near the Medical Bay. It only works while you are crouched or prone and not jumping. Pressing it opens the panels in front of the lever grid.
- detect: `flag_set( "toggle_puzzle_button_pressed" )` at `cp_final_mpq.gsc:380` (flag_init `:19`); then `flag_set( "toggle_puzzle_doors_opened" )` at `:2560` (init `:18`).
- marker: `getstructarray( "puzzle_door_button", "script_noteworthy" )` at `cp_final_mpq.gsc:519` (button model spawned at the struct's `.target`, or the struct itself, `:523-533`).
- status: VERIFIED. Script: stance check `cp_final_mpq.gsc:375-385`, doors `:2552-2561`. Walkthrough: TrueAchievements ("button will now be located on the bottom-side of the Desk in the Force-Field Room near Med Bay"; one comment says placement can be glitchy, "under a table in the medic room"); player.one ("button sits under a desk near the forcefield room, pressing it brings up a grid of dials").

### 16. solve_lever_grid  (MPQ#6 "Complete Toggle Puzzle", part 1)
- objective: Set all levers the same way
- location: Medical Bay lever grid
- hint_minimal: The lever grid wants every lever pointing the same way.
- hint_standard: Turn the levers until all 16 point the same way (all horizontal or all vertical). Each lever also flips several others.
- hint_detailed: Look at a lever to highlight it and use it. Every lever flips itself plus a fixed group of others. Goal: all 16 horizontal or all 16 vertical. Note or screenshot the start layout first so you can undo. Success hacks N31L and starts a 3 min (co-op) / 4 min (solo) timer.
- detect: `level notify( "deactivateNeil" )` at `cp_final_mpq.gsc:864` (fires on every success) and `flag_set( "disable_evil_neil" )` at `:871` (init `:21`; cleared again at `:883` when the hack expires). First success also `flag_set( "completed_toggle_puzzle_once" )` at `:898` (init `:27`).
- marker: `getstruct( "entangler_button", "script_noteworthy" )` at `cp_final_mpq.gsc:945`; lever models in its `.buttons[]` with `.color` "horizontal"/"vertical" (`:950-986`).
- status: VERIFIED for the goal (script `validatepuzzle` `cp_final_mpq.gsc:911-926`: all levers equal; toggle rules `:1104-1561`). Walkthrough: SegmentNext/TrueAchievements ("note down initial orientations", "take a screenshot", "turn ... until all are horizontal"). Note: script accepts all-vertical too; the walkthrough "flip the vertical ones" shortcut is NOT a general solution (see E). Rules are re-randomized (1 of 6 per lever) each time N31L turns evil again (`:1537-1543`, `:889-890`).

### 17. carry_head_to_pap  (MPQ#6 "Complete Toggle Puzzle", part 2)
- objective: Take N31L's head to PaP room
- location: Spawn console -> Pack-a-Punch room
- hint_minimal: While N31L is hacked, his head can be moved. He knows the way.
- hint_standard: While N31L is hacked, entangle his head from the Spawn console and carry it, following where it points, through the PaP portal to the computer on the right.
- hint_detailed: Entangle the head at N31L's console. Doors shut and zombies speed up while you carry it; follow the direction the head faces out to the PaP portal. In the PaP room launch it into the computer on the desk on the right. A miss or dropped head nukes the round; redo the levers.
- detect: `flag_set( "neils_head_placed_in_pap" )` at `cp_final_mpq.gsc:826` (flag_init `:24`); also `level notify( "inFinalPosition" )` at `:817`.
- marker: head `getstruct( "console_neil_head", "targetname" )` at `cp_final_mpq.gsc:900` (its `.headmodel`, also `level._id_BEC5`, `:2319-2329`); goal `getstruct( "neil_head_final_pos", "script_noteworthy" )` at `:808` then `getstruct( <that>.target, "targetname" )` at `:809` (must land within 48 units, `:812`); route `getstruct( "pap_portal", "script_noteworthy" )` at `:1025`; the head's own waypoint list `headmodel.pathtogoal` (`:1022-1034`).
- status: VERIFIED. Script: hack timer `cp_final_mpq.gsc:876` (240 s solo/one player, else 180 s); doors closed/spawns boosted while entangled `:658-672`, `:3136-3163`; wrong landing -> head explodes, N31L angry, forced nuke `:838-851`; head turns along path `:61-153`. Walkthrough: TrueAchievements ("N31L will be temporarily Hacked... timer to entangle his head... take it to the Pack-a-Punch Room... computer on a desk on the right side"; "can't open doors... follow the direction N31L's head is pointing"; "fail or drop... Nuke"). PaP room stay is limited to 30 s per visit (`cp_final_fast_travel.gsc:907-938`) - script only.

### 18. start_boss_fight  (MPQ#7 "Enter Bossfight")
- objective: All players use the PaP computer
- location: Pack-a-Punch room computer
- hint_minimal: Everyone must answer N31L's computer together.
- hint_standard: With the head placed, every player holds the use button on the PaP room computer at the same time to enter the boss fight.
- hint_detailed: All living players must use the computer within about 2 seconds of each other; a lone press expires. Prepare first (perks, PaP weapons, ammo): you are teleported straight into the boss arena and interactions/teleports are locked during the fight.
- detect: `flag_set( "players_triggered_bossfight" )` at `cp_final_mpq.gsc:371` (flag_init `:26`).
- marker: `getstructarray( "neil_head_final_pos", "script_noteworthy" )` at `cp_final_mpq.gsc:316` (interaction activated at `:247`).
- status: VERIFIED. Script: all players must be in `.triggers` (`cp_final_mpq.gsc:331-367`), 2 s window (`:359`). Walkthrough: TrueAchievements ("all players are now able to Hold Activate on the Computer to enter the Boss Fight").

---------------------------------------------------------------------------------------------

## C. Boss fight

### C1. Cryptid boss fight (Rhinos + Mammoths) - always part of the main quest
**Preparation (verified):** players are teleported to the arena at (2896, 2868, -68) area
(`cp_final_rhino_boss.gsc:139-163`), teleporting is disabled for all (`:133-134`), regular waves
pause (`:165-171`), loot drops are off (`:172`), perk "candy boxes" appear in the arena and
refill between stages (`:2309-2441`), an ammo crate exists (`:1136-1157`, not for Venom-X), and
Lost & Found moves to the arena (`:2529-2557`). Walkthrough (TrueAchievements): ammo crate is in a
shipping container in the middle; bring strong weapons (Kendall-44, Type-2, FHR-40, Mauler, VPR
listed by one guide); prefer small teams.

**Start detection:** `level notify( "start_rhino_fight" )` `cp_final_rhino_boss.gsc:136`;
`flag_set( "start_rhino_sequence" )` `:171` (flag_init `:72`). (MPQ#7 complete func calls
`start_rhino_fight` at `cp_final_mpq.gsc:271`.)

**Objectives (script order, `rhino_fight_sequence` `cp_final_rhino_boss.gsc:356-370`):**
| id | objective (<=32) | what to do | detect (end of stage) |
|---|---|---|---|
| boss_rhinos | Kill the 4 Rhinos | The laser cannon breaks 4 cargo containers, releasing 4 Rhinos (`:580-609`). Kill all. | `flag_set( "rhino_stage_1" )` `:359` (init `:62`) |
| boss_wave_1 | Survive the portal waves | Cryptids pour from portals (40/60/80/100 by player count, `:691-722`). | `flag_set( "rhino_stage_2" )` `:361` (init `:63`) |
| boss_wave_2 | Survive the Phantom wave | Stage 2 area opens; Phantoms + Cryptids (25/40/50/60, `:833-867`). | `flag_set( "rhino_stage_3" )` `:363` (init `:64`) |
| boss_consoles | Activate the 3 consoles | Laser now targets players. After 45 s consoles light up (`:1159-1175`); 3 must be active at once - each stays on 20/players seconds (`:2222-2271`). | `flag_set( "consoles_ready" )` `:1167`; `flag_set( "all_buttons_pressed" )` `:1174`; `flag_set( "rhino_stage_4" )` `:366` (init `:65`) |
| boss_emp | Defend the EMP, then use it | Laser opens the EMP door and 2 sentry turret doors (pick up sentries, `:2278-2297`). Defend the EMP console while its counter runs from 99 to 0 (`:1463-1499`), then use the console (`:2591-2615`). | `level notify( "emp_charge_completed" )` `:1496`; `level notify( "emp_done" )` `:2596` |
| boss_mammoths | Kill both Mammoths | Lights go out, 2 Mammoths are released (`:1545-1568`); their blue flame pools hurt badly (`:1693-1754`). Kill both. | `flag_set( "rhino_stage_5" )` `:464` (Mammoth stage start, init `:66`); end below |

Markers for the stage props: consoles `getstructarray( "rhino_console", "targetname" )` at
`cp_final_rhino_boss.gsc:433` (interaction noteworthy "rhino_console"); EMP console
`getent( "emp_console", "targetname" )` at `:1427` (interaction struct created at (3082.96,
2541.72, -175.928), `:29-43`); sentries `getstructarray( "rhino_sentry", "script_noteworthy" )` at
`:88`/`:1399`; Mammoth spawn `getstruct( "mammoth_spawn", "targetname" )` via `spawn_mammoth` `:1651`;
ammo crate `getstruct( "ammo_crate_spawn", "targetname" )` at `:1139`.

Status: SCRIPT ONLY for stage-by-stage mechanics (consoles, EMP, sentries); WALKTHROUGH agrees
on 4 Rhinos released by the laser from crates, ammo crate in middle, and 2 Mammoths guarding
the last Soul Key piece (TrueAchievements; CoD fandom Rhino/Mammoth pages via search summary).
The EMP counter's interaction with enemy damage (`damage_monitor` `:1435-1461` decrements the
same counter) is unclear - see E.

**End detection:** both Mammoths dead -> `level notify( "rhino_fight_over" )` at
`cp_final_rhino_boss.gsc:1685` and again inside `rhino_fight_over()` at `:2025`. Then the
`sysload_o1` cinematic plays (106 s, `:2060-2061`) and every player gets achievement `THE_END`
(`:2104`). Walkthrough: killing them unlocks the final Soul Key piece and the ending cutscene;
the achievement can take ~20 s to pop.

### C2. Mephistopheles (conditional final boss)
**Condition (script):** after the cinematic, `rhino_fight_over` starts the Meph fight only if
`directors_cut_is_activated()` and at least one player has ranked data
`haveItems item_1..item_4` (the Director's Cut talismans of cp_zmb, cp_rave, cp_disco, cp_town,
`cp/zombies/directors_cut.gsc:270-293`) (`cp_final_rhino_boss.gsc:2066-2087`); otherwise the
match resumes (`resume_cp_final`). Walkthrough (fan wiki summary): "appears only when the main quest
is completed with director's cut active and the talisman ... quest completed". VERIFIED (script)
/ weakly confirmed (web).

**Preparation (script):** players are placed in a prep area (afterlife-arcade spots) with a free
Fate & Fortune machine, a free Magic Wheel that can give Venom-X PaP2, and a perk pickup
(`cp_final_final_boss.gsc:48-91`). The fight auto-starts after 300 s (`:93-122`), or earlier when
all players stand within 128 units of the exit and use "start_meph_battle" (`:156-202`).

**Start detection:** `flag_set( "meph_fight" )` at `cp_final_final_boss.gsc:388` (flag_init `:6`),
set in `spawn_meph()`; `level notify( "fight_started" )` at `:166` when started by the exit button.
(`level.meph_fight_started = 1` at `:62`/`:322` when the prep phase begins.)

**Objectives (script mechanics, `cp_final_final_boss.gsc`):**
| id | objective (<=32) | what to do | detect |
|---|---|---|---|
| meph_ritual | Place a talisman in a circle | 5 ritual circles (`capture_points`, `:12-26`). Use one to place a talisman; stand inside to charge it (`:743-855`, `:923-962`). | manual (circle `.state` "CHARGING"/"ACTIVE") |
| meph_souls | Entangle souls into Meph | When charged, souls are released (`:1027-1044`). Every player is given an Entangler (`:692-693`, `:1161-1214`); drag souls into Mephistopheles to stun him (`:1046-1087`). | manual |
| meph_weakspot | Shoot the glowing weak spot | Destroy the weak spot linked to that circle (`:1281-1329`). Repeat for all 5 circles. | manual (`level.fbd.activatedcircles.size`) |
| meph_frenzy | Activate all 5 talismans | After the 5th, he becomes FRENZIED (`:1310-1316`); as his frenzy health drops talismans rise; use all 5 circles again (`:1379-1420`). | `level notify( "STOP_FRENZY_SPAWN" )` `:1427` |
| meph_finish | Finish Mephistopheles | Talisman beams put him in last stand (`:1459`); deal the remaining damage before the soul bomb timer ends or the game is lost (`asm/dlc4_boss/dlc4_boss_asm.gsc:1292-1325`). | `level notify( "FINAL_BOSS_VICTORY" )` |

Status: SCRIPT ONLY for the mechanics; web only confirms "five rituals" and phases that unlock
new attacks (Reddit via search summary). Markers: circles
`getstructarray( "capture_points", "targetname" )` at `cp_final_final_boss.gsc:12`; prep exit
`getstruct( "start_meph_battle", "script_noteworthy" )` at `:90`; perk pickup
`getstruct( "meph_perks", "script_noteworthy" )` at `:89`/`:149`; boss `level.dlc4_boss`
(spawned at (-13314, -337, -109), `:401-402`).

**End detection:** `level notify( "FINAL_BOSS_VICTORY" )` at `cp_final_final_boss.gsc:1506`
(`victory()`, called from `asm/dlc4_boss/dlc4_boss_asm.gsc:1312`) and again at
`asm/dlc4_boss/dlc4_boss_asm.gsc:1192` (`meph_victory`, after the death anim). Failure: soul bomb
detonates -> `level.endgame( "axis", ...["kia"] )` (`dlc4_boss_asm.gsc:1319-1325`).

---------------------------------------------------------------------------------------------

## D. Final objective and completion detection

- **Main quest complete (every eligible game):** objective "Kill both Mammoths" -> detect
  `level notify( "rhino_fight_over" )` at `cp_final_rhino_boss.gsc:1685` (first fire) /
  `:2025`. Confirmation: achievement `THE_END` update at `:2104` (after the 106 s cinematic).
  Tracker text suggestion: "Main quest complete" / then either "Fight resumes" or the Meph prep.
- **True ending (Director's Cut + talismans):** objective "Defeat Mephistopheles" -> detect
  `level notify( "FINAL_BOSS_VICTORY" )` (`cp_final_final_boss.gsc:1506`,
  `asm/dlc4_boss/dlc4_boss_asm.gsc:1192`). The victory sequence awards merit `mt_dlc4_troll2`,
  sets `mt_dc_camo`, plays `sysload_o3` and ends the match as a win
  (`dlc4_boss_asm.gsc:1203-1221`).
- **Direct boss fight mode** (`final_start_direct_boss_fight_func`, `cp_final.gsc:2530-2545`)
  skips the quest entirely; Guided Mode should not run the quest tracker there
  (`scripts\cp\zombies\direct_boss_fight::should_directly_go_to_boss_fight()`).

---------------------------------------------------------------------------------------------

## E. Open questions / discrepancies

Verified again against the scripts while writing the guide (2026-10-13):
- The hack and its end: `deactivateneil` (`cp_final_mpq.gsc:862-893`) sets `disable_evil_neil`,
  waits 180 s (240 s solo) or `makeNeilEvil`, clears the flag and threads `neildoevilstuff`, which
  sends `level notify( "neilIsEvil" )` (`:3397`). It also fires once when the disks are accepted
  (`completefusepuzzle`, `:2579`). After the head reaches its final position the hack thread ends
  (`level endon( "inFinalPosition" )`), so no `neilIsEvil` follows a success. The guide detects the
  lever grid by `disable_evil_neil` and goes back to it on `neilIsEvil`.
- No level notify marks a failed head delivery (the head explodes, N31L turns angry, a forced nuke,
  `:838-851`); the hack goes on until its timer, then `neilIsEvil`.
- The disk and scrap counts are the game's level omnvars `zm_floppy_count` (`setomnvar`, `:2213`;
  back to 0 on a wrong order, `:2221`) and `zm_scrap_count` (`:2902`), read with `getomnvar` as
  stock scripts read `zm_num_ghost_n_skull_coin`.
- Rhinos and Mammoths are agents of type `alien_rhino` (`spawn_rhino`, `cp_final_rhino_boss.gsc:885-900`;
  `spawn_mammoth` `:1649-1661` uses it too, with `.is_mammoth`).
- The boss stages run in order in `rhino_fight_sequence` (`:356-370`): `rhino_stage_1` after the
  Rhinos, `_2` after the portal wave, `_3` after the Phantom wave, then the consoles, `_4`, the
  EMP (`emp_charge_counter` `:1463-1500`, counter 99 to 0 then `emp_charge_completed`), `_5`
  when the Mammoth stage starts, and `rhino_fight_over` when both Mammoths are dead.
- The skull box: `set_up_ghost_box` spawns `ship_hallway_control_box` at one random
  `ghost_n_skull_box` struct; explosive damage makes it `ship_hallway_control_box_body` and
  spawns the skull `zmb_8_bit_price_unlit`, deleted when a player shoots it
  (`cp_final_ghost_activation.gsc:20-128`). The same skull model is used for the pressure plate's
  skull meter (`:287`), so the guide only counts a skull near the box.
- The Entangler: `give_crafted_entangler` puts `crafted_entangler` in the player's crafted slot
  (`cp/crafted_entangler.gsc:50-58`, `cp/utility.gsc:5651-5659`).
- The Theater portal: `blast_doors_with_gun` sets `.opened` on the `fast_travel_portal` struct whose
  `script_noteworthy` is `cargo_room` (`cp_final_fast_travel.gsc:343-354`).

Still open (in-game check or a better source needed):
1. Where the three bridge scrap pieces lie: mmmrkennedy (search summary) names the Cargo Bay,
   Medical Bay and Theater; Mejoress (Spanish) lists other spots. The guide names no rooms.
2. The disk order list's reading direction (TrueAchievements: right to left). The guide says "in
   the paper list's order" only.
3. Whether the disk left of the Pack-a-Punch portal needs the bridge (the guide does not assume it).
4. How the EMP console's damage monitor (`:1435-1461`) interacts with the charge counter.
5. The exact room of the pressure plate (script coordinates near (1467, 2775, -277)); the game
   shows its own map marker there.
