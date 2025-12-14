-- Override Splash Joker to add random card retriggering
function QOL_BUNDLE.funcs.get_ownership_joker_splash()
    if not QOL_BUNDLE.config.splash_joker_retrigger_enabled then
        return
    end

    QOL_BUNDLE.state.splash_joker = SMODS.Joker:take_ownership('j_splash', {
        calculate = function(self, card, context)
            -- On scoring start, select two random cards to retrigger on the repetition phase
            if context.initial_scoring_step then
                -- Create a copy of the scoring hand to select from
                local available_cards = {}
                for _, v in ipairs(context.scoring_hand) do
                    table.insert(available_cards, v)
                end

                -- Select first random card
                local first_index = pseudorandom(pseudoseed('splash_retrigger_1'), 1, #available_cards)
                random_splash_retrigger_1 = available_cards[first_index]

                -- Remove the first card from the pool
                table.remove(available_cards, first_index)

                -- Select second random card (if available)
                random_splash_retrigger_2 = nil
                if #available_cards > 0 then
                    local second_index = pseudorandom(pseudoseed('splash_retrigger_2'), 1, #available_cards)
                    random_splash_retrigger_2 = available_cards[second_index]
                    RIOSODU_SHARED.utils.sendDebugMessage("Splash Joker retriggering random cards: " .. random_splash_retrigger_1.base.value .. " and " .. random_splash_retrigger_2.base.value, QOL_BUNDLE.mod_id)
                else
                    RIOSODU_SHARED.utils.sendDebugMessage("Splash Joker retriggering random card: " .. random_splash_retrigger_1.base.value, QOL_BUNDLE.mod_id)
                end
            end

            -- Handle the random card retrigger effect during scoring
            if context.repetition and context.cardarea == G.play and context.other_card then
                -- Check if this card is one of the selected retrigger cards
                if context.other_card == random_splash_retrigger_1 or context.other_card == random_splash_retrigger_2 then
                    return {
                        message = localize('k_again_ex'),
                        repetitions = 1,
                        card = card
                    }
                end
            end
        end,
    })

    local apply_localization = function()
        local loc = localize('j_splash_original')
        if QOL_BUNDLE.config.splash_joker_retrigger_enabled then
            loc = localize('j_splash_retrigger')
        end
        G.localization.descriptions.Joker.j_splash.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_splash()