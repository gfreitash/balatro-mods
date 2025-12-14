QOL_BUNDLE.utils = QOL_BUNDLE.utils or {}

-- Try to apply enhancement using SMODS poll system (now with reroll logic for Illusion)
function QOL_BUNDLE.utils.try_apply_enhancement(card, seed_key)
    if not card then return end

    local enhancement_key = SMODS.poll_enhancement({
        key = seed_key,
        mod = 2.5, -- 40% chance (default 16% * 2.5 = 40%)
        guaranteed = nil
    })

    -- Check if card has enhancements with  SMODS.get_enhancements, if table not empty it has
    has_enhancements = #SMODS.get_enhancements(card) > 0

    if enhancement_key and not has_enhancements then
        card:set_ability(G.P_CENTERS[enhancement_key])
    end
end

-- Try to apply edition using poll_edition (now with reroll logic for Illusion)
function QOL_BUNDLE.utils.try_apply_edition(card, seed_key)
    if not card then return end

    -- Use poll_edition which respects game logic and SMODS overrides
    local new_edition = poll_edition(seed_key, 1, false, false)
    if new_edition then
        card:set_edition(new_edition)
    end
end

-- Try to apply seal using SMODS poll system (now with reroll logic for Illusion)
function QOL_BUNDLE.utils.try_apply_seal(card, seed_key)
    if not card then return end

    local seal_key = SMODS.poll_seal({
        key = seed_key,
        mod = 10, -- 20% chance (default 2% * 10 = 20%)
        guaranteed = false
    })

    if seal_key then
        card:set_seal(seal_key)
    end
end

-- Try to apply paperclip using Paperback's poll system (if Paperback is available)
function QOL_BUNDLE.utils.try_apply_clip(card, seed_key)
    if not card then return end

    -- Check if Paperback mod is available
    if not PB_UTIL or not PB_UTIL.poll_paperclip or not PB_UTIL.set_paperclip then
        return
    end

    has_paperclip = PB_UTIL.has_paperclip(card)
    -- Use 20% chance (same as seals), guaranteed if already has paperclip
    local clip_chance = has_paperclip and 1 or pseudorandom(pseudoseed(seed_key))
    if clip_chance > 0.8 then -- 20% chance
        local clip_type = PB_UTIL.poll_paperclip(seed_key)
        if clip_type then
            PB_UTIL.set_paperclip(card, clip_type)
        end
    end
end

-- Recalculate playing card cost based on new rules
function QOL_BUNDLE.utils.recalculate_playing_card_cost(card)
    if not card or not (card.ability.set == 'Default' or card.ability.set == 'Enhanced') then
        return
    end

    local extra_cost = 0

    -- Editions
    if card.edition then
        if card.edition.polychrome then
            extra_cost = extra_cost + 3
        else -- Foil, Holo, Negative
            extra_cost = extra_cost + 2
        end
    end

    -- Seals
    if card.seal then
        extra_cost = extra_cost + 1
    end

    -- Enhancements
    if card.ability.set == 'Enhanced' then
        extra_cost = extra_cost + 1
    end

    -- Recalculate final cost, respecting discounts
    card.cost = math.max(1, math.floor((card.base_cost + extra_cost + 0.5) * (100 - G.GAME.discount_percent) / 100))

    -- Recalculate sell cost
    card.sell_cost = math.max(1, math.floor(card.cost / 2)) + (card.ability.extra_value or 0)
    card.sell_cost_label = card.sell_cost
end