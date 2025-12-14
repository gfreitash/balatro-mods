-- Override Fortune Teller to make it cheaper
function QOL_BUNDLE.funcs.get_ownership_joker_fortune_teller()
    if not QOL_BUNDLE.config.fortune_teller_cheaper_enabled then
        return
    end

    QOL_BUNDLE.state.fortune_teller = SMODS.Joker:take_ownership('j_fortune_teller', {
        cost = 4, -- Cheaper (was 6)
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_fortune_teller()
