-- qol-bundle/tests/localization.lua
-- The Ankh rework tooltip uses the sticker badge colours via namespaced
-- loc_colour keys registered when the spectral content loads.

return function(T)
	local F = QOL_BUNDLE.funcs

	BInt.register_test("riosodu/qol_bundle/ankh_tooltip_uses_sticker_colours", function(test)
		test:assert_eq(loc_colour("qolb_eternal"), G.C.ETERNAL,
			"Eternal should use the sticker badge colour")
		test:assert_eq(loc_colour("qolb_perishable"), G.C.PERISHABLE,
			"Perishable should use the sticker badge colour")
		test:assert_eq(loc_colour("qolb_rental"), G.C.RENTAL,
			"Rental should use the sticker badge colour")

		T.apply_feature("ankh_rework_enabled", "c_ankh", F.get_ownership_spectral_ankh)
		T.refresh_loc()

		local text = T.loc_text("Spectral", "c_ankh")
		test:assert_true(T.loc_contains(text, "qolb_eternal"),
			"the tooltip should use the Eternal badge colour")
		test:assert_true(T.loc_contains(text, "qolb_perishable"),
			"the tooltip should use the Perishable badge colour")
		test:assert_true(T.loc_contains(text, "qolb_rental"),
			"the tooltip should use the Rental badge colour")
	end)
end
