-- qol-bundle/tests/fix_regressions.lua
-- Fix-audit regression suite (2026-10-16). Pins the still-current behavioral
-- fixes from qol-bundle/CHANGELOG.md (all versions) that were NOT already
-- covered by the other group files. Full inventory + verdicts:
-- /tmp/opencode/fix-audit-report.md (durable copy: .temp/fix-audit-report.md).
--
-- Covered here (one test per fix unless the setup is shared):
--  * 1.12.2  Onyx Agate / Seance effect tables must carry the Joker CARD in
--            `card` (the scoring engine calls effect.card:juice_up) and the
--            message/colour at the top level (crash fix).
--  * 1.11.2  Smeared shade matching in the non-Paperback branch: no light/dark
--            cross-match and suitless (Stone) cards match no suit.
--  * 1.8.2 / 2ad18d5  Wildcard fix: Wild Cards and same-shade cards under
--            Smeared resist suit-based boss debuffs; the toggle applies live;
--            the modern Blind:debuff_card pipeline (modded debuff_card context,
--            face branches) is preserved.
--  * 1.6.3   Hit the Road: a blueprint pass must not queue the Jack returns.
--  * 1.11.0  Castle suit group is derived from the picked card (no independent
--            roll, so the vanilla fallback can never hit an opposite suit).
--  * 1.8.0   Unweighted editions apply at runtime (no restart) + Magic Trick
--            seal path and the playing-card price matrix.
--  * 1.2.0   Wheel of Fortune value applies to the live center (no restart).
--  * 99dbe2f Game-object callback chain: interest_base is set on every run and
--            the callback list is not leaked to _G.

