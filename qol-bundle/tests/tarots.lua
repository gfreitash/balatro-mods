-- qol-bundle/tests/tarots.lua
-- The Lovers rework (beta, default off): it can enhance up to two selected
-- cards into Wild Cards instead of only one.

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
end
