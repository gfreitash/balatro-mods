-- Override the Loyalty Card Joker: scaling X Mult instead of the vanilla
-- hand-counter effect. Starts at X1, gains X0.5 after finishing a blind and
-- redeems back to X2 after finishing a blind at X4 or higher.
function QOL_BUNDLE.funcs.get_ownership_loyalty_card()
    if not QOL_BUNDLE.config.loyalty_card_scaling_enabled then
        return
    end

    QOL_BUNDLE.state.loyalty_card = SMODS.Joker:take_ownership('j_loyalty_card', {
        config = {
            extra = {
                Xmult = 1,
                -- Legacy fields: vanilla UI/init code paths still reference these
                -- (e.g. Card:generate_UIBox_ability_table), so they must exist
                every = 6,
            }
        },
        loc_vars = function(self, info_queue, card)
            return {
                key = 'j_loyalty_card_scaling',
                name_key = 'j_loyalty_card',
                vars = {
                    card.ability.extra.Xmult or 1, -- #1# - current X Mult
                }
            }
        end,
        calculate = function(self, card, context)
            local extra = card.ability.extra
            extra.Xmult = extra.Xmult or 1

            if context.end_of_round then
                -- Only the single main round-end evaluation counts: the per-card
                -- individual/repetition evaluations fire once per hand card too
                if context.blueprint or context.individual or context.repetition or context.game_over then
                    return {}
                end

                if extra.Xmult >= 4 then
                    -- Redeem: go back to X2 instead of increasing
                    extra.Xmult = 2
                    return {
                        message = localize('k_redeemed_ex'),
                        colour = G.C.XMULT,
                    }
                end

                extra.Xmult = extra.Xmult + 0.5
                return {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.XMULT,
                }
            end

            if context.joker_main then
                if extra.Xmult > 1 then
                    return {
                        message = localize{type = 'variable', key = 'a_xmult', vars = {extra.Xmult}},
                        Xmult_mod = extra.Xmult,
                    }
                end
                return {}
            end

            -- The vanilla hand-counter effect is fully replaced: claim every
            -- remaining joker-scoring context so it can never run
            if context.cardarea == G.jokers then
                return {}
            end

            return nil
        end
    })
end

QOL_BUNDLE.funcs.get_ownership_loyalty_card()
