-- qol-bundle/tests/jokers_scaling.lua
-- Scaling/behavior take_ownership features: Square, Erosion, Yorick, Loyalty
-- Card and Satellite. Behavior is probed through the SMods center-injected
-- calculate path (T.calc) so exact scoring tables can be asserted.

return function(T)
	local F = QOL_BUNDLE.funcs

	-- === Square: 4-card hands grant +2 chips plus a 1-in-2 +4 bonus per card ===

	BInt.register_test("riosodu/qol_bundle/square_config", function(test)
		local g = T.apply_feature("square_joker_enabled", "j_square", F.get_ownership_joker_square)
		test:assert_eq(g.rarity, 2, "Square should be Uncommon")
		local extra = g.config.extra
		test:assert_eq(extra.chips, 0, "chips start at 0")
		test:assert_eq(extra.chip_mod, 2, "base gain is +2")
		test:assert_eq(extra.bonus_chip_mod, 4, "bonus gain is +4")
		test:assert_eq(extra.odds, 2, "bonus chance is 1 in 2")
	end)

	BInt.register_test("riosodu/qol_bundle/square_four_cards_all_bonus", function(test)
		T.apply_feature("square_joker_enabled", "j_square", F.get_ownership_joker_square)
		T.start_run(test, "QOL_SQ_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_square"):assert()

		local card = G.jokers.cards[1]
		local prev_normal = G.GAME.probabilities.normal
		G.GAME.probabilities.normal = 100

		local hand = { G.hand.cards[1], G.hand.cards[2], G.hand.cards[3], G.hand.cards[4] }
		T.calc(card, { before = true, cardarea = G.jokers, full_hand = hand, scoring_hand = hand })

		G.GAME.probabilities.normal = prev_normal
		-- 2 base + 4 successful rolls * 4 bonus
		test:assert_eq(card.ability.extra.chips, 18, "all four bonus rolls should land")
	end)

	BInt.register_test("riosodu/qol_bundle/square_four_cards_no_bonus", function(test)
		T.apply_feature("square_joker_enabled", "j_square", F.get_ownership_joker_square)
		T.start_run(test, "QOL_SQ_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_square"):assert()

		local card = G.jokers.cards[1]
		local prev_normal = G.GAME.probabilities.normal
		G.GAME.probabilities.normal = 0

		local hand = { G.hand.cards[1], G.hand.cards[2], G.hand.cards[3], G.hand.cards[4] }
		T.calc(card, { before = true, cardarea = G.jokers, full_hand = hand, scoring_hand = hand })

		G.GAME.probabilities.normal = prev_normal
		test:assert_eq(card.ability.extra.chips, 2, "a failed roll set should only grant the base +2")
	end)

	BInt.register_test("riosodu/qol_bundle/square_five_cards_ignored", function(test)
		T.apply_feature("square_joker_enabled", "j_square", F.get_ownership_joker_square)
		T.start_run(test, "QOL_SQ_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_square"):assert()

		local card = G.jokers.cards[1]
		local hand = { G.hand.cards[1], G.hand.cards[2], G.hand.cards[3], G.hand.cards[4], G.hand.cards[5] }
		T.calc(card, { before = true, cardarea = G.jokers, full_hand = hand, scoring_hand = hand })

		test:assert_eq(card.ability.extra.chips, 0, "hands of 5 must not scale Square")
	end)

	BInt.register_test("riosodu/qol_bundle/square_joker_main_chips", function(test)
		T.apply_feature("square_joker_enabled", "j_square", F.get_ownership_joker_square)
		T.start_run(test, "QOL_SQ_4", 1)
		test:select_blind():assert()
		test:spawn_joker("j_square"):assert()

		local card = G.jokers.cards[1]
		card.ability.extra.chips = 18
		local eval = T.calc(card, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil, "Square should contribute during joker_main")
		test:assert_eq(eval.chip_mod, 18, "chip contribution should match the accumulated chips")
	end)

	-- === Erosion: X mult per card below the starting deck size ===

	BInt.register_test("riosodu/qol_bundle/erosion_config", function(test)
		local g = T.apply_feature("erosion_xmult_enabled", "j_erosion", F.get_ownership_joker_erosion)
		test:assert_eq(g.config.extra, 0.175, "X mult per missing card should be 0.175")
	end)

	BInt.register_test("riosodu/qol_bundle/erosion_xmult_direct", function(test)
		T.apply_feature("erosion_xmult_enabled", "j_erosion", F.get_ownership_joker_erosion)
		T.start_run(test, "QOL_ER_1", 1)
		test:assert_true(T.remove_deck_card("2h"), "deck card 2h should exist")
		test:assert_true(T.remove_deck_card("3h"), "deck card 3h should exist")
		test:select_blind():assert()
		test:spawn_joker("j_erosion"):assert()

		local card = G.jokers.cards[1]
		local eval = T.calc(card, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil, "Erosion should trigger with cards missing")
		test:assert_true(math.abs(eval.Xmult_mod - 1.35) < 1e-9, "two missing cards should give X1.35")
	end)

	BInt.register_test("riosodu/qol_bundle/erosion_full_deck_nil", function(test)
		T.apply_feature("erosion_xmult_enabled", "j_erosion", F.get_ownership_joker_erosion)
		T.start_run(test, "QOL_ER_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_erosion"):assert()

		local eval = T.calc(G.jokers.cards[1], { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval == nil, "full deck should leave both qol and vanilla Erosion inert")
	end)

	-- End-to-end score probe: one Ace (5 base + 11 chips) x1.35 = 21.6 -> 21.
	BInt.register_test("riosodu/qol_bundle/erosion_score_smoke", function(test)
		T.apply_feature("erosion_xmult_enabled", "j_erosion", F.get_ownership_joker_erosion)
		T.start_run(test, "QOL_ER_3", 1)
		test:assert_true(T.remove_deck_card("2h"), "deck card 2h should exist")
		test:assert_true(T.remove_deck_card("3h"), "deck card 3h should exist")
		test:select_blind():assert()
		test:spawn_joker("j_erosion"):assert()

		T.force_card(1, "S_A")
		test:highlight({ 1 }):assert()
		G.GAME.blind.chips = 1e9
		test:play_hand():assert()

		test:assert_eq(G.GAME.chips, 21, "the X mult should be applied to the scored hand")
	end)

	BInt.register_test("riosodu/qol_bundle/erosion_loc_vars", function(test)
		T.apply_feature("erosion_xmult_enabled", "j_erosion", F.get_ownership_joker_erosion)
		T.start_run(test, "QOL_ER_4", 1)
		test:assert_true(T.remove_deck_card("2h"), "deck card 2h should exist")
		test:assert_true(T.remove_deck_card("3h"), "deck card 3h should exist")
		test:select_blind():assert()
		test:spawn_joker("j_erosion"):assert()

		local res = G.P_CENTERS.j_erosion:loc_vars({}, G.jokers.cards[1])
		test:assert_eq(res.vars[1], 0.175, "per-card X mult var")
		test:assert_eq(res.vars[3], 1.35, "current X mult var should reflect the missing cards")
	end)

	-- === Yorick: configurable X mult per 23 discards ===

	BInt.register_test("riosodu/qol_bundle/yorick_config", function(test)
		local g = T.apply_feature("yorick_multiplier_enabled", "j_yorick", F.get_ownership_joker_yorick)
		test:assert_eq(g.config.extra.xmult, 1.5, "default multiplier is X1.5")
		test:assert_eq(g.config.extra.discards, 23, "still ticks every 23 discards")
	end)

	BInt.register_test("riosodu/qol_bundle/yorick_discard_tick", function(test)
		T.apply_feature("yorick_multiplier_enabled", "j_yorick", F.get_ownership_joker_yorick)
		T.start_run(test, "QOL_YO_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_yorick"):assert()

		local card = G.jokers.cards[1]
		card.ability.yorick_discards = 1
		T.calc(card, { discard = true, full_hand = { G.hand.cards[1] }, other_card = G.hand.cards[1] })

		test:assert_true(math.abs(card.ability.x_mult - 2.5) < 1e-9, "one tick should add X1.5 to the base X1")
		test:assert_eq(card.ability.yorick_discards, 23, "the counter should reset for the next cycle")
	end)

	BInt.register_test("riosodu/qol_bundle/yorick_callback_and_respawn", function(test)
		local g = T.apply_feature("yorick_multiplier_enabled", "j_yorick", F.get_ownership_joker_yorick)

		local orig_save = SMODS.save_mod_config
		SMODS.save_mod_config = function() end
		G.FUNCS.qol_bundle_yorick_callback({ to_key = 3, to_val = 2.5 })
		SMODS.save_mod_config = orig_save

		test:assert_eq(QOL_BUNDLE.config.yorick_multiplier_value, 2.5, "callback should update the config value")
		test:assert_eq(g.config.extra.xmult, 2.5, "callback should update the taken-over center")

		T.start_run(test, "QOL_YO_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_yorick"):assert()
		test:assert_eq(G.jokers.cards[1].ability.extra.xmult, 2.5, "new Yoricks should use the updated multiplier")
	end)

	-- === Loyalty Card: scaling X mult per finished blind (beta) ===

	BInt.register_test("riosodu/qol_bundle/loyalty_config_when_enabled", function(test)
		test:assert_false(QOL_BUNDLE.config.loyalty_card_scaling_enabled, "Loyalty scaling should default to off")
		local g = T.apply_feature("loyalty_card_scaling_enabled", "j_loyalty_card", F.get_ownership_loyalty_card)
		test:assert_eq(g.config.extra.Xmult, 1, "starts at X1")
		test:assert_eq(g.config.extra.every, 6, "keeps a legacy counter field for vanilla UI paths")
		test:assert_true(type(g.calculate) == "function", "scaling calculate should be installed")
	end)

	BInt.register_test("riosodu/qol_bundle/loyalty_end_of_round_ladder", function(test)
		local g = T.apply_feature("loyalty_card_scaling_enabled", "j_loyalty_card", F.get_ownership_loyalty_card)
		T.start_run(test, "QOL_LO_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_loyalty_card"):assert()

		local card = G.jokers.cards[1]
		local expected = { 1.5, 2, 2.5, 3, 3.5, 4, 2 }
		for i, value in ipairs(expected) do
			T.calc(card, { end_of_round = true, cardarea = G.jokers })
			test:assert_true(
				math.abs(card.ability.extra.Xmult - value) < 1e-9,
				"tick " .. i .. " should reach X" .. value .. " (got X" .. tostring(card.ability.extra.Xmult) .. ")"
			)
		end
	end)

	BInt.register_test("riosodu/qol_bundle/loyalty_guard_subcontexts", function(test)
		T.apply_feature("loyalty_card_scaling_enabled", "j_loyalty_card", F.get_ownership_loyalty_card)
		T.start_run(test, "QOL_LO_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_loyalty_card"):assert()

		local card = G.jokers.cards[1]
		card.ability.extra.Xmult = 2

		for _, guard in ipairs({ "individual", "repetition", "game_over", "blueprint" }) do
			local ctx = { end_of_round = true, cardarea = G.jokers }
			ctx[guard] = true
			T.calc(card, ctx)
			test:assert_true(
				math.abs(card.ability.extra.Xmult - 2) < 1e-9,
				"subcontext '" .. guard .. "' must not advance the scaling"
			)
		end
	end)

	BInt.register_test("riosodu/qol_bundle/loyalty_joker_main", function(test)
		T.apply_feature("loyalty_card_scaling_enabled", "j_loyalty_card", F.get_ownership_loyalty_card)
		T.start_run(test, "QOL_LO_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_loyalty_card"):assert()

		local card = G.jokers.cards[1]
		card.ability.extra.Xmult = 2
		local eval = T.calc(card, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil and eval.Xmult_mod == 2, "X2 should be contributed during scoring")

		card.ability.extra.Xmult = 1
		local eval2 = T.calc(card, { joker_main = true, cardarea = G.jokers })
		test:assert_false(eval2 ~= nil and eval2.Xmult_mod ~= nil, "X1 should contribute nothing")
	end)

	-- Integration: exactly one tick per finished blind (main pass only).
	BInt.register_test("riosodu/qol_bundle/loyalty_integration_single_tick", function(test)
		T.apply_feature("loyalty_card_scaling_enabled", "j_loyalty_card", F.get_ownership_loyalty_card)
		T.start_run(test, "QOL_LO_4", 2)
		test:select_blind():assert()
		test:spawn_joker("j_loyalty_card"):assert()

		local card = G.jokers.cards[1]
		T.win_round(test, 0)

		test:assert_true(
			math.abs(card.ability.extra.Xmult - 1.5) < 1e-9,
			"finishing a blind should tick exactly once (got X" .. tostring(card.ability.extra.Xmult) .. ")"
		)
	end)

	-- === Satellite: dollars equal to half the highest poker hand level (rounded up) ===

	BInt.register_test("riosodu/qol_bundle/satellite_dollar_direct", function(test)
		T.apply_feature("satellite_joker_enabled", "j_satellite", F.get_ownership_joker_satellite)
		T.start_run(test, "QOL_SA_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_satellite"):assert()

		local card = G.jokers.cards[1]
		G.GAME.hands["High Card"].level = 7
		test:assert_eq(card:calculate_dollar_bonus(), 4, "level 7 should pay $4 (ceil(7/2))")

		G.GAME.hands["High Card"].level = 2
		test:assert_eq(card:calculate_dollar_bonus(), 1, "level 2 should pay $1")

		card.debuff = true
		test:assert_true(card:calculate_dollar_bonus() == nil, "debuffed Satellite should pay nothing")
	end)

	BInt.register_test("riosodu/qol_bundle/satellite_round_dollars", function(test)
		T.apply_feature("satellite_joker_enabled", "j_satellite", F.get_ownership_joker_satellite)
		T.start_run(test, "QOL_SA_2", 2)
		test:select_blind():assert()
		test:spawn_joker("j_satellite"):assert()
		G.GAME.hands["High Card"].level = 7

		T.win_round(test, 0)

		test:assert_eq(T.round_dollars(test), 4, "the end-of-round joker row should pay the Satellite bonus")
	end)

	-- Documents the current rounding: the code uses math.ceil while the text
	-- says "rounded down" (reported as a doc/code mismatch).
	BInt.register_test("riosodu/qol_bundle/satellite_text_rounding", function(test)
		T.apply_feature("satellite_joker_enabled", "j_satellite", F.get_ownership_joker_satellite)
		T.start_run(test, "QOL_SA_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_satellite"):assert()

		G.GAME.hands["High Card"].level = 3
		test:assert_eq(G.jokers.cards[1]:calculate_dollar_bonus(), 2, "level 3 rounds up to $2")
	end)
end
