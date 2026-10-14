-- Override Canio to destroy scored face cards and scale per destroyed face card
function QOL_BUNDLE.funcs.get_ownership_joker_caino()
    if not QOL_BUNDLE.config.caino_rework_enabled then
        return
    end

    QOL_BUNDLE.state.caino = SMODS.Joker:take_ownership('j_caino', {
        config = { extra = 0.25 },
        loc_vars = function(self, info_queue, center)
            return {
                vars = {
                    center.ability.extra,                     -- #1# - X Mult per destroyed face card
                    center.ability.caino_xmult or 1,          -- #2# - current X Mult
                }
            }
        end,
        calculate = function(self, card, context)
            -- Destroy scored face cards (not blueprint compatible)
            if context.destroying_card and not context.blueprint
                and context.destroying_card:is_face() then
                return { remove = true }
            end

            -- Gain X Mult for every destroyed face card
            if context.remove_playing_cards and not context.blueprint then
                local face_cards = 0
                for _, val in ipairs(context.removed) do
                    if val:is_face() then face_cards = face_cards + 1 end
                end

                if face_cards > 0 then
                    card.ability.caino_xmult = (card.ability.caino_xmult or 1) + face_cards * card.ability.extra
                    return {
                        message = localize{type = 'variable', key = 'a_xmult', vars = {card.ability.caino_xmult}},
                        colour = G.C.XMULT
                    }
                end
                return {}
            end

            if context.joker_main then
                local xmult = card.ability.caino_xmult or 1
                if xmult > 1 then
                    return {
                        message = localize{type = 'variable', key = 'a_xmult', vars = {xmult}},
                        Xmult_mod = xmult
                    }
                end
                return {}
            end

            return nil
        end
    })

    local apply_localization = function()
        local loc = localize('j_caino_original')
        if QOL_BUNDLE.config.caino_rework_enabled then
            loc = localize('j_caino_modified')
        end
        G.localization.descriptions.Joker.j_caino.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_caino()
