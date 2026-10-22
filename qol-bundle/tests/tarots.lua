-- qol-bundle/tests/tarots.lua
-- Tarot reworks (beta, default off): The Lovers enhances up to two selected
-- cards, and Strength requires two cards and equalizes their ranks.

return function(T)
	local F = QOL_BUNDLE.funcs

	local function lovers_setup(test, seed)
		T.apply_feature("lovers_two_cards_enabled", "c_lovers", F.get_ownership_tarot_lovers)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_consumable("c_lovers"):assert()
	end

	BInt.register_test("riosodu/qol_bundle/beta_lovers_two_cards_config", function(test)
		lovers_setup(test, "QOL_BETA_LOVERS_1")
		test:assert_eq(G.P_CENTERS.c_lovers.config.max_highlighted, 2,
			"The Lovers should allow two highlighted cards")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_lovers_enhances_two_cards", function(test)
		lovers_setup(test, "QOL_BETA_LOVERS_2")
		local first = T.force_card(1, "S_7")
		local second = T.force_card(2, "H_2")

		test:highlight({ 1, 2 }):assert()
		test:use_consumable("c_lovers"):assert()
		BInt._wait.for_condition(function()
			return first.config.center.key == 'm_wild' and second.config.center.key == 'm_wild'
		end, 10, "both selected cards should become Wild Cards")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_lovers_single_card_still_works", function(test)
		lovers_setup(test, "QOL_BETA_LOVERS_3")
		local first = T.force_card(1, "S_7")

		test:highlight({ 1 }):assert()
		test:use_consumable("c_lovers"):assert()
		BInt._wait.for_condition(function()
			return first.config.center.key == 'm_wild'
		end, 10, "a single selected card should still become a Wild Card")
	end)

	-- === Strength (two-card rank equalization, default off) ================

	local function strength_setup(test, seed)
		T.apply_feature("strength_two_cards_enabled", "c_strength", F.get_ownership_tarot_strength)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_consumable("c_strength"):assert()
	end

	BInt.register_test("riosodu/qol_bundle/beta_strength_two_cards_config", function(test)
		test:assert_false(QOL_BUNDLE.config.strength_two_cards_enabled,
			"the Strength rework should default to off")
		strength_setup(test, "QOL_BETA_STR_0")
		test:assert_eq(G.P_CENTERS.c_strength.config.max_highlighted, 2,
			"Strength should allow exactly two highlighted cards")
		test:assert_eq(G.P_CENTERS.c_strength.config.min_highlighted, 2,
			"Strength should require two highlighted cards")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_strength_raises_lower_rank", function(test)
		strength_setup(test, "QOL_BETA_STR_1")
		local low = T.force_card(1, "S_7")
		local high = T.force_card(2, "H_K")
		local high_value = high.base.value

		test:highlight({ 1, 2 }):assert()
		test:use_consumable("c_strength"):assert()
		BInt._wait.for_condition(function()
			return low.base.value == high_value
		end, 10, "the lower rank card should rise to the higher rank")
		test:assert_eq(low.base.suit, "Spades", "the lower card should keep its suit")
		test:assert_eq(high.base.value, high_value, "the higher card should not change")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_strength_ace_is_highest", function(test)
		strength_setup(test, "QOL_BETA_STR_2")
		local low = T.force_card(1, "S_2")
		local high = T.force_card(2, "H_A")

		test:highlight({ 1, 2 }):assert()
		test:use_consumable("c_strength"):assert()
		BInt._wait.for_condition(function()
			return low.base.value == "Ace"
		end, 10, "a 2 should rise to an Ace")
		test:assert_eq(high.base.value, "Ace", "the Ace should not change")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_strength_requires_two_selected", function(test)
		strength_setup(test, "QOL_BETA_STR_3")
		local strength = G.consumeables.cards[1]
		T.force_card(1, "S_7")

		test:highlight({ 1 }):assert()
		test:assert_false(strength:can_use_consumeable(),
			"Strength should not be usable with one selected card")

		T.force_card(2, "H_K")
		test:highlight({ 1, 2 }):assert()
		test:assert_true(strength:can_use_consumeable(),
			"Strength should be usable with two selected cards")
	end)
end
