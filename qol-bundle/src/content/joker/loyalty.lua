-- Override the Loyalty Card Joker
local loyalty_juicing = false
function QOL_BUNDLE.funcs.get_ownership_loyalty_card()
    if not QOL_BUNDLE.config.loyalty_card_rounds_enabled then
        return
    end


    QOL_BUNDLE.state.loyalty_card = SMODS.Joker:take_ownership('j_loyalty_card', {
        config = {
            extra = {
                every = 2,
                Xmult = 4,
            }
        },
        loc_vars = function (self, info_queue, card)
            local loyalty_state = 'loyalty_inactive'

            if card.ability.loyalty_remaining == 0 and loyalty_juicing then
                loyalty_state = 'loyalty_active'
            elseif card.ability.loyalty_remaining == 0 and not loyalty_juicing then
                loyalty_state = 'loyalty_redeemed'
            end

            return {
                vars = {
                    card.ability.extra.Xmult,
                    card.ability.extra.every,
                    loyalty_state == 'loyalty_redeemed' and localize('k_redeemed_ex') or localize{
                        type = 'variable',
                        key = loyalty_state,
                        vars = {card.ability.loyalty_remaining}
                    }
                }
            }
        end,
        calculate = function(self, card, context)
            local rounds_since_creation = G.GAME.round - card.ability.rounds_played_at_create
            card.ability.loyalty_remaining = (card.ability.extra.every - rounds_since_creation) % card.ability.extra.every

                if not context.blueprint and G.play and not loyalty_juicing then
                    local eval = function(c)
                        local ret = (
                            c.ability.loyalty_remaining == 0 and (
                                G.STATE == G.STATES.NEW_ROUND or
                                G.STATE == G.STATES.DRAW_TO_HAND or
                                G.STATE == G.STATES.HAND_PLAYED or
                                G.STATE == G.STATES.SELECTING_HAND or
                                G.STATE == G.STATES.PLAY_TAROT or
                                G.STATE == G.STATES.MENU
                            )
                        )

                        loyalty_juicing = ret
                        return ret
                    end

                    juice_card_until(card, eval, true, 0.5)
                    loyalty_juicing = true
                end

            if context.joker_main then
                RIOSODU_SHARED.utils.sendDebugMessage("Loyalty, round crated: " .. card.ability.rounds_played_at_create)
                RIOSODU_SHARED.utils.sendDebugMessage("Loyalty, round current: " .. G.GAME.round)
                RIOSODU_SHARED.utils.sendDebugMessage("Loyalty remaining: " .. card.ability.loyalty_remaining)

                ret = {
                    message = localize{type='variable',key='a_xmult',vars={card.ability.extra.Xmult}},
                    Xmult_mod = card.ability.extra.Xmult,
                }

                if card.ability.loyalty_remaining == 0 then
                    return ret
                end
            end
        end
    })

    local apply_localization = function()
        local loc = localize('j_loyalty_card_original')
        if QOL_BUNDLE.config.loyalty_card_rounds_enabled then
            loc = localize('j_loyalty_card_rounds')
        end
        G.localization.descriptions.Joker.j_loyalty_card.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

