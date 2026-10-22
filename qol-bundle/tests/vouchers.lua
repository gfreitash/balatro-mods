-- qol-bundle/tests/vouchers.lua
-- Voucher rework tests: Planet Merchant / Planet Tycoon (beta, default off).
--
-- The rework replaces the vouchers' vanilla shop-rate bonus with a chance to
-- create the played hand's equivalent Planet card (Merchant 1 in 4, Tycoon
-- 1 in 2; Tycoon replaces Merchant). Odds go through
-- SMODS.pseudorandom_probability, so Oops! All 6s and modded probability
-- modifiers must apply; the roll only happens in the `after` scoring context,
-- once per played hand, and only when the consumable area has space.

return function(T)
	local F = QOL_BUNDLE.funcs

	local function planet_setup(test, seed)
		T.apply_feature("planet_merchant_rework_enabled", "v_planet_merchant",
			F.get_ownership_voucher_planet_merchant)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
	end

	-- Vouchers are calculated from G.vouchers (SMODS includes that area in the
	-- jokers card area), so the test needs a real card plus the ownership flag.
	local function add_voucher(key)
		G.GAME.used_vouchers[key] = true
		return SMODS.add_card({ key = key, area = G.vouchers, bypass_discovery_center = true })
	end

	local function after_context(hand_name)
		local card = G.hand.cards[1]
		return {
			after = true,
			scoring_name = hand_name,
			full_hand = { card },
			scoring_hand = { card },
			poker_hands = {},
		}
	end

	local function last_planet_key()
		local cards = G.consumeables.cards
		for i = #cards, 1, -1 do
			if cards[i].ability.set == "Planet" then
				return cards[i].config.center.key
			end
		end
	end

	BInt.register_test("riosodu/qol_bundle/beta_planet_merchant_config", function(test)
		test:assert_false(QOL_BUNDLE.config.planet_merchant_rework_enabled,
			"the Planet Merchant rework should default to off")
		test:assert_true(localize('v_planet_merchant_modified') ~= 'ERROR',
			"the reworked tooltip localization must exist")

		local merchant = T.apply_feature("planet_merchant_rework_enabled", "v_planet_merchant",
			F.get_ownership_voucher_planet_merchant)
		test:assert_true(type(merchant.calculate) == "function",
			"Planet Merchant should gain a scoring calculate")
		test:assert_true(type(merchant.redeem) == "function",
			"Planet Merchant should define redeem so the vanilla shop-rate branch is skipped")
		test:assert_eq(merchant.config.extra_disp, 4, "Planet Merchant's tooltip should show 1 in 4")

		local tycoon = G.P_CENTERS.v_planet_tycoon
		test:assert_true(type(tycoon.calculate) == "function",
			"Planet Tycoon should gain a scoring calculate")
		test:assert_eq(tycoon.config.extra_disp, 2, "Planet Tycoon's tooltip should show 1 in 2")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_planet_merchant_redeem_replaces_shop_rate", function(test)
		T.apply_feature("planet_merchant_rework_enabled", "v_planet_merchant",
			F.get_ownership_voucher_planet_merchant)
		T.start_run(test, "QOL_BETA_PLANET_REDEEM_1", 1)
		test:select_blind():assert()

		G.GAME.planet_rate = 4
		Card.apply_to_run(nil, G.P_CENTERS.v_planet_merchant)
		BInt._wait.stable_drain()
		test:assert_eq(G.GAME.planet_rate, 4,
			"the vanilla 'planets appear more often' effect must be replaced")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_planet_merchant_quarter_odds", function(test)
		planet_setup(test, "QOL_BETA_PLANET_1")
		local merchant = add_voucher("v_planet_merchant")
		local before = #G.consumeables.cards

		-- 0.4 fails 1/4.
		test:mock("pseudorandom", 0.4)
		T.calc(merchant, after_context("Four of a Kind"))
		BInt._wait.stable_drain()
		test:assert_eq(#G.consumeables.cards, before, "a failed 1-in-4 roll must not create a Planet")

		-- 0.2 succeeds 1/4 and creates the played hand's Planet (Mars).
		test:mock("pseudorandom", 0.2)
		T.calc(merchant, after_context("Four of a Kind"))
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "a successful roll should create exactly one Planet")
		test:clear_all_mocks()
		test:assert_eq(last_planet_key(), "c_mars", "Four of a Kind should create Mars")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_planet_tycoon_half_odds", function(test)
		planet_setup(test, "QOL_BETA_PLANET_2")
		add_voucher("v_planet_merchant")
		local tycoon = add_voucher("v_planet_tycoon")
		local before = #G.consumeables.cards

		-- 0.4 fails Merchant's 1/4 but succeeds Tycoon's 1/2.
		test:mock("pseudorandom", 0.4)
		T.calc(tycoon, after_context("Pair"))
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "Planet Tycoon's 1-in-2 roll should succeed at 0.4")
		test:clear_all_mocks()
		test:assert_eq(last_planet_key(), "c_mercury", "Pair should create Mercury")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_planet_tycoon_replaces_merchant", function(test)
		planet_setup(test, "QOL_BETA_PLANET_3")
		local merchant = add_voucher("v_planet_merchant")
		local tycoon = add_voucher("v_planet_tycoon")
		local before = #G.consumeables.cards

		-- 0.05 would succeed for both vouchers, so exactly one card proves the
		-- two effects do not stack.
		test:mock("pseudorandom", 0.05)
		T.calc(merchant, after_context("Flush"))
		T.calc(tycoon, after_context("Flush"))
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "Planet Tycoon should create exactly one Planet")
		BInt._wait.stable_drain()
		test:clear_all_mocks()

		test:assert_eq(#G.consumeables.cards, before + 1,
			"Planet Tycoon replaces Planet Merchant instead of stacking")
		test:assert_eq(last_planet_key(), "c_jupiter", "Flush should create Jupiter")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_planet_merchant_oops_modifier", function(test)
		planet_setup(test, "QOL_BETA_PLANET_4")
		local merchant = add_voucher("v_planet_merchant")
		test:spawn_joker("j_oops"):assert()
		local before = #G.consumeables.cards

		-- Oops doubles the numerator: 2 in 4 -> 0.4 succeeds.
		test:mock("pseudorandom", 0.4)
		T.calc(merchant, after_context("Two Pair"))
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "Oops! All 6s must double the Planet chance")
		test:clear_all_mocks()
		test:assert_eq(last_planet_key(), "c_uranus", "Two Pair should create Uranus")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_planet_merchant_needs_space", function(test)
		planet_setup(test, "QOL_BETA_PLANET_5")
		local merchant = add_voucher("v_planet_merchant")
		while #G.consumeables.cards < G.consumeables.config.card_limit do
			test:spawn_consumable("c_fool"):assert()
		end
		local before = #G.consumeables.cards

		test:mock("pseudorandom", 0.0)
		T.calc(merchant, after_context("Pair"))
		BInt._wait.stable_drain()
		test:clear_all_mocks()

		test:assert_eq(#G.consumeables.cards, before,
			"a full consumable area must block the Planet card")
		test:assert_eq(G.GAME.consumeable_buffer, 0, "the consumable buffer must stay balanced")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_planet_merchant_context_and_planet_lookup", function(test)
		planet_setup(test, "QOL_BETA_PLANET_6")
		local merchant = add_voucher("v_planet_merchant")
		G.consumeables.config.card_limit = 10
		local before = #G.consumeables.cards

		-- Only context.after runs the roll.
		test:mock("pseudorandom", 0.0)
		T.calc(merchant, {
			joker_main = true,
			scoring_name = "Pair",
			full_hand = { G.hand.cards[1] },
			scoring_hand = { G.hand.cards[1] },
		})
		-- A modded hand with no equivalent Planet must be skipped safely.
		T.calc(merchant, after_context("Not A Real Hand"))
		BInt._wait.stable_drain()
		test:assert_eq(#G.consumeables.cards, before,
			"non-after contexts and hands without a Planet must not create anything")

		-- Standard and hidden hands map to their vanilla planets.
		for _, entry in ipairs({
			{ hand = "High Card", key = "c_pluto" },
			{ hand = "Straight Flush", key = "c_neptune" },
			{ hand = "Five of a Kind", key = "c_planet_x" },
		}) do
			local count = #G.consumeables.cards
			test:mock("pseudorandom", 0.0)
			T.calc(merchant, after_context(entry.hand))
			BInt._wait.for_condition(function()
				return #G.consumeables.cards == count + 1
			end, 10, entry.hand .. " should create its Planet")
			test:assert_eq(last_planet_key(), entry.key,
				entry.hand .. " should create " .. entry.key)
		end
		test:clear_all_mocks()
	end)
end
