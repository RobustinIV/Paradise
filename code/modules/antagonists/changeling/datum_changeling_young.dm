
/datum/antagonist/changeling/young
	name = "Young Changeling"
	roundend_category = "young changelings"
	antag_hud_name = "hudyoungchangeling"
	antag_hud_type = ANTAG_HUD_YOUNG_CHANGELING
	dna_max = 3
	absorbed_count = 0
	chem_charges = 40
	chem_recharge_rate = 1
	chem_storage = 40
	genetic_points = 10
	blurb_text_color = COLOR_VIOLET
	young = TRUE
	var/datum/mind/parent_mind
	var/parent_ling_id
	var/syndie = FALSE

/datum/antagonist/changeling/young/on_gain()
	. = ..()

 	changelingID = "Young [changelingID]"

/datum/antagonist/changeling/young/farewell()
	to_chat(owner.current, "<span class='biggerdanger'><B>By some reason you're not a changeling anymore... ?</span>")

/datum/antagonist/changeling/young/give_objectives()
	add_antag_objective(/datum/objective/absorb)

	var/datum/objective/absorb/a = locate() in owner.get_all_objectives()
	a.target_amount = a.target_amount / 2

	var/list/objective_to_pick = list("Steal" = 2, "Debrain" = 4, "Kill" = 5, "Destroy" = 1)
	var/the_objective = pickweight(objective_to_pick)

	var/mob/living/carbon/human/H
	var/datum/objective/assassinate/kill_objective

	switch(the_objective)
		if("Steal")
			add_antag_objective(/datum/objective/steal)
		if("Debrain")
			add_antag_objective(/datum/objective/debrain)
		if("Kill")
			kill_objective = add_antag_objective(/datum/objective/assassinate)
			H = kill_objective.target?.current
		if("Destroy")
			var/list/active_ais = active_ais()
			if(length(active_ais))
				add_antag_objective(/datum/objective/destroy)


	if(!(locate(/datum/objective/escape) in owner.get_all_objectives(include_team = FALSE)))
		if(prob(80))
			add_antag_objective(/datum/objective/escape)
		else
			if(!(locate(/datum/objective/escape) in owner.get_all_objectives(include_team = FALSE)) && H && !HAS_TRAIT(H, TRAIT_GENELESS))
				var/datum/objective/escape/escape_with_identity/identity_theft = new(assassinate = kill_objective)
				add_antag_objective(identity_theft)


	parent_mind.offstation_role = FALSE

/proc/isyoungchangeling(mob/M)
	return M.mind?.has_antag_datum(/datum/antagonist/changeling/young)

/datum/antagonist/changeling/young/custom_blurb()
	return "We were born in the [get_area_name(owner.current, TRUE)]..."

/datum/antagonist/changeling/young/syndie
	name = "Syndicate Young Changeling"
	roundend_category = "syndicate young changelings"
	antag_hud_name = "hudyoungchangelingsyndie"
	antag_hud_type = ANTAG_HUD_YOUNG_CHANGELING_SYNDIE
	blurb_text_color = COLOR_MAROON

	//they're genetically modified, so they are a little stronger than their usual siblings.
	dna_max = 4
	chem_charges = 50
	chem_recharge_rate = 2
	chem_storage = 50
	genetic_points = 12
	give_objectives = FALSE
	syndie = TRUE

/datum/antagonist/changeling/young/syndie/give_objectives() //gives mindslave like objective to obey and protect
	return
