-- Override Ouija spectral card to enable card selection
function QOL_BUNDLE.funcs.get_ownership_spectral_ouija()
    if not QOL_BUNDLE.config.ouija_control_enabled then
        return
    end

    QOL_BUNDLE.state.ouija = SMODS.Consumable:take_ownership('c_ouija', {
        config = {
            max_highlighted = 1
        }
    })

    local apply_localization = function()
        local loc_text = localize('ouija_loc_text_original')

        if QOL_BUNDLE.config.ouija_control_enabled then
            loc_text = localize('ouija_loc_text_controlled')
        end

        G.localization.descriptions.Spectral.c_ouija.text = loc_text
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_spectral_ouija()