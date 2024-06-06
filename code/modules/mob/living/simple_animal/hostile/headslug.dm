#define EGG_INCUBATION_DEAD_CYCLE 120
#define EGG_INCUBATION_LIVING_CYCLE 200

/mob/living/simple_animal/hostile/headslug
	name = "headslug"
	desc = "Absolutely not de-beaked or harmless. Keep away from corpses."
	icon_state = "headslug"
	icon_living = "headslug"
	icon_dead = "headslug_dead"
	icon = 'icons/mob/mob.dmi'
	health = 60
	maxHealth = 60
	melee_damage_lower = 30
	melee_damage_upper = 35
	melee_damage_type = STAMINA
	attacktext = "gnaws"
	attack_sound = 'sound/weapons/bite.ogg'
	faction = list("creature")
	robust_searching = TRUE
	stat_attack = DEAD
	obj_damage = 0
	environment_smash = 0
	speak_emote = list("squeaks")
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	density = FALSE
	ventcrawler = VENTCRAWLER_ALWAYS
	a_intent = INTENT_HARM
	speed = 0.3
	can_hide = TRUE
	pass_door_while_hidden = TRUE
	var/datum/mind/origin
	var/egg_layed = FALSE
	sentience_type = SENTIENCE_OTHER
	var/young = FALSE
	var/syndie = FALSE
	var/mob/living/carbon/human/the_lesser_type = /mob/living/carbon/human/monkey

	var/datum/mind/parent_mind

/mob/living/simple_animal/hostile/headslug/proc/Infect(mob/living/carbon/victim)
	var/obj/item/organ/internal/body_egg/changeling_egg/egg = new(victim)
	egg.insert(victim)
	if(origin)
		egg.origin = origin
	else if(mind) // Let's make this a feature
		egg.origin = mind
	for(var/obj/item/organ/internal/I in src)
		I.forceMove(egg)
	visible_message("<span class='warning'>[src] plants something in [victim]'s flesh!</span>", \
					"<span class='danger'>We inject our egg into [victim]'s body!</span>")

	egg.young = src.young
	egg.syndie = src.syndie
	egg_layed = TRUE
	egg.the_lesser_type = src.the_lesser_type
	egg.parent_mind = src.parent_mind

/mob/living/simple_animal/hostile/headslug/AltClickOn(mob/living/carbon/carbon_target)
	if(egg_layed || !istype(carbon_target) || !Adjacent(carbon_target) || ismachineperson(carbon_target))
		return ..()
	if(carbon_target.stat != DEAD && !do_mob(src, carbon_target, 5 SECONDS))
		return
	if(HAS_TRAIT(carbon_target, TRAIT_XENO_HOST))
		to_chat(src, "<span class='userdanger'>A foreign presence repels us from this body. Perhaps we should try to infest another?</span>")
		return
	if(!carbon_target.get_int_organ_datum(ORGAN_DATUM_HEART))
		to_chat(src, "<span class='userdanger'>There's no heart for us to infest!</span>")
		return
	Infect(carbon_target)
	to_chat(src, "<span class='userdanger'>With our egg laid, our death approaches rapidly...</span>")
	addtimer(CALLBACK(src, PROC_REF(death)), 25 SECONDS)

/mob/living/simple_animal/hostile/headslug/projectile_hit_check(obj/item/projectile/P)
	return (stat || FALSE)

/obj/item/organ/internal/body_egg/changeling_egg
	name = "changeling egg"
	desc = "Twitching and disgusting."
	origin_tech = "biotech=7" // You need to be really lucky to obtain it.
	var/datum/mind/origin
	var/time = 0

	var/young = FALSE
	var/syndie = FALSE
	var/datum/mind/parent_mind
	var/mob/living/carbon/human/the_lesser_type = /mob/living/carbon/human/monkey

