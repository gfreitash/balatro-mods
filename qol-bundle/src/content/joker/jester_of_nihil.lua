function QOL_BUNDLE.funcs.get_ownership_joker_jester_of_nihil()
    if not PB_UTIL then return end

    QOL_BUNDLE.state.jester_of_nihil = SMODS.Joker:take_ownership('j_paperback_jester_of_nihil', {
        update = function(self, card, dt)
            -- Update the mult this card gives by counting the amount of debuffed cards
            if G.playing_cards then
            local total = 0

            for k, v in ipairs(G.playing_cards) do
                if v.debuff or (QOL_BUNDLE.config.wildcard_fix_enabled and v.config.center.key == 'm_wild') then
                total = total + 1
                end
            end

            card.ability.extra.mult = math.max(0, total * card.ability.extra.debuff_mult)
            end
        end
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_jester_of_nihil()
