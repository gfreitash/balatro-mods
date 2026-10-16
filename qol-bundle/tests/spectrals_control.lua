-- qol-bundle/tests/spectrals_control.lua
-- Controlled Sigil/Ouija: with the feature enabled the spectral converts the
-- whole hand using the single highlighted card as reference (suit for Sigil,
-- rank for Ouija) and can only be used with exactly one card highlighted.
-- With the feature disabled the vanilla random path must run instead.
-- The disabled path is mockable via pseudorandom_element (SMODS.Suits/Ranks
-- are name-keyed, so the mock can queue a suit/rank name).

return function(T)
	local F = QOL_BUNDLE.funcs

	local function sigil_setup(test, seed)
		T.apply_feature("sigil_control_enabled", "c_sigil", F.get_ownership_spectral_sigil)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_consumable("c_sigil"):assert()
		return G.consumeables.cards[1]
	end

	local function ouija_setup(test, seed)
		T.apply_feature("ouija_control_enabled", "c_ouija", F.get_ownership_spectral_ouija)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_consumable("c_ouija"):assert()
		return G.consumeables.cards[1]
	end

	local function hand_all(pred)
		for _, c in ipairs(G.hand.cards) do
			if not pred(c) then
				return false
			end
		end
		return true
	end

	-- === Sigil ============================================================

	BInt.register_test("riosodu/qol_bundle/spec_control_sigil_config_and_gate", function(test)
		local sigil = sigil_setup(test, "QOL_SPC_SIG_1")
		test:assert_eq(G.P_CENTERS.c_sigil.config.max_highlighted, 1, "Sigil should allow one highlighted card")

		test:assert_false(sigil:can_use_consumeable(), "zero highlighted cards should block the controlled Sigil")
		test:highlight({ 1, 2 }):assert()
		test:assert_false(sigil:can_use_consumeable(), "two highlighted cards should block the controlled Sigil")
		test:highlight({ 1 }):assert()
		test:assert_true(sigil:can_use_consumeable(), "exactly one highlighted card should enable the Sigil")
	end)

	BInt.register_test("riosodu/qol_bundle/spec_control_sigil_controlled_conversion", function(test)
		local sigil = sigil_setup(test, "QOL_SPC_SIG_2")
		T.force_card(1, "S_7")
		T.force_card(2, "H_2")
		T.force_card(3, "D_3")

		local ranks = {}
		for i, c in ipairs(G.hand.cards) do
			ranks[i] = c.base.value
		end

		test:highlight({ 1 }):assert()
		test:use_consumable("c_sigil"):assert()
		BInt._wait.for_condition(function()
			return hand_all(function(c) return c.base.suit == "Spades" end)
		end, 10, "Sigil should convert the whole hand to the reference suit")

		for i, c in ipairs(G.hand.cards) do
			test:assert_eq(c.base.value, ranks[i], "card #" .. i .. " should keep its rank")
		end
	end)

	BInt.register_test("riosodu/qol_bundle/spec_control_sigil_wild_reference", function(test)
		local sigil = sigil_setup(test, "QOL_SPC_SIG_3")
		local reference = T.force_card(1, "S_7")
		reference:set_ability(G.P_CENTERS.m_wild)

		test:highlight({ 1 }):assert()
		test:use_consumable("c_sigil"):assert()
		BInt._wait.for_condition(function()
			return hand_all(function(c) return c.base.suit == "Spades" end)
		end, 10, "a Wild reference should still convert to its printed base suit")
		test:assert_eq(reference.base.suit, "Spades", "the Wild reference keeps its printed suit")
	end)

	BInt.register_test("riosodu/qol_bundle/spec_control_sigil_disabled_vanilla_random", function(test)
		QOL_BUNDLE.config.sigil_control_enabled = false
		T.start_run(test, "QOL_SPC_SIG_4", 1)
		test:select_blind():assert()
		test:spawn_consumable("c_sigil"):assert()

		-- The reference would force Spades; vanilla must pick the mocked suit.
		T.force_card(1, "S_7")
		test:highlight({ 1 }):assert()
		test:mock("pseudorandom_element", "Hearts")
		test:use_consumable("c_sigil"):assert()
		test:clear_all_mocks()

		BInt._wait.for_condition(function()
			return hand_all(function(c) return c.base.suit == "Hearts" end)
		end, 10, "the disabled Sigil should use the vanilla random suit")
		test:assert_eq(G.hand.cards[1].base.suit, "Hearts", "the reference suit must be ignored when disabled")
	end)

	BInt.register_test("riosodu/qol_bundle/spec_control_sigil_disabled_no_single_gate", function(test)
		QOL_BUNDLE.config.sigil_control_enabled = false
		T.start_run(test, "QOL_SPC_SIG_5", 1)
		test:select_blind():assert()
		test:spawn_consumable("c_sigil"):assert()
		local sigil = G.consumeables.cards[1]

		test:assert_true(sigil:can_use_consumeable(), "the vanilla Sigil should allow zero highlighted cards")
		test:highlight({ 1, 2 }):assert()
		test:assert_true(sigil:can_use_consumeable(), "the vanilla Sigil must not enforce the exactly-one gate")
	end)

	-- === Ouija ============================================================

	BInt.register_test("riosodu/qol_bundle/spec_control_ouija_config_and_gate", function(test)
		local ouija = ouija_setup(test, "QOL_SPC_OU_1")
		test:assert_eq(G.P_CENTERS.c_ouija.config.max_highlighted, 1, "Ouija should allow one highlighted card")

		test:assert_false(ouija:can_use_consumeable(), "zero highlighted cards should block the controlled Ouija")
		test:highlight({ 1, 2 }):assert()
		test:assert_false(ouija:can_use_consumeable(), "two highlighted cards should block the controlled Ouija")
		test:highlight({ 1 }):assert()
		test:assert_true(ouija:can_use_consumeable(), "exactly one highlighted card should enable the Ouija")
	end)

	BInt.register_test("riosodu/qol_bundle/spec_control_ouija_controlled_conversion", function(test)
		local ouija = ouija_setup(test, "QOL_SPC_OU_2")
		T.force_card(1, "S_7")
		T.force_card(2, "H_2")
		T.force_card(3, "D_3")

		local suits = {}
		for i, c in ipairs(G.hand.cards) do
			suits[i] = c.base.suit
		end
		local limit_before = G.hand.config.card_limit

		test:highlight({ 1 }):assert()
		test:use_consumable("c_ouija"):assert()
		BInt._wait.for_condition(function()
			return hand_all(function(c) return c.base.value == "7" end)
		end, 10, "Ouija should convert the whole hand to the reference rank")

		for i, c in ipairs(G.hand.cards) do
			test:assert_eq(c.base.suit, suits[i], "card #" .. i .. " should keep its suit")
		end
		test:assert_eq(G.hand.config.card_limit, limit_before - 1, "Ouija should reduce the hand size by one")
	end)

	BInt.register_test("riosodu/qol_bundle/spec_control_ouija_stone_reference", function(test)
		local ouija = ouija_setup(test, "QOL_SPC_OU_3")
		local reference = T.force_card(1, "S_Q")
		reference:set_ability(G.P_CENTERS.m_stone)

		test:highlight({ 1 }):assert()
		test:use_consumable("c_ouija"):assert()
		BInt._wait.for_condition(function()
			return hand_all(function(c) return c.base.value == "Queen" end)
		end, 10, "a Stone reference should still convert to its printed base rank")
		test:assert_eq(reference.base.value, "Queen", "the Stone reference keeps its printed rank")
	end)

	BInt.register_test("riosodu/qol_bundle/spec_control_ouija_disabled_vanilla_random", function(test)
		QOL_BUNDLE.config.ouija_control_enabled = false
		T.start_run(test, "QOL_SPC_OU_4", 1)
		test:select_blind():assert()
		test:spawn_consumable("c_ouija"):assert()

		-- The reference would force rank 7/Jack; vanilla must pick the mocked rank.
		T.force_card(1, "S_7")
		test:highlight({ 1 }):assert()
		test:mock("pseudorandom_element", "Ace")
		test:use_consumable("c_ouija"):assert()
		test:clear_all_mocks()

		BInt._wait.for_condition(function()
			return hand_all(function(c) return c.base.value == "Ace" end)
		end, 10, "the disabled Ouija should use the vanilla random rank")
		test:assert_eq(G.hand.cards[1].base.value, "Ace", "the reference rank must be ignored when disabled")
	end)
end