/obj/item/organ/internal/body_egg/changeling_egg/egg_process()
	// Changeling eggs grow in everyone
	time++
	if(young) //young headslugs grows faster.
		time++
	if(syndie) //genetically modified aftel all!!!
		time += 2
	if(time >= 30 && prob(40))
		owner.bleed(5)
	if(time >= 60 && prob(10))
		to_chat(owner, pick("<span class='danger'>We feel great!</span>", "<span class='danger'>Something hurts for a moment but it's gone now.</span>", "<span class='danger'>You feel like you should go to a dark place.</span>", "<span class='danger'>You feel really tired.</span>"))
		owner.adjustToxLoss(30)
	if(time >= 90 && prob(15))
		to_chat(owner, pick("<span class='danger'>Something hurts.</span>", "<span class='danger'>Someone is thinking, but it's not you.</span>", "<span class='danger'>You feel at peace.</span>", "<span class='danger'>Close your eyes.</span>"))
		owner.apply_damage(50, STAMINA)
	if(time >= EGG_INCUBATION_DEAD_CYCLE && owner.stat == DEAD || time >= EGG_INCUBATION_LIVING_CYCLE)
		Pop()
		STOP_PROCESSING(SSobj, src)
		qdel(src)

/obj/item/organ/internal/body_egg/changeling_egg/proc/Pop()
	var/mob/living/carbon/human/M = new the_lesser_type(owner)
	LAZYADD(owner.stomach_contents, M)

	for(var/obj/item/organ/internal/I in src)
		I.insert(M, 1)

	if(origin && origin.current && (origin.current.stat == DEAD))
		origin.transfer_to(M)

		var/datum/antagonist/changeling/cling = M.mind.has_antag_datum(/datum/antagonist/changeling)

		if(young)
			parent_mind.offstation_role = TRUE

			if(syndie)
				origin.add_antag_datum(/datum/antagonist/changeling/young/syndie)
				var/datum/antagonist/changeling/young/syndie/S = M.mind.has_antag_datum(/datum/antagonist/changeling/young/syndie)
				S.parent_mind = src.parent_mind
			else
				origin.add_antag_datum(/datum/antagonist/changeling/young)
				var/datum/antagonist/changeling/young/Y = M.mind.has_antag_datum(/datum/antagonist/changeling/young)
				Y.parent_mind = src.parent_mind

			var/datum/action/changeling/lesserform/LF = new()
			LF.power_type = CHANGELING_INNATE_POWER
			cling.give_power(LF, M, FALSE)

			addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/controller/subsystem/jobs, show_location_blurb), M.client, M.mind), 1 SECONDS)

			parent_mind.offstation_role = FALSE

		if(cling.can_absorb_dna(owner))
			cling.absorb_dna(owner)

		cling.update_languages()

		// When they became a headslug, power typepaths were added to this list, so we need to make new ones from the paths.
		for(var/power_path in cling.acquired_powers)
			cling.give_power(new power_path, M, FALSE)
			cling.acquired_powers -= power_path

		var/datum/action/changeling/evolution_menu/E = locate() in cling.acquired_powers

		// Add purchasable powers they have back to the evolution menu's purchased list.
		for(var/datum/action/changeling/power as anything in cling.acquired_powers)
			if(power.power_type == CHANGELING_PURCHASABLE_POWER)
				E.purchased_abilities += power.type

		cling.give_power(new /datum/action/changeling/humanform)
		M.key = origin.key
		M.revive() // better make sure some weird shit doesn't happen, because it has in the pas
		M.forceMove(get_turf(owner)) // So that they are not stuck inside
	if(!ishuman(owner))
		owner.gib()
		return

	owner.bleed(BLOOD_VOLUME_NORMAL)
	var/datum/organ/our_heart_datum = owner.get_int_organ_datum(ORGAN_DATUM_HEART)
	var/obj/item/organ/internal/our_heart = our_heart_datum.linked_organ
	var/obj/item/organ/external/heart_location = owner.get_organ(our_heart.parent_organ)
	owner.apply_damage(300, BRUTE, our_heart.parent_organ)
	heart_location.fracture()
	heart_location.disembowel(our_heart.parent_organ)

/mob/living/simple_animal/hostile/headslug/young
	name = "slug"
	desc = "A small, cute and fragile maroon worm like creature covered in slime, it looks like it was born recently. Looks... Familiar?"
	icon_state = "young_headslug"
	icon_living = "young_headslug"
	icon_dead = "young_headslug_dead"
	health = 30
	maxHealth = 30
	melee_damage_lower = 14
	melee_damage_upper = 20
	melee_damage_type = STAMINA
	mob_size = MOB_SIZE_TINY
	speed = 0.2 //slightly faster
	young = TRUE
	var/parent_changelingID
	var/datum/mind/parent  // <-         -          -         -          -             -               -             -          -        -	                                                                                                                                  \
