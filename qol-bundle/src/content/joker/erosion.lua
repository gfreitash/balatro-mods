-- Override Erosion to give Xmult per card below starting amount
function QOL_BUNDLE.funcs.get_ownership_erosion_xmult()
    if not QOL_BUNDLE.config.erosion_xmult_enabled then
        return
    end

    QOL_BUNDLE.state.erosion = SMODS.Joker:take_ownership('j_erosion', {
        config = {
            extra = 0.15
        },
        loc_vars = function(self, info_queue, center)
            local cards_below = math.max(0, (G.GAME and G.GAME.starting_deck_size or 52) - (G.playing_cards and #G.playing_cards or 52))
            local current_xmult = 1 + (center.ability.extra * cards_below)
            return {
                vars = {
                    center.ability.extra, -- #1# - per card multiplier 
                    G.GAME and G.GAME.starting_deck_size or 52, -- #2# - starting deck size
                    current_xmult, -- #3# - current X mult  
                }
            }
        end,
        calculate = function(self, card, context)
            if context.joker_main then
                local cards_below = math.max(0, G.GAME.starting_deck_size - #G.playing_cards)
                if cards_below > 0 then
                    local xmult = 1 + (card.ability.extra * cards_below)
                    return {
                        message = localize{type='variable',key='a_xmult',vars={xmult}},
                        Xmult_mod = xmult
                    }
                end
            end
            return nil
        end
    })

    local apply_localization = function()
        local loc = localize('j_erosion_original')
        if QOL_BUNDLE.config.erosion_xmult_enabled then
            loc = localize('j_erosion_xmult')
        end
        G.localization.descriptions.Joker.j_erosion.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_erosion()
