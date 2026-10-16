-- qol-bundle/tests/jokers_scoring.lua
-- Scoring-phase take_ownership features: Splash (random retrigger picks),
-- 8 Ball (configurable Tarot chance) and Space Joker (configurable level-up
-- chance). Effects are probed through the SMods center-injected calculate path
-- (T.calc) with deterministic mocks/odds; the Space level-up has one real
-- scoring integration check.
--
-- Odds trick: SMODS.pseudorandom_probability multiplies its numerator by
-- G.GAME.probabilities.normal, so normal=100 guarantees the roll and normal=0
-- denies it.

return function(T)
	local F = QOL_BUNDLE.funcs

	-- === Splash ===========================================================

	local function splash_setup(test, seed, num_hand)
		T.apply_feature("splash_joker_retrigger_enabled", "j_splash", F.get_ownership_joker_splash)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_joker("j_splash"):assert()
		local splash = G.jokers.cards[1]
		local hand = {}
		for i = 1, (num_hand or 3) do
			hand[i] = G.hand.cards[i]
		end
		return splash, hand
	end

	BInt.register_test("riosodu/qol_bundle/scoring_splash_calculate_installed", function(test)
		local center = T.apply_feature("splash_joker_retrigger_enabled", "j_splash", F.get_ownership_joker_splash)
		test:assert_true(type(center.calculate) == "function", "the retrigger calculate should be installed")
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_splash_picks_two_distinct", function(test)
		local splash, hand = splash_setup(test, "QOL_SC_SPL_1")
		-- Both mocked indices are 1: the table.remove after the first pick must
		-- make the second pick land on a different card (hand[2], not hand[1]).
		test:mock("pseudorandom", 1)
		test:mock("pseudorandom", 1)
		T.calc(splash, { initial_scoring_step = true, scoring_hand = hand })

		local eval_1 = T.calc(splash, { repetition = true, cardarea = G.play, other_card = hand[1] })
		test:assert_true(eval_1 ~= nil, "the first picked card should retrigger")
		test:assert_eq(eval_1.repetitions, 1, "the retrigger should add exactly one repetition")
		test:assert_eq(eval_1.message, localize('k_again_ex'), "the retrigger should show the Again message")
		test:assert_true(eval_1.card == splash, "the effect should credit the Joker")

		local eval_2 = T.calc(splash, { repetition = true, cardarea = G.play, other_card = hand[2] })
		test:assert_true(eval_2 ~= nil, "the second pick must be a distinct card even with colliding rolls")

		local eval_3 = T.calc(splash, { repetition = true, cardarea = G.play, other_card = hand[3] })
		test:assert_true(eval_3 == nil, "cards that were not picked must not retrigger")
		test:clear_all_mocks()
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_splash_single_card_reset", function(test)
		local splash, hand = splash_setup(test, "QOL_SC_SPL_2")
		test:mock("pseudorandom", 1)
		test:mock("pseudorandom", 1)
		T.calc(splash, { initial_scoring_step = true, scoring_hand = hand })

		-- A new scoring with a single card must clear the stale second pick.
		test:mock("pseudorandom", 1)
		T.calc(splash, { initial_scoring_step = true, scoring_hand = { hand[3] } })

		test:assert_true(T.calc(splash, { repetition = true, cardarea = G.play, other_card = hand[1] }) == nil,
			"the previous first pick must not survive a new scoring step")
		test:assert_true(T.calc(splash, { repetition = true, cardarea = G.play, other_card = hand[2] }) == nil,
			"the stale second pick must be cleared on a single-card scoring")
		local eval_3 = T.calc(splash, { repetition = true, cardarea = G.play, other_card = hand[3] })
		test:assert_true(eval_3 ~= nil and eval_3.repetitions == 1, "the single card should still retrigger")
		test:clear_all_mocks()
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_splash_no_globals", function(test)
		local splash, hand = splash_setup(test, "QOL_SC_SPL_3")
		_G.random_splash_retrigger_1 = nil
		_G.random_splash_retrigger_2 = nil

		test:mock("pseudorandom", 1)
		test:mock("pseudorandom", 1)
		T.calc(splash, { initial_scoring_step = true, scoring_hand = hand })

		test:assert_true(_G.random_splash_retrigger_1 == nil, "the picks must not leak random_splash_retrigger_1 into _G")
		test:assert_true(_G.random_splash_retrigger_2 == nil, "the picks must not leak random_splash_retrigger_2 into _G")
		test:clear_all_mocks()
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_splash_repetition_area_guard", function(test)
		local splash, hand = splash_setup(test, "QOL_SC_SPL_4")
		test:mock("pseudorandom", 1)
		test:mock("pseudorandom", 1)
		T.calc(splash, { initial_scoring_step = true, scoring_hand = hand })

		test:assert_true(T.calc(splash, { repetition = true, cardarea = G.hand, other_card = hand[1] }) == nil,
			"a picked card must not retrigger outside G.play")
		test:assert_true(T.calc(splash, { repetition = true, cardarea = G.play }) == nil,
			"a repetition without other_card must stay inert")
		test:clear_all_mocks()
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_splash_config_off_gating", function(test)
		local center = G.P_CENTERS.j_splash
		local before = center.calculate
		QOL_BUNDLE.config.splash_joker_retrigger_enabled = false
		F.get_ownership_joker_splash()
		test:assert_eq(center.calculate, before, "the gated getter must be a no-op while disabled")
	end)

	-- === 8 Ball ===========================================================

	local function eight_ball_setup(test, seed)
		T.apply_feature("eight_ball_joker_enabled", "j_8_ball", F.get_ownership_joker_8_ball)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
		test:spawn_joker("j_8_ball"):assert()
		return G.jokers.cards[1]
	end

	BInt.register_test("riosodu/qol_bundle/scoring_eight_ball_config", function(test)
		local g = T.apply_feature("eight_ball_joker_enabled", "j_8_ball", F.get_ownership_joker_8_ball)
		test:assert_eq(g.config.extra, 3, "8 Ball should be a 1 in 3 chance by default")
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_eight_ball_tarot_guaranteed", function(test)
		local ball = eight_ball_setup(test, "QOL_SC_8B_1")
		local eight = T.force_card(1, "S_8")
		local before = #G.consumeables.cards
		local prev_normal = G.GAME.probabilities.normal
		G.GAME.probabilities.normal = 100

		local eval = T.calc(ball, { individual = true, cardarea = G.play, other_card = eight })
		G.GAME.probabilities.normal = prev_normal

		test:assert_true(eval ~= nil, "an 8 in play should roll for a Tarot")
		test:assert_true(type(eval.extra) == "table" and type(eval.extra.func) == "function",
			"the effect should carry the creation callback")
		eval.extra.func()
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "the Tarot should be created")
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_eight_ball_zero_odds", function(test)
		local ball = eight_ball_setup(test, "QOL_SC_8B_2")
		local eight = T.force_card(1, "S_8")
		local before = #G.consumeables.cards
		local prev_normal = G.GAME.probabilities.normal
		G.GAME.probabilities.normal = 0

		local eval = T.calc(ball, { individual = true, cardarea = G.play, other_card = eight })
		G.GAME.probabilities.normal = prev_normal

		test:assert_true(eval == nil, "zero odds must never produce the Tarot effect")
		test:assert_eq(#G.consumeables.cards, before, "no Tarot may be created")
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_eight_ball_consumables_full", function(test)
		local ball = eight_ball_setup(test, "QOL_SC_8B_3")
		local eight = T.force_card(1, "S_8")
		test:spawn_consumable("c_fool"):assert()
		test:spawn_consumable("c_fool"):assert()
		test:assert_eq(#G.consumeables.cards, G.consumeables.config.card_limit, "the consumable area should be full")

		local prev_normal = G.GAME.probabilities.normal
		G.GAME.probabilities.normal = 100
		local eval = T.calc(ball, { individual = true, cardarea = G.play, other_card = eight })
		G.GAME.probabilities.normal = prev_normal

		test:assert_true(eval == nil, "a full consumable area must suppress the roll")
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_eight_ball_two_eights", function(test)
		local ball = eight_ball_setup(test, "QOL_SC_8B_4")
		local eight_a = T.force_card(1, "S_8")
		local eight_b = T.force_card(2, "H_8")
		local before = #G.consumeables.cards
		local prev_normal = G.GAME.probabilities.normal
		G.GAME.probabilities.normal = 100

		local eval_a = T.calc(ball, { individual = true, cardarea = G.play, other_card = eight_a })
		test:assert_true(eval_a ~= nil, "the first 8 should roll")
		eval_a.extra.func()
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "the first Tarot should be created")

		local eval_b = T.calc(ball, { individual = true, cardarea = G.play, other_card = eight_b })
		test:assert_true(eval_b ~= nil, "the second 8 should roll too")
		eval_b.extra.func()
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 2
		end, 10, "the second Tarot should be created")

		G.GAME.probabilities.normal = prev_normal
	end)

	-- === 8 Ball callback (bug: nil state crash when disabled at load) =====

	local function with_callback_sandbox(state_key)
		local prev_state = QOL_BUNDLE.state[state_key]
		local prev_save = SMODS.save_mod_config
		SMODS.save_mod_config = function() end
		return prev_state, prev_save
	end

	BInt.register_test("riosodu/qol_bundle/scoring_eight_ball_callback_nil_state_safe", function(test)
		local prev_state, prev_save = with_callback_sandbox("eight_ball_joker")
		QOL_BUNDLE.state.eight_ball_joker = nil

		local ok, err = pcall(G.FUNCS.qol_bundle_eight_ball_joker_callback,
			{ to_key = "eight_ball_value_2", to_val = 2 })
		test:assert_true(ok, "the callback must not crash when the feature was off at load: " .. tostring(err))
		test:assert_eq(QOL_BUNDLE.config.eight_ball_joker_value, 2, "the callback should still update the config")

		-- With a state object present the live center config follows the value.
		local fake = { config = { extra = 3 } }
		QOL_BUNDLE.state.eight_ball_joker = fake
		G.FUNCS.qol_bundle_eight_ball_joker_callback({ to_key = "eight_ball_value_2", to_val = 2 })
		test:assert_eq(fake.config.extra, 2, "the live center config should follow the callback value")

		QOL_BUNDLE.state.eight_ball_joker = prev_state
		SMODS.save_mod_config = prev_save
	end)

	-- === Space Joker ======================================================

	BInt.register_test("riosodu/qol_bundle/scoring_space_default_off", function(test)
		test:assert_false(QOL_BUNDLE.config.space_joker_enabled, "Space Joker should default to off")
		local center = G.P_CENTERS.j_space
		local before = center.config
		F.get_ownership_joker_space()
		test:assert_eq(center.config, before, "the gated getter must be a no-op while disabled")
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_space_config_when_enabled", function(test)
		local g = T.apply_feature("space_joker_enabled", "j_space", F.get_ownership_joker_space)
		test:assert_eq(g.config.extra, 3, "Space Joker should be a 1 in 3 chance when enabled")
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_space_level_up_roll", function(test)
		T.apply_feature("space_joker_enabled", "j_space", F.get_ownership_joker_space)
		T.start_run(test, "QOL_SC_SPC_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_space"):assert()
		local space = G.jokers.cards[1]

		local context = { before = true, full_hand = { G.hand.cards[1] }, poker_hands = { Pair = {} }, scoring_name = "Pair" }
		local prev_normal = G.GAME.probabilities.normal
		G.GAME.probabilities.normal = 100
		local eval = T.calc(space, context)
		G.GAME.probabilities.normal = 0
		local eval_denied = T.calc(space, context)
		G.GAME.probabilities.normal = prev_normal

		test:assert_true(eval ~= nil and eval.level_up == true, "guaranteed odds should level up the played hand")
		test:assert_true(eval.card == space, "the level-up should credit the Joker")
		test:assert_true(eval_denied == nil, "zero odds must never level up the hand")
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_space_level_up_integration", function(test)
		T.apply_feature("space_joker_enabled", "j_space", F.get_ownership_joker_space)
		T.start_run(test, "QOL_SC_SPC_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_space"):assert()

		-- Force a plain Pair as the played hand.
		T.force_card(1, "S_2")
		T.force_card(2, "H_2")
		T.force_card(3, "S_7")
		T.force_card(4, "H_9")
		T.force_card(5, "C_J")

		local before_level = G.GAME.hands.Pair.level
		local prev_normal = G.GAME.probabilities.normal
		G.GAME.probabilities.normal = 100
		T.win_round(test)
		BInt._wait.for_condition(function()
			return G.GAME.hands.Pair.level == before_level + 1
		end, 10, "playing the Pair with guaranteed odds should level it up")
		G.GAME.probabilities.normal = prev_normal
	end)

	BInt.register_test("riosodu/qol_bundle/scoring_space_callback_nil_state_safe", function(test)
		local prev_state, prev_save = with_callback_sandbox("space_joker")
		QOL_BUNDLE.state.space_joker = nil

		local ok, err = pcall(G.FUNCS.qol_bundle_space_joker_callback,
			{ to_key = "space_value_2", to_val = 2 })
		test:assert_true(ok, "the callback must not crash when the feature was off at load: " .. tostring(err))
		test:assert_eq(QOL_BUNDLE.config.space_joker_value, 2, "the callback should still update the config")

		local fake = { config = { extra = 3 } }
		QOL_BUNDLE.state.space_joker = fake
		G.FUNCS.qol_bundle_space_joker_callback({ to_key = "space_value_2", to_val = 2 })
		test:assert_eq(fake.config.extra, 2, "the live center config should follow the callback value")

		QOL_BUNDLE.state.space_joker = prev_state
		SMODS.save_mod_config = prev_save
	end)
end
