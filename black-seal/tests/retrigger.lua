-- black-seal/tests/retrigger.lua
-- Retrigger tests: retrigger_black_seal controls whether the effect fires
-- again when the played card is retriggered (Hanging Chad retriggers the first
-- played card twice, for three evaluations total).

return function(T)
	local SEAL = T.SEAL

	-- Retrigger enabled: all three evaluations queue a proc, each targeting a
	-- different eligible Joker.
	BInt.register_test("riosodu/black_seal/retrigger_enabled_multi_proc", function(test)
		T.prep_run({ retrigger_black_seal = true })
		test:start_run({ seed = "BSM_RETRIG_ON_1" })
		test:select_blind()
		test:spawn_joker("j_hanging_chad")
		test:spawn_joker("j_joker")
		test:spawn_joker("j_joker")
		test:spawn_joker("j_joker")

		test:set_seal(1, SEAL):assert()
		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 3, "main evaluation + 2 retriggers should Negative 3 distinct Jokers")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 0, "Black Seal should be consumed")
	end)

	-- Retrigger disabled: repeated evaluations do not queue additional procs.
	BInt.register_test("riosodu/black_seal/retrigger_disabled_single_proc", function(test)
		T.prep_run({ retrigger_black_seal = false })
		test:start_run({ seed = "BSM_RETRIG_OFF_1" })
		test:select_blind()
		test:spawn_joker("j_hanging_chad")
		test:spawn_joker("j_joker")
		test:spawn_joker("j_joker")
		test:spawn_joker("j_joker")

		test:set_seal(1, SEAL):assert()
		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 1, "only the main evaluation should proc")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 0, "Black Seal should be consumed")
	end)

	-- Queued procs re-check eligibility when they run: with a single eligible
	-- Joker, the extra retriggered procs find no target and do nothing.
	BInt.register_test("riosodu/black_seal/retrigger_enabled_single_eligible_target", function(test)
		T.prep_run({ retrigger_black_seal = true })
		test:start_run({ seed = "BSM_RETRIG_ONE_1" })
		test:select_blind()
		test:spawn_joker("j_hanging_chad")

		test:set_seal(1, SEAL):assert()
		test:highlight({ 1 })
		test:play_hand():assert()

		test:assert_eq(T.negative_joker_count(test), 1, "only one eligible Joker -> exactly one Negative")
		test:assert_eq(T.count_seals(test:get_full_deck(), SEAL), 0, "Black Seal should be consumed")
	end)
end
