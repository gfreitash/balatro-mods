-- Override Sigil spectral card to enable card selection
function QOL_BUNDLE.funcs.get_ownership_spectral_sigil()
    if not QOL_BUNDLE.config.sigil_control_enabled then
        return
    end

    QOL_BUNDLE.state.sigil = SMODS.Consumable:take_ownership('c_sigil', {
        config = {
            max_highlighted = 1
        }
    })

    local apply_localization = function()
        local loc_text = localize('sigil_loc_text_original')

        if QOL_BUNDLE.config.sigil_control_enabled then
            loc_text = localize('sigil_loc_text_controlled')
        end

        G.localization.descriptions.Spectral.c_sigil.text = loc_text
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_spectral_sigil()
