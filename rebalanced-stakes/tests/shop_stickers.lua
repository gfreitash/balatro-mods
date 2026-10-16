-- rebalanced-stakes/tests/shop_stickers.lua
-- Shop joker durability stickers are decided inside create_card() from the
-- stake modifiers: first an 'etperpoll' roll (>0.7 eternal, (0.4, 0.7]
-- perishable) then an 'ssjr' rental roll (>0.7). Mocks make the rolls
-- deterministic; the card is created into the real shop area so the vanilla
-- code path runs untouched.

return function(T)
	local function spawn_shop_joker(test, stake, seed, polls)
		T.start_run_at_stake(test, seed, stake)
		test:go_to_shop():assert()
		test:mock_sequence("pseudorandom", polls)
		-- Forced key keeps the pool RNG out of the way: the first pseudorandom
		-- call for a forced shop Joker is the etperpoll sticker roll.
		local card = create_card("Joker", G.shop_jokers, nil, nil, nil, nil, "j_joker", "rebalanced_shop_test")
		BInt._wait.frames(2)
		test:clear_all_mocks()
		return card
	end

	-- Blue Stake: perishables can appear, rentals cannot.
	BInt.register_test("riosodu/rebalanced_stakes/shop_joker_perishable_at_blue", function(test)
		local card = spawn_shop_joker(test, 5, "RST_SHOP_BLUE", { 0.5 })
		test:assert_true(card.ability.perishable == true, "perishable roll should mark the shop joker")
		test:assert_false(card.ability.rental == true, "rentals are not enabled at blue stake")
		test:assert_false(card.ability.eternal == true, "0.5 roll should not be eternal")
	end)

	-- Orange Stake: rentals join the pool; perishables still apply from blue.
	BInt.register_test("riosodu/rebalanced_stakes/shop_joker_rental_at_orange", function(test)
		local card = spawn_shop_joker(test, 7, "RST_SHOP_ORANGE", { 0.5, 0.8 })
		test:assert_true(card.ability.perishable == true, "perishable should be inherited from blue stake")
		test:assert_true(card.ability.rental == true, "rental roll should mark the shop joker at orange stake")
	end)

	-- Below blue no durability stickers may spawn, and rolls must not leak
	-- into the next shop card.
	BInt.register_test("riosodu/rebalanced_stakes/shop_joker_plain_below_blue", function(test)
		local card = spawn_shop_joker(test, 4, "RST_SHOP_BLACK", { 0.5, 0.8 })
		test:assert_false(card.ability.perishable == true, "no perishables below blue stake")
		test:assert_false(card.ability.rental == true, "no rentals below orange stake")
	end)
end
