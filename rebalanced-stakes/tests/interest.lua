-- rebalanced-stakes/tests/interest.lua
-- End-of-round interest is reworked by the Lovely patch shipped with the mod
-- (common_interest_rework.toml): interest uses G.GAME.interest_base and the
-- Seed Money / Money Tree caps scale with it. These tests play a real blind
-- and read the round-evaluation total. On a won Small Blind at stake >= 2 the
-- reward is $0 (red stake) and the round is won with the last hand (no unused
-- hands bonus), no jokers and no tags -- so the round total equals the
-- interest exactly.

return function(T)
	-- Non-gold stakes keep vanilla interest math: $1 per $5.
	BInt.register_test("riosodu/rebalanced_stakes/base_stake_interest_matches_vanilla", function(test)
		T.start_run_at_stake(test, "RST_INT_BASE", 2)
		test:assert_eq(G.GAME.interest_base, 5, "base stakes use $5 interest")
		test:select_blind():assert()
		T.win_round(test, 11)
		test:assert_eq(T.round_dollars(test), 2, "$11 should earn $2 interest")
	end)

	-- Gold stake requires $6 per interest dollar: $11 now earns $1 (vanilla
	-- would pay $2). This is the decisive check that the patched interest
	-- calculation is active.
	BInt.register_test("riosodu/rebalanced_stakes/gold_interest_requires_6", function(test)
		T.start_run_at_stake(test, "RST_INT_GOLD1", 8)
		test:assert_eq(G.GAME.interest_base, 6, "gold uses $6 interest")
		test:select_blind():assert()
		T.win_round(test, 11)
		test:assert_eq(T.round_dollars(test), 1, "$11 at $6 interest should earn $1, not $2")
	end)

	-- Gold stake interest cap: $30 -> at most $5 per round.
	BInt.register_test("riosodu/rebalanced_stakes/gold_interest_cap_5", function(test)
		T.start_run_at_stake(test, "RST_INT_GOLD2", 8)
		test:select_blind():assert()
		T.win_round(test, 100)
		test:assert_eq(T.round_dollars(test), 5, "$100 should be capped at $5 interest")
	end)

	-- Seed Money raises the cap to 10 * interest_base = $60 at gold stake,
	-- so up to $10 are earned.
	BInt.register_test("riosodu/rebalanced_stakes/gold_seed_money_cap_60", function(test)
		T.start_run_at_stake(test, "RST_INT_SEED", 8)
		test:select_blind():assert()
		test:spawn_voucher("v_seed_money"):assert()
		BInt._wait.for_condition(function()
			return G.GAME.interest_cap == 60
		end, 10, "Seed Money should scale the cap with the interest base")
		T.win_round(test, 100)
		test:assert_eq(T.round_dollars(test), 10, "Seed Money should cap interest at $10")
	end)

	-- Money Tree stacks on top: cap 20 * interest_base = $120 at gold stake.
	BInt.register_test("riosodu/rebalanced_stakes/gold_money_tree_cap_120", function(test)
		T.start_run_at_stake(test, "RST_INT_TREE", 8)
		test:select_blind():assert()
		test:spawn_voucher("v_seed_money"):assert()
		BInt._wait.for_condition(function()
			return G.GAME.interest_cap == 60
		end, 10, "Seed Money should scale the cap with the interest base")
		test:spawn_voucher("v_money_tree"):assert()
		BInt._wait.for_condition(function()
			return G.GAME.interest_cap == 120
		end, 10, "Money Tree should scale the cap with the interest base")
		T.win_round(test, 130)
		test:assert_eq(T.round_dollars(test), 20, "Money Tree should cap interest at $20")
	end)
end
