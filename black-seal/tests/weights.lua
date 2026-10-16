-- black-seal/tests/weights.lua
-- Seal weight tests: black_seal_percentage drives G.P_SEALS weights through
-- BSM.utils.calculate_and_set_seal_weights (also exposed as the config
-- callback G.FUNCS.bsm_calculate_and_set_seal_weights).

return function(T)
	local SEAL = T.SEAL

	local function other_weight_sum()
		local sum = 0
		for key, seal in pairs(G.P_SEALS) do
			if key ~= SEAL then
				sum = sum + (seal.weight or 0)
			end
		end
		return sum
	end

	BInt.register_test("riosodu/black_seal/weights_at_0", function(test)
		T.set_config({ black_seal_percentage = 0 })
		test:assert_eq(G.P_SEALS[SEAL].weight, 0, "Black Seal weight should be 0 at 0%")
		test:assert_lte(math.abs(other_weight_sum() - 100), 0.01, "other seals should share 100%")
	end)

	BInt.register_test("riosodu/black_seal/weights_at_50", function(test)
		T.set_config({ black_seal_percentage = 50 })
		test:assert_eq(G.P_SEALS[SEAL].weight, 50, "Black Seal weight should be 50 at 50%")
		test:assert_lte(math.abs(other_weight_sum() - 50), 0.01, "other seals should share the remaining 50%")
	end)

	BInt.register_test("riosodu/black_seal/weights_at_100", function(test)
		T.set_config({ black_seal_percentage = 100 })
		test:assert_eq(G.P_SEALS[SEAL].weight, 100, "Black Seal weight should be 100 at 100%")
		for key, seal in pairs(G.P_SEALS) do
			if key ~= SEAL then
				test:assert_eq(seal.weight, 0, "seal '" .. key .. "' should be at 0 weight")
			end
		end
	end)

	-- Other seals keep their relative proportions while sharing the leftover.
	BInt.register_test("riosodu/black_seal/weights_scale_other_seals_proportionally", function(test)
		T.set_config({ black_seal_percentage = 0 })
		local full = {}
		for key, seal in pairs(G.P_SEALS) do
			if key ~= SEAL then
				full[key] = seal.weight or 0
			end
		end

		T.set_config({ black_seal_percentage = 50 })
		for key, seal in pairs(G.P_SEALS) do
			if key ~= SEAL then
				test:assert_lte(
					math.abs((seal.weight or 0) - full[key] * 0.5),
					0.01,
					"seal '" .. key .. "' should scale to half of its 0% weight"
				)
			end
		end
		test:assert_eq(G.P_SEALS[SEAL].weight, 50, "Black Seal weight should be 50")
	end)

	-- The callback referenced by the config slider applies new weights at
	-- runtime (callbacks.lua wiring).
	BInt.register_test("riosodu/black_seal/runtime_config_change_applies_weights", function(test)
		test:assert_true(type(G.FUNCS.bsm_calculate_and_set_seal_weights) == "function", "config callback should be registered in G.FUNCS")

		BSM.config.black_seal_percentage = 25
		G.FUNCS.bsm_calculate_and_set_seal_weights()
		test:assert_eq(G.P_SEALS[SEAL].weight, 25, "callback should apply the new percentage")

		T.set_config({ black_seal_percentage = 0 })
	end)
end
