-- black-seal/tests/localization.lua
-- Localization tests: the config toggles swap the displayed descriptions
-- through BSM.utils.update_black_seal_text / update_ectoplasm_text (also
-- exercised indirectly by T.set_config).

return function(T)
	local function black_seal_text()
		return G.localization.descriptions.Other.blac_black_seal.text
	end

	local function ectoplasm_text()
		return G.localization.descriptions.Spectral.c_ectoplasm.text
	end

	BInt.register_test("riosodu/black_seal/black_seal_description_matches_keep_config", function(test)
		T.set_config({ keep_seals_in_hand = true })
		test:assert_true(
			T.loc_contains(black_seal_text(), "not in your hand"),
			"keep=true text should mention seals outside the hand"
		)

		T.set_config({ keep_seals_in_hand = false })
		test:assert_true(
			T.loc_contains(black_seal_text(), "from your deck"),
			"keep=false text should mention removing from the deck"
		)
		test:assert_false(
			T.loc_contains(black_seal_text(), "not in your hand"),
			"keep=false text should not mention hand protection"
		)
	end)

	BInt.register_test("riosodu/black_seal/ectoplasm_description_hand_line_toggles", function(test)
		T.set_config({ override_ectoplasm_effect = true, ectoplasm_override_reduces_hand = true })
		test:assert_true(T.loc_contains(ectoplasm_text(), "hand size"), "override+reduces text should mention hand size")
		test:assert_true(T.loc_contains(ectoplasm_text(), "Black Seal"), "override text should mention the Black Seal")

		T.set_config({ override_ectoplasm_effect = true, ectoplasm_override_reduces_hand = false })
		test:assert_false(T.loc_contains(ectoplasm_text(), "hand size"), "override without reduction should not mention hand size")
		test:assert_true(T.loc_contains(ectoplasm_text(), "Black Seal"), "override text should mention the Black Seal")

		T.set_config({ override_ectoplasm_effect = false })
		test:assert_true(T.loc_contains(ectoplasm_text(), "random"), "vanilla text should mention a random Joker")
		test:assert_false(T.loc_contains(ectoplasm_text(), "Black Seal"), "vanilla text should not mention the Black Seal")
	end)
end
