-- Override the Loyalty Card Joker
function QOL_BUNDLE.funcs.get_ownership_loyalty_card()
    if not QOL_BUNDLE.config.loyalty_card_rounds_enabled then
        return
    end

    QOL_BUNDLE.state.loyalty_card = SMODS.Joker:take_ownership('j_loyalty_card', {
        config = {
            extra = {
                every = 3,
                Xmult = 4,
            }
        },
        loc_vars = function(self, info_queue, card)
            local counter = card.ability.loyalty_counter or 0
            local status
            if card.ability.loyalty_caught then
                status = localize('qolb_loyalty_got_caught')
            elseif counter >= card.ability.extra.every then
                status = localize('qolb_loyalty_active')
            else
                status = localize{type = 'variable', key = 'qolb_loyalty_status_remaining', vars = {card.ability.extra.every - counter}}
            end

            -- Description is chosen per card state: a caught card shows only "(got caught)",
            -- and the cheated line follows the persistent catch chance, not the per-cycle flag
            local desc_key = card.ability.loyalty_caught and 'j_loyalty_card_caught'
                or ((card.ability.loyalty_cheats or 0) > 0 and 'j_loyalty_card_rounds_cheated')
                or 'j_loyalty_card_rounds'

            local caught_num, caught_denom = SMODS.get_probability_vars(card, math.min(card.ability.loyalty_cheats or 0, 5), 5, 'qolb_loyalty_catch')

            return {
                key = desc_key,
                name_key = 'j_loyalty_card',
                replace_debuff = card.ability.loyalty_caught,
                vars = {
                    card.ability.extra.Xmult,    -- #1# - X Mult
                    card.ability.extra.every,    -- #2# - rounds to redeem
                    status,                      -- #3# - "Active" / "N rounds left" / "Got caught!"
                    caught_num,                  -- #4# - catch chance numerator
                    caught_denom,                -- #5# - catch chance denominator
                }
            }
        end,
        calculate = function(self, card, context)
            -- Debuff response: keep a caught card disabled permanently (re-evaluated every round)
            -- Only answer for this card itself, so other cards are never debuffed
            if context.debuff_card then
                if not context.blueprint and context.debuff_card == card and card.ability.loyalty_caught then
                    return { debuff = true }
                end
                return nil
            end

            local counter = card.ability.loyalty_counter or 0
            local every = card.ability.extra.every

            if context.end_of_round then
                -- Only the single main round-end evaluation counts: the per-card
                -- individual/repetition evaluations fire once per hand card too
                if not context.blueprint and not context.individual and not context.repetition then
                    -- Played round: advance the counter, unless this was the active round
                    if counter >= every then
                        card.ability.loyalty_counter = 0
                    else
                        card.ability.loyalty_counter = counter + 1
                    end
                end
                return nil
            end

            if context.skip_blind then
                if not context.blueprint and counter < every then
                    -- Skipping counts twice and marks the cycle as cheated.
                    -- An already-armed card gains nothing from a skip: the armed state is
                    -- preserved and the skip is not counted as cheating.
                    card.ability.loyalty_counter = counter + 2
                    card.ability.loyalty_cycle_cheated = true
                    card.ability.loyalty_cheats = (card.ability.loyalty_cheats or 0) + 1
                    card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('qolb_loyalty_cheated'), colour = G.C.RED})
                end
                return nil
            end

            if context.setting_blind then
                -- Redeem at round start: the roll decides "Active" or "Got caught!" for the whole round
                if not context.blueprint and not card.ability.loyalty_caught and counter >= every then
                    if card.ability.loyalty_cycle_cheated then
                        -- Cheated redeem: chance to get caught, growing with each skip
                        local chance = math.min(card.ability.loyalty_cheats or 0, 5)
                        if SMODS.pseudorandom_probability(card, 'loyalty_catch_'..G.GAME.round, chance, 5) then
                            card.ability.loyalty_caught = true
                            card.ability.loyalty_cycle_cheated = false
                            SMODS.recalc_debuff(card)
                            card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('qolb_loyalty_got_caught'), colour = G.C.RED})
                            return nil
                        end
                        card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('qolb_loyalty_active'), colour = G.C.XMULT})
                    else
                        -- Clean redeem: a single clean redeem lowers the catch chance
                        card.ability.loyalty_cheats = math.max(0, (card.ability.loyalty_cheats or 0) - 1)
                        card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('qolb_loyalty_active'), colour = G.C.XMULT})
                    end
                    card.ability.loyalty_cycle_cheated = false

                    -- Continuous juice for the whole active round, like vanilla Loyalty Card
                    juice_card_until(card, function(c)
                        return (c.ability.loyalty_counter or 0) >= every and not c.ability.loyalty_caught and not G.RESET_JIGGLES
                    end, true)
                end
                return nil
            end

            if context.joker_main then
                if card.ability.loyalty_caught then
                    return {}
                end
                if counter < every then
                    return {}
                end

                return {
                    message = localize{type='variable',key='a_xmult',vars={card.ability.extra.Xmult}},
                    Xmult_mod = card.ability.extra.Xmult,
                }
            end

            return nil
        end
    })
end

QOL_BUNDLE.funcs.get_ownership_loyalty_card()