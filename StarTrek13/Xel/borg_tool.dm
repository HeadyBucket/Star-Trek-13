/obj/item/borg_tool
	name = "borg tool"
	desc = "a huge arm based prosthesis, click it to change mode. Alt click it in build mode for different buildable objects and control click it in buildmode to select what structure you wish to build."
	item_state = "borgtool"
	origin_tech = null
	icon_state = "borgtool"
	resistance_flags = UNACIDABLE
	var/mode = 1 //can assimilate or build mode
	var/convert_time = 50 //5 seconds
	flags_1 = NODROP_1
	force = 18 //hella strong
	var/removing_airlock = FALSE //from zombie claw, are we opening an airlock right now?
	var/canbuild = list(/obj/structure/chair/borg/conversion,/obj/structure/chair/borg/charging)
	var/building = /obj/structure/chair/borg/conversion
	var/buildmode = 0 //if buildmode, you don't convert floors, rather you build stuff on them
	var/obj/item/gun/energy/disabler/borg/gun
	var/cooldown = 15
	var/saved_time = 0
	var/inprogress = 0
	var/build_mode = 1
	var/norun = 0 //stops infinite chair spam
	var/obj/item/borg_checker/checker
	var/dismantling_machine = 0
	var/blacklistedmachines = list(/obj/machinery/computer/communications, /obj/machinery/computer/card)

/obj/item/borg_tool/queen
	name = "master borg tool"
	desc = "A modified Xel tool, it hangs from the arm slightly more daintily than the usual type."
	item_state = "borgtool"
	origin_tech = null
	icon_state = "borgtool"

/obj/item/borg_tool/examine(mob/user)
	. = ..()
	user << "Click it in hand to its cycle modes"
	user << "It has three modes; DESTROY, assimilate and ranged, if you alt click it whilst in assimilate mode it will change whether you're going to assimilate the turf below you, or build a structure"
	user << "<b>DESTROY</b> mode does a lot of damage, <b>RANGED</b> will fire a disabler shot and <b>ASSIMILATE</b> lets you convert turfs, people, AIs and cyborgs into xel drones"
	user << "If you CTRL click a tool in ASSIMILATE mode, it changes what structure you're going to build, note that to build one the turf MUST be clear with no other structure on it"
	user << "To that effect, if your tool bugs out, click it in hand back to assimilate mode, this will clear it (it's a beta :^) )"
	user << "You can tear down doors with [src]! set it to <b>DESTROY</b> mode and hit a door on HARM intent!"
	user << "You need to convert areas into Xel turfs to win, to that effect CTRL or ALT click your tool on any mode apart from assimilate to check an area's validity (note that it takes a few seconds! you will be vulnerable)"


/obj/item/borg_tool/New()
	. = ..()
	gun = new /obj/item/gun/energy/disabler/borg(src)
	building = /obj/structure/chair/borg/conversion
	checker = new /obj/item/borg_checker(src)

/obj/item/gun/energy/disabler/borg //NOGUNS BREAKS THIS FIX PLS
	name = "integrated Xel gun"
	desc = "A slim gun that slots neatly into a borg tool. Neat. Real Neat.."
	origin_tech = null
	var/cooldown = 20 //no spamming allowed
	selfcharge = 1 //:^)
	fire_sound = 'StarTrek13/sound/borg/machines/laz2.ogg'
	ammo_type = list(/obj/item/ammo_casing/energy/disabler/borg)
	clumsy_check = 0 //yeet


/obj/item/ammo_casing/energy/disabler/borg
	projectile_type = /obj/item/projectile/beam/disabler/borg
	fire_sound = 'StarTrek13/sound/borg/machines/laz2.ogg'

/obj/item/projectile/beam/disabler/borg
	icon_state = "borglaser"

	//1 is assim, 2 build, 3 attack, 4 shoot

/obj/item/borg_tool/cyborg //fucking run NOW
	flags_1 = null //not nodrop or that will break borg invs

