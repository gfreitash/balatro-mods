-- QoL Bundle/src/main.lua

-- Override the Wheel of Fortune consumable
function get_ownership_wheel_of_fortune()
    if not QOL_BUNDLE.config.wheel_of_fortune_enabled then
        return
    end

    QOL_BUNDLE.state.wheel_of_fortune = SMODS.Consumable:take_ownership('wheel_of_fortune', {
        config = {
            extra = QOL_BUNDLE.config.wheel_of_fortune_value or 4
        }
    })
end

RIOSODU_SHARED.utils.sendDebugMessage("Main logic module loading...", QOL_BUNDLE.mod_id)
get_ownership_wheel_of_fortune()
