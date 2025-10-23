RIOSODU_SHARED.compat = RIOSODU_SHARED.compat or {}

function RIOSODU_SHARED.UI.updateDynamicAreas(uiDefinitions, config)
    base_conf = config or {
        offset = {x=0, y=0},
        align = 'cm',
    }

    for id, uiDefinition in pairs(uiDefinitions) do
        local dynamicArea = G.OVERLAY_MENU:get_UIE_by_ID(id)
        if dynamicArea and dynamicArea.config.object then
            cfg = SMODS.shallow_copy(base_conf)
            cfg.parent = dynamicArea

            dynamicArea.config.object:remove()
            dynamicArea.config.object = UIBox{
                definition = uiDefinition,
                config = cfg
            }
        end
    end
end

function RIOSODU_SHARED.UI.initTab(args)
    local updateFunctions = args.updateFunctions
    local staticPageDefinition = args.staticPageDefinition

    for _, updateFunction in pairs(updateFunctions) do
        G.E_MANAGER:add_event(Event({func = function()
            updateFunction{cycle_config = {}}
            return true
        end}))
    end

    return {
        n = G.UIT.ROOT,
        config = {
            emboss = 0.05,
            minh = 6,
            r = 0.1,
            minw = 8,
            align = "cm",
            colour = G.C.BLACK
        },
        nodes = {
            staticPageDefinition
        }
    }
end
RIOSODU_SHARED.utils.talisman_present = function ()
    return not not Talisman
end

--- Wraps a number in a Big number if Talisman is present or returns the number as is
--- @param a number|table The number to wrap
--- @return number|table result The wrapped number or the original number
RIOSODU_SHARED.utils.wrap_num = function (a)
    local talisman_present = RIOSODU_SHARED.utils.talisman_present()
    return talisman_present and to_big(a) or a
end
local num_wrap = RIOSODU_SHARED.utils.wrap_num

--- Compares two numbers and returns true if first is less or equal to second.
--- It is compatible with Talisman's Big number implementation.
--- @param a number|table
--- @param b number|table
--- @return boolean
function math.le(a, b)
    return num_wrap(a) <= num_wrap(b)
end

--- Compares two numbers and returns true if first is less than second.
--- It is compatible with Talisman's Big number implementation.
--- @param a number|table
--- @param b number|table
--- @return boolean
function math.lt(a, b)
    return num_wrap(a) < num_wrap(b)
end

--- Compares two numbers and returns true if first is greater or equal to second.
--- It is compatible with Talisman's Big number implementation.
--- @param a number|table
--- @param b number|table
--- @return boolean
function math.ge(a, b)
    return num_wrap(a) >= num_wrap(b)
end

--- Compares two numbers and returns true if first is greater than second.
--- It is compatible with Talisman's Big number implementation.
--- @param a number|table
--- @param b number|table
--- @return boolean
function math.gt(a, b)
    return num_wrap(a) > num_wrap(b)
end

--- Compares two numbers and returns true if they are equal.
--- It is compatible with Talisman's Big number implementation.
--- @param a number|table
--- @param b number|table
--- @return boolean
function math.eq(a, b)
    return num_wrap(a) == num_wrap(b)
end

--- This is a railguard function to safely get the interest base from the game state table.
--- This is required because some times the game state table will not have the interest base.
--- Since the bug couldn't be reproduced, going for the safe route is the better approach,
--- specially since this function has extra debug embedded.
--- @return integer interest_base The required amount of dollars to gain $1 of interest
function get_interest_base()
    local interest = G.GAME.interest_base
    if interest == nil then
        value = (not not RSM and G.game.stake and G.GAME.stake >= 8) and 6 or 5
        RIOSODU_SHARED.utils.sendDebugMessage("Interest base not found, defaulting to " .. value)

        RIOSODU_SHARED.utils.sendDebugMessage("Inserting on game state table...")
        interest = value
        G.GAME.interest_base = value
    end

    return interest
end