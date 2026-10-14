-- Override Pareidolia to make it Common and cheaper
function QOL_BUNDLE.funcs.get_ownership_joker_pareidolia()
    if not QOL_BUNDLE.config.pareidolia_common_enabled then
        return
    end

    QOL_BUNDLE.state.pareidolia = SMODS.Joker:take_ownership('j_pareidolia', {
        rarity = 1, -- Common (was 2 - Uncommon)
        cost = 4,   -- Cheaper (was 5)
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_pareidolia()
