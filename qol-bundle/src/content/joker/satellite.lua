-- Override the Satellite Joker
function QOL_BUNDLE.funcs.get_ownership_joker_satellite()
    if not QOL_BUNDLE.config.satellite_joker_enabled then
        return
    end

    QOL_BUNDLE.state.satellite_joker = SMODS.Joker:take_ownership('j_satellite', {
        loc_vars = function(self, info_queue, center)
            -- Find the highest poker hand level
            local highest_level = 0
            for hand_name, hand_data in pairs(G.GAME and G.GAME.hands or {}) do
                if math.gt(hand_data.level, highest_level) then
                    highest_level = hand_data.level
                end
            end

            -- Calculate gold amount (half the highest level, rounded up)
            local gold_amount = math.ceil(highest_level / 2)

            return {
                vars = {
                    center.ability.extra,  -- #1# - Base multiplier (1)
                    gold_amount           -- #2# - Current gold amount
                }
            }
        end,
        calc_dollar_bonus = function(self, card)
            if card.debuff then return end

            -- Find the highest poker hand level
            local highest_level = 0
            for hand_name, hand_data in pairs(G.GAME.hands) do
                if math.gt(hand_data.level, highest_level) then
                    highest_level = hand_data.level
                end
            end

            -- Calculate gold amount (half the highest level, rounded up)
            local gold_amount = math.ceil(highest_level / 2)

            if math.gt(gold_amount, 0) then
                return gold_amount
            end
        end
    })

    local apply_localization = function()
        local loc = localize('j_satellite_original')
        if QOL_BUNDLE.config.satellite_joker_enabled then
            loc = localize('j_satellite_modified')
        end
        G.localization.descriptions.Joker.j_satellite.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_satellite()