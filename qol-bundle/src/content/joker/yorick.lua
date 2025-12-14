-- Override the Yorick Joker to use configurable multiplier
function QOL_BUNDLE.funcs.get_ownership_joker_yorick()
    if not QOL_BUNDLE.config.yorick_multiplier_enabled then
        return
    end

    QOL_BUNDLE.state.yorick = SMODS.Joker:take_ownership('j_yorick', {
        config = {
            extra = {
                xmult = QOL_BUNDLE.config.yorick_multiplier_value or 1.5,
                discards = 23
            }
        }
    })
end

-- Callback for Yorick multiplier cycle option
QOL_BUNDLE.callbacks.yorick_callback_handler = function(e)
    if not e then return end

    -- Update the current option and value in the mod's state
    QOL_BUNDLE.yorick_current_option = e.to_key
    QOL_BUNDLE.yorick_current_option_val = e.to_val

    -- Update the config value
    QOL_BUNDLE.config.yorick_multiplier_value = e.to_val

    -- Save the config
    SMODS.save_mod_config(QOL_BUNDLE.mod)

    -- Update the state if it exists
    if QOL_BUNDLE.state.yorick then
        QOL_BUNDLE.state.yorick.config.extra.xmult = e.to_val
    end

    RIOSODU_SHARED.utils.sendDebugMessage("Yorick multiplier value set to: " .. e.to_val)
end

QOL_BUNDLE.funcs.get_ownership_joker_yorick()
G.FUNCS.qol_bundle_yorick_callback = QOL_BUNDLE.callbacks.yorick_callback_handler