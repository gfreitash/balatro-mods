-- Override Ceremonial Dagger to make it Common and cheaper
function QOL_BUNDLE.funcs.get_ownership_joker_cerimonial()
    if not QOL_BUNDLE.config.ceremonial_dagger_common_enabled then
        return
    end

    QOL_BUNDLE.state.ceremonial_dagger = SMODS.Joker:take_ownership('j_ceremonial', {
        rarity = 1, -- Common (was 2 - Uncommon)
        cost = 3,   -- Cheaper (was 6)
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_cerimonial()