return function(T)
	local F = QOL_BUNDLE.funcs

	-- === 1.12.2: Onyx Agate scoring crash =================================

	-- The old code returned `card = self` (the Joker CENTER) and nested the
	-- message/colour under `extra`, so the scoring engine's juice_card(effect.card)
	-- called juice_up on the center -> "attempt to call method 'juice_up'
	-- (a nil value)" when a Club scored.
	BInt.register_test("riosodu/qol_bundle/regr_onyx_effect_card_is_juiceable", function(test)
		T.apply_feature("onyx_agate_enabled", "j_onyx_agate", F.get_ownership_joker_onyx_agate)
		T.start_run(test, "QOL_REGR_ONYX_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_onyx_agate"):assert()

		local onyx = G.jokers.cards[1]
		local club = T.force_card(1, "C_7")
		local eval = T.calc(onyx, { individual = true, cardarea = G.play, other_card = club })

		test:assert_true(eval ~= nil, "a scored Club should trigger the Onyx rework")
		test:assert_true(eval.card == onyx,
			"the effect must credit the Joker CARD (the scoring engine juices effect.card)")
		test:assert_true(type(eval.card.juice_up) == "function",
			"effect.card must expose juice_up or scoring crashes")
		test:assert_true(eval.message ~= nil,
			"the upgrade message must be a top-level effect key")
		test:assert_eq(eval.colour, G.C.MULT, "the upgrade colour must be top-level")
	end)

	-- === 1.12.2: Seance latent scoring crash ==============================

	BInt.register_test("riosodu/qol_bundle/regr_seance_effect_card_is_juiceable", function(test)
		T.apply_feature("seance_rework_enabled", "j_seance", F.get_ownership_joker_seance)
		T.start_run(test, "QOL_REGR_SEANCE_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_seance"):assert()

		local seance = G.jokers.cards[1]
		local before = #G.consumeables.cards
		local eval = T.calc(seance, {
			joker_main = true,
			poker_hands = { ["Five of a Kind"] = {} },
			scoring_name = "Five of a Kind",
			scoring_hand = { G.hand.cards[1] },
		})

		test:assert_true(eval ~= nil, "a secret hand should trigger the Seance rework")
		test:assert_true(eval.card == seance,
			"the effect must credit the Joker CARD (the scoring engine juices effect.card)")
		test:assert_true(type(eval.card.juice_up) == "function",
			"effect.card must expose juice_up or scoring crashes")
		test:assert_true(eval.message ~= nil, "the Spectral message must be top-level")

		-- Drain the queued Spectral creation so it cannot fire during a later test.
		BInt._wait.for_condition(function()
			return #G.consumeables.cards == before + 1
		end, 10, "Seance should create the Spectral card")
	end)

	-- === 1.11.2: Smeared shade matching (non-Paperback branch) ============

	BInt.register_test("riosodu/qol_bundle/regr_smeared_shade_matching", function(test)
		T.start_run(test, "QOL_REGR_SMEAR_1", 1)
		test:select_blind():assert()

		local spade = T.force_card(1, "S_5")
		local heart = T.force_card(2, "H_5")
		-- Printed Hearts: only the no_suit enhancement can stop the match.
		local stone = T.force_card(3, "H_4")
		stone:set_ability(G.P_CENTERS.m_stone)
		local wild = T.force_card(4, "D_4")
		wild:set_ability(G.P_CENTERS.m_wild)

		test:assert_false(spade:is_suit("Clubs"), "control: without Smeared a Spade is not a Club")
		test:spawn_joker("j_smeared"):assert()

		test:assert_true(spade:is_suit("Clubs"), "a Spade should match Clubs under Smeared (same dark shade)")
		test:assert_false(spade:is_suit("Hearts"), "a Spade must not match Hearts under Smeared (opposite shade)")
		test:assert_true(heart:is_suit("Diamonds"), "a Heart should match Diamonds under Smeared (same light shade)")
		test:assert_false(stone:is_suit("Hearts"),
			"a suitless Stone Card must not match any suit, even its printed shade")
		test:assert_false(stone:is_suit("Spades"), "a suitless Stone Card must not match the opposite shade either")
		test:assert_true(wild:is_suit("Clubs"), "a Wild Card matches every suit")
	end)

	-- === 1.8.2 / 2ad18d5: wildcard fix vs suit-based boss debuffs =========

	BInt.register_test("riosodu/qol_bundle/regr_wildcard_boss_suit_debuff_resist", function(test)
		test:assert_true(QOL_BUNDLE.config.wildcard_fix_enabled, "the wildcard fix should be on by default")
		T.start_run(test, "QOL_REGR_BOSS_1", 1)
		test:select_blind():assert()

		local wild = T.force_card(1, "H_6")
		wild:set_ability(G.P_CENTERS.m_wild)
		local plain = T.force_card(2, "C_5")
		local heart = T.force_card(3, "H_5")
		wild.debuff = nil
		plain.debuff = nil
		heart.debuff = nil

		local blind = G.GAME.blind
		local prev_debuff = blind.debuff
		local prev_disabled = blind.disabled
		blind.debuff = { suit = "Clubs" }
		blind.disabled = false

		blind:debuff_card(plain, true)
		blind:debuff_card(heart, true)
		blind:debuff_card(wild, true)

		blind.debuff = prev_debuff
		blind.disabled = prev_disabled

		test:assert_true(plain.debuff == true, "a plain card of the debuffed suit must be debuffed")
		test:assert_true(heart.debuff ~= true, "an off-suit card must not be debuffed")
		test:assert_true(wild.debuff ~= true, "a Wild Card must resist the suit-based boss debuff")
		test:assert_false(QOL_BUNDLE.wildcard_debuff_check, "the debuff-check window must be restored after the call")
		test:assert_true(wild:is_suit("Clubs"), "normal suit matching must be back outside the debuff window")
	end)

	BInt.register_test("riosodu/qol_bundle/regr_smeared_boss_suit_debuff_resist", function(test)
		T.start_run(test, "QOL_REGR_BOSS_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_smeared"):assert()

		local club = T.force_card(1, "C_5")
		club.debuff = nil
		test:assert_true(club:is_suit("Spades"), "control: Smeared makes same-shade suits match")

		local blind = G.GAME.blind
		local prev_debuff = blind.debuff
		local prev_disabled = blind.disabled
		blind.debuff = { suit = "Spades" }
		blind.disabled = false

		blind:debuff_card(club, true)

		blind.debuff = prev_debuff
		blind.disabled = prev_disabled

		test:assert_true(club.debuff ~= true,
			"under Smeared a same-shade card must resist the suit-based boss debuff")
	end)

	-- The fix is applied dynamically: disabling it takes effect immediately
	-- (no restart), so a Wild Card is debuffed by the same suit blind.
	BInt.register_test("riosodu/qol_bundle/regr_wildcard_fix_runtime_toggle", function(test)
		T.start_run(test, "QOL_REGR_BOSS_3", 1)
		test:select_blind():assert()

		local wild = T.force_card(1, "H_6")
		wild:set_ability(G.P_CENTERS.m_wild)
		wild.debuff = nil

		QOL_BUNDLE.config.wildcard_fix_enabled = false
		local blind = G.GAME.blind
		local prev_debuff = blind.debuff
		local prev_disabled = blind.disabled
		blind.debuff = { suit = "Clubs" }
		blind.disabled = false
		blind:debuff_card(wild, true)
		blind.debuff = prev_debuff
		blind.disabled = prev_disabled
		QOL_BUNDLE.config.wildcard_fix_enabled = true

		test:assert_true(wild.debuff == true,
			"with the fix disabled at runtime a Wild Card is debuffed (vanilla), proving the toggle applies live")
	end)

	-- 2ad18d5: the override must delegate to the modern SMods implementation,
	-- so the debuff_card context pipeline (modded bosses, recalc_debuff) and the
	-- non-suit vanilla branches keep working.
	BInt.register_test("riosodu/qol_bundle/regr_blind_debuff_pipeline_preserved", function(test)
		T.start_run(test, "QOL_REGR_BOSS_4", 1)
		test:select_blind():assert()
		test:spawn_joker("j_joker"):assert()

		local joker = G.jokers.cards[1]
		local center = joker.config.center
		T.snap_center("j_joker")
		local prev_calculate = center.calculate
		center.calculate = function(self, card, context)
			if context.debuff_card == joker then
				return { debuff = true }
			end
			return prev_calculate and prev_calculate(self, card, context)
		end

		local blind = G.GAME.blind
		local prev_debuff = blind.debuff
		local prev_disabled = blind.disabled

		-- 1) modded debuff_card context (SMODS.recalc_debuff path).
		blind.debuff = nil
		blind.disabled = false
		blind:debuff_card(joker)

		-- 2) a non-suit vanilla branch (face debuff).
		blind.debuff = { is_face = "face" }
		local face = T.force_card(1, "S_K")
		local low = T.force_card(2, "S_2")
		blind:debuff_card(face, true)
		blind:debuff_card(low, true)

		center.calculate = prev_calculate
		blind.debuff = prev_debuff
		blind.disabled = prev_disabled

		test:assert_true(joker.debuff == true,
			"the debuff_card context pipeline must still run through the override")
		test:assert_true(face.debuff == true, "a face-debuff boss must still debuff face cards")
		test:assert_true(low.debuff ~= true, "non-face cards must not be debuffed by the face branch")
	end)

	-- === 1.6.3: Hit the Road blueprint guard ==============================

	BInt.register_test("riosodu/qol_bundle/regr_htr_blueprint_queues_no_events", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_REGR_HTR_BP_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_hit_the_road"):assert()

		local joker = G.jokers.cards[1]
		local jack = T.force_card(1, "S_J")
		local queued_before = #G.E_MANAGER.queues.base

		-- A blueprint pass (the copy a Blueprint/Brainstorm installs) must not
		-- queue the Jack-return + shuffle events again.
		T.calc(joker, { pre_discard = true, full_hand = { jack }, blueprint = 1 })
		test:assert_eq(#G.E_MANAGER.queues.base, queued_before,
			"a blueprint pass must not queue the Jack-return events")

		-- Control: the main pass does queue the return.
		T.calc(joker, { pre_discard = true, full_hand = { jack } })
		test:assert_true(#G.E_MANAGER.queues.base > queued_before,
			"the main pass must queue the Jack-return event")

		-- Drain the queued return so it cannot fire during a later test.
		BInt._wait.stable_drain()
	end)

	-- === 1.11.0: Castle group derived from the picked card (#10) ==========

	BInt.register_test("riosodu/qol_bundle/regr_castle_group_derived_from_pick", function(test)
		T.start_run(test, "QOL_REGR_CASTLE_1", 1)

		local eligible = {}
		for _, card in ipairs(G.playing_cards) do
			if not SMODS.has_no_suit(card) then
				eligible[#eligible + 1] = card
			end
		end
		local heart_idx
		for i, card in ipairs(eligible) do
			if card.base.suit == "Hearts" then
				heart_idx = i
				break
			end
		end
		test:assert_true(heart_idx ~= nil, "the run seed should hold a Heart")

		-- Pre-fix the light/dark group was rolled independently of the picked
		-- card: force that roll to 'dark' (0.1 < 0.5) while the element pick is
		-- a Heart (light). The fixed reset derives the group from the pick, so
		-- the stale roll is never consulted.
		test:mock("pseudorandom", 0.1)
		test:mock("pseudorandom_element", heart_idx)
		reset_castle_card()
		test:clear_all_mocks()

		test:assert_eq(G.GAME.current_round.castle_card.suit, "Hearts", "the suit should follow the picked card")
		test:assert_eq(G.GAME.current_round.castle_card_group, "light",
			"the group must be derived from the picked suit, never from an independent roll")
	end)

	-- === 1.8.0: Unweighted editions apply without a restart ===============

	BInt.register_test("riosodu/qol_bundle/regr_unweighted_editions_live_toggle", function(test)
		T.start_run(test, "QOL_REGR_UNW_1", 1)
		test:select_blind():assert()

		-- Runtime toggle ON: a roll inside the 4% edition window (0.99 > 0.96)
		-- must map onto the unweighted thirds (second roll 0.5 -> holo).
		QOL_BUNDLE.config.unweighted_editions_enabled = true
		test:mock("pseudorandom", 0.99)
		test:mock("pseudorandom", 0.5)
		local res_on = poll_edition("regr_unweighted_key", 1, false, false)
		test:clear_all_mocks()
		test:assert_true(res_on ~= nil and res_on.holo == true,
			"the enabled feature should apply the unweighted thirds immediately (got "
				.. tostring(res_on and res_on.holo) .. ")")

		-- Runtime toggle OFF: the override must delegate to the stored original.
		QOL_BUNDLE.config.unweighted_editions_enabled = false
		test:mock("poll_edition", { foil = true })
		local res_off = poll_edition("regr_unweighted_key", 1, false, false)
		test:clear_all_mocks()
		test:assert_true(res_off ~= nil and res_off.foil == true,
			"the disabled feature should delegate to the original poll_edition immediately")
	end)

	-- === 1.8.0: Magic Trick seals actually spawn + price matrix ===========

	BInt.register_test("riosodu/qol_bundle/regr_magic_trick_seal_applies", function(test)
		T.start_run(test, "QOL_REGR_SEAL_1", 1)
		test:select_blind():assert()

		local card = T.force_card(1, "S_5")
		test:mock("SMODS.poll_seal", "Red")
		QOL_BUNDLE.utils.apply_enhanced_magic_trick_upgrades(card)
		test:clear_all_mocks()

		test:assert_eq(card.seal, "Red",
			"the enhanced Magic Trick path must actually apply the polled seal")
	end)

	BInt.register_test("riosodu/qol_bundle/regr_shop_playing_card_pricing", function(test)
		T.start_run(test, "QOL_REGR_PRICE_1", 1)
		test:select_blind():assert()

		local card = T.force_card(1, "S_2")
		card.base_cost = 2
		card.cost = 2

		QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
		test:assert_eq(card.cost, 2, "a plain playing card keeps its base cost")

		card:set_seal("Red", nil, true)
		QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
		test:assert_eq(card.cost, 3, "a seal should add $1")

		card.edition = { key = "e_foil", foil = true }
		QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
		test:assert_eq(card.cost, 5, "a foil edition should add $2")

		card.edition = { key = "e_polychrome", polychrome = true }
		QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
		test:assert_eq(card.cost, 6, "a polychrome edition should add $3")

		card:set_ability(G.P_CENTERS.m_bonus)
		card.base_cost = 2 -- set_ability resets base_cost to the center cost (nil -> 1)
		QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
		test:assert_eq(card.cost, 7, "an enhancement should add $1 on top of seal + polychrome")
	end)

	-- === 1.2.0: Wheel of Fortune value applies without a restart ==========

	BInt.register_test("riosodu/qol_bundle/regr_wheel_config_live_update", function(test)
		local center = T.apply_feature("wheel_of_fortune_enabled", "c_wheel_of_fortune", F.get_ownership_wheel_of_fortune)
		test:assert_eq(center.config.extra, 3, "the Wheel center should read the config at apply time")

		local prev_save = SMODS.save_mod_config
		SMODS.save_mod_config = function() end
		G.FUNCS.qol_bundle_wheel_callback({ to_key = 2, to_val = 2 })
		SMODS.save_mod_config = prev_save

		test:assert_eq(QOL_BUNDLE.config.wheel_of_fortune_value, 2, "the callback should update the config")
		test:assert_eq(center.config.extra, 2,
			"the live Wheel center should follow the callback without a restart")
	end)

	-- The feature can be disabled at load: ownership never runs, so there is
	-- no state object. Cycling the value option must still update the config
	-- without crashing (same guard as the 8 Ball / Space callbacks).
	BInt.register_test("riosodu/qol_bundle/regr_wheel_config_disabled_at_load_nil_safe", function(test)
		local prev_state = QOL_BUNDLE.state.wheel_of_fortune
		local prev_save = SMODS.save_mod_config
		SMODS.save_mod_config = function() end
		QOL_BUNDLE.state.wheel_of_fortune = nil

		local ok, err = pcall(G.FUNCS.qol_bundle_wheel_callback, { to_key = 2, to_val = 2 })
		test:assert_true(ok, "the callback must not crash when the feature was off at load: " .. tostring(err))
		test:assert_eq(QOL_BUNDLE.config.wheel_of_fortune_value, 2, "the callback should still update the config")

		local fake = { config = { extra = 3 } }
		QOL_BUNDLE.state.wheel_of_fortune = fake
		G.FUNCS.qol_bundle_wheel_callback({ to_key = 2, to_val = 2 })
		test:assert_eq(fake.config.extra, 2, "the live center config should follow the callback value")

		QOL_BUNDLE.state.wheel_of_fortune = prev_state
		SMODS.save_mod_config = prev_save
	end)

	-- === 99dbe2f: game-object callback chain ==============================

	BInt.register_test("riosodu/qol_bundle/regr_game_obj_interest_props", function(test)
		T.start_run(test, "QOL_REGR_GOBJ_1", 1)
		test:select_blind():assert()

		test:assert_eq(G.GAME.interest_base, 5,
			"the shared game-object callback must set interest_base on every run")
		test:assert_true(_G.game_obj_callbacks == nil,
			"the game-object callback list must not leak into _G")
	end)
end
