-- Override Bull: +3 Chips for each $1 (was +2)
function QOL_BUNDLE.funcs.get_ownership_joker_bull()
    if not QOL_BUNDLE.config.bull_buff_enabled then
        return
    end

    -- The vanilla loc_vars already reads ability.extra, so the tooltip updates
    -- without a localization swap.
    QOL_BUNDLE.state.bull = SMODS.Joker:take_ownership('j_bull', {
        config = { extra = 3 }
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_bull()
