---@diagnostic disable: duplicate-set-field, duplicate-doc-field

-- Store original functions
QOL_BUNDLE.original = QOL_BUNDLE.original or {}
QOL_BUNDLE.original.Card_is_suit = Card.is_suit
QOL_BUNDLE.original.Blind_debuff_card = Blind.debuff_card
QOL_BUNDLE.original.Game_init_game_object = Game.init_game_object
QOL_BUNDLE.original.poll_edition = poll_edition

-- Override Card:is_suit with wildcard and blurred joker fixes
function Card:is_suit(suit, bypass_debuff, flush_calc, trying_to_debuff)
    RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit called with suit: " .. tostring(suit) .. ", bypass_debuff: " .. tostring(bypass_debuff) .. ", flush_calc: " .. tostring(flush_calc) .. ", trying_to_debuff: " .. tostring(trying_to_debuff))
    if not QOL_BUNDLE.config.wildcard_fix_enabled then
        RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit called without wildcard fix enabled, using original implementation.")
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
    RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit has_smeared_joker: " .. tostring(has_smeared_joker))
    if has_smeared_joker then
        if trying_to_debuff then
            RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit trying to debuff with Smeared Joker, returning false.")
            return false
        end

        local is_base_red = self.base.suit == 'Hearts' or self.base.suit == 'Diamonds'
        local is_target_red = suit == 'Hearts' or suit == 'Diamonds'
        RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit is_base_red: " .. tostring(is_base_red) .. ", is_target_red: " .. tostring(is_target_red))

        if is_base_red == is_target_red then
            return true
        end
    end

    RIOSODU_SHARED.utils.sendDebugMessage("Card:is_suit returning base suit match: " .. tostring(self.base.suit == suit))
    return self.base.suit == suit
end

-- -- Override Blind:debuff_card to use trying_to_debuff parameter
-- function Blind:debuff_card(card, from_blind)
--     if not QOL_BUNDLE.config.wildcard_fix_enabled then
--         RIOSODU_SHARED.utils.sendDebugMessage("Blind:debuff_card called without wildcard fix enabled, using original implementation.")
--         return QOL_BUNDLE.original.Blind_debuff_card(self, card, from_blind)
--     end

--     if self.debuff and not self.disabled and card.area ~= G.jokers then
--         RIOSODU_SHARED.utils.sendDebugMessage("Blind:debuff_card called with debuff active, checking card suitability.")
--         if self.debuff.suit and card:is_suit(self.debuff.suit, true, nil, true) then
--             RIOSODU_SHARED.utils.sendDebugMessage("Blind:debuff_card card is suitable for debuff, setting debuff.")
--             card:set_debuff(true)
--             return
--         end
--     end

--     RIOSODU_SHARED.utils.sendDebugMessage("Blind:debuff_card called without debuff or card not suitable, using original implementation.")
--     return QOL_BUNDLE.original.Blind_debuff_card(self, card, from_blind)
-- end

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

    -- If a non-negative edition would have been generated, distribute equally
    local total_non_negative_prob = 0.04 * G.GAME.edition_rate * _mod
    if _guaranteed then
        total_non_negative_prob = 0.04 * 25 -- Equivalent to 1 - (1 - 0.04*25)
    end

    -- Check if an edition (foil, holo, poly) would have been rolled by original logic
    -- This is the crucial part: we check against the *original* threshold for any non-negative edition
    -- and then redistribute if it falls within that range.
    local original_foil_threshold = 1 - (0.04 * G.GAME.edition_rate * _mod)
    local original_holo_threshold = 1 - (0.02 * G.GAME.edition_rate * _mod)
    local original_polychrome_threshold = 1 - (0.006 * G.GAME.edition_rate * _mod)

    if _guaranteed then
        original_foil_threshold = 1 - (0.04 * 25)
        original_holo_threshold = 1 - (0.02 * 25)
        original_polychrome_threshold = 1 - (0.006 * 25)
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
