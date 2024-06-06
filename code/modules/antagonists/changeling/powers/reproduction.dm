
/datum/action/changeling/reproduction
	name = "Reproduction"
	desc = "We are making a new hive member. Costs 75 chemicals."
	helptext = "It takes about twenty seconds for a young headslug to appear."
	button_icon_state = "reproduction"
	chemical_cost = 0
	req_human = TRUE
	power_type = CHANGELING_UNOBTAINABLE_POWER
	category = /datum/changeling_power_category/utility

//Recover from stuns.
/datum/action/changeling/reproduction/sting_action(mob/living/user)
	if(do_after(user, 1 SECONDS, 0, user))
		to_chat(user, "<span class='notice'>We preparing chemicals for transformation...</span>")

	var/list/candidates = SSghost_spawns.poll_candidates("Do you want to play as a young headslug, the child of [cling.changelingID]?",  ROLE_CHANGELING, TRUE, poll_time = 20 SECONDS, source = /mob/living/simple_animal/hostile/headslug/young)

	cling.chem_charges = 0
	if(do_after(user, 20 SECONDS, 0, user, 1, allow_moving = 1))
		if(cling.chem_charges < 75)
			to_chat(user, "<span class='warning'>Not enough chemicals.</span>")
			return
		cling.chem_charges -= 75
		var/datum/objective/reproduction/rep = locate() in cling.owner.get_all_objectives()
		rep.created++
		if(rep.created >= rep.target_amount)
			var/datum/action/changeling/reproduction/rep_power = locate() in cling.owner.current.actions
			cling.acquired_powers -= rep_power
			qdel(rep_power)
			Remove(rep_power)
			to_chat(user, "<span class='changeling'>That's enough.</span>")

		var/mob/living/simple_animal/hostile/headslug/young/young_crab = new(get_turf(user)) //spawns always cus if no ghosts then no greentext for ling
		if(!length(candidates))
			to_chat(user, "<span class='notice'>Unfortunately, the newborn is thoughtless. For now...</span>")
			notify_ghosts("A young headslug in [get_area(src)] of [cling.changelingID] has born without mind.", enter_link = "<a href=?src=[UID()];ghostjoin=1>(Click to enter)</a>", source = young_crab, action = NOTIFY_ATTACK)
		var/mob/living/carbon/C = user
		user.visible_message("<span class='danger'>[user] burps and a worm-like slug is visible among his vomit!</span>", "Someone burps. But something is... Wrong.")
		C.vomit(0, 0, FALSE)

		young_crab.parent_changelingID = cling.changelingID
		young_crab.parent = user.mind
		if(young_crab.mind)
			young_crab.make_psionic_bond(user)

	SSblackbox.record_feedback("nested tally", "changeling_powers", 1, list("[name]"))
	return TRUE
