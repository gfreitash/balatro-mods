---@diagnostic disable: duplicate-set-field, duplicate-doc-field

-- Store original functions
QOL_BUNDLE.original = QOL_BUNDLE.original or {}
QOL_BUNDLE.original.Card_is_suit = Card.is_suit
QOL_BUNDLE.original.Blind_debuff_card = Blind.debuff_card
QOL_BUNDLE.original.Game_init_game_object = Game.init_game_object

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