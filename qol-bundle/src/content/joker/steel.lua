-- Override Steel Joker to buff its X Mult per Steel Card
function QOL_BUNDLE.funcs.get_ownership_joker_steel()
    if not QOL_BUNDLE.config.steel_joker_enabled then
        return
    end

    QOL_BUNDLE.state.steel_joker = SMODS.Joker:take_ownership('j_steel_joker', {
        config = { extra = 0.25 }
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_steel()
