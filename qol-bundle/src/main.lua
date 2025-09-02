-- QoL Bundle/src/main.lua

QOL_BUNDLE.utils = QOL_BUNDLE.utils or {}
QOL_BUNDLE.funcs = QOL_BUNDLE.funcs or {}

-- Override the Wheel of Fortune consumable
function QOL_BUNDLE.funcs.get_ownership_wheel_of_fortune()
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
function QOL_BUNDLE.funcs.get_ownership_eight_ball_joker()
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
local jacks_to_move = {}
function QOL_BUNDLE.funcs.get_ownership_hit_the_road_joker()
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
                            ..G.GAME.round
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

-- Override the Square Joker
function QOL_BUNDLE.funcs.get_ownership_square_joker()
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

-- Override the Flower Pot Joker
function QOL_BUNDLE.funcs.get_ownership_flower_pot_joker()
    if not QOL_BUNDLE.config.flower_pot_wildcard_enabled then
        return
    end

    QOL_BUNDLE.state.flower_pot = SMODS.Joker:take_ownership('j_flower_pot', {
        enhancement_gate = 'm_wild', -- Only show in shop if wildcard cards exist
        calculate = function(self, card, context)
            if context.joker_main then
                -- Check if scoring hand has any wildcard-enhanced cards
                local has_wildcard = false
                for i = 1, #context.scoring_hand do
                    if context.scoring_hand[i].config.center.key == 'm_wild' then
                        has_wildcard = true
                        break
                    end
                end
                
                if has_wildcard then
                    return {
                        message = localize{type='variable',key='a_xmult',vars={card.ability.extra}},
                        Xmult_mod = card.ability.extra
                    }
                end
            end
            return nil
        end,
    })

    local apply_localization = function()
        local loc = localize('j_flower_pot_original')
        if QOL_BUNDLE.config.flower_pot_wildcard_enabled then
            loc = localize('j_flower_pot_modified')
        end
        G.localization.descriptions.Joker.j_flower_pot.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

-- Override Baron to make it Uncommon and cheaper
function QOL_BUNDLE.funcs.get_ownership_baron_uncommon()
    if not QOL_BUNDLE.config.baron_uncommon_enabled then
        return
    end

    QOL_BUNDLE.state.baron = SMODS.Joker:take_ownership('j_baron', {
        rarity = 2, -- Uncommon (was 3 - Rare)
        cost = 5,   -- Cheaper (was 8)
    })
end

-- Override Mime to make it Rare and more expensive
function QOL_BUNDLE.funcs.get_ownership_mime_rare()
    if not QOL_BUNDLE.config.mime_rare_enabled then
        return
    end

    QOL_BUNDLE.state.mime = SMODS.Joker:take_ownership('j_mime', {
        rarity = 3, -- Rare (was 2 - Uncommon)
        cost = 6,   -- Higher price (was 5)
    })
end

-- Override Photograph and Hanging Chad
function QOL_BUNDLE.funcs.get_ownership_nerf_photochad()
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

-- Override Ceremonial Dagger to make it Common and cheaper
function QOL_BUNDLE.funcs.get_ownership_ceremonial_dagger_common()
    if not QOL_BUNDLE.config.ceremonial_dagger_common_enabled then
        return
    end

    QOL_BUNDLE.state.ceremonial_dagger = SMODS.Joker:take_ownership('j_ceremonial', {
        rarity = 1, -- Common (was 2 - Uncommon)
        cost = 3,   -- Cheaper (was 6)
    })
end

-- Override Mail-In Rebate to make it Uncommon
function QOL_BUNDLE.funcs.get_ownership_mail_in_rebate_uncommon()
    if not QOL_BUNDLE.config.mail_in_rebate_uncommon_enabled then
        return
    end

    QOL_BUNDLE.state.mail_in_rebate = SMODS.Joker:take_ownership('j_mail', {
        rarity = 2, -- Uncommon (was 1 - Common)
    })
end

-- Override Fortune Teller to make it cheaper
function QOL_BUNDLE.funcs.get_ownership_fortune_teller_cheaper()
    if not QOL_BUNDLE.config.fortune_teller_cheaper_enabled then
        return
    end

    QOL_BUNDLE.state.fortune_teller = SMODS.Joker:take_ownership('j_fortune_teller', {
        cost = 4, -- Cheaper (was 6)
    })
