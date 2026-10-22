-- Override Wraith: duplicate a random Joker, other Jokers become Perishable
function QOL_BUNDLE.funcs.get_ownership_spectral_wraith()
    if not QOL_BUNDLE.config.wraith_rework_enabled then
        return
    end

    QOL_BUNDLE.state.wraith = SMODS.Consumable:take_ownership('c_wraith', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            if #G.jokers.cards == 0 or #G.jokers.cards >= G.jokers.config.card_limit then
                return
            end

            local chosen = pseudorandom_element(G.jokers.cards, pseudoseed('wraith_choice'))
            if not chosen then
                return
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    play_sound('timpani')
                    -- Mirrors the SMODS-aware Ankh copy: a negative edition is
                    -- stripped so the copy cannot duplicate it.
                    local copy = copy_card(chosen, nil, nil, nil, chosen.edition and chosen.edition.negative)
                    copy:start_materialize()
                    copy:add_to_deck()
                    if copy.edition and copy.edition.negative then
                        copy:set_edition(nil, true)
                    end
                    G.jokers:emplace(copy)
                    used_tarot:juice_up(0.3, 0.5)

                    for _, joker in ipairs(G.jokers.cards) do
                        if joker ~= chosen and joker ~= copy and not SMODS.is_eternal(joker, used_tarot) then
                            -- set_perishable also enforces perishable_compat.
                            joker:set_perishable(true)
                        end
                    end
                    return true
                end
            }))
            delay(0.6)
        end
    })

    local apply_localization = function()
        local loc = localize('c_wraith_original')
        if QOL_BUNDLE.config.wraith_rework_enabled then
            loc = localize('c_wraith_modified')
        end
        G.localization.descriptions.Spectral.c_wraith.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_spectral_wraith()
