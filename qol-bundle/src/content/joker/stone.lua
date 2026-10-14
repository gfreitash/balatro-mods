-- Override Stone Joker: gives Mult per Stone Card instead of Chips
function QOL_BUNDLE.funcs.get_ownership_joker_stone()
    if not QOL_BUNDLE.config.stone_joker_mult_enabled then
        return
    end

    QOL_BUNDLE.state.stone_joker = SMODS.Joker:take_ownership('j_stone', {
        config = { extra = 4 },
        loc_vars = function(self, info_queue, center)
            local stone_tally = center.ability.stone_tally or 0
            return {
                vars = {
                    center.ability.extra,                  -- #1# - Mult per Stone Card
                    center.ability.extra * stone_tally,    -- #2# - current Mult
                }
            }
        end,
        calculate = function(self, card, context)
            if context.joker_main then
                local stone_tally = card.ability.stone_tally or 0
                if stone_tally > 0 then
                    local mult = card.ability.extra * stone_tally
                    return {
                        message = localize{type = 'variable', key = 'a_mult', vars = {mult}},
                        mult_mod = mult,
                        colour = G.C.MULT
                    }
                end
                return {}
            end
            return nil
        end
    })

    local apply_localization = function()
        local loc = localize('j_stone_original')
        if QOL_BUNDLE.config.stone_joker_mult_enabled then
            loc = localize('j_stone_modified')
        end
        G.localization.descriptions.Joker.j_stone.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_stone()
