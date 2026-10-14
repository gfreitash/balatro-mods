-- Override the Space Joker to make its chance configurable
function QOL_BUNDLE.funcs.get_ownership_joker_space()
    if not QOL_BUNDLE.config.space_joker_enabled then
        return
    end

    QOL_BUNDLE.state.space_joker = SMODS.Joker:take_ownership('j_space', {
        config = {
            extra = QOL_BUNDLE.config.space_joker_value or 3
        }
    })
end

-- Callback for Space Joker cycle option
QOL_BUNDLE.callbacks.space_joker_callback_handler = function(e)
    if not e then return end

    -- Update the current option and value in the mod's state
    QOL_BUNDLE.space_joker_current_option = e.to_key
    QOL_BUNDLE.space_joker_current_option_val = e.to_val

    -- Update the config value
    QOL_BUNDLE.config.space_joker_value = e.to_val

    -- Save the config
    SMODS.save_mod_config(QOL_BUNDLE.mod)

    QOL_BUNDLE.state.space_joker.config.extra = e.to_val

    RIOSODU_SHARED.utils.sendDebugMessage("Space Joker value set to: " .. e.to_val)
end

QOL_BUNDLE.funcs.get_ownership_joker_space()
G.FUNCS.qol_bundle_space_joker_callback = QOL_BUNDLE.callbacks.space_joker_callback_handler
