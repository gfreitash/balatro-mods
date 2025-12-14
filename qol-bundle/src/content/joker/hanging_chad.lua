-- Override Hanging Chad
function QOL_BUNDLE.funcs.get_ownership_joker_hanging_chad()
    if not QOL_BUNDLE.config.nerf_hanging_chad_enabled then
        return
    end

    QOL_BUNDLE.state.hanging_chad = SMODS.Joker:take_ownership('j_hanging_chad', {
        rarity = 2, -- Uncommon (was 1 - Common)
        cost = 7,   -- More expensive (was 6)
    })
end

QOL_BUNDLE.funcs.get_ownership_joker_hanging_chad()
