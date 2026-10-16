-- black-seal/tests/core.lua
-- Core effect tests: proc conditions, target selection, seal consumption scope.

return function(T)
	local SEAL = T.SEAL

	-- Playing a single Black Sealed card with an eligible Joker: the Joker gains
	-- Negative and the played seal is consumed.
	BInt.register_test("riosodu/black_seal/solo_proc_grants_negative", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_NEG_1" })
		test:select_blind()
		test:spawn_joker("j_joker")

		test:set_seal(1, SEAL):assert()
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 1, "one Black Seal before playing")

		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 1, "the Joker should gain Negative")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 0, "played Black Seal should be consumed")
	end)

	-- The effect requires the sealed card to be the only card played.
	BInt.register_test("riosodu/black_seal/no_proc_when_playing_multiple_cards", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_MULTI_1" })
		test:select_blind()
		test:spawn_joker("j_joker")

		test:set_seal(1, SEAL):assert()
		test:highlight({ 1, 2 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 0, "no Negative should be granted")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 1, "Black Seal should not be consumed")
	end)

	-- Without any eligible Joker the effect cannot apply and the safeguard keeps
	-- the seal (it is not wasted).
	BInt.register_test("riosodu/black_seal/no_eligible_joker_preserves_seal", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_NOJOKER_1" })
		test:select_blind()

		test:set_seal(1, SEAL):assert()
		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 1, "Black Seal should be preserved without eligible Jokers")
	end)

	-- Jokers that already have an edition are not eligible targets.
	BInt.register_test("riosodu/black_seal/editioned_joker_not_eligible", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_EDITION_1" })
		test:select_blind()
		test:spawn_joker("j_joker")
		test:set_joker_edition(1, "foil"):assert()

		test:set_seal(1, SEAL):assert()
		test:highlight({ 1 })
		test:play_hand():assert()

		local jokers = test:get_jokers()
		test:assert_eq(jokers[1].edition and jokers[1].edition.foil, true, "existing Foil edition should remain")
		test:assert_eq(T.negative_joker_count(test), 0, "no Negative should be added")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 1, "Black Seal should be preserved")
	end)

	-- Exactly one Joker is targeted even when several are eligible.
	BInt.register_test("riosodu/black_seal/solo_proc_targets_exactly_one_of_many_jokers", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_MANY_1" })
		test:select_blind()
		test:spawn_joker("j_joker")
		test:spawn_joker("j_joker")
		test:spawn_joker("j_joker")

		test:set_seal(1, SEAL):assert()
		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 1, "exactly one of three Jokers should gain Negative")
	end)

	-- The proc removes Black Seals everywhere they can live outside the hand,
	-- including other cards still sitting in the deck.
	BInt.register_test("riosodu/black_seal/proc_removes_deck_and_played_seals", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_DECK_1" })
		test:select_blind()
		test:spawn_joker("j_joker")

		test:assert_true(T.seal_deck_card() ~= nil, "expected a card in the deck to seal")
		test:set_seal(1, SEAL):assert()
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 2, "two Black Seals before playing (deck + hand)")

		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 0, "deck and played Black Seals should both be removed")
	end)

	-- keep_seals_in_hand = true: seals on other cards still in hand survive.
	BInt.register_test("riosodu/black_seal/hand_seals_kept_when_keep_enabled", function(test)
		T.prep_run({ keep_seals_in_hand = true })
		test:start_run({ seed = "BSM_KEEP_1" })
		test:select_blind()
		test:spawn_joker("j_joker")

		test:set_seal(1, SEAL):assert()
		test:set_seal(2, SEAL):assert()
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 2, "two Black Seals before playing")

		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.count_seals(test:get_hand(), SEAL), 1, "the unplayed hand seal should be kept")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 1, "only the played seal should be consumed")
	end)

	-- keep_seals_in_hand = false: every Black Seal is removed, hand included.
	BInt.register_test("riosodu/black_seal/hand_seals_removed_when_keep_disabled", function(test)
		T.prep_run({ keep_seals_in_hand = false })
		test:start_run({ seed = "BSM_KEEP_OFF_1" })
		test:select_blind()
		test:spawn_joker("j_joker")

		test:set_seal(1, SEAL):assert()
		test:set_seal(2, SEAL):assert()
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 2, "two Black Seals before playing")

		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 0, "all Black Seals should be removed")
	end)

	-- A debuffed card does not trigger the effect and its seal is preserved.
	BInt.register_test("riosodu/black_seal/debuffed_card_does_not_proc", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_DEBUFF_1" })
		test:select_blind()
		test:spawn_joker("j_joker")

		test:set_seal(1, SEAL):assert()
		-- Boss suit debuffs only affect specific suits; this test only cares
		-- about the seal's debuff guard, so force the flag directly.
		G.hand.cards[1]:set_debuff(true)
		test:assert_true(G.hand.cards[1].debuff, "card should be debuffed before playing")

		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 0, "no Negative should be granted by a debuffed card")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 1, "Black Seal should be preserved")
	end)

	-- Control: a solo card without a Black Seal changes nothing.
	BInt.register_test("riosodu/black_seal/solo_unsealed_card_no_proc", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_PLAIN_1" })
		test:select_blind()
		test:spawn_joker("j_joker")

		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 0, "no Negative without a Black Seal")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 0, "no seals involved")
	end)

	-- Jokers are only eligible while they have no edition: if every Joker is
	-- already Negative, the effect cannot apply and the seal is not consumed.
	BInt.register_test("riosodu/black_seal/all_jokers_already_negative_preserves_seal", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_NEGONLY_1" })
		test:select_blind()
		test:spawn_joker("j_joker")
		test:spawn_joker("j_joker")
		test:set_joker_edition(1, "negative"):assert()
		test:set_joker_edition(2, "negative"):assert()

		test:set_seal(1, SEAL):assert()
		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 2, "no additional Negative should be added")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 1, "Black Seal should be preserved when no eligible Joker exists")
	end)
end
