-- Update Smeared Joker text based on configuration and Paperback availability
function QOL_BUNDLE.funcs.get_ownership_joker_smeared()
    if not QOL_BUNDLE.config.wildcard_fix_enabled then
        return
    end

    QOL_BUNDLE.state.smeared_joker = SMODS.Joker:take_ownership('j_smeared', { 
        loc_vars = function (self, info_queue, card)
            if PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
                -- Use Paperback's light/dark suit terminology
                info_queue[#info_queue + 1] = PB_UTIL.suit_tooltip('light')
                info_queue[#info_queue + 1] = PB_UTIL.suit_tooltip('dark')
            end
        end
     })

    local apply_localization = function()
        local loc = localize('j_smeared_original')
        if QOL_BUNDLE.config.wildcard_fix_enabled and PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
            loc = localize('j_smeared_paperback')
        end
        G.localization.descriptions.Joker.j_smeared.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_smeared()