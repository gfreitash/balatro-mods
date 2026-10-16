-- rebalanced-stakes/tests/perishable.lua
-- The mod overrides Card:calculate_perishable so expiring jokers become
-- Negative in addition to vanilla's debuff. Expiry happens inside end_round()
-- (before ROUND_EVAL), so the assertions can run right after the winning play.

return function(T)
	local function spawn_expiring_joker(test)
		test:spawn_joker("j_joker"):assert()
		local card = G.jokers.cards[1]
		card:set_perishable(true)
		test:assert_true(card.ability.perishable, "j_joker should accept the perishable sticker")
		return card
	end

	-- Before expiry the mod must behave like vanilla: tick the tally down and
	-- leave the joker untouched.
	BInt.register_test("riosodu/rebalanced_stakes/perishable_countdown_decrements", function(test)
		T.start_run_at_stake(test, "RST_PER_TICK", 5)
		test:select_blind():assert()
		local card = spawn_expiring_joker(test)

		card.ability.perish_tally = 3
		card:calculate_perishable()
		test:assert_eq(card.ability.perish_tally, 2, "tally decrements by one per round")
		test:assert_false(card.edition and card.edition.negative, "joker is not negative before expiry")
		test:assert_false(card.debuff == true, "joker is not debuffed before expiry")
	end)

	-- On expiry the joker becomes Negative and is debuffed immediately, like
	-- vanilla does for the debuff.
	BInt.register_test("riosodu/rebalanced_stakes/expired_perishable_negative_and_debuffed", function(test)
		T.start_run_at_stake(test, "RST_PER_EXPIRE", 5)
		test:select_blind():assert()
		local card = spawn_expiring_joker(test)

		card.ability.perish_tally = 1
		T.win_round(test)

		test:assert_eq(card.ability.perish_tally, 0, "tally should reach zero when the joker expires")
		test:assert_true(
			card.edition ~= nil and card.edition.negative == true,
			"expired perishable joker should become negative"
		)
		test:assert_true(card.debuff == true, "expired perishable joker should be debuffed immediately")
	end)

	-- The debuff must be applied during expiry itself, before the round
	-- evaluation computes joker dollar bonuses: an expiring Golden Joker
	-- must not pay its final bonus (vanilla suppresses it).
	BInt.register_test("riosodu/rebalanced_stakes/expired_perishable_pays_no_final_bonus", function(test)
		T.start_run_at_stake(test, "RST_PER_BONUS", 2)
		test:select_blind():assert()
		test:spawn_joker("j_golden"):assert()
		local card = G.jokers.cards[1]
		card:set_perishable(true)
		card.ability.perish_tally = 1

		T.win_round(test, 0)

		test:assert_eq(card.ability.perish_tally, 0, "the Golden Joker should expire this round")
		test:assert_true(card.debuff == true, "expired joker must be debuffed during round evaluation")
		test:assert_eq(T.round_dollars(test), 0, "the expired joker must not pay its $4 bonus")
	end)

	-- Control test for the fix above: the shipped vanilla implementation of
	-- Card:calculate_perishable (replicated verbatim below from the game's
	-- card.lua as dumped at runtime by Lovely) must suppress the final bonus
	-- too. The mod's `original_calculate_perishable` local is dead code (the
	-- override never references it), so the original function object is not
	-- reachable at runtime; this replica runs the exact vanilla algorithm
	-- through the real end-of-round flow to prove the fix restores vanilla
	-- parity rather than inventing behavior.
	BInt.register_test("riosodu/rebalanced_stakes/vanilla_expiry_suppresses_final_bonus", function(test)
		local function vanilla_calculate_perishable(self)
			if self.ability.perishable and self.ability.perish_tally > 0 then
				if self.ability.perish_tally == 1 then
					self.ability.perish_tally = 0
					card_eval_status_text(self, 'extra', nil, nil, nil, { message = localize('k_disabled_ex'), colour = G.C.FILTER, delay = 0.45 })
					self:set_debuff()
				else
					self.ability.perish_tally = self.ability.perish_tally - 1
					card_eval_status_text(self, 'extra', nil, nil, nil, { message = localize{ type = 'variable', key = 'a_remaining', vars = { self.ability.perish_tally } }, colour = G.C.FILTER, delay = 0.45 })
				end
			end
		end

		local rebalanced_calculate_perishable = Card.calculate_perishable
		Card.calculate_perishable = vanilla_calculate_perishable

		T.start_run_at_stake(test, "RST_PER_VANILLA", 2)
		test:select_blind():assert()
		test:spawn_joker("j_golden"):assert()
		local card = G.jokers.cards[1]
		card:set_perishable(true)
		card.ability.perish_tally = 1

		T.win_round(test, 0)
		Card.calculate_perishable = rebalanced_calculate_perishable

		test:assert_eq(card.ability.perish_tally, 0, "vanilla should still expire the joker")
		test:assert_true(card.debuff == true, "vanilla should debuff the joker at expiry")
		test:assert_false(
			card.edition ~= nil and card.edition.negative == true,
			"vanilla should not grant the Negative edition"
		)
		test:assert_eq(T.round_dollars(test), 0, "vanilla should suppress the joker's final bonus")
	end)

	-- The expired joker stays negative and debuffed when the next blind starts.
	BInt.register_test("riosodu/rebalanced_stakes/expired_perishable_stays_debuffed_next_blind", function(test)
		T.start_run_at_stake(test, "RST_PER_NEXT", 5)
		test:select_blind():assert()
		local card = spawn_expiring_joker(test)

		card.ability.perish_tally = 1
		T.win_round(test)

		test:go_to_shop():assert()
		test:leave_shop():assert()
		test:select_blind():assert()

		test:assert_true(
			card.edition ~= nil and card.edition.negative == true,
			"joker should still be negative next round"
		)
		test:assert_true(card.debuff == true, "joker should still be debuffed next round")
	end)
end
