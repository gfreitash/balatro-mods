---@diagnostic disable: duplicate-set-field, duplicate-doc-field

-- Store original functions
QOL_BUNDLE.original = QOL_BUNDLE.original or {}
QOL_BUNDLE.original.Card_is_suit = Card.is_suit
QOL_BUNDLE.original.Blind_debuff_card = Blind.debuff_card
QOL_BUNDLE.original.Game_init_game_object = Game.init_game_object
QOL_BUNDLE.original.poll_edition = poll_edition
QOL_BUNDLE.original.Card_use_consumeable = Card.use_consumeable
QOL_BUNDLE.original.Card_can_use_consumeable = Card.can_use_consumeable
QOL_BUNDLE.original.Card_set_ability = Card.set_ability

-- Override Card:is_suit with wildcard and blurred joker fixes
function Card:is_suit(suit, bypass_debuff, flush_calc, trying_to_debuff)
    -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit called with suit: " .. tostring(suit) .. ", bypass_debuff: " .. tostring(bypass_debuff) .. ", flush_calc: " .. tostring(flush_calc) .. ", trying_to_debuff: " .. tostring(trying_to_debuff))
    if not QOL_BUNDLE.config.wildcard_fix_enabled then
        -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit called without wildcard fix enabled, using original implementation.")
        return QOL_BUNDLE.original.Card_is_suit(self, suit, bypass_debuff, flush_calc)
    end

    if not flush_calc and self.debuff and not bypass_debuff then
        return nil
    end

    if self.ability.effect == 'Stone Card' then
        return false
    end

    if self.ability.name == "Wild Card" then
        if trying_to_debuff then
            return false
        else
            return not flush_calc or not self.debuff
        end
    end

    local has_smeared_joker = next(find_joker('Smeared Joker'))
    -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit has_smeared_joker: " .. tostring(has_smeared_joker))
    if has_smeared_joker then
        if trying_to_debuff then
            -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit trying to debuff with Smeared Joker, returning false.")
            return false
        end

        local is_base_red = self.base.suit == 'Hearts' or self.base.suit == 'Diamonds'
        local is_target_red = suit == 'Hearts' or suit == 'Diamonds'
        -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit is_base_red: " .. tostring(is_base_red) .. ", is_target_red: " .. tostring(is_target_red))

        if is_base_red == is_target_red then
            return true
        end
    end

    -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit returning base suit match: " .. tostring(self.base.suit == suit))
    return self.base.suit == suit
end


-- Override Game:init_game_object to handle Joker Max
-- Calls the original function first and replace shop.joker_max with the mod's config value
function Game:init_game_object()
    result = QOL_BUNDLE.original.Game_init_game_object(self)
    RIOSODU_SHARED.utils.sendDebugMessage("Setting shop.joker_max to: " .. (QOL_BUNDLE.config.joker_max_enabled and QOL_BUNDLE.config.joker_max_value or 2))
    result.shop.joker_max = QOL_BUNDLE.config.joker_max_enabled and QOL_BUNDLE.config.joker_max_value or 2
    return result
end

-- Override poll_edition to make foil, holo, and poly editions unweighted
function poll_edition(_key, _mod, _no_neg, _guaranteed)
    if not QOL_BUNDLE.config.unweighted_editions_enabled then
        return QOL_BUNDLE.original.poll_edition(_key, _mod, _no_neg, _guaranteed)
    end

    _mod = _mod or 1
    local edition_poll = pseudorandom(pseudoseed(_key or 'edition_generic'))

    -- Preserve negative edition probability
    if _guaranteed then
        if edition_poll > 1 - 0.003*25 and not _no_neg then
            return {negative = true}
        end
    else
        if edition_poll > 1 - 0.003*_mod and not _no_neg then
            return {negative = true}
        end
    end


    -- Check if an edition (foil, holo, poly) would have been rolled by original logic
    -- This is the crucial part: we check against the *original* threshold for any non-negative edition
    -- and then redistribute if it falls within that range.
    local original_foil_threshold = 1 - (0.04 * G.GAME.edition_rate * _mod)

    if _guaranteed then
        original_foil_threshold = 1 - (0.04 * 25)
    end

    if edition_poll > original_foil_threshold then
        local unweighted_roll = pseudorandom(pseudoseed('unweighted_edition_' .. (_key or 'generic')))
        if unweighted_roll < 1/3 then
            return {foil = true}
        elseif unweighted_roll < 2/3 then
            return {holo = true}
        else
            return {polychrome = true}
        end
    end

    return nil
