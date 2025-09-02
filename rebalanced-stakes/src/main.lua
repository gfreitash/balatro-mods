
RIOSODU_SHARED.utils.sendDebugMessage("Taking ownership of stakes...", RSM.mod_id)

-- Blue Stake (5)
SMODS.Stake:take_ownership('blue', {
    modifiers = function ()
        G.GAME.modifiers.enable_perishables_in_shop = true
    end
})
RIOSODU_SHARED.utils.sendDebugMessage("Blue stake ownership taken", RSM.mod_id)

-- Orange stake (7)
SMODS.Stake:take_ownership('orange', {
    modifiers = function()
        G.GAME.modifiers.enable_rentals_in_shop = true
    end
})
RIOSODU_SHARED.utils.sendDebugMessage("Orange stake ownership taken", RSM.mod_id)

-- Gold stake (8)
SMODS.Stake:take_ownership('gold', {
    modifiers = function()
        G.GAME.win_ante = 9
        G.GAME.interest_base = 6
        G.GAME.interest_cap = 30
    end
})
RIOSODU_SHARED.utils.sendDebugMessage("Gold stake ownership taken", RSM.mod_id)

-- Override calculate_perishable function to make perishable jokers negative when they expire
local original_calculate_perishable = Card.calculate_perishable
function Card:calculate_perishable()
    if self.ability.perishable and self.ability.perish_tally > 0 then
        if self.ability.perish_tally == 1 then
            self.ability.perish_tally = 0
            card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('k_disabled_ex'),colour = G.C.FILTER, delay = 0.45})
            -- Make the joker negative when it expires
            if self.area == G.jokers then
                self:set_edition({negative = true}, true)
            end
            return true
        else
            self.ability.perish_tally = self.ability.perish_tally - 1
            card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize{type='variable',key='a_remaining',vars={self.ability.perish_tally}},colour = G.C.FILTER, delay = 0.45})
        end
    end
end

RIOSODU_SHARED.utils.sendDebugMessage("Perishable negative override applied", RSM.mod_id)
