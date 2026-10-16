-- qol-bundle/tests/pb_compat.lua
-- Paperback compatibility coverage. Registered ONLY when Paperback is loaded
-- (T.PB), i.e. in the runner's PB mode (--pb, default pattern riosodu/pb).
-- The main PB-free run covers the opposite branch of every check, so the two
-- modes together exercise both sides of each `PB_UTIL` conditional.

return function(T)
	if not T.PB then
		return
	end

	local F = QOL_BUNDLE.funcs

	BInt.register_test("riosodu/pb/pb_loaded_sanity", function(test)
		test:assert_true(PB_UTIL.light_suits ~= nil and PB_UTIL.dark_suits ~= nil, "PB shade lists should be present")
		test:assert_eq(QOL_BUNDLE.utils.get_suit_shade("Hearts"), "light", "Hearts should be light")
		test:assert_eq(QOL_BUNDLE.utils.get_suit_shade("Diamonds"), "light", "Diamonds should be light")
		test:assert_eq(QOL_BUNDLE.utils.get_suit_shade("Spades"), "dark", "Spades should be dark")
		test:assert_eq(QOL_BUNDLE.utils.get_suit_shade("Clubs"), "dark", "Clubs should be dark")
	end)

	-- Castle: the PB branch must route the discard check through
	-- QOL_BUNDLE.utils.card_is_shade (single vanilla suit would miss a Club).
	BInt.register_test("riosodu/pb/pb_castle_shade_via_card_is_shade", function(test)
		T.apply_feature("castle_checkered_enabled", "j_castle", F.get_ownership_joker_castle)
		T.start_run(test, "QOL_PB_CASTLE_1", 1)
		test:select_blind():assert()
		test:spawn_joker("j_castle"):assert()

		local castle = G.jokers.cards[1]
		G.GAME.current_round.castle_card_group = "dark"
		G.GAME.current_round.castle_card.suit = "Spades"
		castle.ability.extra.chips = 0

		local utils = QOL_BUNDLE.utils
		local original = utils.card_is_shade
		local calls = 0
		utils.card_is_shade = function(...)
			calls = calls + 1
			return original(...)
		end

		local club = T.force_card(1, "C_2")
		local eval = T.calc(castle, { discard = true, other_card = club, full_hand = { club } })

		utils.card_is_shade = original

		test:assert_true(calls > 0, "the PB castle branch should use card_is_shade")
		test:assert_true(eval ~= nil, "a dark-shade Club should trigger Castle")
		test:assert_eq(castle.ability.extra.chips, 3, "Castle should gain its chip_mod")
	end)

	BInt.register_test("riosodu/pb/pb_castle_reset_group_pb", function(test)
		T.start_run(test, "QOL_PB_CASTLE_2", 1)

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

		test:mock("pseudorandom_element", heart_idx)
		reset_castle_card()
		test:clear_all_mocks()

		test:assert_eq(G.GAME.current_round.castle_card.suit, "Hearts", "the suit should follow the pick")
		test:assert_eq(G.GAME.current_round.castle_card_group, "light", "the group should follow the PB shade")
	end)

	BInt.register_test("riosodu/pb/pb_castle_loc_vars_paperback", function(test)
		local center = T.apply_feature("castle_checkered_enabled", "j_castle", F.get_ownership_joker_castle)
		T.start_run(test, "QOL_PB_CASTLE_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_castle"):assert()

		local castle = G.jokers.cards[1]
		castle.ability.extra.chips = 6
		G.GAME.current_round.castle_card_group = "light"

		local info_queue = {}
		local lv = center.loc_vars(nil, info_queue, castle)
		test:assert_eq(#info_queue, 1, "the PB suit tooltip should be appended")
		test:assert_true(lv ~= nil and lv.vars ~= nil, "loc_vars should return vars")
		test:assert_true(lv.vars.colours ~= nil and lv.vars.colours[1] == G.C.PAPERBACK_LIGHT_SUIT,
			"the light group should use the PB light colour")
		test:assert_eq(lv.vars[1], castle.ability.extra.chip_mod, "var #1 is the chip increment")
		test:assert_eq(lv.vars[3], 6, "var #3 is the current chips")
	end)

	-- Smeared: PB tooltips + text variant + shade-based is_suit matching.
	BInt.register_test("riosodu/pb/pb_smeared_tooltips_and_text", function(test)
		local center = T.apply_feature("wildcard_fix_enabled", "j_smeared", F.get_ownership_joker_smeared)
		T.refresh_loc()

		local info_queue = {}
		center.loc_vars(nil, info_queue, nil)
		test:assert_eq(#info_queue, 2, "PB should add both light and dark suit tooltips")
		test:assert_true(G.localization.descriptions.Joker.j_smeared.text == localize('j_smeared_paperback'),
			"the PB smeared text should be active")
	end)

	BInt.register_test("riosodu/pb/pb_smeared_is_suit_shades", function(test)
		T.apply_feature("wildcard_fix_enabled", "j_smeared", F.get_ownership_joker_smeared)
		T.start_run(test, "QOL_PB_SMEARED_1", 1)
		test:select_blind():assert()

		local heart = T.force_card(1, "H_5")
		test:assert_false(heart:is_suit("Diamonds"), "without Smeared a Heart is not a Diamond")
		test:spawn_joker("j_smeared"):assert()
		test:assert_true(heart:is_suit("Diamonds"), "under PB shades a Heart should match Diamonds")
		test:assert_false(heart:is_suit("Clubs"), "light and dark shades must not cross")
	end)

	-- Paperclip application via the real PB API (20% gate, guaranteed reapply).
	BInt.register_test("riosodu/pb/pb_paperclip_apply", function(test)
		T.start_run(test, "QOL_PB_CLIP_1", 1)
		test:select_blind():assert()
		local card = T.force_card(1, "S_5")

		test:mock("pseudorandom", 0.1)
		QOL_BUNDLE.utils.try_apply_clip(card, "qol_pb_clip_a")
		test:clear_all_mocks()
		test:assert_true(PB_UTIL.has_paperclip(card) == nil, "below the 20% threshold nothing should apply")
		test:assert_true(_G.has_paperclip == nil and _G.clip_chance == nil,
			"the clip helper must not leak has_paperclip/clip_chance into _G")

		test:mock("pseudorandom", 0.9)
		QOL_BUNDLE.utils.try_apply_clip(card, "qol_pb_clip_b")
		test:clear_all_mocks()
		test:assert_true(PB_UTIL.has_paperclip(card) ~= nil, "above the threshold a paperclip should be applied")

		test:mock("pseudorandom", 0.1)
		QOL_BUNDLE.utils.try_apply_clip(card, "qol_pb_clip_c")
		test:clear_all_mocks()
		test:assert_true(PB_UTIL.has_paperclip(card) ~= nil, "an already clipped card stays clipped (guaranteed)")
	end)

	-- The PB-only Jester of Nihil rework.
	BInt.register_test("riosodu/pb/pb_jester_of_nihil_rework", function(test)
		test:assert_true(QOL_BUNDLE.state.jester_of_nihil ~= nil, "the PB-only rework should take ownership at load")
		T.start_run(test, "QOL_PB_JON_1", 1)
		test:select_blind():assert()

		-- PB's add_to_deck hook debuffs every card of the Joker's suit (adopted
		-- from the run's last scored suit), so park a card of a DIFFERENT suit
		-- first and count the actual debuffed suit after the spawn.
		local suit = (G.GAME.paperback and G.GAME.paperback.last_scored_suit) or "Spades"
		local letters = { Spades = "S", Hearts = "H", Diamonds = "D", Clubs = "C" }
		local letter = letters[suit] or "S"
		local other = letter == "H" and "S" or "H"
		local wild_candidate = T.force_card(1, other .. "_2")

		test:spawn_joker("j_paperback_jester_of_nihil"):assert()

		local jon = G.jokers.cards[1]
		local center = jon.config.center
		test:assert_eq(jon.ability.extra.suit, suit, "the Joker should adopt the run's last scored suit")
		local debuffed = 0
		for _, c in ipairs(G.playing_cards) do
			if c.base.suit == suit then
				debuffed = debuffed + 1
			end
		end
		test:assert_gt(debuffed, 0, "the deck should hold cards of the Joker's suit")
		test:assert_eq(jon.ability.extra.mult, debuffed * 5, "every debuffed suit card should give +5 Mult")

		-- The rework also counts Wild Cards (PB's original only counted debuffed cards).
		wild_candidate:set_ability(G.P_CENTERS.m_wild)
		center.update(center, jon, 0)
		test:assert_eq(jon.ability.extra.mult, (debuffed + 1) * 5, "a Wild Card should add another +5 Mult")
	end)

	-- Da Capo (PB): debuffs every card that does not match its rotating suit.
	-- It must keep working under the wildcard/blurred fix: Wild Cards match every
	-- suit (never debuffed) and Smeared makes same-shade cards match.
	-- The suit is set before the spawn: Da Capo's add_to_deck hook runs the
	-- debuff pass immediately (default suit is Clubs, per PB's run hook).
	BInt.register_test("riosodu/pb/pb_da_capo_baseline_debuff", function(test)
		T.start_run(test, "QOL_PB_CAPO_1", 1)
		test:select_blind():assert()

		G.GAME.paperback.da_capo_suit = "Spades"
		local heart = T.force_card(1, "H_5")
		local spade = T.force_card(2, "S_5")

		test:spawn_joker("j_paperback_da_capo"):assert()
		test:assert_true(heart.debuff == true, "an off-suit card should be debuffed")
		test:assert_true(spade.debuff ~= true, "an on-suit card should not be debuffed")
	end)

	BInt.register_test("riosodu/pb/pb_da_capo_wildcard_matches_all", function(test)
		T.start_run(test, "QOL_PB_CAPO_2", 1)
		test:select_blind():assert()

		G.GAME.paperback.da_capo_suit = "Spades"
		local wild = T.force_card(1, "H_5")
		wild:set_ability(G.P_CENTERS.m_wild)

		test:spawn_joker("j_paperback_da_capo"):assert()
		test:assert_true(wild.debuff ~= true, "a Wild Card matches every suit and must not be debuffed")
	end)

	BInt.register_test("riosodu/pb/pb_da_capo_smeared_shade", function(test)
		T.start_run(test, "QOL_PB_CAPO_3", 1)
		test:select_blind():assert()
		test:spawn_joker("j_smeared"):assert()

		G.GAME.paperback.da_capo_suit = "Diamonds"
		local heart = T.force_card(1, "H_5") -- light shade: matches Diamonds under Smeared
		local spade = T.force_card(2, "S_5") -- dark shade

		test:spawn_joker("j_paperback_da_capo"):assert()
		test:assert_true(heart.debuff ~= true, "a same-shade card should match under Smeared")
		test:assert_true(spade.debuff == true, "an opposite-shade card should be debuffed")
	end)

	-- Smeared must consider Paperback's custom suits (Stars = light, Crowns =
	-- dark), not just the vanilla red/black grouping (v1.8.0 claim).
	BInt.register_test("riosodu/pb/pb_smeared_custom_suit_shade", function(test)
		T.apply_feature("wildcard_fix_enabled", "j_smeared", F.get_ownership_joker_smeared)
		T.start_run(test, "QOL_PB_SMEARED_2", 1)
		test:select_blind():assert()
		test:spawn_joker("j_smeared"):assert()

		test:assert_eq(QOL_BUNDLE.utils.get_suit_shade("paperback_Stars"), "light", "Stars should be a light suit")
		test:assert_eq(QOL_BUNDLE.utils.get_suit_shade("paperback_Crowns"), "dark", "Crowns should be a dark suit")

		local stars = T.force_card(1, "S_5")
		stars.base.suit = "paperback_Stars"
		local crowns = T.force_card(2, "S_5")
		crowns.base.suit = "paperback_Crowns"

		test:assert_true(stars:is_suit("Diamonds"), "a Stars card should match the light shade")
		test:assert_false(stars:is_suit("Spades"), "a Stars card must not match the dark shade")
		test:assert_true(crowns:is_suit("Spades"), "a Crowns card should match the dark shade")
		test:assert_false(crowns:is_suit("Diamonds"), "a Crowns card must not match the light shade")
	end)

	-- PB text variants selected at runtime.
	BInt.register_test("riosodu/pb/pb_spectral_and_voucher_texts", function(test)
		T.refresh_loc()

		test:assert_true(G.localization.descriptions.Spectral.c_familiar.text == localize('c_familiar_upgraded_paperback'),
			"Familiar should show the PB upgraded text")
		test:assert_true(G.localization.descriptions.Spectral.c_grim.text == localize('c_grim_upgraded_paperback'),
			"Grim should show the PB upgraded text")
		test:assert_true(G.localization.descriptions.Spectral.c_incantation.text == localize('c_incantation_upgraded_paperback'),
			"Incantation should show the PB upgraded text")
		test:assert_true(G.localization.descriptions.Voucher.v_magic_trick.text == localize('v_magic_trick_paperback'),
			"Magic Trick should show the PB text")
	end)
end
