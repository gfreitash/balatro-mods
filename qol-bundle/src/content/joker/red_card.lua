-- Override Red Card: +1 Mult for every Booster Pack opened and +2 Mult for
-- every Booster Pack skipped.
function QOL_BUNDLE.funcs.get_ownership_joker_red_card()
    if not QOL_BUNDLE.config.red_card_rework_enabled then
        return
    end

    QOL_BUNDLE.state.red_card = SMODS.Joker:take_ownership('j_red_card', {
        calculate = function(self, card, context)
            local gain = 0
            if context.open_booster and not context.blueprint then
                gain = 1
            elseif context.skipping_booster and not context.blueprint then
                gain = 2
            end
            if gain == 0 then
                return nil
            end

            card.ability.mult = card.ability.mult + gain
            G.E_MANAGER:add_event(Event({
                func = function()
                    card_eval_status_text(card, 'extra', nil, nil, nil, {
                        message = localize { type = 'variable', key = 'a_mult', vars = { gain } },
                        colour = G.C.RED,
                        delay = 0.45,
                        card = card
                    })
                    return true
                end
            }))

            -- Claim the context so the vanilla +3 on skip cannot also run.
            return {}
        end,
        loc_vars = function(self, info_queue, center)
            return {
                vars = {
                    1,                    -- opened Booster Pack gain
                    2,                    -- skipped Booster Pack gain
                    center.ability.mult   -- current Mult
                }
            }
        end
    })

    local apply_localization = function()
        local loc = localize('j_red_card_original')
        if QOL_BUNDLE.config.red_card_rework_enabled then
            loc = localize('j_red_card_modified')
        end
        G.localization.descriptions.Joker.j_red_card.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_red_card()
