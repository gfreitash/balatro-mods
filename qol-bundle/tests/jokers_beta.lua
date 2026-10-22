-- qol-bundle/tests/jokers_beta.lua
-- Beta take_ownership features (mostly default-off): Flower Pot wildcard
-- rework, Seance secret-hand rework, Canio destruction rework, Onyx Agate
-- permanent-Mult rework.
-- Unit probes run through T.calc; destructive/shop flows get real integration
-- checks (played-card destruction, shop pool gating, perma_mult persistence).

return function(T)
	local F = QOL_BUNDLE.funcs

	local function in_playing_cards(card)
		for _, c in ipairs(G.playing_cards) do
			if c == card then
				return true
			end
		end
		return false
	end

	-- === Flower Pot (wildcard rework, default on) =========================

	BInt.register_test("riosodu/qol_bundle/beta_flower_pot_config", function(test)
		local g = T.apply_feature("flower_pot_wildcard_enabled", "j_flower_pot", F.get_ownership_joker_flower_pot)
		test:assert_eq(g.enhancement_gate, "m_wild", "Flower Pot should be shop-gated on Wild Cards")
		test:assert_eq(g.config.extra, 3, "the X mult should stay at the vanilla X3")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_flower_pot_wild_scoring", function(test)
		T.apply_feature("flower_pot_wildcard_enabled", "j_flower_pot", F.get_ownership_joker_flower_pot)
		T.start_run(test, "QOL_BETA_FP_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_flower_pot"):assert()

		local pot = G.jokers.cards[1]
		local wild = G.hand.cards[1]
		wild:set_ability(G.P_CENTERS.m_wild)
		local spade = T.force_card(2, "S_2")

		local eval = T.calc(pot, { joker_main = true, scoring_hand = { wild, spade } })
		test:assert_true(eval ~= nil, "a Wild Card in the scoring hand should trigger the rework")
		test:assert_true(math.abs(eval.Xmult_mod - 3) < 1e-9, "the wildcard trigger should give X3")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_flower_pot_no_wild_inert", function(test)
		T.apply_feature("flower_pot_wildcard_enabled", "j_flower_pot", F.get_ownership_joker_flower_pot)
		T.start_run(test, "QOL_BETA_FP_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_flower_pot"):assert()

		local pot = G.jokers.cards[1]
		T.force_card(1, "S_2")
		T.force_card(2, "H_3")
		local eval = T.calc(pot, { joker_main = true, scoring_hand = { G.hand.cards[1], G.hand.cards[2] } })
		test:assert_true(eval == nil, "two suits with no Wild Card should stay inert")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_flower_pot_vanilla_fallback", function(test)
		T.apply_feature("flower_pot_wildcard_enabled", "j_flower_pot", F.get_ownership_joker_flower_pot)
		T.start_run(test, "QOL_BETA_FP_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_flower_pot"):assert()

		local pot = G.jokers.cards[1]
		T.force_card(1, "S_2")
		T.force_card(2, "H_3")
		T.force_card(3, "D_4")
		T.force_card(4, "C_5")
		local hand = { G.hand.cards[1], G.hand.cards[2], G.hand.cards[3], G.hand.cards[4] }

		local eval = T.calc(pot, { joker_main = true, scoring_hand = hand })
		test:assert_true(eval ~= nil, "four suits with no Wild Card should fall back to the vanilla branch")
		test:assert_true(math.abs(eval.Xmult_mod - 3) < 1e-9, "the vanilla fallback should give X3")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_flower_pot_pool_gate", function(test)
		T.apply_feature("flower_pot_wildcard_enabled", "j_flower_pot", F.get_ownership_joker_flower_pot)
		T.start_run(test, "QOL_BETA_FP_4", 1)

		local function pool_has_flower_pot()
			-- Poll the Uncommon pool explicitly: get_current_pool("Joker") polls
			-- a random rarity, so the flower pot (Uncommon) is not guaranteed.
			local pool = get_current_pool("Joker", "Uncommon")
			for _, key in ipairs(pool) do
				if key == "j_flower_pot" then
					return true
				end
			end
			return false
		end

		-- The pool also culls locked jokers, so unlock Flower Pot for the probe.
		local flower_pot_center = G.P_CENTERS.j_flower_pot
		local prev_unlocked = flower_pot_center.unlocked
		flower_pot_center.unlocked = true

		test:assert_false(pool_has_flower_pot(), "Flower Pot should be culled without Wild Cards in the deck")
		G.playing_cards[1]:set_ability(G.P_CENTERS.m_wild)
		test:assert_true(pool_has_flower_pot(), "Flower Pot should be available once the deck owns a Wild Card")

		flower_pot_center.unlocked = prev_unlocked
	end)

	-- === Seance (secret-hand rework, default off) =========================

	BInt.register_test("riosodu/qol_bundle/beta_seance_config", function(test)
		test:assert_false(QOL_BUNDLE.config.seance_rework_enabled, "the Seance rework should default to off")
		local g = T.apply_feature("seance_rework_enabled", "j_seance", F.get_ownership_joker_seance)
		test:assert_eq(g.rarity, 3, "Seance should become Rare")
		test:assert_eq(g.cost, 8, "Seance should cost $8")
		test:assert_true(type(g.calculate) == "function", "the secret-hand calculate should be installed")
	end)

	local function seance_setup(test, seed)
		T.apply_feature("seance_rework_enabled", "j_seance", F.get_ownership_joker_seance)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_joker("j_seance"):assert()
		return G.jokers.cards[1]
	end

	BInt.register_test("riosodu/qol_bundle/beta_seance_secret_hand_spawns_spectral", function(test)
		local seance = seance_setup(test, "QOL_BETA_SEA_1")
		local before = #G.consumeables.cards

		local eval = T.calc(seance, {
			joker_main = true,
			poker_hands = { ["Five of a Kind"] = { { G.hand.cards[1] } } },
			scoring_name = "Five of a Kind",
			scoring_hand = { G.hand.cards[1] },
		})
		test:assert_true(eval ~= nil, "an invisible hand should trigger the rework")
		test:assert_eq(eval.message, localize('k_plus_spectral'), "the trigger should announce a Spectral card")
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "Seance should create one Spectral card")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_seance_straight_flush_single_trigger", function(test)
		local seance = seance_setup(test, "QOL_BETA_SEA_2")
		local before = #G.consumeables.cards

		local eval = T.calc(seance, {
			joker_main = true,
			poker_hands = { ["Straight Flush"] = { { G.hand.cards[1] } } },
			scoring_name = "Straight Flush",
			scoring_hand = { G.hand.cards[1] },
		})
		test:assert_true(eval ~= nil, "Straight Flush should keep triggering")
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "Straight Flush should create exactly one Spectral card")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_seance_visible_hand_ignored", function(test)
		local seance = seance_setup(test, "QOL_BETA_SEA_3")
		local before = #G.consumeables.cards

		local eval = T.calc(seance, {
			joker_main = true,
			poker_hands = { ["Flush"] = { { G.hand.cards[1] } } },
			scoring_name = "Flush",
			scoring_hand = { G.hand.cards[1] },
		})
		test:assert_true(eval ~= nil and next(eval) == nil, "a visible hand should return an empty claim")
		BInt._wait.stable_drain()
		test:assert_eq(#G.consumeables.cards, before, "visible hands must not create Spectral cards")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_seance_full_consumables_gate", function(test)
		local seance = seance_setup(test, "QOL_BETA_SEA_4")
		test:spawn_consumable("c_fool"):assert()
		test:spawn_consumable("c_fool"):assert()
		test:assert_eq(#G.consumeables.cards, G.consumeables.config.card_limit, "the consumable area should be full")

		local eval = T.calc(seance, {
			joker_main = true,
			poker_hands = { ["Five of a Kind"] = { { G.hand.cards[1] } } },
			scoring_name = "Five of a Kind",
			scoring_hand = { G.hand.cards[1] },
		})
		test:assert_true(eval ~= nil and next(eval) == nil, "a full consumable area should suppress the trigger")
		BInt._wait.stable_drain()
		test:assert_eq(#G.consumeables.cards, G.consumeables.config.card_limit, "no Spectral card may be created")
	end)

	-- === Canio (destruction rework, default off) ==========================

	BInt.register_test("riosodu/qol_bundle/beta_caino_config", function(test)
		test:assert_false(QOL_BUNDLE.config.caino_rework_enabled, "the Canio rework should default to off")
		local g = T.apply_feature("caino_rework_enabled", "j_caino", F.get_ownership_joker_caino)
		test:assert_eq(g.config.extra, 0.25, "Canio should gain X0.25 per destroyed face card")
		local lv = g.loc_vars(nil, {}, { ability = { extra = 0.25, caino_xmult = 1.5 } })
		test:assert_eq(lv.vars[1], 0.25, "loc var #1 should be the per-face gain")
		test:assert_eq(lv.vars[2], 1.5, "loc var #2 should be the current X mult")
	end)

	local function canio_setup(test, seed)
		T.apply_feature("caino_rework_enabled", "j_caino", F.get_ownership_joker_caino)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_joker("j_caino"):assert()
		return G.jokers.cards[1]
	end

	BInt.register_test("riosodu/qol_bundle/beta_caino_destroying_card", function(test)
		local canio = canio_setup(test, "QOL_BETA_CAN_1")
		local king = T.force_card(1, "S_K")
		local eval = T.calc(canio, { destroying_card = king, full_hand = { king } })
		test:assert_true(eval ~= nil and eval.remove == true, "a scored face card should be marked for destruction")

		local low = T.force_card(2, "S_7")
		local eval_low = T.calc(canio, { destroying_card = low, full_hand = { low } })
		test:assert_true(eval_low == nil, "non-face cards must not be destroyed")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_caino_remove_playing_cards_scaling", function(test)
		local canio = canio_setup(test, "QOL_BETA_CAN_2")
		local face_a = T.force_card(1, "S_K")
		local low = T.force_card(2, "S_3")
		local face_b = T.force_card(3, "H_Q")

		local eval = T.calc(canio, { remove_playing_cards = true, removed = { face_a, low, face_b } })
		test:assert_true(eval ~= nil, "destroyed face cards should report")
		test:assert_true(math.abs(canio.ability.caino_xmult - 1.5) < 1e-9, "two faces destroyed should give X1.5")

		local eval_low = T.calc(canio, { remove_playing_cards = true, removed = { low } })
		test:assert_true(eval_low ~= nil and next(eval_low) == nil, "non-face removals should return an empty table")
		test:assert_true(math.abs(canio.ability.caino_xmult - 1.5) < 1e-9, "non-face removals must not scale")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_caino_blueprint_no_op", function(test)
		local canio = canio_setup(test, "QOL_BETA_CAN_3")
		local king = T.force_card(1, "S_K")

		local eval = T.calc(canio, { destroying_card = king, full_hand = { king }, blueprint = 1 })
		test:assert_true(eval == nil, "blueprint passes must not destroy face cards")

		local eval_removed = T.calc(canio, { remove_playing_cards = true, removed = { king }, blueprint = 1 })
		test:assert_true(eval_removed == nil, "blueprint passes must not scale the X mult")
		test:assert_eq(canio.ability.caino_xmult, 1, "blueprint passes leave the X mult untouched")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_caino_joker_main", function(test)
		local canio = canio_setup(test, "QOL_BETA_CAN_4")
		canio.ability.caino_xmult = 1.5
		local eval = T.calc(canio, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil and math.abs(eval.Xmult_mod - 1.5) < 1e-9, "scoring should use the accumulated X mult")

		canio.ability.caino_xmult = 1
		local eval_base = T.calc(canio, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval_base ~= nil and next(eval_base) == nil, "at X1 Canio should return an empty table")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_caino_integration_destroy", function(test)
		local canio = canio_setup(test, "QOL_BETA_CAN_5")
		local king = T.force_card(1, "S_K")
		T.force_card(2, "S_2")
		T.force_card(3, "H_3")
		T.force_card(4, "D_4")
		T.force_card(5, "C_5")

		local cards_before = #G.playing_cards
		T.win_round(test)
		BInt._wait.for_condition(function()
			return not in_playing_cards(king)
		end, 10, "the scored King should be destroyed")
		BInt._wait.for_condition(function()
			return math.abs(canio.ability.caino_xmult - 1.25) < 1e-9
		end, 10, "exactly one destroyed face should give X0.25 (no double scaling)")

		test:assert_eq(#G.playing_cards, cards_before - 1, "the deck registry should shrink by the destroyed card")
	end)

	-- === Onyx Agate (permanent Mult rework, default off) ==================

	BInt.register_test("riosodu/qol_bundle/beta_onyx_config", function(test)
		test:assert_false(QOL_BUNDLE.config.onyx_agate_enabled, "the Onyx Agate rework should default to off")
		local g = T.apply_feature("onyx_agate_enabled", "j_onyx_agate", F.get_ownership_joker_onyx_agate)
		test:assert_eq(g.config.extra, 3, "scored Clubs should gain +3 permanent Mult")
		local lv = g.loc_vars(nil, {}, { ability = { extra = 3 } })
		test:assert_eq(lv.vars[1], 3, "loc var #1 should be the per-Club permanent Mult")
	end)

	local function onyx_setup(test, seed)
		T.apply_feature("onyx_agate_enabled", "j_onyx_agate", F.get_ownership_joker_onyx_agate)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_joker("j_onyx_agate"):assert()
		return G.jokers.cards[1]
	end

	BInt.register_test("riosodu/qol_bundle/beta_onyx_club_perma_mult", function(test)
		local onyx = onyx_setup(test, "QOL_BETA_ONX_1")
		local club = T.force_card(1, "C_7")
		local eval = T.calc(onyx, { individual = true, cardarea = G.play, other_card = club })
		test:assert_true(eval ~= nil, "a scored Club should trigger the rework")
		test:assert_eq(club.ability.perma_mult, 3, "the Club should permanently gain +3 Mult")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_onyx_non_club_inert", function(test)
		local onyx = onyx_setup(test, "QOL_BETA_ONX_2")
		local spade = T.force_card(1, "S_7")
		local eval = T.calc(onyx, { individual = true, cardarea = G.play, other_card = spade })
		test:assert_true(eval == nil, "non-Clubs should stay inert")
		test:assert_eq(spade.ability.perma_mult, 0, "non-Clubs must not gain permanent Mult")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_onyx_blueprint_claims", function(test)
		local onyx = onyx_setup(test, "QOL_BETA_ONX_3")
		local club = T.force_card(1, "C_7")
		local eval = T.calc(onyx, { individual = true, cardarea = G.play, other_card = club, blueprint = 1 })
		test:assert_true(eval ~= nil and next(eval) == nil, "blueprint passes should claim the context with an empty table")
		test:assert_eq(club.ability.perma_mult, 0, "blueprint passes must not copy the permanent gain")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_onyx_integration_persists", function(test)
		local onyx = onyx_setup(test, "QOL_BETA_ONX_4")
		local club = T.force_card(1, "C_7")
		T.force_card(2, "S_2")
		T.force_card(3, "H_3")
		T.force_card(4, "D_4")
		T.force_card(5, "S_5")

		T.win_round(test)
		BInt._wait.for_condition(function()
			return club.ability.perma_mult == 3
		end, 10, "the scored Club should gain +3 permanent Mult")

		-- The gain lives on the card object and must survive the round change.
		test:go_to_shop():assert()
		test:leave_shop():assert()
		test:select_blind():assert()
		test:assert_true(in_playing_cards(club), "the Club should stay in the deck")
		test:assert_eq(club.ability.perma_mult, 3, "the permanent Mult should persist across rounds")
	end)

	-- === Matador (beta): $5 per hand in a Boss Blind ======================

	local function matador_setup(test, seed)
		T.apply_feature("matador_rework_enabled", "j_matador", F.get_ownership_joker_matador)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_joker("j_matador"):assert()
		return G.jokers.cards[1]
	end

	BInt.register_test("riosodu/qol_bundle/beta_matador_pays_per_boss_hand", function(test)
		local matador = matador_setup(test, "QOL_BETA_MATADOR_1")

		local was_boss = G.GAME.blind.boss
		local hands_played = G.GAME.current_round.hands_played
		G.GAME.blind.boss = true
		G.GAME.current_round.hands_played = 3
		local boss_bonus = matador:calculate_dollar_bonus()
		G.GAME.blind.boss = false
		local non_boss_bonus = matador:calculate_dollar_bonus()
		G.GAME.blind.boss = was_boss
		G.GAME.current_round.hands_played = hands_played

		test:assert_eq(boss_bonus, 15, "a Boss Blind with 3 hands should pay $15")
		test:assert_true(non_boss_bonus == nil, "non-Boss blinds must not pay")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_matador_suppresses_vanilla_payout", function(test)
		local matador = matador_setup(test, "QOL_BETA_MATADOR_2")
		local eval = T.calc(matador, { debuffed_hand = true })
		test:assert_true(eval ~= nil and next(eval) == nil,
			"the vanilla $8 boss-ability payout must be suppressed")
	end)

	-- === Red Card (beta): opened +1, skipped +2 ===========================

	local function red_card_setup(test, seed)
		T.apply_feature("red_card_rework_enabled", "j_red_card", F.get_ownership_joker_red_card)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_joker("j_red_card"):assert()
		return G.jokers.cards[1]
	end

	BInt.register_test("riosodu/qol_bundle/beta_red_card_open_and_skip", function(test)
		local red = red_card_setup(test, "QOL_BETA_RED_1")
		test:assert_eq(red.ability.mult, 0, "precondition: no Mult yet")

		T.calc(red, { open_booster = true })
		test:assert_eq(red.ability.mult, 1, "opening a Booster Pack should give +1 Mult")

		T.calc(red, { open_booster = true, blueprint = 1 })
		test:assert_eq(red.ability.mult, 1, "blueprint passes must not grant Mult")

		T.calc(red, { skipping_booster = true })
		test:assert_eq(red.ability.mult, 3, "skipping a Booster Pack should give +2 Mult (not +3)")

		local loc_vars = G.P_CENTERS.j_red_card.loc_vars(nil, {}, red)
		test:assert_eq(loc_vars.vars[1], 1, "tooltip #1# should be the opened gain")
		test:assert_eq(loc_vars.vars[2], 2, "tooltip #2# should be the skipped gain")
		test:assert_eq(loc_vars.vars[3], red.ability.mult, "tooltip #3# should be the current Mult")
	end)

	-- === Bull (beta): +3 Chips per $ ======================================

	BInt.register_test("riosodu/qol_bundle/beta_bull_three_chips_per_dollar", function(test)
		T.apply_feature("bull_buff_enabled", "j_bull", F.get_ownership_joker_bull)
		T.start_run(test, "QOL_BETA_BULL_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_bull"):assert()

		test:assert_eq(G.P_CENTERS.j_bull.config.extra, 3, "Bull should give +3 Chips per $1")

		local bull = G.jokers.cards[1]
		G.GAME.dollars = 10
		local eval = T.calc(bull, { joker_main = true })
		test:assert_eq(eval.chip_mod, 30, "$10 should give +30 Chips")
	end)

	-- === Mr. Bones (beta): always saves, then cripples the run ============

	BInt.register_test("riosodu/qol_bundle/beta_mr_bones_always_saves_and_cripples", function(test)
		T.apply_feature("mr_bones_rework_enabled", "j_mr_bones", F.get_ownership_joker_mr_bones)
		T.start_run(test, "QOL_BETA_BONES_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_mr_bones"):assert()

		test:assert_eq(G.P_CENTERS.j_mr_bones.cost, 10, "Mr. Bones should cost $10")

		local bones = G.jokers.cards[1]
		local dollars_before = G.GAME.dollars
		local ante_before = G.GAME.round_resets.ante
		local hands_before = G.GAME.round_resets.hands
		local discards_before = G.GAME.round_resets.discards
		local hand_size_before = G.hand.config.card_limit
		test:assert_true(dollars_before > 0, "precondition: the player has money")

		-- No 25% threshold anymore: even 0 chips must be saved.
		G.GAME.chips = 0
		G.GAME.blind.chips = 100
		local eval = T.calc(bones, { game_over = true })
		BInt._wait.for_condition(function()
			return #G.jokers.cards == 0
		end, 10, "Mr. Bones should self-destruct after saving")
		BInt._wait.stable_drain()

		test:assert_true(eval ~= nil and eval.saved == true, "Mr. Bones should save the run")
		test:assert_eq(G.GAME.dollars, 0, "the run should be set to $0")
		test:assert_eq(G.GAME.round_resets.ante, ante_before - 1, "the run should lose 1 Ante")
		test:assert_eq(G.GAME.round_resets.blind_ante, ante_before - 1,
			"the current blind's Ante should also drop by 1")
		test:assert_eq(G.GAME.round_resets.hands, hands_before - 1, "the run should lose 1 hand")
		test:assert_eq(G.GAME.round_resets.discards, discards_before - 1, "the run should lose 1 discard")
		test:assert_eq(G.hand.config.card_limit, hand_size_before - 1, "the hand size should drop by 1")
		test:assert_true(G.localization.descriptions.Other.crippled ~= nil,
			"the Crippled tooltip must be readable")
	end)
end
