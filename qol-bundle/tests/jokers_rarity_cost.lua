-- qol-bundle/tests/jokers_rarity_cost.lua
-- Rarity/cost take_ownership features. Each test re-applies its getter (so it
-- is deterministic regardless of the saved launch config) and asserts both the
-- center fields and, where it matters, the spawned card's base cost.

return function(T)
	local F = QOL_BUNDLE.funcs

	BInt.register_test("riosodu/qol_bundle/rarity_baron", function(test)
		local g = T.apply_feature("baron_uncommon_enabled", "j_baron", F.get_ownership_joker_baron)
		test:assert_eq(g.rarity, 2, "Baron should become Uncommon")
		test:assert_eq(g.cost, 5, "Baron should become cheaper")
	end)

	BInt.register_test("riosodu/qol_bundle/rarity_mime", function(test)
		local g = T.apply_feature("mime_rare_enabled", "j_mime", F.get_ownership_joker_mime)
		test:assert_eq(g.rarity, 3, "Mime should become Rare")
		test:assert_eq(g.cost, 6, "Mime should become more expensive")
	end)

	BInt.register_test("riosodu/qol_bundle/rarity_ceremonial_dagger", function(test)
		local g = T.apply_feature("ceremonial_dagger_common_enabled", "j_ceremonial", F.get_ownership_joker_cerimonial)
		test:assert_eq(g.rarity, 1, "Ceremonial Dagger should become Common")
		test:assert_eq(g.cost, 3, "Ceremonial Dagger should become cheaper")
	end)

	BInt.register_test("riosodu/qol_bundle/rarity_mail_in_rebate", function(test)
		local g = T.apply_feature("mail_in_rebate_uncommon_enabled", "j_mail", F.get_ownership_joker_mail)
		test:assert_eq(g.rarity, 2, "Mail-In Rebate should become Uncommon")
		test:assert_eq(g.cost, 8, "Mail-In Rebate should cost $8")
	end)

	BInt.register_test("riosodu/qol_bundle/rarity_fortune_teller", function(test)
		local g = T.apply_feature("fortune_teller_cheaper_enabled", "j_fortune_teller", F.get_ownership_joker_fortune_teller)
		test:assert_eq(g.cost, 4, "Fortune Teller should become cheaper")
	end)

	BInt.register_test("riosodu/qol_bundle/rarity_hanging_chad", function(test)
		local g = T.apply_feature("nerf_hanging_chad_enabled", "j_hanging_chad", F.get_ownership_joker_hanging_chad)
		test:assert_eq(g.rarity, 2, "Hanging Chad should become Uncommon")
		test:assert_eq(g.cost, 7, "Hanging Chad should cost $7")
	end)

	-- Same take_ownership, but beta (default-off) features: the gating is
	-- covered by loader_default_off_gating; here they are explicitly enabled.
	BInt.register_test("riosodu/qol_bundle/rarity_dna_when_enabled", function(test)
		test:assert_false(QOL_BUNDLE.config.dna_uncommon_enabled, "DNA should default to off")
		local g = T.apply_feature("dna_uncommon_enabled", "j_dna", F.get_ownership_joker_dna)
		test:assert_eq(g.rarity, 2, "DNA should become Uncommon")
		test:assert_eq(g.cost, 6, "DNA should become cheaper")
	end)

	BInt.register_test("riosodu/qol_bundle/rarity_pareidolia_when_enabled", function(test)
		test:assert_false(QOL_BUNDLE.config.pareidolia_common_enabled, "Pareidolia should default to off")
		local g = T.apply_feature("pareidolia_common_enabled", "j_pareidolia", F.get_ownership_joker_pareidolia)
		test:assert_eq(g.rarity, 1, "Pareidolia should become Common")
		test:assert_eq(g.cost, 4, "Pareidolia should become cheaper")
	end)

	-- Spawning a joker copies the (modified) center cost onto the card.
	BInt.register_test("riosodu/qol_bundle/rarity_spawned_cost", function(test)
		T.apply_feature("baron_uncommon_enabled", "j_baron", F.get_ownership_joker_baron)
		T.start_run(test, "QOL_RAR_1", 1)
		test:select_blind():assert()

		test:mock("poll_edition", false)
		test:spawn_joker("j_baron"):assert()
		test:clear_all_mocks()

		test:assert_eq(G.jokers.cards[1].base_cost, 5, "spawned Baron should copy the new base cost")
	end)

	-- The Hanging Chad take_ownership must not alter its retrigger behavior.
	BInt.register_test("riosodu/qol_bundle/rarity_hanging_chad_no_behavior_change", function(test)
		T.apply_feature("nerf_hanging_chad_enabled", "j_hanging_chad", F.get_ownership_joker_hanging_chad)
		T.start_run(test, "QOL_RAR_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_hanging_chad"):assert()

		local card = G.jokers.cards[1]
		local hand = G.hand.cards
		local eval = T.calc(card, {
			repetition = true,
			cardarea = G.play,
			other_card = hand[1],
			scoring_hand = { hand[1], hand[2] },
		})
		test:assert_true(eval ~= nil, "Hanging Chad should still retrigger the first scoring card")
		test:assert_eq(eval.repetitions, 2, "retrigger count should stay vanilla (2)")
	end)
end