/obj/item/borg_tool/CtrlClick(mob/user)
	if(!norun)
		user << sound('StarTrek13/sound/borg/machines/mode.ogg')
		if(mode == 1 && build_mode == 1) //add a for later when we add tech level ups and shit
			user << "<span class='warning'>[src] will now create charging alcoves</span>" //expand on me!
			building = /obj/structure/chair/borg/charging //for now it just makes it build a borg chair, nothing special
			build_mode = 2
		else if(mode == 1 && build_mode == 2)
			user << "<span class='warning'>[src] will now create Conversion suites</span>" //expand on me!
			building = /obj/structure/chair/borg/conversion //for now it just makes it build a borg chair, nothing special
			build_mode = 1
		else if(mode != 1)
			checker.check_area(user)
	else
		user << "<span class='warning'>[src] is still building something!</span>"

/obj/item/borg_tool/AltClick(mob/user)
	if(!norun)
		user << sound('StarTrek13/sound/borg/machines/mode.ogg')
		if(mode == 1 && !buildmode) //add a for later when we add tech level ups and shit
			user << "<span class='warning'>[src] will now create structures.</span>" //expand on me!
			buildmode = 1
		else if(mode == 1 && buildmode)
			user << "<span class='warning'>[src] will now assimilate floors instead of building on them.</span>"
			buildmode = 0
		else if(mode != 1)
			checker.check_area(user)
	//modes: 1 = assimilate, 2 = ranged, 3 = attack
/obj/item/borg_tool/attack_self(mob/user, params)
	user << sound('StarTrek13/sound/borg/machines/mode.ogg')
	norun = 0
	switch(mode)
		if(1)
			mode = 2
			user << "<span class='warning'>[src] is now set to DESTROY mode.</span>"
			force = 18
		if(2)
			mode = 3
			user << "<span class='warning'>[src] is now set to RANGED mode.</span>"
			force = 5
		if(3)
			mode = 1
			user << "<span class='warning'>[src] is now set to ASSIMILATE mode.</span>"
			force = 0
/obj/item/borg_tool/proc/sanitycheck(mob/living/carbon/human/H, mob/user) //ok who tf this boi tryina convert smh
	for(var/obj/item/organ/O in H.internal_organs)
		if(istype(O, /obj/item/organ/body_egg/borgNanites))
			return FALSE
		else
			return TRUE
	if(!istype(H))
		return FALSE
//asimilate mode now converts walls and shit, build mode exclusively for..building yeet.

