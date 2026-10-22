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

-- Override Card:is_suit with wildcard and blurred joker overhaul.
-- Base cases (suitless, any-suit, smeared, modded suits) delegate to the
-- modern SMODS-aware implementation; the wildcard fix only intercepts the
-- boss debuff context (signaled by QOL_BUNDLE.wildcard_debuff_check from the
-- Blind:debuff_card override, or the legacy trying_to_debuff parameter).
function Card:is_suit(suit, bypass_debuff, flush_calc, trying_to_debuff)
    -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit called with suit: " .. tostring(suit) .. ", bypass_debuff: " .. tostring(bypass_debuff) .. ", flush_calc: " .. tostring(flush_calc) .. ", trying_to_debuff: " .. tostring(trying_to_debuff))
    if not QOL_BUNDLE.config.wildcard_fix_enabled then
        -- RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit called without wildcard fix enabled, using original implementation.")
        return QOL_BUNDLE.original.Card_is_suit(self, suit, bypass_debuff, flush_calc)
    end

    -- Debuffed cards don't match any suit (mirrors the modern implementation)
    if not flush_calc and self.debuff and not bypass_debuff then
        return nil
    end

    -- While a boss is evaluating a suit-based debuff, Wild Cards and cards
    -- under Smeared Joker resist matching a specific suit. Scope the resist to
    -- the boss's own suit: other callers inside the same window (notably
    -- Paperback's Da Capo joker, which debuffs cards NOT matching its rotating
    -- suit) must get normal suit matching, or wild/smeared cards get wrongly
    -- debuffed by Da Capo's pass. Known edge: when Da Capo's suit equals the
    -- boss's suit, the two callers are indistinguishable and the resist still
    -- applies to Da Capo's check.
    if trying_to_debuff then
        if self.ability.name == "Wild Card" then
            return false
        end
        if next(find_joker('Smeared Joker')) then
            return false
        end
    elseif QOL_BUNDLE.wildcard_debuff_check then
        local boss_suit = G.GAME and G.GAME.blind and G.GAME.blind.debuff and G.GAME.blind.debuff.suit
        if boss_suit and suit == boss_suit then
            if self.ability.name == "Wild Card" then
                return false
            end
            if next(find_joker('Smeared Joker')) then
                return false
            end
        end
    end

    if self.ability.name == "Wild Card" then
        return not flush_calc or not self.debuff
    end

    -- Enhanced Smeared Joker logic: Use SMODS suit shade metadata when available
    if next(find_joker('Smeared Joker')) then
        -- Suitless cards (e.g. Stone Cards) never match a suit
        if SMODS.has_no_suit(self) then
            return false
        end

        if PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
            local base_shade = QOL_BUNDLE.utils.get_suit_shade(self.base.suit)
            local target_shade = QOL_BUNDLE.utils.get_suit_shade(suit)

            -- Cards match if both are light suits or both are dark suits
            if base_shade and target_shade then
                return base_shade == target_shade
            end

            -- Unknown shade metadata: fall back to the legacy light/dark grouping
            local is_base_light = base_shade == 'light'
            local is_target_light = target_shade == 'light'

            if is_base_light == is_target_light then
                return true
            end
        else
            -- Fallback to original logic when Paperback is not available
            local is_base_red = self.base.suit == 'Hearts' or self.base.suit == 'Diamonds'
            local is_target_red = suit == 'Hearts' or suit == 'Diamonds'

            if is_base_red == is_target_red then
                return true
            end
        end
    end

    -- Delegate everything else to the modern, SMODS-aware implementation
    return QOL_BUNDLE.original.Card_is_suit(self, suit, bypass_debuff, flush_calc)
end

--- comment
--- @param game_obj Game
--- @return Game
local function shop_joker_max(game_obj)
    if game_obj then
        game_obj.shop.joker_max = QOL_BUNDLE.config.joker_max_enabled and QOL_BUNDLE.config.joker_max_value or 2
    end
    return game_obj
end
RIOSODU_SHARED.utils.override_game_obj(shop_joker_max)

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


-- Override Blind:debuff_card to protect Wild Cards / Smeared Joker cards from
-- suit-based boss debuffs (the "wildcard fix"). We delegate to the modern
-- implementation so recalc_debuff callbacks, Crimson Heart, and other boss
-- mechanics keep working, and signal the debuff context to Card:is_suit via
-- the wildcard_debuff_check flag.
function Blind:debuff_card(card, from_blind)
    local prev_check = QOL_BUNDLE.wildcard_debuff_check
    QOL_BUNDLE.wildcard_debuff_check = QOL_BUNDLE.config.wildcard_fix_enabled
    local ok, ret = pcall(QOL_BUNDLE.original.Blind_debuff_card, self, card, from_blind)
    QOL_BUNDLE.wildcard_debuff_check = prev_check
    if not ok then error(ret) end

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
                local suit_prefix = SMODS.Suits[card.base.suit].card_key..'_'
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
    G.GAME.current_round.castle_card_group = nil
    local valid_castle_cards = {}

    for k, v in ipairs(G.playing_cards) do
        if not SMODS.has_no_suit(v) then
            valid_castle_cards[#valid_castle_cards+1] = v
        end
    end

    if valid_castle_cards[1] then 
        -- Enhanced logic: The suit group follows the deck composition, so Castle
        -- scales with suit fixing and is always as reliable as in the checkered deck.
        local castle_card = pseudorandom_element(valid_castle_cards, pseudoseed('cas'..G.GAME.round_resets.ante))
        G.GAME.current_round.castle_card.suit = castle_card.base.suit

        -- Derive the light/dark group from the picked card's suit, so the vanilla
        -- Castle fallback (matching castle_card.suit) can never leave the group.
        local chosen_group
        if PB_UTIL and PB_UTIL.light_suits and PB_UTIL.dark_suits then
            if QOL_BUNDLE.utils.card_is_shade(castle_card, 'light') then
                chosen_group = 'light'
            elseif QOL_BUNDLE.utils.card_is_shade(castle_card, 'dark') then
                chosen_group = 'dark'
            end
        end
        if not chosen_group then
            chosen_group = (castle_card.base.suit == 'Hearts' or castle_card.base.suit == 'Diamonds') and 'light' or 'dark'
        end

        G.GAME.current_round.castle_card_group = chosen_group
    end
end

-- Ankh rework: the reworked Ankh no longer copies a Joker, so the vanilla
-- "no free Joker slot" check must not block it. Every other consumable keeps
-- the vanilla check.
QOL_BUNDLE.original.Card_check_use = Card.check_use
function Card:check_use()
    if QOL_BUNDLE.config.ankh_rework_enabled and self.ability.name == 'Ankh' then
        return nil
    end
    return QOL_BUNDLE.original.Card_check_use(self)
end

