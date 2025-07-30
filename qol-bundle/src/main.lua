-- QoL Bundle/src/main.lua

QOL_BUNDLE.utils = QOL_BUNDLE.utils or {}

-- Override the Wheel of Fortune consumable
function get_ownership_wheel_of_fortune()
    if not QOL_BUNDLE.config.wheel_of_fortune_enabled then
        return
    end

    QOL_BUNDLE.state.wheel_of_fortune = SMODS.Consumable:take_ownership('wheel_of_fortune', {
        config = {
            extra = QOL_BUNDLE.config.wheel_of_fortune_value or 4
        }
    })
end

-- Override the 8 Ball Joker
function get_ownership_eight_ball_joker()
    if not QOL_BUNDLE.config.eight_ball_joker_enabled then
        return
    end

    QOL_BUNDLE.state.eight_ball_joker = SMODS.Joker:take_ownership('8_ball', {
        config = {
            extra = QOL_BUNDLE.config.eight_ball_joker_value or 4
        }
    })
end

-- Override the Hit the Road Joker
function get_ownership_hit_the_road_joker()
    if not QOL_BUNDLE.config.hit_the_road_joker_enabled then
        return
    end

    QOL_BUNDLE.state.hit_the_road_joker = SMODS.Joker:take_ownership('j_hit_the_road', {
        calculate = function(self, card, context)
            -- Check if a card is being discarded
            if context.pre_discard and context.full_hand then
                local jacks_to_move = {}
                for _, card_in_hand in ipairs(context.full_hand) do
                    if card_in_hand.base.value == 'Jack' then
                        table.insert(jacks_to_move, card_in_hand)
                    end
                end

                if #jacks_to_move > 0 then
                    local jack_count = 0
                    for i, jack_card in ipairs(jacks_to_move) do
                        jack_count = jack_count + 1
                        local animation_progress = (jack_count * 100) / #jacks_to_move
                        draw_card(G.hand, G.deck, animation_progress, 'up', true, jack_card)
                    end
                    G.deck:shuffle()
                    return nil
                end
            end
            return nil
        end,
    })
end

-- Override the Square Joker
function get_ownership_square_joker()
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
end

-- Override Photograph and Hanging Chad
function get_ownership_nerf_photochad()
    if not QOL_BUNDLE.config.nerf_photochad_enabled then
        return
    end

    QOL_BUNDLE.state.photograph = SMODS.Joker:take_ownership('j_photograph', {
        rarity = 2, -- Uncommon
    })

    QOL_BUNDLE.state.hanging_chad = SMODS.Joker:take_ownership('j_hanging_chad', {
        rarity = 2, -- Uncommon
    })
end

QOL_BUNDLE.utils.update_hit_the_road_joker_localization = function()
    local text_lines = {}
    if QOL_BUNDLE.config.hit_the_road_joker_enabled then
        table.insert(text_lines, "This Joker gains {X:mult,C:white} X#1# {} Mult")
        table.insert(text_lines, "for every {C:attention}Jack{} discarded this round,")
        table.insert(text_lines, "and discarded {C:attention}Jacks{} are returned to deck.")
        table.insert(text_lines, "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)")
    else
        table.insert(text_lines, "This Joker gains {X:mult,C:white} X#1# {} Mult")
        table.insert(text_lines, "for every {C:attention}Jack{} discarded this round")
        table.insert(text_lines, "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)")
    end
    G.localization.descriptions.Joker.j_hit_the_road.text = text_lines
end

G.FUNCS.qol_bundle_update_hit_the_road_joker_localization = QOL_BUNDLE.utils.update_hit_the_road_joker_localization

RIOSODU_SHARED.utils.sendDebugMessage("Main logic module loading...", QOL_BUNDLE.mod_id)
get_ownership_wheel_of_fortune()
get_ownership_eight_ball_joker()
get_ownership_hit_the_road_joker()
get_ownership_square_joker()
get_ownership_nerf_photochad()
QOL_BUNDLE.utils.update_hit_the_road_joker_localization()
