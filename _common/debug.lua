-- Common debug system
RIOSODU_SHARED.debug = RIOSODU_SHARED.debug or {
  registered_keybinds = {}
}

function RIOSODU_SHARED.utils.sendDebugMessage(msg, mod_id)
  if RIOSODU_SHARED.config and RIOSODU_SHARED.config.debug_logging_enabled then
    local full_msg = (mod_id or 'riosodu_shared') .. ": " .. tostring(msg)
    if SMODS and SMODS.log then
      SMODS.log(full_msg)
    elseif G and G.log and G.log.debug then
      G.log.debug(full_msg)
    else
      print(full_msg)
    end
  end
end

function RIOSODU_SHARED.debug.register_keybind(mod_id, keybind_def)
  if RIOSODU_SHARED.config.debug_features_enabled then
    local kb = keybind_def
    kb.desc = kb.desc .. ' (' .. kb.key_pressed:upper() .. ')'
    SMODS.Keybind(kb)
    RIOSODU_SHARED.utils.sendDebugMessage(mod_id,
      "Registered debug keybind: " .. kb.name)
  end
end

-- Extended function to add joker and modify cards with optional enhancements, seals, editions
function RIOSODU_SHARED.debug.add_joker_and_modify_cards(joker_name, joker_key, card_rank, enhancement, seal, edition, apply_to_selected)
    local mod_id = 'riosodu_shared'
    RIOSODU_SHARED.utils.sendDebugMessage("Attempting to add joker " .. joker_name .. " and modify cards...", mod_id)
    
    -- Add the joker (always with negative edition)
    local target_joker = find_joker(joker_name)
    if not target_joker or #target_joker == 0 then
        if SMODS and SMODS.add_card then
            local added_card = SMODS.add_card({set='Joker', key=joker_key, edition='e_negative'})
            if added_card then
                RIOSODU_SHARED.utils.sendDebugMessage("Successfully added " .. joker_name .. " Joker with negative edition.", mod_id)
                if added_card.juice_up then
                    added_card:juice_up(0.5, 0.5)
                end
            else
                RIOSODU_SHARED.utils.sendDebugMessage("SMODS.add_card failed to add " .. joker_name .. " Joker.", mod_id)
            end
        else
            RIOSODU_SHARED.utils.sendDebugMessage("SMODS.add_card function not found.", mod_id)
        end
    else
        RIOSODU_SHARED.utils.sendDebugMessage(joker_name .. " Joker already exists.", mod_id)
    end
    
    -- Determine which cards to modify
    local cards_to_modify = {}
    if apply_to_selected and G.hand.highlighted and #G.hand.highlighted > 0 then
        cards_to_modify = G.hand.highlighted
        RIOSODU_SHARED.utils.sendDebugMessage("Modifying " .. #cards_to_modify .. " selected cards.", mod_id)
    elseif G.hand and G.hand.cards then
        cards_to_modify = G.hand.cards
        RIOSODU_SHARED.utils.sendDebugMessage("Modifying all " .. #cards_to_modify .. " cards in hand.", mod_id)
    else
        RIOSODU_SHARED.utils.sendDebugMessage("Cannot modify cards: Hand not available.", mod_id)
        return
    end
    
    -- Modify the cards
    local suits = {'Spades', 'Hearts', 'Clubs', 'Diamonds'}
    
    for i, card_in_hand in ipairs(cards_to_modify) do
        if card_in_hand then
            -- Change card rank if specified
            if card_rank and type(card_in_hand.set_base) == 'function' then
                local random_suit = suits[math.random(#suits)]
                local new_card_key = string.sub(random_suit, 1, 1) .. '_' .. card_rank
                
                local card_data = G.P_CARDS[new_card_key]
                if card_data then
                    card_in_hand:set_base(card_data)
                    RIOSODU_SHARED.utils.sendDebugMessage("Transformed card #" .. i .. " to " .. random_suit .. " " .. card_rank, mod_id)
                else
                    RIOSODU_SHARED.utils.sendDebugMessage("Failed to find card data for " .. new_card_key, mod_id)
                end
            end
            
            -- Apply enhancement if specified
            if enhancement then
                local enhancement_center = G.P_CENTERS[enhancement]
                if enhancement_center then
                    card_in_hand.config.center = enhancement_center
                    card_in_hand:set_ability(enhancement_center, nil, true)
                    RIOSODU_SHARED.utils.sendDebugMessage("Applied enhancement " .. enhancement .. " to card #" .. i, mod_id)
                else
                    RIOSODU_SHARED.utils.sendDebugMessage("Failed to find enhancement " .. enhancement, mod_id)
                end
            end
            
            -- Apply seal if specified
            if seal then
                card_in_hand:set_seal(seal, nil, true)
                RIOSODU_SHARED.utils.sendDebugMessage("Applied seal " .. seal .. " to card #" .. i, mod_id)
            end
            
            -- Apply edition if specified
            if edition and card_in_hand.set_edition then
                local edition_table = {}
                edition_table[edition] = true
                card_in_hand:set_edition(edition_table, true)
                RIOSODU_SHARED.utils.sendDebugMessage("Applied edition " .. edition .. " to card #" .. i, mod_id)
            end
            
            -- Visual feedback
            if card_in_hand.juice_up then
                card_in_hand:juice_up(0.5, 0.5)
            end
        end
    end
    
    RIOSODU_SHARED.utils.sendDebugMessage("Finished modifying cards.", mod_id)
end

RIOSODU_SHARED.debug.register_keybind('riosodu_shared', {
  key_pressed = 'f12',
  name = 'restart_game',
  desc = 'Restart Game',
  action = function() SMODS.restart_game() end
})

-- Debug feature: Add joker by key via textbox
function RIOSODU_SHARED.debug.show_joker_input()
    if not G.GAME.blind then return end

    local input_data = { joker = RIOSODU_SHARED.config.last_joker_key or 'joker' }

    -- Create the textbox UI with ID
    local textbox_ui = create_text_input({
        colour = G.C.BLUE,
        hooked_colour = G.C.ORANGE,
        w = 4,
        h = 0.8,
        text_scale = 0.5,
        max_length = 100,
        all_caps = false,
        prompt_text = 'Enter joker key...',
        ref_table = input_data,
        ref_value = 'joker',
        extended_corpus = true,
        id = 'joker_input_textbox'
    })
    
    -- Create the popup
    local popup = create_UIBox_generic_options({
        back_colour = G.C.BLACK,
        contents = {
            {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
                {n = G.UIT.T, config = {text = "Add Joker (Negative)", scale = 0.6, colour = G.C.WHITE}}
            }},
            {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
                textbox_ui
            }},
            {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
                {n = G.UIT.T, config = {text = "Press ENTER to add, ESC to cancel", scale = 0.4, colour = G.C.UI.TEXT_LIGHT}}
            }}
        }
    })
    
    -- Show the popup
    G.FUNCS.overlay_menu({
        definition = popup,
        config = {align = "cm", offset = {x=0, y=0}}
    })

    -- Autofocus the text input after popup is shown
    if G.OVERLAY_MENU then
        local text_input_container = G.OVERLAY_MENU:get_UIE_by_ID('joker_input_textbox')
        if text_input_container then
            G.FUNCS.select_text_input(text_input_container)
            RIOSODU_SHARED.utils.sendDebugMessage("Text input focused successfully", 'riosodu_shared')
        else
            RIOSODU_SHARED.utils.sendDebugMessage("ERROR: Could not find text input container", 'riosodu_shared')
        end
    else
        RIOSODU_SHARED.utils.sendDebugMessage("ERROR: G.OVERLAY_MENU not found", 'riosodu_shared')
    end
    
    -- Store original function ONLY if we haven't already stored it
    if not RIOSODU_SHARED.debug.original_text_input_key then
        RIOSODU_SHARED.debug.original_text_input_key = G.FUNCS.text_input_key
        RIOSODU_SHARED.utils.sendDebugMessage("Stored original text_input_key function for first time", 'riosodu_shared')
    else
        RIOSODU_SHARED.utils.sendDebugMessage("Using previously stored original function", 'riosodu_shared')
    end
    
    -- Hook into text input processing
    G.FUNCS.text_input_key = function(e)
        RIOSODU_SHARED.utils.sendDebugMessage("Key pressed while joker input active: " .. tostring(e.key), 'riosodu_shared')
        if e.key == 'return' then
            -- Store the last joker key before adding
            RIOSODU_SHARED.config.last_joker_key = input_data.joker
            -- Save the config
            SMODS.save_mod_config(RIOSODU_SHARED.mod)
            -- Add the joker
            RIOSODU_SHARED.debug.add_joker_by_key(input_data.joker)
            RIOSODU_SHARED.debug.close_joker_input()
            return
        end

        return RIOSODU_SHARED.debug.original_text_input_key(e)
    end
end

function RIOSODU_SHARED.debug.close_joker_input()
    RIOSODU_SHARED.utils.sendDebugMessage("Closing joker input", 'riosodu_shared')
    -- Restore the original function
    if RIOSODU_SHARED.debug.original_text_input_key then
        G.FUNCS.text_input_key = RIOSODU_SHARED.debug.original_text_input_key
        RIOSODU_SHARED.debug.original_text_input_key = nil
    end

    G.FUNCS.exit_overlay_menu()
end

function RIOSODU_SHARED.debug.add_joker_by_key(joker_key)
    local mod_id = 'riosodu_shared'
    if not joker_key or joker_key == '' then
        RIOSODU_SHARED.debug.show_nope_animation()
        return
    end

    -- Ensure the joker key has the j_ prefix
    if string.sub(joker_key, 1, 2) ~= 'j_' then
        joker_key = 'j_' .. joker_key
        RIOSODU_SHARED.utils.sendDebugMessage("Prepended 'j_' to joker key: " .. joker_key, mod_id)
    end

    -- Check if joker exists in the game's centers
    local joker_center = G.P_CENTERS[joker_key]
    if not joker_center or joker_center.set ~= 'Joker' then
        RIOSODU_SHARED.utils.sendDebugMessage("Joker key '" .. joker_key .. "' not found or invalid", mod_id)
        RIOSODU_SHARED.debug.show_nope_animation()
        return
    end
    
    -- Add the joker with negative edition
    if SMODS and SMODS.add_card then
        local added_card = SMODS.add_card({set='Joker', key=joker_key, edition='e_negative'})
        if added_card then
            RIOSODU_SHARED.utils.sendDebugMessage("Successfully added " .. joker_key .. " with negative edition", mod_id)
            if added_card.juice_up then
                added_card:juice_up(0.5, 0.5)
            end
        else
            RIOSODU_SHARED.utils.sendDebugMessage("Failed to add joker: " .. joker_key, mod_id)
            RIOSODU_SHARED.debug.show_nope_animation()
        end
    else
        RIOSODU_SHARED.utils.sendDebugMessage("SMODS.add_card function not found", mod_id)
        RIOSODU_SHARED.debug.show_nope_animation()
    end
end

function RIOSODU_SHARED.debug.show_nope_animation()
    -- Create a dummy tarot card for the animation
    local temp_tarot = Card(0, 0, 0.8, 1.1, G.P_CENTERS.c_fool, G.P_CENTERS.c_fool)
    temp_tarot.T.x, temp_tarot.T.y = G.ROOM.T.w/2, G.ROOM.T.h/2
    
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.1, func = function()
        attention_text({
            text = localize('k_nope_ex'),
            scale = 1.3, 
            hold = 1.4,
            major = temp_tarot,
            backdrop_colour = G.C.SECONDARY_SET.Tarot,
            align = 'cm',
            offset = {x = 0, y = 0},
            silent = true
        })
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.06*G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
            play_sound('tarot2', 0.76, 0.4)
            return true 
        end}))
        play_sound('tarot2', 1, 0.4)
        temp_tarot:juice_up(0.3, 0.5)
        return true 
    end}))
