-- QoL Bundle/src/callbacks.lua

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

-- Callback for 8 Ball Joker cycle option
QOL_BUNDLE.callbacks.eight_ball_joker_callback_handler = function(e)
    if not e then return end

    -- Update the current option and value in the mod's state
    QOL_BUNDLE.eight_ball_joker_current_option = e.to_key
    QOL_BUNDLE.eight_ball_joker_current_option_val = e.to_val

    -- Update the config value
    QOL_BUNDLE.config.eight_ball_joker_value = e.to_val

    -- Save the config
    SMODS.save_mod_config(QOL_BUNDLE.mod)

    QOL_BUNDLE.state.eight_ball_joker.config.extra = e.to_val

    RIOSODU_SHARED.utils.sendDebugMessage("8 Ball Joker value set to: " .. e.to_val)
end

G.FUNCS.qol_bundle_wheel_callback = QOL_BUNDLE.callbacks.wheel_callback_handler
G.FUNCS.qol_bundle_eight_ball_joker_callback = QOL_BUNDLE.callbacks.eight_ball_joker_callback_handler
