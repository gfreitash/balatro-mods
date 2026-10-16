-- rebalanced-stakes/tests/stakes.lua
-- Stake modifier tests. The mod takes ownership of Blue, Orange and Gold; the
-- other stakes must keep their vanilla modifiers. Stakes are cumulative
-- (SMODS.setup_stake applies the whole chain), so blue's perishable change
-- carries into every later stake while orange/gold only ADD their own change.

return function(T)
	local function flag(key)
		return G.GAME.modifiers[key]
	end

	-- White Stake: untouched baseline.
	BInt.register_test("riosodu/rebalanced_stakes/white_baseline", function(test)
		T.start_run_at_stake(test, "RST_WHITE_1", 1)
		test:assert_false(flag("enable_perishables_in_shop"), "white: no perishables")
		test:assert_false(flag("enable_rentals_in_shop"), "white: no rentals")
		test:assert_false(flag("enable_eternals_in_shop"), "white: no eternals")
		test:assert_eq(G.GAME.interest_base, 5, "white: base $5 interest")
		test:assert_eq(G.GAME.interest_cap, 25, "white: interest cap 25")
		test:assert_eq(G.GAME.win_ante, 8, "white: final ante 8")
	end)

	-- Red Stake keeps its vanilla modifier.
	BInt.register_test("riosodu/rebalanced_stakes/red_no_small_blind_reward", function(test)
		T.start_run_at_stake(test, "RST_RED_1", 2)
		test:assert_true(
			G.GAME.modifiers.no_blind_reward and G.GAME.modifiers.no_blind_reward.Small == true,
			"red: small blind gives no reward money"
		)
	end)

	-- Black Stake keeps eternal Jokers and must NOT inherit the durability
	-- stickers the mod moves around.
	BInt.register_test("riosodu/rebalanced_stakes/black_eternals_only", function(test)
		T.start_run_at_stake(test, "RST_BLACK_1", 4)
		test:assert_true(flag("enable_eternals_in_shop"), "black: eternals enabled")
		test:assert_false(flag("enable_perishables_in_shop"), "black: no perishables yet")
		test:assert_false(flag("enable_rentals_in_shop"), "black: no rentals yet")
	end)

	-- Blue Stake: the mod removes the -1 Discard penalty and moves the
	-- Perishable shop restriction down to this stake instead.
	BInt.register_test("riosodu/rebalanced_stakes/blue_perishables_no_discard_penalty", function(test)
		T.start_run_at_stake(test, "RST_BLUE_BASE_1", 1)
		local base_discards = G.GAME.starting_params.discards

		T.start_run_at_stake(test, "RST_BLUE_BASE_2", 5)
		test:assert_eq(
			G.GAME.starting_params.discards,
			base_discards,
			"blue must no longer remove a discard"
		)
		test:assert_true(flag("enable_perishables_in_shop"), "blue: perishables enabled")
		test:assert_false(flag("enable_rentals_in_shop"), "blue: rentals are not enabled yet")
		test:assert_true(flag("enable_eternals_in_shop"), "blue: inherits eternals from black")
	end)

	-- Purple Stake keeps its vanilla scaling modifier and inherits blue's
	-- perishable change.
	BInt.register_test("riosodu/rebalanced_stakes/purple_scaling_inherits_perishables", function(test)
		T.start_run_at_stake(test, "RST_PURPLE_1", 6)
		test:assert_eq(G.GAME.modifiers.scaling, 3, "purple: scaling reaches 3")
		test:assert_true(flag("enable_perishables_in_shop"), "purple: inherits perishables")
		test:assert_false(flag("enable_rentals_in_shop"), "purple: no rentals")
	end)

	-- Orange Stake: rentals move down from gold; perishables keep applying
	-- (cumulative stake chains).
	BInt.register_test("riosodu/rebalanced_stakes/orange_rentals_inherits_perishables", function(test)
		T.start_run_at_stake(test, "RST_ORANGE_1", 7)
		test:assert_true(flag("enable_rentals_in_shop"), "orange: rentals enabled")
		test:assert_true(flag("enable_perishables_in_shop"), "orange: inherits perishables")
		test:assert_eq(G.GAME.modifiers.scaling, 3, "orange: keeps purple scaling")
	end)

	-- Gold Stake: economy rework on top of everything from the previous stakes.
	BInt.register_test("riosodu/rebalanced_stakes/gold_economy_and_inheritance", function(test)
		T.start_run_at_stake(test, "RST_GOLD_1", 8)
		test:assert_eq(G.GAME.interest_base, 6, "gold: interest requires $6")
		test:assert_eq(G.GAME.interest_cap, 30, "gold: interest cap is 30")
		test:assert_eq(G.GAME.win_ante, 9, "gold: final ante is 9")
		test:assert_true(flag("enable_perishables_in_shop"), "gold: inherits perishables from blue")
		test:assert_true(flag("enable_rentals_in_shop"), "gold: inherits rentals from orange")
		test:assert_true(flag("enable_eternals_in_shop"), "gold: inherits eternals from black")
		test:assert_eq(#G.GAME.applied_stakes, 8, "gold: all eight stakes apply")
	end)
end
