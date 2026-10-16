-- rebalanced-stakes/tests/localization.lua
-- The mod ships stake descriptions (localization/en-us.lua) that replace the
-- vanilla ones: blue advertises Perishables instead of the discard penalty,
-- orange advertises Rentals, gold advertises the economy rework.

return function(T)
	BInt.register_test("riosodu/rebalanced_stakes/blue_stake_description", function(test)
		local text = T.stake_loc("stake_blue")
		test:assert_true(text ~= nil, "blue stake description should exist")
		test:assert_true(T.loc_contains(text, "Perishable"), "blue stake description mentions Perishable")
		test:assert_false(T.loc_contains(text, "Discard"), "blue stake description no longer mentions the discard penalty")
	end)

	BInt.register_test("riosodu/rebalanced_stakes/orange_stake_description", function(test)
		local text = T.stake_loc("stake_orange")
		test:assert_true(text ~= nil, "orange stake description should exist")
		test:assert_true(T.loc_contains(text, "Rental"), "orange stake description mentions Rental")
		test:assert_false(T.loc_contains(text, "Perishable"), "orange stake description no longer introduces Perishables")
	end)

	BInt.register_test("riosodu/rebalanced_stakes/gold_stake_description", function(test)
		local text = T.stake_loc("stake_gold")
		test:assert_true(text ~= nil, "gold stake description should exist")
		test:assert_true(T.loc_contains(text, "$6"), "gold stake description mentions the $6 interest threshold")
		test:assert_true(T.loc_contains(text, "Final Ante"), "gold stake description mentions the final ante")
		test:assert_false(T.loc_contains(text, "Rental"), "gold stake description no longer introduces Rentals")
	end)
end
