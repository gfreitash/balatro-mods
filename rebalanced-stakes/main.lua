SMODS.Blind:take_ownership('blue', {
    modifiers = function ()
        G.GAME.modifiers.enable_perishables_in_shop = true
    end
})

-- Orange stake (7)
SMODS.Blind:take_ownership('orange', {
    modifiers = function()
        G.GAME.modifiers.enable_rentals_in_shop = true
    end
})

-- Gold stake (8)
SMODS.Blind:take_ownership('gold', {
    modifiers = function()
        G.GAME.win_ante = 9
        G.GAME.interest_base = 6
        G.GAME.interest_cap = 30
    end
})
