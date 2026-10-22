-- Override The Lovers: enhance up to two selected cards into Wild Cards.
-- The vanilla mod_conv path already loops every highlighted card, so changing
-- max_highlighted is enough.
function QOL_BUNDLE.funcs.get_ownership_tarot_lovers()
    if not QOL_BUNDLE.config.lovers_two_cards_enabled then
        return
    end

    QOL_BUNDLE.state.lovers = SMODS.Consumable:take_ownership('c_lovers', {
        config = { mod_conv = 'm_wild', max_highlighted = 2 }
    })

    local apply_localization = function()
        local loc = localize('c_lovers_original')
        if QOL_BUNDLE.config.lovers_two_cards_enabled then
            loc = localize('c_lovers_modified')
        end
        G.localization.descriptions.Tarot.c_lovers.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_tarot_lovers()
