-- rebalanced-stakes/tests/win_ante.lua
-- Gold stake raises the final ante from 8 to 9. Winning the Ante 8 boss must
-- not finish the run at gold, while the Ante 9 boss must.

return function(T)
	BInt.register_test("riosodu/rebalanced_stakes/gold_does_not_win_at_ante_8", function(test)
		T.start_run_at_stake(test, "RST_WIN_8", 8)
		test:assert_eq(G.GAME.win_ante, 9, "gold stake should require ante 9")
		test:skip_to(8, "boss"):assert()
		test:select_blind():assert()
		T.win_round(test)
		test:assert_false(G.GAME.won == true, "beating the Ante 8 boss must not win a gold run")
	end)

	BInt.register_test("riosodu/rebalanced_stakes/gold_wins_at_ante_9", function(test)
		T.start_run_at_stake(test, "RST_WIN_9", 8)
		test:skip_to(9, "boss"):assert()
		test:select_blind():assert()
		T.win_round(test)
		test:assert_true(G.GAME.won == true, "beating the Ante 9 boss should win a gold run")
	end)

	-- Regression: the default final ante is untouched at lower stakes.
	BInt.register_test("riosodu/rebalanced_stakes/base_stake_wins_at_ante_8", function(test)
		T.start_run_at_stake(test, "RST_WIN_WHITE", 1)
		test:assert_eq(G.GAME.win_ante, 8, "base stakes should still require ante 8")
		test:skip_to(8, "boss"):assert()
		test:select_blind():assert()
		T.win_round(test)
		test:assert_true(G.GAME.won == true, "white stake should still win at Ante 8")
	end)
end
