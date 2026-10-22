-- qol-bundle/tests/hit_the_road_repro.lua
-- Regression tests for the reworked "Hit the Road"
-- (src/content/joker/hit_the_road.lua): the joker returns the discarded Jacks
-- to the deck and shuffles it, so repeated discards must not bring back the
-- exact same Jacks in the same order ("I draw the same ones, in the same
-- order").
--
-- The original bug: the mod shuffled synchronously inside the event that only
-- QUEUES the draw_card returns, so the shuffle ran before the Jacks were back
-- in the deck, and every return re-sorted the deck canonically (draw_card
-- passes sort = true; get_nominal() is a total order). The fix queues the
-- shuffle as a follow-up event after the returns; these tests pin that down.
--
-- Test set (all four assert the fixed mechanics):
--  * hit_the_road_cycles_repeat (all-Jack deck, equivalent cycles):
--    the shuffle must see the five returned Jacks (deck_size == jacks == 5),
--    and the two same-seed-string shuffles must produce different deck orders
--    (pseudoseed advances a per-key counter on every call, so a repeated tuple
--    is not a repeated permutation key).
--  * hit_the_road_mixed_deck / hit_the_road_more_jacks (identity probes):
--    which Jacks the refill draws back must differ across equivalent cycles.
--  * hit_the_road_multi_discard: consecutive discards in one round reach
--    different seed tuples; the drawn-back Jack identity must differ.
--
-- The deck-shuffle wrapper is diagnostic only: it records the seed string, the
-- deck contents at/after shuffle time and the Jack count for failure messages.
-- It only appends to a local table and delegates.

return function(T)
	local F = QOL_BUNDLE.funcs

	-- "S_Jack#56"-style label: suit, rank and the unique per-card number.
	local function describe_order(order)
		local parts = {}
		for i, card in ipairs(order) do
			local value = card.base and card.base.value or "?"
			local suit = card.base and card.base.suit or "?"
			parts[i] = suit:sub(1, 1) .. "_" .. value .. "#" .. tostring(card.playing_card or card.ID)
		end
		return "[" .. table.concat(parts, ", ") .. "]"
	end

	local function same_order(a, b)
		if #a ~= #b then
			return false
		end
		for i = 1, #a do
			if a[i] ~= b[i] then
				return false
			end
		end
		return true
	end

	-- --- Helpers for the mixed-deck variants -------------------------------

	local function copy_cards(cards)
		local copy = {}
		for i, card in ipairs(cards) do
			copy[i] = card
		end
		return copy
	end

	local function jacks_in(area)
		local jacks = {}
		for _, card in ipairs(area.cards) do
			if card.base and card.base.value == "Jack" then
				jacks[#jacks + 1] = card
			end
		end
		return jacks
	end

	--- Removes every run-deck card not listed in keep_ids (short ids like
	--- "Js"/"10s"; one occurrence per entry) so the variants start from a
	--- controlled small deck.
	local function thin_run_deck_to(keep_ids)
		local keep = {}
		for _, id in ipairs(keep_ids) do
			keep[id] = (keep[id] or 0) + 1
		end
		for _, card in ipairs(copy_cards(G.playing_cards)) do
			local id = BInt._resolve.card_to_id(card)
			if (keep[id] or 0) > 0 then
				keep[id] = keep[id] - 1
			else
				card:remove()
			end
		end
	end

	--- Picks card objects by short id, consuming occurrences in G.playing_cards
	--- order (so a repeated id picks the original before an added duplicate).
	local function pick_cards(ids)
		local pool = {}
		for _, card in ipairs(G.playing_cards) do
			local id = BInt._resolve.card_to_id(card)
			pool[id] = pool[id] or {}
			table.insert(pool[id], card)
		end
		local picked = {}
		for _, id in ipairs(ids) do
			local bucket = pool[id]
			if not bucket or #bucket == 0 then
				error("pick_cards: no card available for id " .. id)
			end
			picked[#picked + 1] = table.remove(bucket, 1)
		end
		return picked
	end

	--- Shapes the scenario synchronously: every playing card goes into the
	--- deck, then `hand_cards` moves into the hand. Same primitive moves
	--- draw_card performs at the event level (remove_card + emplace).
	local function set_scenario_state(hand_cards)
		while G.hand.highlighted[1] do
			G.hand:remove_from_highlighted(G.hand.highlighted[1])
		end
		for _, card in ipairs(G.playing_cards) do
			if card.area and card.area ~= G.deck then
				card.area:remove_card(card)
				G.deck:emplace(card)
			end
		end
		for _, card in ipairs(hand_cards) do
			G.deck:remove_card(card)
			G.hand:emplace(card)
		end
	end

	--- Wraps G.deck:shuffle to log {seed, deck_size, jacks_in_deck, deck_order,
	--- deck_order_after} per call; returns a restore function. The order
	--- snapshots are copies: pseudoshuffle permutes the area's own table in
	--- place.
	local function install_shuffle_probe(log)
		local original = G.deck.shuffle
		G.deck.shuffle = function(self, seed, ...)
			local entry = {
				seed = seed,
				deck_size = #self.cards,
				jacks_in_deck = #jacks_in(self),
				deck_order = copy_cards(self.cards),
			}
			table.insert(log, entry)
			local result = original(self, seed, ...)
			entry.deck_order_after = copy_cards(self.cards)
			return result
		end
		return function()
			G.deck.shuffle = nil
		end
	end

	local function hit_road_shuffles_in(log)
		local hit_road = {}
		for _, entry in ipairs(log) do
			if type(entry.seed) == "string" and entry.seed:find("j_hit_the_road_shuffle", 1, true) then
				table.insert(hit_road, entry)
			end
		end
		return hit_road
	end

	local function describe_shuffle_entry(entry)
		return "seed '" .. tostring(entry.seed) .. "', deck at shuffle time: "
			.. entry.deck_size .. " cards / " .. entry.jacks_in_deck .. " Jacks"
	end

	BInt.register_test("riosodu/qol_bundle/hit_the_road_cycles_repeat", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_HIT_ROAD_1", 1)

		-- Thin the deck to the four Jacks plus one added duplicate, so the whole
		-- hand (and the post-discard refill) consists of exactly five Jacks.
		local ranks = { "2", "3", "4", "5", "6", "7", "8", "9", "10", "Q", "K", "A" }
		local suits = { "s", "h", "d", "c" }
		for _, rank in ipairs(ranks) do
			for _, suit in ipairs(suits) do
				local id = rank .. suit
				test:assert_true(T.remove_deck_card(id), "deck card " .. id .. " should exist")
			end
		end
		test:add_playing_card("Js"):assert()

		test:select_blind():assert()
		test:spawn_joker("j_hit_the_road"):assert()

		local function wait_for_five_jack_hand()
			BInt._wait.for_condition(function()
				return G.hand and #G.hand.cards == 5
			end, 10, "Timeout waiting for the five-Jack hand")
			test:assert_eq(#G.hand.cards, 5, "the whole hand should be five Jacks")
			for _, card in ipairs(G.hand.cards) do
				test:assert_eq(card.base.value, "Jack", "every hand card should be a Jack")
			end
		end

		-- Diagnostic: record every deck shuffle, the deck contents at that
		-- moment and the deck order after the shuffle (the mod shuffles G.deck
		-- once per Hit the Road discard).
		local shuffle_log = {}
		local restore_shuffle = install_shuffle_probe(shuffle_log)

		--- Discards the whole (all-Jack) hand and returns the hand order after
		--- the deck refill -- the Jacks the player draws back.
		local function discard_all_jacks()
			wait_for_five_jack_hand()
			test:highlight({ 1, 2, 3, 4, 5 }):assert()
			test:discard():assert()
			wait_for_five_jack_hand()
			BInt._wait.stable_drain()
			local order = {}
			for i, card in ipairs(G.hand.cards) do
				order[i] = card
			end
			return order
		end

		-- Cycle 1: first discard of the Small blind.
		local cycle_1 = discard_all_jacks()

		-- Cycle 2: same setup in the next round -> same seed tuple.
		test:go_to_shop():assert()
		test:leave_shop():assert()
		test:select_blind():assert()
		local cycle_2 = discard_all_jacks()

		restore_shuffle()

		local hit_road_shuffles = hit_road_shuffles_in(shuffle_log)
		test:assert_eq(#hit_road_shuffles, 2, "expected one Hit the Road shuffle per discard cycle")
		test:assert_eq(
			hit_road_shuffles[1].seed,
			hit_road_shuffles[2].seed,
			"the two cycles should reach the same shuffle seed tuple"
		)

		-- Mechanism (a): the shuffle must run AFTER the returned Jacks are back
		-- in the deck -- in this all-Jack scenario the deck holds exactly the
		-- five returned Jacks when the shuffle executes.
		for i, entry in ipairs(hit_road_shuffles) do
			test:assert_eq(
				entry.jacks_in_deck,
				5,
				"cycle " .. i .. " shuffle should see the five returned Jacks in the deck ("
					.. describe_shuffle_entry(entry) .. ")"
			)
			test:assert_eq(
				entry.deck_size,
				5,
				"cycle " .. i .. " shuffle should see a five-card deck of Jacks ("
					.. describe_shuffle_entry(entry) .. ")"
			)
		end

		-- Diagnostic probe (does not alter game behavior: pseudoseed advances a
		-- per-key counter, so a one-off key is used and cleared afterwards):
		-- the repeated seed tuple does NOT translate to the same pseudoshuffle
		-- seed -- pseudoseed() mutates G.GAME.pseudorandom[key] on every call
		-- (misc_functions.lua:298-313), so a repeated key returns a new value.
		local probe_key = "qol_htr_repro_seed_probe"
		local probe_1 = pseudoseed(probe_key)
		local probe_2 = pseudoseed(probe_key)
		G.GAME.pseudorandom[probe_key] = nil

		-- Mechanism (b): the shuffle must actually permute the returned Jacks.
		-- The two cycles share the seed string, but pseudoseed() advances a
		-- per-key counter on every call, so the permutations must differ.
		test:assert_true(
			not same_order(hit_road_shuffles[1].deck_order_after, hit_road_shuffles[2].deck_order_after),
			"two equivalent cycles should shuffle the returned Jacks into different deck orders -- "
				.. "cycle 1: " .. describe_shuffle_entry(hit_road_shuffles[1]) .. ", after shuffle "
				.. describe_order(hit_road_shuffles[1].deck_order_after) .. "; "
				.. "cycle 2: " .. describe_shuffle_entry(hit_road_shuffles[2]) .. ", after shuffle "
				.. describe_order(hit_road_shuffles[2].deck_order_after) .. ". "
				.. "(pseudoseed('" .. probe_key .. "') twice in a row: "
				.. string.format("%.13f", probe_1) .. " vs " .. string.format("%.13f", probe_2) .. ")"
		)

		test:log(
			"five returned Jacks shuffled into different deck orders: cycle 1 "
				.. describe_order(hit_road_shuffles[1].deck_order_after) .. ", cycle 2 "
				.. describe_order(hit_road_shuffles[2].deck_order_after)
		)
	end)

	-- === Variant 1: mixed deck ==============================================
	-- Hand and deck contain non-Jacks, so the refill actually chooses which of
	-- the returned Jacks are drawn back; a working deck shuffle would change
	-- that choice across equivalent cycles (its pseudoseed differs per call).
	BInt.register_test("riosodu/qol_bundle/hit_the_road_mixed_deck", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_HIT_ROAD_MIX", 1)

		-- 12-card deck: four Jacks + two high cards (sort above the Jacks) +
		-- four numbered cards (sort below) + two more numbered cards that stay
		-- in the deck while the Jacks are being discarded. Note the card-id
		-- format: tens are "10s"/"10h" (BInt._resolve.RANK_MAP).
		thin_run_deck_to({ "Js", "Jh", "Jd", "Jc", "Ks", "Kh", "10s", "10h", "5s", "4s", "3s", "2s" })

		test:select_blind():assert()
		BInt._wait.stable_drain()
		test:spawn_joker("j_hit_the_road"):assert()

		local shuffle_log = {}
		local restore_shuffle = install_shuffle_probe(shuffle_log)

		-- Scenario hand: the four Jacks + 10s, 10h, 5s, 4s; the deck keeps Ks,
		-- Kh, 3s, 2s. Discarding four Jacks leaves an eight-card deck while
		-- the refill only draws four, so the canonical deck order decides
		-- which Jacks come back (the two lowest: Jd, Jc) and which stay.
		local scenario_hand = pick_cards({ "Js", "Jh", "Jd", "Jc", "10s", "10h", "5s", "4s" })

		local function run_cycle()
			set_scenario_state(scenario_hand)
			test:assert_eq(#G.hand.cards, 8, "scenario hand size")
			local jack_indices = {}
			for i, card in ipairs(G.hand.cards) do
				if card.base.value == "Jack" then
					jack_indices[#jack_indices + 1] = i
				end
			end
			test:assert_eq(#jack_indices, 4, "the scenario hand should hold four Jacks")
			test:highlight(jack_indices):assert()
			test:discard():assert()
			BInt._wait.for_condition(function()
				return #G.hand.cards == 8
			end, 10, "Timeout waiting for the mixed-deck refill")
			BInt._wait.stable_drain()
			return {
				hand_order = copy_cards(G.hand.cards),
				deck_order = copy_cards(G.deck.cards),
				drawn_jacks = jacks_in(G.hand),
				deck_jacks = jacks_in(G.deck),
			}
		end

		local cycle_1 = run_cycle()

		test:go_to_shop():assert()
		test:leave_shop():assert()
		test:select_blind():assert()
		BInt._wait.stable_drain()
		local cycle_2 = run_cycle()

		restore_shuffle()

		local hit_road_shuffles = hit_road_shuffles_in(shuffle_log)
		test:assert_eq(#hit_road_shuffles, 2, "expected one Hit the Road shuffle per discard cycle")
		test:assert_eq(
			hit_road_shuffles[1].seed,
			hit_road_shuffles[2].seed,
			"the two cycles should reach the same shuffle seed tuple"
		)

		local function describe_cycle(cycle)
			return "{hand " .. describe_order(cycle.hand_order)
				.. ", deck " .. describe_order(cycle.deck_order)
				.. ", Jacks drawn back " .. describe_order(cycle.drawn_jacks)
				.. ", Jacks left in deck " .. describe_order(cycle.deck_jacks) .. "}"
		end

		test:assert_true(
			not same_order(cycle_1.drawn_jacks, cycle_2.drawn_jacks),
			"mixed deck: the refill drew back the same Jacks on two equivalent cycles -- "
				.. "a shuffled deck should change which of the returned Jacks are drawn. "
				.. "cycle 1 shuffle: " .. describe_shuffle_entry(hit_road_shuffles[1]) .. "; "
				.. "cycle 2 shuffle: " .. describe_shuffle_entry(hit_road_shuffles[2]) .. ". "
				.. "cycle 1: " .. describe_cycle(cycle_1) .. ". "
				.. "cycle 2: " .. describe_cycle(cycle_2)
		)

		test:log(
			"mixed deck drew back different Jacks per cycle: cycle 1 "
				.. describe_order(cycle_1.drawn_jacks) .. " (deck at shuffle "
				.. describe_order(hit_road_shuffles[1].deck_order) .. ", after shuffle "
				.. describe_order(hit_road_shuffles[1].deck_order_after) .. "), cycle 2 "
				.. describe_order(cycle_2.drawn_jacks)
		)
	end)

	-- === Variant 2: more Jacks than the refill draws ========================
	-- Seven Jacks in a ten-card deck; five are discarded and the refill draws
	-- five, so "the same ones" is card identity: the canonical deck order
	-- decides which five of the seven return (and the same two stay behind).
	BInt.register_test("riosodu/qol_bundle/hit_the_road_more_jacks", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_HIT_ROAD_MANY", 1)

		-- Ten-card deck: four Jacks + three added Jack duplicates + 2s, 3s, 4s.
		thin_run_deck_to({ "Js", "Jh", "Jd", "Jc", "2s", "3s", "4s" })
		test:add_playing_card("Js"):assert()
		test:add_playing_card("Jh"):assert()
		test:add_playing_card("Jc"):assert()

		test:select_blind():assert()
		BInt._wait.stable_drain()
		test:spawn_joker("j_hit_the_road"):assert()

		local shuffle_log = {}
		local restore_shuffle = install_shuffle_probe(shuffle_log)

		-- Scenario hand: five Jacks (both Spades, both Hearts, one Diamond) +
		-- the three low cards. The deck keeps the two Club Jacks.
		local scenario_hand = pick_cards({ "Js", "Js", "Jh", "Jh", "Jd", "2s", "3s", "4s" })

		local function run_cycle()
			set_scenario_state(scenario_hand)
			test:assert_eq(#G.hand.cards, 8, "scenario hand size")
			local jack_indices = {}
			for i, card in ipairs(G.hand.cards) do
				if card.base.value == "Jack" then
					jack_indices[#jack_indices + 1] = i
				end
			end
			test:assert_eq(#jack_indices, 5, "the scenario hand should hold five Jacks")
			test:highlight(jack_indices):assert()
			test:discard():assert()
			BInt._wait.for_condition(function()
				return #G.hand.cards == 8
			end, 10, "Timeout waiting for the seven-Jack refill")
			BInt._wait.stable_drain()
			return {
				hand_order = copy_cards(G.hand.cards),
				deck_order = copy_cards(G.deck.cards),
				drawn_jacks = jacks_in(G.hand),
				deck_jacks = jacks_in(G.deck),
			}
		end

		local cycle_1 = run_cycle()

		test:go_to_shop():assert()
		test:leave_shop():assert()
		test:select_blind():assert()
		BInt._wait.stable_drain()
		local cycle_2 = run_cycle()

		restore_shuffle()

		local hit_road_shuffles = hit_road_shuffles_in(shuffle_log)
		test:assert_eq(#hit_road_shuffles, 2, "expected one Hit the Road shuffle per discard cycle")
		test:assert_eq(
			hit_road_shuffles[1].seed,
			hit_road_shuffles[2].seed,
			"the two cycles should reach the same shuffle seed tuple"
		)

		local function describe_cycle(cycle)
			return "{hand " .. describe_order(cycle.hand_order)
				.. ", deck " .. describe_order(cycle.deck_order)
				.. ", Jacks drawn back " .. describe_order(cycle.drawn_jacks)
				.. ", Jacks left in deck " .. describe_order(cycle.deck_jacks) .. "}"
		end

		test:assert_true(
			not same_order(cycle_1.drawn_jacks, cycle_2.drawn_jacks),
			"more Jacks than the refill draws: the same five Jacks came back on two equivalent cycles -- "
				.. "a shuffled seven-Jack deck should change which five are drawn. "
				.. "cycle 1 shuffle: " .. describe_shuffle_entry(hit_road_shuffles[1]) .. "; "
				.. "cycle 2 shuffle: " .. describe_shuffle_entry(hit_road_shuffles[2]) .. ". "
				.. "cycle 1: " .. describe_cycle(cycle_1) .. ". "
				.. "cycle 2: " .. describe_cycle(cycle_2)
		)

		test:log(
			"seven-Jack deck returned different five Jacks per cycle: cycle 1 "
				.. describe_order(cycle_1.drawn_jacks) .. " (left "
				.. describe_order(cycle_1.deck_jacks) .. "), cycle 2 "
				.. describe_order(cycle_2.drawn_jacks) .. " (left "
				.. describe_order(cycle_2.deck_jacks) .. ")"
		)
	end)

	-- === Variant 3: consecutive discards within one round ===================
	-- The mod now shuffles with a fixed seed key; pseudoseed() advances a
	-- per-key counter, so consecutive discards still get different shuffles.
	-- Seven Jacks in a ten-card deck keep the drawn-back identity observable
	-- (5 of 7 return), and playing one low card between discards also varies
	-- the hand counters.
	BInt.register_test("riosodu/qol_bundle/hit_the_road_multi_discard", function(test)
		T.apply_feature("hit_the_road_joker_enabled", "j_hit_the_road", F.get_ownership_joker_hit_the_road)
		T.start_run(test, "QOL_HIT_ROAD_MULTI", 1)

		-- Ten-card deck: four Jacks + three added Jack duplicates + 2s, 3s, 4s.
		thin_run_deck_to({ "Js", "Jh", "Jd", "Jc", "2s", "3s", "4s" })
		test:add_playing_card("Js"):assert()
		test:add_playing_card("Jh"):assert()
		test:add_playing_card("Jc"):assert()

		test:select_blind():assert()
		BInt._wait.stable_drain()
		test:spawn_joker("j_hit_the_road"):assert()

		local shuffle_log = {}
		local restore_shuffle = install_shuffle_probe(shuffle_log)

		local scenario_hand = pick_cards({ "Js", "Js", "Jh", "Jh", "Jd", "2s", "3s", "4s" })

		--- Discards `jack_cards` (all of them must be in hand) and records the
		--- Hit-the-Road shuffle entry, the seed counters and the Jacks the
		--- refill actually drew back (post-refill hand Jacks minus the Jacks
		--- that were in hand before the discard and not discarded).
		local function discard_jacks(label, jack_cards)
			local target = {}
			for _, card in ipairs(jack_cards) do
				target[card] = true
			end
			local highlight_indices = {}
			for i, card in ipairs(G.hand.cards) do
				if target[card] then
					highlight_indices[#highlight_indices + 1] = i
				end
			end
			test:assert_eq(#highlight_indices, #jack_cards, label .. ": every target Jack should be in the hand")

			local kept_set = {}
			for _, card in ipairs(jacks_in(G.hand)) do
				if not target[card] then
					kept_set[card] = true
				end
			end
			local counters = {
				hands_played = G.GAME.hands_played,
				hands_left = G.GAME.current_round.hands_left,
				discards_left = G.GAME.current_round.discards_left,
			}

			test:highlight(highlight_indices):assert()
			test:discard():assert()
			BInt._wait.for_condition(function()
				return #G.hand.cards == 8
			end, 10, label .. ": timeout waiting for the refill")
			BInt._wait.stable_drain()

			local entry
			for i = #shuffle_log, 1, -1 do
				local candidate = shuffle_log[i]
				if type(candidate.seed) == "string" and candidate.seed:find("j_hit_the_road_shuffle", 1, true) then
					entry = candidate
					break
				end
			end
			test:assert_true(entry ~= nil, label .. ": expected a Hit the Road shuffle")

			local drawn = {}
			for _, card in ipairs(jacks_in(G.hand)) do
				if not kept_set[card] then
					drawn[#drawn + 1] = card
				end
			end

			return {
				label = label,
				seed = entry.seed,
				counters = counters,
				deck_at_shuffle = entry.deck_order,
				drawn_jacks = drawn,
				hand_jacks = jacks_in(G.hand),
				deck_jacks = jacks_in(G.deck),
			}
		end

		-- Discard 1: first discard of the round.
		set_scenario_state(scenario_hand)
		test:assert_eq(#G.hand.cards, 8, "scenario hand size")
		local records = {}
		records[1] = discard_jacks("discard 1", jacks_in(G.hand))

		-- Play one low card so the next discards' tuples also differ on the
		-- hands axis (hands_left 4 -> 3, G.GAME.hands_played 0 -> 1).
		local low_index
		for i, card in ipairs(G.hand.cards) do
			if card.base.value == "2" then
				low_index = i
				break
			end
		end
		test:assert_true(low_index ~= nil, "the refill should have left the 2s in hand to play")
		test:highlight({ low_index }):assert()
		test:play_hand():assert()
		BInt._wait.for_condition(function()
			return G.GAME.hands_played == 1 and G.GAME.current_round.hands_left == 3
		end, 10, "timeout waiting for the played-card counters")
		BInt._wait.stable_drain()

		-- Discards 2 and 3: the same five Jacks.
		records[2] = discard_jacks("discard 2", records[1].drawn_jacks)
		records[3] = discard_jacks("discard 3", records[2].drawn_jacks)

		restore_shuffle()

		local seeds = {}
		for i, record in ipairs(records) do
			seeds[i] = record.seed
		end

		-- The seed key is fixed; the shuffle variation comes from pseudoseed()'s
		-- advancing per-key counter.
		test:assert_eq(seeds[1], seeds[2], "in-round discards should use the fixed Hit the Road seed")
		test:assert_eq(seeds[2], seeds[3], "in-round discards should use the fixed Hit the Road seed")

		local function describe_record(record)
			return record.label .. " (" .. record.seed
				.. "; hands_played=" .. record.counters.hands_played
				.. ", hands_left=" .. record.counters.hands_left
				.. ", discards_left=" .. record.counters.discards_left
				.. "; deck at shuffle " .. describe_order(record.deck_at_shuffle)
				.. "): drew back " .. describe_order(record.drawn_jacks)
				.. ", hand Jacks " .. describe_order(record.hand_jacks)
				.. ", left in deck " .. describe_order(record.deck_jacks)
		end

		-- Different pseudoseed values must produce different draw outcomes --
		-- the drawn-back Jack sequence must not be identical across the three
		-- discards.
		local all_same = true
		for i = 2, #records do
			if not same_order(records[1].drawn_jacks, records[i].drawn_jacks) then
				all_same = false
			end
		end
		test:assert_true(
			not all_same,
			"consecutive in-round discards drew back the same Jacks in the same order -- "
				.. "the fixed pseudoseed must still produce different shuffles. "
				.. describe_record(records[1]) .. "; "
				.. describe_record(records[2]) .. "; "
				.. describe_record(records[3])
		)

		test:log(
			"multi-discard drew back different Jacks per shuffle: "
				.. records[1].seed .. " -> " .. describe_order(records[1].drawn_jacks) .. "; "
				.. records[2].seed .. " -> " .. describe_order(records[2].drawn_jacks) .. "; "
				.. records[3].seed .. " -> " .. describe_order(records[3].drawn_jacks)
		)
	end)

end