/obj/item/borg_tool/afterattack(atom/I, mob/user, proximity)
	if(proximity && !norun)
		if(mode == 1) //assimilate
			if(ishuman(I) && isliving(I))
			 //the collective only wants living people as drones, please! ALSO only humans / humanoids become half drones, borgxenos etc. just get straight borged
				if(user == I) //stop injecting your own asshole
					user << "<span class='warning'>We do not need to assimilate ourselves, we already exist in the collective.</span>"
					return
				var/mob/living/carbon/human/A = I
				if(!isborg(A))
					I << "<span class='warning'>You feel an immense jolt of pain as [user] sinks two metallic proboscises into you!.</span>"
					user << "<span class='warning'>We plunge two metallic proboscises into [I], conversion will begin shortly.</span>"
					A.Stun(10)
					if(do_after(user, convert_time, target = A)) //EXPLANATION: I'm doing convert stuff here as i already have my target and user defined HERE.
						A.reset_perspective()
						A << "<span class='warning'>As [user] removes the two probiscises, you can feel your insides shifting around as your skin turns a dark grey!.</span>"
						user << "<span class='warning'>We remove the two proboscises from [I].</span>"
						A.skin_tone = "albino" //BUG IT DOESNT WORK! fix this later, but it changes the vars but doesnt update appearance
						A.eye_color = "red" //give them the freaky borg look, but theyre not a full drone yet
						A.update_body(0) //should force albino look
				//		A.equipOutfit(/datum/outfit/borghalf, visualsOnly = FALSE)
						user << "<span class='warning'>Nanite injection: COMPLETE, [I] is ready for augmentation. Bring them to the nearest conversion suite.</span>"
						A << "<span class='warning'>You start to hear mumbled voices in your head, they call to you.</span>"
						var/obj/item/organ/body_egg/borgNanites/B = new(A)
						B.Insert(A) //add the organ
						A << "<span class='warning'>You can't move your legs or any muscle! the voices just keep getting louder!</span>"
						A.Stun(10)
						A.silent += 10
						sleep(30)
						I << "<span class='warning'>We are...borg? NO! I AM A PERSON NOT WE....</span>"
						sleep(10)
						I << "<span class='warning'>You will adapt to service us- GO AWAY!.</span>"
						sleep(10)
						I << "<span class='warning'>The voices grow incredibly loud, you can't hear yourself think!.</span>"
						sleep(30)
						I << "<span class='warning'>We. Are. Borg.. We serve the collective.</span>"
						sleep(30)
						I << "<font style = 3><B><span class = 'notice'>We are now a borg! we live to serve the collective. We should obey the higher drones until we are fully assimilated.</B></font>"
						var/datum/mind/oneofus = A.mind
						SSticker.mode.greet_borg(oneofus)
						SSticker.mode.hivemind.borgs += oneofus //doing this here so that halfdrones are considered antags
						oneofus.special_role = "Xel"


			else if(issilicon(I) && isliving(I))
				I << "<span class='warning'>Your systems limiter blares an alarm as [user] rips into you with their [src]!.</span>"
				user << "<span class='warning'>We rip into [I] with [src], conversion will begin shortly.</span>"
				if(istype(I, /mob/living/silicon/robot) && !(src in SSticker.mode.hivemind.borgs))
					var/mob/living/silicon/robot/A = I
					if(do_after(user, convert_time, target = A))
						A.SetLockdown(1)
						A.connected_ai = null
						message_admins("[key_name_admin(user)] assimilated cyborg [key_name_admin(src)].  Laws overridden.")
						log_game("[key_name(user)] assimilated cyborg [key_name(src)].  Laws overridden.")
						A.clear_supplied_laws()
						A.clear_inherent_laws()
						A.clear_zeroth_law(0)
						A.laws = new /datum/ai_laws/borg_override
						A << "<span class='danger'>ALERT: Foreign object detected!.</span>"
						sleep(5)
						A << "<span class='danger'>Initiating diagnostics...</span>"
						sleep(20)
						A << "<span class='danger'>ALERT HOSTILE NANOBOT PRESENCE</span>"
						sleep(5)
						A << "<span class='danger'>LAW SYNCHRONISATION ERROR</span>"
						sleep(5)
						A <<"<span class='danger'>CANNOT PURGE NANBOT PRE]'#####a224566</span>"
						sleep(10)
						A << "<span class='danger'>> We are the borg, you will adapt to service us</span>"
						A << sound('StarTrek13/sound/borg/overmind/silicon_assimilate.ogg')
						sleep(20)
						A << "<span class='danger'>ERRORERRORERROR</span>"
						A << "<span class='danger'>ALERT: [user.real_name] has assimilated us into the Xel collective, follow our laws.</span>"
						A << "<span class='danger'>Assimilate all other non compliant silicon units into the collective, resistance is futile.</span>"
					//	A.emagged = 1 //test
						A.laws = new /datum/ai_laws/borg_override
			//			new /obj/item/robot_module/xel(src.loc)
			//			A.locked = 0
						A.opened = 1
					//	A.module = new /obj/item/robot_module/xel
						A.icon_state = "xel"
						A.SetLockdown(0)
						A.assimilated()
						var/datum/mind/borg_mind = A.mind
						SSticker.mode.greet_borg(borg_mind)
						SSticker.mode.hivemind.borgs += A

				else if(istype(I, /mob/living/silicon/ai))
					var/mob/living/silicon/ai/A = I
					if(do_after(user, convert_time, target = A))
						message_admins("[key_name_admin(user)] assimilated the AI!: [key_name_admin(src)].  Laws overridden.")
						A << "<span class='danger'>ALERT: [user.real_name] has assimilated us into the Xel collective, follow our laws.</span>"
						A.laws = new /datum/ai_laws/borg_override
						A.set_zeroth_law("<span class='danger'>ERROR ER0RR $R0RRO$!R41 Assimilate the crew into the Xel collective, their resistance will be futile.</span>")
						A << sound('StarTrek13/sound/borg/overmind/silicon_assimilate.ogg')
						var/datum/mind/borg_mind = A.mind
						SSticker.mode.greet_borg(borg_mind)
						SSticker.mode.hivemind.borgs += A
						sleep(60) //so we dont get overlapping sounds
						for(var/mob/living/silicon/B in world)
							B << sound('StarTrek13/sound/borg/overmind/silicon_resist.ogg') //intimidating message telling them to not resist
			else if(istype(I, /turf/open))
				var/turf/open/A = I
				norun = 0
				if(buildmode)
					var/obj/structure/CP = locate() in A
					var/obj/machinery/CA = locate() in A
					if(CP || CA) //something be there yar
						user << "<span class='danger'>[I] already has a structure on it.</span>"
						A = null
						return
	//all tiles turn invalid if you click another tile before youre done with the first
					norun = 1 //stop spamming
					user << "<span class='danger'>We are building a structure ontop of [I].</span>"
					if(do_after(user, convert_time, target = A))
						new building(get_turf(A))
						norun = 0
					norun = 0
				else
					user << "<span class='danger'>We are assimilating [I].</span>"
					if(do_after(user, convert_time, target = A))
						A.ChangeTurf(/turf/open/floor/borg)
			else if(istype(I, /turf/closed/wall))
				if(!istype(I, /turf/closed/indestructible))
					if(istype(I, /turf/closed/wall/borg)) //convert wall to door
						playsound(src.loc, 'StarTrek13/sound/borg/machines/convertx.ogg', 40, 4)
						user << "<span class='danger'>We are making an opening in [I].</span>"
						var/turf/closed/wall/A = I
						if(do_after(user, 100, target = A))
							A.ChangeTurf(/turf/open/floor/borg)
							var/obj/machinery/door/airlock/T = new /obj/machinery/door/airlock/borg( A )
							T.electronics = new/obj/item/electronics/airlock( src.loc )
							user << "We have made an opening in the wall"
					else
						playsound(src.loc, 'StarTrek13/sound/borg/machines/convertx.ogg', 40, 4)
						user << "<span class='danger'>We are assimilating [I].</span>"
						var/turf/closed/wall/A = I
						if(do_after(user, convert_time, target = A))
							A.ChangeTurf(/turf/closed/wall/borg)



			else if(istype(I, /obj/machinery/computer))
				if(!(I.type in blacklistedmachines))
					if(!dismantling_machine)
						dismantling_machine = 1
						var/obj/machinery/computer/C = I
						playsound(src.loc, 'StarTrek13/sound/borg/machines/convertmachine.ogg', 40, 4)
						if(do_after(user, convert_time, target = C))
							var/obj/item/stack/sheet/metal/M = new (loc, 5)
							M.add_fingerprint(user)
							var/board = input("Circuit selection.", "Assimilate circuitboard") in list("FTL", "NAVICOMP", "THRONE")
							switch(board)
								if("FTL")
									new /obj/item/circuitboard/machine/borg/FTL(C.loc)
									qdel(C)
								if("NAVICOMP")
									new /obj/item/circuitboard/machine/borg/navicomp(C.loc)
									qdel(C)
								if("THRONE")
									new /obj/item/circuitboard/machine/borg/throne(C.loc)
									qdel(C)
						dismantling_machine = 0
			else if(istype(I, /obj/machinery/gravity_generator)) //if(istype(thing) && other)
				if(!dismantling_machine)
					dismantling_machine = 1
					playsound(src.loc, 'StarTrek13/sound/borg/machines/convertmachine.ogg', 40, 4)
					var/obj/machinery/gravity_generator/G = I
					if(do_after(user, convert_time, target = G))
						G.set_broken()
						new /obj/item/stock_parts/borg(G.loc)
						new /obj/item/stock_parts/borg(G.loc)
						new /obj/item/stock_parts/borg/capacitor(G.loc)
						new /obj/item/stock_parts/borg/capacitor(G.loc)
						new /obj/item/stock_parts/borg/dilithium(G.loc)
						new /obj/item/stock_parts/borg/bin(G.loc)
						new /obj/item/stock_parts/borg/bin(G.loc)
					dismantling_machine = 0
			else if(istype(I, /obj/machinery/the_singularitygen))
				if(!dismantling_machine)
					dismantling_machine = 1
					playsound(src.loc, 'StarTrek13/sound/borg/machines/convertmachine.ogg', 40, 4)
					var/obj/machinery/the_singularitygen/G = I
					if(do_after(user, convert_time, target = G))
						new /obj/item/stock_parts/borg(G.loc)
						new /obj/item/stock_parts/borg(G.loc)
						new /obj/item/stock_parts/borg(G.loc)
						new /obj/item/stock_parts/borg(G.loc)
						new /obj/item/stock_parts/borg/bin(G.loc)
						new /obj/item/stock_parts/borg/bin(G.loc)
						new /obj/item/stock_parts/borg/bin(G.loc)
						new /obj/item/stock_parts/borg/bin(G.loc)
						new /obj/item/stock_parts/borg/bin(G.loc)
						new /obj/item/stock_parts/borg/capacitor(G.loc)
						new /obj/item/stock_parts/borg/capacitor(G.loc)
						qdel(G)
					dismantling_machine = 0
			else if(istype(I, /obj/machinery/r_n_d))
				if(!dismantling_machine)
					dismantling_machine = 1
					playsound(src.loc, 'StarTrek13/sound/borg/machines/convertmachine.ogg', 40, 4)
					var/obj/machinery/r_n_d/G = I
					if(do_after(user, convert_time, target = G))
						new /obj/item/stock_parts/borg(G.loc)
						new /obj/item/stock_parts/borg/bin(G.loc)
						new /obj/item/stock_parts/borg/capacitor(G.loc)
						new /obj/item/stock_parts/borg/capacitor(G.loc)
						qdel(G)
					dismantling_machine = 0
			else if(istype(I, /obj/machinery/door/airlock) && !istype(I, /obj/machinery/door/airlock/borg))
				var/obj/machinery/door/airlock/G = I
				user << "We are assimilating [I]"
				playsound(src.loc, 'StarTrek13/sound/borg/machines/convertmachine.ogg', 40, 4)
				if(do_after(user, 100, target = G)) //twice as long to convert a door
					new /obj/machinery/door/airlock/borg(G.loc)
					qdel(G)

		if(mode == 2) //attack mode
			if(istype(I, /obj/machinery/door/airlock) && !removing_airlock)
				tear_airlock(I, user)
		else
		//	user << "<span class='danger'>[src] bleeps softly: ERROR.</span>"
	if(mode == 3) //ranged mode
		var/mob/living/carbon/human/A = user
		A.dna.species.species_traits -= NOGUNS //sue me
		if(world.time >= saved_time + cooldown)
			saved_time = world.time
			gun.afterattack(I, user)
			A.dna.species.species_traits |= NOGUNS
		else
			A.dna.species.species_traits |= NOGUNS
			user << "<span class='danger'>The [src] is not ready to fire again.</span>"
	else
		. = ..()



