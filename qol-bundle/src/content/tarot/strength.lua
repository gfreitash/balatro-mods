-- Override Strength: requires exactly two selected cards and raises the lower
-- rank card's rank to match the higher one.
function QOL_BUNDLE.funcs.get_ownership_tarot_strength()
    if not QOL_BUNDLE.config.strength_two_cards_enabled then
        return
    end

    QOL_BUNDLE.state.strength = SMODS.Consumable:take_ownership('c_strength', {
        config = {
            mod_conv = 'up_rank',
            max_highlighted = 2,
            min_highlighted = 2,
        },
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            local cards = G.hand and G.hand.highlighted or {}
            if #cards ~= 2 then
                return
            end

            -- Determine the higher and lower cards by rank id.
            local first, second = cards[1], cards[2]
            local lower, higher
            if (first.base.id or 0) <= (second.base.id or 0) then
                lower, higher = first, second
            else
                lower, higher = second, first
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    play_sound('tarot1')
                    used_tarot:juice_up(0.3, 0.5)
                    return true
                end
            }))

            for i = 1, #cards do
                local percent = 1.15 - (i - 0.999) / (#cards - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        cards[i]:flip()
                        play_sound('card1', percent)
                        cards[i]:juice_up(0.3, 0.3)
                        return true
                    end
                }))
            end
            delay(0.2)

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.1,
                func = function()
                    if lower and higher and lower.base.id ~= higher.base.id then
                        SMODS.change_base(lower, lower.base.suit, higher.base.value)
                    end
                    return true
                end
            }))

            for i = 1, #cards do
                local percent = 0.85 + (i - 0.999) / (#cards - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        cards[i]:flip()
                        play_sound('tarot2', percent, 0.6)
                        cards[i]:juice_up(0.3, 0.3)
                        return true
                    end
                }))
            end

            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    G.hand:unhighlight_all()
                    return true
                end
            }))
            delay(0.5)
        end
    })

    local apply_localization = function()
        local loc = localize('c_strength_original')
        if QOL_BUNDLE.config.strength_two_cards_enabled then
            loc = localize('c_strength_modified')
        end
        G.localization.descriptions.Tarot.c_strength.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_tarot_strength()