end


-- Paperback compatibility: Override Blind.debuff_card to handle jester_of_nihil properly
local source_blind_debuff_card = function (self, card, from_blind)
    if self.debuff and not self.disabled and card.area ~= G.jokers then
        if self.debuff.suit and card:is_suit(self.debuff.suit, true) then
            card:set_debuff(true)
            return
        end
        if self.debuff.is_face =='face' and card:is_face(true) then
            card:set_debuff(true)
            return
        end
        if self.name == 'The Pillar' and card.ability.played_this_ante then
            card:set_debuff(true)
            return
        end
        if self.debuff.value and self.debuff.value == card.base.value then
            card:set_debuff(true)
            return
        end
        if self.debuff.nominal and self.debuff.nominal == card.base.nominal then
            card:set_debuff(true)
            return
        end
    end
    if self.name == 'Crimson Heart' and not self.disabled and card.area == G.jokers then 
        return
    end
    if self.name == 'Verdant Leaf' and not self.disabled and card.area ~= G.jokers then card:set_debuff(true); return end
    card:set_debuff(false)
end

function Blind:debuff_card(card, from_blind)
    local ret = source_blind_debuff_card(self, card, from_blind)

    if PB_UTIL then
        -- Handle jester_of_nihil compatibility by re-implementing its logic with the trying_to_debuff parameter
        if card.area ~= G.jokers then
            for k, v in ipairs(SMODS.find_card('j_paperback_jester_of_nihil')) do
                if card:is_suit(v.ability.extra.suit, false, false, true) then
                    card:set_debuff(true)
                    if card.debuff then card.debuffed_by_blind = true end
                end
            end
        end
    end

    return ret
end

function Card:can_use_consumeable(any_state, skip_check)
    -- Early return if not Sigil/Ouija OR if the overrides are disabled
    if not self.ability
        or (self.ability.name ~= 'Ouija' and self.ability.name ~= 'Sigil')
        or (self.ability.name == 'Ouija' and not QOL_BUNDLE.config.ouija_control_enabled)
        or (self.ability.name == 'Sigil' and not QOL_BUNDLE.config.sigil_control_enabled)
    then
        return QOL_BUNDLE.original.Card_can_use_consumeable(self, any_state, skip_check)
    end

    -- For controlled Sigil/Ouija, we need exactly 1 highlighted card
    -- Call original first to do basic checks
    local can_use_original = QOL_BUNDLE.original.Card_can_use_consumeable(self, any_state, skip_check)
    if not can_use_original then
        return false
    end

    -- Additional requirement: exactly 1 highlighted card for controlled mode
    if not G.hand or not G.hand.highlighted or #G.hand.highlighted ~= 1 then
        return false
    end

    return true
end

