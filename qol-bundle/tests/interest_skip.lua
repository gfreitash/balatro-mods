-- qol-bundle/tests/interest_skip.lua
-- "Interest on skip" (`interest_on_skip_enabled`, src/main.lua:9-47): skipping a
-- blind awards round-style interest before vanilla processing. The vanilla
-- handler only advances the blind when a tag is present, so T.manual_skip()
-- (nil tag) isolates the money math exactly.

return function(T)
	local function interest_on()
		QOL_BUNDLE.config.interest_on_skip_enabled = true
		QOL_BUNDLE.funcs.apply_interest_on_skip_override()
	end

	--- Skips without a tag and waits for the expected dollars balance.
	local function manual_skip_expecting(expected)
		T.manual_skip()
		BInt._wait.for_condition(function()
			return G.GAME.dollars == expected
		end, 5, "Timeout waiting for dollars == " .. tostring(expected))
		BInt._wait.stable_drain()
		G.CONTROLLER.locks.skip_blind = nil
	end

	BInt.register_test("riosodu/qol_bundle/interest_basic_rate", function(test)
		interest_on()
		T.start_run(test, "QOL_INT_1", 1)
		local skips_before = G.GAME.skips or 0

		test:set_money(15)
		manual_skip_expecting(18)

		test:assert_eq(G.GAME.skips, skips_before + 1, "the skip itself should still happen")
	end)

	BInt.register_test("riosodu/qol_bundle/interest_cap_25", function(test)
		interest_on()
		T.start_run(test, "QOL_INT_2", 1)

		test:set_money(100)
		-- floor(100/5) = 20 but capped at interest_cap/5 = 5
		manual_skip_expecting(105)
	end)

	BInt.register_test("riosodu/qol_bundle/interest_below_5", function(test)
		interest_on()
		T.start_run(test, "QOL_INT_3", 1)

		test:set_money(4)
		-- floor(4/5) = 0: no interest
		manual_skip_expecting(4)
	end)

	BInt.register_test("riosodu/qol_bundle/interest_debt_guard", function(test)
		interest_on()
		T.start_run(test, "QOL_INT_4", 1)

		test:set_money(0)
		manual_skip_expecting(0)
	end)

	BInt.register_test("riosodu/qol_bundle/interest_no_interest_modifier", function(test)
		interest_on()
		T.start_run(test, "QOL_INT_5", 1)

		test:set_money(20)
		G.GAME.modifiers.no_interest = true
		manual_skip_expecting(20)
		G.GAME.modifiers.no_interest = nil
	end)

	BInt.register_test("riosodu/qol_bundle/interest_runtime_disable", function(test)
		T.start_run(test, "QOL_INT_6", 1)

		QOL_BUNDLE.config.interest_on_skip_enabled = false
		QOL_BUNDLE.funcs.apply_interest_on_skip_override()
		test:assert_true(
			G.FUNCS.skip_blind == QOL_BUNDLE.original.skip_blind,
			"disabling should restore the original skip_blind"
		)

		test:set_money(10)
		manual_skip_expecting(10)

		-- Restore the default-enabled state for the rest of the suite.
		interest_on()
	end)

	BInt.register_test("riosodu/qol_bundle/interest_re_enable_idempotent", function(test)
		T.start_run(test, "QOL_INT_7", 1)

		interest_on()
		interest_on() -- must not double-wrap / double-pay

		test:set_money(10)
		manual_skip_expecting(12)
	end)

	-- Full path through the real BInt skip action (with a staged neutral tag so
	-- no random tag money leaks into the result).
	BInt.register_test("riosodu/qol_bundle/interest_via_action_with_neutral_tag", function(test)
		interest_on()
		T.start_run(test, "QOL_INT_8", 1)

		G.GAME.round_resets.blind_tags[G.GAME.blind_on_deck] = "tag_boss"
		add_tag(Tag("tag_boss"))

		test:set_money(10)
		test:skip_blind():assert()
		BInt._wait.stable_drain()

		test:assert_eq(G.GAME.dollars, 12, "the real skip path should also award interest")
	end)
end
