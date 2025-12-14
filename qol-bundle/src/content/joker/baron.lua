-- Override Baron to make it Uncommon and cheaper
function QOL_BUNDLE.funcs.get_ownership_joker_baron()
    if not QOL_BUNDLE.config.baron_uncommon_enabled then
        return
    end

    QOL_BUNDLE.state.baron = SMODS.Joker:take_ownership('j_baron', {
        rarity = 2, -- Uncommon (was 3 - Rare)
        cost = 5,   -- Cheaper (was 8)
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_baron()
