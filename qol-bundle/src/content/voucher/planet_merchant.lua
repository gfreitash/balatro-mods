-- Override Planet Merchant and Planet Tycoon: instead of boosting the shop
-- planet rate, a played hand can create its equivalent Planet card.
--
-- Both effects run through SMODS:
--  * vouchers calculate in every scoring context (SMODS includes G.vouchers in
--    the jokers card area, and Card:calculate_joker dispatches to any center's
--    calculate); `context.after` fires exactly once per played hand
--  * odds go through SMODS.pseudorandom_probability, so mod_probability /
--    fix_probability contexts (Oops! All 6s and modded modifiers) apply
--  * `redeem` is an SMODS voucher hook: defining it makes Card:apply_to_run
--    skip the vanilla shop-rate branch, replacing the original effect
local function find_planet_key(hand_name)
    local matches = {}
    for _, center in pairs(G.P_CENTER_POOLS.Planet or {}) do
        if center.config and center.config.hand_type == hand_name then
            matches[#matches + 1] = center
        end
    end
    if #matches == 0 then
        return nil
    end
    if #matches == 1 then
        return matches[1].key
    end
    -- Some mods can register more than one planet for a hand; stay seeded.
    return pseudorandom_element(matches, pseudoseed('qolb_planet_merchant_choice')).key
end

local function roll_planet(card, context, odds)
    if not context.after or not context.scoring_name then
        return
    end

    -- The Planet card can only be created if there is space. Checked before
    -- rolling so a full consumable area cannot consume the roll.
    if #G.consumeables.cards + G.GAME.consumeable_buffer >= G.consumeables.config.card_limit then
        return
    end

    -- Modded hands have no equivalent planet when the mod that registers the
    -- hand does not register one; skip instead of crashing.
    local planet_key = find_planet_key(context.scoring_name)
    if not planet_key then
        return
    end

    if not SMODS.pseudorandom_probability(card, pseudoseed('qolb_planet_merchant'), 1, odds, 'qolb_planet_merchant') then
        return
    end

    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
    G.E_MANAGER:add_event(Event({
        trigger = 'before',
        delay = 0.0,
        func = (function()
            SMODS.add_card({ set = 'Planet', key = planet_key, area = G.consumeables })
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer - 1
            return true
        end)
    }))
end

function QOL_BUNDLE.funcs.get_ownership_voucher_planet_merchant()
    if not QOL_BUNDLE.config.planet_merchant_rework_enabled then
        return
    end

    QOL_BUNDLE.state.planet_merchant = SMODS.Voucher:take_ownership('v_planet_merchant', {
        config = { extra = 9.6 / 4, extra_disp = 4 },
        -- Replaces the vanilla "planets appear 2X more often" effect.
        redeem = function(self, voucher) end,
        calculate = function(self, card, context)
            -- One roll per played hand: Planet Tycoon replaces this effect.
            if G.GAME.used_vouchers.v_planet_tycoon then
                return
            end
            roll_planet(card, context, 4)
        end
    })

    QOL_BUNDLE.state.planet_tycoon = SMODS.Voucher:take_ownership('v_planet_tycoon', {
        config = { extra = 32 / 4, extra_disp = 2 },
        -- Replaces the vanilla "planets appear 3X more often" effect.
        redeem = function(self, voucher) end,
        calculate = function(self, card, context)
            roll_planet(card, context, 2)
        end
    })

    local apply_localization = function()
        local merchant = localize('v_planet_merchant_original')
        local tycoon = localize('v_planet_tycoon_original')
        if QOL_BUNDLE.config.planet_merchant_rework_enabled then
            merchant = localize('v_planet_merchant_modified')
            tycoon = localize('v_planet_tycoon_modified')
        end
        G.localization.descriptions.Voucher.v_planet_merchant.text = merchant
        G.localization.descriptions.Voucher.v_planet_tycoon.text = tycoon
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_voucher_planet_merchant()
