-- Override the 8 Ball Joker
function QOL_BUNDLE.funcs.get_ownership_joker_8_ball()
    if not QOL_BUNDLE.config.eight_ball_joker_enabled then
        return
    end

    QOL_BUNDLE.state.eight_ball_joker = SMODS.Joker:take_ownership('8_ball', {
        config = {
            extra = QOL_BUNDLE.config.eight_ball_joker_value or 4
        }
    })
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

QOL_BUNDLE.funcs.get_ownership_joker_8_ball()
G.FUNCS.qol_bundle_eight_ball_joker_callback = QOL_BUNDLE.callbacks.eight_ball_joker_callback_handler
