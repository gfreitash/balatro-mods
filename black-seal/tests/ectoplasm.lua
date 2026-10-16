-- black-seal/tests/ectoplasm.lua
-- Ectoplasm override tests: override_ectoplasm_effect decides whether Ectoplasm
-- applies a Black Seal to one selected card (plus, unless disabled, the vanilla
-- hand size penalty), or falls back to the vanilla random-Joker Negative.

return function(T)
	local SEAL = T.SEAL

	-- Override enabled: Ectoplasm seals the single highlighted card.
	BInt.register_test("riosodu/black_seal/ectoplasm_override_applies_seal", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_ECTO_SEAL_1" })
		test:select_blind()
		test:spawn_consumable("c_ectoplasm"):assert()

		test:highlight({ 2 })
		test:use_consumable("c_ectoplasm"):assert()

		local hand = test:get_hand()
		test:assert_eq(T.count_seals(hand, SEAL), 1, "exactly one hand card should receive a Black Seal")
		test:assert_eq(hand[2] and hand[2].seal, SEAL, "the selected card should be the sealed one")
	end)

	-- Override + reduction enabled: hand size drops by the ecto_minus counter.
	BInt.register_test("riosodu/black_seal/ectoplasm_override_reduces_hand_when_enabled", function(test)
		T.prep_run({ ectoplasm_override_reduces_hand = true })
		test:start_run({ seed = "BSM_ECTO_HAND_ON_1" })
		test:select_blind()
		test:spawn_consumable("c_ectoplasm"):assert()

		local before = T.hand_limit()
		test:highlight({ 1 })
		test:use_consumable("c_ectoplasm"):assert()

		test:assert_eq(T.hand_limit(), before - 1, "hand size should be reduced by 1")
	end)

	-- Override + reduction disabled: the seal is applied without the penalty.
	BInt.register_test("riosodu/black_seal/ectoplasm_override_reduces_hand_when_disabled", function(test)
		T.prep_run({ ectoplasm_override_reduces_hand = false })
		test:start_run({ seed = "BSM_ECTO_HAND_OFF_1" })
		test:select_blind()
		test:spawn_consumable("c_ectoplasm"):assert()

		local before = T.hand_limit()
		test:highlight({ 1 })
		test:use_consumable("c_ectoplasm"):assert()

		test:assert_eq(T.hand_limit(), before, "hand size should not change")
		test:assert_eq(T.count_seals(test:get_hand(), SEAL), 1, "the seal should still be applied")
	end)

	-- Override disabled: vanilla Ectoplasm (random Joker Negative + hand size).
	BInt.register_test("riosodu/black_seal/ectoplasm_vanilla_when_override_disabled", function(test)
		T.prep_run({ override_ectoplasm_effect = false })
		test:start_run({ seed = "BSM_ECTO_VANILLA_1" })
		test:select_blind()
		test:spawn_joker("j_joker")
		test:spawn_consumable("c_ectoplasm"):assert()

		local before = T.hand_limit()
		-- The center keeps max_highlighted = 1, so vanilla Ectoplasm still
		-- expects exactly one highlighted card.
		test:highlight({ 1 })
		test:use_consumable("c_ectoplasm"):assert()

		test:assert_eq(T.negative_joker_count(test), 1, "vanilla Ectoplasm should grant Negative to the Joker")
		test:assert_eq(T.hand_limit(), before - 1, "vanilla Ectoplasm should reduce hand size")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 0, "no Black Seal should be applied")
	end)

	-- The override requires exactly one highlighted card to be usable.
	BInt.register_test("riosodu/black_seal/ectoplasm_override_requires_single_highlight", function(test)
		T.prep_run()
		test:start_run({ seed = "BSM_ECTO_CANUSE_1" })
		test:select_blind()
		test:spawn_consumable("c_ectoplasm"):assert()

		local card = G.consumeables.cards[1]
		test:assert_true(card ~= nil, "Ectoplasm should be in the consumable area")

		test:highlight({})
		BInt._wait.for_condition(function()
			return #G.hand.highlighted == 0
		end, 5, "Timeout clearing highlights")
		test:assert_false(card:can_use_consumeable(), "should not be usable with 0 highlighted cards")

		test:highlight({ 1, 2 })
		BInt._wait.for_condition(function()
			return #G.hand.highlighted == 2
		end, 5, "Timeout highlighting two cards")
		test:assert_false(card:can_use_consumeable(), "should not be usable with 2 highlighted cards")

		test:highlight({ 1 })
		BInt._wait.for_condition(function()
			return #G.hand.highlighted == 1
		end, 5, "Timeout highlighting exactly one card")
		local usable = card:can_use_consumeable()
		test:assert_true(usable, string.format(
			"should be usable with exactly 1 highlighted card (highlighted=%d mod_num=%s max_highlighted=%s min_highlighted=%s name=%s override=%s state=%s play=%d locked=%s stop_use=%s)",
			#G.hand.highlighted,
			tostring(card.ability.consumeable and card.ability.consumeable.mod_num),
			tostring(card.ability.consumeable and card.ability.consumeable.max_highlighted),
			tostring(card.ability.consumeable and card.ability.consumeable.min_highlighted),
			tostring(card.ability.name),
			tostring(BSM.config.override_ectoplasm_effect),
			tostring(G.STATE),
			G.play and #G.play.cards or -1,
			tostring(G.CONTROLLER.locked),
			tostring(G.GAME.STOP_USE)
		))
	end)

	-- The hand size penalty stacks through G.GAME.ecto_minus across uses.
	BInt.register_test("riosodu/black_seal/ecto_minus_stacks_on_second_use", function(test)
		T.prep_run({ ectoplasm_override_reduces_hand = true })
		test:start_run({ seed = "BSM_ECTO_STACK_1" })
		test:select_blind()
		test:spawn_consumable("c_ectoplasm"):assert()
		test:spawn_consumable("c_ectoplasm"):assert()

		local before = T.hand_limit()
		test:highlight({ 1 })
		test:use_consumable("c_ectoplasm"):assert()
		test:highlight({ 2 })
		test:use_consumable("c_ectoplasm"):assert()

		test:assert_eq(T.hand_limit(), before - 3, "penalties should stack (-1 then -2)")
		test:assert_eq(T.count_seals(test:get_hand(), SEAL), 2, "both selected cards should be sealed")
	end)

	-- [Unreleased]: the Ectoplasm override must survive prototype rebuilds.
	-- The old raw G.P_CENTERS swap silently reverted on
	-- Game:init_item_prototypes(), so a rebuilt prototype table lost the modded
	-- config; take_ownership re-injects it.
	BInt.register_test("riosodu/black_seal/ectoplasm_survives_prototype_rebuild", function(test)
		T.prep_run()
		G:init_item_prototypes()

		test:assert_eq(G.P_CENTERS.c_ectoplasm.config.extra, SEAL,
			"the modded config.extra should survive a prototype rebuild")
		test:assert_eq(G.P_CENTERS.c_ectoplasm.config.max_highlighted, 1,
			"the single-highlight config should survive a prototype rebuild")

		-- The override behavior must also still work after the rebuild.
		test:start_run({ seed = "BSM_ECTO_REBUILD_1" })
		test:select_blind()
		test:spawn_consumable("c_ectoplasm"):assert()
		test:highlight({ 1 })
		test:use_consumable("c_ectoplasm"):assert()
		test:assert_eq(T.count_seals(test:get_hand(), SEAL), 1,
			"the override should still seal after a prototype rebuild")
	end)
end
