-- src/main.lua

-- Define constants or state related to the seal within the BSM table
BSM.black_seal_id = 'Black'
BSM.black_seal_id_full = BSM.mod.prefix .. '_' .. BSM.black_seal_id
BSM.state.seal_atlas_key = 'black_seal_atlas'

BSM.utils.sendDebugMessage("Main logic module loading...")

-- --- Asset Registration ---
SMODS.Atlas({
  key = BSM.state.seal_atlas_key,
  path = 'black_seal.png',
  px = 71,
  py = 95,
})
BSM.utils.sendDebugMessage("Atlas registered.")

-- --- Helper function related to the Seal's effect ---
function BSM.utils.add_negative_random_joker()
  local eligible_jokers = {}
  for k, v in pairs(G.jokers.cards) do
    -- Assert that the card is a Joker and does not already have an edition
    if v and v.ability and v.ability.set == 'Joker' and (not v.edition) then
      table.insert(eligible_jokers, v)
    end
  end

  if #eligible_jokers >= 1 then
    local eligible_joker_card = pseudorandom_element(eligible_jokers, pseudoseed("blackseal_neg"))
    if eligible_joker_card then
      eligible_joker_card:set_edition({ negative = true })
      G.E_MANAGER:add_event(Event({
        func = function()
          play_sound('negative')
          eligible_joker_card:juice_up(0.5, 0.5)
          return true
        end
      }))
      BSM.utils.sendDebugMessage("Added Negative to a random eligible Joker.")
      return true
    end
  end
  BSM.utils.sendDebugMessage("No eligible Joker found to add Negative edition.")
  return false
end

--- Calculates and directly sets all seal weights in G.P_SEALS based on config percentage.
--- This should be called once at startup and whenever the config percentage changes.
function BSM.utils.calculate_and_set_seal_weights()
  BSM.utils.sendDebugMessage("Calculating and setting seal weights...")

  local percentage = math.max(0, math.min(100, math.floor(BSM.config.black_seal_percentage)))
  local default_weight = 5 -- Default weight for seals without a defined weight. Check SMODS.poll_seal() implementation.

  -- Calculate the sum of current weights for all *other* seals in G.P_SEALS
  local total_weight = 0
  local weights = {}
  for key, seal_data in pairs(G.P_SEALS) do
      if key ~= BSM.black_seal_id_full then
          local weight = tonumber(seal_data.weight) or default_weight
          if weight > 0 then
              weights[key] = weight
              total_weight = total_weight + weight
          end
      end
  end

  -- Apply the new weights, scaling the other seals accordingly to their original relative weights
  for key, seal_data in pairs(G.P_SEALS) do
      BSM.utils.sendDebugMessage(string.format("G.P_SEALS[%s].weight = %.2f (original weight)", key, seal_data.weight or 5))
      local new_weight = 0
      if key == BSM.black_seal_id_full then
          new_weight = percentage
      else
          new_weight = (100 - percentage) *
              (weights[key] / total_weight) -- Scale other seals to the remaining percentage
      end
      seal_data.weight = new_weight
      BSM.utils.sendDebugMessage(string.format("G.P_SEALS[%s].weight = %.2f (new weight)", key, new_weight))
      G.P_SEALS[key] = seal_data -- Update the seal data in G.P_SEALS
  end

    -- Ensure our seal is registered before proceeding
    if not G.P_SEALS[BSM.black_seal_id_full] then
        BSM.utils.sendDebugMessage(string.format("G.P_SEALS[%s].weight = %.2f (initial weight)", BSM.black_seal_id_full, percentage))
    end

    return percentage
end

-- --- Seal Registration ---
SMODS.Seal({
  key = BSM.black_seal_id,
  atlas = BSM.state.seal_atlas_key,
  pos = { x = 0, y = 0 },
  loc_txt = {
    ['default'] = {
      name = 'Black Seal',
      label = 'Black Seal',
      text = {
        "If you play only this card:",
        "add {C:dark_edition}negative{} to a random {C:attention}Joker{}",
        "remove all {C:dark_edition}Black Seals{} from your deck",
        "{C:inactive}(Effect does not trigger if card is debuffed){}",
      },
    },
  },
  weight = BSM.utils.calculate_and_set_seal_weights(), -- Initial weight
  discovered = false,
  badge_colour = G.C.BLACK,
  calculate = function(self, card, context)
    -- If the not in the proper context and only one not debuffed card played returns early
    if not (context.cardarea == G.play and context.main_scoring and #context.full_hand == 1 and not card.debuff) then return nil end

    BSM.utils.sendDebugMessage("Black Seal effect triggered.")

    -- Tries to add a negative edition to a random eligible joker
    if not BSM.utils.add_negative_random_joker() then return nil end

    local played_card_from_hand_ref = context.full_hand[1]
    G.E_MANAGER:add_event(Event({
      func = function()
        if not G.playing_cards or not played_card_from_hand_ref then return true end

        -- Check if the played card is still in the playing cards list
        BSM.utils.sendDebugMessage("Black Seal removal event running...")

        -- Create a lookup table for cards in hand
        local hand_lookup = setmetatable({}, { __mode = 'k' }) -- Weak keys
        if G.hand and G.hand.cards then
          for _, hand_card in ipairs(G.hand.cards) do
            if hand_card then hand_lookup[hand_card] = true end
          end
        end

        for _, playing_card in ipairs(G.playing_cards) do
          -- Skip if the card can't have a seal or does not have the black seal
          if not playing_card or type(playing_card.set_seal) ~= 'function' or playing_card.seal ~= BSM.black_seal_id_full then
            goto next_playing_card
          end
          -- Check if the card is in hand and not the played card
          local is_in_hand = hand_lookup[playing_card]
          local is_the_played_card = (playing_card == played_card_from_hand_ref)

          -- If the card is in hand but not the played card, skip it
          if is_in_hand and not is_the_played_card then goto next_playing_card end

          -- Finally, remove the seal from the card
          BSM.utils.sendDebugMessage("Removing Black Seal from card (was played or not in hand).")
          playing_card:set_seal(nil, true)

          ::next_playing_card::
        end
        BSM.utils.sendDebugMessage("Finished checking and cleaning Black Seals.")
        return true
      end
    }))
    return {}
  end,
})
BSM.utils.sendDebugMessage("Black Seal registered.")

BSM.utils.sendDebugMessage("Main logic module loaded.")
