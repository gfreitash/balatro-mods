-- qol-bundle/src/debug.lua

QOL_BUNDLE.debug = QOL_BUNDLE.debug or {}

function QOL_BUNDLE.debug.test_poll_edition(num_calls, guaranteed_edition)
    num_calls = num_calls or 10000
    local results = {
        foil = 0,
        holo = 0,
        polychrome = 0,
        negative = 0,
        none = 0
    }

    RIOSODU_SHARED.utils.sendDebugMessage("Starting poll_edition test with " .. num_calls .. " calls (guaranteed_edition: " .. tostring(guaranteed_edition) .. ")...")

    for i = 1, num_calls do
        local edition = poll_edition('test_key_' .. i, 1, false, guaranteed_edition)
        if edition then
            if edition.foil then
                results.foil = results.foil + 1
            elseif edition.holo then
                results.holo = results.holo + 1
            elseif edition.polychrome then
                results.polychrome = results.polychrome + 1
            elseif edition.negative then
                results.negative = results.negative + 1
            end
        else
            results.none = results.none + 1
        end
    end

    RIOSODU_SHARED.utils.sendDebugMessage("--- poll_edition Test Results ---")
    RIOSODU_SHARED.utils.sendDebugMessage("Total Calls: " .. num_calls)
    for k, v in pairs(results) do
        local percentage = string.format("%.2f", (v / num_calls) * 100)
        RIOSODU_SHARED.utils.sendDebugMessage(string.format("%s: %d (%.2f%%)", k, v, percentage))
    end
    RIOSODU_SHARED.utils.sendDebugMessage("---------------------------------")
end

-- Refactored function to add joker and transform hand
function QOL_BUNDLE.debug.add_joker_and_transform_hand(joker_name, joker_key, card_rank, skip_transform)
    RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "Attempting to add Negative " .. joker_name .. " Joker and transform hand to " .. card_rank .. "s...")
    local target_joker = find_joker(joker_name)
    if not target_joker or #target_joker == 0 then
        if SMODS and SMODS.add_card then
            local added_card = SMODS.add_card({set='Joker', key=joker_key, edition='e_negative'})
            if added_card then
                RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "Successfully added Negative " .. joker_name .. " Joker.")
                if added_card.juice_up then
                    added_card:juice_up(0.5, 0.5)
                end
            else
                RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "SMODS.add_card failed to add Negative " .. joker_name .. " Joker.")
            end
        else
            RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "SMODS.add_card function not found.")
        end
    else
        RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, joker_name .. " Joker already exists.")
    end
    
    if not G.hand then
        RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "Cannot transform hand: Hand not available.")
        return
    end

    if skip_transform then
        RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "Skipping transform hand.")
        return
    end

    local suits = {'Spades', 'Hearts', 'Clubs', 'Diamonds'}

    for i, card_in_hand in ipairs(G.hand.cards) do
        if card_in_hand and type(card_in_hand.set_base) == 'function' then
            local random_suit = suits[math.random(#suits)]
            local new_card_key = string.sub(random_suit, 1, 1) .. '_' .. card_rank
            
            local card_data = G.P_CARDS[new_card_key]
            if card_data then
                card_in_hand:set_base(card_data)
                card_in_hand:juice_up(0.5, 0.5)
                RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "Transformed card #" .. i .. " to " .. random_suit .. " " .. card_rank)
            else
                RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "Failed to find card data for " .. new_card_key)
            end
        end
    end
    RIOSODU_SHARED.utils.sendDebugMessage(QOL_BUNDLE.mod_id, "Finished transforming hand to " .. card_rank .. "s.")
end

function QOL_BUNDLE.debug.register_debug_keybinds()
    RIOSODU_SHARED.debug.register_keybind(QOL_BUNDLE.mod_id, {
        key_pressed = 'f11',
        name = 'test_unweighted_editions',
        desc = 'Test Unweighted Editions (10000 polls)',
        action = function() QOL_BUNDLE.debug.test_poll_edition(10000, true) end
    })
    RIOSODU_SHARED.debug.register_keybind(QOL_BUNDLE.mod_id, {
        key_pressed = '8',
        name = 'eight_ball_debug_action',
        desc = 'Adds Negative 8 Ball Joker & Transforms hand to 8s',
        action = function() QOL_BUNDLE.debug.add_joker_and_transform_hand('8 Ball', 'j_8_ball', '8') end
    })
    RIOSODU_SHARED.debug.register_keybind(QOL_BUNDLE.mod_id, {
        key_pressed = '9',
        name = 'hit_the_road_debug_action',
        desc = 'Adds Negative Hit the Road Joker & Transforms hand to Jacks',
        action = function() QOL_BUNDLE.debug.add_joker_and_transform_hand('Hit the Road', 'j_hit_the_road', 'J') end
    })
end