end

RIOSODU_SHARED.debug.register_keybind('riosodu_shared', {
  key_pressed = 'f10',
  name = 'add_joker_textbox',
  desc = 'Open Add Joker Textbox',
  action = function() RIOSODU_SHARED.debug.show_joker_input() end
})

--- Recursively prints a Lua table with configurable depth and handles circular references.
-- This function is a wrapper for a recursive helper, providing a simple user-facing API.
-- @param t The table to be printed.
-- @param max_depth The maximum recursion depth. Defaults to 1 if nil or not provided.
--
-- The function will print keys in a consistent order using `pairs()`.
-- It also detects and handles cyclic table references to prevent infinite loops.

function RIOSODU_SHARED.debug.print_table(t, max_depth)
    -- Internal helper function to handle the recursion
    -- The visited and indent parameters are for internal use only
    local function _print_table_recursive(t, max_depth, visited, indent)
        -- Check if the current depth exceeds the max_depth
        if indent > max_depth then
            print(string.rep("  ", indent) .. "... (max depth reached)")
            return
        end

        -- Check if the table has already been visited (to detect cyclic references)
        -- Lua tables can be used as keys, making this simple and effective
        if visited[t] then
            print(string.rep("  ", indent) .. "... (cyclic reference)")
            return
        end

        -- Mark the current table as visited before processing its contents
        -- This prevents infinite loops
        visited[t] = true

        -- Loop through the key-value pairs
        for k, v in pairs(t) do
            local indent_str = string.rep("  ", indent)
            local key_str = type(k) == "number" and string.format("[%d]", k) or tostring(k)

            -- Check the type of the value
            if type(v) == "table" then
                print(indent_str .. key_str .. ": {")
                -- Recursively call the function for the nested table, increasing the indent
                _print_table_recursive(v, max_depth, visited, indent + 1)
                print(indent_str .. "}")
            else
                -- Print the key and the non-table value
                print(indent_str .. key_str .. ": " .. tostring(v))
            end
        end
    end

    -- Handle the max_depth parameter for the user-facing function
    -- Default to 1 if it's nil or not a number
    max_depth = (type(max_depth) == "number") and max_depth or 1
    
    -- Check if the input is actually a table before starting
    if type(t) ~= "table" then
        print(tostring(t))
        return
    end

    -- Start the process with the initial call
    print("{")
    _print_table_recursive(t, max_depth, {}, 1)
    print("}")
end
