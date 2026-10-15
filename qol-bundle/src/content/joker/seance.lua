-- Override Seance to trigger on secret poker hands, including modded ones
function QOL_BUNDLE.funcs.get_ownership_joker_seance()
    if not QOL_BUNDLE.config.seance_rework_enabled then
        return
    end

    local is_secret_hand = function(hand)
        -- Straight Flush is kept as a trigger even though the base game
        -- considers it visible
        if hand == 'Straight Flush' then
            return true
        end
        -- Mod-aware check: uses SMODS.PokerHands visibility metadata
        return not SMODS.is_poker_hand_visible(hand)
    end

    QOL_BUNDLE.state.seance = SMODS.Joker:take_ownership('j_seance', {
        rarity = 3, -- Rare (was 2 - Uncommon)
        cost = 8,   -- More expensive (was 6)
        calculate = function(self, card, context)
            if not context.joker_main then
                return nil
            end

            -- The vanilla Straight Flush trigger is fully replaced by our set
            if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                local secret_hand_played = false
                for hand, _ in pairs(context.poker_hands or {}) do
                    if is_secret_hand(hand) then
                        secret_hand_played = true
                        break
                    end
                end

                if secret_hand_played then
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    G.E_MANAGER:add_event(Event({
                        trigger = 'before',
                        delay = 0.0,
                        func = (function()
                            local new_card = create_card('Spectral', G.consumeables, nil, nil, nil, nil, nil, 'sea')
                            new_card:add_to_deck()
                            G.consumeables:emplace(new_card)
                            G.GAME.consumeable_buffer = 0
                            return true
                        end)
                    }))
                    return { message = localize('k_plus_spectral'), colour = G.C.SECONDARY_SET.Spectral, card = card }
                end
            end

            return {}
        end
    })

    local apply_localization = function()
        local loc = localize('j_seance_original')
        if QOL_BUNDLE.config.seance_rework_enabled then
            loc = localize('j_seance_modified')
        end
        G.localization.descriptions.Joker.j_seance.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_seance()