//                                                                                                                                         |
//                                                                                                                                         /
/mob/living/simple_animal/hostile/headslug/young/proc/make_psionic_bond(mob/living/parentd) //parentd because we already have var/parent -
	parentd.mind.psionic_bond += src.mind
	src.mind.psionic_bond += parentd.mind

	src.parent = parentd.mind
	src.mind?.psionic_bond += parentd.mind.psionic_bond //this happens to have 3 and more members in psionic bond
	parentd.mind.psionic_bond += src.mind?.psionic_bond

	var/parent_name

	if(parent_changelingID)
		parent_name = parent_changelingID
	else
		if(ishuman(parentd.mind.current))
			var/mob/living/carbon/human/H = parent.current
			parent_name = H.real_name
		else
			parent_name = parent.current.name

	src.mind.store_memory("Our parent is [parent_name]. We can't hurt them.")

	var/datum/atom_hud/antag/hud
	if(!syndie)
		hud = GLOB.huds[ANTAG_HUD_YOUNG_CHANGELING]
	else
		hud = GLOB.huds[ANTAG_HUD_YOUNG_CHANGELING_SYNDIE]
	hud.join_hud(parentd.mind.current)

	hud.join_hud(src, 1)
	var/slug_icon
	if(!syndie)
		slug_icon = "hudyoungchangeling"
	else
		slug_icon = "hudyoungchangelingsyndie"

	set_antag_hud(src, "[slug_icon]")

	var/datum/antagonist/changeling/cling = parentd.mind.has_antag_datum(/datum/antagonist/changeling)

	if(cling)
		src.mind.store_memory("They are changeling, like us. They call themselves... [cling.changelingID]")

	var/the_icon
	if(cling)
		the_icon = "hudchangeling"
	else
		the_icon = "hudchangelingparent"

	set_antag_hud(parentd.mind.current, "[the_icon]")
	add_language("Psionic Bond")
	parentd.mind.current.add_language("Psionic Bond")
	var/datum/language/psionic_bond/pb = new()

	var/the_message = "<span class='changeling'><B><i><large>Use :[pb.key] to commune with your relative(s)!</large><i></B></span>"

	to_chat(src, the_message)
	to_chat(parentd, the_message)

/mob/living/simple_animal/hostile/headslug/young/attack_ghost(mob/user) //if nobody got on poll
	if(jobban_isbanned(user, "Syndicate"))
		to_chat(user, "<span class='warning'>You are banned from antagonists!</span>")
		return
	if(key)
		return
	if(stat != CONSCIOUS)
		return
	var/question = alert("Become a young headslug? (Warning, You can no longer be cloned!)",,"Yes","No")
	if(question == "No" || !src || QDELETED(src))
		return

	src.key = user.key
	make_psionic_bond(parent.current)

/obj/item/slug_flask
	name = "slug flask"
	desc = "This flask contains genetically modified young changeling's slug. There's a button on it's bottom..."
	icon_state = "slug_flask"
	w_class = WEIGHT_CLASS_SMALL
	var/is_in_use = FALSE
	var/mob/living/carbon/human/lesser_type
	var/lesser_type_name

/mob/living/simple_animal/hostile/headslug/young/syndie
	health = 40
	maxHealth = 40
	melee_damage_lower = 20
	melee_damage_upper = 24
	syndie = TRUE

/obj/item/slug_flask/examine(mob/user)
	. = ..()
	. += "The lesser form is: [lesser_type_name]"

