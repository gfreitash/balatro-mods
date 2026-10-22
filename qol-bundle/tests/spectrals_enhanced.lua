-- qol-bundle/tests/spectrals_enhanced.lua
-- Baseline check for the spectral seal/clip feature.
--
-- With the QoL feature disabled, Familiar / Grim / Incantation create cards
-- through the vanilla `create_playing_card` call, which applies neither seals
-- nor editions. This samples that creation 1000 times per spectral using the
-- exact inputs the vanilla code passes (rank/suit picks + the Enhanced pool),
-- but does not emplace or animate the cards, so the sample stays fast.

return function(T)
	local SAMPLE_CARDS = 1000

	local function enhanced_pool()
		local pool = {}
		for _, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
			-- Vanilla excludes Stone from the spectral Enhanced pool.
			if v.key ~= 'm_stone' then
				pool[#pool + 1] = v
			end
		end
		return pool
	end

	-- Mirrors the rank/suit picks in vanilla Card:use_consumeable.
	local spec_inputs = {
		familiar = function()
			return pseudorandom_element({ 'J', 'Q', 'K' }, pseudoseed('familiar_create')),
				pseudorandom_element({ 'S', 'H', 'D', 'C' }, pseudoseed('familiar_create'))
		end,
		grim = function()
			return 'A', pseudorandom_element({ 'S', 'H', 'D', 'C' }, pseudoseed('grim_create'))
		end,
		incantation = function()
			return pseudorandom_element({ '2', '3', '4', '5', '6', '7', '8', '9', 'T' }, pseudoseed('incantation_create')),
				pseudorandom_element({ 'S', 'H', 'D', 'C' }, pseudoseed('incantation_create'))
		end,
	}

	-- One real creation call, without area/emplace/materialize, discarded
	-- immediately so G.I.CARD and G.playing_cards stay small.
	local function sample_card(pool, pick)
		local rank, suit = pick()
		local card = create_playing_card({
			front = G.P_CARDS[suit .. '_' .. rank],
			center = pseudorandom_element(pool, pseudoseed('spe_card')),
		}, nil, true)
		local seal = card.seal
		local edition = card.edition and card.edition.key or nil
		local enhanced = card.ability.set == 'Enhanced'
		card:remove()
		return seal, edition, enhanced
	end

	BInt.register_test("riosodu/qol_bundle/beta_spectrals_vanilla_adds_no_seals_or_editions", function(test)
		test:assert_false(QOL_BUNDLE.config.spectral_seal_clip_enabled,
			"the seal/clip feature must be off for this baseline check")
		T.start_run(test, "QOL_SPECTRAL_BASELINE_1", 1)
		test:select_blind():assert()

		local pool = enhanced_pool()
		test:assert_true(#pool > 0, "the Enhanced pool must not be empty")

		for name, pick in pairs(spec_inputs) do
			local seals, editions, not_enhanced = 0, 0, 0
			local first_seal, first_edition
			for _ = 1, SAMPLE_CARDS do
				local seal, edition, enhanced = sample_card(pool, pick)
				if seal then
					seals = seals + 1
					first_seal = first_seal or seal
				end
				if edition then
					editions = editions + 1
					first_edition = first_edition or edition
				end
				if not enhanced then
					not_enhanced = not_enhanced + 1
				end
			end
			-- Control: the sample must really be creating the Enhanced cards
			-- these spectrals produce, or the seal/edition result is meaningless.
			test:assert_eq(not_enhanced, 0, string.format(
				"%s: %d/%d sampled cards were not Enhanced", name, not_enhanced, SAMPLE_CARDS))
			test:assert_eq(seals, 0, string.format(
				"%s created %d/%d sealed cards without the QoL feature (first: %s)",
				name, seals, SAMPLE_CARDS, tostring(first_seal)))
			test:assert_eq(editions, 0, string.format(
				"%s created %d/%d edition cards without the QoL feature (first: %s)",
				name, editions, SAMPLE_CARDS, tostring(first_edition)))
		end
	end)
end
