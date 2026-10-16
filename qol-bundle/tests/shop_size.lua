-- qol-bundle/tests/shop_size.lua
-- "Increased shop size" (`joker_max_enabled`/`joker_max_value`, applied via
-- RIOSODU_SHARED.utils.override_game_obj in src/overrides.lua:88-94). The value
-- is baked into G.GAME.shop.joker_max when the run's game object is created, so
-- config changes need a restart.

return function(T)
	BInt.register_test("riosodu/qol_bundle/shop_size_default_is_3", function(test)
		T.start_run(test, "QOL_SHOP_1", 1)
		test:assert_eq(G.GAME.shop.joker_max, 3, "default joker_max should be 3")
	end)

	BInt.register_test("riosodu/qol_bundle/shop_size_cards_generated", function(test)
		T.start_run(test, "QOL_SHOP_2", 1)
		test:go_to_shop():assert()
		BInt._wait.stable_drain()
		test:assert_eq(#G.shop_jokers.cards, 3, "shop should spawn joker_max jokers")
	end)

	BInt.register_test("riosodu/qol_bundle/shop_size_restart_required", function(test)
		T.start_run(test, "QOL_SHOP_3", 1)
		test:assert_eq(G.GAME.shop.joker_max, 3)

		QOL_BUNDLE.config.joker_max_enabled = false
		test:assert_eq(G.GAME.shop.joker_max, 3, "existing run keeps the old value")

		test:restart_run():assert()
		test:assert_eq(G.GAME.shop.joker_max, 2, "restart applies the vanilla value")
	end)

	BInt.register_test("riosodu/qol_bundle/shop_size_custom_value", function(test)
		T.start_run(test, "QOL_SHOP_4", 1)

		QOL_BUNDLE.config.joker_max_value = 5
		test:restart_run():assert()
		test:assert_eq(G.GAME.shop.joker_max, 5, "custom value should be applied on restart")

		-- Restore the default for any later run in this suite.
		QOL_BUNDLE.config.joker_max_value = 3
		test:restart_run():assert()
		test:assert_eq(G.GAME.shop.joker_max, 3)
	end)
end