/obj/item/slug_flask/attack_self(mob/user)

	switch(tgui_alert(user, "Choose.", "What to do?", list("Release", "Lesser Form Choice")))
		if("Release")
			var/datum/antagonist/changeling/clinger = user.mind.has_antag_datum(/datum/antagonist/changeling)
			if(clinger)
				to_chat(user, "<span class='changeling'>What are they doing to our younger ones?</span>")
			to_chat(user, "<span class='notice'>You are trying to press on the button...</span>")
			if(do_after(user, 2 SECONDS, 0, user) && !in_use)
				to_chat(user, "<span class='notice'>Done! But... Nothing happens. For now?</span>")
				is_in_use = TRUE

				var/mob/living/carbon/human/H = user

				var/list/candidates = SSghost_spawns.poll_candidates("Do you want to play as a young genetically modified headslug with master [H.real_name]?",  ROLE_CHANGELING, TRUE, poll_time = 20 SECONDS, source = /mob/living/simple_animal/hostile/headslug/young)

				if(!length(candidates))
					to_chat(user, "<span class='notice'>The slug seems doesn't want to come out...</span>")
					is_in_use = FALSE
					return

				var/mob/candidate = pick(candidates)

				var/mob/living/simple_animal/hostile/headslug/young/syndie/young_crab = new(get_turf(user))
				young_crab.key = candidate.key
				young_crab.the_lesser_type = lesser_type
				young_crab.parent = user.mind
				young_crab.make_psionic_bond(user)

				qdel(src)
				var/obj/item/stack/sheet/metal/M = new(get_turf(user))
				new /obj/item/shard(get_turf(user))
				M.amount = 2
				H.wetlevel = 1
				H.put_in_hands(M)

				playsound(H, 'sound/effects/hit_on_shattered_glass.ogg', 40, TRUE)

				if(!clinger)
					to_chat(user, "<span class='changeling'>We are free. Our hive is just us and our single autonomous parent - [H.real_name].</span>")
				else
					to_chat(user, "<span class='changeling'>We returned to hive. Thanks to [H.real_name] - [clinger.changelingID].</span>")

				young_crab.visible_message("<span class='warning'>Something worm-like, slimy and small crawls out of a metal flask, which immediately shrinks!</span>", "<span class='warning'>Something metal... Shrinks...</span>")

				var/explanation_text = "Obey every order from and protect [H.real_name]."
				young_crab.make_psionic_bond(H)
				var/datum/objective/protect/mindslave/O = new()
				O.owner = young_crab.mind
				O.target = user.mind
				O.explanation_text = explanation_text
				O.holder.add_objective(O, explanation_text, user)

				to_chat(young_crab, "<span class='boldnotice'>We can use Alt-Click to place our egg in any corpse to evolve!.</span>")
		else

			switch(tgui_alert(user, "Choose", "Lesser Form Choice", list("Monkey (Human)", "Neara (Skrell)", "Stok (Unathi)", "Wolpin (Vulpkanin)", "Farwa (Tajaran)")))
				if("Monkey (Human)")
					lesser_type = /mob/living/carbon/human/monkey
					lesser_type_name = "Monkey (Human)"
				if("Neara (Skrell)")
					lesser_type = /mob/living/carbon/human/neara
					lesser_type_name = "Neara (Skrell)"
				if("Stok (Unathi)")
					lesser_type = /mob/living/carbon/human/stok
					lesser_type_name = "Stok (Unathi)"
				if("Wolpin (Vulpkanin)")
					lesser_type = /mob/living/carbon/human/wolpin
					lesser_type_name = "Wolpin (Vulpkanin)"
				if("Farwa (Tajaran)")
					lesser_type = /mob/living/carbon/human/farwa
					lesser_type_name = "Farwa (Tajaran)"

/obj/item/storage/box/syndie_kit/slug
	name = "slug kit"

/obj/item/paper/slug
	name = "Slug Guide"
	icon_state = "paper"
	info = "<b>Grow your own Changeling! :<br></b>\
	<ul>\
	<li>Prepare an organic dead body of a monkey or a human with a heart nearby so that the slug can evolve into a changeling.</li>\
	<li>Select the type of lesser form if you want.</li>\
	<li>Press the button on flask's bottom.</li>\
	<li>Then wait for a half minute. If it doesn't work, try again later.</li>\
	<li>Profit!</li>\
	<hr>\
	<li><small><i>Little bonus: The changeling can always turn back into a lesser form without any mutations!</small></i></li>\
	<li><small><i>We are not responsible for the malfunction of the flask or/and the slug. The product is delivered under license as is. Use refund after all.</small></i></li>\
	<li><small><i><center><br>Biomoon Enterprises</br></center></small></i></li>\
	</ul>"

/obj/item/storage/box/syndie_kit/headslug/populate_contents()
	new /obj/item/slug_flask(src)
	new /obj/item/paper/slug(src)

#undef EGG_INCUBATION_DEAD_CYCLE
#undef EGG_INCUBATION_LIVING_CYCLE
