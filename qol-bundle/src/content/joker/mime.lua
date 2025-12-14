-- Override Mime to make it Rare and more expensive
function QOL_BUNDLE.funcs.get_ownership_joker_mime()
    if not QOL_BUNDLE.config.mime_rare_enabled then
        return
    end

    QOL_BUNDLE.state.mime = SMODS.Joker:take_ownership('j_mime', {
        rarity = 3, -- Rare (was 2 - Uncommon)
        cost = 6,   -- Higher price (was 5)
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_mime()
