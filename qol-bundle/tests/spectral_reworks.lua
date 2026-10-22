-- qol-bundle/tests/spectral_reworks.lua
-- Wraith / Ankh / Hex beta reworks (all default off).
--
-- Wraith: duplicates a random Joker and makes every other Joker Perishable
--         (Eternal Jokers are skipped, money is untouched, no Rare Joker).
-- Ankh:   strips every sticker (vanilla + modded) from every Joker, then up to
--         two random Eternal-compatible Jokers become Eternal.
-- Hex:    gives Polychrome AND one random applicable sticker to the same
--         random Joker; no other Joker is destroyed or modified.

return function(T)
	local F = QOL_BUNDLE.funcs

	local function setup(test, seed, config_key, center_key, getter)
		T.apply_feature(config_key, center_key, getter)
		T.start_run(test, seed, 1)
		test:select_blind():assert()
	end

	local function count_eternal()
		local n = 0
		for _, joker in ipairs(G.jokers.cards) do
			if joker.ability.eternal then
				n = n + 1
			end
		end
		return n
	end

	-- === Wraith ==========================================================

	BInt.register_test("riosodu/qol_bundle/beta_wraith_duplicates_and_perishables", function(test)
		setup(test, "QOL_BETA_WRAITH_1", "wraith_rework_enabled", "c_wraith",
			F.get_ownership_spectral_wraith)
		test:spawn_joker("j_joker"):assert()
		test:spawn_joker("j_greedy_joker"):assert()
		test:spawn_joker("j_misprint"):assert()
		test:spawn_consumable("c_wraith"):assert()

		local eternal = G.jokers.cards[1]
		eternal:set_eternal(true)
		test:assert_true(eternal.ability.eternal, "precondition: the first Joker is Eternal")

		local dollars_before = G.GAME.dollars
		local jokers_before = #G.jokers.cards

		-- Chosen Joker: index 2 in G.jokers.cards.
		test:mock("pseudorandom_element", 2)
		test:use_consumable("c_wraith"):assert()
		test:clear_all_mocks()
		BInt._wait.stable_drain()

		test:assert_eq(#G.jokers.cards, jokers_before + 1, "Wraith should add exactly one copy")
		test:assert_eq(G.GAME.dollars, dollars_before, "Wraith must not set money to $0")

		local chosen = G.jokers.cards[2]
		local copy = G.jokers.cards[#G.jokers.cards]
		test:assert_eq(copy.config.center.key, chosen.config.center.key,
			"the new Joker should be a copy of the chosen Joker")
		test:assert_true(not chosen.ability.perishable, "the chosen Joker must not become Perishable")
		test:assert_true(not copy.ability.perishable, "the copy must not become Perishable")
		test:assert_true(not eternal.ability.perishable, "Eternal Jokers must not become Perishable")
		test:assert_true(G.jokers.cards[3].ability.perishable == true,
			"every other Joker should become Perishable")
	end)

	BInt.register_test("riosodu/qol_bundle/beta_wraith_single_joker", function(test)
		setup(test, "QOL_BETA_WRAITH_2", "wraith_rework_enabled", "c_wraith",
			F.get_ownership_spectral_wraith)
		test:spawn_joker("j_joker"):assert()
		test:spawn_consumable("c_wraith"):assert()

		test:mock("pseudorandom_element", 1)
		test:use_consumable("c_wraith"):assert()
		test:clear_all_mocks()
		BInt._wait.stable_drain()

		test:assert_eq(#G.jokers.cards, 2, "a single Joker should be duplicated")
		test:assert_true(not G.jokers.cards[1].ability.perishable,
			"the single source Joker must not become Perishable")
		test:assert_true(not G.jokers.cards[2].ability.perishable,
			"the copy must not become Perishable")
	end)

	-- === Ankh ============================================================

	BInt.register_test("riosodu/qol_bundle/beta_ankh_strips_stickers_and_eternals_two", function(test)
		setup(test, "QOL_BETA_ANKH_1", "ankh_rework_enabled", "c_ankh",
			F.get_ownership_spectral_ankh)
		test:spawn_joker("j_joker"):assert()
		test:spawn_joker("j_greedy_joker"):assert()
		test:spawn_joker("j_misprint"):assert()
		test:spawn_joker("j_abstract"):assert()
		test:spawn_joker("j_blue_joker"):assert()
		test:spawn_consumable("c_ankh"):assert()

		local a, b, c, d, e = G.jokers.cards[1], G.jokers.cards[2], G.jokers.cards[3],
			G.jokers.cards[4], G.jokers.cards[5]

		-- Three starters are Eternal: if Ankh failed to strip Eternal first,
		-- the final Eternal count would stay above two.
		a:set_eternal(true)
		b:set_eternal(true)
		c:set_eternal(true)
		d:set_perishable(true)
		e:set_rental(true)
		a:add_sticker("pinned", true)
		test:assert_eq(count_eternal(), 3, "precondition: three Eternal Jokers")
		test:assert_true(d.ability.perishable, "precondition: a Perishable sticker is present")
		test:assert_true(e.ability.rental, "precondition: a Rental sticker is present")
		test:assert_true(a.pinned, "precondition: a SMODS-only sticker is present")

		test:use_consumable("c_ankh"):assert()
		BInt._wait.stable_drain()

		test:assert_eq(#G.jokers.cards, 5, "Ankh must not destroy or copy Jokers")
		test:assert_eq(count_eternal(), 2,
			"exactly two random Jokers should become Eternal (the three starters must be stripped first)")
		for i, joker in ipairs({ a, b, c, d, e }) do
			test:assert_true(not joker.ability.perishable, "Joker #" .. i .. " should lose Perishable")
			test:assert_true(not joker.ability.rental, "Joker #" .. i .. " should lose Rental")
			test:assert_true(not joker.pinned, "Joker #" .. i .. " should lose the modded sticker")
		end
	end)

	BInt.register_test("riosodu/qol_bundle/beta_ankh_fewer_than_two_jokers", function(test)
		setup(test, "QOL_BETA_ANKH_2", "ankh_rework_enabled", "c_ankh",
			F.get_ownership_spectral_ankh)
		test:spawn_joker("j_joker"):assert()
		test:spawn_consumable("c_ankh"):assert()

		G.jokers.cards[1]:set_eternal(true)
		test:use_consumable("c_ankh"):assert()
		BInt._wait.stable_drain()

		test:assert_eq(count_eternal(), 1, "with one Joker, Ankh should make it Eternal")
	end)

	-- === Hex =============================================================

	BInt.register_test("riosodu/qol_bundle/beta_hex_polychrome_and_sticker_on_one_joker", function(test)
		setup(test, "QOL_BETA_HEX_1", "hex_rework_enabled", "c_hex",
			F.get_ownership_spectral_hex)
		test:spawn_joker("j_joker"):assert()
		test:spawn_joker("j_greedy_joker"):assert()
		test:spawn_joker("j_misprint"):assert()
		test:spawn_consumable("c_hex"):assert()

		local jokers_before = #G.jokers.cards

		-- Target: index 2. Sticker: index 2 of the candidate list (Perishable,
		-- since the target has no incompatible stickers).
		test:mock("pseudorandom_element", 2)
		test:mock("pseudorandom_element", 2)
		test:use_consumable("c_hex"):assert()
		test:clear_all_mocks()
		BInt._wait.stable_drain()

		local target = G.jokers.cards[2]
		test:assert_eq(#G.jokers.cards, jokers_before, "Hex must not destroy any Joker")
		test:assert_true(target.edition and target.edition.polychrome,
			"the target Joker should gain Polychrome")
		test:assert_true(target.ability.perishable == true,
			"the same Joker should gain the rolled sticker")
		for i, joker in ipairs(G.jokers.cards) do
			if i ~= 2 then
				test:assert_true(not joker.edition, "other Jokers must not gain an edition")
				test:assert_true(not joker.ability.eternal and not joker.ability.perishable
					and not joker.ability.rental, "other Jokers must not gain a sticker")
			end
		end
	end)

	BInt.register_test("riosodu/qol_bundle/beta_hex_never_perishable_on_eternal", function(test)
		setup(test, "QOL_BETA_HEX_2", "hex_rework_enabled", "c_hex",
			F.get_ownership_spectral_hex)
		test:spawn_joker("j_joker"):assert()
		test:spawn_consumable("c_hex"):assert()

		local target = G.jokers.cards[1]
		target:set_eternal(true)
		test:assert_true(target.ability.eternal, "precondition: the target is Eternal")

		-- The Perishable slot in the candidate list no longer exists once the
		-- target is Eternal: the only applicable sticker left is Rental.
		test:mock("pseudorandom_element", 1)
		test:mock("pseudorandom_element", 1)
		test:use_consumable("c_hex"):assert()
		test:clear_all_mocks()
		BInt._wait.stable_drain()

		test:assert_true(target.edition and target.edition.polychrome,
			"the Eternal Joker should still gain Polychrome")
		test:assert_true(not target.ability.perishable,
			"an Eternal Joker must never become Perishable")
		test:assert_true(target.ability.rental == true,
			"the fallback sticker should come from the filtered candidate list")
	end)
end
