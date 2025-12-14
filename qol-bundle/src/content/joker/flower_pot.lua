-- Override the Flower Pot Joker
function QOL_BUNDLE.funcs.get_ownership_joker_flower_pot()
    if not QOL_BUNDLE.config.flower_pot_wildcard_enabled then
        return
    end

    QOL_BUNDLE.state.flower_pot = SMODS.Joker:take_ownership('j_flower_pot', {
        enhancement_gate = 'm_wild', -- Only show in shop if wildcard cards exist
        calculate = function(self, card, context)
            if context.joker_main then
                -- Check if scoring hand has any wildcard-enhanced cards
                local has_wildcard = false
                for i = 1, #context.scoring_hand do
                    if context.scoring_hand[i].config.center.key == 'm_wild' then
                        has_wildcard = true
                        break
                    end
                end

                if has_wildcard then
                    return {
                        message = localize{type='variable',key='a_xmult',vars={card.ability.extra}},
                        Xmult_mod = card.ability.extra
                    }
                end
            end
        end,
    })

    local apply_localization = function()
        local loc = localize('j_flower_pot_original')
        if QOL_BUNDLE.config.flower_pot_wildcard_enabled then
            loc = localize('j_flower_pot_modified')
        end
        G.localization.descriptions.Joker.j_flower_pot.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_flower_pot()
