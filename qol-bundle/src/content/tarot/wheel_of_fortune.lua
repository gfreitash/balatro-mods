-- Override the Wheel of Fortune consumable
function QOL_BUNDLE.funcs.get_ownership_wheel_of_fortune()
    if not QOL_BUNDLE.config.wheel_of_fortune_enabled then
        return
    end

    QOL_BUNDLE.state.wheel_of_fortune = SMODS.Consumable:take_ownership('wheel_of_fortune', {
        config = {
            extra = QOL_BUNDLE.config.wheel_of_fortune_value or 4
        }
    })
end

-- Callback for Wheel of Fortune cycle option
QOL_BUNDLE.callbacks.wheel_callback_handler = function(e)
    if not e then return end

    -- Update the current option and value in the mod's state
    QOL_BUNDLE.wheel_of_fortune_current_option = e.to_key
    QOL_BUNDLE.wheel_of_fortune_current_option_val = e.to_val

    -- Update the config value
    QOL_BUNDLE.config.wheel_of_fortune_value = e.to_val

    -- Save the config
    SMODS.save_mod_config(QOL_BUNDLE.mod)

    QOL_BUNDLE.state.wheel_of_fortune.config.extra = e.to_val

    RIOSODU_SHARED.utils.sendDebugMessage("Wheel of Fortune value set to: " .. e.to_val)
end

QOL_BUNDLE.funcs.get_ownership_wheel_of_fortune()
G.FUNCS.qol_bundle_wheel_callback = QOL_BUNDLE.callbacks.wheel_callback_handler