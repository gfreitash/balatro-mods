-- Override Matador: earn $5 for every hand played during a Boss Blind, paid
-- at the end of the round (like Satellite / Delayed Gratification).
function QOL_BUNDLE.funcs.get_ownership_joker_matador()
    if not QOL_BUNDLE.config.matador_rework_enabled then
        return
    end

    QOL_BUNDLE.state.matador = SMODS.Joker:take_ownership('j_matador', {
        config = { extra = 5 },
        calculate = function(self, card, context)
            -- Claim the context so the vanilla "boss ability triggered" $8
            -- payout can never run.
            if context.debuffed_hand then
                return {}
            end
            return nil
        end,
        calc_dollar_bonus = function(self, card)
            if G.GAME.blind and G.GAME.blind.boss then
                local hands_played = G.GAME.current_round.hands_played or 0
                if hands_played > 0 then
                    return hands_played * card.ability.extra
                end
            end
        end
    })

    local apply_localization = function()
        local loc = localize('j_matador_original')
        if QOL_BUNDLE.config.matador_rework_enabled then
            loc = localize('j_matador_modified')
        end
        G.localization.descriptions.Joker.j_matador.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_matador()
