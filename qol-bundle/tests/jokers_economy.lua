-- qol-bundle/tests/jokers_economy.lua
-- Economy/behavior take_ownership features: Hit the Road, Castle, Marble, Stone,
-- Steel. Exact effects are probed through the SMods center-injected calculate
-- path (T.calc); flow-dependent behavior (discard returns, blind selection,
-- deck selection) is exercised with real integration actions.
--
-- Fall-through note: SMods (lovely/center.toml) runs the center's calculate
-- first and only falls back to the vanilla name chain in card.lua when it
-- returns nil. The reworks rely on that: Hit the Road keeps the vanilla scaling
-- through the fall-through, Castle/Marble/Stone return their own effects only
-- for the contexts they rework.

return function(T)
	local F = QOL_BUNDLE.funcs

	local function in_area(area, card)
		for _, c in ipairs(area.cards) do
			if c == card then
				return true
			end
		end
		return false
	end

	--- Counts card objects appearing in more than one area (must stay 0) and
	--- how many area cards exist in total (must equal #G.playing_cards).
	local function area_invariants()
		local seen, duplicates, seen_count = {}, 0, 0
		for _, area in ipairs({ G.deck, G.hand, G.discard, G.play }) do
			for _, c in ipairs(area.cards) do
				seen_count = seen_count + 1
				if seen[c] then
					duplicates = duplicates + 1
				else
					seen[c] = true
				end
			end
		end
		return duplicates, seen_count
	end

	-- === Hit the Road =====================================================

	BInt.register_test("riosodu/qol_bundle/econ_htr_xmult_gain", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_ECON_HTR_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_hit_the_road"):assert()

		local joker = G.jokers.cards[1]
		local jack = T.force_card(1, "S_J")
		test:assert_eq(joker.ability.x_mult, 1, "Hit the Road should start at X1")

		-- SMods patches this branch to `return nil, true` (the trigger signal);
		-- the scaling itself lands through SMODS.scale_card.
		local eval, triggered = T.calc(joker, { discard = true, other_card = jack, full_hand = { jack } })
		test:assert_true(triggered == true, "discarding a Jack should tick the X mult")
		test:assert_eq(joker.ability.x_mult, 1.5, "one discarded Jack should give X0.5")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_htr_two_jacks_gain", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_ECON_HTR_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_hit_the_road"):assert()

		local joker = G.jokers.cards[1]
		local jack_a = T.force_card(1, "S_J")
		local jack_b = T.force_card(2, "H_J")

		T.calc(joker, { discard = true, other_card = jack_a, full_hand = { jack_a, jack_b } })
		T.calc(joker, { discard = true, other_card = jack_b, full_hand = { jack_a, jack_b } })
		test:assert_eq(joker.ability.x_mult, 2, "two discarded Jacks should give X1.0 total (X2)")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_htr_debuffed_jack_no_tick", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_ECON_HTR_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_hit_the_road"):assert()

		local joker = G.jokers.cards[1]
		local jack = T.force_card(1, "S_J")
		jack.debuff = true

		local eval = T.calc(joker, { discard = true, other_card = jack, full_hand = { jack } })
		test:assert_true(eval == nil, "a debuffed Jack must not tick the X mult (vanilla asymmetry)")
		test:assert_eq(joker.ability.x_mult, 1, "debuffed Jacks leave the X mult untouched")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_htr_xmult_resets_end_of_round", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_ECON_HTR_4", 1)
		test:select_blind():assert()
		test:spawn_joker("j_hit_the_road"):assert()

		local joker = G.jokers.cards[1]
		joker.ability.x_mult = 3
		-- Patched branch: signals via the second return, resets through SMODS.reset_card.
		local eval, triggered = T.calc(joker, { end_of_round = true, game_over = false })
		test:assert_true(triggered == true, "the end-of-round reset should report")
		test:assert_eq(joker.ability.x_mult, 1, "the X mult should reset at the end of the round")
	end)

	-- Integration: the discarded Jacks must come back (by object identity) even
	-- when debuffed, while only the normal Jack ticks the X mult.
	BInt.register_test("riosodu/qol_bundle/econ_htr_return_identity_and_debuff_tick", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_ECON_HTR_5", 1)
		test:select_blind():assert()
		test:spawn_joker("j_hit_the_road"):assert()

		local joker = G.jokers.cards[1]
		local jack_ok = T.force_card(1, "S_J")
		local jack_debuff = T.force_card(2, "H_J")
		T.force_card(3, "S_3")
		T.force_card(4, "H_4")
		T.force_card(5, "S_5")
		jack_debuff.debuff = true

		local hand_size = #G.hand.cards
		local cards_before = #G.playing_cards
		test:highlight({ 1, 2, 3, 4, 5 }):assert()
		test:discard():assert()
		BInt._wait.for_condition(function()
			return #G.hand.cards == hand_size
		end, 10, "the hand should refill after the discard")
		BInt._wait.stable_drain()

		test:assert_false(in_area(G.discard, jack_ok), "the normal Jack should not stay in the discard pile")
		test:assert_false(in_area(G.discard, jack_debuff), "the debuffed Jack should also be returned")
		test:assert_true(in_area(G.deck, jack_ok) or in_area(G.hand, jack_ok), "the normal Jack should be in deck or redrawn")
		test:assert_true(in_area(G.deck, jack_debuff) or in_area(G.hand, jack_debuff), "the debuffed Jack should be in deck or redrawn")
		test:assert_eq(joker.ability.x_mult, 1.5, "only the non-debuffed Jack should have ticked the X mult")
		test:assert_eq(#G.playing_cards, cards_before, "the return must not lose or duplicate cards")
	end)

	-- Integration: a second discard in the same round must re-collect and
	-- re-return the fresh Jacks (file-local jacks_to_move reset), with no
	-- duplicated card objects sliding into the registry.
	BInt.register_test("riosodu/qol_bundle/econ_htr_second_discard_re_returns", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_ECON_HTR_6", 1)
		test:select_blind():assert()
		test:spawn_joker("j_hit_the_road"):assert()

		local joker = G.jokers.cards[1]
		local hand_size = #G.hand.cards
		local cards_before = #G.playing_cards
		local suits = { "S", "H", "D", "C" }

		local function jackify_hand()
			for i, card in ipairs(G.hand.cards) do
				card:set_base(G.P_CARDS[suits[(i - 1) % 4 + 1] .. "_J"])
			end
		end

		local function discard_five()
			jackify_hand()
			local highlighted = {}
			for i = 1, 5 do
				highlighted[i] = G.hand.cards[i]
			end
			test:highlight({ 1, 2, 3, 4, 5 }):assert()
			test:discard():assert()
			BInt._wait.for_condition(function()
				return #G.hand.cards == hand_size
			end, 10, "the hand should refill after the discard")
			BInt._wait.stable_drain()
			return highlighted
		end

		local first_jacks = discard_five()
		test:assert_eq(joker.ability.x_mult, 3.5, "five Jacks should have ticked X2.5 on the first discard")

		local second_jacks = discard_five()
		test:assert_eq(joker.ability.x_mult, 6, "five more Jacks should tick X2.5 on the second discard")

		for i, jack in ipairs(second_jacks) do
			test:assert_false(in_area(G.discard, jack), "second-discard Jack #" .. i .. " should be returned to the deck")
		end
		local duplicates, seen_count = area_invariants()
		test:assert_eq(duplicates, 0, "no card object may appear in two areas")
		test:assert_eq(seen_count, cards_before, "every registered card must live in exactly one area (no dupes/losses)")
		test:assert_eq(#G.playing_cards, cards_before, "the registry must not change size")
		test:assert_false(first_jacks[1] == second_jacks[1], "the tests must track distinct physical Jacks across discards")
	end)

	-- === Castle ===========================================================

	BInt.register_test("riosodu/qol_bundle/econ_castle_reset_group_follows_pick", function(test)
		T.start_run(test, "QOL_ECON_CASTLE_1", 1)

		-- Build the same eligible list reset_castle_card uses, then mock the
		-- pick as an index into it (BInt mocks return _t[key]).
		local eligible = {}
		for _, card in ipairs(G.playing_cards) do
			if not SMODS.has_no_suit(card) then
				eligible[#eligible + 1] = card
			end
		end
		local spade_idx, heart_idx
		for i, card in ipairs(eligible) do
			if not spade_idx and card.base.suit == "Spades" then spade_idx = i end
			if not heart_idx and card.base.suit == "Hearts" then heart_idx = i end
		end
		test:assert_true(spade_idx ~= nil and heart_idx ~= nil, "the run seed should hold Spades and Hearts")

		test:mock("pseudorandom_element", spade_idx)
		reset_castle_card()
		test:assert_eq(G.GAME.current_round.castle_card.suit, "Spades", "the suit should follow the picked card")
		test:assert_eq(G.GAME.current_round.castle_card_group, "dark", "a Spade pick should choose the dark group")

		test:mock("pseudorandom_element", heart_idx)
		reset_castle_card()
		test:assert_eq(G.GAME.current_round.castle_card.suit, "Hearts", "the suit should follow the second pick")
		test:assert_eq(G.GAME.current_round.castle_card_group, "light", "a Heart pick should choose the light group")
		test:clear_all_mocks()
	end)

	BInt.register_test("riosodu/qol_bundle/econ_castle_matching_shade_gain", function(test)
		T.apply_feature("castle_checkered_enabled", "j_castle", F.get_ownership_joker_castle)
		T.start_run(test, "QOL_ECON_CASTLE_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_castle"):assert()

		local castle = G.jokers.cards[1]
		-- Group is dark but the vanilla single-suit fallback is Spades: a Club
		-- can only gain through the shade logic.
		G.GAME.current_round.castle_card_group = "dark"
		G.GAME.current_round.castle_card.suit = "Spades"
		castle.ability.extra.chips = 0

		local club = T.force_card(1, "C_2")
		local eval = T.calc(castle, { discard = true, other_card = club, full_hand = { club } })
		test:assert_true(eval ~= nil, "a dark-shade discard should trigger Castle")
		test:assert_eq(castle.ability.extra.chips, 3, "Castle should gain its vanilla chip_mod (+3)")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_castle_off_shade_no_gain", function(test)
		T.apply_feature("castle_checkered_enabled", "j_castle", F.get_ownership_joker_castle)
		T.start_run(test, "QOL_ECON_CASTLE_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_castle"):assert()

		local castle = G.jokers.cards[1]
		G.GAME.current_round.castle_card_group = "dark"
		G.GAME.current_round.castle_card.suit = "Spades"
		castle.ability.extra.chips = 6

		local heart = T.force_card(1, "H_2")
		local eval = T.calc(castle, { discard = true, other_card = heart, full_hand = { heart } })
		test:assert_true(eval == nil, "an off-shade discard should not trigger Castle")
		test:assert_eq(castle.ability.extra.chips, 6, "off-shade discards must not change Castle chips")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_castle_disabled_reset_keeps_group_nil", function(test)
		T.start_run(test, "QOL_ECON_CASTLE_4", 1)
		G.GAME.current_round.castle_card_group = nil
		QOL_BUNDLE.config.castle_checkered_enabled = false

		reset_castle_card()
		test:assert_true(G.GAME.current_round.castle_card_group == nil, "the disabled override must not set a group")
		test:assert_true(G.GAME.current_round.castle_card.suit ~= nil, "the original reset should still pick a suit")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_castle_checkered_deck_group", function(test)
		-- The back selection carries over between runs: G:start_run falls back to
		-- the old G.GAME.selected_back center when viewed_back is nil, so capture
		-- its key and restore it at the end or every later test would silently
		-- run on the Checkered Deck. (selected_back_key is a center OBJECT.)
		local prev_center = G.GAME and G.GAME.selected_back_key
		local prev_back = (type(prev_center) == "table" and prev_center.key) or "b_red"
		T.start_run(test, "QOL_ECON_CASTLE_5", 1, "b_checkered")

		local only_checkered = true
		for _, card in ipairs(G.playing_cards) do
			local suit = card.base.suit
			if suit ~= "Spades" and suit ~= "Hearts" then
				only_checkered = false
			end
		end
		test:assert_true(only_checkered, "the Checkered Deck should only contain Spades and Hearts")

		reset_castle_card()
		local suit = G.GAME.current_round.castle_card.suit
		test:assert_true(suit == "Spades" or suit == "Hearts", "the picked suit should be a checkered suit")
		local expected = (suit == "Hearts") and "light" or "dark"
		test:assert_eq(G.GAME.current_round.castle_card_group, expected, "the group should follow the picked suit shade")

		T.start_run(test, "QOL_ECON_CASTLE_5R", 1, prev_back)
		test:log("castle checkered restored back: "
			.. tostring(G.GAME and G.GAME.selected_back_key and G.GAME.selected_back_key.key))
	end)

	-- === Marble ===========================================================

	BInt.register_test("riosodu/qol_bundle/econ_marble_added_stone_ticks", function(test)
		T.apply_feature("marble_joker_xchips_enabled", "j_marble", F.get_ownership_joker_marble)
		T.start_run(test, "QOL_ECON_MARBLE_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_marble"):assert()

		local marble = G.jokers.cards[1]
		local stone = G.hand.cards[1]
		stone:set_ability(G.P_CENTERS.m_stone)
		test:assert_true(math.abs(marble.ability.extra.xchips - 1) < 1e-9, "X Chips should start at 1")

		local eval = T.calc(marble, { playing_card_added = true, cards = { stone } })
		test:assert_true(eval ~= nil, "adding a Stone card should tick Marble")
		test:assert_true(math.abs(marble.ability.extra.xchips - 1.1) < 1e-9, "one Stone card should give X0.1 Chips")

		local stone2 = G.hand.cards[2]
		stone2:set_ability(G.P_CENTERS.m_stone)
		T.calc(marble, { playing_card_added = true, cards = { stone, stone2 } })
		test:assert_true(math.abs(marble.ability.extra.xchips - 1.3) < 1e-9,
			"re-counting the Stone plus a new one should add X0.2 (total X1.3)")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_marble_non_stone_adds_no_tick", function(test)
		T.apply_feature("marble_joker_xchips_enabled", "j_marble", F.get_ownership_joker_marble)
		T.start_run(test, "QOL_ECON_MARBLE_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_marble"):assert()

		local marble = G.jokers.cards[1]
		marble.ability.extra.xchips = 1.2
		local base_card = G.hand.cards[3]

		local eval = T.calc(marble, { playing_card_added = true, cards = { base_card } })
		test:assert_true(eval ~= nil and next(eval) == nil, "a non-Stone add should return an empty table")
		test:assert_true(math.abs(marble.ability.extra.xchips - 1.2) < 1e-9, "non-Stone adds must not tick")

		-- Defensive: the vanilla creation shape reports {true} (a marker, not a
		-- card object). SMods patches the caller to pass the real card, but the
		-- rework must filter the marker either way.
		local marker = T.calc(marble, { playing_card_added = true, cards = { true } })
		test:assert_true(marker ~= nil and next(marker) == nil, "the {true} marker should return an empty table")
		test:assert_true(math.abs(marble.ability.extra.xchips - 1.2) < 1e-9, "the {true} marker must not tick")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_marble_joker_main_xchips", function(test)
		T.apply_feature("marble_joker_xchips_enabled", "j_marble", F.get_ownership_joker_marble)
		T.start_run(test, "QOL_ECON_MARBLE_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_marble"):assert()

		local marble = G.jokers.cards[1]
		marble.ability.extra.xchips = 1.3
		local eval = T.calc(marble, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil and eval.x_chips ~= nil, "X Chips above 1 should be granted at scoring")
		test:assert_true(math.abs(eval.x_chips - 1.3) < 1e-9, "X Chips contribution should match the accumulated value")

		marble.ability.extra.xchips = 1
		local eval_base = T.calc(marble, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval_base ~= nil and next(eval_base) == nil, "at X1 the Joker should return an empty table")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_marble_blind_stone_preserved", function(test)
		T.apply_feature("marble_joker_xchips_enabled", "j_marble", F.get_ownership_joker_marble)
		T.start_run(test, "QOL_ECON_MARBLE_4", 1)
		local before = #G.playing_cards
		test:spawn_joker("j_marble"):assert()
		local marble = G.jokers.cards[1]

		test:select_blind():assert()
		BInt._wait.for_condition(function()
			for _, card in ipairs(G.playing_cards) do
				if card.config.center.key == "m_stone" then
					return true
				end
			end
			return false
		end, 10, "Marble should still create a Stone card on blind selection")
		BInt._wait.stable_drain()

		test:assert_eq(#G.playing_cards, before + 1, "exactly one Stone card should be added")
		-- Empirical: the SMods-patched creation path fires playing_card_joker_effects
		-- with the real Stone card, so the rework ticks exactly once (X1 -> X1.1).
		test:log("marble xchips after blind stone: " .. tostring(marble.ability.extra.xchips))
		test:assert_true(math.abs(marble.ability.extra.xchips - 1.1) < 1e-9, "the blind-created Stone should tick once (X0.1)")
	end)

	-- === Stone ============================================================

	BInt.register_test("riosodu/qol_bundle/econ_stone_config_and_loc_vars", function(test)
		local g = T.apply_feature("stone_joker_mult_enabled", "j_stone", F.get_ownership_joker_stone)
		test:assert_eq(g.config.extra, 4, "Stone Joker should grant +4 Mult per Stone card")
		local lv = g.loc_vars(nil, {}, { ability = { extra = 4, stone_tally = 2 } })
		test:assert_eq(lv.vars[1], 4, "loc var #1 should be the per-Stone amount")
		test:assert_eq(lv.vars[2], 8, "loc var #2 should be the current total")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_stone_joker_main_mult", function(test)
		T.apply_feature("stone_joker_mult_enabled", "j_stone", F.get_ownership_joker_stone)
		T.start_run(test, "QOL_ECON_STONE_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_stone"):assert()

		local stone = G.jokers.cards[1]
		stone.ability.stone_tally = 3
		local eval = T.calc(stone, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil, "with Stones in the deck the Joker should contribute")
		test:assert_eq(eval.mult_mod, 12, "3 Stone cards * 4 Mult should be +12 Mult")
		test:assert_true(eval.chip_mod == nil, "the rework should grant Mult, not Chips")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_stone_no_stones_empty", function(test)
		T.apply_feature("stone_joker_mult_enabled", "j_stone", F.get_ownership_joker_stone)
		T.start_run(test, "QOL_ECON_STONE_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_stone"):assert()

		local stone = G.jokers.cards[1]
		stone.ability.stone_tally = 0
		local eval = T.calc(stone, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil and next(eval) == nil, "no Stones should return an empty table")
		test:assert_true(eval.mult_mod == nil, "no Stones should not grant Mult")
	end)

	-- === Steel ============================================================

	BInt.register_test("riosodu/qol_bundle/econ_steel_config_extra", function(test)
		local g = T.apply_feature("steel_joker_enabled", "j_steel_joker", F.get_ownership_joker_steel)
		test:assert_eq(g.config.extra, 0.25, "Steel Joker should give X0.25 per Steel Card")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_steel_joker_main_xmult", function(test)
		T.apply_feature("steel_joker_enabled", "j_steel_joker", F.get_ownership_joker_steel)
		T.start_run(test, "QOL_ECON_STEEL_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_steel_joker"):assert()

		local steel = G.jokers.cards[1]
		steel.ability.steel_tally = 4
		local eval = T.calc(steel, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil and eval.Xmult_mod ~= nil, "with Steel Cards the Joker should contribute")
		test:assert_true(math.abs(eval.Xmult_mod - 2) < 1e-9, "1 + 0.25 * 4 Steel Cards should be X2")
	end)

	BInt.register_test("riosodu/qol_bundle/econ_steel_edition_does_not_change_math", function(test)
		T.apply_feature("steel_joker_enabled", "j_steel_joker", F.get_ownership_joker_steel)
		T.start_run(test, "QOL_ECON_STEEL_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_steel_joker"):assert()

		local steel = G.jokers.cards[1]
		steel.ability.steel_tally = 4
		test:set_joker_edition(1, "foil"):assert()

		local eval = T.calc(steel, { joker_main = true, cardarea = G.jokers })
		test:assert_true(eval ~= nil and eval.Xmult_mod ~= nil, "a foil Steel Joker should still contribute")
		test:assert_true(math.abs(eval.Xmult_mod - 2) < 1e-9, "the foil edition must not change the Steel X mult")
	end)
end