-- Override Card:use_consumeable to handle controlled Sigil and Ouija spectral cards
function Card:use_consumeable(area, copier)
    -- Early return if not Sigil/Ouija OR if overrides are disabled
    if not self.ability
        or (self.ability.name ~= 'Sigil' and self.ability.name ~= 'Ouija')
        or (self.ability.name == 'Sigil' and not QOL_BUNDLE.config.sigil_control_enabled)
        or (self.ability.name == 'Ouija' and not QOL_BUNDLE.config.ouija_control_enabled)
    then
        return QOL_BUNDLE.original.Card_use_consumeable(self, area, copier)
    end

    -- Standard initial setup steps (from original)
    stop_use()
    if not copier then set_consumeable_usage(self) end
    if self.debuff then return nil end
    local used_tarot = copier or self

    -- Get reference card for controlled behavior
    local reference_card = G.hand.highlighted and G.hand.highlighted[1]
    if not reference_card then
        -- Fallback to original if no reference card
        return QOL_BUNDLE.original.Card_use_consumeable(self, area, copier)
    end

    -- Follow original Sigil/Ouija flow with controlled suit/rank selection
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
        play_sound('tarot1')
        used_tarot:juice_up(0.3, 0.5)
        return true end }))
    
    for i=1, #G.hand.cards do
        local percent = 1.15 - (i-0.999)/(#G.hand.cards-0.998)*0.3
        G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() 
            G.hand.cards[i]:flip()
            play_sound('card1', percent)
            G.hand.cards[i]:juice_up(0.3, 0.3)
            return true 
        end }))
    end
    delay(0.2)
    
    if self.ability.name == 'Sigil' then
        -- Use reference card's suit instead of random
        local reference_suit = reference_card.base.suit
        local _suit = reference_suit == 'Spades' and 'S' or
                     reference_suit == 'Hearts' and 'H' or
                     reference_suit == 'Diamonds' and 'D' or
                     reference_suit == 'Clubs' and 'C' or 'S'
        
        for i=1, #G.hand.cards do
            G.E_MANAGER:add_event(Event({func = function()
                local card = G.hand.cards[i]
                local suit_prefix = _suit..'_'
                local rank_suffix = card.base.id < 10 and tostring(card.base.id) or
                                    card.base.id == 10 and 'T' or card.base.id == 11 and 'J' or
                                    card.base.id == 12 and 'Q' or card.base.id == 13 and 'K' or
                                    card.base.id == 14 and 'A'
                card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
            return true end }))
        end  
    end
    
    if self.ability.name == 'Ouija' then
        -- Use reference card's rank instead of random
        local reference_rank_id = reference_card.base.id
        local _rank = reference_rank_id < 10 and tostring(reference_rank_id) or
                     reference_rank_id == 10 and 'T' or reference_rank_id == 11 and 'J' or
                     reference_rank_id == 12 and 'Q' or reference_rank_id == 13 and 'K' or
                     reference_rank_id == 14 and 'A'
        
        for i=1, #G.hand.cards do
            G.E_MANAGER:add_event(Event({func = function()
                local card = G.hand.cards[i]
                local suit_prefix = string.sub(card.base.suit, 1, 1)..'_'
                local rank_suffix = _rank
                card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
            return true end }))
        end  
        G.hand:change_size(-1)
    end
    
    for i=1, #G.hand.cards do
        local percent = 0.85 + (i-0.999)/(#G.hand.cards-0.998)*0.3
        G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() 
            G.hand.cards[i]:flip()
            play_sound('tarot2', percent, 0.6)
            G.hand.cards[i]:juice_up(0.3, 0.3)
            return true 
        end }))
    end
    delay(0.5)
end

function Card:set_ability(center, initial, delay_sprites)
    QOL_BUNDLE.original.Card_set_ability(self, center, initial, delay_sprites)
    self.ability.rounds_played_at_create = G.GAME and G.GAME.round or 0
end

-- Update Sigil spectral card text based on configuration
function QOL_BUNDLE.utils.update_sigil_text()
    local loc_text = localize('sigil_loc_text_original')
    
    if QOL_BUNDLE.config.sigil_control_enabled then
        loc_text = localize('sigil_loc_text_controlled')
    end
    
    G.localization.descriptions.Spectral.c_sigil.text = loc_text
    init_localization()
end

-- Update Ouija spectral card text based on configuration
function QOL_BUNDLE.utils.update_ouija_text()
    local loc_text = localize('ouija_loc_text_original')
    
    if QOL_BUNDLE.config.ouija_control_enabled then
        loc_text = localize('ouija_loc_text_controlled')
    end
    
    G.localization.descriptions.Spectral.c_ouija.text = loc_text
    init_localization()
end

-- Register hooks for text updates
RIOSODU_SHARED.register_hook('on_game_start', QOL_BUNDLE.utils.update_sigil_text)
RIOSODU_SHARED.register_hook('on_game_start', QOL_BUNDLE.utils.update_ouija_text)

