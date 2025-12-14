-- QoL Bundle/src/main.lua

QOL_BUNDLE.utils = QOL_BUNDLE.utils or {}
QOL_BUNDLE.funcs = QOL_BUNDLE.funcs or {}

-- Interest on Skip functionality via overriding G.FUNCS.skip_blind
QOL_BUNDLE.original = QOL_BUNDLE.original or {}

function QOL_BUNDLE.funcs.apply_interest_on_skip_override()
    -- Store the original function if we haven't already
    if not QOL_BUNDLE.original.skip_blind then
        QOL_BUNDLE.original.skip_blind = G.FUNCS.skip_blind
    end

    if not QOL_BUNDLE.config.interest_on_skip_enabled then
        -- Restore the original function
        G.FUNCS.skip_blind = QOL_BUNDLE.original.skip_blind
        return
    end

    -- Apply the override
    G.FUNCS.skip_blind = function(e)
        -- Calculate and award interest BEFORE processing the skip
        local interest_base = G.GAME.interest_base or 5
        local interest_amount = G.GAME.interest_amount or 1
        local interest_cap = G.GAME.interest_cap or 25

        local not_in_debt = math.ge(G.GAME.dollars, 1)

        if not_in_debt and not G.GAME.modifiers.no_interest then
            interest_earned = interest_amount * math.min(math.floor(G.GAME.dollars / interest_base), interest_cap / interest_base)
            gained_interest = math.ge(interest_earned, 1)

            if gained_interest then
                ease_dollars(interest_earned)
                RIOSODU_SHARED.utils.sendDebugMessage("Interest on skip: $" .. interest_earned, QOL_BUNDLE.mod_id)
            end
        end

        -- Call the original function
        return QOL_BUNDLE.original.skip_blind(e)
    end
end

RIOSODU_SHARED.utils.sendDebugMessage("Main logic module loading...", QOL_BUNDLE.mod_id)

QOL_BUNDLE.funcs.apply_interest_on_skip_override()

RIOSODU_SHARED.utils.sendDebugMessage("Main logic module loaded", QOL_BUNDLE.mod_id)
