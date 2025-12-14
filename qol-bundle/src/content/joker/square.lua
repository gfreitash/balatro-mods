-- Override the Square Joker
function QOL_BUNDLE.funcs.get_ownership_joker_square()
    if not QOL_BUNDLE.config.square_joker_enabled then
        return
    end

    QOL_BUNDLE.state.square_joker = SMODS.Joker:take_ownership('j_square', {
        rarity = 2, -- Uncommon
        config = {
            extra = {
                chips = 0,
                chip_mod = 4,  -- Base +4 chips
                odds = 2       -- 1 in 2 chance for bonus
            }
        },
        loc_vars = function(self, info_queue, center)
            return {
                vars = {
                    center.ability.extra.chips,
                    center.ability.extra.chip_mod,
                    ''..(G.GAME and G.GAME.probabilities.normal or 1),
                    center.ability.extra.odds
                }
            }
        end,
        calculate = function(self, card, context)
            -- Handle the scaling when hand is played (before scoring)
            if context.before and #context.full_hand == 4 and not context.blueprint then
                local bonus_chips = 4  -- Base +4 chips
                local bonus_count = 0  -- Track how many cards triggered

                delay_amount = 0.4
                -- Check scoring cards from context.scoring_hand and roll for each
                if context.scoring_hand then
                    for i, scoring_card in ipairs(context.scoring_hand) do
                        -- Each scoring card has 1/2 chance to add +4 more chips
                        if SMODS.pseudorandom_probability(card, 'square_joker_' .. scoring_card.unique_val, 1, 2) then
                            bonus_chips = bonus_chips + 4
                            bonus_count = bonus_count + 1
                            -- Add visual effect on the scoring card with delay
                            G.E_MANAGER:add_event(Event({
                                trigger = 'after',
                                blocking = true,
                                blockable = true,
                                delay = (delay_amount * i), -- Sequential delay
                                func = function()
                                    attention_text({
                                        major = card,
                                        backdrop_colour = G.C.CHIPS,
                                        text = localize('k_upgrade_ex'),
                                        scale = 0.8,
                                        hold = (1 + delay_amount + 0.2)/G.SETTINGS.GAMESPEED,
                                        align = 'bm',
                                    })
                                    play_sound('chips2', 1, 0.4)
                                    card:juice_up(0.3, 0.5)
                                    scoring_card:juice_up(0.3, 0.5)
                                    delay(0.2)
                                    return true
                                end
                            }))
                        end
                    end
                end

                -- Update the joker's chip total
                card.ability.extra.chips = card.ability.extra.chips + bonus_chips
                delay((delay_amount * bonus_count) + 0.2)
                return { }
            end

            -- Handle the actual chip contribution during scoring
            if context.joker_main then
                return {
                    message = localize{type='variable',key='a_chips',vars={card.ability.extra.chips}},
                    chip_mod = card.ability.extra.chips,
                    colour = G.C.CHIPS
                }
            end

            return nil
        end
    })

    local apply_localization = function() 
        local loc = localize('j_square_original')
        if QOL_BUNDLE.config.square_joker_enabled then
            loc = localize('j_square_modified')
        end
        G.localization.descriptions.Joker.j_square.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_square()
