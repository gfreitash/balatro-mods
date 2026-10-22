-- qol-bundle/tests/loader.lua
-- Baseline sanity tests: globals, config defaults, which features are applied
-- by default vs left vanilla, registered UI callbacks and the interest-on-skip
-- override wiring.

return function(T)
	local JOKER = SMODS.Joker

	BInt.register_test("riosodu/qol_bundle/loader_globals", function(test)
		test:assert_true(QOL_BUNDLE ~= nil, "QOL_BUNDLE global should exist")
		test:assert_eq(QOL_BUNDLE.mod_id, "qol_bundle", "mod id should match")
		test:assert_true(type(QOL_BUNDLE.funcs) == "table", "funcs table should exist")
		test:assert_true(type(QOL_BUNDLE.utils) == "table", "utils table should exist")
		test:assert_true(type(QOL_BUNDLE.UI) == "table", "UI table should exist")
		test:assert_true(type(QOL_BUNDLE.debug) == "table", "debug table should exist")
		test:assert_true(QOL_BUNDLE.mod ~= nil, "SMODS mod object should be linked")
	end)

	BInt.register_test("riosodu/qol_bundle/loader_config_baseline", function(test)
		for _, key in ipairs(T.CONFIG_KEYS) do
			test:assert_eq(QOL_BUNDLE.config[key], T.DEFAULTS[key], "config default for " .. key)
		end
	end)

	-- Every default-on feature must be applied when enabled at runtime; the
	-- getters are idempotent (take_ownership copies fields onto the live center).
	BInt.register_test("riosodu/qol_bundle/loader_default_on_takeovers", function(test)
		local F = QOL_BUNDLE.funcs

		local g = T.apply_feature("baron_uncommon_enabled", "j_baron", F.get_ownership_joker_baron)
		test:assert_eq(g.rarity, 2)
		test:assert_eq(g.cost, 5)

		g = T.apply_feature("mime_rare_enabled", "j_mime", F.get_ownership_joker_mime)
		test:assert_eq(g.rarity, 3)
		test:assert_eq(g.cost, 6)

		g = T.apply_feature("ceremonial_dagger_common_enabled", "j_ceremonial", F.get_ownership_joker_cerimonial)
		test:assert_eq(g.rarity, 1)
		test:assert_eq(g.cost, 3)

		g = T.apply_feature("mail_in_rebate_uncommon_enabled", "j_mail", F.get_ownership_joker_mail)
		test:assert_eq(g.rarity, 2)
		test:assert_eq(g.cost, 8)

		g = T.apply_feature("fortune_teller_cheaper_enabled", "j_fortune_teller", F.get_ownership_joker_fortune_teller)
		test:assert_eq(g.cost, 4)

		g = T.apply_feature("nerf_hanging_chad_enabled", "j_hanging_chad", F.get_ownership_joker_hanging_chad)
		test:assert_eq(g.rarity, 2)
		test:assert_eq(g.cost, 7)

		g = T.apply_feature("eight_ball_joker_enabled", "j_8_ball", F.get_ownership_joker_8_ball)
		test:assert_eq(g.config.extra, 3)

		g = T.apply_feature("splash_joker_retrigger_enabled", "j_splash", F.get_ownership_joker_splash)
		test:assert_true(type(g.calculate) == "function", "splash should gain a calculate")

		g = T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		test:assert_true(type(g.calculate) == "function", "hit the road should gain a calculate")

		g = T.apply_feature("square_joker_enabled", "j_square", F.get_ownership_joker_square)
		test:assert_eq(g.rarity, 2)
		test:assert_eq(g.config.extra.chip_mod, 2)
		test:assert_eq(g.config.extra.bonus_chip_mod, 4)

		g = T.apply_feature("erosion_xmult_enabled", "j_erosion", F.get_ownership_joker_erosion)
		test:assert_eq(g.config.extra, 0.175)

		g = T.apply_feature("marble_joker_xchips_enabled", "j_marble", F.get_ownership_joker_marble)
		test:assert_eq(g.config.extra.xchips, 1)

		g = T.apply_feature("stone_joker_mult_enabled", "j_stone", F.get_ownership_joker_stone)
		test:assert_eq(g.config.extra, 4)

		g = T.apply_feature("satellite_joker_enabled", "j_satellite", F.get_ownership_joker_satellite)
		test:assert_true(type(g.calc_dollar_bonus) == "function", "satellite should gain calc_dollar_bonus")

		g = T.apply_feature("castle_checkered_enabled", "j_castle", F.get_ownership_joker_castle)
		test:assert_true(type(g.calculate) == "function", "castle should gain a calculate")

		g = T.apply_feature("flower_pot_wildcard_enabled", "j_flower_pot", F.get_ownership_joker_flower_pot)
		test:assert_eq(g.enhancement_gate, "m_wild")

		g = T.apply_feature("yorick_multiplier_enabled", "j_yorick", F.get_ownership_joker_yorick)
		test:assert_eq(g.config.extra.xmult, QOL_BUNDLE.config.yorick_multiplier_value)
		test:assert_eq(g.config.extra.discards, 23)
	end)

	-- Default-off (beta) features must stay inert while disabled. Absolute
	-- vanilla values are intentionally NOT asserted (the saved launch config may
	-- already have the feature applied before the tests can snapshot), so the
	-- check is a before/after comparison of the center fields.
	BInt.register_test("riosodu/qol_bundle/loader_default_off_gating", function(test)
		for _, key in ipairs({
			"space_joker_enabled",
			"steel_joker_enabled",
			"dna_uncommon_enabled",
			"pareidolia_common_enabled",
			"loyalty_card_scaling_enabled",
			"seance_rework_enabled",
			"caino_rework_enabled",
			"onyx_agate_enabled",
			"planet_merchant_rework_enabled",
			"wraith_rework_enabled",
			"ankh_rework_enabled",
			"lovers_two_cards_enabled",
			"strength_two_cards_enabled",
			"hex_rework_enabled",
			"matador_rework_enabled",
			"red_card_rework_enabled",
			"bull_buff_enabled",
			"mr_bones_rework_enabled",
			"spectral_seal_clip_enabled",
			"unweighted_editions_enabled",
		}) do
			test:assert_false(QOL_BUNDLE.config[key], key .. " should default to false")
		end

		local gated = {
			{ "space_joker_enabled", "j_space", QOL_BUNDLE.funcs.get_ownership_joker_space },
			{ "steel_joker_enabled", "j_steel_joker", QOL_BUNDLE.funcs.get_ownership_joker_steel },
			{ "dna_uncommon_enabled", "j_dna", QOL_BUNDLE.funcs.get_ownership_joker_dna },
			{ "pareidolia_common_enabled", "j_pareidolia", QOL_BUNDLE.funcs.get_ownership_joker_pareidolia },
			{ "loyalty_card_scaling_enabled", "j_loyalty_card", QOL_BUNDLE.funcs.get_ownership_loyalty_card },
			{ "seance_rework_enabled", "j_seance", QOL_BUNDLE.funcs.get_ownership_joker_seance },
			{ "caino_rework_enabled", "j_caino", QOL_BUNDLE.funcs.get_ownership_joker_caino },
			{ "onyx_agate_enabled", "j_onyx_agate", QOL_BUNDLE.funcs.get_ownership_joker_onyx_agate },
			{ "planet_merchant_rework_enabled", "v_planet_merchant", QOL_BUNDLE.funcs.get_ownership_voucher_planet_merchant },
			{ "wraith_rework_enabled", "c_wraith", QOL_BUNDLE.funcs.get_ownership_spectral_wraith },
			{ "ankh_rework_enabled", "c_ankh", QOL_BUNDLE.funcs.get_ownership_spectral_ankh },
			{ "lovers_two_cards_enabled", "c_lovers", QOL_BUNDLE.funcs.get_ownership_tarot_lovers },
			{ "strength_two_cards_enabled", "c_strength", QOL_BUNDLE.funcs.get_ownership_tarot_strength },
			{ "hex_rework_enabled", "c_hex", QOL_BUNDLE.funcs.get_ownership_spectral_hex },
			{ "matador_rework_enabled", "j_matador", QOL_BUNDLE.funcs.get_ownership_joker_matador },
			{ "red_card_rework_enabled", "j_red_card", QOL_BUNDLE.funcs.get_ownership_joker_red_card },
			{ "bull_buff_enabled", "j_bull", QOL_BUNDLE.funcs.get_ownership_joker_bull },
			{ "mr_bones_rework_enabled", "j_mr_bones", QOL_BUNDLE.funcs.get_ownership_joker_mr_bones },
		}
		for _, entry in ipairs(gated) do
			local config_key, center_key, getter = entry[1], entry[2], entry[3]
			QOL_BUNDLE.config[config_key] = false
			local center = G.P_CENTERS[center_key]
			local before = {
				rarity = center.rarity,
				cost = center.cost,
				config = center.config,
				calculate = center.calculate,
				enhancement_gate = center.enhancement_gate,
			}
			getter()
			test:assert_eq(center.rarity, before.rarity, center_key .. ": rarity untouched while disabled")
			test:assert_eq(center.cost, before.cost, center_key .. ": cost untouched while disabled")
			test:assert_true(center.config == before.config, center_key .. ": config untouched while disabled")
			test:assert_true(center.calculate == before.calculate, center_key .. ": calculate untouched while disabled")
			test:assert_eq(center.enhancement_gate, before.enhancement_gate, center_key .. ": gate untouched while disabled")
		end
	end)

	BInt.register_test("riosodu/qol_bundle/loader_gfuncs", function(test)
		test:assert_true(type(G.FUNCS.qol_bundle_wheel_callback) == "function")
		test:assert_true(type(G.FUNCS.qol_bundle_eight_ball_joker_callback) == "function")
		test:assert_true(type(G.FUNCS.qol_bundle_space_joker_callback) == "function")
		test:assert_true(type(G.FUNCS.qol_bundle_yorick_callback) == "function")
		test:assert_true(type(G.FUNCS.qol_bundle_update_config_page) == "function")
	end)

	BInt.register_test("riosodu/qol_bundle/loader_interest_installed", function(test)
		test:assert_true(type(QOL_BUNDLE.original.skip_blind) == "function", "original skip_blind should be stored")
		QOL_BUNDLE.funcs.apply_interest_on_skip_override()
		test:assert_true(
			G.FUNCS.skip_blind ~= QOL_BUNDLE.original.skip_blind,
			"skip_blind should be wrapped while interest_on_skip_enabled is true"
		)
	end)
end
