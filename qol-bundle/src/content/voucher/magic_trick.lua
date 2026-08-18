QOL_BUNDLE.utils = QOL_BUNDLE.utils or {}

-- Apply enhanced Magic Trick upgrades: enhancements, editions, seals, and clips
function QOL_BUNDLE.utils.apply_enhanced_magic_trick_upgrades(card)
    if not card then return end

    -- Use the shared try_apply functions for consistent logic
    QOL_BUNDLE.utils.try_apply_enhancement(card, 'magic_trick_enh')
    QOL_BUNDLE.utils.try_apply_edition(card, 'magic_trick_shop')
    QOL_BUNDLE.utils.try_apply_seal(card, 'magic_trick_seal')
    QOL_BUNDLE.utils.try_apply_clip(card, 'magic_trick_clip')
end

-- Override Magic Trick voucher to enable enhanced shop card generation
function QOL_BUNDLE.funcs.get_ownership_voucher_magic_trick()
    if not QOL_BUNDLE.config.enhanced_magic_trick_enabled then
        return
    end

    QOL_BUNDLE.state.magic_trick = SMODS.Voucher:take_ownership('v_magic_trick', {
        -- Keep the same config (extra = 4 for playing_card_rate)
        -- The actual enhancement logic will be in the shop card generation override
    })

    local apply_localization = function()
        local loc_text = localize('v_magic_trick_original')

        if QOL_BUNDLE.config.enhanced_magic_trick_enabled then
            loc_text = localize('v_magic_trick_enhanced')
        end

        if QOL_BUNDLE.config.enhanced_magic_trick_enabled and PB_UTIL then
            loc_text = localize('v_magic_trick_paperback')
        end

        G.localization.descriptions.Voucher.v_magic_trick.text = loc_text
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_voucher_magic_trick()
