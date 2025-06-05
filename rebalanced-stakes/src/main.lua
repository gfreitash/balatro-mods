
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
