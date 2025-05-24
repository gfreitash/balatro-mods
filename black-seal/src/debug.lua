-- src/debug.lua

-- --- Common Utility: Debug Messaging ---
---@param msg string The message to log
function BSM.utils.sendDebugMessage(msg)
  -- Check the config setting before logging
  if BSM.config.debug_logging_enabled then
    if SMODS and SMODS.log then
      SMODS.log(BSM.mod_id .. ": " .. tostring(msg))
    elseif G and G.log and G.log.debug then
      G.log.debug(BSM.mod_id .. ": " .. tostring(msg))
    else
      print(BSM.mod_id .. ": " .. tostring(msg))
    end
  end
end

BSM.utils.sendDebugMessage("Debug module loading...")

-- Only enable debug features if the config option is true
if BSM.config.debug_features_enabled then
  BSM.utils.sendDebugMessage("Debug features enabled. Registering keybinds...")

  -- Keybind to apply Black Seal to hand
  -- Uses the key configured in config.lua
  SMODS.Keybind({
    key_pressed = BSM.config.debug_apply_seal_key,
    name = 'apply_black_seal_to_hand',
    desc = 'Apply Black Seal to all cards in hand ('
        .. BSM.config.debug_apply_seal_key:upper()
        .. ')', -- Show key in description

    action = function(self)
      local seal_key_to_apply = BSM.black_seal_id_full -- Get the full seal key from BSM
      local cards_sealed = 0

      BSM.utils.sendDebugMessage(
        "Attempting to apply seal '"
        .. seal_key_to_apply
        .. "' to hand cards..."
      )

      -- Iterate through the cards currently in the hand area
      for i, card_in_hand in ipairs(G.hand.cards) do
        -- Check if it's a valid card object with the set_seal method
        if card_in_hand and type(card_in_hand.set_seal) == 'function' then
          BSM.utils.sendDebugMessage(
            "Applying seal to card #"
            .. i
            .. " (Current seal: "
            .. tostring(card_in_hand.seal)
            .. ")"
          )

          -- Apply the seal using the correct key
          -- The 'true' arguments are likely for visual/immediate updates
          card_in_hand:set_seal(seal_key_to_apply, true, true)

          cards_sealed = cards_sealed + 1
        end
      end

      BSM.utils.sendDebugMessage(
        "Finished applying seal. Sealed " .. cards_sealed .. " cards."
      )
    end,
  })
  BSM.utils.sendDebugMessage(
    "Keybind '"
    .. BSM.config.debug_apply_seal_key:upper()
    .. "' for applying seal registered."
  )

  -- Define num_polls here so it's accessible for the keybind description
  local num_polls = 10000 -- Use a reasonable number of polls for testing the percentage

  -- Function to test seal weights by polling repeatedly using events
  local function test_seal_weights_evented()
    if not G.GAME or not G.E_MANAGER or not SMODS or not SMODS.poll_seal then
      BSM.utils.sendDebugMessage(
        "Test Seal Weights (Evented): Cannot run test: Game state, Event Manager, or SMODS.poll_seal not available."
      )
      return
    end

    -- Use local variables within this function's scope to track results.
    local seal_counts = {}
    local polls_completed = 0

    BSM.utils.sendDebugMessage(
      "Test Seal Weights (Evented): Scheduling "
      .. num_polls
      .. " seal polls as non-blocking events (using SMODS.poll_seal)..."
    )

    -- Schedule num_polls individual polling events
    for i = 1, num_polls do
      G.E_MANAGER:add_event(
        Event({
          blocking = false, -- These events don't block the game loop
          blockable = true,
          func = function()
            -- Call the standard SMODS.poll_seal function.
            -- It will use the weights we modified in main.lua.
            local returned_seal_key = SMODS.poll_seal({ mod = 10 }) -- Poll from the standard set

            local key_to_count = returned_seal_key or 'NO_SEAL'
            seal_counts[key_to_count] = (seal_counts[key_to_count] or 0) + 1

            polls_completed = polls_completed + 1

            -- Optional: Print progress periodically
            -- if polls_completed % (num_polls / 10) == 0 then
            --     BSM.utils.sendDebugMessage("... " .. polls_completed .. "/" .. num_polls .. " polls completed ...")
            -- end

            return true -- This individual polling event is complete
          end,
        })
      )
    end

    -- Add a final event to the queue to wait for all polling events and print results
    G.E_MANAGER:add_event(
      Event({
        blockable = false,
        blocking = true, -- This event will wait for all preceding non-blocking events
        func = function()
          -- Keep waiting until all polling events have completed
          if polls_completed < num_polls then
            return false -- Not all polls are done yet, keep this event waiting
          end

          -- All poll events have completed! Now print the results with percentages.
          BSM.utils.sendDebugMessage(
            "Test Seal Weights (Evented): Polling complete. Results:"
          )

          local sorted_keys = {}
          for key in pairs(seal_counts) do
            table.insert(sorted_keys, key)
          end
          -- Sort keys alphabetically for consistent output, placing 'NO_SEAL' last
          table.sort(
            sorted_keys,
            function(a, b)
              if a == 'NO_SEAL' then
                return false
              end
              if b == 'NO_SEAL' then
                return true
              end
              return tostring(a) < tostring(b)
            end
          )

          -- Calculate total successful polls (where a seal was returned, excluding 'NO_SEAL')
          local no_seal_count = seal_counts['NO_SEAL'] or 0
          local total_successful_polls = num_polls - no_seal_count

          if #sorted_keys == 0 then
            BSM.utils.sendDebugMessage("  (No results recorded)")
          else
            for _, key in ipairs(sorted_keys) do
              local count = seal_counts[key] or 0
              -- Calculate percentage of total polls
              local percent_of_total = (count / num_polls) * 100

              local line_output = string.format(
                "  Seal '%s': %d times (%.2f%% of total)",
                tostring(key),
                count,
                percent_of_total
              )

              -- If this is an actual seal key (not 'NO_SEAL'), also calculate and add percentage
              -- relative to only the polls where a seal was successfully applied.
              if key ~= 'NO_SEAL' then
                if total_successful_polls > 0 then
                  local percent_of_successful = (count / total_successful_polls)
                      * 100
                  line_output = line_output
                      .. string.format(
                        ", (%.2f%% of seals)",
                        percent_of_successful
                      )
                else
                  -- Handle the edge case where total_successful_polls is 0
                  line_output = line_output .. ", (0.00%% of seals)"
                end
              end

              BSM.utils.sendDebugMessage(line_output)
            end
          end

          BSM.utils.sendDebugMessage(
            "Test Seal Weights (Evented): Finished printing results."
          )

          return true -- This waiting event is now complete
        end,
      })
    )

    BSM.utils.sendDebugMessage(
      "Test Seal Weights (Evented): All polling events scheduled. Results will appear once all polls complete."
    )
  end

  -- Keybind to trigger the event-based seal weight test function
  -- Uses the key configured in config.lua
  SMODS.Keybind({
    key_pressed = BSM.config.debug_test_weights_key, -- Use configured key
    name = 'test_seal_weights_evented',
    -- Reference num_polls which is now defined in the correct scope
    desc = 'Poll SMODS.poll_seal '
        .. num_polls
        .. ' times ('
        .. BSM.config.debug_test_weights_key:upper()
        .. ')',
    action = test_seal_weights_evented, -- Call the evented function
  })
  BSM.utils.sendDebugMessage(
    "Keybind '"
    .. BSM.config.debug_test_weights_key:upper()
    .. "' for testing weights registered."
  )

  -- Function to add a random Joker using SMODS.add_card
  local function add_random_joker()
    BSM.utils.sendDebugMessage("Debug key pressed: Attempting to add random Joker...")
    if SMODS and SMODS.add_card then
      local added_card = SMODS.add_card({ set = 'Joker' })
      if added_card then
        BSM.utils.sendDebugMessage(
          "Successfully added Joker: " .. (added_card.name or 'Unknown Joker')
        )
        -- Optional: Add visual feedback like juicing the card
        if added_card.juice_up then
          added_card:juice_up(0.5, 0.5)
        end
      else
        BSM.utils.sendDebugMessage("SMODS.add_card called, but failed to add a Joker.")
      end
    else
      BSM.utils.sendDebugMessage("Cannot add Joker: SMODS.add_card function not found.")
    end
  end

  -- Keybind to trigger adding a random Joker
  -- Assumes a key like 'j' is configured in config.lua as BSM.config.debug_add_joker_key
  -- Example config entry: debug_add_joker_key = 'j'
  if BSM.config.debug_add_joker_key then
    SMODS.Keybind({
      key_pressed = BSM.config.debug_add_joker_key,
      name = 'add_random_joker',
      desc = 'Add a random Joker ('
          .. BSM.config.debug_add_joker_key:upper()
          .. ')',
      action = add_random_joker,
    })
    BSM.utils.sendDebugMessage(
      "Keybind '"
      .. BSM.config.debug_add_joker_key:upper()
      .. "' for adding Joker registered."
    )
  else
    BSM.utils.sendDebugMessage(
      "Keybind for adding Joker not registered: 'debug_add_joker_key' not found in config."
    )
  end

  local function open_spectral_pack()
    if G.STATE ~= G.STATES.SHOP then
      BSM.utils.sendDebugMessage("Debug key pressed: Not in shop, cannot open pack.")
      return
    end

    local key = 'p_spectral_mega_1'
    local card = Card(G.shop_booster.T.x + G.shop_booster.T.w/2,
    G.shop_booster.T.y, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, G.P_CENTERS[key], {bypass_discovery_center = true, bypass_discovery_ui = true})
    
    G.FUNCS.use_card({config={ref_table = card }})
  end

  if BSM.config.debug_open_spectral_pack_key then
    SMODS.Keybind({
      key_pressed = BSM.config.debug_open_spectral_pack_key,
      name = 'open_spectral_pack',
      desc = 'Open Spectral Pack ('
          .. BSM.config.debug_open_spectral_pack_key:upper()
          .. ')',
      action = open_spectral_pack,
    })
    BSM.utils.sendDebugMessage(
      "Keybind '"
      .. BSM.config.debug_open_spectral_pack_key:upper()
      .. "' for opening spectral pack registered."
    )
  else
    BSM.utils.sendDebugMessage(
      "Keybind for opening spectral pack not registered: 'debug_open_spectral_pack_key' not found in config."
    )
  end

  local function restart_game()
    SMODS.restart_game()
  end

  SMODS.Keybind({
    key_pressed = 'f12',
    name = 'restart_game',
    desc = 'Restart Game (F12)',
    action = restart_game,
  })
  BSM.utils.sendDebugMessage("Keybind 'F12' for restarting game registered.")
else
  BSM.utils.sendDebugMessage("Debug features disabled in config.")
end

BSM.utils.sendDebugMessage("Debug module loaded.")
