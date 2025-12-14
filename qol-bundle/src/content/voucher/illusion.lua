-- Override Illusion voucher to enable deck-based card generation
function QOL_BUNDLE.utils.apply_new_illusion_logic(original_card, area)
    if not G.playing_cards or #G.playing_cards == 0 then
        -- Fallback to enhanced Magic Trick if no deck cards available
        -- Should never happen, but just in case
        QOL_BUNDLE.utils.apply_enhanced_magic_trick_upgrades(original_card)
        return original_card
    end

    -- Select random card from player's deck
    local deck_card = pseudorandom_element(G.playing_cards, pseudoseed('illusion_deck'..G.GAME.round_resets.ante))
    if not deck_card then
        QOL_BUNDLE.utils.apply_enhanced_magic_trick_upgrades(original_card)
        return original_card
    end

    -- Modify the existing shop card instead of creating a new one
    -- Change base suit/rank to match deck card
    original_card:set_base(G.P_CARDS[deck_card.config.card_key])


    -- Copy ALL existing properties from deck card (complete copy)
    if deck_card.edition then
        original_card:set_edition(deck_card.edition)
    end
    if deck_card.seal then
        original_card:set_seal(deck_card.seal)
    end
    if deck_card.config.center.set == 'Enhanced' then
        original_card:set_ability(deck_card.config.center)
    end
    -- We should also copy config.extra, so we clone specific buffs done to the deck card
    if deck_card.ability.extra then
        original_card.ability.extra = deck_card.ability.extra
    end

    -- Now attempt improvements with Magic Trick logic (only if they would improve the card)
    QOL_BUNDLE.utils.try_apply_enhancement(original_card, 'illusion_enh_improve')
    QOL_BUNDLE.utils.try_apply_edition(original_card, 'illusion_ed_improve')
    QOL_BUNDLE.utils.try_apply_seal(original_card, 'illusion_seal_improve')
    QOL_BUNDLE.utils.try_apply_clip(original_card, 'illusion_clip_improve')

    return original_card
end

-- Override Illusion voucher to enable deck-based card generation  
function QOL_BUNDLE.funcs.get_ownership_voucher_illusion()
    if not QOL_BUNDLE.config.new_illusion_enabled then
        return
    end

    QOL_BUNDLE.state.illusion = SMODS.Voucher:take_ownership('v_illusion', {
        -- Keep the same config (extra = 4 for playing_card_rate)  
        -- The actual new logic will be in the shop card generation override
    })

    local apply_localization = function()
        local loc_text = localize('v_illusion_original')

        if QOL_BUNDLE.config.new_illusion_enabled then
            loc_text = localize('v_illusion_deck_based')
        end

        G.localization.descriptions.Voucher.v_illusion.text = loc_text
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_voucher_illusion()
