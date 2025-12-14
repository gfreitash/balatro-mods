-- Override the Hit the Road Joker
local jacks_to_move = {}
function QOL_BUNDLE.funcs.get_ownership_joker_hit_the_road()
    if not QOL_BUNDLE.config.hit_the_road_joker_enabled then
        return
    end

    QOL_BUNDLE.state.hit_the_road_joker = SMODS.Joker:take_ownership('j_hit_the_road', {
        calculate = function(self, card, context)
            if context.blueprint then return nil end

            -- Check if a card is being discarded
            if context.pre_discard and context.full_hand then
                for _, card_in_hand in ipairs(context.full_hand) do
                    if card_in_hand.base.value == 'Jack' then
                        table.insert(jacks_to_move, card_in_hand)
                    end
                end
                
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    blocking = true,
                    blockable = true,
                    func = function()
                        local jack_count = 0
                        for index, value in ipairs(jacks_to_move) do
                            print("ID: " ..  (value.ID or "nil"))
                        end

                        for i, jack_card in ipairs(jacks_to_move) do
                            jack_count = jack_count + 1
                            local animation_progress = (jack_count * 100) / #jacks_to_move
                            print("Drawing jack: " .. tostring(jack_card.ID))
                            draw_card(G.discard, G.deck, animation_progress, 'up', true, jack_card)
                        end
                        jacks_to_move = {}

                        G.deck:shuffle(
                            'j_hit_the_road_shuffle_'
                            ..G.GAME.hands_played
                            ..'_'
                            ..G.GAME.current_round.hands_left
                            ..'_'
                            ..G.GAME.current_round.discards_left
                        )
                        return true
                    end
                }))
            end
            return nil
        end,
    })

    local apply_localization = function()
        local loc = localize('j_hit_the_road_original')
        if QOL_BUNDLE.config.hit_the_road_joker_enabled then
            loc = localize('j_hit_the_road_modified')
        end
        G.localization.descriptions.Joker.j_hit_the_road.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

QOL_BUNDLE.funcs.get_ownership_joker_hit_the_road()
