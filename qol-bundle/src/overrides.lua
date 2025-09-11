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
QOL_BUNDLE.original.create_card_for_shop = create_card_for_shop
QOL_BUNDLE.original.reset_castle_card = reset_castle_card

-- Store Paperback's is_suit function if it exists to avoid infinite recursion
if PB_UTIL and PB_UTIL.is_suit then
    QOL_BUNDLE.original.PB_UTIL_is_suit = PB_UTIL.is_suit
    
    -- Override PB_UTIL.is_suit to use original Card:is_suit
    function PB_UTIL.is_suit(card, type)
        for _, v in ipairs(type == 'light' and PB_UTIL.light_suits or PB_UTIL.dark_suits) do
            if QOL_BUNDLE.original.Card_is_suit(card, v) then return true end
        end
        return false
    end
end

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

        -- Enhanced Smeared Joker logic: Use Paperback's light/dark suits when available
        if PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
            -- Use Paperback's enhanced light/dark suit logic
            local is_base_light = PB_UTIL.is_suit(self, 'light')
            local is_target_light = false
            
            -- Check if target suit is light
            for _, light_suit in ipairs(PB_UTIL.light_suits) do
                if suit == light_suit then
                    is_target_light = true
                    break
                end
            end
            
            -- Cards match if both are light suits or both are dark suits
            if is_base_light == is_target_light then
                return true
            end
        else
            -- Fallback to original red/black logic when Paperback is not available
            local is_base_red = self.base.suit == 'Hearts' or self.base.suit == 'Diamonds'
            local is_target_red = suit == 'Hearts' or suit == 'Diamonds'
            -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit is_base_red: " .. tostring(is_base_red) .. ", is_target_red: " .. tostring(is_target_red))

            if is_base_red == is_target_red then
                return true
            end
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
        local _suit = SMODS.Suits[reference_suit].card_key
        
        for i=1, #G.hand.cards do
            G.E_MANAGER:add_event(Event({func = function()
                local card = G.hand.cards[i]
                local suit_prefix = _suit..'_'
                local rank_suffix = SMODS.Ranks[card.base.value].card_key
                card:set_base(G.P_CARDS[suit_prefix..rank_suffix])
            return true end }))
        end  
    end
    
    if self.ability.name == 'Ouija' then
        -- Use reference card's rank instead of random
        local reference_rank_id = reference_card.base.value
        local _rank = SMODS.Ranks[reference_rank_id].card_key
        
        for i=1, #G.hand.cards do
            G.E_MANAGER:add_event(Event({func = function()
                local card = G.hand.cards[i]
                local suit_prefix = SMODS.Suits[card.base.suit].card_key
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

-- Update Magic Trick voucher text based on configuration
function QOL_BUNDLE.utils.update_magic_trick_text()
    local loc_text = localize('v_magic_trick_original')
    
    if QOL_BUNDLE.config.enhanced_magic_trick_enabled then
        loc_text = localize('v_magic_trick_enhanced')
    end
    
    G.localization.descriptions.Voucher.v_magic_trick.text = loc_text
    init_localization()
end

-- Update Illusion voucher text based on configuration
function QOL_BUNDLE.utils.update_illusion_text()
    local loc_text = localize('v_illusion_original')
    
    if QOL_BUNDLE.config.new_illusion_enabled then
        loc_text = localize('v_illusion_deck_based')
    end
    
    G.localization.descriptions.Voucher.v_illusion.text = loc_text
    init_localization()
end

-- Update Smeared Joker text based on configuration and Paperback availability
function QOL_BUNDLE.utils.update_smeared_text()
    local loc_text = localize('j_smeared_original')
    
    if QOL_BUNDLE.config.wildcard_fix_enabled and PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
        loc_text = localize('j_smeared_paperback')
    end
    
    G.localization.descriptions.Joker.j_smeared.text = loc_text
    init_localization()
end

-- Register hooks for text updates
RIOSODU_SHARED.register_hook('on_game_start', QOL_BUNDLE.utils.update_sigil_text)
RIOSODU_SHARED.register_hook('on_game_start', QOL_BUNDLE.utils.update_ouija_text)
RIOSODU_SHARED.register_hook('on_game_start', QOL_BUNDLE.utils.update_magic_trick_text)
RIOSODU_SHARED.register_hook('on_game_start', QOL_BUNDLE.utils.update_illusion_text)
RIOSODU_SHARED.register_hook('on_game_start', QOL_BUNDLE.utils.update_smeared_text)

-- Enhanced shop card generation with Magic Trick and Illusion improvements
function create_card_for_shop(area)
    -- Call original function first
    local card = QOL_BUNDLE.original.create_card_for_shop(area)
    
    -- Only apply enhancements to playing cards when vouchers are active
    if card and card.ability and (card.ability.set == 'Default' or card.ability.set == 'Enhanced') then
        local has_enhanced_magic_trick = QOL_BUNDLE.config.enhanced_magic_trick_enabled and G.GAME.used_vouchers["v_magic_trick"]
        local has_new_illusion = QOL_BUNDLE.config.new_illusion_enabled and G.GAME.used_vouchers["v_illusion"]
        
        if has_enhanced_magic_trick and not has_new_illusion then
            -- Enhanced Magic Trick: Apply all possible upgrades with proper probabilities
            QOL_BUNDLE.utils.apply_enhanced_magic_trick_upgrades(card)
            QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
            
        elseif has_new_illusion then
            -- New Illusion: Replace card with deck-based card and reroll upgrades
            card = QOL_BUNDLE.utils.apply_new_illusion_logic(card, area) or card
            QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
        end
    end
    
    return card
end

-- Override reset_castle_card to support checkered deck enhancement
function reset_castle_card()
    -- Call original if not enabled
    if not QOL_BUNDLE.config.castle_checkered_enabled then
        return QOL_BUNDLE.original.reset_castle_card()
    end

    G.GAME.current_round.castle_card.suit = 'Spades'
    local valid_castle_cards = {}
    
    for k, v in ipairs(G.playing_cards) do
        if not SMODS.has_no_suit(v) then
            valid_castle_cards[#valid_castle_cards+1] = v
        end
    end
    
    if valid_castle_cards[1] then 
        -- Enhanced logic: Choose between light suits (Hearts+Diamonds) or dark suits (Clubs+Spades)
        -- Randomly choose light or dark suits
        local chosen_group = pseudorandom(pseudoseed('castle_group'..G.GAME.round_resets.ante)) > 0.5 and 'light' or 'dark'
        
        -- Store which group was chosen for the joker logic and UI display
        G.GAME.current_round.castle_card_group = chosen_group
        
        -- Keep the original suit assignment for compatibility, but it won't be used in the logic
        local castle_card = pseudorandom_element(valid_castle_cards, pseudoseed('cas'..G.GAME.round_resets.ante))
        G.GAME.current_round.castle_card.suit = castle_card.base.suit
    end
end

-- Helper functions for enhanced voucher logic
QOL_BUNDLE.utils = QOL_BUNDLE.utils or {}

-- Apply enhanced Magic Trick upgrades: enhancements, editions, seals, and clips
function QOL_BUNDLE.utils.apply_enhanced_magic_trick_upgrades(card)
    if not card then return end
    
    -- Use the shared try_apply functions for consistent logic
    QOL_BUNDLE.utils.try_apply_enhancement(card, 'magic_trick_enh')
    QOL_BUNDLE.utils.try_apply_edition(card, 'magic_trick_shop')  
    QOL_BUNDLE.utils.try_apply_seal(card, 'magic_trick_seal')
    QOL_BUNDLE.utils.try_apply_clip(card, 'magic_trick_clip')
end

-- Apply new Illusion logic: deck-based cards with reroll upgrades
function QOL_BUNDLE.utils.apply_new_illusion_logic(original_card, area)
    if not G.playing_cards or #G.playing_cards == 0 then
        -- Fallback to enhanced Magic Trick if no deck cards available
        QOL_BUNDLE.utils.apply_enhanced_magic_trick_upgrades(original_card)
        return original_card
    end
    
    -- Select random card from player's deck
    local deck_card = pseudorandom_element(G.playing_cards, pseudoseed('illusion_deck'..G.GAME.round_resets.ante))
    if not deck_card then
        QOL_BUNDLE.utils.apply_enhanced_magic_trick_upgrades(original_card)
        return original_card
    end
    
    -- Modify the existing shop card instead of creating a new one
    -- Change base suit/rank to match deck card
    original_card:set_base(G.P_CARDS[deck_card.config.card_key])
    
    -- Copy ALL existing properties from deck card (complete copy)
    if deck_card.edition then
        original_card:set_edition(deck_card.edition)
    end
    if deck_card.seal then  
        original_card:set_seal(deck_card.seal)
    end
    if deck_card.config.center.set == 'Enhanced' then
        original_card:set_ability(deck_card.config.center)
    end
    
    -- Now attempt improvements with Magic Trick logic (only if they would improve the card)
    QOL_BUNDLE.utils.try_apply_enhancement(original_card, 'illusion_enh_improve')
    QOL_BUNDLE.utils.try_apply_edition(original_card, 'illusion_ed_improve')
    QOL_BUNDLE.utils.try_apply_seal(original_card, 'illusion_seal_improve')
    QOL_BUNDLE.utils.try_apply_clip(original_card, 'illusion_clip_improve')
    
    return original_card
end

-- Recalculate playing card cost based on new rules
function QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
    if not card or not (card.ability.set == 'Default' or card.ability.set == 'Enhanced') then
        return
    end

    local extra_cost = 0

    -- Editions
    if card.edition then
        if card.edition.polychrome then
            extra_cost = extra_cost + 3
        else -- Foil, Holo, Negative
            extra_cost = extra_cost + 2
        end
    end

    -- Seals
    if card.seal then
        extra_cost = extra_cost + 1
    end

    -- Enhancements
    if card.ability.set == 'Enhanced' then
        extra_cost = extra_cost + 1
    end

    -- Recalculate final cost, respecting discounts
    card.cost = math.max(1, math.floor((card.base_cost + extra_cost + 0.5) * (100 - G.GAME.discount_percent) / 100))

    -- Recalculate sell cost
    card.sell_cost = math.max(1, math.floor(card.cost / 2)) + (card.ability.extra_value or 0)
    card.sell_cost_label = card.sell_cost
end

-- Try to apply enhancement using SMODS poll system (now with reroll logic for Illusion)
function QOL_BUNDLE.utils.try_apply_enhancement(card, seed_key)
    if not card then return end
    
    local enhancement_key = SMODS.poll_enhancement({
        key = seed_key,
        mod = 2.5, -- 40% chance (default 16% * 2.5 = 40%)
        guaranteed = nil
    })
    
    if enhancement_key then
        card:set_ability(G.P_CENTERS[enhancement_key])
    end
end

-- Try to apply edition using poll_edition (now with reroll logic for Illusion)
function QOL_BUNDLE.utils.try_apply_edition(card, seed_key)
    if not card then return end
    
    -- Use poll_edition which respects game logic and SMODS overrides
    local new_edition = poll_edition(seed_key, 1, false, false)
    if new_edition then
        card:set_edition(new_edition)
    end
end

-- Try to apply seal using SMODS poll system (now with reroll logic for Illusion)
function QOL_BUNDLE.utils.try_apply_seal(card, seed_key)
    if not card then return end
    
    local seal_key = SMODS.poll_seal({
        key = seed_key,
        mod = 10, -- 20% chance (default 2% * 10 = 20%)
        guaranteed = false
    })
    
    if seal_key then
        card:set_seal(seal_key)
    end
end

-- Try to apply paperclip using Paperback's poll system (if Paperback is available)
function QOL_BUNDLE.utils.try_apply_clip(card, seed_key)
    if not card then return end

    -- Check if Paperback mod is available
    if not PB_UTIL or not PB_UTIL.poll_paperclip or not PB_UTIL.set_paperclip then
        return -- Paperback not available, skip
    end

    -- Use 20% chance (same as seals) split equally between all clips
    local clip_chance = pseudorandom(pseudoseed(seed_key))
    if clip_chance > 0.8 then -- 20% chance
        local clip_type = PB_UTIL.poll_paperclip(seed_key)
        if clip_type then
            PB_UTIL.set_paperclip(card, clip_type)
        end
    end
end

