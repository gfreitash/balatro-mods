-- Override Canio to destroy every played face card (not just the cards in the
-- scoring hand) and to scale per destroyed face card.
function QOL_BUNDLE.funcs.get_ownership_joker_caino()
    if not QOL_BUNDLE.config.caino_rework_enabled then
        return
    end

    QOL_BUNDLE.state.caino = SMODS.Joker:take_ownership('j_caino', {
        config = { extra = 0.5 },
        loc_vars = function(self, info_queue, center)
            return {
                vars = {
                    center.ability.extra,                     -- #1# - X Mult per destroyed face card
                    center.ability.caino_xmult or 1,          -- #2# - current X Mult
                }
            }
        end,
        calculate = function(self, card, context)
            -- Gain X Mult for every face card destroyed by any source this hand.
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
                -- Remember that this hand actually scored, so a debuffed/invalid
                -- hand does not trigger the destruction below.
                card.ability.qolb_caino_scored = true

                local xmult = card.ability.caino_xmult or 1
                if xmult > 1 then
                    return {
                        message = localize{type = 'variable', key = 'a_xmult', vars = {xmult}},
                        Xmult_mod = xmult
                    }
                end
                return {}
            end

            -- Destroy every face card that was played, including cards that were
            -- not part of the scoring hand. This runs after scoring, so the
            -- played cards already contributed their score.
            if context.after then
                local scored = card.ability.qolb_caino_scored
                card.ability.qolb_caino_scored = nil
                if context.blueprint or not scored then
                    return nil
                end

                local faces = {}
                for _, played in ipairs(context.full_hand or G.play.cards or {}) do
                    if played:is_face() and not played.destroyed and not played.shattered then
                        faces[#faces + 1] = played
                    end
                end

                if #faces > 0 then
                    for _, face in ipairs(faces) do
                        face.destroyed = true
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                face:start_dissolve()
                                return true
                            end
                        }))
                    end

                    card.ability.caino_xmult = (card.ability.caino_xmult or 1) + #faces * card.ability.extra
                    return {
                        message = localize{type = 'variable', key = 'a_xmult', vars = {card.ability.caino_xmult}},
                        colour = G.C.XMULT
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