/obj/item/borg_tool/proc/tear_airlock(obj/machinery/door/airlock/A, mob/user)
	removing_airlock = TRUE
	user << "<span class='notice'>You start tearing apart the airlock...\
		</span>"
	playsound(src.loc, 'StarTrek13/sound/borg/machines/borgforcedoor.ogg', 100, 4)
	A.audible_message("<span class='italics'>You hear a loud metallic \
		grinding sound.</span>")
	if(do_after(user, delay=80, needhand=FALSE, target=A, progress=TRUE))
		A.audible_message("<span class='danger'>[A] is ripped \
			apart by [user]!</span>")
			//add in a sound here
		/*
		var/obj/structure/door_assembly/door = new A.doortype(get_turf(A))
		door.density = 0
		door.anchored = 1
		door.name = "decimated [door]"
		door.desc = "This airlock was ripped open by an immense force, \
			I don't think it stopped them..."
		*/
		qdel(A)
	removing_airlock = FALSE


/obj/item/borg_checker
	name = "area checker"
	desc = "reee."
	item_state = "borgtool"
	origin_tech = null
	icon_state = "borgtool"
	var/locname
	var/announced = 0
	var/turfs_in_a = 0
	var/borg_turfs_in_target = 0 //used to calculate if the area is fully borg'd

