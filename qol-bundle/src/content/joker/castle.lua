-- Override Castle joker to support checkered deck enhancement
function QOL_BUNDLE.funcs.get_ownership_joker_castle()
    if not QOL_BUNDLE.config.castle_checkered_enabled then
        return
    end

    QOL_BUNDLE.state.castle = SMODS.Joker:take_ownership('j_castle', {
        loc_vars = function(self, info_queue, center)
            local chosen_group = G.GAME and G.GAME.current_round and G.GAME.current_round.castle_card_group or 'dark'

            -- Check Paperback compatibility for custom light/dark suits
            if PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
                -- Use Paperback's light/dark suit terminology
                tooltip = chosen_group == 'light' and PB_UTIL.suit_tooltip('light') or PB_UTIL.suit_tooltip('dark')
                info_queue[#info_queue + 1] = tooltip

                local group_name = chosen_group == 'light' and localize({
                    type = 'name_text', set='Other', key='paperback_light_suits'
                }) or localize({
                    type = 'name_text', set='Other', key='paperback_dark_suits'
                })
                RIOSODU_SHARED.debug.print_table(G.C.SUITS)
                color = chosen_group == 'light' and G.C.PAPERBACK_LIGHT_SUIT or G.C.PAPERBACK_DARK_SUIT

                -- RIOSODU_SHARED.utils.sendDebugMessage("Chosen colour: " .. color)
                return {
                    vars = {
                        center.ability.extra.chip_mod, -- #1# - chip increment
                        group_name,                     -- #2# - "light suits" or "dark suits"
                        center.ability.extra.chips,      -- #3# - current chips
                        colours = {color}
                    }
                }
            else
                -- Default logic: show individual suits
                local light_suits = {'Hearts', 'Diamonds'}
                local dark_suits = {'Spades', 'Clubs'}
                local suits = chosen_group == 'light' and light_suits or dark_suits

                local suit1_name = localize(suits[1], 'suits_singular')
                local suit2_name = localize(suits[2], 'suits_singular')
                local suit1_color = G.C.SUITS[suits[1]]
                local suit2_color = G.C.SUITS[suits[2]]

                return {
                    vars = {
                        center.ability.extra.chip_mod, -- #1# - chip increment  
                        suit1_name,                     -- #2# - first suit name
                        suit2_name,                     -- #3# - second suit name
                        center.ability.extra.chips,     -- #4# - current chips
                        colours = {suit1_color, suit2_color,}
                    },
                }
            end
        end,
        calculate = function(self, card, context)
            if context.discard and not context.other_card.debuff and not context.blueprint then
                local is_matching_suit = false

                -- Use the chosen group from reset_castle_card
                local chosen_group = G.GAME.current_round.castle_card_group or 'dark'

                -- Check Paperback compatibility for custom light/dark suits
                if PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
                    -- Use Paperback's is_suit function
                    is_matching_suit = PB_UTIL.is_suit(context.other_card, chosen_group)
                else
                    -- Default logic when Paperback is not available
                    local light_suits = {'Hearts', 'Diamonds'}
                    local dark_suits = {'Spades', 'Clubs'}
                    local suits_to_check = chosen_group == 'light' and light_suits or dark_suits

                    for _, suit in ipairs(suits_to_check) do
                        if context.other_card:is_suit(suit) then
                            is_matching_suit = true
                            break
                        end
                    end
                end

                RIOSODU_SHARED.utils.sendDebugMessage("Hello, I'm a castle joker! I'm matching suit: " .. tostring(is_matching_suit))
                if is_matching_suit then
                    card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
                    return {
                        message = localize('k_upgrade_ex'),
                        card = card,
                        colour = G.C.CHIPS
                    }
                end
            end
            return nil
        end,
    })

    local apply_localization = function()
        local loc = localize('j_castle_original')
        if QOL_BUNDLE.config.castle_checkered_enabled then
            if PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
                loc = localize('j_castle_checkered_paperback')
            else
                loc = localize('j_castle_checkered')
            end
        end
        G.localization.descriptions.Joker.j_castle.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_castle()