end

-- Override Erosion to give 0.2X mult per card below starting amount
function QOL_BUNDLE.funcs.get_ownership_erosion_xmult()
    if not QOL_BUNDLE.config.erosion_xmult_enabled then
        return
    end

    QOL_BUNDLE.state.erosion = SMODS.Joker:take_ownership('j_erosion', {
        config = {
            extra = 0.2 -- 0.2X mult per card below starting amount
        },
        loc_vars = function(self, info_queue, center)
            local cards_below = math.max(0, (G.GAME and G.GAME.starting_deck_size or 52) - (G.playing_cards and #G.playing_cards or 52))
            local current_xmult = 1 + (center.ability.extra * cards_below)
            return {
                vars = {
                    center.ability.extra, -- #1# - per card multiplier (0.2)
                    G.GAME and G.GAME.starting_deck_size or 52, -- #2# - starting deck size
                    current_xmult, -- #3# - current X mult  
                }
            }
        end,
        calculate = function(self, card, context)
            if context.joker_main then
                local cards_below = math.max(0, G.GAME.starting_deck_size - #G.playing_cards)
                if cards_below > 0 then
                    local xmult = 1 + (card.ability.extra * cards_below)
                    return {
                        message = localize{type='variable',key='a_xmult',vars={xmult}},
                        Xmult_mod = xmult
                    }
                end
            end
            return nil
        end
    })

    local apply_localization = function()
        local loc = localize('j_erosion_original')
        if QOL_BUNDLE.config.erosion_xmult_enabled then
            loc = localize('j_erosion_xmult')
        end
        G.localization.descriptions.Joker.j_erosion.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

-- Override the Satellite Joker
function QOL_BUNDLE.funcs.get_ownership_satellite_joker()
    if not QOL_BUNDLE.config.satellite_joker_enabled then
        return
    end

    QOL_BUNDLE.state.satellite_joker = SMODS.Joker:take_ownership('j_satellite', {
        loc_vars = function(self, info_queue, center)
            -- Find the highest poker hand level
            local highest_level = 0
            for hand_name, hand_data in pairs(G.GAME and G.GAME.hands or {}) do
                if hand_data.level > highest_level then
                    highest_level = hand_data.level
                end
            end

            -- Calculate gold amount (half the highest level, rounded down)
            local gold_amount = math.floor(highest_level / 2)

            return {
                vars = {
                    center.ability.extra,  -- #1# - Base multiplier (1)
                    gold_amount           -- #2# - Current gold amount
                }
            }
        end,
        calculate = function(self, card, context)
            if context.end_of_round and not context.individual and not context.repetition then
                -- Find the highest poker hand level
                local highest_level = 0
                for hand_name, hand_data in pairs(G.GAME.hands) do
                    if hand_data.level > highest_level then
                        highest_level = hand_data.level
                    end
                end

                -- Calculate gold amount (half the highest level, rounded down)
                local gold_amount = math.floor(highest_level / 2)

                if gold_amount > 0 then
                    return {
                        message = localize('$')..gold_amount,
                        dollars = gold_amount,
                        colour = G.C.MONEY
                    }
                end
            end
            return nil
        end
    })

    local apply_localization = function()
        local loc = localize('j_satellite_original')
        if QOL_BUNDLE.config.satellite_joker_enabled then
            loc = localize('j_satellite_modified')
        end
        G.localization.descriptions.Joker.j_satellite.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

-- Override the Loyalty Card Joker
local loyalty_juicing = false
function QOL_BUNDLE.funcs.get_ownership_loyalty_card()
    if not QOL_BUNDLE.config.loyalty_card_rounds_enabled then
        return
    end


    QOL_BUNDLE.state.loyalty_card = SMODS.Joker:take_ownership('j_loyalty_card', {
        config = {
            extra = {
                every = 2,
                Xmult = 4,
            }
        },
        loc_vars = function (self, info_queue, card)
            local loyalty_state = 'loyalty_inactive'

            if card.ability.loyalty_remaining == 0 and loyalty_juicing then
                loyalty_state = 'loyalty_active'
            elseif card.ability.loyalty_remaining == 0 and not loyalty_juicing then
                loyalty_state = 'loyalty_redeemed'
            end

            return {
                vars = {
                    card.ability.extra.Xmult,
                    card.ability.extra.every,
                    loyalty_state == 'loyalty_redeemed' and localize('k_redeemed_ex') or localize{
                        type = 'variable',
                        key = loyalty_state,
                        vars = {card.ability.loyalty_remaining}
                    }
                }
            }
        end,
        calculate = function(self, card, context)
            local rounds_since_creation = G.GAME.round - card.ability.rounds_played_at_create
            card.ability.loyalty_remaining = (card.ability.extra.every - rounds_since_creation) % card.ability.extra.every

                if not context.blueprint and G.play and not loyalty_juicing then
                    local eval = function(c)
                        local ret = (
                            c.ability.loyalty_remaining == 0 and (
                                G.STATE == G.STATES.NEW_ROUND or
                                G.STATE == G.STATES.DRAW_TO_HAND or
                                G.STATE == G.STATES.HAND_PLAYED or
                                G.STATE == G.STATES.SELECTING_HAND or
                                G.STATE == G.STATES.PLAY_TAROT or
                                G.STATE == G.STATES.MENU
                            )
                        )

                        loyalty_juicing = ret
                        return ret
                    end

                    juice_card_until(card, eval, true, 0.5)
                    loyalty_juicing = true
                end

            if context.joker_main then
                RIOSODU_SHARED.utils.sendDebugMessage("Loyalty, round crated: " .. card.ability.rounds_played_at_create)
                RIOSODU_SHARED.utils.sendDebugMessage("Loyalty, round current: " .. G.GAME.round)
                RIOSODU_SHARED.utils.sendDebugMessage("Loyalty remaining: " .. card.ability.loyalty_remaining)

                ret = {
                    message = localize{type='variable',key='a_xmult',vars={card.ability.extra.Xmult}},
                    Xmult_mod = card.ability.extra.Xmult,
                }

                if card.ability.loyalty_remaining == 0 then
                    return ret
                end
            end
        end
    })

    local apply_localization = function()
        local loc = localize('j_loyalty_card_original')
        if QOL_BUNDLE.config.loyalty_card_rounds_enabled then
            loc = localize('j_loyalty_card_rounds')
        end
        G.localization.descriptions.Joker.j_loyalty_card.text = loc
    end

    RIOSODU_SHARED.register_hook('on_game_start', function ()
        apply_localization()
        init_localization()
    end)
end

-- Override Splash Joker to add random card retriggering
local random_splah_retrigger = nil
function QOL_BUNDLE.funcs.get_ownership_splash_joker()
    if not QOL_BUNDLE.config.splash_joker_retrigger_enabled then
        return
    end

    QOL_BUNDLE.state.splash_joker = SMODS.Joker:take_ownership('j_splash', {
        calculate = function(self, card, context)
            -- On scoring start, select a random card to retrigger on the repetition phase
            if context.initial_scoring_step then
                random_splah_retrigger = pseudorandom_element(context.scoring_hand, pseudoseed('splash_retrigger'))
                RIOSODU_SHARED.utils.sendDebugMessage("Splash Joker retriggering random card: " .. random_splah_retrigger.base.value, QOL_BUNDLE.mod_id)
            end

            -- Handle the random card retrigger effect during scoring
            if context.repetition and context.cardarea == G.play and context.other_card then
                -- Check if this is a random retrigger by checking if there are multiple scoring cards
                if context.other_card == random_splah_retrigger then
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

-- Override Sigil spectral card to enable card selection
function QOL_BUNDLE.funcs.get_ownership_sigil_control()
    if not QOL_BUNDLE.config.sigil_control_enabled then
        return
    end

    QOL_BUNDLE.state.sigil = SMODS.Consumable:take_ownership('c_sigil', {
        config = {
            max_highlighted = 1
        }
    })
end

-- Override Ouija spectral card to enable card selection
function QOL_BUNDLE.funcs.get_ownership_ouija_control()
    if not QOL_BUNDLE.config.ouija_control_enabled then
        return
    end

    QOL_BUNDLE.state.ouija = SMODS.Consumable:take_ownership('c_ouija', {
        config = {
            max_highlighted = 1
        }
    })
end

function QOL_BUNDLE.funcs.get_ownership_jester_of_nihil()
    if not PB_UTIL then return end

    QOL_BUNDLE.state.jester_of_nihil = SMODS.Joker:take_ownership('j_paperback_jester_of_nihil', {
        update = function(self, card, dt)
            -- Update the mult this card gives by counting the amount of debuffed cards
            if G.playing_cards then
            local total = 0

            for k, v in ipairs(G.playing_cards) do
                if v.debuff or (QOL_BUNDLE.config.wildcard_fix_enabled and v.config.center.key == 'm_wild') then
                total = total + 1
                end
            end

            card.ability.extra.mult = math.max(0, total * card.ability.extra.debuff_mult)
            end
        end
    })
end

-- Interest on Skip functionality via overriding G.FUNCS.skip_blind
QOL_BUNDLE.original = QOL_BUNDLE.original or {}

function QOL_BUNDLE.funcs.apply_interest_on_skip_override()
    -- Store the original function if we haven't already
    if not QOL_BUNDLE.original.skip_blind then
        QOL_BUNDLE.original.skip_blind = G.FUNCS.skip_blind
    end
    
    if not QOL_BUNDLE.config.interest_on_skip_enabled then
        -- Restore the original function
        G.FUNCS.skip_blind = QOL_BUNDLE.original.skip_blind
        return
    end
    
    -- Apply the override
    G.FUNCS.skip_blind = function(e)
        -- Calculate and award interest BEFORE processing the skip
        local interest_base = G.GAME.interest_base or 5
        local interest_amount = G.GAME.interest_amount or 1
        local interest_cap = G.GAME.interest_cap or 25
        
        if G.GAME.dollars >= 1 and not G.GAME.modifiers.no_interest then
            local interest_earned = interest_amount * math.min(math.floor(G.GAME.dollars / interest_base), interest_cap / interest_base)
            
            if interest_earned > 0 then
                ease_dollars(interest_earned)
                RIOSODU_SHARED.utils.sendDebugMessage("Interest on skip: $" .. interest_earned, QOL_BUNDLE.mod_id)
            end
        end
        
        -- Call the original function
        return QOL_BUNDLE.original.skip_blind(e)
    end
end

RIOSODU_SHARED.utils.sendDebugMessage("Main logic module loading...", QOL_BUNDLE.mod_id)

QOL_BUNDLE.funcs.get_ownership_wheel_of_fortune()
QOL_BUNDLE.funcs.get_ownership_eight_ball_joker()
QOL_BUNDLE.funcs.get_ownership_hit_the_road_joker()
QOL_BUNDLE.funcs.get_ownership_square_joker()
QOL_BUNDLE.funcs.get_ownership_flower_pot_joker()
QOL_BUNDLE.funcs.get_ownership_baron_uncommon()
QOL_BUNDLE.funcs.get_ownership_mime_rare()
QOL_BUNDLE.funcs.get_ownership_nerf_photochad()
QOL_BUNDLE.funcs.get_ownership_ceremonial_dagger_common()
QOL_BUNDLE.funcs.get_ownership_mail_in_rebate_uncommon()
QOL_BUNDLE.funcs.get_ownership_fortune_teller_cheaper()
QOL_BUNDLE.funcs.get_ownership_erosion_xmult()
QOL_BUNDLE.funcs.get_ownership_satellite_joker()
QOL_BUNDLE.funcs.get_ownership_loyalty_card()
QOL_BUNDLE.funcs.get_ownership_splash_joker()
QOL_BUNDLE.funcs.get_ownership_sigil_control()
QOL_BUNDLE.funcs.get_ownership_ouija_control()
QOL_BUNDLE.funcs.get_ownership_jester_of_nihil()
QOL_BUNDLE.funcs.apply_interest_on_skip_override()

RIOSODU_SHARED.utils.sendDebugMessage("Main logic module loading...", QOL_BUNDLE.mod_id)