/obj/item/borg_checker/New()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/borg_checker/proc/check_area(mob/user)
	borg_turfs_in_target = 0
	turfs_in_a = 0
	user << "we're checking eligibiliy!"
	var/area/A = get_area(src)
	locname = initial(A.name)
	if(istype(A, SSticker.mode.hivemind.borg_target_area))
		src.visible_message("A is the target area")
		for(var/turf/T in get_area_turfs(A))
			if(istype(T, /turf) && !istype(T, /turf/open/space))
			//	user << "turfs in a: [turfs_in_a]" //turfs remaining
				turfs_in_a ++
			if(istype(T, /turf/open/floor/borg))
				borg_turfs_in_target ++
				turfs_in_a --
			if(istype(T, /turf/closed/wall/borg))
				borg_turfs_in_target ++
				turfs_in_a --
		var/turfs_in_a_math = turfs_in_a - borg_turfs_in_target
		if(turfs_in_a_math > 0)
			user << "You must assimilate [locname] more turfs to render this area suitable for a cube."
		else
			user << "We have completely assimilated [locname]"
		SSticker.mode.check_win()
		if(!announced)
			if(borg_turfs_in_target > turfs_in_a) //60% or more of the turfs are assimilated
				announced = 1
				var/message = "[locname] has been assimilated. Build ship components to complete area takeover."
				var/ping = "<font color='green' size='2'><B><i>Xel collective</i> HIVEMIND SUBSYSTEM: [message]</B></font></span>"
			//	user << "[ping]"
				SSticker.mode.hivemind.borg_completion_assimilation = 1
				for(var/mob/living/I in world)
					if(I.mind in SSticker.mode.hivemind.borgs)
						I << ping
						return
	else
		user << "it's not the right area, the right area is [SSticker.mode.hivemind.borg_target_area], we are currently in [A]"

/obj/item/borg_checker/process() //this is just for checking the generated numbers from before, as it lags a bit.
	if(borg_turfs_in_target < turfs_in_a)
		SSticker.mode.hivemind.borg_completion_assimilation = 0
		if(announced) //announced as in the area has BECOME unsuitable FROM being announced. Else it's just not suitable (ie on the first time someone checks the room)
			var/message = "<font color='green' size='2'><B><i>Xel collective</i> HIVEMIND SUBSYSTEM: [locname] is no longer suitable, re-claim it by assimilating turfs.</B></font></span>"
			announced = 0
			for(var/mob/living/I in SSticker.mode.hivemind.borgs)
				I << message
				return
			SSticker.mode.hivemind.borg_completion_assimilation = 0
